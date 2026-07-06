import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_activity_model.dart';
import '../models/performance_frequency_model.dart';
import '../models/performance_medal_model.dart';
import '../utils/performance_formatters.dart';

class PerformanceMedalGrid extends StatelessWidget {
  final List<PerformanceMedal> medals;

  const PerformanceMedalGrid({super.key, required this.medals});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: medals.length,
      itemBuilder: (BuildContext context, int index) {
        final PerformanceMedal medal = medals[index];
        return Card(
          color: medal.isEarned
              ? scheme.surface
              : scheme.surfaceVariant.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  medal.emoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: medal.isEarned ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  medal.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: medal.isEarned ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
                if (medal.earnedAt != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(medal.earnedAt!),
                    style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class PerformanceHorasTimeline extends StatelessWidget {
  final List<PerformanceHorasEvent> events;
  final int totalMinutes;

  const PerformanceHorasTimeline({
    super.key,
    required this.events,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Hoje',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...events.asMap().entries.map(
              (MapEntry<int, PerformanceHorasEvent> entry) {
                final bool isLast = entry.key == events.length - 1;
                return _TimelineItem(
                  event: entry.value,
                  isLast: isLast,
                );
              },
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total do dia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  PerformanceFormatters.formatHoursMinutes(totalMinutes),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final PerformanceHorasEvent event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color dotColor = _resolveDotColor(event.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    PerformanceFormatters.formatTimeLabel(event.hora),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    event.label,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveDotColor(String type) {
    switch (type) {
      case 'lunch_start':
      case 'lunch_end':
        return Colors.orange;
      case 'idle':
        return Colors.red.shade300;
      default:
        return AppColors.lightBlue;
    }
  }
}

class PerformanceActivityTimeline extends StatelessWidget {
  final List<PerformanceTimelineEvent> activities;

  const PerformanceActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhuma atividade recente.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final PerformanceTimelineEvent activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.lightBlue.withOpacity(0.15),
              child: Text(
                PerformanceFormatters.formatTimeLabel(activity.hora),
                style: const TextStyle(fontSize: 9, color: AppColors.darkBlue),
              ),
            ),
            title: Text(activity.displayAction),
            subtitle: activity.histor != null
                ? Text(
                    activity.histor!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          );
        },
      ),
    );
  }
}

class PerformanceFrequencyCalendar extends StatelessWidget {
  final PerformanceFrequenciaData data;

  const PerformanceFrequencyCalendar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<int, List<PerformanceFrequencyDay>> weeks = <int, List<PerformanceFrequencyDay>>{};
    for (final PerformanceFrequencyDay day in data.days) {
      final int weekIndex = ((day.date.day - 1) ~/ 7);
      weeks.putIfAbsent(weekIndex, () => <PerformanceFrequencyDay>[]).add(day);
    }
    return Column(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: weeks.entries.map(
                (MapEntry<int, List<PerformanceFrequencyDay>> entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: List<Widget>.generate(5, (int index) {
                        if (index >= entry.value.length) {
                          return const Expanded(child: SizedBox(height: 28));
                        }
                        final PerformanceFrequencyDay day = entry.value[index];
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 28,
                            decoration: BoxDecoration(
                              color: _resolveStatusColor(day.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.date.day}',
                              style: TextStyle(
                                fontSize: 10,
                                color: day.status == PerformanceFrequencyStatus.none
                                    ? scheme.onSurfaceVariant
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: <Widget>[
            _LegendItem(color: Colors.green, label: 'Presente (${data.presentDays})'),
            _LegendItem(color: Colors.amber, label: 'Meio período (${data.halfDays})'),
            _LegendItem(color: Colors.red, label: 'Faltas (${data.absentDays})'),
            _LegendItem(color: Colors.blue, label: 'Férias (${data.vacationDays})'),
          ],
        ),
      ],
    );
  }

  Color _resolveStatusColor(PerformanceFrequencyStatus status) {
    switch (status) {
      case PerformanceFrequencyStatus.present:
        return Colors.green;
      case PerformanceFrequencyStatus.halfDay:
        return Colors.amber;
      case PerformanceFrequencyStatus.absent:
        return Colors.red;
      case PerformanceFrequencyStatus.vacation:
        return Colors.blue;
      case PerformanceFrequencyStatus.none:
        return Colors.grey.shade200;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
