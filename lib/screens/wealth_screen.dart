import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/wealth_account.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  bool _isSyncing = false;

  Future<void> _refreshSyncRates() async {
    setState(() => _isSyncing = true);
    final rates = await ApiService.instance.fetchExchangeRates(base: 'USD');
    StorageService.instance.updateExchangeRates(rates);
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Live FX rates synced (${rates.length} currencies)!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddAccountDialog([WealthAccount? account]) {
    final isEdit = account != null;
    final instCtrl = TextEditingController(text: account?.institution ?? '');
    final nameCtrl = TextEditingController(text: account?.accountName ?? '');
    final numberCtrl = TextEditingController(text: account?.maskedNumber ?? '');
    final balanceCtrl = TextEditingController(
        text: account != null ? account.balance.toStringAsFixed(2) : '');
    final notesCtrl = TextEditingController(text: account?.notes ?? '');
    final memberCtrl = TextEditingController(text: account?.assignedMember ?? 'Entire Family');

    var selectedType = account?.accountType ?? AccountType.checking;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Account' : 'Add Financial Account',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(),
                  ),
                  items: AccountType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bank / Institution (e.g. Chase, Fidelity, Vanguard)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Nickname (e.g. Joint Checking, Emergency Fund)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: balanceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: selectedType.isLiability ? 'Current Debt / Balance' : 'Current Balance',
                          prefixText: '\$ ',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: numberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Last 4 Digits',
                          hintText: '•••• 1234',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Member (e.g. Dad & Mom, Emma)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Interest rate, APY, account purpose)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'Save Changes' : 'Add to Family Wealth'),
                    onPressed: () async {
                      final balance = double.tryParse(balanceCtrl.text) ?? 0.0;
                      if (instCtrl.text.trim().isEmpty) return;

                      const uuid = Uuid();
                      final newAcc = WealthAccount(
                        id: account?.id ?? uuid.v4(),
                        institution: instCtrl.text.trim(),
                        accountType: selectedType,
                        accountName: nameCtrl.text.trim().isEmpty ? selectedType.displayName : nameCtrl.text.trim(),
                        maskedNumber: numberCtrl.text.trim(),
                        balance: balance,
                        assignedMember: memberCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );

                      if (isEdit) {
                        await StorageService.instance.updateWealthAccount(newAcc);
                      } else {
                        await StorageService.instance.addWealthAccount(newAcc);
                      }

                      if (mounted) {
                        Navigator.of(ctx).pop();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = StorageService.instance;
    final totalAssets = storage.totalAssets;
    final totalLiabilities = storage.totalLiabilities;
    final netWorth = storage.netWorth;
    final accounts = storage.wealthAccounts;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Family Wealth & Net Worth'),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync Financial Rates',
            onPressed: _isSyncing ? null : _refreshSyncRates,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // NET WORTH HERO CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.tertiaryContainer.withAlpha(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL FAMILY NET WORTH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('All Portfolios', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(netWorth),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Total Assets', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(totalAssets),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: theme.colorScheme.outlineVariant),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text('Total Debts', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(totalLiabilities),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WEALTH BREAKDOWN OVERVIEW
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asset Allocation Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildAssetProgressBar(
                    realEstate: storage.properties.fold(0.0, (s, p) => s + p.estimatedMarketValue),
                    liquid: storage.wealthAccounts.where((a) => a.accountType == AccountType.checking || a.accountType == AccountType.savings).fold(0.0, (s, a) => s + a.balance),
                    investments: storage.wealthAccounts.where((a) => a.accountType == AccountType.investment || a.accountType == AccountType.retirement).fold(0.0, (s, a) => s + a.balance),
                    vehicles: storage.vehicles.fold(0.0, (s, v) => s + v.estimatedValue),
                    total: totalAssets > 0 ? totalAssets : 1.0,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ACCOUNTS LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Accounts (${accounts.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Bank / Fund'),
                onPressed: () => _showAddAccountDialog(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (accounts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No accounts added yet.'),
                      TextButton(
                        onPressed: () => _showAddAccountDialog(),
                        child: const Text('Add First Account'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...accounts.map((acc) {
              final isDebt = acc.isLiability;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDebt ? Colors.red.withAlpha(40) : Colors.green.withAlpha(40),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDebt ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDebt ? Icons.credit_card_rounded : Icons.account_balance_rounded,
                      color: isDebt ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    acc.institution,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${acc.accountName} ${acc.maskedNumber}'),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              acc.assignedMember,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (acc.notes.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                acc.notes,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isDebt ? "-" : ""}${currencyFormat.format(acc.balance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDebt ? Colors.red : Colors.green,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            _showAddAccountDialog(acc);
                          } else if (action == 'delete') {
                            await storage.deleteWealthAccount(acc.id);
                            setState(() {});
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAssetProgressBar({
    required double realEstate,
    required double liquid,
    required double investments,
    required double vehicles,
    required double total,
  }) {
    final rePct = (realEstate / total).clamp(0.0, 1.0);
    final invPct = (investments / total).clamp(0.0, 1.0);
    final liqPct = (liquid / total).clamp(0.0, 1.0);
    final vehPct = (vehicles / total).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (rePct > 0) Expanded(flex: (rePct * 100).round(), child: Container(color: Colors.deepPurple)),
                if (invPct > 0) Expanded(flex: (invPct * 100).round(), child: Container(color: Colors.blue)),
                if (liqPct > 0) Expanded(flex: (liqPct * 100).round(), child: Container(color: Colors.green)),
                if (vehPct > 0) Expanded(flex: (vehPct * 100).round(), child: Container(color: Colors.orange)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem('Real Estate (${(rePct * 100).toStringAsFixed(0)}%)', Colors.deepPurple),
            _legendItem('Investments (${(invPct * 100).toStringAsFixed(0)}%)', Colors.blue),
            _legendItem('Cash / Bank (${(liqPct * 100).toStringAsFixed(0)}%)', Colors.green),
            _legendItem('Vehicles (${(vehPct * 100).toStringAsFixed(0)}%)', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
