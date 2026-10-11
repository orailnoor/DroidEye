import 'package:droideye/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('layer ids are unique and exclude camera and military layers', () {
    final ids = [for (final g in layerGroups) ...g.layers.map((l) => l.id)];
    expect(ids.toSet().length, ids.length);
    for (final banned in [
      'cctv',
      'alpr-cameras',
      'military',
      'military-installations',
      'military-awareness',
    ]) {
      expect(ids, isNot(contains(banned)));
    }
  });
}
