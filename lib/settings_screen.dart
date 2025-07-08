import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'habit_model.dart';
import 'user_id_util.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<HabitModel> _habitBox;
  String? _userName;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<HabitModel>('habits');
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await UserIdUtil.getUserName();
    setState(() {
      _userName = name;
      _nameController.text = name ?? '';
    });
  }

  Future<void> _saveUserName() async {
    await UserIdUtil.saveUserName(_nameController.text.trim());
    setState(() {
      _userName = _nameController.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임이 변경되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정/알림')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('닉네임 변경'),
            subtitle: Text(_userName ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('닉네임 변경'),
                    content: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '닉네임'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
                      ElevatedButton(onPressed: () {
                        _saveUserName();
                        Navigator.of(ctx).pop();
                      }, child: const Text('저장')),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('목표별 알림 시간 설정'),
            subtitle: Text('미구현: 실제 알림 기능은 추후 연동'),
            trailing: Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            title: const Text('데이터 백업/복원'),
            subtitle: const Text('미구현: 추후 로컬/클라우드 연동'),
            trailing: const Icon(Icons.backup),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('추후 지원 예정입니다.')));
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('앱 정보'),
            subtitle: Text('Beumz v1.0.0\nFlutter 기반 감성 습관 앱'),
          ),
        ],
      ),
    );
  }
} 