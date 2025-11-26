import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/repositories/mock_repository.dart';

class CustomerSegmentManagerSheet extends StatefulWidget {
  final AppLocalizations t;
  final MockCustomerRepository repository;

  const CustomerSegmentManagerSheet({
    super.key,
    required this.t,
    required this.repository,
  });

  @override
  State<CustomerSegmentManagerSheet> createState() =>
      _CustomerSegmentManagerSheetState();
}

class _CustomerSegmentManagerSheetState
    extends State<CustomerSegmentManagerSheet> {
  final TextEditingController _segmentCtrl = TextEditingController();
  List<String> _segments = [];
  bool _loading = true;
  String? _error;
  String? _editingOriginal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _segmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final segments = await widget.repository.fetchSegments();
      if (!mounted) return;
      setState(() {
        _segments = segments;
        _loading = false;
        _editingOriginal = null;
        _segmentCtrl.clear();
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = err.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.customersSegmentManagerTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                t.customersSegmentManagerDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _segmentCtrl,
                decoration: InputDecoration(
                  labelText: t.customersFormSegment,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_editingOriginal != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _editingOriginal = null;
                          _segmentCtrl.clear();
                        });
                      },
                      child: Text(t.categoryManagerCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saveSegment,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _editingOriginal == null
                          ? t.categoryManagerAdd
                          : t.categoryManagerUpdate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final t = widget.t;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_segments.isEmpty) {
      return Center(child: Text(t.categoryManagerEmpty));
    }
    return ListView.separated(
      itemCount: _segments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final name = _segments[index];
        return Card(
          child: ListTile(
            title: Text(name),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      _editingOriginal = name;
                      _segmentCtrl.text = name;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(name),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSegment() async {
    final label = _segmentCtrl.text.trim();
    if (label.isEmpty) return;
    await widget.repository.upsertSegment(
      label,
      original: _editingOriginal,
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _confirmDelete(String name) async {
    final t = widget.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.categoryManagerDelete),
          content: Text(t.categoryManagerDeleteConfirm(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.orderEditCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.categoryManagerDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await widget.repository.deleteSegment(name);
    if (!mounted) return;
    context.read<NotificationTicker>().push(t.categoryManagerDeleted);
    await _load();
  }
}
