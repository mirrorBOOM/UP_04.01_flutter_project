import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/page_result.dart';
import '../models/workout.dart';
import '../models/workout_query.dart';
import '../repositories/pocketbase_repository.dart';

enum LoadStatus { idle, loading, success, error }

class WorkoutListNotifier extends ChangeNotifier {
  final PocketBaseRepository _repository;

  WorkoutListNotifier(this._repository);

  WorkoutQuery _query = const WorkoutQuery();
  PageResult<Workout> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};
  Timer? _debounceTimer;

  WorkoutQuery get query => _query;
  PageResult<Workout> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.findWorkouts(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Ошибка загрузки данных из PocketBase: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(WorkoutQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void setSearchDebounced(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      applyQuery(_query.copyWith(search: text, page: 1));
    });
  }

  void toggleSelection(String id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  Future<void> softDelete(String id) async {
    await _repository.softDeleteWorkout(id);
    await load();
  }

  Future<void> restore(String id) async {
    await _repository.restoreWorkout(id);
    await load();
  }

  Future<void> hardDelete(String id) async {
    await _repository.hardDeleteWorkout(id);
    await load();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}