import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';
import 'item_detail_screen.dart';

class SpreadsheetScreen extends StatefulWidget {
  const SpreadsheetScreen({super.key});

  @override
  State<SpreadsheetScreen> createState() => _SpreadsheetScreenState();
}

class _SpreadsheetScreenState extends State<SpreadsheetScreen> {
  String _searchQuery = '';
  VaultCategory? _categoryFilter;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final Set<String> _revealedPasswords = {};

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
      if (_revealedPasswords.contains(id)) {
        _revealedPasswords.remove(id);
      } else {
        _revealedPasswords.add(id);
      }
    });
  }

  void _exportCsvDialog() {
    final csv = StorageService.instance.exportToCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_view_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Spreadsheet (CSV)'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This CSV format is 100% compatible with Google Sheets and Excel:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy CSV'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV copied! You can paste it directly into Google Sheets.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _importCsvDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Import from Google Sheets'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste CSV rows exported or copied from Google Sheets / Excel below:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Paste CSV text here...\ne.g. Netflix,Accounts & Logins,Family,user@mail.com,pass123,...',
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(fontSize: 12),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final content = textController.text.trim();
              if (content.isEmpty) return;
              final count = await StorageService.instance.importFromCsv(content);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully imported $count rows into vault!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Import Rows'),
          ),
        ],
      ),
    );
  }

  List<VaultItem> _getFilteredItems() {
    var list = StorageService.instance.items.where((it) {
      final matchesCat = _categoryFilter == null || it.category == _categoryFilter;
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          it.title.toLowerCase().contains(q) ||
          it.username.toLowerCase().contains(q) ||
          it.assignedMember.toLowerCase().contains(q) ||
          it.notes.toLowerCase().contains(q) ||
          it.url.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 1:
          cmp = a.category.displayName.compareTo(b.category.displayName);
          break;
        case 2:
          cmp = a.assignedMember.toLowerCase().compareTo(b.assignedMember.toLowerCase());
          break;
        case 3:
          cmp = a.username.toLowerCase().compareTo(b.username.toLowerCase());
          break;
        case 4:
          cmp = a.expiryDate.compareTo(b.expiryDate);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _getFilteredItems();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grid_on_rounded, size: 22),
            SizedBox(width: 8),
            Text('Spreadsheet View'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import CSV from Google Sheets',
            onPressed: _importCsvDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exportCsvDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search spreadsheet rows...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(width: 8),
                PopupMenuButton<VaultCategory?>(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: _categoryFilter != null ? theme.colorScheme.primary : null,
                  ),
                  tooltip: 'Filter by category',
                  onSelected: (cat) => setState(() => _categoryFilter = cat),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...VaultCategory.values.map(
                      (c) => PopupMenuItem(
                        value: c,
                        child: Text(c.displayName),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Count Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} records in sheet',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Scroll horizontally for all columns ➔',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Spreadsheet Table View
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_rows_outlined, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text('No spreadsheet records found'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Row'),
                          onPressed: () async {
                            final res = await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ItemDetailScreen()),
                            );
                            if (res == true) setState(() {});
                          },
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columnSpacing: 20,
                        horizontalMargin: 16,
                        headingRowColor: WidgetStateProperty.all(
                          theme.colorScheme.primaryContainer.withAlpha(70),
                        ),
                        columns: [
                          DataColumn(
                            label: const Text('Title / Service', style: TextStyle(fontWeight: FontWeight.bold)),
                            onSort: (col, asc) => setState(() {
                              _sortColumnIndex = col;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                            onSort: (col, asc) => setState(() {
                              _sortColumnIndex = col;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Member', style: TextStyle(fontWeight: FontWeight.bold)),
                            onSort: (col, asc) => setState(() {
                              _sortColumnIndex = col;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: const Text('Username / ID', style: TextStyle(fontWeight: FontWeight.bold)),
                            onSort: (col, asc) => setState(() {
                              _sortColumnIndex = col;
                              _sortAscending = asc;
                            }),
                          ),
                          const DataColumn(
                            label: Text('Password / Secret', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const DataColumn(
                            label: Text('URL / Location', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: const Text('Expiry', style: TextStyle(fontWeight: FontWeight.bold)),
                            onSort: (col, asc) => setState(() {
                              _sortColumnIndex = col;
                              _sortAscending = asc;
                            }),
                          ),
                          const DataColumn(
                            label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const DataColumn(
                            label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        rows: items.map((item) {
                          final isRevealed = _revealedPasswords.contains(item.id);
                          return DataRow(
                            cells: [
                              // Title
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.isFavorite)
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                    if (item.isFavorite) const SizedBox(width: 4),
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                onTap: () => _editItem(item),
                              ),
                              // Category
                              DataCell(
                                Chip(
                                  label: Text(item.category.shortCode, style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              // Member
                              DataCell(Text(item.assignedMember)),
                              // Username
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.username),
                                    if (item.username.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 14),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _copy(item.username, 'Username'),
                                      ),
                                  ],
                                ),
                              ),
                              // Password
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isRevealed ? item.password : (item.password.isNotEmpty ? '••••••••' : '-'),
                                      style: TextStyle(
                                        fontFamily: isRevealed ? null : 'monospace',
                                        letterSpacing: isRevealed ? null : 2,
                                      ),
                                    ),
                                    if (item.password.isNotEmpty) ...[
                                      IconButton(
                                        icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 14),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _toggleReveal(item.id),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 14),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _copy(item.password, 'Password'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // URL
                              DataCell(Text(item.url)),
                              // Expiry
                              DataCell(Text(item.expiryDate.isEmpty ? '-' : item.expiryDate)),
                              // Notes
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    item.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // Action
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _editItem(item),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Row to Sheet',
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ItemDetailScreen()),
          );
          if (res == true) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editItem(VaultItem item) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    if (res == true) setState(() {});
  }
}
