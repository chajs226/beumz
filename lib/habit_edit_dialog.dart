import 'package:flutter/material.dart';
import 'habit_model.dart';
import 'dart:math';

class HabitEditDialog extends StatefulWidget {
  final HabitModel? initial;
  final void Function(HabitModel habit) onSave;
  const HabitEditDialog({Key? key, this.initial, required this.onSave}) : super(key: key);

  @override
  State<HabitEditDialog> createState() => _HabitEditDialogState();
}

class _HabitEditDialogState extends State<HabitEditDialog> {
  final _nameController = TextEditingController();
  String _limitType = '매일 금지';
  String _icon = '🌱';
  String _color = '#FDF9F2';

  final _limitTypes = ['매일 금지', '주 3회 이하', '주 1회 이하'];
  final _iconList = ['🌱', '🍔', '📱', '🛒', '🎮', '🧃', '🛏️', '💸'];
  final _colorList = ['#FDF9F2', '#FDF9F1', '#FFFDF8', '#F2F2F2', '#F3F3F2'];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _limitType = widget.initial!.limitType;
      _icon = widget.initial!.icon;
      _color = widget.initial!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '비움 목표 추가' : '비움 목표 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '목표 이름'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _limitType,
              items: _limitTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _limitType = v!),
              decoration: const InputDecoration(labelText: '제한 조건'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('아이콘: '),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _iconList.map((e) => GestureDetector(
                        onTap: () => setState(() => _icon = e),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: _icon == e ? Colors.deepPurple : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 20)),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('색상: '),
                ..._colorList.map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${c.substring(1)}')),
                      border: Border.all(color: _color == c ? Colors.deepPurple : Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            widget.onSave(HabitModel(
              id: widget.initial?.id ?? UniqueKey().toString(),
              name: _nameController.text.trim(),
              limitType: _limitType,
              icon: _icon,
              color: _color,
            ));
            Navigator.of(context).pop();
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
} 