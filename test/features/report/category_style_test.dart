import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/category_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every category has its own shape and color (FR-MAP-02)', () {
    const all = ReportCategory.values;
    expect(all.map((c) => c.shape).toSet(), hasLength(all.length));
    expect(all.map((c) => c.color).toSet(), hasLength(all.length));
  });

  test('marker colors hold 3:1 against the white icon', () {
    for (final c in ReportCategory.values) {
      final l = c.color.computeLuminance();
      expect(1.05 / (l + 0.05), greaterThanOrEqualTo(3), reason: c.name);
    }
  });

  testWidgets('markers render for every category', (tester) async {
    for (final c in ReportCategory.values) {
      for (final urgent in [false, true]) {
        final image = await renderMarker(
          c,
          urgent: urgent,
          logicalSize: 40,
          pixelRatio: 2,
        );
        expect(image.width, 80);
        image.dispose();
      }
    }
  });
}
