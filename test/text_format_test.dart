import 'package:flutter_test/flutter_test.dart';
import 'package:sync_month/utils/text_format.dart';

void main() {
  test('sentenceCase capitalizes the first letter only', () {
    expect(sentenceCase('parking'), 'Parking');
    expect(sentenceCase('house renting'), 'House renting');
    expect(sentenceCase('  parking  '), 'Parking');
    expect(sentenceCase('Parking'), 'Parking');
    expect(sentenceCase(''), '');
  });
}
