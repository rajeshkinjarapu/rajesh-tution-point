import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'id_card_students_screen.dart';

class IdCardTemplatesScreen extends StatefulWidget {
  const IdCardTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<IdCardTemplatesScreen> createState() => _IdCardTemplatesScreenState();
}

class _IdCardTemplatesScreenState extends State<IdCardTemplatesScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.8);

  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'template_1',
      'name': 'Standard Vertical',
      'description': 'Classic vertical ID card with prominent logo and details.',
      'color': Colors.blue.shade800,
      'is_horizontal': false,
    },
    {
      'id': 'template_2',
      'name': 'Horizontal Corporate',
      'description': 'Modern horizontal layout suitable for staff and students.',
      'color': Colors.indigo.shade900,
      'is_horizontal': true,
    },
    {
      'id': 'template_3',
      'name': 'Gradient Premium',
      'description': 'Vibrant gradient design for a premium look.',
      'color': Colors.purple.shade700,
      'is_horizontal': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        title: Text('Select ID Design',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Swipe to explore our premium collection of ID Card templates.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                final bool isActive = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: isActive ? 0 : 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: template['color'].withOpacity(isActive ? 0.2 : 0.05),
                        blurRadius: isActive ? 20 : 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: isActive ? template['color'] : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: _buildMockTemplate(template['color'], template['is_horizontal']),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(22),
                            bottomRight: Radius.circular(22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['name'],
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              template['description'],
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _templates.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? _templates[_currentIndex]['color'] : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IdCardStudentsScreen(
                        templateId: _templates[_currentIndex]['id'],
                        templateColor: _templates[_currentIndex]['color'],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _templates[_currentIndex]['color'],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 0,
                ),
                child: Text(
                  'Use this Design',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTemplate(Color primaryColor, bool isHorizontal) {
    if (isHorizontal) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(width: 8, color: primaryColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: 100, color: primaryColor.withOpacity(0.5)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Container(height: 60, width: 50, color: Colors.grey.shade200),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 8, width: double.infinity, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Container(height: 8, width: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Container(height: 8, width: 80, color: Colors.grey.shade300),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      );
    } else {
      return Container(
        width: 160,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(height: 40, color: primaryColor),
            const SizedBox(height: 15),
            Container(height: 60, width: 50, color: Colors.grey.shade200),
            const SizedBox(height: 15),
            Container(height: 8, width: 100, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Container(height: 8, width: 60, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Container(height: 8, width: 80, color: Colors.grey.shade300),
            const Spacer(),
            Container(height: 30, color: Colors.amber.shade400),
          ],
        ),
      );
    }
  }
}
