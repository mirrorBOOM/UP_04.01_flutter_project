class AppValidators {
  static String? requiredField(String? value, [String message = 'Обязательное поле']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.trim().length < min) {
      return 'Минимум $min символов';
    }
    return null;
  }

  static String? positiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите число';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Число должно быть больше 0';
    return null;
  }

  static String? textLength(String? value, {int min = 2, int max = 50, String? fieldName}) {
    if (value == null || value.trim().isEmpty) return 'Поле обязательно к заполнению';
    final len = value.trim().length;
    final name = fieldName ?? 'Текст';
    if (len < min) return '$name: минимум $min символов';
    if (len > max) return '$name: максимум $max символов';
    return null;
  }

  static String? rangeInt(String? value, {required int min, required int max, required String fieldName}) {
    if (value == null || value.trim().isEmpty) return 'Введите значение';
    final num = int.tryParse(value.trim());
    if (num == null) return 'Введите корректное число';
    if (num < min || num > max) return '$fieldName должно быть от $min до $max';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите адрес электронной почты';
    final trimmed = value.trim();
    if (trimmed.length > 50) return 'Email не может быть длиннее 50 символов';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(trimmed)) return 'Некорректный формат почты (пример: user@fit.ru)';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите номер телефона';
    final trimmed = value.trim();
    if (trimmed.length < 10) return 'Номер слишком короткий (минимум 10 знаков)';
    if (trimmed.length > 18) return 'Номер не может быть длиннее 18 символов';
    final regex = RegExp(r'^\+?[0-9\s\-\(\)]{10,18}$');
    if (!regex.hasMatch(trimmed)) return 'Некорректный номер (пример: +7 (999) 123-45-67)';
    return null;
  }

  static String? dateIso(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите дату';
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(value.trim())) return 'Формат даты: ГГГГ-ММ-ДД (пример: 2026-12-31)';
    return null;
  }

  static String? code(String? value, {String label = 'Артикул'}) {
    if (value == null || value.trim().isEmpty) return 'Введите $label';
    final trimmed = value.trim();
    if (trimmed.length < 3) return '$label: минимум 3 символа';
    if (trimmed.length > 20) return '$label: максимум 20 символов';
    return null;
  }
}