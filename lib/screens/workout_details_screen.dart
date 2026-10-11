import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../logic/fitness_calculator.dart';
import '../models/booking.dart';
import '../models/client.dart';
import '../models/membership_card.dart';
import '../models/workout.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailsScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool _isBooking = false;

  void _bookWorkout(BuildContext context, Workout workout) async {
    setState(() => _isBooking = true);
    final auth = context.read<AuthNotifier>();
    final repo = context.read<PocketBaseRepository>();

    try {
      final existingBookings = await repo.getBookings(workoutId: workout.id);
      const mockCard = MembershipCard(
        id: 'mock_card',
        cardNumber: 'CARD-7790',
        clientId: 'c1',
        validUntil: '2026-12-31',
        status: 'ACTIVE',
        balanceVisits: 10,
      );

      final error = FitnessCalculator.validateBooking(
        workout: workout,
        card: mockCard,
        existingBookingsCount: existingBookings.length,
      );

      if (error != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ $error'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      final clients = await repo.getClients();
      String realClientId;

      if (clients.isNotEmpty) {
        final currentUsername = auth.user?.username.toLowerCase() ?? '';
        final matched = clients.firstWhere(
          (c) => c.fullName.toLowerCase().contains(currentUsername) || c.email.toLowerCase().contains(currentUsername),
          orElse: () => clients.first,
        );
        realClientId = matched.id;
      } else {
        final newClient = Client(
          id: '',
          fullName: auth.user?.fullName ?? 'Клиент клуба',
          email: '${auth.user?.username ?? "user"}@fitness.local',
          phone: '+7 999 000-00-00',
        );
        await repo.saveClient(newClient);
        final updatedClients = await repo.getClients();
        realClientId = updatedClients.last.id;
      }

      await repo.createBooking(Booking(
        id: '',
        clientId: realClientId,
        workoutId: workout.id,
        bookingDate: DateTime.now().toUtc().toIso8601String(),
        status: 'CONFIRMED',
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы успешно записаны на тренировку!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка записи: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PocketBaseRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка тренировки'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: FutureBuilder<Workout?>(
        future: repo.findWorkoutById(widget.workoutId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('Тренировка не найдена'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text('Артикул: ${item.code}'),
                      Text('Длительность: ${item.durationMinutes} мин'),
                      Text('Сжигание калорий: ~${item.caloriesBurned} ккал'),
                      Text('Зал проведения : ${item.hallName ?? "Основной зал"}'),
                      Text('Ведущий инструктор : ${item.trainerName ?? "Дежурный тренер"}'),
                      Text('Свободно мест в группе: ${item.capacityAvailable} из ${item.capacityTotal}'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isBooking ? null : () => _bookWorkout(context, item),
                          icon: _isBooking
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.bookmark_add),
                          label: Text(_isBooking ? 'Запись...' : 'Записаться на занятие'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}