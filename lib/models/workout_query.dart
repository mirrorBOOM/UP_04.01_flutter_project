class WorkoutQuery {
  final String search;
  final String? trainerId;
  final String? hallId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int perPage;
  final bool includeDeleted;

  const WorkoutQuery({
    this.search = '',
    this.trainerId,
    this.hallId,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.perPage = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  WorkoutQuery copyWith({
    String? search,
    Object? trainerId = _unset,
    Object? hallId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? perPage,
    bool? includeDeleted,
  }) {
    return WorkoutQuery(
      search: search ?? this.search,
      trainerId: trainerId == _unset ? this.trainerId : trainerId as String?,
      hallId: hallId == _unset ? this.hallId : hallId as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      perPage: perPage ?? this.perPage,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }
}