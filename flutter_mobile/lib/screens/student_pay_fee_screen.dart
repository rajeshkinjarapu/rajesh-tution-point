import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class StudentPayFeeScreen extends StatefulWidget {
  const StudentPayFeeScreen({super.key});

  @override
  State<StudentPayFeeScreen> createState() => _StudentPayFeeScreenState();
}

class _StudentPayFeeScreenState extends State<StudentPayFeeScreen> {
  bool _isLoading = true;
  List<dynamic> _dueFees = [];
  dynamic _selectedFee;
  Map<String, dynamic> _settings = {};

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _utrController = TextEditingController();
  XFile? _imageFile;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is List<dynamic>) {
      _dueFees = args;
      if (_dueFees.isNotEmpty) {
        _selectedFee = _dueFees.first;
        _updateAmountField();
      }
    }
    _fetchSettings();
  }

  void _updateAmountField() {
    if (_selectedFee != null) {
      double due = double.tryParse(_selectedFee['amountDue']?.toString() ?? '0') ?? 0;
      _amountController.text = due.toStringAsFixed(0);
    }
  }

  Future<void> _fetchSettings() async {
    try {
      final response = await ApiService.getSettings();
      if (response != null && mounted) {
        setState(() {
          _settings = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load payment settings')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a fee type')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload the payment screenshot')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bytes = await _imageFile!.readAsBytes();
      final filename = _imageFile!.name;

      String feeStructureId = _selectedFee['feeStructure']?['id']?.toString() ?? '';

      final res = await ApiService.studentPayFeeWithScreenshot(
        amount: double.parse(_amountController.text),
        paymentMethod: 'UPI/BANK',
        referenceNumber: _utrController.text,
        feeStructureId: feeStructureId,
        imageBytes: bytes,
        imageFilename: filename,
      );

      if (res['success']) {
        if (mounted) {
          // Success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Payment Submitted!', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('మీ పేమెంట్‌ను అడ్మిన్ వెరిఫై చేస్తారు. ప్రాసెస్ కంప్లీట్ అవ్వగానే రసీదు జనరేట్ అవుతుంది.', 
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.center),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close screen
                    },
                    child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        _showError(res['message'] ?? 'Submission failed');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> settingsData = _settings['data'] ?? _settings;
    String? qrCodeUrl = settingsData['qrCodeUrl'];
    String? upiId = settingsData['upiId'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pay Fee', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF6366F1),
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
                      Text('Select Fee Type', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<dynamic>(
                        value: _selectedFee,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                        ),
                        items: _dueFees.map((fee) {
                          final name = fee['feeStructure']?['name'] ?? 'Unknown Fee';
                          final amountDue = double.tryParse(fee['amountDue']?.toString() ?? '0') ?? 0;
                          return DropdownMenuItem(
                            value: fee,
                            child: Text('$name (Due: ₹${amountDue.toStringAsFixed(0)})', style: GoogleFonts.poppins(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedFee = val;
                            _updateAmountField();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      Text('Enter Amount to Pay (₹)', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.currency_rupee_rounded),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      
                      const SizedBox(height: 32),
                      Center(
                        child: Text('Scan QR to Pay', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: qrCodeUrl != null && qrCodeUrl.isNotEmpty
                              ? Image.network(ApiService.getImageUrl(qrCodeUrl), height: 180, width: 180, fit: BoxFit.contain)
                              : const SizedBox(height: 180, width: 180, child: Center(child: Text('No QR Configured'))),
                        ),
                      ),
                      if (upiId != null && upiId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(child: Text('UPI: $upiId', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500))),
                      ],

                      const SizedBox(height: 32),
                      Text('Reference Number / UTR (Optional)', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _utrController,
                        decoration: InputDecoration(
                          hintText: 'Enter 12-digit UTR',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text('Upload Screenshot', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Builder(builder: (context) {
                                    if (kIsWeb) {
                                      return Image.network(_imageFile!.path, fit: BoxFit.cover);
                                    }
                                    return Image.file(File(_imageFile!.path), fit: BoxFit.cover);
                                  }),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 32),
                                    const SizedBox(height: 8),
                                    Text('Tap to upload', style: GoogleFonts.poppins(color: Colors.grey)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading 
          ? null 
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'I have paid the amount',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
    );
  }
}
