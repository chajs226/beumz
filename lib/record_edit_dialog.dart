import 'package:flutter/material.dart';
import 'record_model.dart';

class RecordEditDialog extends StatefulWidget {
  final RecordModel? initial;
  final void Function(RecordModel record) onSave;
  final String habitId;
  final String status; // 'success' or 'fail'
  const RecordEditDialog({Key? key, this.initial, required this.onSave, required this.habitId, required this.status}) : super(key: key);

  @override
  State<RecordEditDialog> createState() => _RecordEditDialogState();
}

class _RecordEditDialogState extends State<RecordEditDialog> {
  String _emotion = '';
  final _memoController = TextEditingController();
  final _emotions = ['😊', '😐', '😢', '😠', '😰', '😎', '🥲', '🤔'];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _emotion = widget.initial!.emotion;
      _memoController.text = widget.initial!.memo;
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.status == 'success' ? '성공 기록' : '실패/감정 기록'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.status == 'fail') ...[
              const Text('감정 선택'),
              Wrap(
                spacing: 8,
                children: _emotions.map((e) => ChoiceChip(
                  label: Text(e, style: const TextStyle(fontSize: 20)),
                  selected: _emotion == e,
                  onSelected: (_) => setState(() => _emotion = e),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: '메모(선택)'),
                maxLines: 2,
              ),
            ]
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
            widget.onSave(RecordModel(
              date: DateTime.now(),
              habitId: widget.habitId,
              status: widget.status,
              emotion: widget.status == 'fail' ? _emotion : '',
              memo: widget.status == 'fail' ? _memoController.text.trim() : '',
              name: '', // 실제 사용처에서 올바른 값 전달 필요
              icon: '', // 실제 사용처에서 올바른 값 전달 필요
            ));
            Navigator.of(context).pop();
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
} 