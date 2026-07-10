import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/known_location.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databaseFolder = await getDatabasesPath();
    final databasePath = path.join(
      databaseFolder,
      'smart_cargo.db',
    );

    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: _createDatabase,
    );

    return _database!;
  }

  Future<void> _createDatabase(
    Database database,
    int version,
  ) async {
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
  }

  Future<KnownLocation?> findLocation({
    required String street,
    required String houseNumber,
  }) async {
    final db = await database;
    final addressKey = createAddressKey(
      street,
      houseNumber,
    );

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
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    final addressKey = createAddressKey(
      street,
      houseNumber,
    );

    final existing = await findLocation(
      street: street,
      houseNumber: houseNumber,
    );

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
          'latitude': latitude,
          'longitude': longitude,
          'uses': 1,
          'created_at': now,
          'updated_at': now,
        },
      );

      return KnownLocation(
        id: id,
        addressKey: addressKey,
        street: street.trim(),
        houseNumber: houseNumber.trim(),
        type: type,
        name: name.trim(),
        latitude: latitude,
        longitude: longitude,
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
        'latitude': latitude ?? existing.latitude,
        'longitude': longitude ?? existing.longitude,
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
      latitude: latitude ?? existing.latitude,
      longitude: longitude ?? existing.longitude,
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

  Future<void> saveCoordinates({
    required String street,
    required String houseNumber,
    required double latitude,
    required double longitude,
  }) async {
    final db = await database;

    final existing = await findLocation(
      street: street,
      houseNumber: houseNumber,
    );

    if (existing == null) {
      throw StateError(
        'O endereço precisa estar salvo antes de receber coordenadas.',
      );
    }

    await db.update(
      'known_locations',
      {
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [existing.id],
    );
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

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
    normalized = normalized.replaceAll(
      original,
      replacement,
    );
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

String createAddressKey(
  String street,
  String houseNumber,
) {
  return '${normalizeAddressPart(street)}|'
      '${normalizeAddressPart(houseNumber)}';
}
