import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fees_screen.dart';

class StudentFinanceDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const StudentFinanceDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Finance & Fees', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // Quick Access Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildServiceCard(
                  context: context,
                  title: 'Pay Fees',
                  subtitle: 'View dues & pay',
                  icon: Icons.account_balance_wallet_rounded,
                  colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                  },
                ),
                _buildServiceCard(
                  context: context,
                  title: 'Fee Receipts',
                  subtitle: 'Download invoices',
                  icon: Icons.receipt_long_rounded,
                  colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                  },
                ),
                _buildServiceCard(
                  context: context,
                  title: 'Fee Structure',
                  subtitle: 'Term wise details',
                  icon: Icons.account_tree_rounded,
                  colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee structure details coming soon')));
                  },
                ),
                _buildServiceCard(
                  context: context,
                  title: 'Transactions',
                  subtitle: 'Payment history',
                  icon: Icons.history_rounded,
                  colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Payment Support Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Issues?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Contact accounts department', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(icon, size: 90, color: colors.first.withOpacity(0.04)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.first.withOpacity(0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: colors.first, size: 28),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle, 
                        style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
