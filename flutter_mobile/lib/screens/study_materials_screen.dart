import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _questionPapers = [];
  List<dynamic> _generatedPapers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait<Map<String, dynamic>>([
      ApiService.getQuestionPapers(),
      ApiService.getGeneratedPapers(),
    ]);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (results[0]['success']) {
          _questionPapers = results[0]['data'] ?? [];
        }
        if (results[1]['success']) {
          _generatedPapers = results[1]['data'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      drawer: AppDrawer(currentRoute: 'studymaterials'),
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Study Materials',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E2A66), Color(0xFF222854)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Question Papers'),
            Tab(text: 'Generated Papers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaperList(_questionPapers, 'No Question Papers Available', Icons.menu_book_rounded),
                _buildPaperList(_generatedPapers, 'No Generated Papers Available', Icons.description_rounded),
              ],
            ),
    );
  }

  Widget _buildPaperList(List<dynamic> papers, String emptyMsg, IconData emptyIcon) {
    if (papers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: papers.length,
      itemBuilder: (context, index) {
        final paper = papers[index];
        return _buildPaperCard(paper);
      },
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper) {
    final title = paper['title'] ?? 'Untitled Paper';
    final subject = (paper['subject'] != null && paper['subject'] is Map) 
        ? paper['subject']['name'] ?? 'Subject' 
        : 'General';
    final createdAt = paper['createdAt']?.toString().split('T')[0] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF818CF8)),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subject.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Added on $createdAt',
              style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 11),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Downloading paper PDF...')),
            );
          },
        ),
      ),
    );
  }
}


