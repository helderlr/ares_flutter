import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/terms_dialog.dart';
import 'terms_service.dart';

class TermsCheckService {
  static Future<void> checkAndShowTerms(
    BuildContext context, {
    VoidCallback? onTermsRejected,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final TermsService termsService = TermsService(prefs);
      final termsStatus = await termsService.getTermsStatus();
      if (termsStatus.accepted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return TermsDialog(termsService: termsService);
        },
      );
      if (result != true) {
        onTermsRejected?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao carregar os termos. Tente novamente mais tarde.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
