import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'record_model.dart';
import 'record_edit_dialog.dart';
import 'habit_list_screen.dart';
import 'daily_emotion_model.dart';
import 'dart:math';

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
  late String _cheerMessage;

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<HabitModel>('habits');
    _recordBox = Hive.box<RecordModel>('records');
    _emotionBox = Hive.box<DailyEmotionModel>('daily_emotion');
    _cheerMessage = _cheerMessages[Random().nextInt(_cheerMessages.length)];
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
                      onPressed: () => setState(() => status = 'success'),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(Icons.cancel, color: status == 'fail' ? Colors.red : Colors.grey, size: 36),
                      onPressed: () => setState(() => status = 'fail'),
                    ),
                  ],
                ),
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
                      ..memo = memo;
                    await existing.save();
                  } else {
                    await _recordBox.add(RecordModel(
                      date: _today,
                      habitId: habit.id,
                      status: status!,
                      emotion: '',
                      memo: memo,
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

  @override
  Widget build(BuildContext context) {
    final habits = _habitBox.values.toList();
    final todayRecords = getTodayRecords();
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 비움 목표'),
        actions: [
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
                    GestureDetector(
                      onTap: _showEmotionDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.deepPurple, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          getTodayEmotion()?.emotion ?? '선택',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: habits.isEmpty
                ? const Center(child: Text('등록된 비움 목표가 없습니다.'))
                : ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (ctx, i) {
                      final h = habits[i];
                      final recList = todayRecords.where((r) => r.habitId == h.id).toList();
                      final rec = recList.isNotEmpty ? recList.first : null;
                      IconData statusIcon;
                      Color statusColor;
                      if (rec == null) {
                        statusIcon = Icons.radio_button_unchecked;
                        statusColor = Colors.grey;
                      } else if (rec.status == 'success') {
                        statusIcon = Icons.check_circle;
                        statusColor = Colors.green;
                      } else {
                        statusIcon = Icons.cancel;
                        statusColor = Colors.red;
                      }
                      return Card(
                        color: Color(int.parse('0xFF${h.color.substring(1)}')),
                        child: ListTile(
                          onTap: () => _showRecordDialog(h, rec),
                          onLongPress: rec?.memo?.isNotEmpty == true ? () => _showMemoDialog(rec!.memo) : null,
                          leading: Text(h.icon, style: const TextStyle(fontSize: 28)),
                          title: Text(h.name),
                          subtitle: Row(
                            children: [
                              Icon(statusIcon, color: statusColor),
                              const SizedBox(width: 8),
                              Text(h.limitType, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          trailing: rec?.memo?.isNotEmpty == true
                              ? IconButton(
                                  icon: const Icon(Icons.sticky_note_2),
                                  onPressed: () => _showMemoDialog(rec!.memo),
                                )
                              : null,
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