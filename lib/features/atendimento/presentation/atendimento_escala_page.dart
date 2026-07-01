import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AtendimentoEscalaPage extends StatelessWidget {
  const AtendimentoEscalaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escala'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.swap_vert,
                size: 64,
                color: AppColors.lightBlue.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Escala',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Consulta e gestão de escalas em breve nesta versão do app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
