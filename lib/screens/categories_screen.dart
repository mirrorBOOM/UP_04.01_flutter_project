import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/workout_category.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/validators.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();

  void _showCategoryDialog([WorkoutCategory? category]) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать категорию' : 'Новая категория'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Название категории * (макс. 40)', border: OutlineInputBorder()),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  validator: (v) => AppValidators.textLength(v, min: 2, max: 40, fieldName: 'Название категории'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Описание (макс. 150)', border: OutlineInputBorder()),
                  maxLines: 2,
                  inputFormatters: [LengthLimitingTextInputFormatter(150)],
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
              await repo.saveCategory(WorkoutCategory(
                id: isEditing ? category.id : '',
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
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
    final canManage = auth.hasRole(Role.trainer);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории фитнеса'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить категорию'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<List<WorkoutCategory>>(
            future: repo.getCategories(),
            builder: (ctx, snap) {
              return AsyncStateView<List<WorkoutCategory>>(
                snapshot: snap,
                onRetry: () => setState(() {}),
                isEmpty: (list) => list.isEmpty,
                emptyMessage: 'Категории фитнеса пока не добавлены',
                builder: (list) {
                  return isMobile
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            final c = list[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.category)),
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                subtitle: Text(c.description, overflow: TextOverflow.ellipsis),
                                trailing: canManage
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(c)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              await repo.deleteCategory(c.id);
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
                      : EntityTable<WorkoutCategory>(
                          items: list,
                          idOf: (c) => c.id,
                          columns: [
                            TableColumnSpec(label: 'Название категории', build: (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            TableColumnSpec(label: 'Описание', build: (c) => Text(c.description, overflow: TextOverflow.ellipsis)),
                          ],
                          actions: canManage
                              ? (c) => [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Редактировать',
                                      onPressed: () => _showCategoryDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Удалить',
                                      onPressed: () async {
                                        await repo.deleteCategory(c.id);
                                        setState(() {});
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