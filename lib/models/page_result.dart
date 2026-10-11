class PageResult<T> {
  final List<T> items;
  final int page;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const PageResult({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  PageResult.empty()
      : items = <T>[],
        page = 1,
        perPage = 10,
        totalItems = 0,
        totalPages = 1;
}