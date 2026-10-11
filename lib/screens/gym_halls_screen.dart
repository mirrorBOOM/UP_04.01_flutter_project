import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/gym_hall.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/validators.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class GymHallsScreen extends StatefulWidget {
  const GymHallsScreen({super.key});

  @override
  State<GymHallsScreen> createState() => _GymHallsScreenState();
}

class _GymHallsScreenState extends State<GymHallsScreen> {
  final _formKey = GlobalKey<FormState>();

  void _showHallDialog([GymHall? hall]) {
    final isEditing = hall != null;
    final nameCtrl = TextEditingController(text: hall?.name ?? '');
    final capCtrl = TextEditingController(text: hall?.capacity.toString() ?? '25');
    final floorCtrl = TextEditingController(text: hall?.floor.toString() ?? '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать зал' : 'Новый зал клуба'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Название зала * (макс. 50)', border: OutlineInputBorder()),
                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                  validator: (v) => AppValidators.textLength(v, min: 2, max: 50, fieldName: 'Название зала'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capCtrl,
                  decoration: const InputDecoration(labelText: 'Вместимость (1-300 чел) *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(3), FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => AppValidators.rangeInt(v, min: 1, max: 300, fieldName: 'Вместимость'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: floorCtrl,
                  decoration: const InputDecoration(labelText: 'Этаж (1-25) *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => AppValidators.rangeInt(v, min: 1, max: 25, fieldName: 'Этаж'),
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

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PocketBaseRepository>();
    final auth = context.watch<AuthNotifier>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canManage = auth.hasRole(Role.admin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Залы клуба'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showHallDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить зал'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: FutureBuilder<List<GymHall>>(
            future: repo.getHalls(),
            builder: (ctx, snap) {
              return AsyncStateView<List<GymHall>>(
                snapshot: snap,
                onRetry: () => setState(() {}),
                isEmpty: (list) => list.isEmpty,
                emptyMessage: 'Залы пока не созданы',
                builder: (halls) {
                  return isMobile
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: halls.length,
                          itemBuilder: (ctx, i) {
                            final h = halls[i];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.meeting_room)),
                                title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            TableColumnSpec(label: 'Зал', build: (h) => Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold))),
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
              );
            },
          ),
        ),
      ),
    );
  }
}