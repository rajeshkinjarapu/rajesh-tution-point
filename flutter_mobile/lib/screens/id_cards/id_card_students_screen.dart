import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'id_card_preview_screen.dart';

class IdCardStudentsScreen extends StatefulWidget {
  final String templateId;
  final Color templateColor;

  const IdCardStudentsScreen({
    Key? key,
    required this.templateId,
    required this.templateColor,
  }) : super(key: key);

  @override
  State<IdCardStudentsScreen> createState() => _IdCardStudentsScreenState();
}

class _IdCardStudentsScreenState extends State<IdCardStudentsScreen> {
  bool _isLoading = false;
  List<dynamic> _classes = [];
  List<dynamic> _students = [];
  String? _selectedClassId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getClasses();
    if (res['success'] == true) {
      setState(() {
        _classes = res['data'] ?? [];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    final res = await ApiService.getStudents(
      classId: _selectedClassId,
      search: _searchController.text,
      limit: 200,
    );
    if (res['success'] == true) {
      setState(() {
        _students = res['data'] ?? [];
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Select Student',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (_classes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Select Class & Section', style: GoogleFonts.inter()),
                        value: _selectedClassId,
                        items: _classes.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text('${c['name']} - ${c['section']}', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClassId = val;
                          });
                          _fetchStudents();
                        },
                      ),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => _fetchStudents(),
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: widget.templateColor))
                : _students.isEmpty
                    ? Center(
                        child: Text(
                          _selectedClassId == null
                              ? 'Please select a class first.'
                              : 'No students found.',
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final user = student['user'] ?? {};
                          final String name = user['name'] ?? 'Unknown';
                          final String rollNo = student['rollNo'] ?? '';
                          final String photoUrl = ApiService.getImageUrl(user['photoUrl']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                )
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: widget.templateColor.withOpacity(0.1),
                                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                child: photoUrl.isEmpty
                                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(color: widget.templateColor, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              subtitle: Text('ID: $rollNo', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: widget.templateColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IdCardPreviewScreen(
                                      templateId: widget.templateId,
                                      templateColor: widget.templateColor,
                                      studentData: student,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
