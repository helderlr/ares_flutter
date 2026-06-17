import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../../features/login/models/empresa_model.dart';

enum BrandLogoMode {
  domina,
  empresa,
}

class BrandLogo extends StatefulWidget {
  final BrandLogoMode mode;
  final EmpresaModel? empresa;
  final double height;
  final double? width;
  final Color backgroundColor;

  const BrandLogo({
    super.key,
    this.mode = BrandLogoMode.domina,
    this.empresa,
    this.height = 120,
    this.width,
    this.backgroundColor = Colors.white,
  });

  const BrandLogo.domina({
    super.key,
    this.height = 120,
    this.width,
    this.backgroundColor = Colors.white,
  })  : mode = BrandLogoMode.domina,
        empresa = null;

  BrandLogo.empresa({
    super.key,
    required EmpresaModel this.empresa,
    this.height = 120,
    this.width,
    this.backgroundColor = Colors.white,
  }) : mode = BrandLogoMode.empresa;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> {
  bool hasEmpresaLogoError = false;

  @override
  void didUpdateWidget(BrandLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.empresa?.id != widget.empresa?.id ||
        oldWidget.mode != widget.mode) {
      hasEmpresaLogoError = false;
    }
  }

  String? get _empresaLogoSource {
    final String? raw = widget.empresa?.logomarcaUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (raw.toLowerCase().startsWith('data:')) {
      final int commaIndex = raw.indexOf(',');
      if (commaIndex == -1) {
        return raw;
      }
      final String meta = raw.substring(0, commaIndex);
      final String payload = raw.substring(commaIndex + 1);
      if (RegExp(r';base64', caseSensitive: false).hasMatch(meta)) {
        return '$meta,${payload.replaceAll(RegExp(r'\s'), '')}';
      }
      return raw;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('/')) {
      return '${ApiConfig.baseUrl}$raw';
    }
    if (RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(raw) && raw.length > 80) {
      return 'data:image/png;base64,${raw.replaceAll(RegExp(r'\s'), '')}';
    }
    return '${ApiConfig.baseUrl}/$raw';
  }

  bool get _shouldShowEmpresaLogo {
    return widget.mode == BrandLogoMode.empresa &&
        !hasEmpresaLogoError &&
        _empresaLogoSource != null;
  }

  Widget _buildDominaFallbackText() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'DOMINA',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: widget.height * 0.22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'TECNOLOGIA',
          style: TextStyle(
            color: const Color(0xFF0A2F66),
            fontSize: widget.height * 0.12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDominaLogo() {
    return Image.asset(
      'assets/images/logo_domina.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Image.network(
          ApiConfig.dominaLogoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildDominaFallbackText(),
        );
      },
    );
  }

  Widget _buildEmpresaLogoImage() {
    final String source = _empresaLogoSource!;
    if (source.toLowerCase().startsWith('data:image')) {
      try {
        final int commaIndex = source.indexOf(',');
        if (commaIndex > 0) {
          final Uint8List bytes =
              base64Decode(source.substring(commaIndex + 1));
          return Image.memory(bytes, fit: BoxFit.contain);
        }
      } catch (_) {
        return _buildDominaLogo();
      }
    }
    return Image.network(
      source,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !hasEmpresaLogoError) {
            setState(() {
              hasEmpresaLogoError = true;
            });
          }
        });
        return _buildDominaLogo();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      color: widget.backgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _shouldShowEmpresaLogo
          ? _buildEmpresaLogoImage()
          : _buildDominaLogo(),
    );
  }
}
