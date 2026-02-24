import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medical_profile_provider.dart';
import '../models/medical_profile_model.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  bool _editMode = false;

  // Form controllers
  final _ec1Name = TextEditingController();
  final _ec1Phone = TextEditingController();
  final _ec2Name = TextEditingController();
  final _ec2Phone = TextEditingController();
  final _docName = TextEditingController();
  final _docPhone = TextEditingController();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();

  String _bloodGroup = 'Not Set';
  static const _bloodGroups = [
    'Not Set', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prov = context.read<MedicalProfileProvider>();
    if (prov.hasProfile) _loadIntoForm(prov.profile);
  }

  void _loadIntoForm(MedicalProfile p) {
    _bloodGroup = _bloodGroups.contains(p.bloodGroup) ? p.bloodGroup : 'Not Set';
    _allergies.text = p.allergies;
    _conditions.text = p.conditions;
    _ec1Name.text = p.emergencyContact1Name;
    _ec1Phone.text = p.emergencyContact1Phone;
    _ec2Name.text = p.emergencyContact2Name;
    _ec2Phone.text = p.emergencyContact2Phone;
    _docName.text = p.doctorName;
    _docPhone.text = p.doctorPhone;
  }

  Future<void> _save() async {
    final profile = MedicalProfile(
      bloodGroup: _bloodGroup,
      allergies: _allergies.text.trim(),
      conditions: _conditions.text.trim(),
      emergencyContact1Name: _ec1Name.text.trim(),
      emergencyContact1Phone: _ec1Phone.text.trim(),
      emergencyContact2Name: _ec2Name.text.trim(),
      emergencyContact2Phone: _ec2Phone.text.trim(),
      doctorName: _docName.text.trim(),
      doctorPhone: _docPhone.text.trim(),
    );
    await context.read<MedicalProfileProvider>().saveProfile(profile);
    if (mounted) {
      setState(() => _editMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Medical profile saved'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _ec1Name.dispose(); _ec1Phone.dispose();
    _ec2Name.dispose(); _ec2Phone.dispose();
    _docName.dispose(); _docPhone.dispose();
    _allergies.dispose(); _conditions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MedicalProfileProvider>();
    final hasProfile = prov.hasProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Profile'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit profile',
              onPressed: () {
                if (hasProfile) _loadIntoForm(prov.profile);
                setState(() => _editMode = true);
              },
            ),
          if (hasProfile && !_editMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear profile',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: hasProfile && !_editMode
          ? _buildHealthCard(prov.profile)
          : _buildEditForm(),
    );
  }

  // ─── Health Card View ────────────────────────────────────────────────────────
  Widget _buildHealthCard(MedicalProfile p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.red.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.medical_services, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text('EMERGENCY HEALTH CARD',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('TrainAssist • Show this card in emergencies',
                    style: TextStyle(
                        color: Colors.white.withAlpha(200), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Blood group
          _infoCard(
            icon: Icons.bloodtype,
            iconColor: Colors.red,
            title: 'Blood Group',
            value: p.bloodGroup,
            big: true,
          ),

          // Medical info
          if (p.allergies.isNotEmpty)
            _infoCard(
              icon: Icons.warning_amber,
              iconColor: Colors.orange,
              title: 'Allergies ⚠️',
              value: p.allergies,
            ),
          if (p.conditions.isNotEmpty)
            _infoCard(
              icon: Icons.monitor_heart,
              iconColor: Colors.purple,
              title: 'Medical Conditions',
              value: p.conditions,
            ),

          const Divider(height: 32),
          const Row(children: [
            Icon(Icons.phone_in_talk, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Contacts',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),

          if (p.emergencyContact1Name.isNotEmpty)
            _contactCard('Contact 1', p.emergencyContact1Name,
                p.emergencyContact1Phone, Colors.red[50]!),
          if (p.emergencyContact2Name.isNotEmpty)
            _contactCard('Contact 2', p.emergencyContact2Name,
                p.emergencyContact2Phone, Colors.orange[50]!),
          if (p.doctorName.isNotEmpty)
            _contactCard('Doctor / Hospital', p.doctorName, p.doctorPhone,
                Colors.blue[50]!),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadIntoForm(p);
              setState(() => _editMode = true);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String value,
      bool big = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withAlpha(30),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title,
            style: TextStyle(
                color: Colors.grey[600], fontSize: 12)),
        subtitle: Text(value,
            style: TextStyle(
                fontSize: big ? 28 : 15,
                fontWeight: FontWeight.bold,
                color: iconColor)),
      ),
    );
  }

  Widget _contactCard(
      String label, String name, String phone, Color bg) {
    return Card(
      color: bg,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.person, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600])),
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (phone.isNotEmpty)
                    Text(phone,
                        style: const TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Edit Form ───────────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Basic Medical Info', Icons.health_and_safety,
              Colors.red),
          const SizedBox(height: 12),

          const Text('Blood Group',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _bloodGroup,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bloodtype, color: Colors.red),
            ),
            items: _bloodGroups
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _bloodGroup = v ?? 'Not Set'),
          ),
          const SizedBox(height: 16),

          const Text('Allergies (comma-separated)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _allergies,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. Penicillin, Peanuts, Dust',
              prefixIcon: Icon(Icons.warning_amber, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Medical Conditions',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _conditions,
            maxLines: 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. Diabetes Type 2, Hypertension',
              prefixIcon: Icon(Icons.monitor_heart, color: Colors.purple),
            ),
          ),
          const SizedBox(height: 24),

          _sectionHeader(
              'Emergency Contacts', Icons.phone_in_talk, Colors.red),
          const SizedBox(height: 12),

          _contactFields(
              'Primary Contact (Family/Friend)', _ec1Name, _ec1Phone),
          const SizedBox(height: 16),
          _contactFields('Secondary Contact', _ec2Name, _ec2Phone),
          const SizedBox(height: 16),
          _contactFields('Doctor / Hospital', _docName, _docPhone),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Profile',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_editMode) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _editMode = false),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _contactFields(
      String label, TextEditingController nameCt, TextEditingController phoneCt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: nameCt,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: phoneCt,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.call),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Medical Profile?'),
        content: const Text(
            'This will permanently delete all your medical data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<MedicalProfileProvider>().clearProfile();
      setState(() => _editMode = false);
    }
  }
}
