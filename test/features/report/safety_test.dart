import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool recheck(
    String text, {
    ReportCategory category = ReportCategory.fallenTree,
    Severity severity = Severity.urgent,
  }) => needsSafetyRecheck(
    category: category,
    severity: severity,
    description: text,
  );

  test('urgent tree, flood or streetlight with danger words re-asks', () {
    expect(recheck('Tree took down a wire, it is sparking'), isTrue);
    expect(recheck('Smells like GAS near the drain'), isTrue);
    expect(
      recheck('Car trapped in water', category: ReportCategory.flooding),
      isTrue,
    );
    expect(
      recheck('Pole is sparking', category: ReportCategory.streetlight),
      isTrue,
    );
  });

  test('does not re-ask otherwise', () {
    expect(recheck('Big branch on the sidewalk'), isFalse);
    expect(recheck('Wires are down', severity: Severity.medium), isFalse);
    expect(
      recheck('Wires are down', category: ReportCategory.pothole),
      isFalse,
    );
    // Matches at the start of words only.
    expect(recheck('Pulled a hardwired sign'), isFalse);
  });

  test('Remote Config list parsing', () {
    expect(parseKeywords('wire, flame ,,'), ['wire', 'flame']);
    expect(parseKeywords('  '), defaultSafetyKeywords);
    expect(
      needsSafetyRecheck(
        category: ReportCategory.fallenTree,
        severity: Severity.urgent,
        description: 'flames everywhere',
        keywords: parseKeywords('flame'),
      ),
      isTrue,
    );
  });
}
