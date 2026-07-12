import 'package:flutter/foundation.dart';
import '../models/delivery_stop.dart';

class HomeController extends ChangeNotifier {
  final List<DeliveryStop> stops = [];
  bool _processing = false;

  bool get processing => _processing;

  void setProcessing(bool value) {
    if (_processing == value) return;
    _processing = value;
    notifyListeners();
  }

  int get totalPackages {
    return stops.fold(0, (total, stop) => total + stop.packageCodes.length);
  }

  int get condominiums {
    return stops.where((stop) => stop.type == 'Condomínio').length;
  }

  int get residences {
    return stops.where((stop) => stop.type == 'Residência').length;
  }

  int get commerces {
    return stops.where((stop) => stop.type == 'Comércio').length;
  }
}
