import 'package:flutter_test/flutter_test.dart';
import 'package:up_0401_project/logic/fitness_calculator.dart';
import 'package:up_0401_project/models/membership_card.dart';
import 'package:up_0401_project/models/workout.dart';
import 'package:up_0401_project/state/auth_notifier.dart';
import 'package:up_0401_project/utils/validators.dart';

void main() {
  group('1. Модульные тесты валидаторов (AppValidators):', () {
    test('1.1. Обязательное поле отклоняет пустую строку', () {
      expect(AppValidators.requiredField(''), isNotNull);
      expect(AppValidators.requiredField('   '), isNotNull);
      expect(AppValidators.requiredField(null), isNotNull);
    });

    test('1.2. Обязательное поле принимает валидный ввод', () {
      expect(AppValidators.requiredField('CrossFit WOD'), isNull);
    });

    test('1.3. Проверка минимальной длины строки', () {
      expect(AppValidators.minLength('a', 3), isNotNull);
      expect(AppValidators.minLength('Fit', 3), isNull);
    });

    test('1.4. Проверка положительного числа', () {
      expect(AppValidators.positiveInt('0'), isNotNull);
      expect(AppValidators.positiveInt('-10'), isNotNull);
      expect(AppValidators.positiveInt('60'), isNull);
    });

    test('1.5. Проверка формата почты (Email)', () {
      expect(AppValidators.email('wrong-email'), isNotNull);
      expect(AppValidators.email('admin@fitness.ru'), isNull);
    });

    test('1.6. Проверка номера телефона', () {
      expect(AppValidators.phone('123'), isNotNull);
      expect(AppValidators.phone('+7 (999) 111-22-33'), isNull);
    });
  });

  group('2. Тесты моделей и бизнес-логики (п. 20 ТЗ):', () {
    test('2.1. Расчёт цены абонемента со скидкой 10% на 6 месяцев', () {
      final price = FitnessCalculator.calculateMembershipPrice(
        basePrice: 3000,
        personalWorkoutsCount: 4,
        trainerHourlyRate: 1500,
        durationMonths: 6,
      );
      expect(price, closeTo(8100, 0.01));
    });

    test('2.2. Блокировка бронирования при неактивной клубной карте', () {
      const card = MembershipCard(
        id: 'c1',
        cardNumber: 'C-1',
        clientId: 'cl1',
        validUntil: '2026-01-01',
        status: 'FROZEN',
        balanceVisits: 5,
      );
      const workout = Workout(
        id: 'w1', title: 'Бокс', code: 'BOX-1', durationMinutes: 60, caloriesBurned: 500,
        intensity: 3, hallId: 'h1', trainerId: 't1', categoryIds: [], capacityTotal: 10, capacityAvailable: 5,
      );

      final error = FitnessCalculator.validateBooking(workout: workout, card: card, existingBookingsCount: 2);
      expect(error, contains('нет активной клубной карты'));
    });

    test('2.3. Иерархия уровней ролей пользователей', () {
      expect(Role.client.level < Role.trainer.level, isTrue);
      expect(Role.trainer.level < Role.admin.level, isTrue);
      expect(Role.admin.level >= Role.client.level, isTrue);
    });
  });
}