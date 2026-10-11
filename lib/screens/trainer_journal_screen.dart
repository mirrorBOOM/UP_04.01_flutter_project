import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/async_state_view.dart';

class TrainerJournalScreen extends StatefulWidget {
  const TrainerJournalScreen({super.key});

  @override
  State<TrainerJournalScreen> createState() => _TrainerJournalScreenState();
}

class _TrainerJournalScreenState extends State<TrainerJournalScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final repo = context.watch<PocketBaseRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал тренера: Отметка посещений'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.sports)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Инструктор: ${auth.user?.fullName ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                            const Text('Электронный журнал посещаемости групп'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Записавшиеся клиенты на занятия:', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              FutureBuilder<List<Booking>>(
                future: repo.getBookings(),
                builder: (context, snapshot) {
                  return AsyncStateView<List<Booking>>(
                    snapshot: snapshot,
                    onRetry: () => setState(() {}),
                    isEmpty: (list) => list.isEmpty,
                    emptyMessage: 'В ваших группах пока нет активных записей клиентов',
                    builder: (list) {
                      return Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final b = list[i];
                            return ListTile(
                              title: Text(b.clientName ?? 'Клиент', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Программа: ${b.workoutTitle ?? ""} • Статус: ${b.status}'),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      await repo.updateBookingStatus(b.id, 'ATTENDED');
                                      setState(() {});
                                    },
                                    child: const Text('Был'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await repo.updateBookingStatus(b.id, 'MISSED');
                                      setState(() {});
                                    },
                                    child: const Text('Пропуск'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}