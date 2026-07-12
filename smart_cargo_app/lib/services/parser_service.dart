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
        .replaceAllMapped(
          RegExp(r'\b(?:Aua|Rva|Ruo|Roa)\b', caseSensitive: false),
          (_) => 'Rua',
        )
        .replaceAllMapped(
          RegExp(r'\b(?:Avenida|Avenlda|Avenda|Av\.?)\b', caseSensitive: false),
          (_) => 'Avenida',
        )
        .trim();
  }

  String _findPostalCode(String text) {
    final directMatch = RegExp(
      r'\b(\d{5})[-.\s]?(\d{3})\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (directMatch != null) {
      return '${directMatch.group(1)}-${directMatch.group(2)}';
    }

    // Aceita erros do OCR, como D no lugar de 0:
    // 13184-D81 -> 13184-081
    final ocrMatch = RegExp(
      r'\b(?:CEP\s*[:.]?\s*)?([0-9OQDISBLZG]{5})[-.\s]?([0-9OQDISBLZG]{3})\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (ocrMatch == null) {
      return '';
    }

    final firstPart = _correctOcrDigits(ocrMatch.group(1) ?? '');
    final secondPart = _correctOcrDigits(ocrMatch.group(2) ?? '');

    if (firstPart.length != 5 ||
        secondPart.length != 3 ||
        !RegExp(r'^\d+$').hasMatch(firstPart) ||
        !RegExp(r'^\d+$').hasMatch(secondPart)) {
      return '';
    }

    return '$firstPart-$secondPart';
  }

  String _correctOcrDigits(String value) {
    return value
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('G', '6')
        .replaceAll('B', '8');
  }

  String _detectCarrier(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('imile') || normalized.contains('i mile')) {
      return 'iMile';
    }

    if (normalized.contains('shein')) {
      return 'Shein';
    }

    if (normalized.contains('shopee')) {
      return 'Shopee';
    }

    if (normalized.contains('mercado livre') ||
        normalized.contains('mercadolivre')) {
      return 'Mercado Livre';
    }

    if (normalized.contains('amazon')) {
      return 'Amazon';
    }

    if (normalized.contains('tiktok') || normalized.contains('tik tok')) {
      return 'TikTok Shop';
    }

    if (normalized.contains('kwai')) {
      return 'Kwai';
    }

    if (normalized.contains('olist')) {
      return 'Olist';
    }

    if (normalized.contains('correios')) {
      return 'Correios';
    }

    if (normalized.contains('jadlog')) {
      return 'Jadlog';
    }

    return 'Não identificada';
  }

  _AddressResult? _findAddress(List<String> lines) {
    if (lines.isEmpty) {
      return null;
    }

    final destinationLines = _destinationSection(lines);

    // Primeiro procura dentro do bloco do destinatário.
    final destinationResult = _findAddressInLines(destinationLines);

    if (destinationResult != null) {
      return destinationResult;
    }

    // Se o bloco não estiver bem definido, procura no texto todo,
    // mas para antes do remetente.
    final safeLines = <String>[];

    for (final line in lines) {
      if (_isSenderMarker(line)) {
        break;
      }

      safeLines.add(line);
    }

    return _findAddressInLines(safeLines);
  }

  List<String> _destinationSection(List<String> lines) {
    final result = <String>[];
    var insideDestination = false;

    for (final line in lines) {
      final normalized = _normalizeForComparison(line);

      if (normalized.contains('destinatario') ||
          normalized.contains('destino')) {
        insideDestination = true;
        continue;
      }

      if (insideDestination && _isSenderMarker(line)) {
        break;
      }

      if (insideDestination) {
        result.add(line);
      }
    }

    return result;
  }

  bool _isSenderMarker(String line) {
    final normalized = _normalizeForComparison(line);

    return normalized.contains('remetente') ||
        normalized == 'sender' ||
        normalized.contains('dados do remetente');
  }

  _AddressResult? _findAddressInLines(List<String> lines) {
    for (final line in lines) {
      final result = _extractAddressFromLine(line);

      if (result != null) {
        return result;
      }
    }

    // O OCR pode separar a rua e o número em linhas diferentes.
    for (var index = 0; index < lines.length - 1; index++) {
      final currentLine = lines[index];
      final nextLine = lines[index + 1];

      final streetOnly = _extractStreetOnly(currentLine);

      if (streetOnly == null) {
        continue;
      }

      final number = _extractNumberAtStart(nextLine);

      if (number.isEmpty) {
        continue;
      }

      return _AddressResult(street: streetOnly, houseNumber: number);
    }

    return null;
  }

  _AddressResult? _extractAddressFromLine(String line) {
    var normalizedLine = line
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\bN[º°o]\s*', caseSensitive: false), '')
        .trim();

    normalizedLine = normalizedLine.replaceFirst(
      RegExp(r'^(?:Aua|Rva|Ruo|Roa)\b', caseSensitive: false),
      'Rua',
    );

    final pattern = RegExp(
      r'\b('
      r'(?:Rua|R\.?|Avenida|Av\.?|Travessa|Tv\.?|Alameda|Estrada|Rodovia)'
      r'\s+'
      r'[A-Za-zÀ-ÿ0-9 .'
      '-]{2,}?)'
      r'\s*[,;:-]\s*'
      r'(\d{1,6}[A-Za-z]?)'
      r'\b',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(normalizedLine);

    if (match != null) {
      final street = _normalizeStreetDisplay(match.group(1) ?? '');
      final number = match.group(2)?.trim() ?? '';

      if (_validStreet(street) && number.isNotEmpty) {
        return _AddressResult(street: street, houseNumber: number);
      }
    }

    // Aceita endereço sem vírgula:
    // Rua Wilson Vasco Mazon 402
    final loosePattern = RegExp(
      r'\b('
      r'(?:Rua|R\.?|Avenida|Av\.?|Travessa|Tv\.?|Alameda|Estrada|Rodovia)'
      r'\s+'
      r'[A-Za-zÀ-ÿ0-9 .'
      '-]{3,}?)'
      r'\s+'
      r'(\d{1,6}[A-Za-z]?)'
      r'\b',
      caseSensitive: false,
    );

    final looseMatch = loosePattern.firstMatch(normalizedLine);

    if (looseMatch == null) {
      return null;
    }

    final street = _normalizeStreetDisplay(looseMatch.group(1) ?? '');
    final number = looseMatch.group(2)?.trim() ?? '';

    if (!_validStreet(street) || number.isEmpty) {
      return null;
    }

    return _AddressResult(street: street, houseNumber: number);
  }

  String? _extractStreetOnly(String line) {
    var value = line.replaceAll(RegExp(r'\s+'), ' ').trim();

    value = value.replaceFirst(
      RegExp(r'^(?:Aua|Rva|Ruo|Roa)\b', caseSensitive: false),
      'Rua',
    );

    final match = RegExp(
      r'^('
      r'(?:Rua|R\.?|Avenida|Av\.?|Travessa|Tv\.?|Alameda|Estrada|Rodovia)'
      r'\s+'
      r"[A-Za-zÀ-ÿ0-9 .'-]{3,}"
      r')$',
      caseSensitive: false,
    ).firstMatch(value);

    if (match == null) {
      return null;
    }

    final street = _normalizeStreetDisplay(match.group(1) ?? '');

    return _validStreet(street) ? street : null;
  }

  String _extractNumberAtStart(String line) {
    final match = RegExp(
      r'^\s*(?:N[º°o]\s*)?(\d{1,6}[A-Za-z]?)\b',
      caseSensitive: false,
    ).firstMatch(line);

    return match?.group(1)?.trim() ?? '';
  }

  String _normalizeStreetDisplay(String street) {
    var value = street.replaceAll(RegExp(r'\s+'), ' ').trim();

    value = value.replaceFirst(
      RegExp(r'^(?:R\.?|Aua|Rva|Ruo|Roa)\s+', caseSensitive: false),
      'Rua ',
    );

    value = value.replaceFirst(
      RegExp(r'^(?:Av\.?|Avenlda|Avenda)\s+', caseSensitive: false),
      'Avenida ',
    );

    value = value.replaceFirst(
      RegExp(r'^Tv\.?\s+', caseSensitive: false),
      'Travessa ',
    );

    return value.trim();
  }

  bool _validStreet(String street) {
    final normalized = _normalizeForComparison(street);

    if (normalized.length < 5) {
      return false;
    }

    const forbiddenWords = [
      'remetente',
      'destinatario',
      'pedido',
      'cep',
      'transportadora',
      'data de envio',
      'peso bruto',
      'referencia',
      'volume',
    ];

    return !forbiddenWords.any(normalized.contains);
  }

  String _normalizeForComparison(String value) {
    var normalized = value.toLowerCase();

    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ç': 'c',
    };

    replacements.forEach((original, replacement) {
      normalized = normalized.replaceAll(original, replacement);
    });

    return normalized
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
