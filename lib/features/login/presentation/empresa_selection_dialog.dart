import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/empresa_model.dart';

class EmpresaSelectionDialog extends StatelessWidget {
  final List<EmpresaModel> empresas;

  const EmpresaSelectionDialog({
    super.key,
    required this.empresas,
  });

  static Future<EmpresaModel?> show(
    BuildContext context,
    List<EmpresaModel> empresas,
  ) {
    return showDialog<EmpresaModel>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EmpresaSelectionDialog(empresas: empresas);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione a empresa'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: empresas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final EmpresaModel empresa = empresas[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightBlue.withOpacity(0.15),
                child: const Icon(Icons.business, color: AppColors.lightBlue),
              ),
              title: Text(empresa.displayLabel),
              onTap: () => Navigator.of(context).pop(empresa),
            );
          },
        ),
      ),
    );
  }
}
