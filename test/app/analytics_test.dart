import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fixburgh/app/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Recording extends Analytics {
  final events = <(String, Map<String, Object>)>[];

  @override
  Future<void> log(
    String event, [
    Map<String, Object> params = const {},
  ]) async => events.add((event, params));
}

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

/// Every journey event, so the checks below cover them all.
Future<void> _logAll(Analytics a) async {
  await a.societySearch(results: 3);
  await a.societyJoinRequested();
  await a.societyJoinedWithCode();
  await a.societyClaimSubmitted();
  await a.channelPost(photos: 2);
  await a.channelComment(reply: true);
  await a.channelReaction();
  await a.providerSearch(typed: true, miles: 5, results: 4);
  await a.serviceRequestPosted(
    category: 'plumbing',
    scope: 'home',
    hasProvider: false,
  );
  await a.serviceRequestStep('accepted');
  await a.reviewPosted(stars: 5);
  await a.providerApplied(categories: 2);
}

void main() {
  test('event names fit Firebase limits', () async {
    final a = _Recording();
    await _logAll(a);
    expect(a.events, hasLength(12));
    for (final (name, params) in a.events) {
      expect(name, matches(RegExp(r'^[a-z][a-z0-9_]{0,39}$')));
      expect(params.length, lessThanOrEqualTo(25));
    }
  });

  test('parameters carry kinds and counts, never personal data', () async {
    final a = _Recording();
    await _logAll(a);
    // Only these keys may hold text, and only fixed vocabulary.
    const textKeys = {'category', 'scope', 'status'};
    for (final (_, params) in a.events) {
      for (final MapEntry(:key, :value) in params.entries) {
        if (value is String) expect(textKeys, contains(key));
        if (value is! String) expect(value, isA<int>());
      }
    }
  });

  test('a failing Firebase call never reaches the caller', () async {
    final analytics = _MockAnalytics();
    final crashlytics = _MockCrashlytics();
    when(() => crashlytics.log(any())).thenAnswer((_) async {});
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenThrow(Exception('offline'));
    final a = FirebaseJourneyAnalytics(analytics, crashlytics);
    await expectLater(a.reviewPosted(stars: 4), completes);
    verify(() => crashlytics.log('review_posted {stars: 4}')).called(1);
  });
}
