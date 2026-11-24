import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/wealth_account.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  static const List<String> _popularBanks = [
    'Chase',
    'Bank of America',
    'Wells Fargo',
    'Fidelity',
    'Vanguard',
    'Capital One',
    'Citi',
    'Charles Schwab',
    'Amex',
    'HDFC Bank',
    'ICICI Bank',
    'SBI',
  ];

  static const List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD'];

  static Future<bool> showAddAccountSheet(BuildContext context, [WealthAccount? account]) async {
    final isEdit = account != null;
    final instCtrl = TextEditingController(text: account?.institution ?? '');
    final nameCtrl = TextEditingController(text: account?.accountName ?? '');
    final numberCtrl = TextEditingController(text: account?.maskedNumber ?? '');
    final balanceCtrl = TextEditingController(
      text: account != null ? account.balance.toStringAsFixed(2) : '',
    );
    final notesCtrl = TextEditingController(text: account?.notes ?? '');
    final memberCtrl = TextEditingController(text: account?.assignedMember ?? 'Entire Family');

    var selectedType = account?.accountType ?? AccountType.checking;
    var selectedCurrency = account?.currency ?? 'USD';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          final members = StorageService.instance.members.map((m) => m.name).toList();
          final memberOptions = ['Entire Family', ...members.where((m) => m != 'Entire Family')];

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 14,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Bank / Account' : 'Add Bank or Account',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 1-TAP POPULAR BANK PICKER
                  const Text('1. Tap your Bank / Institution (or type below)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _popularBanks.map((bank) {
                      final isSelected = instCtrl.text.trim().toLowerCase() == bank.toLowerCase();
                      return ChoiceChip(
                        label: Text(bank, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) => setModalState(() => instCtrl.text = bank),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: instCtrl,
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Bank / Institution Name *',
                      hintText: 'e.g. Chase, Fidelity, Local Credit Union',
                      prefixIcon: Icon(Icons.account_balance_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1-TAP ACCOUNT TYPE CHIPS
                  const Text('2. Account Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: AccountType.values.map((t) {
                      final isSelected = selectedType == t;
                      return ChoiceChip(
                        label: Text(t.displayName, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: t.isLiability ? Colors.red.withAlpha(60) : Colors.green.withAlpha(60),
                        onSelected: (_) => setModalState(() => selectedType = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // BALANCE + CURRENCY
                  const Text('3. Current Balance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: balanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: selectedType.isLiability ? 'Amount Owed' : 'Current Balance',
                            hintText: '0.00',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _currencies.contains(selectedCurrency) ? selectedCurrency : 'USD',
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            border: OutlineInputBorder(),
                          ),
                          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCurrency = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // OPTIONAL EXTRA DETAILS (COLLAPSED BY DEFAULT FOR CLEAN UX)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Optional Details (Nickname, Last 4, Member)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    children: [
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Account Nickname (auto-named if blank)',
                          hintText: '${instCtrl.text.isEmpty ? "Bank" : instCtrl.text} ${selectedType.displayName}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: numberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Last 4 Digits (Optional)',
                          hintText: '•••• 1234',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          children: memberOptions.map((m) {
                            return ChoiceChip(
                              label: Text(m, style: const TextStyle(fontSize: 11)),
                              selected: memberCtrl.text == m,
                              onSelected: (_) => setModalState(() => memberCtrl.text = m),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (APY %, routing note, purpose)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(isEdit ? 'Save Changes' : 'Save Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if (instCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please tap or enter a bank name'), behavior: SnackBarBehavior.floating),
                          );
                          return;
                        }
                        final balance = double.tryParse(balanceCtrl.text.replaceAll(',', '')) ?? 0.0;
                        const uuid = Uuid();
                        final autoName = nameCtrl.text.trim().isEmpty
                            ? '${instCtrl.text.trim()} ${selectedType.displayName}'
                            : nameCtrl.text.trim();

                        final newAcc = WealthAccount(
                          id: account?.id ?? uuid.v4(),
                          institution: instCtrl.text.trim(),
                          accountType: selectedType,
                          accountName: autoName,
                          maskedNumber: numberCtrl.text.trim(),
                          balance: balance,
                          currency: selectedCurrency,
                          assignedMember: memberCtrl.text.trim().isEmpty ? 'Entire Family' : memberCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                        );

                        if (isEdit) {
                          await StorageService.instance.updateWealthAccount(newAcc);
                        } else {
                          await StorageService.instance.addWealthAccount(newAcc);
                        }

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    return saved ?? false;
  }

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
            Text('Family Wealth & Banks'),
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
            tooltip: 'Sync Live Currency Rates',
            onPressed: _isSyncing ? null : _refreshSyncRates,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL FAMILY NET WORTH (USD)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormat.format(netWorth),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assets', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                          Text(currencyFormat.format(totalAssets), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Debts', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          Text(currencyFormat.format(totalLiabilities), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asset Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Accounts (${accounts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Bank'),
                onPressed: () async {
                  if (await WealthScreen.showAddAccountSheet(context)) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (accounts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No bank accounts added yet.'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () async {
                          if (await WealthScreen.showAddAccountSheet(context)) setState(() {});
                        },
                        child: const Text('Add Your First Bank'),
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
                      color: isDebt ? Colors.redAccent : Colors.green,
                    ),
                  ),
                  title: Text(acc.institution, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('${acc.accountName} ${acc.maskedNumber} • ${acc.assignedMember}', style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isDebt ? "-" : ""}${acc.currency} ${acc.balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDebt ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            if (await WealthScreen.showAddAccountSheet(context, acc)) setState(() {});
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
