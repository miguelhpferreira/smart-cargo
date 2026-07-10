class PackageData {
  final String street;
  final String houseNumber;
  final String postalCode;
  final String carrier;
  final String rawText;
  final double confidence;

  const PackageData({
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.carrier,
    required this.rawText,
    required this.confidence,
  });

  bool get hasValidAddress {
    return street.trim().isNotEmpty &&
        houseNumber.trim().isNotEmpty;
  }

  String get fullAddress {
    if (postalCode.trim().isEmpty) {
      return '$street, $houseNumber';
    }

    return '$street, $houseNumber — CEP $postalCode';
  }
}
