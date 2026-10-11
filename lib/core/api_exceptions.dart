import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Не удалось соединиться с PocketBase. Убедитесь, что сервер запущен (./pocketbase serve).',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется авторизация.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Недостаточно прав для выполнения действия.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись в базе данных не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Ошибка на стороне PocketBase.']);
}

ApiException mapHttpError(int status, dynamic body) {
  String? message;
  Map<String, String> fieldErrors = {};

  if (body is Map) {
    message = body['message'] as String?;
    if (body['data'] is Map) {
      final dataMap = body['data'] as Map;
      for (final entry in dataMap.entries) {
        if (entry.value is Map && entry.value['message'] != null) {
          fieldErrors[entry.key.toString()] = entry.value['message'].toString();
        } else {
          fieldErrors[entry.key.toString()] = entry.value.toString();
        }
      }
    }
  }

  return switch (status) {
    400 || 422 => ValidationException(message ?? 'Ошибка валидации полей', fieldErrors),
    401 => UnauthorizedException(message ?? 'Требуется авторизация.'),
    403 => ForbiddenException(message ?? 'Доступ запрещён правилами PocketBase (API rules).'),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Конфликт целостности данных.'),
    _ => ServerException(message ?? 'Ошибка сервера (код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Таймаут соединения с PocketBase.'),
    DioExceptionType.connectionError => const NetworkException(),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}