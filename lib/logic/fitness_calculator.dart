import '../models/membership_card.dart';
import '../models/workout.dart';

class FitnessCalculator {
  static double calculateMembershipPrice({
    required int basePrice,
    required int personalWorkoutsCount,
    required int trainerHourlyRate,
    required int durationMonths,
  }) {
    final rawTotal = basePrice + (personalWorkoutsCount * trainerHourlyRate);
    
    final discount = switch (durationMonths) {
      >= 12 => 0.15,
      >= 6 => 0.10,
      >= 3 => 0.05,
      _ => 0.0,
    };

    return rawTotal * (1.0 - discount);
  }

  static String? validateBooking({
    required Workout workout,
    required MembershipCard? card,
    required int existingBookingsCount,
  }) {
    if (card == null || !card.isActive) {
      return 'У вас нет активной клубной карты для записи на тренировку';
    }
    if (card.balanceVisits <= 0) {
      return 'На клубной карте исчерпан баланс доступных посещений';
    }
    if (existingBookingsCount >= workout.capacityTotal) {
      return 'В группе исчерпан лимит свободных мест (${workout.capacityTotal} мест занято)';
    }
    return null; 
  }
}