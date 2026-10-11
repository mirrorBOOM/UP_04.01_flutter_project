import 'package:flutter/material.dart';

class AsyncStateView<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final bool Function(T data)? isEmpty;
  final VoidCallback? onRetry;
  final Widget Function(T data) builder;
  final String emptyMessage;

  const AsyncStateView({
    super.key,
    required this.snapshot,
    required this.builder,
    this.isEmpty,
    this.onRetry,
    this.emptyMessage = 'Данные отсутствуют',
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Ошибка загрузки данных: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 15),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Повторить'),
                ),
            ],
          ),
        ),
      );
    }

    final data = snapshot.data;
    final isDataEmpty = data == null || (isEmpty != null && isEmpty!(data));

    if (isDataEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return builder(data);
  }
}