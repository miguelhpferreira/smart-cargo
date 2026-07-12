class DeliveryStop {
  final int number;
  final String name;
  final String street;
  final String houseNumber;
  final String type;
  final List<String> packageCodes;
  final bool knownLocation;

  bool delivered;
  DateTime? deliveredAt;

  DeliveryStop({
    required this.number,
    required this.name,
    required this.street,
    required this.houseNumber,
    required this.type,
    required this.packageCodes,
    required this.knownLocation,
    this.delivered = false,
    this.deliveredAt,
  });

  int get packages => packageCodes.length;

  String get address {
    final cleanStreet = street.trim();
    final lowerStreet = cleanStreet.toLowerCase();

    if (lowerStreet.startsWith('rua ') ||
        lowerStreet.startsWith('avenida ') ||
        lowerStreet.startsWith('av. ')) {
      return '$cleanStreet, $houseNumber';
    }

    return 'Rua $cleanStreet, $houseNumber';
  }
}
