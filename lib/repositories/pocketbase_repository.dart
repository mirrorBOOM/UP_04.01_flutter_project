import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/booking.dart';
import '../models/client.dart';
import '../models/equipment_inventory.dart';
import '../models/gym_hall.dart';
import '../models/membership_card.dart';
import '../models/page_result.dart';
import '../models/trainer.dart';
import '../models/workout.dart';
import '../models/workout_category.dart'; 
import '../models/workout_query.dart';

class PocketBaseRepository {
  final Dio _dio;
  CancelToken? _searchCancelToken;

  PocketBaseRepository(this._dio);


  Future<PageResult<Workout>> findWorkouts(WorkoutQuery q) => guard(() async {
    _searchCancelToken?.cancel();
    _searchCancelToken = CancelToken();

    final filters = <String>[];
    if (!q.includeDeleted) {
      filters.add('is_deleted = false');
    }
    if (q.search.trim().isNotEmpty) {
      final s = q.search.trim().replaceAll("'", "\\'");
      filters.add("(title ~ '$s' || code ~ '$s')");
    }
    if (q.trainerId != null && q.trainerId!.isNotEmpty) {
      filters.add("trainer = '${q.trainerId}'");
    }
    if (q.hallId != null && q.hallId!.isNotEmpty) {
      filters.add("hall = '${q.hallId}'");
    }

    final sortPrefix = q.sortAscending ? '+' : '-';
    final sortKey = switch (q.sortField) {
      'duration' => 'duration_minutes',
      'calories' => 'calories_burned',
      'intensity' => 'intensity',
      _ => 'title',
    };

    final queryParams = <String, dynamic>{
      'page': q.page,
      'perPage': q.perPage,
      'sort': '$sortPrefix$sortKey',
      'expand': 'hall,trainer,categories',
      if (filters.isNotEmpty) 'filter': filters.join(' && '),
    };

    final response = await _dio.get(
      '/collections/workouts/records',
      queryParameters: queryParams,
      cancelToken: _searchCancelToken,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Workout.fromJson)
        .toList();

    return PageResult(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? 1,
      perPage: (data['perPage'] as num?)?.toInt() ?? q.perPage,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
    );
  });

  Future<Workout?> findWorkoutById(String id) => guard(() async {
    final response = await _dio.get(
      '/collections/workouts/records/$id',
      queryParameters: {'expand': 'hall,trainer,categories'},
    );
    return Workout.fromJson(response.data as Map<String, dynamic>);
  });

  Future<void> saveWorkout(Workout item) => guard(() async {
    if (item.id.isEmpty) {
      await _dio.post('/collections/workouts/records', data: item.toJson());
    } else {
      await _dio.patch('/collections/workouts/records/${item.id}', data: item.toJson());
    }
  });

  Future<void> softDeleteWorkout(String id) => guard(() async {
    await _dio.patch('/collections/workouts/records/$id', data: {'is_deleted': true});
  });

  Future<void> hardDeleteWorkout(String id) => guard(() async {
    await _dio.delete('/collections/workouts/records/$id');
  });

  Future<void> restoreWorkout(String id) => guard(() async {
    await _dio.patch('/collections/workouts/records/$id', data: {'is_deleted': false});
  });

  
  Future<List<GymHall>> getHalls() => guard(() async {
    final res = await _dio.get('/collections/gym_halls/records', queryParameters: {'perPage': 50});
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(GymHall.fromJson).toList();
  });

  Future<void> saveHall(GymHall hall) => guard(() async {
    if (hall.id.isEmpty) {
      await _dio.post('/collections/gym_halls/records', data: hall.toJson());
    } else {
      await _dio.patch('/collections/gym_halls/records/${hall.id}', data: hall.toJson());
    }
  });

  Future<void> deleteHall(String id) => guard(() async {
    final check = await _dio.get(
      '/collections/workouts/records',
      queryParameters: {'filter': "hall = '$id' && is_deleted = false", 'perPage': 1},
    );
    final count = (check.data['totalItems'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      throw ConflictException('Невозможно удалить зал: к нему привязано $count активных тренировок.');
    }
    await _dio.delete('/collections/gym_halls/records/$id');
  });

  Future<List<WorkoutCategory>> getCategories() => guard(() async {
    final res = await _dio.get('/collections/workout_categories/records', queryParameters: {'perPage': 50});
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(WorkoutCategory.fromJson).toList();
  });

  Future<void> saveCategory(WorkoutCategory cat) => guard(() async {
    if (cat.id.isEmpty) {
      await _dio.post('/collections/workout_categories/records', data: cat.toJson());
    } else {
      await _dio.patch('/collections/workout_categories/records/${cat.id}', data: cat.toJson());
    }
  });

  Future<void> deleteCategory(String id) => guard(() async {
    await _dio.delete('/collections/workout_categories/records/$id');
  });

  Future<List<Trainer>> getTrainers() => guard(() async {
    final res = await _dio.get('/collections/trainers/records', queryParameters: {'perPage': 50});
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(Trainer.fromJson).toList();
  });

  Future<void> saveTrainer(Trainer trainer) => guard(() async {
    if (trainer.id.isEmpty) {
      await _dio.post('/collections/trainers/records', data: trainer.toJson());
    } else {
      await _dio.patch('/collections/trainers/records/${trainer.id}', data: trainer.toJson());
    }
  });

  Future<void> deleteTrainer(String id) => guard(() async {
    await _dio.delete('/collections/trainers/records/$id');
  });


  Future<List<Client>> getClients() => guard(() async {
    final res = await _dio.get('/collections/clients/records', queryParameters: {'perPage': 50});
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(Client.fromJson).toList();
  });

  Future<void> saveClient(Client client) => guard(() async {
    if (client.id.isEmpty) {
      await _dio.post('/collections/clients/records', data: client.toJson());
    } else {
      await _dio.patch('/collections/clients/records/${client.id}', data: client.toJson());
    }
  });

  Future<void> deleteClient(String id) => guard(() async {
    await _dio.delete('/collections/clients/records/$id');
  });

  Future<List<MembershipCard>> getMembershipCards() => guard(() async {
    final res = await _dio.get(
      '/collections/membership_cards/records',
      queryParameters: {'perPage': 50, 'expand': 'client'},
    );
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(MembershipCard.fromJson).toList();
  });

  Future<void> saveMembershipCard(MembershipCard card) => guard(() async {
    if (card.id.isEmpty) {
      await _dio.post('/collections/membership_cards/records', data: card.toJson());
    } else {
      await _dio.patch('/collections/membership_cards/records/${card.id}', data: card.toJson());
    }
  });


  Future<List<EquipmentInventory>> getEquipment() => guard(() async {
    final res = await _dio.get(
      '/collections/equipment_inventory/records',
      queryParameters: {'perPage': 50, 'expand': 'hall'},
    );
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(EquipmentInventory.fromJson).toList();
  });

  Future<List<Booking>> getBookings({String? clientId, String? workoutId}) => guard(() async {
    final filters = <String>[];
    if (clientId != null) filters.add("client = '$clientId'");
    if (workoutId != null) filters.add("workout = '$workoutId'");

    final res = await _dio.get(
      '/collections/bookings/records',
      queryParameters: {
        'perPage': 50,
        'expand': 'client,workout',
        if (filters.isNotEmpty) 'filter': filters.join(' && '),
      },
    );
    final items = (res.data['items'] as List).whereType<Map<String, dynamic>>();
    return items.map(Booking.fromJson).toList();
  });

  Future<void> createBooking(Booking booking) => guard(() async {
    await _dio.post('/collections/bookings/records', data: booking.toJson());
  });

  Future<void> updateBookingStatus(String bookingId, String newStatus) => guard(() async {
    await _dio.patch('/collections/bookings/records/$bookingId', data: {'status': newStatus});
  });

  Future<void> cancelBooking(String bookingId) => guard(() async {
    await _dio.delete('/collections/bookings/records/$bookingId');
  });
  Future<void> saveEquipment(EquipmentInventory eq) => guard(() async {
    if (eq.id.isEmpty) {
      await _dio.post('/collections/equipment_inventory/records', data: eq.toJson());
    } else {
      await _dio.patch('/collections/equipment_inventory/records/${eq.id}', data: eq.toJson());
    }
  });

  Future<void> deleteEquipment(String id) => guard(() async {
    await _dio.delete('/collections/equipment_inventory/records/$id');
  });

  Future<void> deleteMembershipCard(String id) => guard(() async {
    await _dio.delete('/collections/membership_cards/records/$id');
  });
  Future<void> saveBooking(Booking b) => guard(() async {
    if (b.id.isEmpty) {
      await _dio.post('/collections/bookings/records', data: b.toJson());
    } else {
      await _dio.patch('/collections/bookings/records/${b.id}', data: b.toJson());
    }
  });

  Future<void> deleteBooking(String id) => guard(() async {
    await _dio.delete('/collections/bookings/records/$id');
  });
  Future<PageResult<Trainer>> findTrainers({
    String search = '',
    String? category,
    int? minExperience,
    String sortField = 'full_name',
    bool sortAscending = true,
    int page = 1,
    int perPage = 10,
  }) => guard(() async {
    final filters = <String>[];
    if (search.trim().isNotEmpty) {
      final s = search.trim().replaceAll("'", "\\'");
      filters.add("(full_name ~ '$s' || specialization ~ '$s')");
    }
    if (category != null && category.isNotEmpty) {
      filters.add("category = '$category'");
    }
    if (minExperience != null && minExperience > 0) {
      filters.add("experience_years >= $minExperience");
    }

    final sortPrefix = sortAscending ? '+' : '-';
    final res = await _dio.get(
      '/collections/trainers/records',
      queryParameters: {
        'page': page,
        'perPage': perPage,
        'sort': '$sortPrefix$sortField',
        if (filters.isNotEmpty) 'filter': filters.join(' && '),
      },
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Trainer.fromJson)
        .toList();

    return PageResult(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? 1,
      perPage: (data['perPage'] as num?)?.toInt() ?? perPage,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
    );
  });
}