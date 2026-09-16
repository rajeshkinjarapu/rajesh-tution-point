import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> submission;
  final Map<String, dynamic> exam;

  const QuizResultScreen({Key? key, required this.submission, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final obtainedMarks = submission['marksObtained'] ?? 0;
    final totalMarks = exam['totalMarks'] ?? 100;
    final percentage = (obtainedMarks / totalMarks) * 100;
    final isPass = percentage >= (exam['passMarks'] ?? 35);
    
    // Assume questions array is returned inside submission (if detailed)
    final responses = submission['responses'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Quiz Result'),
        elevation: 0,
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(
                color: Colors.purple[800],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isPass ? 'Congratulations!' : 'Better Luck Next Time!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    exam['title'],
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 32),
                  
                  // Score Circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(isPass ? Colors.green : Colors.red),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isPass ? Colors.green : Colors.red),
                            ),
                            Text(
                              '$obtainedMarks / $totalMarks',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Questions', '${responses.length}', FontAwesomeIcons.clipboardQuestion, Colors.blue),
                      SizedBox(width: 16),
                      _buildStatCard('Result', isPass ? 'PASS' : 'FAIL', isPass ? FontAwesomeIcons.check : FontAwesomeIcons.xmark, isPass ? Colors.green : Colors.red),
                    ],
                  ),
                  SizedBox(height: 32),
                  
                  // Answers review (if backend sends it)
                  if (responses.isNotEmpty) ...[
                    Text('Detailed Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: responses.length,
                      itemBuilder: (context, index) {
                        final r = responses[index];
                        final isCorrect = r['isCorrect'] == true;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FaIcon(
                                    isCorrect ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
                                    color: isCorrect ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      r['question']['questionText'] ?? 'Question Text',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Answer: ${r['selectedOption'] ?? 'None'}', 
                                      style: TextStyle(color: isCorrect ? Colors.green[700] : Colors.red[700], fontSize: 13)
                                    ),
                                    if (!isCorrect)
                                      Text('Correct Answer: ${r['question']['correctAnswer'] ?? 'Unknown'}', 
                                        style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.w500)
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, dynamic icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
