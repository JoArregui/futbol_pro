import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_pro/core/consts.dart';

void main() {
  test('AppConsts.baseUrl no está vacío y es http', () {
    expect(AppConsts.baseUrl, isNotEmpty);
    expect(AppConsts.baseUrl, startsWith('http'));
  });

  test('AppConsts.baseUrl default contiene /api/v1', () {
    expect(AppConsts.baseUrl, contains('/api/v1'));
  });
}
