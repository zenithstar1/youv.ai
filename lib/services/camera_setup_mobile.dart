import 'package:flutter/foundation.dart';
import 'package:camera_android/camera_android.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';

/// Registers the Camera2 API implementation on Android.
///
/// CameraX (the default camera_android_camerax backend) has a known bug on
/// certain Samsung devices running Android 15 where ImageAnalysis stays
/// INACTIVE after startImageStream(), preventing face-detection frames from
/// arriving.  Camera2 does not have this issue.
void setupAndroidCamera() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    CameraPlatform.instance = AndroidCamera();
  }
}
