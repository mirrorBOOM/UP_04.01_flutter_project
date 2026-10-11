import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../repositories/pocketbase_repository.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PocketBaseRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика и аудит клуба (Admin)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpiCard('Выручка за месяц', '540 000 ₽', Icons.monetization_on, Colors.purple),
                  _kpiCard('Загрузка клуба', '82%', Icons.pie_chart, Colors.orange),
                  _kpiCard('Активных карт', '128', Icons.credit_card, Colors.green),
                  _kpiCard('Снарядов в залах', '46 шт.', Icons.fitness_center, Colors.blue),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Состояние инвентаря по залам (Коллекция 8)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: repo.getEquipment(),
                        builder: (ctx, snap) {
                          if (!snap.hasData) return const CircularProgressIndicator();
                          final eq = snap.data!;
                          if (eq.isEmpty) return const Text('Инвентарь пока не добавлен в базу PocketBase');
                          return Column(
                            children: eq.map((e) => ListTile(
                              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Зал: ${e.hallName ?? "Основной"} • Количество: ${e.quantity} шт.'),
                              trailing: Chip(label: Text(e.condition)),
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String val, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}