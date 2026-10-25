import 'dart:io';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/data/request_outbox.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceProvider _p(String id, {double avg = 0, int count = 0}) =>
    ServiceProvider(
      id: id,
      businessName: id,
      categories: const ['plumbing'],
      status: ProviderStatus.approved,
      ratingAvg: avg,
      ratingCount: count,
      rankScore: rankScore(avg, count),
    );

void main() {
  final groups = parseServiceCategories(serviceCategoriesDefault);

  group('finding the category from the words', () {
    test('"kitchen tap leaking" finds plumbers', () {
      expect(
        detectCategories('kitchen tap leaking under the sink', groups).first.id,
        'plumbing',
      );
      expect(
        detectCategories('Kitchen tap leaking', groups).first.id,
        'plumbing',
      );
    });

    test('other everyday words', () {
      expect(
        detectCategories('no heat, furnace is off', groups).first.id,
        'hvac',
      );
      expect(
        detectCategories(
          'need a dog walker on weekdays',
          groups,
        ).map((c) => c.id),
        contains('dog_walking'),
      );
      expect(
        detectCategories('locked out of my apartment', groups).first.id,
        'locksmith',
      );
    });

    test('nothing to go on finds nothing', () {
      expect(detectCategories('', groups), isEmpty);
      expect(detectCategories('please help', groups), isEmpty);
    });

    test('search words drop filler, as the server does', () {
      expect(searchTokens('The kitchen tap is leaking!'), [
        'kitchen',
        'tap',
        'leaking',
      ]);
    });
  });

  group('ranking', () {
    test('1 five-star review ranks below 200 reviews averaging 4.8', () {
      expect(rankScore(5, 1), lessThan(rankScore(4.8, 200)));
      final sorted = sortResults([
        (
          provider: _p('new', avg: 5, count: 1),
          distanceMiles: 1,
          recommended: false,
        ),
        (
          provider: _p('proven', avg: 4.8, count: 200),
          distanceMiles: 8,
          recommended: false,
        ),
      ]);
      expect(sorted.map((r) => r.provider.id), ['proven', 'new']);
    });

    test('a new provider starts at the prior, between good and bad', () {
      expect(rankScore(0, 0), priorMean);
      expect(rankScore(2, 30), lessThan(priorMean));
    });

    test('society recommendations come first, then rank, then distance', () {
      final sorted = sortResults([
        (
          provider: _p('far', avg: 4.5, count: 40),
          distanceMiles: 9,
          recommended: false,
        ),
        (
          provider: _p('near', avg: 4.5, count: 40),
          distanceMiles: 2,
          recommended: false,
        ),
        (
          provider: _p('top', avg: 4.9, count: 90),
          distanceMiles: 5,
          recommended: false,
        ),
        (
          provider: _p('ours', avg: 4.1, count: 3),
          distanceMiles: 20,
          recommended: true,
        ),
      ]);
      expect(sorted.map((r) => r.provider.id), ['ours', 'top', 'near', 'far']);
    });
  });

  test('documents needed follow the services offered', () {
    expect(requiredDocuments(['plumbing'], groups), {'license', 'insurance'});
    expect(requiredDocuments(['house_cleaning'], groups), {'insurance'});
    expect(requiredDocuments(['babysitting'], groups), {'background'});
    expect(requiredDocuments(['dog_walking', 'plumbing'], groups), {
      'license',
      'insurance',
      'background',
    });
  });

  test('a provider shows Background checked only once the check passed', () {
    ServiceProvider check(String status) => ServiceProvider.fromDoc('p', {
      'businessName': 'Sue',
      'categories': const ['babysitting'],
      'status': 'approved',
      'backgroundCheck': {'status': status},
    });
    expect(check('passed').backgroundChecked, isTrue);
    expect(check('pending').backgroundChecked, isFalse);
    expect(check('passed').offersPersonalCare, isTrue);
  });

  test('the request form asks for fields that fit the category', () {
    expect(detailFieldsFor('personal_care', 'babysitting'), [
      DetailField.date,
      DetailField.hours,
      DetailField.childrenAges,
      DetailField.budget,
    ]);
    expect(
      detailFieldsFor('personal_care', 'dog_walking'),
      contains(DetailField.petSize),
    );
    expect(
      detailFieldsFor('home_repair', 'plumbing'),
      contains(DetailField.urgency),
    );
  });

  test('requests read their stored status and completion', () {
    final r = ServiceRequest.fromDoc('r1', const {
      'posterUid': 'a',
      'title': 'Tap',
      'category': 'plumbing',
      'status': 'in_progress',
      'providerId': 'p',
      'details': {'urgency': 'soon', 'bad': 3},
      'completion': {
        'note': 'New washer',
        'photos': [
          {'path': 'x', 'thumbPath': 'y', 'thumbUrl': 'z'},
        ],
        'video': {'path': 'v.mp4'},
      },
    });
    expect(r.status, RequestStatus.inProgress);
    expect(r.status.isOpen, isTrue);
    expect(r.details, {'urgency': 'soon'});
    expect(r.completion?.photos.single.thumbUrl, 'z');
    expect(r.completion?.videoPath, 'v.mp4');
    expect(RequestStatus.notFixed.id, 'not_fixed');
    expect(RequestStatus.parse('confirmed').isOpen, isFalse);
  });

  test('only a confirmed, unrated job with a provider can be reviewed', () {
    ServiceRequest r(String status, {bool rated = false}) =>
        ServiceRequest.fromDoc('r', {
          'posterUid': 'a',
          'title': 't',
          'category': 'plumbing',
          'status': status,
          'providerId': 'p',
          'rated': rated,
        });
    expect(r('confirmed').canReview, isTrue);
    expect(r('confirmed', rated: true).canReview, isFalse);
    expect(r('completed').canReview, isFalse);
  });

  test('the request outbox keeps a request and its photos on disk', () async {
    final dir = await Directory.systemTemp.createTemp('request_outbox');
    addTearDown(() => dir.delete(recursive: true));
    final photo = File('${dir.path}/picked.jpg')..writeAsBytesSync([1, 2, 3]);
    final box = RequestOutbox(baseDir: () async => dir);
    await box.add('r1', (
      scope: RequestScope.common,
      societyId: 's1',
      title: 'Lobby light out',
      description: 'Since Monday',
      category: 'electrical',
      group: 'home_repair',
      details: const {'urgency': 'soon'},
      photos: [photo],
      location: const GeoPoint(40.44, -79.99),
      providerId: null,
    ), posterName: 'Ann');
    photo.deleteSync(); // The outbox has its own copy.
    final [item] = await box.load();
    expect(item.id, 'r1');
    expect(item.draft.scope, RequestScope.common);
    expect(item.draft.details, {'urgency': 'soon'});
    expect(item.draft.location?.lat, 40.44);
    expect(item.draft.photos.single.readAsBytesSync(), [1, 2, 3]);
    final later = item.retried(DateTime(2026, 10, 24));
    expect(later.attempts, 1);
    expect(later.nextAttemptAt, DateTime(2026, 10, 24, 0, 0, 30));
    await box.update(later);
    expect((await box.load()).single.attempts, 1);
    await box.remove('r1');
    expect(await box.load(), isEmpty);
    expect(Directory('${dir.path}/service_outbox/r1').existsSync(), isFalse);
  });
}
