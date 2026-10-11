import 'package:go_router/go_router.dart';
import 'models/workout_query.dart';
import 'state/auth_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/workout_list_screen.dart';
import 'screens/workout_details_screen.dart';
import 'screens/workout_form_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/trainer_journal_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/gym_halls_screen.dart';
import 'screens/equipment_screen.dart';
import 'screens/trainers_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/membership_cards_screen.dart';
import 'screens/bookings_screen.dart';

GoRouter buildAppRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      
      GoRoute(
        path: '/',
        builder: (c, s) {
          final q = s.uri.queryParameters;
          final sortRaw = q['sort'] ?? 'title,asc';
          final sortParts = sortRaw.split(',');

          return WorkoutListScreen(
            initialQuery: WorkoutQuery(
              search: q['search'] ?? '',
              trainerId: q['trainerId'],
              hallId: q['hallId'],
              sortField: sortParts[0],
              sortAscending: sortParts.length > 1 ? sortParts[1] == 'asc' : true,
              page: int.tryParse(q['page'] ?? '') ?? 1,
              perPage: int.tryParse(q['perPage'] ?? '') ?? 10,
              includeDeleted: q['includeDeleted'] == 'true',
            ),
          );
        },
      ),
      GoRoute(
        path: '/workouts/new',
        redirect: (_, __) => auth.hasRole(Role.trainer) ? null : '/forbidden',
        builder: (c, s) => const WorkoutFormScreen(),
      ),
      GoRoute(
        path: '/workouts/:id/edit',
        redirect: (_, __) => auth.hasRole(Role.trainer) ? null : '/forbidden',
        builder: (c, s) => WorkoutFormScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/workouts/:id',
        builder: (c, s) => WorkoutDetailsScreen(workoutId: s.pathParameters['id'] ?? ''),
      ),

      GoRoute(path: '/halls', builder: (c, s) => const GymHallsScreen()),
      GoRoute(path: '/equipment', builder: (c, s) => const EquipmentScreen()),
      GoRoute(path: '/categories', builder: (c, s) => const CategoriesScreen()),
      GoRoute(path: '/trainers', builder: (c, s) => const TrainersScreen()),
      GoRoute(path: '/clients', builder: (c, s) => const ClientsScreen()),
      GoRoute(path: '/cards', builder: (c, s) => const MembershipCardsScreen()),
      GoRoute(path: '/bookings', builder: (c, s) => const BookingsScreen()),

      GoRoute(
        path: '/my-bookings',
        redirect: (_, __) => auth.user?.role == Role.client ? null : '/forbidden',
        builder: (c, s) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/trainer/journal',
        redirect: (_, __) => auth.user?.role == Role.trainer ? null : '/forbidden',
        builder: (c, s) => const TrainerJournalScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        redirect: (_, __) => auth.user?.role == Role.admin ? null : '/forbidden',
        builder: (c, s) => const AdminAnalyticsScreen(),
      ),
    ],
  );
}