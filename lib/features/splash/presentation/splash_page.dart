import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/domina_animated_logo.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _totalDuration = Duration(seconds: 3);
  static const Duration _rotationDuration = Duration(seconds: 1);

  late final AnimationController _controller;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _symbolRotationAnimation;
  late final Animation<double> _fullLogoRevealAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  Timer? _safetyTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _symbolRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0,
          _rotationDuration.inMilliseconds / _totalDuration.inMilliseconds,
          curve: Curves.easeInOut,
        ),
      ),
    );
    _fullLogoRevealAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _rotationDuration.inMilliseconds / _totalDuration.inMilliseconds,
        0.5,
        curve: Curves.easeInOut,
      ),
    );
    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.78, curve: Curves.easeIn),
    );
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    _controller.addStatusListener(_handleAnimationStatus);
    _safetyTimer = Timer(_totalDuration + const Duration(milliseconds: 500), () {
      _completeSplash();
    });
  }

  void _completeSplash() {
    if (_completed) {
      return;
    }
    _completed = true;
    widget.onComplete();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _completeSplash();
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  double _resolveLogoSize(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 360) {
      return 72;
    }
    if (screenWidth < 600) {
      return 88;
    }
    return 104;
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = _resolveLogoSize(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5F9FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DominaAnimatedLogo(
                    symbolSize: logoSize,
                    fadeAnimation: _logoFadeAnimation,
                    scaleAnimation: _logoScaleAnimation,
                    rotationAnimation: _symbolRotationAnimation,
                    fullLogoRevealAnimation: _fullLogoRevealAnimation,
                  ),
                  SizedBox(height: logoSize * 0.35),
                  FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: SlideTransition(
                      position: _titleSlideAnimation,
                      child: const _DominaTitle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DominaTitle extends StatelessWidget {
  const _DominaTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'DOMINA TECNOLOGIA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.darkBlue,
            fontSize: _resolveTitleSize(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                AppColors.lightBlue,
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _resolveTitleSize(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 360) {
      return 16;
    }
    if (screenWidth < 600) {
      return 18;
    }
    return 20;
  }
}
