import 'dart:async';
import 'dart:html' as html;

Timer? _introPointerWatchTimer;

void _applyIntroPointerBlock() {
  const selectors = ['video', 'flt-platform-view'];
  for (final selector in selectors) {
    for (final element in html.document.querySelectorAll(selector)) {
      element.style.pointerEvents = 'none';
    }
  }
}

void startIntroVideoPointerFix() {
  _applyIntroPointerBlock();
  _introPointerWatchTimer?.cancel();
  _introPointerWatchTimer = Timer.periodic(
    const Duration(milliseconds: 250),
    (_) => _applyIntroPointerBlock(),
  );
}

void stopIntroVideoPointerFix() {
  _introPointerWatchTimer?.cancel();
  _introPointerWatchTimer = null;
  restoreIntroVideoPointerEvents();
}

void disableIntroVideoPointerEvents() {
  _applyIntroPointerBlock();
}

void restoreIntroVideoPointerEvents() {
  const selectors = ['video', 'flt-platform-view'];
  for (final selector in selectors) {
    for (final element in html.document.querySelectorAll(selector)) {
      element.style.pointerEvents = 'auto';
    }
  }
}
