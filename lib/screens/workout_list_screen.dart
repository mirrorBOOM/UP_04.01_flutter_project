import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/gym_hall.dart';
import '../models/trainer.dart';
import '../models/workout.dart';
import '../models/workout_query.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../state/workout_list_notifier.dart';
import '../widgets/entity_table.dart';

class WorkoutListScreen extends StatefulWidget {
  final WorkoutQuery initialQuery;

  const WorkoutListScreen({super.key, required this.initialQuery});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late final TextEditingController _searchController;
  List<GymHall> _halls = [];
  List<Trainer> _trainers = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutListNotifier>().applyQuery(widget.initialQuery);
      _loadFilterData();
    });
  }

  Future<void> _loadFilterData() async {
    final repo = context.read<PocketBaseRepository>();
    final halls = await repo.getHalls();
    final trainers = await repo.getTrainers();
    if (mounted) {
      setState(() {
        _halls = halls;
        _trainers = trainers;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncUrl(WorkoutQuery q) {
    final params = <String, String>{
      if (q.search.isNotEmpty) 'search': q.search,
      if (q.hallId != null && q.hallId!.isNotEmpty) 'hallId': q.hallId!,
      if (q.trainerId != null && q.trainerId!.isNotEmpty) 'trainerId': q.trainerId!,
      if (q.includeDeleted) 'includeDeleted': 'true',
      'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
      'page': q.page.toString(),
      'perPage': q.perPage.toString(),
    };
    context.go(Uri(path: '/', queryParameters: params).toString());
  }

  void _confirmDeleteSingle(BuildContext context, Workout w, WorkoutListNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удаление программы: ${w.title}'),
        content: const Text('Выберите тип удаления:\n• Логическое — переместить в архив с возможностью восстановления.\n• Физическое — безвозвратно стереть из базы PocketBase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.softDelete(w.id);
            },
            child: const Text('В архив (Логическое)'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.hardDelete(w.id);
            },
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context, WorkoutListNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Множественное удаление'),
        content: Text('Удалить выбранные программы (${notifier.selected.length} шт.) в архив?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in notifier.selected) {
                await notifier.softDelete(id);
              }
            },
            child: const Text('Удалить выбранные'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<WorkoutListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canManage = auth.hasRole(Role.trainer);
    final isAdmin = auth.hasRole(Role.admin);

    return Scaffold(
      appBar: AppBar(
        title: Text('Фитнес-клуб (${auth.user?.fullName ?? ""})'),
        actions: [
          if (notifier.hasSelection && canManage)
            IconButton(
              icon: Badge(
                label: Text('${notifier.selected.length}'),
                child: const Icon(Icons.delete_sweep, color: Colors.red, size: 28),
              ),
              tooltip: 'Удалить выбранные',
              onPressed: () => _confirmBulkDelete(context, notifier),
            ),
          if (auth.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Chip(label: Text(auth.user!.role.label), backgroundColor: Colors.white),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => context.read<AuthNotifier>().logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepOrange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Фитнес-клуб', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${auth.user?.fullName ?? ""} (${auth.user?.role.label ?? ""})', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('1. Каталог программ '),
              onTap: () { Navigator.pop(context); context.go('/'); },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('2. Залы клуба'),
              onTap: () { Navigator.pop(context); context.go('/halls'); },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('3. Инвентарь залов'),
              onTap: () { Navigator.pop(context); context.go('/equipment'); },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('4. Категории'),
              onTap: () { Navigator.pop(context); context.go('/categories'); },
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('5. Тренеры '),
              onTap: () { Navigator.pop(context); context.go('/trainers'); },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('6. Клиенты'),
              onTap: () { Navigator.pop(context); context.go('/clients'); },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('7. Клубные карты'),
              onTap: () { Navigator.pop(context); context.go('/cards'); },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('8. Бронирования'),
              onTap: () { Navigator.pop(context); context.go('/bookings'); },
            ),
            const Divider(),
            if (auth.user?.role == Role.client)
              ListTile(
                leading: const Icon(Icons.account_box, color: Colors.deepOrange),
                title: const Text('Личный кабинет клиента'),
                onTap: () { Navigator.pop(context); context.go('/my-bookings'); },
              ),
            if (auth.user?.role == Role.trainer)
              ListTile(
                leading: const Icon(Icons.event_note, color: Colors.blue),
                title: const Text('Журнал тренера'),
                onTap: () { Navigator.pop(context); context.go('/trainer/journal'); },
              ),
            if (auth.user?.role == Role.admin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                title: const Text('Сводная аналитика клуба'),
                onTap: () { Navigator.pop(context); context.go('/admin/analytics'); },
              ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/workouts/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить тренировку'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: 0,
              destinations: [
                const NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Каталог'),
                if (auth.user?.role == Role.client)
                  const NavigationDestination(icon: Icon(Icons.credit_card), label: 'Кабинет')
                else if (auth.user?.role == Role.admin)
                  const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Аналитика')
                else
                  const NavigationDestination(icon: Icon(Icons.event_note), label: 'Журнал'),
              ],
              onDestinationSelected: (idx) {
                if (idx == 1) {
                  if (auth.user?.role == Role.client) {
                    context.go('/my-bookings');
                  } else if (auth.user?.role == Role.admin) {
                    context.go('/admin/analytics');
                  } else {
                    context.go('/trainer/journal');
                  }
                }
              },
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Поиск по названию или коду...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (text) {
                          notifier.setSearchDebounced(text);
                          _syncUrl(notifier.query.copyWith(search: text));
                        },
                      ),
                    ),
                    DropdownButton<String?>(
                      value: notifier.query.hallId,
                      hint: const Text('Все залы'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все залы')),
                        ..._halls.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))),
                      ],
                      onChanged: (val) {
                        final next = notifier.query.copyWith(hallId: val);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      },
                    ),
                    DropdownButton<String?>(
                      value: notifier.query.trainerId,
                      hint: const Text('Все тренеры'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все тренеры')),
                        ..._trainers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))),
                      ],
                      onChanged: (val) {
                        final next = notifier.query.copyWith(trainerId: val);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Архивные'),
                        Switch(
                          value: notifier.query.includeDeleted,
                          onChanged: (val) {
                            final next = notifier.query.copyWith(includeDeleted: val);
                            notifier.applyQuery(next);
                            _syncUrl(next);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (notifier.status) {
                  LoadStatus.loading => const Center(child: CircularProgressIndicator()),
                  LoadStatus.error => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          Text(notifier.error ?? 'Ошибка'),
                          ElevatedButton(onPressed: () => notifier.load(), child: const Text('Повторить')),
                        ],
                      ),
                    ),
                  _ => notifier.result.items.isEmpty
                      ? const Center(child: Text('Ничего не найдено по заданным фильтрам'))
                      : isMobile
                          ? ListView.builder(
                              itemCount: notifier.result.items.length,
                              itemBuilder: (ctx, i) {
                                final w = notifier.result.items[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    leading: canManage
                                        ? Checkbox(
                                            value: notifier.selected.contains(w.id),
                                            onChanged: (_) => notifier.toggleSelection(w.id),
                                          )
                                        : null,
                                    title: Text(w.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: w.isDeleted ? TextDecoration.lineThrough : null)),
                                    subtitle: Text('${w.code} • ${w.durationMinutes} мин • Зал: ${w.hallName ?? "Основной"}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (canManage)
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => context.go('/workouts/${w.id}/edit')),
                                        const Icon(Icons.arrow_forward_ios, size: 14),
                                      ],
                                    ),
                                    onTap: () => context.go('/workouts/${w.id}'),
                                  ),
                                );
                              },
                            )
                          : EntityTable<Workout>(
                              items: notifier.result.items,
                              idOf: (w) => w.id,
                              selected: notifier.selected,
                              onToggleSelect: canManage ? (id) => notifier.toggleSelection(id) : null,
                              sortField: notifier.query.sortField,
                              sortAscending: notifier.query.sortAscending,
                              onSort: (field) {
                                final asc = notifier.query.sortField == field ? !notifier.query.sortAscending : true;
                                final next = notifier.query.copyWith(sortField: field, sortAscending: asc);
                                notifier.applyQuery(next);
                                _syncUrl(next);
                              },
                              columns: [
                                TableColumnSpec(
                                  label: 'Название (Карточка)',
                                  sortField: 'title',
                                  build: (w) => InkWell(
                                    onTap: () => context.go('/workouts/${w.id}'),
                                    child: Text(w.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, decoration: w.isDeleted ? TextDecoration.lineThrough : TextDecoration.underline)),
                                  ),
                                ),
                                TableColumnSpec(label: 'Артикул', build: (w) => Text(w.code)),
                                TableColumnSpec(label: 'Длительность', sortField: 'duration', numeric: true, build: (w) => Text('${w.durationMinutes} мин')),
                                TableColumnSpec(label: 'Зал', build: (w) => Text(w.hallName ?? '—')),
                                TableColumnSpec(label: 'Тренер', build: (w) => Text(w.trainerName ?? '—')),
                                TableColumnSpec(label: 'Места', numeric: true, build: (w) => Text('${w.capacityAvailable}/${w.capacityTotal}')),
                              ],
                              actions: (w) => [
                                IconButton(icon: const Icon(Icons.visibility, color: Colors.teal), onPressed: () => context.go('/workouts/${w.id}')),
                                if (canManage) ...[
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => context.go('/workouts/${w.id}/edit')),
                                  if (w.isDeleted)
                                    IconButton(
                                      icon: const Icon(Icons.restore, color: Colors.green),
                                      tooltip: 'Восстановить из архива',
                                      onPressed: () => notifier.restore(w.id),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Color.fromARGB(255, 245, 51, 51)),
                                      tooltip: isAdmin ? 'Удалить (выбор мягкого/физического)' : 'В архив',
                                      onPressed: () => _confirmDeleteSingle(context, w, notifier),
                                    ),
                                ],
                              ],
                            ),
                },
              ),
              _buildPagination(notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(WorkoutListNotifier notifier) {
    final res = notifier.result;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Всего: ${res.totalItems} | Стр. ${res.page} из ${res.totalPages}'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: res.hasPrevious
                    ? () {
                        final next = notifier.query.copyWith(page: res.page - 1);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: res.hasNext
                    ? () {
                        final next = notifier.query.copyWith(page: res.page + 1);
                        notifier.applyQuery(next);
                        _syncUrl(next);
                      }
                    : null,
              ),
            ],
          )
        ],
      ),
    );
  }
}