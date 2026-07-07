import 'package:flutter/material.dart';

import '../models/stop.dart';
import '../services/knowledge_service.dart';
import '../services/package_service.dart';
import '../services/stop_matcher_service.dart';
import '../services/stop_service.dart';
import 'scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StopService stopService;

  @override
  void initState() {
    super.initState();

    stopService = StopService(
      packageService: PackageService(),
      matcher: StopMatcherService(),
      knowledge: KnowledgeService(),
    );
  }

  void simulateScan() {
    final examples = [
      'Rua Ermínio Alexandre da Silva, 50',
      'Rua 17, 50',
      'Rua Capitão João Gonçalves, 116',
      'R. Capitao Joao Goncalves 116',
    ];

    final total = stopService.totalPackages;
    final rawAddress = examples[total % examples.length];

    setState(() {
      stopService.registerPackage(
        address: rawAddress,
        neighborhood: 'Jardim das Flores',
        city: 'Hortolândia',
        state: 'SP',
        postalCode: '13184-000',
      );
    });
  }

  void resetLoad() {
    setState(() {
      stopService.reset();
    });
  }

  void openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = stopService.stops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Cargo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'A inteligência por trás da rota.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Carga atual',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${stopService.totalStops} paradas',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${stopService.totalPackages} pacotes',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openScanner,
                icon: const Icon(Icons.document_scanner),
                label: const Text('ESCANEAR ETIQUETA REAL'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: simulateScan,
                icon: const Icon(Icons.science),
                label: const Text('SIMULAR ESCANEAMENTO'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: stops.isEmpty ? null : resetLoad,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar carga'),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: stops.isEmpty
                  ? const Center(
                      child: Text('Nenhuma parada criada ainda.'),
                    )
                  : ListView.builder(
                      itemCount: stops.length,
                      itemBuilder: (context, index) {
                        final stop = stops[index];
                        return _StopCard(stop: stop);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final Stop stop;

  const _StopCard({
    required this.stop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(stop.stopLabel),
        ),
        title: Text(
          'Parada ${stop.stopLabel}  •  📦 x${stop.packageCount}',
        ),
        subtitle: Text(
          '${stop.address}\n'
          '${stop.neighborhood}\n'
          '${stop.city} - ${stop.state} | ${stop.postalCode}',
        ),
        isThreeLine: true,
      ),
    );
  }
}