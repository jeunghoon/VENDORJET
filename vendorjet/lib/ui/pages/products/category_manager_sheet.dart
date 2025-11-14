import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class CategoryManagerSheet extends StatefulWidget {
  final AppLocalizations t;
  final MockProductRepository repository;

  const CategoryManagerSheet({
    super.key,
    required this.t,
    required this.repository,
  });

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet> {
  final _levelCtrls = List.generate(3, (_) => TextEditingController());
  List<List<String>> _categories = [];
  bool _loading = true;
  String? _error;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final ctrl in _levelCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repository.fetchCategoryPresets();
      if (!mounted) return;
      setState(() {
        _categories = data;
        _loading = false;
        _editingIndex = null;
        for (final ctrl in _levelCtrls) {
          ctrl.clear();
        }
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
          height: MediaQuery.of(context).size.height * 0.8,
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
                t.categoryManagerTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                t.categoryManagerDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...List.generate(_levelCtrls.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _levelCtrls.length - 1 ? 0 : 12),
                  child: TextField(
                    controller: _levelCtrls[index],
                    decoration: InputDecoration(
                      labelText: t.productCategoryLevel(index + 1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_editingIndex != null)
                    TextButton(
                      onPressed: _resetForm,
                      child: Text(t.categoryManagerCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saveCategory,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _editingIndex == null
                          ? t.categoryManagerAdd
                          : t.categoryManagerUpdate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCategoryList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    final t = widget.t;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return StateMessageView(
        icon: Icons.error_outline,
        title: t.stateErrorMessage,
        message: _error,
        action: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text(t.stateRetry),
        ),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Text(
          t.categoryManagerEmpty,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.separated(
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final path = _categories[index];
        final label = path.join(' > ');
        return Card(
          child: ListTile(
            title: Text(label),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: t.edit,
                  onPressed: () => _startEdit(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: t.categoryManagerDelete,
                  onPressed: () => _confirmDelete(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCategory() async {
    final t = widget.t;
    final path = _levelCtrls
        .map((ctrl) => ctrl.text.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.categoryManagerPrimaryRequired)),
      );
      return;
    }
    final original =
        _editingIndex != null ? _categories[_editingIndex!] : null;
    await widget.repository.saveCategory(
      path,
      originalPath: original,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.categoryManagerSaved)),
    );
    await _load();
  }

  void _startEdit(int index) {
    final path = _categories[index];
    for (var i = 0; i < _levelCtrls.length; i++) {
      _levelCtrls[i].text = i < path.length ? path[i] : '';
    }
    setState(() {
      _editingIndex = index;
    });
  }

  void _resetForm() {
    for (final ctrl in _levelCtrls) {
      ctrl.clear();
    }
    setState(() => _editingIndex = null);
  }

  Future<void> _confirmDelete(int index) async {
    final t = widget.t;
    final path = _categories[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.categoryManagerDelete),
          content: Text(
            t.categoryManagerDeleteConfirm(path.join(' > ')),
          ),
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
    await widget.repository.deleteCategory(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.categoryManagerDeleted)),
    );
    await _load();
  }
}
