import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 4);

  bool check(int year, int month) =>
      isAtLeast13(birthYear: year, birthMonth: month, today: today);

  test('13th birthday already passed this year is allowed', () {
    expect(check(2013, 9), isTrue);
  });

  test('birthday later this year is not yet 13', () {
    expect(check(2013, 11), isFalse);
  });

  test('birthday this month is treated as not yet passed', () {
    expect(check(2013, 10), isFalse);
    expect(check(2012, 10), isTrue);
  });

  test('adults are allowed and young children are not', () {
    expect(check(1960, 1), isTrue);
    expect(check(2020, 1), isFalse);
  });
}
