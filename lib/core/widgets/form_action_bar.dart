import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FormActionBar extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final String loadingLabel;

  const FormActionBar({
    super.key,
    required this.isLoading,
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Salvar',
    this.loadingLabel = 'Salvando...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      color: AppColors.lightBlue,
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: isLoading ? null : onCancel,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.cancel, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: InkWell(
              onTap: isLoading ? null : onSave,
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loadingLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          isEditing ? Icons.save : Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          saveLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
