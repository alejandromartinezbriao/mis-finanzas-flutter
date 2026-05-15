import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/logo_selector_field.dart';

class BalanceDialog extends StatefulWidget {
  final FirebaseService service;
  final Map<String, dynamic>? account;

  const BalanceDialog({
    super.key,
    required this.service,
    this.account,
  });

  @override
  State<BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<BalanceDialog> {
  late TextEditingController nameCtrl;
  late String currency;
  late String accountType;
  late String? selectedLogo;
  late bool isBimonetary;
  late bool includeInCoverage;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.account != null;
    nameCtrl = TextEditingController(
        text: widget.account?['accountName']?.toString().replaceAll(RegExp(r' \((UYU|USD)\)$'), '') ?? '');
    currency = widget.account?['currency'] ?? 'UYU';
    accountType = widget.account?['accountType'] ?? 'BANK';
    selectedLogo = widget.account?['brandLogo'];
    isBimonetary = widget.account?['isBimonetaryPart'] ?? false;
    includeInCoverage = widget.account?['includeInCoverage'] ?? true;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Editar Cuenta' : 'Nueva Cuenta (Arqueo)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'BANK', label: Text('Banco'), icon: Icon(Icons.account_balance)),
                ButtonSegment(value: 'PREPAID', label: Text('Prepaga'), icon: Icon(Icons.credit_card)),
                ButtonSegment(value: 'CASH', label: Text('Efectivo'), icon: Icon(Icons.money)),
              ],
              selected: {accountType},
              onSelectionChanged: (val) => setState(() => accountType = val.first),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (ej: Prex, Santander)', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            if (accountType == 'BANK' || accountType == 'PREPAID')
              SwitchListTile(
                title: const Text('¿Es Bimonetaria?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Crea registros para Pesos y Dólares', style: TextStyle(fontSize: 11)),
                value: isBimonetary,
                onChanged: (widget.account?['isBimonetaryPart'] == true)
                    ? null
                    : (v) => setState(() => isBimonetary = v),
              ),
            if (!isBimonetary) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: currency,
                items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => currency = v!),
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
            ],
            const SizedBox(height: 15),
            LogoSelectorField(
              selectedLogo: selectedLogo,
              onSelect: (logo) => setState(() => selectedLogo = logo),
              currentName: nameCtrl.text,
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              title: const Text('Considerar para Cobertura', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Si se apaga, el saldo de esta cuenta no se sumará al dinero disponible para pagar deudas del mes.', style: TextStyle(fontSize: 11)),
              value: includeInCoverage,
              onChanged: (v) => setState(() => includeInCoverage = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (nameCtrl.text.isNotEmpty) {
              final String currentName = nameCtrl.text;

              if (isEdit && isBimonetary && (widget.account!['isBimonetaryPart'] != true)) {
                // MIGRACIÓN INTELIGENTE
                final cleanBaseName = currentName
                    .replaceAll(RegExp(r'\s+(pesos|dólares|uyu|usd|dolares)$', caseSensitive: false), '')
                    .trim();

                final otherCurrency = (widget.account!['currency'] ?? 'UYU') == 'UYU' ? 'USD' : 'UYU';

                // Buscar posible gemela existente
                final allAccounts = await widget.service.getBalances().first;
                final existingGemela = allAccounts.where((a) {
                  final name = (a['accountName'] as String).toLowerCase();
                  return name.contains(cleanBaseName.toLowerCase()) &&
                      a['currency'] == otherCurrency &&
                      a['id'] != widget.account!['id'];
                }).firstOrNull;

                String message = "¿Deseas pasar esta cuenta a bimonetaria?";
                if (existingGemela != null) {
                  message =
                      "He encontrado la cuenta '${existingGemela['accountName']}'. ¿Deseas vincularla como la parte en $otherCurrency de '$cleanBaseName'? Ambas mantendrán sus saldos actuales.";
                } else {
                  message =
                      "Se creará una nueva cuenta gemela en $otherCurrency para '$cleanBaseName'. Tu saldo actual en ${widget.account!['currency']} se mantendrá intacto.";
                }

                if (!context.mounted) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Confirmar Migración'),
                    content: Text(message),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar')),
                    ],
                  ),
                );

                if (confirm == true) {
                  await widget.service.upgradeAccountToBimonetary(
                    originalId: widget.account!['id'],
                    baseName: cleanBaseName,
                    type: accountType,
                    logo: selectedLogo,
                    currentAmount: (widget.account!['amount'] ?? 0.0).toDouble(),
                    originalCurrency: widget.account!['currency'] ?? 'UYU',
                    existingGemelaId: existingGemela?['id'],
                    includeInCoverage: includeInCoverage,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
                return;
              }

              // FLUJO NORMAL (Creación o edición simple)
              final data = {
                'accountName': currentName,
                'currency': currency,
                'accountType': accountType,
                'brandLogo': selectedLogo,
                'isBimonetaryPart': isBimonetary,
                'includeInCoverage': includeInCoverage,
              };

              if (isEdit) {
                await widget.service.updateBalanceAccountDetails(widget.account!['id'], data);
              } else {
                await widget.service.addBalanceAccount(currentName, currency,
                    logo: selectedLogo, type: accountType, isBimonetary: isBimonetary, includeInCoverage: includeInCoverage);
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Actualizar' : 'Agregar'),
        ),
      ],
    );
  }
}
