class KnownLocation {
  final int? id;
  final String addressKey;
  final String street;
  final String houseNumber;
  final String type;
  final String name;
  final double? latitude;
  final double? longitude;
  final int uses;

  const KnownLocation({
    this.id,
    required this.addressKey,
    required this.street,
    required this.houseNumber,
    required this.type,
    required this.name,
    this.latitude,
    this.longitude,
    this.uses = 1,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'address_key': addressKey,
      'street': street,
      'house_number': houseNumber,
      'type': type,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'uses': uses,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory KnownLocation.fromMap(Map<String, Object?> map) {
    return KnownLocation(
      id: map['id'] as int?,
      addressKey: map['address_key'] as String,
      street: map['street'] as String,
      houseNumber: map['house_number'] as String,
      type: map['type'] as String,
      name: map['name'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      uses: map['uses'] as int? ?? 1,
    );
  }
}
