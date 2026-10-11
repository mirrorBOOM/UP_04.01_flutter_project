import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/membership_card.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/validators.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class MembershipCardsScreen extends StatefulWidget {
  const MembershipCardsScreen({super.key});

  @override
  State<MembershipCardsScreen> createState() => _MembershipCardsScreenState();
}

class _MembershipCardsScreenState extends State<MembershipCardsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _showCardDialog(List<Client> clients, [MembershipCard? card]) {
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала добавьте клиента в разделе Клиенты!')));
      return;
    }

    final isEditing = card != null;
    final numCtrl = TextEditingController(text: card?.cardNumber ?? 'CARD-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final visitsCtrl = TextEditingController(text: card?.balanceVisits.toString() ?? '20');
    final validCtrl = TextEditingController(text: card?.validUntil ?? '2026-12-31');
    String clientId = card?.clientId ?? clients.first.id;
    String status = card?.status ?? 'ACTIVE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isEditing ? 'Редактировать клубную карту' : 'Выдать клубную карту'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: numCtrl,
                    decoration: const InputDecoration(labelText: 'Номер карты * (3-20 симв.)', border: OutlineInputBorder()),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]')),
                    ],
                    validator: (v) => AppValidators.code(v, label: 'Номер карты'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: clientId,
                    decoration: const InputDecoration(labelText: 'Владелец карты (Клиент 1:1)', border: OutlineInputBorder()),
                    items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullName))).toList(),
                    onChanged: (val) => setDlgState(() => clientId = val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: visitsCtrl,
                    decoration: const InputDecoration(labelText: 'Остаток посещений (1-365) *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [LengthLimitingTextInputFormatter(3), FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => AppValidators.rangeInt(v, min: 1, max: 365, fieldName: 'Остаток посещений'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: validCtrl,
                    decoration: const InputDecoration(labelText: 'Действует до (ГГГГ-ММ-ДД) *', border: OutlineInputBorder()),
                    inputFormatters: [LengthLimitingTextInputFormatter(10)],
                    validator: AppValidators.dateIso,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Статус карты', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Активна)')),
                      DropdownMenuItem(value: 'FROZEN', child: Text('FROZEN (Заморожена)')),
                      DropdownMenuItem(value: 'EXPIRED', child: Text('EXPIRED (Истекла)')),
                    ],
                    onChanged: (val) => setDlgState(() => status = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final repo = context.read<PocketBaseRepository>();
                await repo.saveMembershipCard(MembershipCard(
                  id: isEditing ? card.id : '',
                  cardNumber: numCtrl.text.trim(),
                  clientId: clientId,
                  validUntil: validCtrl.text.trim(),
                  status: status,
                  balanceVisits: int.tryParse(visitsCtrl.text) ?? 10,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(isEditing ? 'Сохранить' : 'Выдать карту'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PocketBaseRepository>();
    final auth = context.watch<AuthNotifier>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canManage = auth.hasRole(Role.admin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Клубные карты'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final clients = await repo.getClients();
                if (context.mounted) _showCardDialog(clients);
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Выдать карту'),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<List<Client>>(
              future: repo.getClients(),
              builder: (ctx, clientSnap) {
                final clients = clientSnap.data ?? [];

                return FutureBuilder<List<MembershipCard>>(
                  future: repo.getMembershipCards(),
                  builder: (ctx, snap) {
                    return AsyncStateView<List<MembershipCard>>(
                      snapshot: snap,
                      onRetry: () => setState(() {}),
                      isEmpty: (list) => list.isEmpty,
                      emptyMessage: 'Клубные карты пока не выданы',
                      builder: (cards) {
                        return isMobile
                            ? ListView.builder(
                                itemCount: cards.length,
                                itemBuilder: (ctx, i) {
                                  final card = cards[i];
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.credit_card, color: Colors.deepOrange),
                                      title: Text(card.cardNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Клиент: ${card.clientName ?? "Привязан"} • Остаток: ${card.balanceVisits} визитов'),
                                      trailing: canManage
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCardDialog(clients, card)),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    await repo.deleteMembershipCard(card.id);
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            )
                                          : Chip(label: Text(card.status)),
                                    ),
                                  );
                                },
                              )
                            : EntityTable<MembershipCard>(
                                items: cards,
                                idOf: (c) => c.id,
                                columns: [
                                  TableColumnSpec(label: 'Номер карты', build: (c) => Text(c.cardNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  TableColumnSpec(label: 'Владелец', build: (c) => Text(c.clientName ?? 'Клиент')),
                                  TableColumnSpec(label: 'Остаток визитов', numeric: true, build: (c) => Text('${c.balanceVisits}')),
                                  TableColumnSpec(label: 'Статус', build: (c) => Chip(label: Text(c.status))),
                                ],
                                actions: canManage
                                    ? (c) => [
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCardDialog(clients, c)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              await repo.deleteMembershipCard(c.id);
                                              setState(() {});
                                            },
                                          ),
                                        ]
                                    : null,
                              );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}