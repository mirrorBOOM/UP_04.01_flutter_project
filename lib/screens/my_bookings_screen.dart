import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../logic/fitness_calculator.dart';
import '../models/booking.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _personalWorkouts = 4;
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final repo = context.watch<PocketBaseRepository>();

    final calculatedPrice = FitnessCalculator.calculateMembershipPrice(
      basePrice: 3000,
      personalWorkoutsCount: _personalWorkouts,
      trainerHourlyRate: 1500,
      durationMonths: _months,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кабинет клиента и бронирования'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.deepOrange, Colors.amber]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('FITNESS CLUB MEMBER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(auth.user?.fullName ?? 'Клиент', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('КАРТА: #CARD-7790 • СТАТУС: АКТИВЕН', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Text('Калькулятор продления абонемента', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Срок абонемента: $_months мес. (скидка ${(_months >= 12 ? 15 : _months >= 6 ? 10 : 5)}%)'),
                      Slider(
                        value: _months.toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '$_months мес.',
                        onChanged: (v) => setState(() => _months = v.toInt()),
                      ),
                      Text('Персональных тренировок с тренером: $_personalWorkouts'),
                      Slider(
                        value: _personalWorkouts.toDouble(),
                        min: 0,
                        max: 20,
                        divisions: 20,
                        label: '$_personalWorkouts шт.',
                        onChanged: (v) => setState(() => _personalWorkouts = v.toInt()),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итоговая стоимость со скидкой:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${calculatedPrice.toInt()} ₽', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Мои активные записи на тренировки', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              FutureBuilder<List<Booking>>(
                future: repo.getBookings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('У вас пока нет активных бронирований. Запишитесь из каталога!'),
                      ),
                    );
                  }
                  return Column(
                    children: bookings.map((b) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.event_available, color: Colors.green),
                        title: Text(b.workoutTitle ?? 'Тренировка'),
                        subtitle: Text('Дата: ${b.bookingDate} • Статус: ${b.status}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            await repo.cancelBooking(b.id);
                            setState(() {});
                          },
                        ),
                      ),
                    )).toList(),
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