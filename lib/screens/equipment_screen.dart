import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/equipment_inventory.dart';
import '../models/gym_hall.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/validators.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  void _showEquipmentDialog(List<GymHall> halls, [EquipmentInventory? eq]) {
    if (halls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала создайте зал в разделе Залы!')));
      return;
    }

    final isEditing = eq != null;
    final titleCtrl = TextEditingController(text: eq?.title ?? '');
    final qtyCtrl = TextEditingController(text: eq?.quantity.toString() ?? '5');
    String hallId = eq?.hallId ?? halls.first.id;
    String condition = eq?.condition ?? 'GOOD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isEditing ? 'Редактировать снаряд' : 'Новый инвентарь'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Наименование * (макс. 50)', border: OutlineInputBorder()),
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    validator: (v) => AppValidators.textLength(v, min: 2, max: 50, fieldName: 'Наименование'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Количество (1-500 шт) *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [LengthLimitingTextInputFormatter(3), FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => AppValidators.rangeInt(v, min: 1, max: 500, fieldName: 'Количество'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: hallId,
                    decoration: const InputDecoration(labelText: 'Зал размещения', border: OutlineInputBorder()),
                    items: halls.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))).toList(),
                    onChanged: (val) => setDlgState(() => hallId = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: condition,
                    decoration: const InputDecoration(labelText: 'Состояние', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'EXCELLENT', child: Text('Отличное')),
                      DropdownMenuItem(value: 'GOOD', child: Text('Хорошее')),
                      DropdownMenuItem(value: 'REPAIR', child: Text('Требует ремонта')),
                    ],
                    onChanged: (val) => setDlgState(() => condition = val!),
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
                await repo.saveEquipment(EquipmentInventory(
                  id: isEditing ? eq.id : '',
                  title: titleCtrl.text.trim(),
                  hallId: hallId,
                  quantity: int.tryParse(qtyCtrl.text) ?? 1,
                  condition: condition,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(isEditing ? 'Сохранить' : 'Создать'),
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
        title: const Text('Инвентарь залов'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final halls = await repo.getHalls();
                if (context.mounted) _showEquipmentDialog(halls);
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить инвентарь'),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<List<GymHall>>(
              future: repo.getHalls(),
              builder: (ctx, hallSnap) {
                final halls = hallSnap.data ?? [];

                return FutureBuilder<List<EquipmentInventory>>(
                  future: repo.getEquipment(),
                  builder: (ctx, snap) {
                    return AsyncStateView<List<EquipmentInventory>>(
                      snapshot: snap,
                      onRetry: () => setState(() {}),
                      isEmpty: (list) => list.isEmpty,
                      emptyMessage: 'Инвентарь пока не добавлен',
                      builder: (items) {
                        return isMobile
                            ? ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (ctx, i) {
                                  final e = items[i];
                                  return Card(
                                    child: ListTile(
                                      leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Зал: ${e.hallName ?? "Основной"} • ${e.quantity} шт. • ${e.condition}'),
                                      trailing: canManage
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEquipmentDialog(halls, e)),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    await repo.deleteEquipment(e.id);
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
                            : EntityTable<EquipmentInventory>(
                                items: items,
                                idOf: (e) => e.id,
                                columns: [
                                  TableColumnSpec(label: 'Снаряд', build: (e) => Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  TableColumnSpec(label: 'Зал', build: (e) => Text(e.hallName ?? '—')),
                                  TableColumnSpec(label: 'Кол-во', numeric: true, build: (e) => Text('${e.quantity} шт.')),
                                  TableColumnSpec(label: 'Состояние', build: (e) => Chip(label: Text(e.condition))),
                                ],
                                actions: canManage
                                    ? (e) => [
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEquipmentDialog(halls, e)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              await repo.deleteEquipment(e.id);
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