import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_ranking_model.dart';
import 'performance_score_card.dart';

class PerformanceRankingPodium extends StatelessWidget {
  final List<PerformanceRankingEntry> topThree;

  const PerformanceRankingPodium({
    super.key,
    required this.topThree,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }
    final PerformanceRankingEntry? first =
        topThree.length > 0 ? topThree[0] : null;
    final PerformanceRankingEntry? second =
        topThree.length > 1 ? topThree[1] : null;
    final PerformanceRankingEntry? third =
        topThree.length > 2 ? topThree[2] : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (second != null)
              _PodiumItem(entry: second, height: 70, medal: '🥈'),
            if (first != null) ...<Widget>[
              const SizedBox(width: 8),
              _PodiumItem(entry: first, height: 90, medal: '🥇'),
              const SizedBox(width: 8),
            ],
            if (third != null)
              _PodiumItem(entry: third, height: 55, medal: '🥉'),
          ],
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final PerformanceRankingEntry entry;
  final double height;
  final String medal;

  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.lightBlue.withOpacity(0.2),
            child: Text(
              entry.nome.isNotEmpty ? entry.nome[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.nome.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          PerformanceStarDisplay(starCount: entry.starCount, size: 12),
          Text(
            '${entry.scorePercent}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.lightBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.position}º',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PerformanceRankingListTile extends StatelessWidget {
  final PerformanceRankingEntry entry;
  final VoidCallback? onTap;

  const PerformanceRankingListTile({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.surfaceVariant,
          child: Text(
            '${entry.position}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          entry.nome,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: PerformanceStarDisplay(starCount: entry.starCount, size: 14),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${entry.scorePercent}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.lightBlue,
              ),
            ),
            Text(
              '${entry.totalPoints} pts',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
