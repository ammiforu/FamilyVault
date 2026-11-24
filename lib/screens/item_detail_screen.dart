import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final VaultItem? item;
  final VaultCategory? initialCategory;

  const ItemDetailScreen({super.key, this.item, this.initialCategory});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _assignedMemberController;
  late TextEditingController _expiryDateController;
  late TextEditingController _notesController;

  late VaultCategory _selectedCategory;
  bool _obscurePassword = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _selectedCategory = item?.category ?? widget.initialCategory ?? VaultCategory.login;
    _titleController = TextEditingController(text: item?.title ?? '');
    _usernameController = TextEditingController(text: item?.username ?? '');
    _passwordController = TextEditingController(text: item?.password ?? '');
    _urlController = TextEditingController(text: item?.url ?? '');
    _assignedMemberController = TextEditingController(text: item?.assignedMember ?? 'Entire Family');
    _expiryDateController = TextEditingController(text: item?.expiryDate ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _isFavorite = item?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _assignedMemberController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String fieldName) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _generateQuickPassword() {
    const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%^&*';
    final random = Random.secure();
    final pwd = List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = pwd;
      _obscurePassword = false;
    });
    _copyToClipboard(pwd, 'Generated password');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isNew = widget.item == null;
    final item = VaultItem(
      id: widget.item?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _selectedCategory,
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      url: _urlController.text.trim(),
      assignedMember: _assignedMemberController.text.trim().isEmpty
          ? 'Entire Family'
          : _assignedMemberController.text.trim(),
      expiryDate: _expiryDateController.text.trim(),
      notes: _notesController.text.trim(),
      isFavorite: _isFavorite,
      createdAt: widget.item?.createdAt,
    );

    if (isNew) {
      await StorageService.instance.addItem(item);
    } else {
      await StorageService.instance.updateItem(item);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    if (widget.item == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vault Entry?'),
        content: Text('Are you sure you want to delete "${widget.item!.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.deleteItem(widget.item!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.item == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Vault Item' : 'Edit Item'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
            color: _isFavorite ? Colors.amber : null,
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category Dropdown
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.folder_outlined),
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VaultCategory>(
                  value: _selectedCategory,
                  isDense: true,
                  items: VaultCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName),
                    );
                  }).toList(),
                  onChanged: (newCat) {
                    if (newCat != null) setState(() => _selectedCategory = newCat);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Service Name *',
                hintText: 'e.g. Netflix, Chase Bank, Home Wi-Fi, Passport',
                prefixIcon: Icon(Icons.title_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Assigned Member
            TextFormField(
              controller: _assignedMemberController,
              decoration: const InputDecoration(
                labelText: 'Assigned Family Member',
                hintText: 'e.g. Entire Family, Dad, Mom, Emma',
                prefixIcon: Icon(Icons.people_alt_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Username / Email
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: _getUsernameLabel(),
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () => _copyToClipboard(_usernameController.text, 'Username / ID'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password / Secret
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: _getPasswordLabel(),
                prefixIcon: const Icon(Icons.key_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome_rounded),
                      tooltip: 'Generate strong password',
                      onPressed: _generateQuickPassword,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: () => _copyToClipboard(_passwordController.text, 'Password / Secret'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // URL or Location
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _getUrlLabel(),
                prefixIcon: const Icon(Icons.link_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () => _copyToClipboard(_urlController.text, 'URL / Detail'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expiry / Renewal Date
            TextFormField(
              controller: _expiryDateController,
              decoration: const InputDecoration(
                labelText: 'Expiry / Renewal Date (Optional)',
                hintText: 'MM/YYYY or YYYY-MM-DD',
                prefixIcon: Icon(Icons.event_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes & Extra Details',
                hintText: 'Security questions, account numbers, PIN codes, blood type, etc.',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(isNew ? 'Create Item' : 'Save Changes', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getUsernameLabel() {
    switch (_selectedCategory) {
      case VaultCategory.login:
        return 'Username or Email';
      case VaultCategory.card:
        return 'Cardholder Name / Card #';
      case VaultCategory.document:
        return 'Document ID / Number';
      case VaultCategory.legal:
        return 'Trustee / Executor / Authority';
      case VaultCategory.emergency:
        return 'Primary Contact / Phone';
      case VaultCategory.wifi:
        return 'Network Name (SSID)';
      case VaultCategory.note:
        return 'Subheading / Reference';
    }
  }

  String _getPasswordLabel() {
    switch (_selectedCategory) {
      case VaultCategory.login:
        return 'Password';
      case VaultCategory.card:
        return 'CVV / Card PIN';
      case VaultCategory.document:
        return 'Issuing Authority / Group #';
      case VaultCategory.legal:
        return 'Registration / Document Code';
      case VaultCategory.emergency:
        return 'Secondary Contact / Cell';
      case VaultCategory.wifi:
        return 'Wi-Fi Password';
      case VaultCategory.note:
        return 'Secret Code / Key';
    }
  }

  String _getUrlLabel() {
    switch (_selectedCategory) {
      case VaultCategory.login:
        return 'Website / Login URL';
      case VaultCategory.card:
        return 'Bank Online Portal';
      case VaultCategory.document:
        return 'Portal or File Link';
      case VaultCategory.legal:
        return 'Law Firm / Safe Location';
      case VaultCategory.emergency:
        return 'Address / Hospital Location';
      case VaultCategory.wifi:
        return 'Router IP (e.g. 192.168.1.1)';
      case VaultCategory.note:
        return 'Location or Tag';
    }
  }
}
