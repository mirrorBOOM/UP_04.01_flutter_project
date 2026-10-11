import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/gym_hall.dart';
import '../models/trainer.dart';
import '../models/workout.dart';
import '../models/workout_category.dart';
import '../repositories/pocketbase_repository.dart';
import '../state/workout_list_notifier.dart';
import '../utils/validators.dart';

class WorkoutFormScreen extends StatefulWidget {
  final String? id;
  const WorkoutFormScreen({super.key, this.id});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _durationController;
  late final TextEditingController _caloriesController;

  String? _selectedHallId;
  String? _selectedTrainerId;
  List<String> _selectedCategoryIds = [];

  List<GymHall> _halls = [];
  List<Trainer> _trainers = [];
  List<WorkoutCategory> _categories = [];
  bool _loading = true;

  bool get isEditing => widget.id != null && widget.id!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _codeController = TextEditingController();
    _durationController = TextEditingController(text: '60');
    _caloriesController = TextEditingController(text: '500');
    _loadFormData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    final repo = context.read<PocketBaseRepository>();
    final halls = await repo.getHalls();
    final trainers = await repo.getTrainers();
    final categories = await repo.getCategories();

    if (isEditing) {
      final item = await repo.findWorkoutById(widget.id!);
      if (item != null) {
        _titleController.text = item.title;
        _codeController.text = item.code;
        _durationController.text = item.durationMinutes.toString();
        _caloriesController.text = item.caloriesBurned.toString();
        _selectedHallId = item.hallId;
        _selectedTrainerId = item.trainerId;
        _selectedCategoryIds = List.from(item.categoryIds);
      }
    } else {
      if (halls.isNotEmpty) _selectedHallId = halls.first.id;
      if (trainers.isNotEmpty) _selectedTrainerId = trainers.first.id;
    }

    if (mounted) {
      setState(() {
        _halls = halls;
        _trainers = trainers;
        _categories = categories;
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<PocketBaseRepository>();
    final notifier = context.read<WorkoutListNotifier>();

    final workout = Workout(
      id: isEditing ? widget.id! : '',
      title: _titleController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      durationMinutes: int.parse(_durationController.text.trim()),
      caloriesBurned: int.parse(_caloriesController.text.trim()),
      intensity: 3,
      hallId: _selectedHallId ?? '',
      trainerId: _selectedTrainerId ?? '',
      categoryIds: _selectedCategoryIds,
      capacityTotal: 15,
      capacityAvailable: 15,
    );

    try {
      await repo.saveWorkout(workout);
      await notifier.load();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать тренировку' : 'Новая тренировка'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Название программы * (макс. 50)', border: OutlineInputBorder()),
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    validator: (v) => AppValidators.textLength(v, min: 3, max: 50, fieldName: 'Название'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'Артикул / Код * (3-20 симв.)', border: OutlineInputBorder()),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]')),
                    ],
                    validator: (v) => AppValidators.code(v, label: 'Артикул'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(labelText: 'Длительность (10-180 мин) *', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(3), FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => AppValidators.rangeInt(v, min: 10, max: 180, fieldName: 'Длительность'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _caloriesController,
                          decoration: const InputDecoration(labelText: 'Калории (50-2500 ккал) *', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => AppValidators.rangeInt(v, min: 50, max: 2500, fieldName: 'Калории'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('hall_$_selectedHallId'),
                    initialValue: _selectedHallId,
                    decoration: const InputDecoration(labelText: 'Зал проведения *', border: OutlineInputBorder()),
                    items: _halls.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))).toList(),
                    onChanged: (val) => setState(() => _selectedHallId = val),
                    validator: (v) => v == null ? 'Выберите зал' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('trainer_$_selectedTrainerId'),
                    initialValue: _selectedTrainerId,
                    decoration: const InputDecoration(labelText: 'Ведущий инструктор *', border: OutlineInputBorder()),
                    items: _trainers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))).toList(),
                    onChanged: (val) => setState(() => _selectedTrainerId = val),
                    validator: (v) => v == null ? 'Выберите тренера' : null,
                  ),
                  const SizedBox(height: 16),
                  FormField<List<String>>(
                    initialValue: _selectedCategoryIds,
                    validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы одну категорию' : null,
                    builder: (field) => InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Категории фитнеса *',
                        border: const OutlineInputBorder(),
                        errorText: field.errorText,
                      ),
                      child: Wrap(
                        spacing: 8,
                        children: _categories.map((c) {
                          final isSelected = _selectedCategoryIds.contains(c.id);
                          return FilterChip(
                            label: Text(c.name),
                            selected: isSelected,
                            onSelected: (sel) {
                              setState(() {
                                sel ? _selectedCategoryIds.add(c.id) : _selectedCategoryIds.remove(c.id);
                                field.didChange(_selectedCategoryIds);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _submit, child: Text(isEditing ? 'Сохранить изменения' : 'Создать')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}