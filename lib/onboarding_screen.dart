import 'package:flutter/material.dart';
import 'user_id_util.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key, required this.onFinish}) : super(key: key);
  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _pageIndex = 0;
  final PageController _controller = PageController();
  final TextEditingController _nameController = TextEditingController();
  bool _nameValid = false;

  final List<Map<String, String>> _slides = [
    {
      'title': '비움의 시작',
      'desc': '가득한 하루를 비워내세요. Beumz는 하지 않을 일을 기록하는 감성 습관 앱입니다.'
    },
    {
      'title': '습관, 감정, 기록',
      'desc': '오늘의 비움 목표를 체크하고, 실패 시 감정도 기록해보세요.'
    },
    {
      'title': '절제력 성장',
      'desc': '성공/실패를 달력과 통계로 확인하며, 자기관리를 이어가세요.'
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_pageIndex < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // 마지막 슬라이드: 이름 입력
      setState(() {
        _pageIndex++;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await UserIdUtil.saveUserName(name);
    await UserIdUtil.ensureDeviceId();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F1),
      body: SafeArea(
        child: _pageIndex < _slides.length
            ? Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemCount: _slides.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_slides[i]['title']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            Text(_slides[i]['desc']!, style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: i == _pageIndex ? Colors.deepPurple : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_pageIndex == _slides.length - 1 ? '이름 입력' : '다음'),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('닉네임을 입력하세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: '이름(닉네임)', border: OutlineInputBorder()),
                      onChanged: (v) => setState(() => _nameValid = v.trim().isNotEmpty),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _nameValid ? _finishOnboarding : null,
                      child: const Text('시작하기'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
} 