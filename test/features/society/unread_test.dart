import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t = DateTime(2026, 10, 25, 9);

  test('a channel with no posts has nothing unread', () {
    expect(mayHaveUnread(null, null), isFalse);
    expect(mayHaveUnread(null, t), isFalse);
  });

  test('only a post newer than the last read can be unread', () {
    expect(mayHaveUnread(t, t), isFalse);
    expect(mayHaveUnread(t, t.add(const Duration(minutes: 1))), isFalse);
    expect(mayHaveUnread(t.add(const Duration(seconds: 1)), t), isTrue);
  });

  test('never read means any post counts', () {
    expect(mayHaveUnread(t, null), isTrue);
  });
}
