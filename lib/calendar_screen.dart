import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'record_model.dart';
import 'dart:collection';
import 'statistics_screen.dart';
import 'daily_emotion_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final days = getMonthDays(_month);
    final monthRecords = getMonthRecords();
    final successMap = getSuccessCountByHabit();
    final failMap = getFailCountByHabit();
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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
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
                Text('${_month.year}년 ${_month.month}월', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('이 달의 종합 성공률: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${getMonthSuccessRate().toStringAsFixed(1)}%', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) => Text(['일','월','화','수','목','금','토'][i], style: const TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.7,
              ),
              itemCount: days.length,
              itemBuilder: (ctx, i) {
                final d = days[i];
                final validHabitIds = _habitBox.values.map((h) => h.id).toSet();
                final recs = (monthRecords[d] ?? []).where((r) => validHabitIds.contains(r.habitId)).toList();
                int total = recs.where((r) => r.status == 'success' || r.status == 'fail').length;
                int success = recs.where((r) => r.status == 'success').length;
                double rate = total == 0 ? 0.0 : (success / total) * 100;
                Color? color;
                if (total == 0) {
                  color = Colors.grey[200];
                } else if (rate > 50) {
                  color = Colors.green[200];
                } else {
                  color = Colors.red[200];
                }
                final DailyEmotionModel? emotionModel = _emotionBox.values.cast<DailyEmotionModel?>().firstWhere(
                  (e) => e?.date.year == d.year && e?.date.month == d.month && e?.date.day == d.day,
                  orElse: () => null,
                );
                final emotion = emotionModel?.emotion;
                return GestureDetector(
                  onTap: () => _showDayDetail(d, recs),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${d.day}'),
                            if (emotion != null && emotion.isNotEmpty)
                              Text(emotion, style: const TextStyle(fontSize: 16)),
                            if (total > 0)
                              Text('${rate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
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