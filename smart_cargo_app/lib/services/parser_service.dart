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
    final address = _findAddress(lines);

    final street = address?.street ?? '';
    final houseNumber = address?.houseNumber ?? '';

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
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
  }

  _AddressResult? _findAddress(List<String> lines) {
    // Primeiro tenta localizar o endereço em cada linha individual.
    for (final line in lines) {
      final result = _extractAddressFromLine(line);

      if (result != null) {
        return result;
      }
    }

    // Depois combina até três linhas consecutivas.
    for (var index = 0; index < lines.length; index++) {
      final buffer = <String>[lines[index]];

      if (index + 1 < lines.length) {
        buffer.add(lines[index + 1]);
      }

      if (index + 2 < lines.length) {
        buffer.add(lines[index + 2]);
      }

      final result = _extractAddressFromLine(buffer.join(' '));

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  _AddressResult? _extractAddressFromLine(String originalLine) {
    var line = originalLine
        .replaceAll(RegExp(r'\bN[º°oO0]\.?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Evita interpretar endereço do remetente.
    final lower = line.toLowerCase();

    if (lower.contains('dock ') ||
        lower.contains('remetente') ||
        lower.contains('guarulhos') && !lower.contains('destinat')) {
      return null;
    }

    final prefixMatch = RegExp(
      r'\b(Rua|R\.?|Avenida|Av\.?|Travessa|Tv\.?|Alameda|Estrada|Rodovia)\s+',
      caseSensitive: false,
    ).firstMatch(line);

    if (prefixMatch == null) {
      return null;
    }

    line = line.substring(prefixMatch.start).trim();

    final streetPrefix = prefixMatch.group(1) ?? 'Rua';

    // Rua 17, 50
    // Rua Wilson Vasco Mazon, 402, Remanso
    // Rua Rodrigo Carvalho, 200, Parque Ortolândia
    final commaPattern = RegExp(
      r'^(Rua|R\.?|Avenida|Av\.?|Travessa|Tv\.?|Alameda|Estrada|Rodovia)\s+'
      r'(.+?)[,;]\s*(\d{1,6}[A-Za-z]?)\b',
      caseSensitive: false,
    );

    final commaMatch = commaPattern.firstMatch(line);

    if (commaMatch != null) {
      final streetBody = commaMatch.group(2)?.trim() ?? '';
      final number = commaMatch.group(3)?.trim() ?? '';

      if (_validStreet(streetBody) && _validNumber(number)) {
        return _AddressResult(
          street: _normalizeStreet('$streetPrefix $streetBody'),
          houseNumber: number,
        );
      }
    }

    // Formato sem vírgula:
    // R. Capitao Joao Goncalves 116
    final simplePattern = RegExp(
      r'^(Rua|R\.?|Avenida|Av\.?|Travessa|Tv\.?|Alameda|Estrada|Rodovia)\s+'
      r'(.+?)\s+(\d{1,6}[A-Za-z]?)\b',
      caseSensitive: false,
    );

    final simpleMatches = simplePattern.allMatches(line).toList();

    if (simpleMatches.isNotEmpty) {
      // Usa a última correspondência válida para não confundir "Rua 17".
      for (final match in simpleMatches.reversed) {
        final streetBody = match.group(2)?.trim() ?? '';
        final number = match.group(3)?.trim() ?? '';

        if (_validStreet(streetBody) && _validNumber(number)) {
          return _AddressResult(
            street: _normalizeStreet('$streetPrefix $streetBody'),
            houseNumber: number,
          );
        }
      }
    }

    // Caso com informações extras:
    // Rua 17, Cond Hm Smart 2, AP 13, BL D, 50, 530...
    final numbers = RegExp(r'(?<!\d)(\d{1,6}[A-Za-z]?)(?!\d)')
        .allMatches(line)
        .map((match) => match.group(1) ?? '')
        .where(_validNumber)
        .toList();

    if (numbers.length >= 2) {
      final firstComma = line.indexOf(',');

      if (firstComma > 0) {
        final street = line.substring(0, firstComma).trim();

        // Prefere números depois de marcadores AP/BL/condomínio.
        // O penúltimo costuma ser o número da residência.
        final number = numbers.length >= 3
            ? numbers[numbers.length - 2]
            : numbers.last;

        if (_validStreet(street) && _validNumber(number)) {
          return _AddressResult(
            street: _normalizeStreet(street),
            houseNumber: number,
          );
        }
      }
    }

    return null;
  }

  bool _validStreet(String street) {
    final value = street.trim();

    if (value.length < 2) {
      return false;
    }

    return RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(value) ||
        RegExp(r'^\d{1,4}$').hasMatch(value);
  }

  bool _validNumber(String number) {
    final value = number.trim();

    if (!RegExp(r'^\d{1,6}[A-Za-z]?$').hasMatch(value)) {
      return false;
    }

    final numericPart = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));

    if (numericPart == null || numericPart <= 0) {
      return false;
    }

    // Evita anos e CEPs sendo usados como número da casa.
    if (numericPart >= 1900 && numericPart <= 2100) {
      return false;
    }

    return true;
  }

  String _normalizeStreet(String street) {
    var value = street.replaceAll(RegExp(r'\s+'), ' ').trim();

    value = value.replaceFirst(
      RegExp(r'^R\.?\s+', caseSensitive: false),
      'Rua ',
    );

    value = value.replaceFirst(
      RegExp(r'^Av\.?\s+', caseSensitive: false),
      'Avenida ',
    );

    value = value.replaceFirst(
      RegExp(r'^Tv\.?\s+', caseSensitive: false),
      'Travessa ',
    );

    return value;
  }

  String _findPostalCode(String text) {
    final match = RegExp(
      r'\b(\d{5})[\s.\-]?(\d{3})\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (match == null) {
      return '';
    }

    return '${match.group(1)}-${match.group(2)}';
  }

  String _detectCarrier(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('shein')) {
      return 'Shein';
    }

    if (normalized.contains('imile') ||
        normalized.contains('i mile') ||
        normalized.contains('imile')) {
      return 'iMile';
    }

    if (normalized.contains('fm transportes')) {
      return 'FM Transportes';
    }

    if (normalized.contains('tiktok') || normalized.contains('tik tok')) {
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

  const _AddressResult({required this.street, required this.houseNumber});
}
