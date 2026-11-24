import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/insurance_policy.dart';
import '../services/storage_service.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  static const List<String> _popularProviders = [
    'LIC of India',
    'HDFC Life',
    'ICICI Pru',
    'SBI Life',
    'MetLife',
    'Prudential',
    'New York Life',
    'BlueCross',
    'State Farm',
    'GEICO',
  ];

  static const List<String> _claimStatuses = [
    'Active Policy',
    'Claim Filed',
    'Under Review',
    'Settled',
  ];

  static Future<bool> showAddPolicySheet(BuildContext context, [InsurancePolicy? policy]) async {
    final isEdit = policy != null;
    final providerCtrl = TextEditingController(text: policy?.provider ?? '');
    final nameCtrl = TextEditingController(text: policy?.policyName ?? '');
    final numberCtrl = TextEditingController(text: policy?.policyNumber ?? '');
    final insuredCtrl = TextEditingController(text: policy?.insuredMember ?? 'Entire Family');
    final nomineeCtrl = TextEditingController(text: policy?.nomineeName ?? '');
    final coverageCtrl = TextEditingController(text: policy != null && policy.coverageAmount > 0 ? policy.coverageAmount.toStringAsFixed(0) : '');
    final premiumCtrl = TextEditingController(text: policy != null && policy.premiumAmount > 0 ? policy.premiumAmount.toStringAsFixed(0) : '');
    final agentNameCtrl = TextEditingController(text: policy?.agentName ?? '');
    final agentPhoneCtrl = TextEditingController(text: policy?.agentPhone ?? '');
    final agentEmailCtrl = TextEditingController(text: policy?.agentEmail ?? '');
    final agentCodeCtrl = TextEditingController(text: policy?.agentCode ?? '');
    final claimRefCtrl = TextEditingController(text: policy?.claimReferenceNumber ?? '');
    final notesCtrl = TextEditingController(text: policy?.notes ?? '');

    InsuranceType selectedType = policy?.type ?? InsuranceType.lifeLic;
    String selectedFreq = policy?.premiumFrequency ?? 'Annual';
    String selectedClaimStatus = policy?.claimStatus ?? 'Active Policy';
    DateTime? nextDue = policy?.nextPremiumDueDate;
    DateTime? maturityDate = policy?.maturityOrExpiryDate;
    String policyDocPath = policy?.policyDocPath ?? '';
    String claimDocPath = policy?.claimDocPath ?? '';
    final picker = ImagePicker();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          maxChildSize: 0.96,
          minChildSize: 0.65,
          builder: (ctx, scrollCtrl) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: ListView(
              controller: scrollCtrl,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Policy / LIC' : 'Add Insurance / LIC / Claim',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop(false)),
                  ],
                ),
                const SizedBox(height: 8),

                // POLICY TYPE CHIPS
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: InsuranceType.values.map((t) {
                    return ChoiceChip(
                      label: Text(t.displayName, style: const TextStyle(fontSize: 11)),
                      selected: selectedType == t,
                      onSelected: (_) => setModalState(() => selectedType = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // POPULAR PROVIDERS CHIPS
                const Text('Provider (Tap or Type)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _popularProviders.map((p) {
                    return ChoiceChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      selected: providerCtrl.text.trim().toLowerCase() == p.toLowerCase(),
                      onSelected: (_) => setModalState(() => providerCtrl.text = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: providerCtrl,
                  decoration: const InputDecoration(labelText: 'Company / Provider * (e.g. LIC of India, MetLife)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Plan / Policy Name', hintText: 'e.g. Jeevan Anand', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: numberCtrl,
                        decoration: const InputDecoration(labelText: 'Policy Number', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: coverageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sum Assured / Cover', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: premiumCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Premium Amount', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: insuredCtrl,
                        decoration: const InputDecoration(labelText: 'Insured Member', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: nomineeCtrl,
                        decoration: const InputDecoration(labelText: 'Nominee / Beneficiary', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // FREQUENCY CHIPS
                Row(
                  children: [
                    const Text('Premium: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...['Monthly', 'Quarterly', 'Annual'].map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(f, style: const TextStyle(fontSize: 11)),
                          selected: selectedFreq == f,
                          onSelected: (_) => setModalState(() => selectedFreq = f),
                        ),
                      );
                    }),
                  ],
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_rounded, color: Colors.amber),
                  title: Text(nextDue != null ? 'Next Premium Due: ${DateFormat.yMMMd().format(nextDue!)}' : 'Set Next Premium Due Date'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: nextDue ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null) setModalState(() => nextDue = picked);
                    },
                    child: const Text('Pick Date'),
                  ),
                ),

                // AGENT DETAILS EXPANSION
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: agentNameCtrl.text.isNotEmpty || agentPhoneCtrl.text.isNotEmpty,
                  title: const Text('Agent / Advisor Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: agentNameCtrl, decoration: const InputDecoration(labelText: 'Agent Name', border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: agentCodeCtrl, decoration: const InputDecoration(labelText: 'Agent Code', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: agentPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Agent Phone', border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: agentEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Agent Email', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),

                // CLAIMS & DOCUMENTS EXPANSION
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: selectedClaimStatus != 'Active Policy' || policyDocPath.isNotEmpty || claimDocPath.isNotEmpty,
                  title: const Text('Policy Docs, LIC Bond & Claim Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  children: [
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _claimStatuses.map((s) {
                        return ChoiceChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          selected: selectedClaimStatus == s,
                          onSelected: (_) => setModalState(() => selectedClaimStatus = s),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: claimRefCtrl,
                      decoration: const InputDecoration(labelText: 'Claim Reference # (if filed)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.description_outlined, size: 18),
                            label: Text(policyDocPath.isEmpty ? 'Attach Policy/LIC Doc' : '✓ Policy Doc Attached'),
                            onPressed: () async {
                              final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                              if (file != null) setModalState(() => policyDocPath = file.path);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.assignment_outlined, size: 18),
                            label: Text(claimDocPath.isEmpty ? 'Attach Claim Doc' : '✓ Claim Doc Attached'),
                            onPressed: () async {
                              final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                              if (file != null) setModalState(() => claimDocPath = file.path);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event, color: Colors.green),
                      title: Text(maturityDate != null ? 'Maturity/Expiry: ${DateFormat.yMMMd().format(maturityDate!)}' : 'Set Maturity / Expiry Date'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: maturityDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2080),
                          );
                          if (picked != null) setModalState(() => maturityDate = picked);
                        },
                        child: const Text('Pick Date'),
                      ),
                    ),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes (Safe location, rider details)', border: OutlineInputBorder()),
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
                    icon: const Icon(Icons.verified_user_rounded),
                    label: Text(isEdit ? 'Save Policy' : 'Save Insurance Policy', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (providerCtrl.text.trim().isEmpty) return;
                      const uuid = Uuid();
                      final updated = InsurancePolicy(
                        id: policy?.id ?? uuid.v4(),
                        type: selectedType,
                        provider: providerCtrl.text.trim(),
                        policyName: nameCtrl.text.trim().isEmpty ? selectedType.displayName : nameCtrl.text.trim(),
                        policyNumber: numberCtrl.text.trim(),
                        insuredMember: insuredCtrl.text.trim().isEmpty ? 'Entire Family' : insuredCtrl.text.trim(),
                        nomineeName: nomineeCtrl.text.trim(),
                        coverageAmount: double.tryParse(coverageCtrl.text.replaceAll(',', '')) ?? 0.0,
                        premiumAmount: double.tryParse(premiumCtrl.text.replaceAll(',', '')) ?? 0.0,
                        premiumFrequency: selectedFreq,
                        nextPremiumDueDate: nextDue,
                        maturityOrExpiryDate: maturityDate,
                        agentName: agentNameCtrl.text.trim(),
                        agentPhone: agentPhoneCtrl.text.trim(),
                        agentEmail: agentEmailCtrl.text.trim(),
                        agentCode: agentCodeCtrl.text.trim(),
                        claimStatus: selectedClaimStatus,
                        claimReferenceNumber: claimRefCtrl.text.trim(),
                        policyDocPath: policyDocPath,
                        claimDocPath: claimDocPath,
                        notes: notesCtrl.text.trim(),
                      );

                      if (isEdit) {
                        await StorageService.instance.updatePolicy(updated);
                      } else {
                        await StorageService.instance.addPolicy(updated);
                      }

                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return saved ?? false;
  }

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  InsuranceType? _filterType;
  bool _onlyClaims = false;

  void _copy(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied!'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allPolicies = StorageService.instance.policies;
    final filtered = allPolicies.where((p) {
      if (_onlyClaims && p.claimStatus == 'Active Policy') return false;
      if (_filterType != null && p.type != _filterType) return false;
      return true;
    }).toList();

    final totalCoverage = allPolicies.fold(0.0, (s, p) => s + p.coverageAmount);
    final activeClaims = allPolicies.where((p) => p.claimStatus != 'Active Policy').length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: Colors.indigoAccent, size: 24),
            SizedBox(width: 8),
            Text('Insurance, LIC & Claims'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigoAccent.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Coverage', style: TextStyle(fontSize: 12, color: Colors.indigoAccent, fontWeight: FontWeight.w600)),
                      Text(currencyFormat.format(totalCoverage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Container(width: 1, height: 30, color: theme.colorScheme.outlineVariant),
                  Column(
                    children: [
                      const Text('Policies / Claims', style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600)),
                      Text('${allPolicies.length} Policies • $activeClaims Claims', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterType == null && !_onlyClaims,
                  onSelected: (_) => setState(() {
                    _filterType = null;
                    _onlyClaims = false;
                  }),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Claims Only'),
                  selected: _onlyClaims,
                  onSelected: (v) => setState(() => _onlyClaims = v),
                ),
                const SizedBox(width: 6),
                ...InsuranceType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(t.displayName),
                        selected: _filterType == t,
                        onSelected: (_) => setState(() => _filterType = _filterType == t ? null : t),
                      ),
                    )),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No policies or claims found.'),
                        TextButton(
                          onPressed: () async {
                            if (await InsuranceScreen.showAddPolicySheet(context)) setState(() {});
                          },
                          child: const Text('Add Life / LIC / Insurance Policy'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: filtered.length,
                    itemBuilder: (_, idx) {
                      final p = filtered[idx];
                      final hasClaim = p.claimStatus != 'Active Policy';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.policy_rounded, color: Colors.indigoAccent),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.policyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('${p.provider} • ${p.type.displayName}', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (hasClaim ? Colors.amber : Colors.green).withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p.claimStatus,
                                      style: TextStyle(
                                        color: hasClaim ? Colors.amber : Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (a) async {
                                      if (a == 'edit') {
                                        if (await InsuranceScreen.showAddPolicySheet(context, p)) setState(() {});
                                      } else if (a == 'delete') {
                                        await StorageService.instance.deletePolicy(p.id);
                                        setState(() {});
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Policy #', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      GestureDetector(
                                        onTap: () => _copy(p.policyNumber, 'Policy Number'),
                                        child: Text('${p.policyNumber} 📋', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Coverage', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(currencyFormat.format(p.coverageAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Premium (${p.premiumFrequency})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(currencyFormat.format(p.premiumAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (p.nomineeName.isNotEmpty)
                                Text('👤 Insured: ${p.insuredMember}  •  Nominee: ${p.nomineeName}', style: const TextStyle(fontSize: 12)),

                              if (p.agentName.isNotEmpty || p.agentPhone.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(110),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.support_agent_rounded, size: 18, color: Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Agent: ${p.agentName} ${p.agentCode.isNotEmpty ? "(${p.agentCode})" : ""}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (p.agentPhone.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.phone_rounded, size: 18, color: Colors.green),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => launchUrl(Uri.parse('tel:${p.agentPhone}')),
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              if (p.claimReferenceNumber.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('Claim Ref: ${p.claimReferenceNumber}', style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                                ),

                              if (p.policyDocPath.isNotEmpty || p.claimDocPath.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (p.policyDocPath.isNotEmpty)
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: kIsWeb
                                              ? Image.network(p.policyDocPath, height: 70, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Text('Policy Doc'))
                                              : Image.file(File(p.policyDocPath), height: 70, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Text('Policy Doc')),
                                        ),
                                      ),
                                    if (p.policyDocPath.isNotEmpty && p.claimDocPath.isNotEmpty) const SizedBox(width: 8),
                                    if (p.claimDocPath.isNotEmpty)
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: kIsWeb
                                              ? Image.network(p.claimDocPath, height: 70, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Text('Claim Doc'))
                                              : Image.file(File(p.claimDocPath), height: 70, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Text('Claim Doc')),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Policy / LIC'),
        onPressed: () async {
          if (await InsuranceScreen.showAddPolicySheet(context)) setState(() {});
        },
      ),
    );
  }
}
