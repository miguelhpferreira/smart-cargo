import 'package:flutter/foundation.dart';
import '../models/delivery_stop.dart';
import '../services/database_service.dart';

class HomeController extends ChangeNotifier {
  DeliveryStop? lastStop;
  DeliveryStop? get nextPendingStop {
  for (final stop in stops) {
    if (!stop.delivered) {
      return stop;
    }
  }
  return null;
}
  int _knownLocationsCount = 0;

  int get knownLocationsCount => _knownLocationsCount;

  final DatabaseService databaseService;

  HomeController({DatabaseService? databaseService})
    : databaseService = databaseService ?? DatabaseService.instance;
  final List<DeliveryStop> stops = [];
  bool _processing = false;

  bool get processing => _processing;

  void setProcessing(bool value) {
    if (_processing == value) return;
    _processing = value;
    notifyListeners();
  }

  void confirmDelivery(DeliveryStop stop) {
    if (stop.delivered) return;

    stop.delivered = true;
    stop.deliveredAt = DateTime.now();

    DeliveryStop? nextStop;

    final currentIndex = stops.indexOf(stop);

    for (var index = currentIndex + 1; index < stops.length; index++) {
      if (!stops[index].delivered) {
        nextStop = stops[index];
        break;
      }
    }

    if (nextStop == null) {
      for (final item in stops) {
        if (!item.delivered) {
          nextStop = item;
          break;
        }
      }
    }

    lastStop = nextStop ?? stop;
    notifyListeners();
  }

  void undoDelivery(DeliveryStop stop) {
    if (!stop.delivered) return;

    stop.delivered = false;
    stop.deliveredAt = null;
    lastStop = stop;

    notifyListeners();
  }

  int get deliveredStops => stops.where((stop) => stop.delivered).length;

  int get remainingStops => stops.where((stop) => !stop.delivered).length;

  int get deliveredPackages => stops
      .where((stop) => stop.delivered)
      .fold(0, (total, stop) => total + stop.packages);

  int get remainingPackages => stops
      .where((stop) => !stop.delivered)
      .fold(0, (total, stop) => total + stop.packages);

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

  Future<void> loadKnownLocations() async {
    notifyListeners();
  }

  Future<void> loadKnownLocationsCount() async {
    _knownLocationsCount = await databaseService.countKnownLocations();
    notifyListeners();
  }

  void upsertStop({
    required String code,
    required String street,
    required String houseNumber,
    required String type,
    required String name,
    required bool knownLocation,
    required String Function(String street, String houseNumber)
    createAddressKey,
  }) {
    final newKey = createAddressKey(street, houseNumber);

    DeliveryStop? existingStop;

    for (final stop in stops) {
      final existingKey = createAddressKey(stop.street, stop.houseNumber);

      if (existingKey == newKey) {
        existingStop = stop;
        break;
      }
    }

    if (existingStop != null) {
      if (!existingStop.packageCodes.contains(code)) {
        existingStop.packageCodes.add(code);
      }

      lastStop = existingStop;
    } else {
      final newStop = DeliveryStop(
        number: stops.length + 1,
        name: name,
        street: street,
        houseNumber: houseNumber,
        type: type,
        packageCodes: [code],
        knownLocation: knownLocation,
      );

      stops.add(newStop);
      lastStop = newStop;
    }

    notifyListeners();
  }
}
