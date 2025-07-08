import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'record_model.dart';
import 'dart:math';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  List<DateTime> getRecentDays(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) => DateTime(now.year, now.month, now.day - (count - 1 - i)));
  }

  @override
  Widget build(BuildContext context) {
    final habitBox = Hive.box<HabitModel>('habits');
    final recordBox = Hive.box<RecordModel>('records');
    final habits = habitBox.values.toList();
    final records = recordBox.values.toList();
    final days = getRecentDays(14); // 최근 2주

    final validHabitIds = habits.map((h) => h.id).toSet();
    // 일자별 전체 성공률 계산
    List<double> dailyRates = days.map((d) {
      final dayRecords = records.where((r) =>
        r.date.year == d.year && r.date.month == d.month && r.date.day == d.day &&
        validHabitIds.contains(r.habitId)
      ).toList();
      final total = dayRecords.where((r) => r.status == 'success' || r.status == 'fail').length;
      if (total == 0) return 0.0;
      final success = dayRecords.where((r) => r.status == 'success').length;
      return (success / total) * 100;
    }).toList();

    // 목표별 전체 성공률 계산
    List<double> habitRates = habits.map((h) {
      final total = records.where((r) => r.habitId == h.id && (r.status == 'success' || r.status == 'fail')).length;
      if (total == 0) return 0.0;
      final success = records.where((r) => r.habitId == h.id && r.status == 'success').length;
      return (success / total) * 100;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('통계')), 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('목표별 성공/실패 통계', style: TextStyle(fontWeight: FontWeight.bold)),
              ...habits.map((h) {
                final total = records.where((r) => r.habitId == h.id && (r.status == 'success' || r.status == 'fail')).length;
                final success = records.where((r) => r.habitId == h.id && r.status == 'success').length;
                final fail = records.where((r) => r.habitId == h.id && r.status == 'fail').length;
                final rate = total == 0 ? 0.0 : (success / total) * 100;
                return Row(
                  children: [
                    Text(h.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(h.name),
                    const SizedBox(width: 8),
                    Text('성공률: ${rate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.blue)),
                    const SizedBox(width: 8),
                    Text('성공: $success', style: const TextStyle(color: Colors.green)),
                    const SizedBox(width: 4),
                    Text('실패: $fail', style: const TextStyle(color: Colors.red)),
                  ],
                );
              }),
              const SizedBox(height: 24),
              const Text('일자별 전체 성공률(최근 2주)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(days.length, (i) {
                    final rate = dailyRates[i];
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: rate,
                            width: 12,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 4),
                          Text('${days[i].day}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              const Text('목표별 전체 성공률', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(habits.length, (i) {
                    final rate = habitRates[i];
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: rate,
                            width: 24,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 4),
                          Text(habits[i].name, style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 