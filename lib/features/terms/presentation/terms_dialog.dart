import 'package:flutter/material.dart';
import '../services/terms_service.dart';
import 'terms_page.dart';

class TermsDialog extends StatelessWidget {
  final TermsService termsService;

  const TermsDialog({
    super.key,
    required this.termsService,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Impede fechar com botão voltar
      child: AlertDialog(
        title: const Text(
          'Termos e Condições',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bem-vindo ao Ares Flutter!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Para utilizar o aplicativo, você precisa aceitar nossos termos e condições. Ao aceitar, você concorda com:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildTopic('Uso responsável do aplicativo'),
              _buildTopic('Proteção dos dados dos pacientes'),
              _buildTopic('Respeito às normas de segurança'),
              _buildTopic('Confidencialidade das informações'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TermsPage(),
                    ),
                  );
                },
                child: const Text('Ler termos completos'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text(
              'Recusar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await termsService.acceptTerms();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Erro ao aceitar os termos. Tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopic(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
