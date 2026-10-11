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

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _showClientDialog(List<MembershipCard> cards, [Client? client]) {
    final isEditing = client != null;
    final nameCtrl = TextEditingController(text: client?.fullName ?? '');
    final emailCtrl = TextEditingController(text: client?.email ?? '');
    final phoneCtrl = TextEditingController(text: client?.phone ?? '+7 ');

    final existingCard = isEditing
        ? cards.cast<MembershipCard?>().firstWhere((c) => c?.clientId == client.id, orElse: () => null)
        : null;
    final cardNumCtrl = TextEditingController(text: existingCard?.cardNumber ?? 'CARD-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final visitsCtrl = TextEditingController(text: existingCard?.balanceVisits.toString() ?? '12');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать клиента' : 'Новый клиент + Карта'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ФИО клиента *', border: OutlineInputBorder()),
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    validator: (v) => AppValidators.textLength(v, min: 3, max: 50, fieldName: 'ФИО'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email * (макс. 50)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Телефон * (макс. 18)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(18),
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-\(\)]')),
                    ],
                    validator: AppValidators.phone,
                  ),
                  const Divider(height: 32),
                  const Text('Клубная карта (Связь 1:1):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cardNumCtrl,
                    decoration: const InputDecoration(labelText: 'Номер карты * (3-20 симв.)', border: OutlineInputBorder()),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]')),
                    ],
                    validator: (v) => AppValidators.code(v, label: 'Номер карты'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: visitsCtrl,
                    decoration: const InputDecoration(labelText: 'Баланс посещений (1-365) *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) => AppValidators.rangeInt(v, min: 1, max: 365, fieldName: 'Баланс посещений'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final repo = context.read<PocketBaseRepository>();

              final savedClient = Client(
                id: isEditing ? client.id : '',
                fullName: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              await repo.saveClient(savedClient);

              if (!isEditing) {
                final allClients = await repo.getClients();
                final created = allClients.firstWhere((c) => c.email == savedClient.email, orElse: () => allClients.last);
                await repo.saveMembershipCard(MembershipCard(
                  id: '',
                  cardNumber: cardNumCtrl.text.trim(),
                  clientId: created.id,
                  validUntil: '2026-12-31',
                  status: 'ACTIVE',
                  balanceVisits: int.tryParse(visitsCtrl.text) ?? 10,
                ));
              }

              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(isEditing ? 'Сохранить' : 'Создать'),
          ),
        ],
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
        title: const Text('Клиенты клуба'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final cards = await repo.getMembershipCards();
                if (context.mounted) _showClientDialog(cards);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить клиента'),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<List<MembershipCard>>(
              future: repo.getMembershipCards(),
              builder: (ctx, cardSnap) {
                final cards = cardSnap.data ?? [];

                return FutureBuilder<List<Client>>(
                  future: repo.getClients(),
                  builder: (ctx, snap) {
                    return AsyncStateView<List<Client>>(
                      snapshot: snap,
                      onRetry: () => setState(() {}),
                      isEmpty: (list) => list.isEmpty,
                      emptyMessage: 'Клиенты пока не добавлены',
                      builder: (clients) {
                        return isMobile
                            ? ListView.builder(
                                itemCount: clients.length,
                                itemBuilder: (ctx, i) {
                                  final c = clients[i];
                                  return Card(
                                    child: ListTile(
                                      leading: const CircleAvatar(child: Icon(Icons.person)),
                                      title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${c.email} • ${c.phone}'),
                                      trailing: canManage
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showClientDialog(cards, c)),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    await repo.deleteClient(c.id);
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : EntityTable<Client>(
                                items: clients,
                                idOf: (c) => c.id,
                                columns: [
                                  TableColumnSpec(label: 'ФИО', build: (c) => Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  TableColumnSpec(label: 'Email', build: (c) => Text(c.email)),
                                  TableColumnSpec(label: 'Телефон', build: (c) => Text(c.phone)),
                                ],
                                actions: canManage
                                    ? (c) => [
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showClientDialog(cards, c)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              await repo.deleteClient(c.id);
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