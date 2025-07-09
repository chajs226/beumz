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

/// 캘린더 모드(주간/월간) 구분을 위한 enum - SRP(단일 책임 원칙) 적용
enum CalendarMode { week, month }

class _CalendarScreenState extends State<CalendarScreen> {
  late Box<HabitModel> _habitBox;
  late Box<RecordModel> _recordBox;
  late Box<DailyEmotionModel> _emotionBox;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _weekBase = DateTime.now();
  CalendarMode _mode = CalendarMode.week; // 주간/월간 모드 상태
  int? _selectedWeekIndex; // 주간 리스트뷰에서 선택된 인덱스(애니메이션용)

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
    // 현재 존재하는 목표들
    for (final h in _habitBox.values) {
      map[h.name] = _recordBox.values.where((r) => r.habitId == h.id && r.status == 'success').length;
    }
    // 삭제된 목표들의 기록도 추가
    final existingHabitIds = _habitBox.values.map((h) => h.id).toSet();
    final deletedHabitRecords = _recordBox.values.where((r) => !existingHabitIds.contains(r.habitId));
    for (final r in deletedHabitRecords) {
      if (r.status == 'success' && r.name.isNotEmpty) {
        map[r.name] = (map[r.name] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<String, int> getFailCountByHabit() {
    final map = <String, int>{};
    // 현재 존재하는 목표들
    for (final h in _habitBox.values) {
      map[h.name] = _recordBox.values.where((r) => r.habitId == h.id && r.status == 'fail').length;
    }
    // 삭제된 목표들의 기록도 추가
    final existingHabitIds = _habitBox.values.map((h) => h.id).toSet();
    final deletedHabitRecords = _recordBox.values.where((r) => !existingHabitIds.contains(r.habitId));
    for (final r in deletedHabitRecords) {
      if (r.status == 'fail' && r.name.isNotEmpty) {
        map[r.name] = (map[r.name] ?? 0) + 1;
      }
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

  @override
  Widget build(BuildContext context) {
    final weekDays = getWeekDays(_weekBase);
    final weekRatio = getWeekSuccessRatio(_weekBase);
    final monthDays = getMonthDays(_month);
    final monthRecords = getMonthRecords();
    // 월간 달력: 1일이 무슨 요일인지, 마지막 날이 무슨 요일인지 계산
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // 0:일~6:토
    final lastWeekday = lastDay.weekday % 7;
    final daysBefore = firstWeekday; // 앞에 채울 빈 칸
    final daysAfter = 6 - lastWeekday; // 뒤에 채울 빈 칸
    final totalCells = daysBefore + monthDays.length + daysAfter;
    final gridRows = (totalCells / 7).ceil();
    
    // 주간 리스트 스크롤 및 카드별 키 관리 (SRP, DIP)
    final ScrollController _weekScrollController = ScrollController();
    final List<GlobalKey> _weekCardKeys = List.generate(weekDays.length, (_) => GlobalKey());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          // 주간/월간 전환 아이콘 버튼 (ToggleButtons 대신)
          IconButton(
            icon: Icon(_mode == CalendarMode.week ? Icons.calendar_view_month : Icons.calendar_view_week),
            tooltip: _mode == CalendarMode.week ? '월간 달력 보기' : '주간 달력 보기',
            onPressed: () {
              setState(() {
                _mode = _mode == CalendarMode.week ? CalendarMode.month : CalendarMode.week;
              });
            },
          ),
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
          // 상단 전환 UI 제거(아이콘 버튼으로 대체)
          if (_mode == CalendarMode.week) ...[
            // 기존 주간 UI 그대로 유지
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
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
                children: List.generate(weekDays.length, (i) {
                  final d = weekDays[i];
                  final emotion = getEmotionForDay(d);
                  return GestureDetector(
                    onTap: () {
                      // 날짜 클릭 시 해당 카드가 화면 중간에 오도록 스크롤 및 애니메이션 효과
                      setState(() {
                        _selectedWeekIndex = i;
                      });
                      final keyContext = _weekCardKeys[i].currentContext;
                      if (keyContext != null) {
                        Scrollable.ensureVisible(
                          keyContext,
                          duration: const Duration(milliseconds: 400),
                          alignment: 0.5, // 화면 중간
                        );
                      }
                      // 1초 후 애니메이션 해제
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                          setState(() {
                            _selectedWeekIndex = null;
                          });
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // overflow 방지
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                            border: (emotion != null && emotion.isNotEmpty)
                                ? Border.all(color: Colors.deepPurple, width: 2)
                                : null,
                          ),
                          child: Text(
                            emotion ?? '—',
                            style: const TextStyle(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}일',
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _weekScrollController,
                itemCount: weekDays.length,
                itemBuilder: (context, i) {
                  final d = weekDays[i];
                  final records = _recordBox.values.where((r) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day).toList();
                  final isSelected = _selectedWeekIndex == i;
                  return AnimatedContainer(
                    key: _weekCardKeys[i],
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.deepPurple, width: 3)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.15), blurRadius: 12, spreadRadius: 2)]
                          : [],
                    ),
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
                            final icon = habit?.icon ?? r.icon;
                            final name = habit?.name ?? r.name;
                            return Row(
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 4),
                                Text(name),
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
          ] else ...[
            // 월간 달력 UI - SRP(단일 책임), DIP(의존성 역전) 적용
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _month = DateTime(_month.year, _month.month - 1);
                      });
                    },
                  ),
                  Text('${_month.year}년 ${_month.month}월', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _month = DateTime(_month.year, _month.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('일', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('월', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('화', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('수', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('목', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('금', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('토', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0, // 셀 비율 고정(실제 크기는 SizedBox로)
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: gridRows * 7,
                itemBuilder: (context, idx) {
                  final dayNum = idx - daysBefore + 1;
                  if (idx < daysBefore || dayNum > monthDays.length) {
                    return const SizedBox.shrink();
                  }
                  final day = monthDays[dayNum - 1];
                  final records = monthRecords[day] ?? [];
                  final emotion = getEmotionForDay(day);
                  Color bgColor;
                  if (records.any((r) => r.status == 'success')) {
                    bgColor = Colors.green.shade100;
                  } else if (records.any((r) => r.status == 'fail')) {
                    bgColor = Colors.red.shade100;
                  } else {
                    bgColor = Colors.grey.shade200;
                  }
                  // 고정 크기 셀(SizedBox)로 오버플로우 방지, 내부 이모지/텍스트도 안전하게 배치
                  return GestureDetector(
                    onTap: () {
                      // 셀 클릭 시 해당 주간으로 전환만 수행, 팝업은 띄우지 않음
                      setState(() {
                        _weekBase = day;
                        _mode = CalendarMode.week;
                      });
                    },
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // overflow 방지
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(13),
                              border: (emotion != null && emotion.isNotEmpty)
                                  ? Border.all(color: Colors.deepPurple, width: 2)
                                  : null,
                            ),
                            child: Text(
                              emotion ?? '—',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: const TextStyle(fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
} 