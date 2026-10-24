import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:flutter_test/flutter_test.dart';

Comment c(String id, int minute, {String? replyTo}) => Comment(
  id: id,
  authorUid: 'u',
  text: id,
  replyTo: replyTo,
  createdAt: DateTime(2026, 10, 24, 12, minute),
);

void main() {
  test('General comes first, then the most recently active', () {
    final sorted = sortChannels([
      Channel(id: 'events', name: 'Events', lastPostAt: DateTime(2026, 10, 2)),
      Channel(id: 'general', name: 'General', lastPostAt: DateTime(2026)),
      Channel(id: 'b', name: 'Block B', lastPostAt: DateTime(2026, 10, 5)),
      const Channel(id: 'quiet', name: 'Quiet'),
    ]);
    expect(sorted.map((x) => x.id), ['general', 'b', 'events', 'quiet']);
  });

  test('replies sit under their comment, one level deep', () {
    final thread = threadComments([
      c('second', 5),
      c('reply-to-first', 3, replyTo: 'first'),
      c('first', 1),
      c('reply-to-reply', 4, replyTo: 'reply-to-first'),
      c('orphan', 6, replyTo: 'gone'),
    ]);
    expect(thread.map((e) => '${e.$1.id}${e.$2 ? '>' : ''}'), [
      'first',
      'reply-to-first>',
      'reply-to-reply>',
      'second',
      'orphan',
    ]);
  });

  test('mutes last until their time, or always', () {
    final now = DateTime(2026, 10, 24, 12);
    expect(
      muteFor(MuteLength.eightHours, now).until,
      DateTime(2026, 10, 24, 20),
    );
    expect(muteFor(MuteLength.oneWeek, now).until, DateTime(2026, 10, 31, 12));
    expect(muteFor(MuteLength.always, now).isActive(DateTime(2099)), isTrue);
    expect(
      Mute.until(now).isActive(now.add(const Duration(seconds: 1))),
      isFalse,
    );
    final m = Membership.fromDoc('me', {
      'role': 'member',
      'status': 'approved',
      'mutes': {'general': 'always', 'old': DateTime(2020), 'x': 42},
      'lastRead': {'general': now, 'bad': 'yesterday'},
    });
    expect(m.isMuted('general', now), isTrue);
    expect(m.isMuted('old', now), isFalse);
    expect(m.mutes.keys, ['general', 'old']);
    expect(m.lastRead, {'general': now});
  });

  test('@mentions are found by display name, longest first', () {
    expect(splitMentions('Thanks @Ann Lee and @ann!', ['Ann', 'Ann Lee']), [
      ('Thanks ', false),
      ('@Ann Lee', true),
      (' and ', false),
      ('@ann', true),
      ('!', false),
    ]);
    expect(splitMentions('No one here', const []), [('No one here', false)]);
  });

  test('only members still mentioned in the text are notified', () {
    expect(
      mentionedUids('Ask @Ann Lee about it', {'Ann Lee': 'a', 'Cal': 'c'}),
      ['a'],
    );
  });

  test('the member picker opens after an @ at a word start', () {
    expect(mentionQuery('Hi @An', 6), 'An');
    expect(mentionQuery('@', 1), '');
    expect(mentionQuery('mail me@home', 12), isNull);
    expect(mentionQuery('Hi @Ann\nnext', 12), isNull);
    expect(mentionQuery('Hi there', 8), isNull);
  });

  test('reads posts with photos and counts', () {
    final p = Post.fromDoc('p1', {
      'authorUid': 'meg',
      'text': 'Hi',
      'photos': const [
        {'path': 'a', 'thumbPath': 'b', 'thumbUrl': 'c'},
        'junk',
      ],
      'reactionCounts': const {'👍': 9, '❤️': 0, 'bad': 'x'},
      'commentCount': 6,
      'editedAt': DateTime(2026),
    });
    expect(p.photos, hasLength(1));
    expect(p.reactionCounts, {'👍': 9});
    expect(p.commentCount, 6);
    expect(p.edited, isTrue);
  });
}
