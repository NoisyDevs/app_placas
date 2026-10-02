import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:placas/services/photo_normalizer.dart';

Uint8List _jpeg({int? orientation}) {
  final image = img.Image(width: 2, height: 1);
  if (orientation != null) image.exif.imageIfd.orientation = orientation;
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  test('orientation 6 is baked into pixels (2x1 becomes 1x2)', () {
    final input = _jpeg(orientation: 6);
    final output = normalizePhotoOrientationSync(input);

    expect(identical(output, input), isFalse);
    final decoded = img.decodeJpg(output)!;
    expect(decoded.width, 1);
    expect(decoded.height, 2);
    final orientation = decoded.exif.imageIfd.orientation;
    expect(orientation == null || orientation == 1, isTrue);
  });

  test('orientation 1 returns the identical instance', () {
    final input = _jpeg(orientation: 1);
    expect(identical(normalizePhotoOrientationSync(input), input), isTrue);
  });

  test('absent orientation returns the identical instance', () {
    final input = _jpeg();
    expect(identical(normalizePhotoOrientationSync(input), input), isTrue);
  });

  test('garbage bytes return the identical instance', () {
    final input = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
    expect(identical(normalizePhotoOrientationSync(input), input), isTrue);
  });

  test('empty bytes return the identical instance', () {
    final input = Uint8List(0);
    expect(identical(normalizePhotoOrientationSync(input), input), isTrue);
  });

  test('a PNG returns the identical instance', () {
    final input = Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 1)));
    expect(identical(normalizePhotoOrientationSync(input), input), isTrue);
  });

  test('async wrapper normalizes like the sync version', () async {
    final output = await normalizePhotoOrientation(_jpeg(orientation: 6));
    final decoded = img.decodeJpg(output)!;
    expect(decoded.width, 1);
    expect(decoded.height, 2);
  });
}
