import 'package:flutter/foundation.dart';

class HomeController extends ChangeNotifier {
  bool _processing = false;

  bool get processing => _processing;

  void setProcessing(bool value) {
    if (_processing == value) return;
    _processing = value;
    notifyListeners();
  }
}
