import 'package:flutter/material.dart';
import '../../legal/data/legal_content.dart';
import '../../legal/presentation/legal_document_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Política de Privacidade',
      subtitle: 'Aresia — DOMINA TECNOLOGIA',
      updatedAt: LegalContent.privacyUpdatedAt,
      sections: LegalContent.privacySections,
    );
  }
}
