import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AtendimentoRelatoriosPage extends StatelessWidget {
  const AtendimentoRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text('Relatórios'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Relatórios PDF / Excel / impressão',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Módulo em desenvolvimento.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
