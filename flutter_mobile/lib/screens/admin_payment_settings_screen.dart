import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class AdminPaymentSettingsScreen extends StatefulWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  State<AdminPaymentSettingsScreen> createState() => _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState extends State<AdminPaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  XFile? _qrFile;
  String? _existingQr;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiService.getSettings();
      if (res != null) {
        setState(() {
          _bankNameCtrl.text = res['bankName'] ?? '';
          _accNoCtrl.text = res['bankAccountNumber'] ?? '';
          _ifscCtrl.text = res['bankIfsc'] ?? '';
          _upiCtrl.text = res['upiId'] ?? '';
          _existingQr = res['qrCodeUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load settings')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _qrFile = pickedFile;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      List<int>? fileBytes;
      String? fileName;

      if (_qrFile != null) {
        fileBytes = await _qrFile!.readAsBytes();
        fileName = _qrFile!.name;
      }

      final payload = {
        'bankName': _bankNameCtrl.text,
        'bankAccountNumber': _accNoCtrl.text,
        'bankIfsc': _ifscCtrl.text,
        'upiId': _upiCtrl.text,
      };

      final res = await ApiService.updateSettingsWithFile(
        fields: payload,
        fileBytes: fileBytes,
        filename: fileName,
      );

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved Successfully'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to save'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Payment Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4B497B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bank Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4B497B))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankNameCtrl,
                        decoration: InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accNoCtrl,
                        decoration: InputDecoration(labelText: 'Account Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ifscCtrl,
                        decoration: InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 32),

                      Text('UPI & QR Code', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4B497B))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _upiCtrl,
                        decoration: InputDecoration(labelText: 'UPI ID (e.g. school@ybl)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 16),

                      Text('Upload QR Code', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: _qrFile != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(14), child: kIsWeb ? Image.network(_qrFile!.path, fit: BoxFit.contain) : Image.file(File(_qrFile!.path), fit: BoxFit.contain))
                              : (_existingQr != null && _existingQr!.isNotEmpty)
                                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(ApiService.getImageUrl(_existingQr!), fit: BoxFit.contain))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text('Tap to select QR image', style: GoogleFonts.poppins(color: Colors.grey[500])),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: MediaQuery.of(context).padding.bottom > 0 ? 16.0 : 24.0),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B497B),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save Payment Setup', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
