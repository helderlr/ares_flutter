import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';

class DominaAnimatedLogo extends StatelessWidget {
  final double symbolSize;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final Animation<double> fullLogoRevealAnimation;

  const DominaAnimatedLogo({
    super.key,
    required this.symbolSize,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.fullLogoRevealAnimation,
  });

  double get _fullLogoWidth => symbolSize * 2.35;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _fullLogoWidth,
      height: symbolSize,
      child: AnimatedBuilder(
        animation: fullLogoRevealAnimation,
        builder: (BuildContext context, Widget? child) {
          final double reveal = fullLogoRevealAnimation.value;
          final double symbolOpacity = (1.0 - reveal).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (reveal > 0)
                Opacity(
                  opacity: reveal,
                  child: _buildFullLogo(),
                ),
              if (symbolOpacity > 0)
                Opacity(
                  opacity: symbolOpacity,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: RotationTransition(
                        turns: rotationAnimation,
                        child: _buildSymbolOnly(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSymbolOnly() {
    return SizedBox(
      width: symbolSize,
      height: symbolSize,
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_domina.png',
          width: _fullLogoWidth,
          height: symbolSize,
          fit: BoxFit.cover,
          alignment: Alignment.centerLeft,
          errorBuilder: (_, __, ___) {
            return Image.network(
              ApiConfig.dominaLogoUrl,
              width: _fullLogoWidth,
              height: symbolSize,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) => _buildSymbolFallback(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFullLogo() {
    return Image.asset(
      'assets/images/logo_domina.png',
      width: _fullLogoWidth,
      height: symbolSize,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Image.network(
          ApiConfig.dominaLogoUrl,
          width: _fullLogoWidth,
          height: symbolSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFullLogoFallback(),
        );
      },
    );
  }

  Widget _buildSymbolFallback() {
    return Container(
      width: symbolSize,
      height: symbolSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2E7D32), width: 3),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.hub_outlined,
        size: symbolSize * 0.5,
        color: const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildFullLogoFallback() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSymbolFallback(),
        SizedBox(width: symbolSize * 0.12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DOMINA',
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontSize: symbolSize * 0.28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                height: 1,
              ),
            ),
            Text(
              'TECNOLOGIA',
              style: TextStyle(
                color: const Color(0xFF0A2F66),
                fontSize: symbolSize * 0.14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
