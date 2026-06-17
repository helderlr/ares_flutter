import 'package:flutter/material.dart';

import '../../../core/widgets/brand_logo.dart';
import '../models/empresa_model.dart';

class LoginLogo extends StatelessWidget {
  final EmpresaModel? empresa;

  const LoginLogo({
    super.key,
    this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    final String? logoUrl = empresa?.logomarcaUrl?.trim();
    if (empresa != null && logoUrl != null && logoUrl.isNotEmpty) {
      return BrandLogo.empresa(
        key: ValueKey<String>('empresa-logo-${empresa!.id}'),
        empresa: empresa!,
        height: 120,
      );
    }
    return const BrandLogo.domina(height: 120);
  }
}
