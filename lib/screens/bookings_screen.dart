import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../models/client.dart';
import '../models/workout.dart';
import '../models/workout_query.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  void _showBookingDialog(List<Client> clients, List<Workout> workouts, [Booking? booking]) {
    if (clients.isEmpty || workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала создайте клиентов и тренировки!')));
      return;
    }

    final isEditing = booking != null;
    String clientId = booking?.clientId ?? clients.first.id;
    String workoutId = booking?.workoutId ?? workouts.first.id;
    String status = booking?.status ?? 'CONFIRMED';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isEditing ? 'Редактировать запись' : 'Новая запись на тренировку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: clientId,
                decoration: const InputDecoration(labelText: 'Клиент'),
                items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullName))).toList(),
                onChanged: (val) => setDlgState(() => clientId = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: workoutId,
                decoration: const InputDecoration(labelText: 'Тренировка'),
                items: workouts.map((w) => DropdownMenuItem(value: w.id, child: Text(w.title))).toList(),
                onChanged: (val) => setDlgState(() => workoutId = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Статус бронирования'),
                items: const [
                  DropdownMenuItem(value: 'CONFIRMED', child: Text('CONFIRMED (Записан)')),
                  DropdownMenuItem(value: 'ATTENDED', child: Text('ATTENDED (Посетил)')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED (Отменено)')),
                ],
                onChanged: (val) => setDlgState(() => status = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                final repo = context.read<PocketBaseRepository>();
                await repo.saveBooking(Booking(
                  id: isEditing ? booking.id : '',
                  clientId: clientId,
                  workoutId: workoutId,
                  bookingDate: DateTime.now().toString().substring(0, 16),
                  status: status,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(isEditing ? 'Сохранить' : 'Создать запись'),
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
    final canManage = auth.hasRole(Role.trainer);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал записей'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final clients = await repo.getClients();
                final res = await repo.findWorkouts(const WorkoutQuery(perPage: 50));
                if (context.mounted) _showBookingDialog(clients, res.items);
              },
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Создать бронь'),
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

                return FutureBuilder(
                  future: repo.findWorkouts(const WorkoutQuery(perPage: 50)),
                  builder: (ctx, workoutSnap) {
                    final workouts = workoutSnap.data?.items ?? [];

                    return FutureBuilder<List<Booking>>(
                      future: repo.getBookings(),
                      builder: (ctx, snap) {
                        return AsyncStateView<List<Booking>>(
                          snapshot: snap,
                          onRetry: () => setState(() {}),
                          isEmpty: (list) => list.isEmpty,
                          emptyMessage: 'Записи на тренировки пока не созданы',
                          builder: (bookings) {
                            return isMobile
                                ? ListView.builder(
                                    itemCount: bookings.length,
                                    itemBuilder: (ctx, i) {
                                      final b = bookings[i];
                                      return Card(
                                        child: ListTile(
                                          leading: const Icon(Icons.event_available, color: Colors.green),
                                          title: Text(b.clientName ?? 'Клиент', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('Программа: ${b.workoutTitle ?? ""} • ${b.bookingDate}'),
                                          trailing: canManage
                                              ? Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showBookingDialog(clients, workouts, b)),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () async {
                                                        await repo.deleteBooking(b.id);
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ],
                                                )
                                              : Chip(label: Text(b.status)),
                                        ),
                                      );
                                    },
                                  )
                                : EntityTable<Booking>(
                                    items: bookings,
                                    idOf: (b) => b.id,
                                    columns: [
                                      TableColumnSpec(label: 'Клиент', build: (b) => Text(b.clientName ?? 'Клиент', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      TableColumnSpec(label: 'Тренировка', build: (b) => Text(b.workoutTitle ?? 'Тренировка')),
                                      TableColumnSpec(label: 'Дата слота', build: (b) => Text(b.bookingDate)),
                                      TableColumnSpec(label: 'Статус', build: (b) => Chip(label: Text(b.status))),
                                    ],
                                    actions: canManage
                                        ? (b) => [
                                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showBookingDialog(clients, workouts, b)),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () async {
                                                  await repo.deleteBooking(b.id);
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}