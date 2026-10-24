import 'package:flutter/material.dart';

import '../models.dart';
import '../sos_actions.dart';
import '../store.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await Store.contacts();
    if (mounted) setState(() => _items = c);
  }

  Future<void> _add() async {
    if (_items.length >= 5) {
      toast('You can save up to 5 contacts');
      return;
    }
    final c = await showDialog<Contact>(
      context: context,
      builder: (_) => const _AddContactDialog(),
    );
    if (c == null) return;
    final next = [..._items, c];
    await Store.saveContacts(next);
    if (mounted) setState(() => _items = next);
  }

  Future<void> _move(int i, int delta) async {
    final j = i + delta;
    if (j < 0 || j >= _items.length) return;
    final next = [..._items];
    final t = next[i];
    next[i] = next[j];
    next[j] = t;
    await Store.saveContacts(next);
    if (mounted) setState(() => _items = next);
  }

  Future<void> _remove(int i) async {
    final next = [..._items]..removeAt(i);
    await Store.saveContacts(next);
    if (mounted) setState(() => _items = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trusted contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Add up to 5 people you trust. When you use the MeToo widget, the '
            'first one is called; if they do not pick up, the next one is '
            'called. Everyone gets your location by SMS. Stored only on this '
            'phone.',
          ),
          if (_items.length == 1)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Tip: add a second contact so someone is called if the first does not pick up.'),
            ),
          const SizedBox(height: 12),
          for (var i = 0; i < _items.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_items[i].name),
                subtitle: Text(_items[i].phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Call earlier',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: i == 0 ? null : () => _move(i, -1),
                    ),
                    IconButton(
                      tooltip: 'Call later',
                      icon: const Icon(Icons.arrow_downward),
                      onPressed:
                          i == _items.length - 1 ? null : () => _move(i, 1),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(i),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add contact'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '10-digit mobile number',
              ),
              validator: (v) => isValidPhone(normalizePhone(v ?? ''))
                  ? null
                  : 'Enter a valid number',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.of(context).pop(Contact(
                name: _name.text.trim(),
                phone: normalizePhone(_phone.text),
              ));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
