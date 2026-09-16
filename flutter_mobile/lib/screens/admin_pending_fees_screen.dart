import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminPendingFeesScreen extends StatefulWidget {
  const AdminPendingFeesScreen({super.key});

  @override
  State<AdminPendingFeesScreen> createState() => _AdminPendingFeesScreenState();
}

class _AdminPendingFeesScreenState extends State<AdminPendingFeesScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingFees();
  }

  Future<void> _fetchPendingFees() async {
    try {
      final response = await ApiService.getPendingFeeApprovals();
      if (response['success'] == true || response is List) {
        setState(() {
          _pendingPayments = response['data'] ?? response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load pending approvals')));
    }
  }

  Future<void> _handleApproval(String paymentId, bool approve) async {
    try {
      final response = await ApiService.approveFeePayment(paymentId, approve: approve);
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Payment Approved!' : 'Payment Rejected'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ));
        _fetchPendingFees(); // Refresh list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing request: $e')));
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            child: Image.network(
              ApiService.getImageUrl(imageUrl),
              fit: BoxFit.contain,
              errorBuilder: (ctx, _, __) => Container(color: Colors.white, padding: const EdgeInsets.all(20), child: const Text('Image not found')),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Pending Approvals', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFB91C1C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
                      const SizedBox(height: 16),
                      Text('All Caught Up!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      Text('No pending payments to verify.', style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingPayments.length,
                  itemBuilder: (context, index) {
                    final payment = _pendingPayments[index];
                    return _buildPaymentCard(payment);
                  },
                ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final student = payment['student'] ?? {};
    final amount = payment['amount'] ?? 0;
    final utr = payment['referenceNumber'] ?? 'N/A';
    final screenshot = payment['screenshotUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student['name'] ?? 'Unknown Student', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Class: ${student['class']?['name'] ?? 'N/A'}', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('₹$amount', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[700])),
                      Text('UTR: $utr', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13)),
                    ],
                  ),
                ),
                if (screenshot != null)
                  GestureDetector(
                    onTap: () => _showImageDialog(screenshot),
                    child: Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ApiService.getImageUrl(screenshot),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleApproval(payment['id'], false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApproval(payment['id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
