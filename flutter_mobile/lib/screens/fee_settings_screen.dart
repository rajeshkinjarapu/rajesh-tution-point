import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class FeeSettingsScreen extends StatefulWidget {
  const FeeSettingsScreen({super.key});

  @override
  State<FeeSettingsScreen> createState() => _FeeSettingsScreenState();
}

class _FeeSettingsScreenState extends State<FeeSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _feeGroups = [];
  List<dynamic> _feeHeads = [];
  List<dynamic> _feeConcessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getFeeGroups(),
      ApiService.getFeeHeads(),
      ApiService.getFeeConcessions(),
    ]);
    if (mounted) {
      setState(() {
        _feeGroups      = results[0]['success'] ? (results[0]['data'] ?? []) : [];
        _feeHeads       = results[1]['success'] ? (results[1]['data'] ?? []) : [];
        _feeConcessions = results[2]['success'] ? (results[2]['data'] ?? []) : [];
        _loading = false;
      });
    }
  }

  // ── Add helpers ─────────────────────────────────────────────────────────────

  void _showAddGroupDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    _showFormDialog(
      title: 'Add Fee Group',
      icon: Icons.layers_rounded,
      iconColor: const Color(0xFF10B981),
      fields: [
        _dialogField(nameCtrl, 'Group Name *', 'e.g. Academic Fee'),
        const SizedBox(height: 12),
        _dialogField(descCtrl, 'Description', 'Optional description'),
      ],
      onSave: () async {
        if (nameCtrl.text.trim().isEmpty) return false;
        final r = await ApiService.createFeeGroup({'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()});
        return r['success'] == true;
      },
    );
  }

  void _showAddHeadDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedGroupId;
    _showFormDialog(
      title: 'Add Fee Head',
      icon: Icons.monetization_on_rounded,
      iconColor: const Color(0xFFD97706),
      fields: [
        StatefulBuilder(builder: (ctx, setSt) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee Group *', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedGroupId,
                  isExpanded: true,
                  hint: Text('Select Group', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8))),
                  items: _feeGroups.map((g) => DropdownMenuItem<String?>(
                    value: g['id'] as String?,
                    child: Text(g['name'] ?? '', style: GoogleFonts.poppins(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setSt(() => selectedGroupId = v),
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B)),
                  dropdownColor: Colors.white,
                  isDense: true,
                ),
              ),
            ),
          ],
        )),
        const SizedBox(height: 12),
        _dialogField(nameCtrl, 'Head Name *', 'e.g. Tuition Fee'),
        const SizedBox(height: 12),
        _dialogField(descCtrl, 'Description', 'Optional description'),
      ],
      onSave: () async {
        if (nameCtrl.text.trim().isEmpty || selectedGroupId == null) return false;
        final r = await ApiService.createFeeHead({'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'groupId': selectedGroupId});
        return r['success'] == true;
      },
    );
  }

  void _showAddConcessionDialog() {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String cType = 'PERCENT';
    _showFormDialog(
      title: 'Add Fee Concession',
      icon: Icons.local_offer_rounded,
      iconColor: const Color(0xFFE11D48),
      fields: [
        _dialogField(nameCtrl, 'Concession Name *', 'e.g. Merit Scholarship'),
        const SizedBox(height: 12),
        StatefulBuilder(builder: (ctx, setSt) => Row(
          children: [
            Expanded(child: _dialogDropdown<String>(
              value: cType,
              items: const [
                DropdownMenuItem(value: 'PERCENT', child: Text('Percentage (%)')),
                DropdownMenuItem(value: 'FLAT', child: Text('Flat Amount (₹)')),
              ],
              onChanged: (v) => setSt(() => cType = v ?? 'PERCENT'),
              label: 'Type',
            )),
            const SizedBox(width: 12),
            Expanded(child: _dialogField(valueCtrl, cType == 'PERCENT' ? 'Value (%)' : 'Amount (₹)', '0', type: TextInputType.number)),
          ],
        )),
      ],
      onSave: () async {
        if (nameCtrl.text.trim().isEmpty || valueCtrl.text.trim().isEmpty) return false;
        final r = await ApiService.createFeeConcession({'name': nameCtrl.text.trim(), 'type': cType, 'value': double.tryParse(valueCtrl.text) ?? 0});
        return r['success'] == true;
      },
    );
  }

  void _showFormDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> fields,
    required Future<bool> Function() onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool saving = false;
        String error = '';
        return StatefulBuilder(builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: iconColor, size: 20)),
                    const SizedBox(width: 10),
                    Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF1E293B))),
                  ]),
                  GestureDetector(onTap: () => Navigator.pop(ctx),
                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)))),
                ]),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error, style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 12))),
                    ])),
                ],
                const SizedBox(height: 20),
                ...fields,
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF64748B))))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: saving ? null : () async {
                      setSt(() { saving = true; error = ''; });
                      final ok = await onSave();
                      if (!ok) {
                        setSt(() { saving = false; error = 'Please fill all required fields.'; });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadAll();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  )),
                ]),
              ],
            ),
          ),
        ));
      },
    );
  }

  Future<void> _deleteItem(String endpoint, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this item?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    await ApiService.deleteItem('$endpoint/$id');
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Fee Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Fee Groups'),
            Tab(text: 'Fee Heads'),
            Tab(text: 'Concessions'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final idx = _tabController.index;
          if (idx == 0) _showAddGroupDialog();
          else if (idx == 1) _showAddHeadDialog();
          else _showAddConcessionDialog();
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add New', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsList(),
                _buildHeadsList(),
                _buildConcessionsList(),
              ],
            ),
    );
  }

  // ── Tab content builders ──────────────────────────────────────────────────

  Widget _buildGroupsList() => _buildItemList(
    items: _feeGroups,
    icon: Icons.layers_rounded,
    color: const Color(0xFF10B981),
    bgColor: const Color(0xFFF0FDF4),
    emptyMsg: 'No fee groups yet.\nTap + to add one.',
    nameKey: 'name',
    descKey: 'description',
    onDelete: (id) => _deleteItem('/api/fees/groups', id),
  );

  Widget _buildHeadsList() => _buildItemList(
    items: _feeHeads,
    icon: Icons.monetization_on_rounded,
    color: const Color(0xFFD97706),
    bgColor: const Color(0xFFFFFBEB),
    emptyMsg: 'No fee heads yet.\nTap + to add one.',
    nameKey: 'name',
    descKey: 'description',
    badgeKey: 'group',
    badgeNestedKey: 'name',
    onDelete: (id) => _deleteItem('/api/fees/heads', id),
  );

  Widget _buildConcessionsList() => _buildItemList(
    items: _feeConcessions,
    icon: Icons.local_offer_rounded,
    color: const Color(0xFFE11D48),
    bgColor: const Color(0xFFFFF1F2),
    emptyMsg: 'No concessions yet.\nTap + to add one.',
    nameKey: 'name',
    valueFn: (item) {
      final type = item['type'] ?? 'PERCENT';
      final value = item['value'] ?? 0;
      return type == 'PERCENT' ? '$value%' : '₹$value';
    },
    onDelete: (id) => _deleteItem('/api/fees/concessions', id),
  );

  Widget _buildItemList({
    required List<dynamic> items,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String emptyMsg,
    required String nameKey,
    String? descKey,
    String? badgeKey,
    String? badgeNestedKey,
    String Function(dynamic)? valueFn,
    required Future<void> Function(String) onDelete,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 40)),
          const SizedBox(height: 16),
          Text(emptyMsg, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final name = item[nameKey]?.toString() ?? '';
          final desc = descKey != null ? item[descKey]?.toString() ?? '' : '';
          final badge = badgeKey != null
              ? (badgeNestedKey != null 
                  ? (item[badgeKey] != null ? item[badgeKey][badgeNestedKey]?.toString() : null)
                  : item[badgeKey]?.toString()) ?? ''
              : '';
          final value = valueFn != null ? valueFn(item) : '';
          final id = item['id']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (desc.isNotEmpty) Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                  if (badge.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(badge, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  ],
                ],
              ),
              trailing: IconButton(
                onPressed: () => onDelete(id),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Form helpers ─────────────────────────────────────────────────────────

  Widget _dialogField(TextEditingController ctrl, String label, String hint, {TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFCBD5E1)),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _dialogDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(value: value, items: items, onChanged: onChanged, isExpanded: true, isDense: true,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
              dropdownColor: Colors.white),
          ),
        ),
      ],
    );
  }
}
