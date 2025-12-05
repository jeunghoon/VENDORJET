import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/customer.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';

class OrderEditResult {
  final OrderStatus status;
  final DateTime plannedShip;
  final String note;
  final List<OrderLine> lines;
  final double? totalOverride;

  const OrderEditResult({
    required this.status,
    required this.plannedShip,
    required this.note,
    required this.lines,
    this.totalOverride,
  });
}

class OrderEditSheet extends StatefulWidget {
  final AppLocalizations t;
  final String localeName;
  final OrderStatus initialStatus;
  final DateTime initialPlannedShip;
  final String initialNote;
  final List<OrderLine> initialLines;
  final bool compactMode;
  final String orderCode;
  final String buyerName;
  final String buyerContact;
  final String buyerNote;
  final DateTime createdAt;

  const OrderEditSheet({
    super.key,
    required this.t,
    required this.localeName,
    required this.initialStatus,
    required this.initialPlannedShip,
    required this.initialNote,
    required this.initialLines,
    required this.createdAt,
    this.compactMode = false,
    this.orderCode = '',
    this.buyerName = '',
    this.buyerContact = '',
    this.buyerNote = '',
  });

  @override
  State<OrderEditSheet> createState() => _OrderEditSheetState();
}

class _OrderEditSheetState extends State<OrderEditSheet> {
  late OrderStatus _status = widget.initialStatus;
  late DateTime _plannedShip = widget.initialPlannedShip;
  late final TextEditingController _dateController =
      TextEditingController(text: DateFormat.yMMMd(widget.localeName).format(widget.initialPlannedShip));
  late final TextEditingController _noteController = TextEditingController(text: widget.initialNote);
  late final TextEditingController _totalController =
      TextEditingController(text: widget.initialLines.fold<double>(0, (s, l) => s + l.lineTotal).toStringAsFixed(2));
  final _formKey = GlobalKey<FormState>();
  final List<_EditableLine> _lines = [];
  final MockProductRepository _productRepo = MockProductRepository();
  final MockCustomerRepository _customerRepo = MockCustomerRepository();
  String _buyerName = '';
  String _buyerNote = '';

  @override
  void initState() {
    super.initState();
    _buyerName = widget.buyerName;
    _buyerNote = widget.buyerNote;
    _lines.addAll(widget.initialLines.map(_EditableLine.fromOrderLine));
    if (_lines.isEmpty && !widget.compactMode) {
      _lines.add(_EditableLine.empty());
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _noteController.dispose();
    _totalController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _computedTotal => _lines.fold<double>(0, (sum, l) => sum + l.total);

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final statuses = OrderStatus.values;
    final number = NumberFormat.decimalPattern(widget.localeName);
    _isKoLocale = widget.localeName.toLowerCase().startsWith('ko');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_label('orderCode'), style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.orderCode.isEmpty ? '-' : widget.orderCode,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(_statusLabel(_status, t)),
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: t.orderEditCancel,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: TextFormField(
                                readOnly: true,
                                controller: TextEditingController(text: _buyerName),
                                decoration: _outlinedInput(
                                  context,
                                  label: _label('storeName'),
                                  suffix: const Icon(Icons.search),
                                ),
                                onTap: _pickCustomer,
                                validator: (v) => (v ?? '').trim().isEmpty ? _label('storeName') : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<OrderStatus>(
                                initialValue: _status,
                                isExpanded: true,
                                items: [
                                  for (final status in statuses)
                                    DropdownMenuItem(
                                      value: status,
                                      child: Text(_statusLabel(status, t)),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) setState(() => _status = value);
                                },
                                decoration: _outlinedInput(context, label: t.orderEditStatusLabel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_label("orderDate")} ${DateFormat.yMMMd(widget.localeName).format(widget.createdAt)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.buyerContact.trim().isEmpty ? _label('unknown') : widget.buyerContact.trim(),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.buyerNote.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.sticky_note_2_outlined, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.buyerNote.trim(),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        _LineEditor(
                          lines: _lines,
                          onChanged: () => setState(() {}),
                          localeName: widget.localeName,
                          onPickProduct: _pickProduct,
                          onAddNext: _startAddFlow,
                        ),
                        const SizedBox(height: 12),
                        if (!widget.compactMode) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_label('totalPrice'), style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                number.format(_computedTotal),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_label('internalNote'), style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: _outlinedInput(context, hint: _label('noteHint')),
                          ),
                        ] else ...[
                          Text(_label('totalPrice'), style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _totalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _outlinedInput(context),
                          ),
                          const SizedBox(height: 12),
                          Text(_label('internalNote'), style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: _outlinedInput(context),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_label('plannedShip'), style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: _outlinedInput(context, suffix: const Icon(Icons.calendar_today_outlined)),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(_label('save')),
                          onPressed: _handleSave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _outlinedInput(BuildContext context, {String? label, String? hint, Widget? suffix, double radius = 12}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedShip,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: Locale(widget.localeName),
    );
    if (picked != null) {
      setState(() {
        _plannedShip = picked;
        _dateController.text = DateFormat.yMMMd(widget.localeName).format(_plannedShip);
      });
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    final lines = widget.compactMode
        ? widget.initialLines
        : _lines.map((l) => l.toOrderLine()).where((l) => l.quantity > 0).toList();
    final totalOverride = widget.compactMode ? double.tryParse(_totalController.text) : null;
    Navigator.of(context).pop(
      OrderEditResult(
        status: _status,
        plannedShip: _plannedShip,
        note: _noteController.text.trim().isEmpty ? _buyerNote : _noteController.text.trim(),
        lines: lines,
        totalOverride: totalOverride,
      ),
    );
  }

  Future<Product?> _pickProduct() async {
    final controller = TextEditingController();
    final listFocus = FocusNode(debugLabel: 'productPickerList');
    final scrollController = ScrollController();
    const itemExtent = 68.0;
    int selectedIndex = 0;
    bool closing = false;
    bool loading = true;
    List<Product> products = [];
    await _loadProducts('', (list) => products = list);
    loading = false;
    if (!mounted) return null;
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            void scrollToSelected(int index) {
              if (!scrollController.hasClients || itemExtent == 0) return;
              final position = scrollController.position;
              final visibleCount = (position.extentInside / itemExtent).floor().clamp(1, 9999);
              final startIndex = (position.pixels / itemExtent).floor();
              final endIndex = startIndex + visibleCount - 1;

              double? target;
              if (index < startIndex) {
                target = index * itemExtent;
              } else if (index > endIndex) {
                target = (index - visibleCount + 1) * itemExtent;
              }

              if (target != null) {
                final clamped = target.clamp(0.0, position.maxScrollExtent);
                scrollController.jumpTo(clamped);
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FocusScope(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Focus(
                        onKeyEvent: (node, event) {
                          if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
                              event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (loading || products.isEmpty) return KeyEventResult.ignored;
                            selectedIndex = 0;
                            if (products.length == 1) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!closing && Navigator.of(context).canPop()) {
                                  closing = true;
                                  Navigator.of(context).pop(products.first);
                                }
                              });
                              return KeyEventResult.handled;
                            }
                            FocusScope.of(context).unfocus();
                            Future.microtask(() {
                              if (!mounted) return;
                              listFocus.requestFocus();
                            });
                            setStateModal(() {});
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: _outlinedInput(context, hint: _label('searchProduct'), suffix: const Icon(Icons.search)),
                          onChanged: (v) async {
                            setStateModal(() {
                              loading = true;
                            });
                            await _loadProducts(v, (list) {
                              setStateModal(() {
                                products = list;
                                selectedIndex = 0;
                                loading = false;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                            });
                          },
                          onSubmitted: (_) {
                            if (products.isEmpty) return;
                            selectedIndex = 0;
                            if (products.length == 1) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!closing && Navigator.of(context).canPop()) {
                                  closing = true;
                                  Navigator.of(context).pop(products.first);
                                }
                              });
                              return;
                            }
                            FocusScope.of(context).unfocus();
                            Future.microtask(() {
                              if (!mounted) return;
                              listFocus.requestFocus();
                            });
                            setStateModal(() {});
                            WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 320,
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : products.isEmpty
                                ? Center(
                                    child: Text(
                                      _label('noResults'),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  )
                            : Focus(
                                focusNode: listFocus,
                                skipTraversal: true,
                                descendantsAreFocusable: false,
                                descendantsAreTraversable: false,
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent || event is KeyRepeatEvent) {
                                    final key = event.logicalKey;
                                    if (key == LogicalKeyboardKey.arrowDown) {
                                      selectedIndex = (selectedIndex + 1).clamp(0, products.length - 1);
                                      setStateModal(() {});
                                      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                                      return KeyEventResult.handled;
                                    } else if (key == LogicalKeyboardKey.arrowUp) {
                                      selectedIndex = (selectedIndex - 1).clamp(0, products.length - 1);
                                      setStateModal(() {});
                                      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                                      return KeyEventResult.handled;
                                    } else if (key == LogicalKeyboardKey.enter) {
                                      final chosen = products[selectedIndex];
                                      final nav = Navigator.of(context);
                                      Future.microtask(() {
                                        if (!closing && nav.mounted && nav.canPop()) {
                                          closing = true;
                                          nav.pop(chosen);
                                        }
                                      });
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemExtent: itemExtent,
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final p = products[index];
                                    final selected = index == selectedIndex;
                                    return ListTile(
                                      selected: selected,
                                      selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      title: Text(p.name),
                                      subtitle: Text(p.sku),
                                      trailing: Text(p.price.toStringAsFixed(2)),
                                      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (!closing && Navigator.of(context).canPop()) {
                                          closing = true;
                                          Navigator.of(context).pop(p);
                                        }
                                      }),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadProducts(String query, void Function(List<Product>) onLoaded) async {
    try {
      final items = await _productRepo.fetch(query: query);
      onLoaded(items);
    } catch (_) {
      onLoaded([]);
    }
  }

  Future<void> _pickCustomer() async {
    final controller = TextEditingController();
    List<Customer> customers = [];
    bool loading = true;
    final listFocus = FocusNode(debugLabel: 'customerPickerList');
    final scrollController = ScrollController();
    const itemExtent = 64.0;
    int selectedIndex = 0;

    void scrollToSelected(int index) {
      if (!scrollController.hasClients || itemExtent == 0) return;
      final position = scrollController.position;
      final visibleCount = (position.extentInside / itemExtent).floor().clamp(1, 9999);
      final startIndex = (position.pixels / itemExtent).floor();
      final endIndex = startIndex + visibleCount - 1;
      double? target;
      if (index < startIndex) {
        target = index * itemExtent;
      } else if (index > endIndex) {
        target = (index - visibleCount + 1) * itemExtent;
      }
      if (target != null) {
        final clamped = target.clamp(0.0, position.maxScrollExtent);
        scrollController.jumpTo(clamped);
      }
    }

    await _loadCustomers('', (list) {
      customers = list;
      loading = false;
    });
    if (!mounted) return;

    final picked = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            bool localLoading = loading;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(
                      onKeyEvent: (node, event) {
                        if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
                            event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          if (localLoading || customers.isEmpty) return KeyEventResult.ignored;
                          selectedIndex = 0;
                          if (customers.length == 1) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop(customers.first);
                              }
                            });
                            return KeyEventResult.handled;
                          }
                          FocusScope.of(context).unfocus();
                          Future.microtask(() {
                            if (!mounted) return;
                            listFocus.requestFocus();
                            scrollToSelected(selectedIndex);
                          });
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: _outlinedInput(context, hint: _label('storeName'), suffix: const Icon(Icons.search)),
                        onChanged: (v) async {
                          setStateModal(() => localLoading = true);
                          await _loadCustomers(v, (list) {
                            customers = list;
                            selectedIndex = 0;
                            setStateModal(() => localLoading = false);
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                        },
                        onSubmitted: (_) {
                          if (customers.isEmpty) return;
                          selectedIndex = 0;
                          if (customers.length == 1) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop(customers.first);
                              }
                            });
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          Future.microtask(() {
                            if (!mounted) return;
                            listFocus.requestFocus();
                            scrollToSelected(selectedIndex);
                          });
                          setStateModal(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: localLoading
                          ? const Center(child: CircularProgressIndicator())
                          : customers.isEmpty
                              ? Center(child: Text(_label('noResults')))
                              : Focus(
                                  focusNode: listFocus,
                                  skipTraversal: true,
                                  descendantsAreFocusable: false,
                                  descendantsAreTraversable: false,
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent || event is KeyRepeatEvent) {
                                      final key = event.logicalKey;
                                      if (key == LogicalKeyboardKey.arrowDown) {
                                        selectedIndex = (selectedIndex + 1).clamp(0, customers.length - 1);
                                        setStateModal(() {});
                                        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                                        return KeyEventResult.handled;
                                      } else if (key == LogicalKeyboardKey.arrowUp) {
                                        selectedIndex = (selectedIndex - 1).clamp(0, customers.length - 1);
                                        setStateModal(() {});
                                        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToSelected(selectedIndex));
                                        return KeyEventResult.handled;
                                      } else if (key == LogicalKeyboardKey.enter) {
                                        final chosen = customers[selectedIndex];
                                        final nav = Navigator.of(context);
                                        Future.microtask(() {
                                          if (nav.mounted && nav.canPop()) {
                                            nav.pop(chosen);
                                          }
                                        });
                                        return KeyEventResult.handled;
                                      }
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemExtent: itemExtent,
                                    itemCount: customers.length,
                                    itemBuilder: (context, index) {
                                      final c = customers[index];
                                      final selected = index == selectedIndex;
                                      return ListTile(
                                        selected: selected,
                                        selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        title: Text(c.name),
                                        subtitle: Text(c.contactName),
                                        onTap: () => Navigator.of(context).pop(c),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _buyerName = picked.name;
      });
    }
  }

  Future<void> _loadCustomers(String query, void Function(List<Customer>) onLoaded) async {
    try {
      final items = await _customerRepo.fetch(query: query);
      onLoaded(items);
    } catch (_) {
      onLoaded([]);
    }
  }

  Future<void> _startAddFlow() async {
    final newLine = _EditableLine.empty();
    setState(() {
      _lines.insert(0, newLine);
    });

    final picked = await _pickProduct();
    if (!mounted) return;
    if (picked == null) {
      setState(() {
        _lines.remove(newLine);
      });
      return;
    }

    setState(() {
      newLine.applyProduct(picked);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        newLine.qtyFocus.requestFocus();
      }
    });
  }
}

class _LineEditor extends StatefulWidget {
  final List<_EditableLine> lines;
  final VoidCallback onChanged;
  final String localeName;
  final Future<Product?> Function() onPickProduct;
  final Future<void> Function() onAddNext;

  const _LineEditor({
    required this.lines,
    required this.onChanged,
    required this.localeName,
    required this.onPickProduct,
    required this.onAddNext,
  });

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_label('lineItems'), style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: _label('addItem'),
              onPressed: () async {
                await widget.onAddNext();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.lines.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final line = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: line.nameCtrl,
                            readOnly: true,
                            decoration: _outlinedInput(
                              context,
                              label: _label('productName'),
                              radius: 8,
                            ),
                            onTap: () async {
                              final picked = await widget.onPickProduct();
                              if (picked != null) {
                                setState(() {
                                  line.applyProduct(picked);
                                });
                                widget.onChanged();
                                line.qtyFocus.requestFocus();
                              }
                            },
                            validator: (v) => (v ?? '').trim().isEmpty ? _label('productNameReq') : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: _label('changeProduct'),
                          onPressed: () async {
                            final picked = await widget.onPickProduct();
                            if (picked != null) {
                              setState(() {
                                line.applyProduct(picked);
                              });
                              widget.onChanged();
                              line.qtyFocus.requestFocus();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              widget.lines.removeAt(index);
                            });
                            widget.onChanged();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: line.qtyCtrl,
                            focusNode: line.qtyFocus,
                            keyboardType: TextInputType.number,
                            decoration: _outlinedInput(
                              context,
                              label: _label('quantity'),
                              radius: 8,
                            ),
                            onChanged: (v) {
                              line.updateQuantity(v);
                              widget.onChanged();
                              setState(() {});
                            },
                            onFieldSubmitted: (_) => widget.onAddNext(),
                            validator: (v) {
                              final parsed = int.tryParse(v ?? '');
                              if (parsed == null || parsed <= 0) return _label('quantityReq');
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: line.unitCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _outlinedInput(
                              context,
                              label: _label('unitPrice'),
                              radius: 8,
                            ),
                            onChanged: (v) {
                              line.updateUnitPrice(v);
                              widget.onChanged();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: line.totalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _outlinedInput(
                              context,
                              label: _label('totalPrice'),
                              radius: 8,
                            ),
                            onChanged: (v) {
                              line.updateTotal(v);
                              widget.onChanged();
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          NumberFormat.decimalPattern(widget.localeName).format(line.total),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  InputDecoration _outlinedInput(BuildContext context, {required String label, double radius = 12}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    );
    return InputDecoration(
      labelText: label,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _EditableLine {
  final String productId;
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController totalCtrl;
  final FocusNode qtyFocus;

  _EditableLine({
    required this.productId,
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
    required this.totalCtrl,
    required this.qtyFocus,
  });

  factory _EditableLine.fromOrderLine(OrderLine line) {
    return _EditableLine(
      productId: line.productId,
      nameCtrl: TextEditingController(text: line.productName),
      qtyCtrl: TextEditingController(text: line.quantity.toString()),
      unitCtrl: TextEditingController(text: line.unitPrice.toStringAsFixed(2)),
      totalCtrl: TextEditingController(text: line.lineTotal.toStringAsFixed(2)),
      qtyFocus: FocusNode(),
    );
  }

  factory _EditableLine.empty() {
    return _EditableLine(
      productId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      nameCtrl: TextEditingController(),
      qtyCtrl: TextEditingController(text: '1'),
      unitCtrl: TextEditingController(text: '0'),
      totalCtrl: TextEditingController(text: '0'),
      qtyFocus: FocusNode(),
    );
  }

  int get quantity => int.tryParse(qtyCtrl.text) ?? 0;
  double get unitPrice => double.tryParse(unitCtrl.text) ?? 0;
  double get total => double.tryParse(totalCtrl.text) ?? (quantity * unitPrice);

  void updateQuantity(String v) {
    final qty = int.tryParse(v) ?? 0;
    if (qty > 0) {
      final newTotal = qty * unitPrice;
      totalCtrl.text = newTotal.toStringAsFixed(2);
    }
  }

  void updateUnitPrice(String v) {
    final unit = double.tryParse(v) ?? 0;
    final qty = quantity == 0 ? 1 : quantity;
    totalCtrl.text = (qty * unit).toStringAsFixed(2);
  }

  void updateTotal(String v) {
    final totalVal = double.tryParse(v) ?? 0;
    final qty = quantity == 0 ? 1 : quantity;
    unitCtrl.text = (totalVal / qty).toStringAsFixed(2);
  }

  void applyProduct(Product product) {
    nameCtrl.text = product.name;
    unitCtrl.text = product.price.toStringAsFixed(2);
    updateUnitPrice(unitCtrl.text);
  }

  OrderLine toOrderLine() {
    return OrderLine(
      productId: productId,
      productName: nameCtrl.text.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    totalCtrl.dispose();
    qtyFocus.dispose();
  }
}

class InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const InfoPill({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String _label(String key) {
  final isKo = _isKoLocale;
  switch (key) {
    case 'orderCode':
      return isKo ? '주문 코드' : 'Order Code';
    case 'buyerInfo':
      return isKo ? '구매자 정보' : 'Buyer Info';
    case 'storeName':
      return isKo ? '상호명' : 'Store Name';
    case 'buyerContact':
      return isKo ? '구매자 연락처' : 'Buyer Contact';
    case 'buyerNote':
      return isKo ? '구매자 메모' : 'Buyer Note';
    case 'orderDate':
      return isKo ? '주문일' : 'Order Date';
    case 'plannedShip':
      return isKo ? '출고 예정일' : 'Planned Shipment';
    case 'unknown':
      return isKo ? '미정' : 'N/A';
    case 'lineItems':
      return isKo ? '품목 내역' : 'Line Items';
    case 'searchProduct':
      return isKo ? '상품 검색' : 'Search product';
    case 'productName':
      return isKo ? '상품명' : 'Product Name';
    case 'productNameReq':
      return isKo ? '상품명을 입력하세요' : 'Enter product name';
    case 'quantity':
      return isKo ? '수량' : 'Quantity';
    case 'quantityReq':
      return isKo ? '수량을 입력하세요' : 'Enter quantity';
    case 'unitPrice':
      return isKo ? '개별 금액' : 'Unit Price';
    case 'totalPrice':
      return isKo ? '전체 금액' : 'Line Total';
    case 'internalNote':
      return isKo ? '내부 메모' : 'Internal Note';
    case 'noteHint':
      return isKo ? '변경 사항이나 주의 사항을 적어주세요' : 'Add notes or remarks';
    case 'addItem':
      return isKo ? '품목 추가' : 'Add item';
    case 'changeProduct':
      return isKo ? '상품 변경' : 'Change product';
    case 'save':
      return isKo ? '저장' : 'Save';
    case 'noResults':
      return isKo ? '검색 결과가 없습니다' : 'No products found';
    default:
      return key;
  }
}

bool _isKoLocale = true;

String _statusLabel(OrderStatus status, AppLocalizations t) {
  switch (status) {
    case OrderStatus.pending:
      return t.ordersStatusPending;
    case OrderStatus.confirmed:
      return t.ordersStatusConfirmed;
    case OrderStatus.shipped:
      return t.ordersStatusShipped;
    case OrderStatus.completed:
      return t.ordersStatusCompleted;
    case OrderStatus.canceled:
      return t.ordersStatusCanceled;
    case OrderStatus.returned:
      return t.ordersStatusReturned;
  }
}
