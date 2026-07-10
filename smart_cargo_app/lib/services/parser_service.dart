import '../models/package_data.dart';

class ParserService {
  const ParserService();

  PackageData parse(String rawText) {
    final cleanedText = _cleanText(rawText);
    final lines = cleanedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final postalCode = _findPostalCode(cleanedText);
    final carrier = _detectCarrier(cleanedText);

    String street = '';
    String houseNumber = '';

    for (final line in lines) {
      final result = _extractAddressFromLine(line);

      if (result != null) {
        street = result.street;
        houseNumber = result.houseNumber;
        break;
      }
    }

    if (street.isEmpty || houseNumber.isEmpty) {
      final combinedResult = _extractAddressFromCombinedLines(lines);

      if (combinedResult != null) {
        street = combinedResult.street;
        houseNumber = combinedResult.houseNumber;
      }
    }

    final confidence = _calculateConfidence(
      street: street,
      houseNumber: houseNumber,
      postalCode: postalCode,
    );

    return PackageData(
      street: street,
      houseNumber: houseNumber,
      postalCode: postalCode,
      carrier: carrier,
      rawText: rawText,
      confidence: confidence,
    );
  }

  String _cleanText(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  String _findPostalCode(String text) {
    final match = RegExp(
      r'\b(\d{5})[-.\s]?(\d{3})\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (match == null) {
      return '';
    }

    return '${match.group(1)}-${match.group(2)}';
  }

  String _detectCarrier(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('imile')) {
      return 'iMile';
    }

    if (normalized.contains('shein')) {
      return 'Shein';
    }

    if (normalized.contains('tiktok') ||
        normalized.contains('tik tok')) {
      return 'TikTok Shop';
    }

    if (normalized.contains('olist')) {
      return 'Olist';
    }

    if (normalized.contains('kwai')) {
      return 'Kwai';
    }

    if (normalized.contains('shopee')) {
      return 'Shopee';
    }

    return 'Não identificada';
  }

  _AddressResult? _extractAddressFromLine(String line) {
    final normalizedLine = line
        .replaceAll(RegExp(r'\bN[º°o]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final pattern = RegExp(
      r'\b((?:Rua|R\.|Avenida|Av\.|Av|Travessa|Tv\.|Alameda|Estrada|Rodovia)\s+[A-Za-zÀ-ÿ0-9 .º°\-]+?)[,\s]+(\d+[A-Za-z]?)\b',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(normalizedLine);

    if (match == null) {
      return null;
    }

    final street = match.group(1)?.trim() ?? '';
    final number = match.group(2)?.trim() ?? '';

    if (street.isEmpty || number.isEmpty) {
      return null;
    }

    return _AddressResult(
      street: _normalizeStreetDisplay(street),
      houseNumber: number,
    );
  }

  _AddressResult? _extractAddressFromCombinedLines(
    List<String> lines,
  ) {
    for (var index = 0; index < lines.length - 1; index++) {
      final currentLine = lines[index];
      final nextLine = lines[index + 1];

      final hasStreetPrefix = RegExp(
        r'^(Rua|R\.|Avenida|Av\.|Av|Travessa|Tv\.|Alameda|Estrada|Rodovia)\b',
        caseSensitive: false,
      ).hasMatch(currentLine);

      if (!hasStreetPrefix) {
        continue;
      }

      final numberMatch = RegExp(
        r'^\s*(?:N[º°o]\s*)?(\d+[A-Za-z]?)\b',
        caseSensitive: false,
      ).firstMatch(nextLine);

      if (numberMatch == null) {
        continue;
      }

      return _AddressResult(
        street: _normalizeStreetDisplay(currentLine),
        houseNumber: numberMatch.group(1) ?? '',
      );
    }

    return null;
  }

  String _normalizeStreetDisplay(String street) {
    var value = street
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (RegExp(r'^r\.', caseSensitive: false).hasMatch(value)) {
      value = value.replaceFirst(
        RegExp(r'^r\.', caseSensitive: false),
        'Rua',
      );
    }

    if (RegExp(r'^av\.', caseSensitive: false).hasMatch(value)) {
      value = value.replaceFirst(
        RegExp(r'^av\.', caseSensitive: false),
        'Avenida',
      );
    }

    return value;
  }

  double _calculateConfidence({
    required String street,
    required String houseNumber,
    required String postalCode,
  }) {
    var score = 0.0;

    if (street.isNotEmpty) {
      score += 0.55;
    }

    if (houseNumber.isNotEmpty) {
      score += 0.35;
    }

    if (postalCode.isNotEmpty) {
      score += 0.10;
    }

    return score;
  }
}

class _AddressResult {
  final String street;
  final String houseNumber;

  const _AddressResult({
    required this.street,
    required this.houseNumber,
  });
}
