import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class IdCardPreviewScreen extends StatefulWidget {
  final String templateId;
  final Color templateColor;
  final Map<String, dynamic> studentData;

  const IdCardPreviewScreen({
    Key? key,
    required this.templateId,
    required this.templateColor,
    required this.studentData,
  }) : super(key: key);

  @override
  State<IdCardPreviewScreen> createState() => _IdCardPreviewScreenState();
}

class _IdCardPreviewScreenState extends State<IdCardPreviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    _isFront = !_isFront;
  }

  void _handleDownloadPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading PDF... (Placeholder for PDF generation)')),
    );
    // TODO: Implement PDF generation using `pdf` and `printing` packages
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing to share... (Placeholder for share functionality)')),
    );
    // TODO: Implement Share functionality using `share_plus`
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.studentData['user'] ?? {};
    final classData = widget.studentData['class'] ?? {};
    
    final String name = user['name'] ?? 'Unknown';
    final String rollNo = widget.studentData['rollNo'] ?? '';
    final String photoUrl = ApiService.getImageUrl(user['photoUrl']);
    final String className = classData['name'] ?? '';
    final String section = classData['section'] ?? '';
    final String bloodGroup = widget.studentData['bloodGroup'] ?? 'N/A';
    final String phone = user['phone'] ?? 'N/A';

    final bool isHorizontal = widget.templateId == 'template_2';
    final double cardWidth = isHorizontal ? 320 : 210;
    final double cardHeight = isHorizontal ? 210 : 320;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: AppBar(
        title: Text('Live Preview', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: _toggleFlip,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final angle = _animation.value * pi;
                  final isUnder = angle > pi / 2;
                  
                  return Transform(
                    transform: Matrix4.rotationY(angle),
                    alignment: Alignment.center,
                    child: isUnder
                        ? Transform(
                            transform: Matrix4.rotationY(pi),
                            alignment: Alignment.center,
                            child: _buildBackCard(cardWidth, cardHeight),
                          )
                        : _buildFrontCard(
                            cardWidth, cardHeight, name, rollNo, photoUrl, className, section, bloodGroup, phone),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, color: Colors.grey.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tap the card to flip',
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleShare,
                      icon: Icon(Icons.share, color: widget.templateColor),
                      label: Text('Share', style: GoogleFonts.inter(color: widget.templateColor, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: widget.templateColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleDownloadPdf,
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: Text('Save PDF', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.templateColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(double width, double height, String name, String rollNo, String photoUrl, String className, String section, String bloodGroup, String phone) {
    if (widget.templateId == 'template_2') {
      return _buildHorizontalCorporate(width, height, name, rollNo, photoUrl, className, section, bloodGroup);
    } else if (widget.templateId == 'template_3') {
      return _buildGradientPremium(width, height, name, rollNo, photoUrl, className, section, bloodGroup);
    } else {
      return _buildStandardVertical(width, height, name, rollNo, photoUrl, className, section, bloodGroup, phone);
    }
  }

  Widget _buildStandardVertical(double width, double height, String name, String rollNo, String photoUrl, String className, String section, String bloodGroup, String phone) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.templateColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 24),
                  const SizedBox(height: 4),
                  Text('JY INTERNATIONAL SCHOOL', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 85,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 2),
                      image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                      color: Colors.grey.shade200,
                    ),
                    child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey, size: 40) : null,
                  ),
                  const SizedBox(height: 8),
                  Text(name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  _infoRow('Class', '$className - $section'),
                  _infoRow('ID No', rollNo),
                  _infoRow('Blood', bloodGroup, isRed: true),
                  _infoRow('Phone', phone),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Container(width: 40, height: 1, color: Colors.black87),
                    const SizedBox(height: 2),
                    Text('Principal', style: GoogleFonts.inter(fontSize: 9, fontStyle: FontStyle.italic)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  color: Colors.white,
                  child: QrImageView(data: rollNo, version: QrVersions.auto, size: 30),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalCorporate(double width, double height, String name, String rollNo, String photoUrl, String className, String section, String bloodGroup) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(width: 8, decoration: const BoxDecoration(color: Colors.lightBlue, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JY INTERNATIONAL SCHOOL', style: GoogleFonts.inter(color: widget.templateColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('123 Main Street, Education Hub', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 8)),
                        ],
                      ),
                      const Icon(Icons.school, color: Colors.grey, size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 75,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                          color: Colors.grey.shade200,
                        ),
                        child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey, size: 30) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('STUDENT', style: GoogleFonts.inter(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 9)),
                            const SizedBox(height: 6),
                            _infoRowHoriz('ID No:', rollNo),
                            _infoRowHoriz('Class:', '$className - $section'),
                            _infoRowHoriz('Blood:', bloodGroup),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                QrImageView(data: rollNo, version: QrVersions.auto, size: 40),
                const SizedBox(height: 12),
                Container(width: 40, height: 1, color: Colors.black54),
                const SizedBox(height: 2),
                Text('Auth Sign', style: GoogleFonts.inter(fontSize: 7, fontStyle: FontStyle.italic, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGradientPremium(double width, double height, String name, String rollNo, String photoUrl, String className, String section, String bloodGroup) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF7E22CE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text('JY INTERNATIONAL SCHOOL', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Positioned(
            top: 50,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30), bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 45, 16, 12),
              child: Column(
                children: [
                  Text(name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF9333EA)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('STUDENT', style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  _gradInfoRow('ID No', rollNo),
                  _gradInfoRow('Class', '$className $section'),
                  _gradInfoRow('Blood', bloodGroup, isRed: true),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: QrImageView(data: rollNo, size: 30)),
                      Column(
                        children: [
                          Container(width: 50, height: 1, color: Colors.grey.shade400),
                          const SizedBox(height: 2),
                          Text('Principal', style: GoogleFonts.inter(fontSize: 8, color: Colors.grey.shade600)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          Positioned(
            top: 30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
              ),
              child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey, size: 40) : null,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBackCard(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.templateColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Text('TERMS & CONDITIONS', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bulletPoint('This card is the property of JY International School.'),
                  _bulletPoint('Must be worn at all times while in the school premises.'),
                  _bulletPoint('If lost, report immediately to the administration.'),
                  _bulletPoint('This card is non-transferable.'),
                  _bulletPoint('Valid for the current academic year only.'),
                  const Spacer(),
                  const Divider(),
                  Center(
                    child: Column(
                      children: [
                        Text('If found, please return to:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 9)),
                        Text('JY International School', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 9)),
                        Text('123 Main Street, Education Hub', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 8)),
                        Text('Ph: +91 98765 43210', style: GoogleFonts.inter(fontSize: 8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: QrImageView(data: 'Return to Rajesh Tution Point', size: 30))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade800))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
          Text(value, style: GoogleFonts.inter(fontSize: 10, fontWeight: isRed ? FontWeight.bold : FontWeight.normal, color: isRed ? Colors.red : Colors.black87)),
        ],
      ),
    );
  }

  Widget _infoRowHoriz(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade800))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 9, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _gradInfoRow(String label, String value, {bool isRed = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          Text(value, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.grey.shade800)),
        ],
      ),
    );
  }
}
