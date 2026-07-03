import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MiscelaneaPerformanceOperacionalPage extends StatelessWidget {
  const MiscelaneaPerformanceOperacionalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Operacional'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.bar_chart,
                size: 64,
                color: AppColors.lightBlue.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Performance Operacional',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Módulo em desenvolvimento.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
