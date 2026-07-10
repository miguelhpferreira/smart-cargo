import 'screens/ ocr_test_page.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationDatabase.instance.database;

  runApp(const SmartCargoApp());
}

class SmartCargoApp extends StatelessWidget {
  const SmartCargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cargo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// MODELOS
// ============================================================

class DeliveryStop {
  final int number;
  final String name;
  final String street;
  final String houseNumber;
  final String type;
  final List<String> packageCodes;
  final bool knownLocation;

  DeliveryStop({
    required this.number,
    required this.name,
    required this.street,
    required this.houseNumber,
    required this.type,
    required this.packageCodes,
    required this.knownLocation,
  });

  int get packages => packageCodes.length;

  String get address {
    final cleanStreet = street.trim();

    if (cleanStreet.toLowerCase().startsWith('rua ') ||
        cleanStreet.toLowerCase().startsWith('avenida ') ||
        cleanStreet.toLowerCase().startsWith('av. ')) {
      return '$cleanStreet, $houseNumber';
    }

    return 'Rua $cleanStreet, $houseNumber';
  }
}

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
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      uses: map['uses'] as int? ?? 1,
    );
  }
}

class ManualEntryResult {
  final String street;
  final String houseNumber;
  final String type;
  final String name;

  const ManualEntryResult({
    required this.street,
    required this.houseNumber,
    required this.type,
    required this.name,
  });
}

// ============================================================
// NORMALIZAÇÃO DE ENDEREÇO
// ============================================================

String normalizeAddressPart(String value) {
  var normalized = value.toLowerCase().trim();

  const replacements = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  replacements.forEach((original, replacement) {
    normalized = normalized.replaceAll(original, replacement);
  });

  normalized = normalized
      .replaceFirst(RegExp(r'^rua\s+'), '')
      .replaceFirst(RegExp(r'^r\.\s*'), '')
      .replaceFirst(RegExp(r'^avenida\s+'), '')
      .replaceFirst(RegExp(r'^av\.\s*'), '')
      .replaceFirst(RegExp(r'^av\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return normalized;
}

String createAddressKey(String street, String number) {
  return '${normalizeAddressPart(street)}|${normalizeAddressPart(number)}';
}

// ============================================================
// BANCO LOCAL
// ============================================================

class LocationDatabase {
  LocationDatabase._();

  static final LocationDatabase instance = LocationDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databaseFolder = await getDatabasesPath();
    final databasePath = path.join(databaseFolder, 'smart_cargo.db');

    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE known_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            address_key TEXT NOT NULL UNIQUE,
            street TEXT NOT NULL,
            house_number TEXT NOT NULL,
            type TEXT NOT NULL,
            name TEXT NOT NULL DEFAULT '',
            latitude REAL,
            longitude REAL,
            uses INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<KnownLocation?> findLocation(
    String street,
    String houseNumber,
  ) async {
    final db = await database;
    final addressKey = createAddressKey(street, houseNumber);

    final result = await db.query(
      'known_locations',
      where: 'address_key = ?',
      whereArgs: [addressKey],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return KnownLocation.fromMap(result.first);
  }

  Future<KnownLocation> saveOrUpdateLocation({
    required String street,
    required String houseNumber,
    required String type,
    required String name,
  }) async {
    final db = await database;
    final addressKey = createAddressKey(street, houseNumber);
    final existing = await findLocation(street, houseNumber);
    final now = DateTime.now().toIso8601String();

    if (existing == null) {
      final id = await db.insert(
        'known_locations',
        {
          'address_key': addressKey,
          'street': street.trim(),
          'house_number': houseNumber.trim(),
          'type': type,
          'name': name.trim(),
          'uses': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return KnownLocation(
        id: id,
        addressKey: addressKey,
        street: street.trim(),
        houseNumber: houseNumber.trim(),
        type: type,
        name: name.trim(),
      );
    }

    final updatedUses = existing.uses + 1;

    await db.update(
      'known_locations',
      {
        'street': street.trim(),
        'house_number': houseNumber.trim(),
        'type': type,
        'name': name.trim(),
        'uses': updatedUses,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [existing.id],
    );

    return KnownLocation(
      id: existing.id,
      addressKey: addressKey,
      street: street.trim(),
      houseNumber: houseNumber.trim(),
      type: type,
      name: name.trim(),
      latitude: existing.latitude,
      longitude: existing.longitude,
      uses: updatedUses,
    );
  }

  Future<int> countKnownLocations() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM known_locations',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}

// ============================================================
// TELA PRINCIPAL
// ============================================================

SizedBox(
  width: double.infinity,
  height: 56,
  child: FilledButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OcrTestPage(),
        ),
      );
    },
    icon: const Icon(Icons.document_scanner),
    label: const Text('Testar OCR da etiqueta'),
  ),
),
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<DeliveryStop> stops = [];

  DeliveryStop? lastStop;
  int knownLocationsCount = 0;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    loadKnownLocationsCount();
  }

  int get totalPackages {
    return stops.fold(
      0,
      (total, stop) => total + stop.packageCodes.length,
    );
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

  Future<void> loadKnownLocationsCount() async {
    final total = await LocationDatabase.instance.countKnownLocations();

    if (!mounted) return;

    setState(() {
      knownLocationsCount = total;
    });
  }

  Future<void> addPackage({
    required String code,
    required String street,
    required String houseNumber,
    required String type,
    required String name,
    bool saveInMemory = true,
  }) async {
    if (processing) return;

    setState(() {
      processing = true;
    });

    try {
      final knownLocation = await LocationDatabase.instance.findLocation(
        street,
        houseNumber,
      );

      final effectiveStreet = knownLocation?.street ?? street.trim();
      final effectiveNumber =
          knownLocation?.houseNumber ?? houseNumber.trim();
      final effectiveType = knownLocation?.type ?? type;

      final suppliedName = name.trim();
      final savedName = knownLocation?.name.trim() ?? '';

      final effectiveName = suppliedName.isNotEmpty
          ? suppliedName
          : savedName.isNotEmpty
              ? savedName
              : effectiveType;

      final newKey = createAddressKey(
        effectiveStreet,
        effectiveNumber,
      );

      DeliveryStop? existingStop;

      for (final stop in stops) {
        final existingKey = createAddressKey(
          stop.street,
          stop.houseNumber,
        );

        if (existingKey == newKey) {
          existingStop = stop;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        if (existingStop != null) {
          if (!existingStop!.packageCodes.contains(code)) {
            existingStop!.packageCodes.add(code);
          }

          lastStop = existingStop;
        } else {
          final newStop = DeliveryStop(
            number: stops.length + 1,
            name: effectiveName,
            street: effectiveStreet,
            houseNumber: effectiveNumber,
            type: effectiveType,
            packageCodes: [code],
            knownLocation: knownLocation != null,
          );

          stops.add(newStop);
          lastStop = newStop;
        }
      });

      if (saveInMemory) {
        await LocationDatabase.instance.saveOrUpdateLocation(
          street: effectiveStreet,
          houseNumber: effectiveNumber,
          type: effectiveType,
          name: effectiveName == effectiveType ? '' : effectiveName,
        );

        await loadKnownLocationsCount();
      }
    } finally {
      if (mounted) {
        setState(() {
          processing = false;
        });
      }
    }
  }

  Future<void> openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(),
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.isEmpty) {
      return;
    }

    // O código de barras identifica o pacote.
    // Até ligarmos o OCR, pedimos somente o endereço.
    final manualResult = await Navigator.push<ManualEntryResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualEntryPage(
          title: 'Endereço do pacote',
        ),
      ),
    );

    if (!mounted || manualResult == null) {
      return;
    }

    await addPackage(
      code: scannedCode,
      street: manualResult.street,
      houseNumber: manualResult.houseNumber,
      type: manualResult.type,
      name: manualResult.name,
    );
  }

  Future<void> openManualEntry() async {
    final result = await Navigator.push<ManualEntryResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualEntryPage(
          title: 'Inserir manualmente',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final packageCode =
        'manual-${DateTime.now().millisecondsSinceEpoch}';

    await addPackage(
      code: packageCode,
      street: result.street,
      houseNumber: result.houseNumber,
      type: result.type,
      name: result.name,
    );
  }

  Future<void> resetLoad() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reiniciar carga?'),
          content: const Text(
            'Os pacotes e paradas desta carga serão apagados. '
            'A memória de endereços conhecidos continuará salva.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reiniciar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      stops.clear();
      lastStop = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStop = lastStop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Cargo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              const Text(
                'A inteligência por trás da rota',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _InfoCard(
                    title: 'Pacotes',
                    value: totalPackages,
                  ),
                  const SizedBox(width: 8),
                  _InfoCard(
                    title: 'Paradas',
                    value: stops.length,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  _InfoCard(
                    title: 'Condomínios',
                    value: condominiums,
                    compact: true,
                  ),
                  const SizedBox(width: 8),
                  _InfoCard(
                    title: 'Residências',
                    value: residences,
                    compact: true,
                  ),
                  const SizedBox(width: 8),
                  _InfoCard(
                    title: 'Comércios',
                    value: commerces,
                    compact: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.memory,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$knownLocationsCount locais na memória',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                ),
                child: currentStop == null
                    ? const Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum pacote lido',
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Escaneie ou insira manualmente',
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                currentStop.knownLocation
                                    ? Icons.check_circle
                                    : Icons.fiber_new,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentStop.knownLocation
                                    ? 'LOCAL CONHECIDO'
                                    : 'NOVO LOCAL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ESCREVA NO PACOTE',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${currentStop.number}',
                            style: const TextStyle(
                              fontSize: 82,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentStop.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentStop.address,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentStop.packages} pacote(s) nesta parada',
                            style: const TextStyle(fontSize: 17),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: processing ? null : openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear pacote'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: processing ? null : openManualEntry,
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Inserir manualmente'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: stops.isEmpty || processing
                      ? null
                      : resetLoad,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar carga'),
                ),
              ),

              if (processing) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],

              if (stops.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Paradas da carga',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  itemCount: stops.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final stop = stops[index];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${stop.number}'),
                        ),
                        title: Text(
                          stop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(stop.address),
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              '${stop.packages}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('pacotes'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INSERÇÃO MANUAL
// ============================================================

class ManualEntryPage extends StatefulWidget {
  final String title;

  const ManualEntryPage({
    super.key,
    required this.title,
  });

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final nameController = TextEditingController();

  String selectedType = 'Residência';
  bool checkingAddress = false;
  KnownLocation? existingLocation;

  @override
  void dispose() {
    streetController.dispose();
    numberController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> checkKnownAddress() async {
    final street = streetController.text.trim();
    final number = numberController.text.trim();

    if (street.isEmpty || number.isEmpty) {
      return;
    }

    setState(() {
      checkingAddress = true;
    });

    final location = await LocationDatabase.instance.findLocation(
      street,
      number,
    );

    if (!mounted) return;

    setState(() {
      checkingAddress = false;
      existingLocation = location;

      if (location != null) {
        streetController.text = location.street;
        numberController.text = location.houseNumber;
        selectedType = location.type;
        nameController.text = location.name;
      }
    });
  }

  void save() {
    final street = streetController.text.trim();
    final number = numberController.text.trim();

    if (street.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a rua e o número'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ManualEntryResult(
        street: street,
        houseNumber: number,
        type: selectedType,
        name: nameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const types = [
      'Residência',
      'Condomínio',
      'Comércio',
      'Outro',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: streetController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Rua',
                  hintText: 'Ex.: Rua 17',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.signpost),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: numberController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => checkKnownAddress(),
                decoration: const InputDecoration(
                  labelText: 'Número',
                  hintText: 'Ex.: 50',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed:
                    checkingAddress ? null : checkKnownAddress,
                icon: checkingAddress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: const Text('Verificar na memória'),
              ),

              if (existingLocation != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  child: const ListTile(
                    leading: Icon(Icons.check_circle),
                    title: Text('Local conhecido'),
                    subtitle: Text(
                      'Os dados salvos foram preenchidos automaticamente.',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Text(
                'Tipo do local',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((type) {
                  IconData icon;

                  switch (type) {
                    case 'Condomínio':
                      icon = Icons.apartment;
                      break;
                    case 'Comércio':
                      icon = Icons.storefront;
                      break;
                    case 'Outro':
                      icon = Icons.place;
                      break;
                    default:
                      icon = Icons.home;
                  }

                  return ChoiceChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(type),
                    selected: selectedType == type,
                    onSelected: (_) {
                      setState(() {
                        selectedType = type;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome do local (opcional)',
                  hintText: 'Ex.: HM Smart',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar parada'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SCANNER
// ============================================================

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool hasScanned = false;

  void onDetect(BarcodeCapture capture) {
    if (hasScanned || capture.barcodes.isEmpty) {
      return;
    }

    final code = capture.barcodes.first.rawValue;

    if (code == null || code.trim().isEmpty) {
      return;
    }

    hasScanned = true;
    Navigator.pop(context, code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear pacote'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: onDetect,
          ),
          Center(
            child: Container(
              width: 300,
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Text(
              'Aponte para o código de barras ou QR Code da etiqueta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTES
// ============================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final int value;
  final bool compact;

  const _InfoCard({
    required this.title,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: compact ? 12 : 16,
          ),
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: compact ? 25 : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}