import '../models/performance_comparativo_model.dart';
import '../models/performance_activity_model.dart';
import '../models/performance_desempenho_model.dart';
import '../models/performance_evolution_model.dart';
import '../models/performance_frequency_model.dart';
import '../models/performance_home_model.dart';
import '../models/performance_medal_model.dart';
import '../models/performance_ranking_model.dart';
import '../utils/performance_score_calculator.dart';

class PerformanceMockData {
  static PerformanceHomeData buildHomeData({String userName = 'Carlos'}) {
    return PerformanceHomeData(
      userName: userName,
      score: 9820,
      scorePercent: 98,
      starCount: 5,
      levelLabel: 'Nível Ouro',
      goalTarget: 500,
      goalCurrent: 460,
      goalPercent: 92,
      hoursTodayMinutes: 504,
      activitiesToday: 482,
      rankingPosition: 1,
    );
  }

  static PerformanceRankingData buildRankingData() {
    final List<PerformanceRankingEntry> entries = <PerformanceRankingEntry>[
      const PerformanceRankingEntry(
        position: 1,
        codusu: 1,
        nome: 'Carlos Silva',
        score: 11800,
        scorePercent: 98,
        starCount: 5,
        medalTier: 'ouro',
        totalPoints: 12450,
      ),
      const PerformanceRankingEntry(
        position: 2,
        codusu: 2,
        nome: 'Ana Paula',
        score: 10500,
        scorePercent: 95,
        starCount: 5,
        medalTier: 'prata',
        totalPoints: 11230,
      ),
      const PerformanceRankingEntry(
        position: 3,
        codusu: 3,
        nome: 'Ricardo G.',
        score: 9200,
        scorePercent: 92,
        starCount: 4,
        medalTier: 'bronze',
        totalPoints: 10120,
      ),
      const PerformanceRankingEntry(
        position: 4,
        codusu: 4,
        nome: 'João',
        score: 7800,
        scorePercent: 89,
        starCount: 4,
        medalTier: '',
        totalPoints: 8900,
      ),
      const PerformanceRankingEntry(
        position: 5,
        codusu: 5,
        nome: 'Fernanda',
        score: 7200,
        scorePercent: 87,
        starCount: 4,
        medalTier: '',
        totalPoints: 8700,
      ),
    ];
    return PerformanceRankingData(entries: entries, totalUsers: 27);
  }

  static PerformanceDesempenhoData buildDesempenhoData({
    int codusu = 1,
    String nome = 'Carlos Silva',
  }) {
    return PerformanceDesempenhoData(
      codusu: codusu,
      nome: nome,
      score: 9820,
      scorePercent: 98,
      starCount: 5,
      levelLabel: 'Nível Ouro',
      totalHoursMinutes: 10462,
      averageOnlineMinutes: 492,
      firstAccess: '07:41',
      lastAccess: '18:09',
      daysWorked: 22,
      totalOperations: 4892,
      actionsPerHour: 34,
      efficiencyPercent: 96,
      frequencyPercent: 100,
      operations: <PerformanceOperationCount>[
        const PerformanceOperationCount(operacao: 'Inclusão', count: 1200, percent: 24),
        const PerformanceOperationCount(operacao: 'Alteração', count: 2890, percent: 48),
        const PerformanceOperationCount(operacao: 'Consulta', count: 780, percent: 15),
        const PerformanceOperationCount(operacao: 'Exclusão', count: 22, percent: 1),
        const PerformanceOperationCount(operacao: 'Relatório', count: 120, percent: 5),
        const PerformanceOperationCount(operacao: 'Outros', count: 150, percent: 3),
      ],
      hourlyActivities: List<PerformanceHourlyActivity>.generate(
        10,
        (int index) => PerformanceHourlyActivity(
          hour: index + 8,
          count: <int>[3, 7, 11, 8, 2, 5, 7, 9, 8, 5][index],
        ),
      ),
      weekdayActivities: const <PerformanceWeekdayActivity>[
        PerformanceWeekdayActivity(weekday: 1, label: 'Seg', count: 7),
        PerformanceWeekdayActivity(weekday: 2, label: 'Ter', count: 11),
        PerformanceWeekdayActivity(weekday: 3, label: 'Qua', count: 12),
        PerformanceWeekdayActivity(weekday: 4, label: 'Qui', count: 7),
        PerformanceWeekdayActivity(weekday: 5, label: 'Sex', count: 10),
      ],
      moduleUsage: const <PerformanceModuleUsage>[
        PerformanceModuleUsage(modulo: 'Financeiro', count: 2690, percent: 55),
        PerformanceModuleUsage(modulo: 'Estoque', count: 880, percent: 18),
        PerformanceModuleUsage(modulo: 'Compras', count: 587, percent: 12),
        PerformanceModuleUsage(modulo: 'RH', count: 489, percent: 10),
        PerformanceModuleUsage(modulo: 'Outros', count: 246, percent: 5),
      ],
      heatmap: _buildHeatmap(),
    );
  }

  static List<PerformanceHeatmapCell> _buildHeatmap() {
    final List<PerformanceHeatmapCell> cells = <PerformanceHeatmapCell>[];
    final List<List<int>> values = <List<int>>[
      <int>[2, 2, 2, 2, 2],
      <int>[4, 4, 4, 4, 4],
      <int>[6, 6, 6, 6, 6],
      <int>[5, 5, 5, 5, 5],
      <int>[1, 1, 1, 1, 1],
      <int>[3, 3, 3, 3, 3],
      <int>[4, 4, 4, 4, 4],
      <int>[5, 5, 5, 5, 5],
      <int>[3, 3, 3, 3, 3],
      <int>[2, 2, 2, 2, 2],
    ];
    for (int hourIndex = 0; hourIndex < values.length; hourIndex++) {
      for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
        cells.add(
          PerformanceHeatmapCell(
            weekday: dayIndex + 1,
            hour: hourIndex + 8,
            count: values[hourIndex][dayIndex],
          ),
        );
      }
    }
    return cells;
  }

  static PerformanceEvolutionData buildEvolutionData(
    PerformanceEvolutionPeriod period,
  ) {
    final List<PerformanceEvolutionPoint> points;
    if (period == PerformanceEvolutionPeriod.daily) {
      points = List<PerformanceEvolutionPoint>.generate(
        22,
        (int index) => PerformanceEvolutionPoint(
          label: '${index + 1}',
          score: 70 + (index * 1.2).round(),
        ),
      );
    } else if (period == PerformanceEvolutionPeriod.weekly) {
      points = const <PerformanceEvolutionPoint>[
        PerformanceEvolutionPoint(label: 'S1', score: 72),
        PerformanceEvolutionPoint(label: 'S2', score: 78),
        PerformanceEvolutionPoint(label: 'S3', score: 82),
        PerformanceEvolutionPoint(label: 'S4', score: 88),
      ];
    } else {
      points = const <PerformanceEvolutionPoint>[
        PerformanceEvolutionPoint(label: 'Jan', score: 72),
        PerformanceEvolutionPoint(label: 'Fev', score: 76),
        PerformanceEvolutionPoint(label: 'Mar', score: 82),
        PerformanceEvolutionPoint(label: 'Abr', score: 88),
        PerformanceEvolutionPoint(label: 'Mai', score: 98),
      ];
    }
    return PerformanceEvolutionData(
      period: period,
      points: points,
      growthPercent: 18,
      averageScore: 82,
    );
  }

  static PerformanceMedalhasData buildMedalhasData() {
    final DateTime now = DateTime.now();
    return PerformanceMedalhasData(
      earnedCount: 6,
      totalCount: 8,
      medals: <PerformanceMedal>[
        PerformanceMedal(
          id: 'early_bird',
          title: 'Primeira atividade antes das 08',
          description: 'Acessou o sistema antes das 08:00',
          emoji: '🏅',
          earnedAt: now.subtract(const Duration(days: 5)),
          isEarned: true,
        ),
        PerformanceMedal(
          id: 'streak_10',
          title: '10 dias seguidos',
          description: 'Trabalhou 10 dias consecutivos',
          emoji: '🔥',
          earnedAt: now.subtract(const Duration(days: 3)),
          isEarned: true,
        ),
        PerformanceMedal(
          id: 'productive',
          title: 'Mais produtivo',
          description: 'Maior score do mês',
          emoji: '🚀',
          earnedAt: now.subtract(const Duration(days: 1)),
          isEarned: true,
        ),
        PerformanceMedal(
          id: 'no_delay',
          title: 'Sem atrasos',
          description: 'Nenhum atraso no mês',
          emoji: '🎯',
          earnedAt: now.subtract(const Duration(days: 2)),
          isEarned: true,
        ),
        PerformanceMedal(
          id: 'growth',
          title: 'Evoluiu 20%',
          description: 'Crescimento de 20% vs mês anterior',
          emoji: '📈',
          earnedAt: now.subtract(const Duration(days: 7)),
          isEarned: true,
        ),
        PerformanceMedal(
          id: 'daily_500',
          title: '500 operações no dia',
          description: 'Realizou 500 ações em um dia',
          emoji: '⚡',
          earnedAt: now.subtract(const Duration(days: 10)),
          isEarned: true,
        ),
        const PerformanceMedal(
          id: 'gold',
          title: 'Funcionário Ouro',
          description: 'Alcançou nível ouro',
          emoji: '💎',
          earnedAt: null,
          isEarned: false,
        ),
        const PerformanceMedal(
          id: 'top1',
          title: 'Top 1',
          description: 'Primeiro lugar no ranking',
          emoji: '👑',
          earnedAt: null,
          isEarned: true,
        ),
      ],
    );
  }

  static PerformanceHorasData buildHorasData() {
    return PerformanceHorasData(
      date: DateTime.now(),
      totalMinutes: 544,
      productiveMinutes: 480,
      idleMinutes: 64,
      events: const <PerformanceHorasEvent>[
        PerformanceHorasEvent(hora: '08:01', label: 'Primeiro acesso', type: 'access'),
        PerformanceHorasEvent(hora: '12:03', label: 'Início do almoço', type: 'lunch_start'),
        PerformanceHorasEvent(hora: '13:12', label: 'Retorno do almoço', type: 'lunch_end'),
        PerformanceHorasEvent(hora: '18:14', label: 'Último acesso', type: 'access'),
      ],
    );
  }

  static PerformanceFrequenciaData buildFrequenciaData() {
    final DateTime now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final List<PerformanceFrequencyDay> days = <PerformanceFrequencyDay>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(year, month, day);
      if (date.weekday > 5) {
        continue;
      }
      PerformanceFrequencyStatus status = PerformanceFrequencyStatus.present;
      if (day == 8) {
        status = PerformanceFrequencyStatus.halfDay;
      }
      if (day == 15) {
        status = PerformanceFrequencyStatus.absent;
      }
      if (day > now.day) {
        status = PerformanceFrequencyStatus.none;
      }
      days.add(PerformanceFrequencyDay(date: date, status: status));
    }
    return PerformanceFrequenciaData(
      year: year,
      month: month,
      days: days,
      presentDays: 22,
      halfDays: 1,
      absentDays: 1,
      vacationDays: 0,
    );
  }

  static PerformanceAtividadesData buildAtividadesData() {
    return const PerformanceAtividadesData(
      activities: <PerformanceTimelineEvent>[
        PerformanceTimelineEvent(hora: '08:11', operacao: 'Inclusão', tabela: 'CIRURGIA'),
        PerformanceTimelineEvent(hora: '09:02', operacao: 'Alteração', tabela: 'PACIENTE'),
        PerformanceTimelineEvent(hora: '09:55', operacao: 'Relatório', tabela: 'AGENDA'),
        PerformanceTimelineEvent(hora: '11:30', operacao: 'Fechamento', tabela: 'ESCALA'),
        PerformanceTimelineEvent(hora: '14:22', operacao: 'Consulta', tabela: 'HOSPITAL'),
        PerformanceTimelineEvent(hora: '16:45', operacao: 'Alteração', tabela: 'CONVENIO'),
      ],
    );
  }

  static PerformanceGestorData buildGestorData() {
    return PerformanceGestorData(
      growthPercent: 18,
      topRanking: buildRankingData().entries.take(5).toList(),
      kpis: const <PerformanceGestorKpi>[
        PerformanceGestorKpi(label: 'Usuários ativos hoje', value: '27', icon: 'users'),
        PerformanceGestorKpi(label: 'Média de Performance', value: '82%', icon: 'star'),
        PerformanceGestorKpi(label: 'Horas trabalhadas', value: '214 h', icon: 'clock'),
        PerformanceGestorKpi(label: 'Ações realizadas', value: '38.421', icon: 'fire'),
        PerformanceGestorKpi(label: 'Melhor usuário do mês', value: 'Carlos Silva', icon: 'trophy'),
        PerformanceGestorKpi(label: 'Crescimento vs mês anterior', value: '+18%', icon: 'growth'),
      ],
    );
  }

  static PerformanceComparativoData buildComparativoData({required int codusuB}) {
    final PerformanceRankingData ranking = buildRankingData();
    final PerformanceRankingEntry userB = ranking.entries.firstWhere(
      (PerformanceRankingEntry e) => e.codusu == codusuB,
      orElse: () => ranking.entries.length > 1
          ? ranking.entries[1]
          : ranking.entries.first,
    );
    final PerformanceRankingEntry userA = ranking.entries.first;
    return PerformanceComparativoData(
      userA: PerformanceComparativoUser(
        codusu: userA.codusu,
        nome: userA.nome,
        horasMinutes: 10462,
        operacoes: 4892,
        pontuacao: userA.score,
        eficiencia: 96,
        ranking: userA.position,
        starCount: userA.starCount,
      ),
      userB: PerformanceComparativoUser(
        codusu: userB.codusu,
        nome: userB.nome,
        horasMinutes: 10080,
        operacoes: 3210,
        pontuacao: userB.score,
        eficiencia: 84,
        ranking: userB.position,
        starCount: userB.starCount,
      ),
    );
  }

  static int calculateScorePercent(int score, int maxScore) {
    if (maxScore <= 0) {
      return 0;
    }
    return ((score / maxScore) * 100).round().clamp(0, 100);
  }

  static int resolveStars(int scorePercent) {
    return PerformanceScoreCalculator.calculateStarCount(scorePercent);
  }
}
