import 'package:flutter/material.dart';
import '../data/legal_content.dart';

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String updatedAt;
  final List<LegalSection> sections;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última atualização: $updatedAt',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          for (final LegalSection section in sections) ...[
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            if (section.body.isNotEmpty)
              Text(
                section.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF475569),
                ),
              ),
            if (section.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final String bullet in section.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          bullet,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
