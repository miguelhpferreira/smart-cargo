import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final int value;
  final bool compact;

  const InfoCard({
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
                style: TextStyle(fontSize: compact ? 12 : 15),
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
