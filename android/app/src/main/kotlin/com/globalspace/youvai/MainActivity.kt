package com.globalspace.youvai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register MediaPipe face detection plugin
        flutterEngine.plugins.add(MediaPipeFaceDetectorPlugin())
    }
}
