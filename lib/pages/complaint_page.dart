import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../sos_actions.dart';
import '../theme.dart';
import '../store.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  List<Complaint> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await Store.complaints();
    if (mounted) setState(() => _items = c);
  }

  Future<void> _new() async {
    final c = await Navigator.of(context).push<Complaint>(
      MaterialPageRoute(builder: (_) => const _ComplaintForm()),
    );
    if (c == null) return;
    final next = [c, ..._items];
    await Store.saveComplaints(next);
    if (mounted) setState(() => _items = next);
    toast('Saved privately on this phone');
  }

  Future<void> _delete(Complaint c) async {
    final next = _items.where((e) => e.id != c.id).toList();
    await Store.saveComplaints(next);
    if (mounted) setState(() => _items = next);
  }

  void _open(Complaint c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.toShareText()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Share.share(c.toShareText()),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share / export'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _delete(c);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My complaints')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _new,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.infoBg,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Records stay on this phone, encrypted. Nothing is sent '
                'anywhere unless you choose to share it. Writing it down '
                'does not mean you have to report it. Open the Rights tab '
                'to see your options.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty) const Text('No records yet.'),
          for (final c in _items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  c.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Saved ${c.savedOn}'),
                onTap: () => _open(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComplaintForm extends StatefulWidget {
  const _ComplaintForm();

  @override
  State<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<_ComplaintForm> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _when = TextEditingController();
  final _place = TextEditingController();
  final _details = TextEditingController();
  final _accused = TextEditingController();

  @override
  void dispose() {
    for (final c in [_phone, _when, _place, _details, _accused]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.of(context).pop(Complaint(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      when: _when.text.trim(),
      place: _place.text.trim(),
      details: _details.text.trim(),
      accused: _accused.text.trim(),
      contactPhone:
          _phone.text.trim().isEmpty ? '' : normalizePhone(_phone.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New record')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Your phone number (optional)',
              ),
              validator: (v) => (v == null ||
                      v.trim().isEmpty ||
                      isValidPhone(normalizePhone(v)))
                  ? null
                  : 'Enter a valid number',
            ),
            TextFormField(
              controller: _when,
              decoration: const InputDecoration(
                labelText: 'When did it happen? (date and time)',
              ),
            ),
            TextFormField(
              controller: _place,
              decoration: const InputDecoration(labelText: 'Where?'),
            ),
            TextFormField(
              controller: _details,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Write a few words about what happened'
                  : null,
            ),
            TextFormField(
              controller: _accused,
              decoration: const InputDecoration(
                labelText: 'Person(s) involved, witnesses (optional)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Save privately')),
          ],
        ),
      ),
    );
  }
}
