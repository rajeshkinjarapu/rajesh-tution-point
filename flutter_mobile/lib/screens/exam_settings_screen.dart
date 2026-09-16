import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';

class ExamSettingsScreen extends StatefulWidget {
  const ExamSettingsScreen({super.key});

  @override
  State<ExamSettingsScreen> createState() => _ExamSettingsScreenState();
}

class _ExamSettingsScreenState extends State<ExamSettingsScreen> {
  bool _autoPublishResults = false;
  bool _sendSmsOnPublish = true;
  bool _showGradesOnAdmitCard = false;
  String _selectedGradingSystem = 'CBSE Standard (A1-E2)';
  String _admitCardInstructions = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final res = await ApiService.getSettings();
    if (res['success'] && res['data'] != null) {
      final data = res['data'];
      setState(() {
        _autoPublishResults = data['examAutoPublish'] ?? false;
        _sendSmsOnPublish = data['examSendSms'] ?? true;
        _showGradesOnAdmitCard = data['examShowGradesOnAdmitCard'] ?? false;
        _selectedGradingSystem = data['examGradingSystem'] ?? 'CBSE Standard (A1-E2)';
        _admitCardInstructions = data['examAdmitCardInstructions'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final data = {
      'examAutoPublish': _autoPublishResults,
      'examSendSms': _sendSmsOnPublish,
      'examShowGradesOnAdmitCard': _showGradesOnAdmitCard,
      'examGradingSystem': _selectedGradingSystem,
      'examAdmitCardInstructions': _admitCardInstructions,
    };
    final res = await ApiService.updateSettings(data);
    if (!res['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      }
    }
  }

  void _updateSetting(VoidCallback updateAction) {
    setState(updateAction);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Exam Settings', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Grading & Evaluation', Icons.rule_rounded, const Color(0xFF4F46E5)),
            const SizedBox(height: 12),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildDropdownRow('Grading System', _selectedGradingSystem, ['CBSE Standard (A1-E2)', 'State Board (Points 10.0)', 'Percentage Only'], (val) {
                    if (val != null) _updateSetting(() => _selectedGradingSystem = val);
                  }),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildSwitchRow('Auto-Publish Results', 'Publish automatically after approval', _autoPublishResults, (val) => _updateSetting(() => _autoPublishResults = val)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Communications', Icons.message_rounded, const Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildSwitchRow('Send SMS on Publish', 'Notify parents when results are out', _sendSmsOnPublish, (val) => _updateSetting(() => _sendSmsOnPublish = val)),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildActionRow('Edit SMS Templates', 'Customize result messages', Icons.edit_note_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage SMS templates in the Web Admin Panel.')));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Admit Card & Reports', Icons.badge_rounded, const Color(0xFF10B981)),
            const SizedBox(height: 12),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildSwitchRow('Show Grades on Admit Card', 'Include previous grades on hall ticket', _showGradesOnAdmitCard, (val) => _updateSetting(() => _showGradesOnAdmitCard = val)),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildActionRow('Admit Card Instructions', 'Update default rules', Icons.list_alt_rounded, () {
                    _showInstructionsDialog();
                  }),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildActionRow('Signatures & Logos', 'Manage principal & teacher signatures', Icons.draw_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please update Logos & Signatures in the Global School Settings.')));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog() {
    final TextEditingController controller = TextEditingController(text: _admitCardInstructions);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Admit Card Instructions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter instructions here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              onPressed: () {
                _updateSetting(() => _admitCardInstructions = controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B))),
            ],
          ),
        ),
        CupertinoSwitch(value: value, onChanged: onChanged, activeColor: const Color(0xFF4F46E5)),
      ],
    );
  }

  Widget _buildDropdownRow(String title, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF4F46E5)),
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5)),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
