import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';
import 'item_detail_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  VaultCategory? _selectedCategory;
  String _searchQuery = '';
  bool _onlyFavorites = false;
  final Set<String> _revealedIds = {};

  void _copy(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleReveal(String id) {
    setState(() {
      if (_revealedIds.contains(id)) {
        _revealedIds.remove(id);
      } else {
        _revealedIds.add(id);
      }
    });
  }

  IconData _getCategoryIcon(VaultCategory cat) {
    switch (cat) {
      case VaultCategory.login:
        return Icons.lock_outline_rounded;
      case VaultCategory.card:
        return Icons.credit_card_rounded;
      case VaultCategory.document:
        return Icons.badge_outlined;
      case VaultCategory.legal:
        return Icons.gavel_rounded;
      case VaultCategory.emergency:
        return Icons.medical_services_outlined;
      case VaultCategory.wifi:
        return Icons.wifi_rounded;
      case VaultCategory.note:
        return Icons.note_alt_outlined;
    }
  }

  Color _getCategoryColor(VaultCategory cat) {
    switch (cat) {
      case VaultCategory.login:
        return Colors.blue;
      case VaultCategory.card:
        return Colors.teal;
      case VaultCategory.document:
        return Colors.deepPurple;
      case VaultCategory.legal:
        return Colors.brown;
      case VaultCategory.emergency:
        return Colors.red;
      case VaultCategory.wifi:
        return Colors.amber.shade800;
      case VaultCategory.note:
        return Colors.indigo;
    }
  }

  List<VaultItem> _getFilteredItems() {
    return StorageService.instance.items.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_onlyFavorites && !item.isFavorite) {
        return false;
      }
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final inTitle = item.title.toLowerCase().contains(q);
        final inUser = item.username.toLowerCase().contains(q);
        final inMember = item.assignedMember.toLowerCase().contains(q);
        final inNotes = item.notes.toLowerCase().contains(q);
        if (!inTitle && !inUser && !inMember && !inNotes) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _getFilteredItems();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Family Vault', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_onlyFavorites ? Icons.star_rounded : Icons.star_outline_rounded),
            color: _onlyFavorites ? Colors.amber : null,
            tooltip: 'Filter favorites',
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logins, cards, IDs, Wi-Fi...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Categories Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Items'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...VaultCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(_getCategoryIcon(cat), size: 16),
                      label: Text(cat.displayName),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = isSelected ? null : cat),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Vault Items List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'No vault items found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the + button to add a password, card, or document',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isRevealed = _revealedIds.contains(item.id);
                      final catColor = _getCategoryColor(item.category);

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withAlpha(80),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final res = await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                            );
                            if (res == true) setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Icon, Title, Member Badge, Star
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: catColor.withAlpha(30),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_getCategoryIcon(item.category), color: catColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.assignedMember,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.colorScheme.onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                              if (item.expiryDate.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Exp: ${item.expiryDate}',
                                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: item.isFavorite ? Colors.amber : null,
                                      ),
                                      onPressed: () async {
                                        await StorageService.instance.toggleFavorite(item.id);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),

                                const Divider(height: 20),

                                // Fields
                                if (item.username.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.username,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Copy username',
                                        onPressed: () => _copy(item.username, 'Username'),
                                      ),
                                    ],
                                  ),

                                if (item.password.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.key_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isRevealed ? item.password : '••••••••••••',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: isRevealed ? null : 'monospace',
                                            letterSpacing: isRevealed ? null : 2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: isRevealed ? 'Hide' : 'Reveal',
                                        onPressed: () => _toggleReveal(item.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Copy password',
                                        onPressed: () => _copy(item.password, 'Password'),
                                      ),
                                    ],
                                  ),

                                if (item.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.notes,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(initialCategory: _selectedCategory),
            ),
          );
          if (res == true) setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
    );
  }
}
