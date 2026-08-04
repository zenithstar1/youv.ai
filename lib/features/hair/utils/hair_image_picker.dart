import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class HairPickedImage {
  final Uint8List bytes;
  final String fileName;

  const HairPickedImage({required this.bytes, required this.fileName});
}

class HairSoftValidation {
  final bool isEmpty;
  final bool maybeDark;
  final bool maybeBlurry;
  final String? tip;

  const HairSoftValidation({
    required this.isEmpty,
    required this.maybeDark,
    required this.maybeBlurry,
    this.tip,
  });

  bool get hasSoftWarning => maybeDark || maybeBlurry;
}

class HairImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<HairPickedImage?> fromGallery() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final f = result.files.first;
      if (f.bytes == null || f.bytes!.isEmpty) return null;
      return HairPickedImage(
        bytes: f.bytes!,
        fileName: f.name.isEmpty ? 'upload.jpg' : f.name,
      );
    }

    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) return null;
    return HairPickedImage(
      bytes: bytes,
      fileName: x.name.isEmpty ? 'upload.jpg' : x.name,
    );
  }

  static Future<HairPickedImage?> fromCamera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 92,
      );
      if (x == null) return null;
      final bytes = await x.readAsBytes();
      if (bytes.isEmpty) return null;
      return HairPickedImage(
        bytes: bytes,
        fileName: x.name.isEmpty ? 'capture.jpg' : x.name,
      );
    } catch (_) {
      // Camera unavailable (common on desktop web) — fall back to gallery.
      return fromGallery();
    }
  }

  /// Soft client-side checks — never hard-blocks unless empty.
  static HairSoftValidation validate(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const HairSoftValidation(
        isEmpty: true,
        maybeDark: false,
        maybeBlurry: false,
        tip: 'Image is empty. Please choose another photo.',
      );
    }

    bool maybeDark = false;
    bool maybeBlurry = false;
    String? tip;

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final sample = img.copyResize(decoded, width: 64);
        var sum = 0;
        var count = 0;
        var edge = 0;
        for (var y = 1; y < sample.height - 1; y += 2) {
          for (var x = 1; x < sample.width - 1; x += 2) {
            final p = sample.getPixel(x, y);
            final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
            sum += lum;
            count++;
            final left = sample.getPixel(x - 1, y);
            final leftLum =
                (0.299 * left.r + 0.587 * left.g + 0.114 * left.b).round();
            edge += (lum - leftLum).abs();
          }
        }
        if (count > 0) {
          final avg = sum / count;
          maybeDark = avg < 45;
          final avgEdge = edge / count;
          maybeBlurry = avgEdge < 6;
        }
      }
    } catch (_) {}

    if (maybeDark && maybeBlurry) {
      tip = 'Photo looks dark and soft — try brighter light and hold steady.';
    } else if (maybeDark) {
      tip = 'Photo looks dark — try even lighting for clearer scalp detail.';
    } else if (maybeBlurry) {
      tip = 'Photo may be soft/blurry — hold steady and retake if needed.';
    }

    return HairSoftValidation(
      isEmpty: false,
      maybeDark: maybeDark,
      maybeBlurry: maybeBlurry,
      tip: tip,
    );
  }

  /// True when API view_type roughly matches the slot the user filled.
  static bool viewMatchesSlot(String expectedSlot, String apiViewType) {
    final a = expectedSlot.toLowerCase();
    final b = apiViewType.toLowerCase();
    if (b.isEmpty) return true;
    if (a.contains('front')) return b.contains('front');
    if (a.contains('left')) return b.contains('left');
    if (a.contains('right')) return b.contains('right');
    if (a.contains('top') || a.contains('crown') || a.contains('back')) {
      return b.contains('top') ||
          b.contains('crown') ||
          b.contains('back') ||
          b.contains('vertex');
    }
    return true;
  }
}
