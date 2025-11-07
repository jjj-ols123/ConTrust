// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart';

import 'web_redirect_stub.dart'
    if (dart.library.html) 'web_redirect_web.dart' as web_redirect;

void redirectToUrl(String url) {
  if (kIsWeb) {
    web_redirect.redirectToUrl(url);
  }
}

