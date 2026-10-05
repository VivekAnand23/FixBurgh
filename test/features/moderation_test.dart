import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('masks email addresses', () {
    expect(
      cleanUserText('Email me at jane.doe@example.com please'),
      'Email me at [email removed] please',
    );
  });

  test('masks phone numbers in common formats', () {
    for (final n in ['412-555-1234', '(412) 555 1234', '+1 412.555.1234']) {
      expect(cleanUserText('Call $n'), 'Call [phone removed]');
    }
  });

  test('masks profanity but keeps normal words', () {
    expect(cleanUserText('This shitty pothole'), 'This s***** pothole');
    expect(cleanUserText('Dickens Ave is scrappy'), 'Dickens Ave is scrappy');
  });

  test('leaves house numbers and routes alone', () {
    expect(
      cleanUserText('Near 1234 Route 51, 2 ft wide'),
      'Near 1234 Route 51, 2 ft wide',
    );
  });
}
