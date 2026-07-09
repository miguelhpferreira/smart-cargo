import 'package:flutter/material.dart';

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
  int packages;

  Stop({
    required this.number,
    required this.name,
    required this.address,
    required this.type,
    this.packages = 1,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Stop> stops = [];

  final List<Map<String, String>> simulatedPackages = [
    {
      'name': 'HM Smart',
      'address': 'Rua 17, 50',
      'type': 'Condomínio',
    },
    {
      'name': 'HM Smart',
      'address': 'Rua Ermínio Alexandre da Silva, 50',
      'type': 'Condomínio',
    },
    {
      'name': 'Residência',
      'address': 'Rua Cordilheiras dos Andes, 101',
      'type': 'Residência',
    },
    {
      'name': 'HM Smart',
      'address': 'Rua 17, 50',
      'type': 'Condomínio',
    },
  ];

  int totalPackages = 0;

  String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ermínio alexandre da silva', '17')
        .replaceAll('erminio alexandre da silva', '17')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void simulateScan() {
    final data = simulatedPackages[totalPackages % simulatedPackages.length];
    final normalizedAddress = normalize(data['address']!);

    Stop? existingStop;

    for (final stop in stops) {
      if (normalize(stop.address) == normalizedAddress) {
        existingStop = stop;
        break;
      }
    }

    setState(() {
      totalPackages++;

      if (existingStop != null) {
        existingStop!.packages++;
      } else {
        stops.add(
          Stop(
            number: stops.length + 1,
            name: data['name']!,
            address: data['address']!,
            type: data['type']!,
          ),
        );
      }
    });
  }

  void resetLoad() {
    setState(() {
      stops.clear();
      totalPackages = 0;
    });
  }

  int get condominiums =>
      stops.where((stop) => stop.type == 'Condomínio').length;

  int get residences =>
      stops.where((stop) => stop.type == 'Residência').length;

  @override
  Widget build(BuildContext context) {
    final lastStop = stops.isEmpty ? null : stops.last;

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
              child: lastStop == null
                  ? const Column(
                      children: [
                        Text(
                          'Nenhum pacote lido',
                          style: TextStyle(fontSize: 22),
                        ),
                        SizedBox(height: 8),
                        Text('Toque em simular leitura para começar'),
                      ],
                    )
                  : Column(
                      children: [
                        const Text(
                          'ESCREVA NO PACOTE',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${lastStop.number}',
                          style: const TextStyle(
                            fontSize: 82,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          lastStop.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${lastStop.packages} pacote(s) nesta parada',
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
                onPressed: simulateScan,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Simular leitura'),
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
