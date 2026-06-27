import 'package:flutter/material.dart';

enum ShareFormat {
  image,
  pdf,
}

class ShareFormatSheet {
  static Future<ShareFormat?> show(BuildContext context) {
    return showModalBottomSheet<ShareFormat>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Compartilhar como',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Imagem'),
                onTap: () => Navigator.of(context).pop(ShareFormat.image),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Arquivo PDF'),
                onTap: () => Navigator.of(context).pop(ShareFormat.pdf),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
