export 'yamnet_classifier_native.dart'
    if (dart.library.js_interop) 'yamnet_classifier_web.dart'
    if (dart.library.html) 'yamnet_classifier_web.dart';
