import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'record_model.dart';
import 'record_edit_dialog.dart';
import 'habit_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<HabitModel> _habitBox;
  late Box<RecordModel> _recordBox;
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<HabitModel>('habits');
    _recordBox = Hive.box<RecordModel>('records');
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

  void _checkHabit(HabitModel habit, String status) async {
    final existing = getRecordForHabit(habit.id);
    if (status == 'fail') {
      showDialog(
        context: context,
        builder: (ctx) => RecordEditDialog(
          initial: existing,
          onSave: (record) async {
            if (existing != null) {
              existing
                ..status = 'fail'
                ..emotion = record.emotion
                ..memo = record.memo;
              await existing.save();
            } else {
              await _recordBox.add(record);
            }
            setState(() {});
          },
          habitId: habit.id,
          status: 'fail',
        ),
      );
    } else {
      if (existing != null) {
        existing
          ..status = 'success'
          ..emotion = ''
          ..memo = '';
        await existing.save();
      } else {
        await _recordBox.add(RecordModel(
          date: _today,
          habitId: habit.id,
          status: 'success',
          emotion: '',
          memo: '',
        ));
      }
      setState(() {});
    }
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
      body: habits.isEmpty
          ? const Center(child: Text('등록된 비움 목표가 없습니다.'))
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (ctx, i) {
                final h = habits[i];
                final recList = todayRecords.where((r) => r.habitId == h.id).toList();
                final rec = recList.isNotEmpty ? recList.first : null;
                return Card(
                  color: Color(int.parse('0xFF${h.color.substring(1)}')),
                  child: ListTile(
                    leading: Text(h.icon, style: const TextStyle(fontSize: 28)),
                    title: Text(h.name),
                    subtitle: Text(h.limitType),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: rec?.status == 'success',
                          onChanged: (v) => _checkHabit(h, v == true ? 'success' : 'fail'),
                        ),
                        if (rec?.status == 'fail')
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.red),
                            onPressed: () => _checkHabit(h, 'fail'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 