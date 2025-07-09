import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'record_model.dart';
import 'record_edit_dialog.dart';
import 'habit_list_screen.dart';
import 'daily_emotion_model.dart';
import 'dart:math';
import 'calendar_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show Time;
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:beumz_app/main.dart' show flutterLocalNotificationsPlugin;
import 'package:collection/collection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<HabitModel> _habitBox;
  late Box<RecordModel> _recordBox;
  late Box<DailyEmotionModel> _emotionBox;
  DateTime _today = DateTime.now();
  final List<String> _cheerMessages = [
    '오늘도 잘 비워보자! 🌱',
    '작은 실천이 큰 변화를 만듭니다.',
    '실패해도 괜찮아요, 다시 시작하면 돼요.',
    '비움의 하루, 멋지게 보내세요!',
    '포기하지 않는 당신이 멋져요.',
    '오늘의 한 걸음이 내일의 변화를 만듭니다.',
    '스스로를 칭찬해 주세요!',
    '습관은 작은 선택에서 시작됩니다.',
    '오늘도 나를 위해 한 번 더!',
    '실패는 성장의 씨앗입니다.',
    '비움의 용기, 당신에게 박수를!',
    '조금씩, 천천히, 꾸준히!',
    '오늘의 비움, 내일의 자유!',
    '나를 믿고 한 번 더 도전!',
    '작은 성공이 쌓여 큰 변화를!',
    '오늘도 수고했어요.',
    '비움의 기록, 멋진 선택입니다.',
    '실패해도 괜찮아요. 다시 시작!',
    '나만의 속도로, 나만의 방식으로.',
    '오늘도 비움 챌린지 파이팅!'
  ];

  final List<String> _successMessages = [
    '👏 정말 대단해요! 오늘도 성공했네요!',
    '🎉 훌륭합니다! 비움의 첫 걸음을 잘 해냈어요!',
    '✨ 멋져요! 이런 식으로 계속해보세요!',
    '🌟 완벽해요! 스스로를 자랑스러워하세요!',
    '💪 강한 의지력이네요! 계속 화이팅!',
    '🏆 오늘의 승자는 바로 당신입니다!',
    '🎯 목표 달성! 정말 멋진 선택이었어요!',
    '🔥 열정이 느껴져요! 이대로 쭉 가세요!',
    '🌱 성장하는 모습이 보기 좋아요!',
    '💎 소중한 변화의 순간이에요!',
    '🚀 계속 이런 식으로 날아오르세요!',
    '🎪 축하합니다! 오늘도 이겨냈네요!',
    '🌈 빛나는 하루를 만들어가고 있어요!',
    '⭐ 별처럼 반짝이는 성공이에요!',
    '🎵 성공의 멜로디가 들려오네요!',
    '🏅 금메달감 실천력이에요!',
    '🦋 나비처럼 아름다운 변화네요!',
    '🎨 인생이라는 캔버스에 멋진 색칠을!',
    '🌸 꽃처럼 피어나는 좋은 습관이에요!',
    '💫 별빛처럼 빛나는 하루였어요!'
  ];

  final List<String> _failMessages = [
    '😤 어? 뭐하는 거야? 이래서는 안 되지!',
    '🙄 또 실패했네... 정신 좀 차려봐!',
    '😒 이런 식으로 하면 언제 성공해?',
    '🤨 진짜로 바꿀 생각이 있는 거야?',
    '😏 실패하면서 배우는 것도 나쁘지 않지만...',
    '🥲 아이고... 다음엔 좀 더 신경 써봐!',
    '😅 괜찮아, 모든 영웅에게는 실패가 있어!',
    '🤗 실패해도 괜찮아요, 다시 일어서면 돼요!',
    '🫂 힘들었겠어요, 그래도 내일은 다를 거예요!',
    '💪 실패는 성공의 어머니라고 하잖아요!',
    '🌱 씨앗이 자라려면 시간이 필요해요!',
    '🔄 다시 시작하는 것도 용기예요!',
    '🎯 과녁을 맞추려면 여러 번 쏴야죠!',
    '📚 실패에서 배우는 것이 더 많아요!',
    '🌅 내일은 새로운 기회가 있어요!',
    '🎪 넘어져도 다시 일어서는 게 진짜 실력!',
    '🌊 파도처럼 밀려와도 다시 일어서요!',
    '🍀 행운은 준비된 자에게 온다고 해요!',
    '🎈 풍선처럼 다시 부풀어 오르세요!',
    '🌙 달도 차고 기우니까, 괜찮아요!'
  ];
  late String _cheerMessage;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _habitBox = Hive.box<HabitModel>('habits');
    _recordBox = Hive.box<RecordModel>('records');
    _emotionBox = Hive.box<DailyEmotionModel>('daily_emotion');
    _cheerMessage = _cheerMessages[Random().nextInt(_cheerMessages.length)];
    scheduleDailyNotificationIfNeeded(_habitBox, _recordBox, _emotionBox);
  }

  List<RecordModel> getTodayRecords() {
    return _recordBox.values.where((r) =>
      r.date.year == _today.year && r.date.month == _today.month && r.date.day == _today.day
    ).toList();
  }

  RecordModel? getRecordForHabit(String habitId) {
    final list = getTodayRecords().where((r) => r.habitId == habitId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  DailyEmotionModel? getTodayEmotion() {
    final list = _emotionBox.values.where((e) =>
      e.date.year == _today.year && e.date.month == _today.month && e.date.day == _today.day
    ).toList();
    return list.isNotEmpty ? list.first : null;
  }

  void _setTodayEmotion(String emotion) async {
    final existing = getTodayEmotion();
    if (existing != null) {
      existing.emotion = emotion;
      await existing.save();
    } else {
      await _emotionBox.add(DailyEmotionModel(date: _today, emotion: emotion));
    }
    setState(() {});
  }

  void _showRecordDialog(HabitModel habit, RecordModel? existing) {
    showDialog(
      context: context,
      builder: (ctx) {
        String? status = existing?.status;
        String memo = existing?.memo ?? '';
        String? motivationMessage;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('기록 입력'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check_circle, color: status == 'success' ? Colors.green : Colors.grey, size: 36),
                      onPressed: () => setState(() {
                        status = 'success';
                        motivationMessage = _successMessages[Random().nextInt(_successMessages.length)];
                      }),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(Icons.cancel, color: status == 'fail' ? Colors.red : Colors.grey, size: 36),
                      onPressed: () => setState(() {
                        status = 'fail';
                        motivationMessage = _failMessages[Random().nextInt(_failMessages.length)];
                      }),
                    ),
                  ],
                ),
                if (motivationMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status == 'success' ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: status == 'success' ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      motivationMessage!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: status == 'success' ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: memo),
                  onChanged: (v) => memo = v,
                  decoration: const InputDecoration(labelText: '메모(선택)'),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: status == null ? null : () async {
                  if (existing != null) {
                    existing
                      ..status = status!
                      ..memo = memo
                      ..name = habit.name
                      ..icon = habit.icon;
                    await existing.save();
                  } else {
                    await _recordBox.add(RecordModel(
                      date: _today,
                      habitId: habit.id,
                      status: status!,
                      emotion: '',
                      memo: memo,
                      name: habit.name,
                      icon: habit.icon,
                    ));
                  }
                  setState(() {});
                  Navigator.of(context).pop();
                  this.setState(() {});
                },
                child: const Text('저장'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemoDialog(String memo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모'),
        content: Text(memo),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('닫기'))],
      ),
    );
  }

  void _showEmotionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오늘의 감정 선택'),
        content: Wrap(
          spacing: 12,
          children: ['😊','😐','😢','😠','😰','😎','🥲','🤔'].map((e) => GestureDetector(
            onTap: () {
              _setTodayEmotion(e);
              Navigator.of(ctx).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(e, style: const TextStyle(fontSize: 32)),
            ),
          )).toList(),
        ),
      ),
    );
  }

  // 주간 시작(월요일)~종료(일요일) 날짜 반환
  List<DateTime> getCurrentWeekDays() {
    final now = _today;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // limitType에서 주간 제한 횟수 추출 (예: '주 3회 이하' → 3)
  int? parseWeeklyLimit(String limitType) {
    final reg = RegExp(r'주 (\d+)회 이하');
    final match = reg.firstMatch(limitType);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  // 이번 주 해당 습관의 성공/실패/총 시도 횟수 집계
  Map<String, int> getWeeklyStatus(String habitId) {
    final weekDays = getCurrentWeekDays();
    final records = _recordBox.values.where((r) =>
      r.habitId == habitId &&
      weekDays.any((d) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day)
    );
    int success = records.where((r) => r.status == 'success').length;
    int fail = records.where((r) => r.status == 'fail').length;
    int total = records.length;
    return {'success': success, 'fail': fail, 'total': total};
  }

  @override
  Widget build(BuildContext context) {
    final habits = _habitBox.values.toList();
    final todayRecords = getTodayRecords();
    final weekDays = getCurrentWeekDays();
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 비움 목표'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '캘린더/통계',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '목표 관리',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HabitListScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('오늘의 감정: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: _showEmotionDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTodayEmotion()?.emotion ?? '😊',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            getTodayEmotion()?.emotion != null ? '변경' : '선택',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, i) {
                final h = habits[i];
                final rec = getRecordForHabit(h.id);
                final weekly = getWeeklyStatus(h.id);
                final limit = parseWeeklyLimit(h.limitType);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: rec != null 
                    ? (rec.status == 'success' ? Colors.green.shade50 : Colors.red.shade50)
                    : null,
                  child: Container(
                    decoration: rec != null 
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rec.status == 'success' ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        )
                      : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(h.icon, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              if (rec != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: rec.status == 'success' ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        rec.status == 'success' ? Icons.check : Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        rec.status == 'success' ? '성공' : '실패',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    '미기록',
                                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              if (limit != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('주 $limit회 이하', style: const TextStyle(fontSize: 13, color: Colors.deepPurple)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 주간 달력/상태 표시
                          Row(
                            children: weekDays.map((d) {
                              final r = _recordBox.values.firstWhereOrNull(
                                (r) => r.habitId == h.id && r.date.year == d.year && r.date.month == d.month && r.date.day == d.day,
                              );
                              Color color;
                              IconData icon;
                              if (r == null) {
                                color = Colors.grey.shade300;
                                icon = Icons.remove;
                              } else if (r.status == 'success') {
                                color = Colors.green.shade300;
                                icon = Icons.check;
                              } else {
                                color = Colors.red.shade200;
                                icon = Icons.close;
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(['월','화','수','목','금','토','일'][d.weekday-1], style: const TextStyle(fontSize: 10)),
                                    Icon(icon, size: 16),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          if (limit != null)
                            Text('이번 주 남은 횟수: ${limit - (weekly['success']! + weekly['fail']!)}회', style: const TextStyle(fontSize: 13, color: Colors.deepPurple)),
                          Text(h.limitType, style: const TextStyle(fontSize: 13)),
                          // 기존 기록 입력/수정 버튼 등은 그대로 유지
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _showRecordDialog(h, rec),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rec == null 
                                    ? Colors.deepPurple 
                                    : (rec.status == 'success' ? Colors.green : Colors.red),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(rec == null ? '기록하기' : '수정하기'),
                              ),
                              if (rec != null && rec.memo.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.sticky_note_2),
                                  onPressed: () => _showMemoDialog(rec.memo),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _cheerMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> scheduleDailyNotificationIfNeeded(Box<HabitModel> habitBox, Box<RecordModel> recordBox, Box<DailyEmotionModel> emotionBox) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final habits = habitBox.values.toList();
  final records = recordBox.values.where((r) =>
    r.date.year == today.year && r.date.month == today.month && r.date.day == today.day
  ).toList();
  final emotion = emotionBox.values.where((e) =>
    e.date.year == today.year && e.date.month == today.month && e.date.day == today.day
  ).toList();
  final hasAnyRecord = habits.any((h) => records.any((r) => r.habitId == h.id && (r.status == 'success' || r.status == 'fail')));
  final hasEmotion = emotion.isNotEmpty;
  if (!hasAnyRecord && !hasEmotion) {
    final scheduledDate = tz.TZDateTime.local(now.year, now.month, now.day, 20);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '오늘의 비움을 기록하세요',
      '아직 비움 성공/실패나 오늘의 기분을 입력하지 않았어요!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('beumz_channel', 'Beumz 알림', channelDescription: '비움 기록 알림'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } else {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
} 