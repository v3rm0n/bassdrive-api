import 'package:bassdrive_api/bassdrive_api.dart';
import 'package:test/test.dart';

void main() {
  test('generate', () async {
    expect(await generateJSON(), 42);
  });
}