import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PerformanceStarDisplay extends StatelessWidget {
  final int starCount;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const PerformanceStarDisplay({
    super.key,
    required this.starCount,
    this.size = 18,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = activeColor ?? const Color(0xFFFFB300);
    final Color inactive = inactiveColor ?? Colors.grey.shade300;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int index) {
        final bool isFilled = index < starCount;
        return Icon(
          isFilled ? Icons.star : Icons.star_border,
          size: size,
          color: isFilled ? active : inactive,
        );
      }),
    );
  }
}

class PerformanceLevelBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const PerformanceLevelBadge({
    super.key,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = color ?? const Color(0xFFFFB300);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor.withOpacity(0.9),
        ),
      ),
    );
  }
}

class PerformanceScoreCard extends StatelessWidget {
  final int score;
  final int scorePercent;
  final int starCount;
  final String levelLabel;

  const PerformanceScoreCard({
    super.key,
    required this.score,
    required this.scorePercent,
    required this.starCount,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.darkBlue,
              AppColors.darkBlue.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Score',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  score.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '$scorePercent%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PerformanceStarDisplay(
              starCount: starCount,
              activeColor: const Color(0xFFFFD54F),
              inactiveColor: Colors.white24,
            ),
            const SizedBox(height: 8),
            PerformanceLevelBadge(
              label: levelLabel,
              color: const Color(0xFFFFD54F),
            ),
          ],
        ),
      ),
    );
  }
}
