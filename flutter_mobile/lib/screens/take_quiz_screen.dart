import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';

class TakeQuizScreen extends StatefulWidget {
  final String examId;

  const TakeQuizScreen({Key? key, required this.examId}) : super(key: key);

  @override
  _TakeQuizScreenState createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _exam;
  List<dynamic> _questions = [];
  Map<String, String> _answers = {}; // questionId -> selectedOption
  
  PageController _pageController = PageController();
  int _currentIndex = 0;
  
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchExamDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Anti-cheat mechanism: warn if app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // User minimized the app during exam
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Do not minimize the app during the exam!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _fetchExamDetails() async {
    try {
      final res = await ApiService.getOnlineExamDetails(widget.examId);
      if (res['success'] == true) {
        setState(() {
          _exam = res['data'];
          _questions = _exam!['questions'] ?? [];
          _remainingSeconds = (_exam!['duration'] as int) * 60;
          _isLoading = false;
        });
        _startTimer();
      } else {
        _showErrorAndExit(res['message'] ?? 'Failed to load exam');
      }
    } catch (e) {
      _showErrorAndExit('Network error occurred');
    }
  }

  void _showErrorAndExit(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitExam(autoSubmit: true);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Exam?'),
        content: Text('Are you sure you want to exit? Your progress will be lost and it may count as an attempt.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Exit', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _submitExam({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!autoSubmit) {
      final confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Submit Exam?'),
          content: Text('You have answered ${_answers.length} out of ${_questions.length} questions. Are you sure you want to submit?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              child: Text('Submit', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    // Backend expects a Map of { questionId: selectedOption }
    Map<String, String> submitAnswers = {};
    _answers.forEach((qId, ans) {
      submitAnswers[qId] = ans;
    });

    try {
      final res = await ApiService.submitOnlineExam(widget.examId, submitAnswers);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exam submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to quiz list, it will redirect to result
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to submit'), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error during submission'), backgroundColor: Colors.red));
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: Text('No questions found for this exam.')),
      );
    }

    final isWarningTime = _remainingSeconds < 300; // less than 5 mins

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(_exam!['title']),
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isWarningTime ? Colors.red[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isWarningTime ? Colors.red : Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: isWarningTime ? Colors.red : Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isWarningTime ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 4,
            ),
            
            // Question Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${_questions.length}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  Text(
                    'Marks: ${_questions[_currentIndex]['marks']}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
                  ),
                ],
              ),
            ),

            // PageView for Questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final List<dynamic> options = q['options'];
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['questionText'],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                        SizedBox(height: 32),
                        ...options.map((opt) {
                          final isSelected = _answers[q['id']] == opt;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _answers[q['id']] = opt;
                                });
                                // Auto next after 500ms
                                if (index < _questions.length - 1) {
                                  Future.delayed(Duration(milliseconds: 500), () {
                                    if (mounted) {
                                      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                                    }
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.purple[50] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.purple : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSelected ? Colors.purple : Colors.grey[400]!, width: 2),
                                      ),
                                      child: isSelected 
                                          ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple)))
                                          : null,
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? Colors.purple[900] : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          bottom: true,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentIndex > 0
                    ? TextButton(
                        onPressed: () {
                          _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        child: Text('Previous'),
                      )
                    : SizedBox(width: 80), // placeholder to maintain center alignment
                
                // Submit Button
                _isSubmitting
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => _submitExam(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text('Submit Exam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),

                _currentIndex < _questions.length - 1
                    ? TextButton(
                        onPressed: () {
                          _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        child: Text('Next'),
                      )
                    : SizedBox(width: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
