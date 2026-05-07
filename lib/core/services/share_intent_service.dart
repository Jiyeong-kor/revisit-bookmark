import 'dart:async';

import 'package:flutter/services.dart';

class ShareIntentService {
  static const _channel = MethodChannel('revisit_bookmark/share');

  final _controller = StreamController<String>.broadcast();

  Stream<String> get sharedText => _controller.stream;

  ShareIntentService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _controller.add(text);
        }
      }
    });
  }

  /// 앱 콜드 스타트 시 공유 텍스트를 가져옵니다.
  Future<String?> getInitialSharedText() async {
    try {
      final text = await _channel.invokeMethod<String>('getSharedText');
      return (text?.isNotEmpty ?? false) ? text : null;
    } on PlatformException {
      return null;
    }
  }

  void dispose() {
    _controller.close();
  }
}
