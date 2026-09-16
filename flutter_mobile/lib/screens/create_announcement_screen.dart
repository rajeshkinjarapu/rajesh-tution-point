import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic>? announcementData;
  const CreateAnnouncementScreen({super.key, this.announcementData});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _priority = 'NORMAL';
  String _targetRoles = ''; // Empty means All
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcementData != null) {
      _titleController.text = widget.announcementData!['title'] ?? '';
      _contentController.text = widget.announcementData!['content'] ?? '';
      _priority = widget.announcementData!['priority'] ?? 'NORMAL';
      _targetRoles = widget.announcementData!['targetRoles'] ?? '';
    }
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'priority': _priority,
      'targetRoles': _targetRoles,
    };

    final isEditing = widget.announcementData != null;
    final res = isEditing
        ? await ApiService.updateAnnouncement(widget.announcementData!['id'].toString(), payload)
        : await ApiService.createAnnouncement(payload);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Announcement updated!' : 'Announcement created successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to signal refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? (isEditing ? 'Failed to update' : 'Failed to create announcement')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.announcementData != null ? 'Edit Announcement' : 'Create Announcement',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Announcement Details'),
              const SizedBox(height: 16),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration('Title', Icons.title_rounded),
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              
              // Content Field
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: _buildInputDecoration('Content', Icons.segment_rounded),
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (val) => val == null || val.trim().isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Settings'),
              const SizedBox(height: 16),
              
              // Target Audience Dropdown
              DropdownButtonFormField<String>(
                value: _targetRoles,
                decoration: _buildInputDecoration('Target Audience', Icons.group_rounded),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All (Students & Teachers)')),
                  DropdownMenuItem(value: 'STUDENT', child: Text('Students Only')),
                  DropdownMenuItem(value: 'TEACHER', child: Text('Teachers Only')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _targetRoles = val);
                },
              ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: _buildInputDecoration('Priority', Icons.low_priority_rounded),
                items: const [
                  DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High / Urgent')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _priority = val);
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.announcementData != null ? 'Update Announcement' : 'Publish Announcement', 
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
