import 'package:arquivolta/platform/win32/util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escapeStringForBash smoke test', () {
    expect(escapeStringForBash('ani'), 'ani');
    expect(escapeStringForBash('ani!'), r'ani\!');
    expect(escapeStringForBash('(ani)!'), r'\(ani\)\!');
  });
}
