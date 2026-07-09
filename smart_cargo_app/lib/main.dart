import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
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

class Stop {
  final int number;
  final String name;
  final String address;
  final String type;
  final List<String> packageCodes;

  Stop({
    required this.number,
    required this.name,
    required this.address,
    required this.type,
    required this.packageCodes,
  });

  int get packages => packageCodes.length;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Stop> stops = [];

  int get totalPackages =>
      stops.fold(0, (total, stop) => total + stop.packageCodes.length);

  int get condominiums =>
      stops.where((stop) => stop.type == 'Condomínio').length;

  int get residences =>
      stops.where((stop) => stop.type == 'Residência').length;

  Stop? lastStop;

  String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void addScannedPackage(String code) {
    // Por enquanto, sem OCR.
    // Todo pacote escaneado cai em uma parada teste.
    const address = 'Endereço lido pelo código';
    const name = 'Pacote escaneado';
    const type = 'Residência';

    final normalizedAddress = normalize(address);

    Stop? existingStop;

    for (final stop in stops) {
      if (normalize(stop.address) == normalizedAddress) {
        existingStop = stop;
        break;
      }
    }

    setState(() {
      if (existingStop != null) {
        if (!existingStop!.packageCodes.contains(code)) {
          existingStop!.packageCodes.add(code);
        }
        lastStop = existingStop;
      } else {
        final newStop = Stop(
          number: stops.length + 1,
          name: name,
          address: address,
          type: type,
          packageCodes: [code],
        );

        stops.add(newStop);
        lastStop = newStop;
      }
    });
  }

  Future<void> openScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      addScannedPackage(result);
    }
  }

  void resetLoad() {
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'A inteligência por trás da rota',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoCard(title: 'Pacotes', value: totalPackages),
                const SizedBox(width: 8),
                _InfoCard(title: 'Paradas', value: stops.length),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoCard(title: 'Condomínios', value: condominiums),
                const SizedBox(width: 8),
                _InfoCard(title: 'Residências', value: residences),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: currentStop == null
                  ? const Column(
                      children: [
                        Text(
                          'Nenhum pacote lido',
                          style: TextStyle(fontSize: 22),
                        ),
                        SizedBox(height: 8),
                        Text('Toque em escanear pacote para começar'),
                      ],
                    )
                  : Column(
                      children: [
                        const Text(
                          'ESCREVA NO PACOTE',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${currentStop.number}',
                          style: const TextStyle(
                            fontSize: 82,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentStop.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currentStop.packages} pacote(s) nesta parada',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear pacote'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: stops.isEmpty ? null : resetLoad,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar carga'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: stops.length,
                itemBuilder: (context, index) {
                  final stop = stops[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${stop.number}'),
                      ),
                      title: Text(stop.name),
                      subtitle: Text(stop.address),
                      trailing: Text('📦 ${stop.packages}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool hasScanned = false;

  void onDetect(BarcodeCapture capture) {
    if (hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;

    hasScanned = true;
    Navigator.pop(context, code);
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
        children: [
          MobileScanner(
            onDetect: onDetect,
          ),
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Text(
              'Aponte para o código de barras ou QR Code da etiqueta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final int value;

  const _InfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 28,
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