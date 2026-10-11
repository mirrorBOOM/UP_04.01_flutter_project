import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/equipment_inventory.dart';
import '../models/gym_hall.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class HallsInventoryScreen extends StatefulWidget {
  const HallsInventoryScreen({super.key});

  @override
  State<HallsInventoryScreen> createState() => _HallsInventoryScreenState();
}

class _HallsInventoryScreenState extends State<HallsInventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showHallDialog([GymHall? hall]) {
    final isEditing = hall != null;
    final nameCtrl = TextEditingController(text: hall?.name ?? '');
    final capCtrl = TextEditingController(text: hall?.capacity.toString() ?? '25');
    final floorCtrl = TextEditingController(text: hall?.floor.toString() ?? '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать зал' : 'Новый зал клуба'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название зала *')),
            const SizedBox(height: 12),
            TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Вместимость (чел)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: floorCtrl, decoration: const InputDecoration(labelText: 'Этаж'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final repo = context.read<PocketBaseRepository>();
              await repo.saveHall(GymHall(
                id: isEditing ? hall.id : '',
                name: nameCtrl.text.trim(),
                capacity: int.tryParse(capCtrl.text) ?? 20,
                floor: int.tryParse(floorCtrl.text) ?? 1,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(isEditing ? 'Сохранить' : 'Создать'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentDialog(List<GymHall> halls, [EquipmentInventory? eq]) {
    if (halls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала добавьте хотя бы один зал!')));
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
          title: Text(isEditing ? 'Редактировать инвентарь' : 'Добавить инвентарь в зал'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Наименование снаряда/тренажёра *')),
              const SizedBox(height: 12),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Количество (шт)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: hallId,
                decoration: const InputDecoration(labelText: 'Зал размещения'),
                items: halls.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))).toList(),
                onChanged: (val) => setDlgState(() => hallId = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: condition,
                decoration: const InputDecoration(labelText: 'Состояние'),
                items: const [
                  DropdownMenuItem(value: 'EXCELLENT', child: Text('Отличное')),
                  DropdownMenuItem(value: 'GOOD', child: Text('Хорошее')),
                  DropdownMenuItem(value: 'REPAIR', child: Text('Требует ремонта')),
                ],
                onChanged: (val) => setDlgState(() => condition = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
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
              child: Text(isEditing ? 'Сохранить' : 'Добавить'),
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
        title: const Text('Залы и спортивный инвентарь '),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.meeting_room), text: 'Залы клуба '),
            Tab(icon: Icon(Icons.fitness_center), text: 'Инвентарь '),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: FutureBuilder<List<GymHall>>(
                future: repo.getHalls(),
                builder: (ctx, snap) {
                  return Scaffold(
                    floatingActionButton: canManage
                        ? FloatingActionButton.extended(
                            onPressed: () => _showHallDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Новый зал'),
                          )
                        : null,
                    body: AsyncStateView<List<GymHall>>(
                      snapshot: snap,
                      onRetry: () => setState(() {}),
                      isEmpty: (list) => list.isEmpty,
                      emptyMessage: 'Залы клуба пока не созданы',
                      builder: (halls) {
                        return isMobile
                            ? ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: halls.length,
                                itemBuilder: (ctx, i) {
                                  final h = halls[i];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: const CircleAvatar(child: Icon(Icons.meeting_room)),
                                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      subtitle: Text('Вместимость: ${h.capacity} чел. • Этаж: ${h.floor}'),
                                      trailing: canManage
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showHallDialog(h)),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    try {
                                                      await repo.deleteHall(h.id);
                                                      setState(() {});
                                                    } catch (e) {
                                                      if (ctx.mounted) {
                                                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.orange));
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : EntityTable<GymHall>(
                                items: halls,
                                idOf: (h) => h.id,
                                columns: [
                                  TableColumnSpec(label: 'Зал', build: (h) => Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  TableColumnSpec(label: 'Вместимость', numeric: true, build: (h) => Text('${h.capacity} чел.')),
                                  TableColumnSpec(label: 'Этаж', numeric: true, build: (h) => Text('${h.floor}')),
                                ],
                                actions: canManage
                                    ? (h) => [
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showHallDialog(h)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              try {
                                                await repo.deleteHall(h.id);
                                                setState(() {});
                                              } catch (e) {
                                                if (ctx.mounted) {
                                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.orange));
                                                }
                                              }
                                            },
                                          ),
                                        ]
                                    : null,
                              );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: FutureBuilder<List<GymHall>>(
                future: repo.getHalls(),
                builder: (ctx, hallSnap) {
                  final halls = hallSnap.data ?? [];
                  return FutureBuilder<List<EquipmentInventory>>(
                    future: repo.getEquipment(),
                    builder: (ctx, eqSnap) {
                      return Scaffold(
                        floatingActionButton: canManage
                            ? FloatingActionButton.extended(
                                onPressed: () => _showEquipmentDialog(halls),
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить инвентарь'),
                              )
                            : null,
                        body: AsyncStateView<List<EquipmentInventory>>(
                          snapshot: eqSnap,
                          onRetry: () => setState(() {}),
                          isEmpty: (list) => list.isEmpty,
                          emptyMessage: 'Спортивный инвентарь пока не добавлен',
                          builder: (items) {
                            return isMobile
                                ? ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: items.length,
                                    itemBuilder: (ctx, i) {
                                      final e = items[i];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: ListTile(
                                          leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                                          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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
                                      TableColumnSpec(label: 'Снаряд / Тренажёр', build: (e) => Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                      TableColumnSpec(label: 'Зал ', build: (e) => Text(e.hallName ?? '—', overflow: TextOverflow.ellipsis)),
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}