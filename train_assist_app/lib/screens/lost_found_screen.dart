import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lost_found_provider.dart';
import '../providers/user_provider.dart';
import '../services/local_data_service.dart';
import '../models/lost_found_model.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _local = LocalDataService();

  // Form fields
  String? _selTrainName;
  final _coachCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  LostFoundStatus _itemStatus = LostFoundStatus.lost;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _coachCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reporterName = context.read<UserProvider>().userName ?? 'Anonymous';
    if (_selTrainName == null) {
      _snack('Please select a train', Colors.red);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please describe the item', Colors.red);
      return;
    }

    final item = LostFoundItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reporterName: reporterName,
      trainName: _selTrainName!,
      coachNumber: _coachCtrl.text.trim().isEmpty
          ? 'Unknown'
          : _coachCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      status: _itemStatus,
      reportedAt: DateTime.now(),
    );

    await context.read<LostFoundProvider>().addItem(item);

    if (mounted) {
      _snack('✅ Report submitted!', Colors.green);
      setState(() {
        _selTrainName = null;
        _itemStatus = LostFoundStatus.lost;
      });
      _coachCtrl.clear();
      _descCtrl.clear();
      _tabs.animateTo(item.status == LostFoundStatus.lost ? 1 : 2);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LostFoundProvider>();
    final trains = _local.searchTrains();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(icon: Icon(Icons.report), text: 'Report'),
            Tab(
                icon: const Icon(Icons.search),
                text: 'Lost (${prov.lostItems.length})'),
            Tab(
                icon: const Icon(Icons.check_circle),
                text: 'Found (${prov.foundItems.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildReportTab(trains),
          _buildListTab(prov.lostItems, Colors.red[700]!, 'No lost reports'),
          _buildListTab(
              prov.foundItems, Colors.green[700]!, 'No found reports'),
        ],
      ),
    );
  }

  Widget _buildReportTab(List trains) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status toggle
          Row(
            children: [
              const Text('Reporting: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('I Lost Something'),
                selected: _itemStatus == LostFoundStatus.lost,
                selectedColor: Colors.red[100],
                onSelected: (_) =>
                    setState(() => _itemStatus = LostFoundStatus.lost),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('I Found Something'),
                selected: _itemStatus == LostFoundStatus.found,
                selectedColor: Colors.green[100],
                onSelected: (_) =>
                    setState(() => _itemStatus = LostFoundStatus.found),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Train', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.train),
            ),
            hint: const Text('Select train'),
            value: _selTrainName,
            items: trains
                .map((t) => DropdownMenuItem<String>(
                      value: t.trainName as String,
                      child: Text(
                          '${t.trainName} (${t.source} → ${t.destination})',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selTrainName = v),
          ),
          const SizedBox(height: 16),

          const Text('Coach / Compartment (optional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _coachCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.event_seat),
              hintText: 'e.g. B2, S4, A1',
            ),
          ),
          const SizedBox(height: 16),

          const Text('Describe the Item',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'e.g. Black leather wallet with blue strap, Samsung phone...',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Be specific! Auto-matching uses keywords to connect lost & found reports.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: Icon(
                  _itemStatus == LostFoundStatus.lost
                      ? Icons.report_problem
                      : Icons.add_task),
              label: Text(
                  _itemStatus == LostFoundStatus.lost
                      ? 'Submit Lost Report'
                      : 'Submit Found Report',
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _itemStatus == LostFoundStatus.lost
                    ? Colors.red[700]
                    : Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(
      List<LostFoundItem> items, Color accent, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isMatched = item.status == LostFoundStatus.matched;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMatched)
                Container(
                  width: double.infinity,
                  color: Colors.green[50],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text('✅ Matched with another report!',
                          style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      item.status == LostFoundStatus.lost ? Colors.red : Colors.green,
                  child: Icon(
                    item.status == LostFoundStatus.lost
                        ? Icons.search
                        : Icons.check,
                    color: Colors.white,
                  ),
                ),
                title: Text(item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚂 ${item.trainName} · Coach ${item.coachNumber}'),
                    Text('Reported by ${item.reporterName} · ${_formatDate(item.reportedAt)}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
