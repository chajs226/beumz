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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('목표 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${habit.name}" 목표를 삭제하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이전에 기록한 데이터는 삭제되지 않고 보존됩니다.',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // habit만 삭제하고, 연관된 record들은 보존
      await habit.delete();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('목표가 삭제되었습니다. 이전 기록은 보존됩니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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