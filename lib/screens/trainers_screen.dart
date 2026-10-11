import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/page_result.dart';
import '../models/trainer.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/auth_notifier.dart';
import '../utils/validators.dart';
import '../widgets/async_state_view.dart';
import '../widgets/entity_table.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String _search = '';
  String? _category;
  int? _minExp;
  String _sortField = 'full_name';
  bool _sortAscending = true;
  int _page = 1;

  void _showTrainerDialog([Trainer? trainer]) {
    final isEditing = trainer != null;
    final nameCtrl = TextEditingController(text: trainer?.fullName ?? '');
    final specCtrl = TextEditingController(text: trainer?.specialization ?? '');
    final expCtrl = TextEditingController(text: trainer?.experienceYears.toString() ?? '3');
    final rateCtrl = TextEditingController(text: trainer?.hourlyRate.toString() ?? '1500');
    String category = trainer?.category ?? 'PRO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isEditing ? 'Редактировать тренера' : 'Новый тренер'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'ФИО тренера * (макс. 50)', border: OutlineInputBorder()),
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      validator: (v) => AppValidators.textLength(v, min: 3, max: 50, fieldName: 'ФИО'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: specCtrl,
                      decoration: const InputDecoration(labelText: 'Специализация * (макс. 50)', border: OutlineInputBorder()),
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      validator: (v) => AppValidators.textLength(v, min: 2, max: 50, fieldName: 'Специализация'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expCtrl,
                      decoration: const InputDecoration(labelText: 'Опыт работы (0-50 лет) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => AppValidators.rangeInt(v, min: 0, max: 50, fieldName: 'Опыт работы'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rateCtrl,
                      decoration: const InputDecoration(labelText: 'Ставка в час (500-30000 ₽) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(5), FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => AppValidators.rangeInt(v, min: 500, max: 30000, fieldName: 'Ставка в час'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Квалификация', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'PRO', child: Text('PRO Инструктор')),
                        DropdownMenuItem(value: 'MASTER', child: Text('MASTER Тренер')),
                        DropdownMenuItem(value: 'VIP', child: Text('VIP Эксперт')),
                      ],
                      onChanged: (val) => setDlgState(() => category = val ?? 'PRO'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final repo = context.read<PocketBaseRepository>();
                await repo.saveTrainer(Trainer(
                  id: isEditing ? trainer.id : '',
                  fullName: nameCtrl.text.trim(),
                  specialization: specCtrl.text.trim(),
                  experienceYears: int.tryParse(expCtrl.text) ?? 0,
                  category: category,
                  hourlyRate: int.tryParse(rateCtrl.text) ?? 1500,
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
        title: const Text('Тренерский состав'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showTrainerDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить тренера'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
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
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Поиск тренера...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (text) => setState(() {
                          _search = text;
                          _page = 1;
                        }),
                      ),
                    ),
                    DropdownButton<String?>(
                      value: _category,
                      hint: const Text('Все категории'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все категории')),
                        DropdownMenuItem(value: 'PRO', child: Text('PRO Инструкторы')),
                        DropdownMenuItem(value: 'MASTER', child: Text('MASTER Тренеры')),
                        DropdownMenuItem(value: 'VIP', child: Text('VIP Эксперты')),
                      ],
                      onChanged: (val) => setState(() {
                        _category = val;
                        _page = 1;
                      }),
                    ),
                    DropdownButton<int?>(
                      value: _minExp,
                      hint: const Text('Любой стаж'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Любой стаж')),
                        DropdownMenuItem(value: 3, child: Text('От 3 лет опыта')),
                        DropdownMenuItem(value: 5, child: Text('От 5 лет опыта')),
                        DropdownMenuItem(value: 10, child: Text('От 10 лет опыта')),
                      ],
                      onChanged: (val) => setState(() {
                        _minExp = val;
                        _page = 1;
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<PageResult<Trainer>>(
                  future: repo.findTrainers(
                    search: _search,
                    category: _category,
                    minExperience: _minExp,
                    sortField: _sortField,
                    sortAscending: _sortAscending,
                    page: _page,
                    perPage: 10,
                  ),
                  builder: (ctx, snap) {
                    return AsyncStateView<PageResult<Trainer>>(
                      snapshot: snap,
                      onRetry: () => setState(() {}),
                      isEmpty: (res) => res.items.isEmpty,
                      emptyMessage: 'Тренеры по заданным критериям не найдены',
                      builder: (res) {
                        final list = res.items;

                        return isMobile
                            ? ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: list.length,
                                itemBuilder: (ctx, i) {
                                  final t = list[i];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.deepOrange.shade50,
                                        child: Text(t.fullName.isNotEmpty ? t.fullName[0] : 'T'),
                                      ),
                                      title: Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${t.specialization} • ${t.experienceYears} лет • ${t.hourlyRate} ₽/ч'),
                                      trailing: canManage
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showTrainerDialog(t)),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    await repo.deleteTrainer(t.id);
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            )
                                          : Chip(label: Text(t.category)),
                                    ),
                                  );
                                },
                              )
                            : EntityTable<Trainer>(
                                items: list,
                                idOf: (t) => t.id,
                                sortField: _sortField,
                                sortAscending: _sortAscending,
                                onSort: (field) => setState(() {
                                  if (_sortField == field) {
                                    _sortAscending = !_sortAscending;
                                  } else {
                                    _sortField = field;
                                    _sortAscending = true;
                                  }
                                }),
                                columns: [
                                  TableColumnSpec(label: 'ФИО', sortField: 'full_name', build: (t) => Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  TableColumnSpec(label: 'Специализация', build: (t) => Text(t.specialization)),
                                  TableColumnSpec(label: 'Категория', build: (t) => Chip(label: Text(t.category))),
                                  TableColumnSpec(label: 'Стаж', sortField: 'experience_years', numeric: true, build: (t) => Text('${t.experienceYears} лет')),
                                  TableColumnSpec(label: 'Ставка/час', sortField: 'hourly_rate', numeric: true, build: (t) => Text('${t.hourlyRate} ₽')),
                                ],
                                actions: canManage
                                    ? (t) => [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            tooltip: 'Редактировать',
                                            onPressed: () => _showTrainerDialog(t),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            tooltip: 'Удалить',
                                            onPressed: () async {
                                              await repo.deleteTrainer(t.id);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Страница: $_page'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _page > 1 ? () => setState(() => _page--) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setState(() => _page++),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}