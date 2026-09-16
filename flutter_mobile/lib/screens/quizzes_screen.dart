import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'take_quiz_screen.dart';
import 'quiz_result_screen.dart';

class QuizzesScreen extends StatefulWidget {
  @override
  _QuizzesScreenState createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _isLoading = true;
  List<dynamic> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getOnlineExams();
      if (res['success'] == true) {
        setState(() {
          _exams = res['data'] ?? [];
        });
      }
    } catch (e) {
      print('Failed to fetch online exams: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleExamClick(dynamic exam) {
    if (exam['submission'] != null) {
      // Already submitted
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(submission: exam['submission'], exam: exam),
        ),
      );
    } else {
      // Not submitted, check time
      final now = DateTime.now();
      final startTime = DateTime.parse(exam['startTime']).toLocal();
      final endTime = DateTime.parse(exam['endTime']).toLocal();

      if (now.isBefore(startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz starts at ${DateFormat('MMM d, h:mm a').format(startTime)}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (now.isAfter(endTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz has already ended'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Can take exam
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TakeQuizScreen(examId: exam['id']),
        ),
      ).then((_) => _fetchExams()); // refresh on return
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Online Quizzes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[700]!, Colors.deepPurple[900]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_exams.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.clipboardQuestion, size: 64, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text('No quizzes available', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exam = _exams[index];
                    final hasSubmitted = exam['submission'] != null;
                    final startTime = DateTime.parse(exam['startTime']).toLocal();
                    final isUpcoming = DateTime.now().isBefore(startTime);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _handleExamClick(exam),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: hasSubmitted ? Colors.green[50] : (isUpcoming ? Colors.orange[50] : Colors.purple[50]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: FaIcon(
                                      hasSubmitted ? FontAwesomeIcons.checkDouble : (isUpcoming ? FontAwesomeIcons.lock : FontAwesomeIcons.pen),
                                      color: hasSubmitted ? Colors.green : (isUpcoming ? Colors.orange : Colors.purple),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exam['title'] ?? 'Quiz',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${exam['subject']['name']} • ${exam['duration']} mins',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                      Text(DateFormat('MMM dd, yyyy').format(startTime), style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Marks', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                      Text('${exam['totalMarks']}', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: hasSubmitted ? Colors.green : (isUpcoming ? Colors.grey[300] : Colors.purple),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      hasSubmitted ? 'View Result' : (isUpcoming ? 'Starts Later' : 'Start Quiz'),
                                      style: TextStyle(
                                        color: hasSubmitted ? Colors.white : (isUpcoming ? Colors.grey[700] : Colors.white),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _exams.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
