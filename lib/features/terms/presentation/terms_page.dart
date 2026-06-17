import 'package:flutter/material.dart';
import '../../legal/data/legal_content.dart';
import '../../legal/presentation/legal_document_page.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Termos de Uso',
      subtitle: 'Aresia — DOMINA TECNOLOGIA',
      updatedAt: LegalContent.termsUpdatedAt,
      sections: LegalContent.termsSections,
    );
  }
}
