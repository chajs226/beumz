import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'habit_edit_dialog.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({Key? key}) : super(key: key);

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  late Box<HabitModel> _habitBox;

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<HabitModel>('habits');
  }

  void _addOrEditHabit([HabitModel? habit]) async {
    showDialog(
      context: context,
      builder: (ctx) => HabitEditDialog(
        initial: habit,
        onSave: (h) async {
          if (habit == null) {
            await _habitBox.add(h);
          } else {
            habit
              ..name = h.name
              ..limitType = h.limitType
              ..icon = h.icon
              ..color = h.color;
            await habit.save();
          }
          setState(() {});
        },
      ),
    );
  }

  void _deleteHabit(HabitModel habit) async {
    await habit.delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final habits = _habitBox.values.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('비움 목표 관리'),
      ),
      body: habits.isEmpty
          ? const Center(child: Text('아직 등록된 목표가 없습니다.'))
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (ctx, i) {
                final h = habits[i];
                return Card(
                  color: Color(int.parse('0xFF${h.color.substring(1)}')),
                  child: ListTile(
                    leading: Text(h.icon, style: const TextStyle(fontSize: 28)),
                    title: Text(h.name),
                    subtitle: Text(h.limitType),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _addOrEditHabit(h),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteHabit(h),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditHabit(),
        child: const Icon(Icons.add),
        tooltip: '비움 목표 추가',
      ),
    );
  }
} 