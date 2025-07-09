import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'record_model.dart';
import 'dart:collection';
import 'statistics_screen.dart';
import 'daily_emotion_model.dart';
import 'package:collection/collection.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Box<HabitModel> _habitBox;
  late Box<RecordModel> _recordBox;
  late Box<DailyEmotionModel> _emotionBox;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<HabitModel>('habits');
    _recordBox = Hive.box<RecordModel>('records');
    _emotionBox = Hive.box<DailyEmotionModel>('daily_emotion');
  }

  List<DateTime> getMonthDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(last.day, (i) => DateTime(month.year, month.month, i + 1));
  }

  Map<DateTime, List<RecordModel>> getMonthRecords() {
    final days = getMonthDays(_month);
    final map = <DateTime, List<RecordModel>>{};
    for (final d in days) {
      map[d] = _recordBox.values.where((r) =>
        r.date.year == d.year && r.date.month == d.month && r.date.day == d.day
      ).toList();
    }
    return map;
  }

  void _showDayDetail(DateTime day, List<RecordModel> records) {
    final DailyEmotionModel? emotionModel = _emotionBox.values.cast<DailyEmotionModel?>().firstWhere(
      (e) => e?.date.year == day.year && e?.date.month == day.month && e?.date.day == day.day,
      orElse: () => null,
    );
    final emotion = emotionModel?.emotion;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text('${day.month}월 ${day.day}일 상세 기록'),
            if (emotion != null && emotion.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(emotion, style: const TextStyle(fontSize: 24)),
            ],
          ],
        ),
        content: records.isEmpty
            ? const Text('기록 없음')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: records.map((r) {
                  final HabitModel? habit = _habitBox.values.cast<HabitModel?>().firstWhere(
                    (h) => h?.id == r.habitId,
                    orElse: () => null,
                  );
                  final icon = habit?.icon ?? r.icon;
                  final name = habit?.name ?? r.name;
                  return ListTile(
                    leading: Text(icon, style: const TextStyle(fontSize: 24)),
                    title: Text(name),
                    subtitle: Text(r.status == 'success' ? '성공' : '실패'),
                    trailing: r.memo.isNotEmpty ? Icon(Icons.sticky_note_2) : null,
                    onTap: r.memo.isNotEmpty ? () => showDialog(
                      context: context,
                      builder: (c) => AlertDialog(title: const Text('메모'), content: Text(r.memo), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('닫기'))]),
                    ) : null,
                  );
                }).toList(),
              ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('닫기'))],
      ),
    );
  }

  Map<String, int> getSuccessCountByHabit() {
    final map = <String, int>{};
    for (final h in _habitBox.values) {
      map[h.name] = _recordBox.values.where((r) => r.habitId == h.id && r.status == 'success').length;
    }
    return map;
  }

  Map<String, int> getFailCountByHabit() {
    final map = <String, int>{};
    for (final h in _habitBox.values) {
      map[h.name] = _recordBox.values.where((r) => r.habitId == h.id && r.status == 'fail').length;
    }
    return map;
  }

  double getSuccessRate(String habitId) {
    final total = _recordBox.values.where((r) => r.habitId == habitId && (r.status == 'success' || r.status == 'fail')).length;
    if (total == 0) return 0;
    final success = _recordBox.values.where((r) => r.habitId == habitId && r.status == 'success').length;
    return (success / total) * 100;
  }

  Map<String, int> getFailCountByWeekday(String habitId) {
    // 요일별 실패 횟수 (0:일~6:토)
    final map = <String, int>{'일':0,'월':0,'화':0,'수':0,'목':0,'금':0,'토':0};
    for (final r in _recordBox.values.where((r) => r.habitId == habitId && r.status == 'fail')) {
      final wd = ['일','월','화','수','목','금','토'][r.date.weekday % 7];
      map[wd] = (map[wd] ?? 0) + 1;
    }
    return map;
  }

  double getMonthSuccessRate() {
    final days = getMonthDays(_month);
    int total = 0;
    int success = 0;
    final validHabitIds = _habitBox.values.map((h) => h.id).toSet();
    for (final d in days) {
      final recs = _recordBox.values.where((r) =>
        r.date.year == d.year && r.date.month == d.month && r.date.day == d.day &&
        validHabitIds.contains(r.habitId)
      ).toList();
      final dayTotal = recs.where((r) => r.status == 'success' || r.status == 'fail').length;
      final daySuccess = recs.where((r) => r.status == 'success').length;
      total += dayTotal;
      success += daySuccess;
    }
    if (total == 0) return 0.0;
    return (success / total) * 100;
  }

  // 이번 주(월~일) 날짜 리스트 반환
  List<DateTime> getCurrentWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // limitType에서 주간 성공 기준(분모) 추출
  int getWeeklyGoalCount(HabitModel habit) {
    if (habit.limitType.contains('매일 금지')) {
      return 7;
    }
    final reg = RegExp(r'주 (\d+)회 이하');
    final match = reg.firstMatch(habit.limitType);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 7; // 기본값: 매일 금지
  }

  // 주간 성공률 계산 (분자/분모, 100% 초과 허용)
  Map<String, dynamic> getWeekSuccessRatio(DateTime base) {
    final weekDays = getWeekDays(base);
    final habits = _habitBox.values.toList();
    int numerator = 0;
    int denominator = 0;
    for (final h in habits) {
      final goal = getWeeklyGoalCount(h);
      denominator += goal;
      final weekRecords = _recordBox.values.where((r) =>
        r.habitId == h.id &&
        weekDays.any((d) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day) &&
        r.status == 'success'
      ).length;
      numerator += weekRecords;
    }
    double percent = denominator == 0 ? 0.0 : (numerator / denominator) * 100;
    return {'numerator': numerator, 'denominator': denominator, 'percent': percent};
  }

  // 기준 날짜에 해당하는 주(월~일) 리스트 반환
  List<DateTime> getWeekDays(DateTime base) {
    final monday = base.subtract(Duration(days: base.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // 기준 날짜의 감정 이모지 반환
  String? getEmotionForDay(DateTime day) {
    final e = _emotionBox.values.firstWhereOrNull(
      (e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day,
    );
    return e?.emotion;
  }

  DateTime _weekBase = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final weekDays = getWeekDays(_weekBase);
    final weekRatio = getWeekSuccessRatio(_weekBase);
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '통계',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _weekBase = _weekBase.subtract(const Duration(days: 7));
                    });
                  },
                ),
                Text('${weekDays.first.month}월 ${weekDays.first.day}일 ~ ${weekDays.last.month}월 ${weekDays.last.day}일', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _weekBase = _weekBase.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('이번 주 종합 성공률: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${weekRatio['numerator']}/${weekRatio['denominator']}회', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('${weekRatio['percent'].toStringAsFixed(1)}%', style: TextStyle(color: weekRatio['percent'] > 100 ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold)),
                if (weekRatio['percent'] > 100)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('초과 달성!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((d) {
                final emotion = getEmotionForDay(d);
                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(emotion ?? '—', style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 4),
                    Text('${d.day}일', style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: weekDays.length,
              itemBuilder: (context, i) {
                final d = weekDays[i];
                final records = _recordBox.values.where((r) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day).toList();
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('${d.month}월 ${d.day}일 (${['월','화','수','목','금','토','일'][d.weekday-1]})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('기분: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(getEmotionForDay(d) ?? '—', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...records.map((r) {
                          final habit = _habitBox.values.firstWhereOrNull((h) => h.id == r.habitId);
                          return Row(
                            children: [
                              Text(habit?.icon ?? '', style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(habit?.name ?? ''),
                              const SizedBox(width: 8),
                              Text(r.status == 'success' ? '성공' : '실패', style: TextStyle(color: r.status == 'success' ? Colors.green : Colors.red)),
                              if (r.memo.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.sticky_note_2, size: 16),
                              ],
                            ],
                          );
                        }).toList(),
                        if (records.isEmpty)
                          const Text('기록 없음', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 