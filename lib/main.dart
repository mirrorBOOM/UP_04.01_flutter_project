import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'repositories/pocketbase_repository.dart';
import 'state/auth_notifier.dart';
import 'state/workout_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final authNotifier = AuthNotifier(prefs);
  await authNotifier.restore();

  final dio = buildDio(tokenProvider: () => authNotifier.accessToken);
  final pbRepository = PocketBaseRepository(dio);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<PocketBaseRepository>.value(value: pbRepository),
        ChangeNotifierProvider<WorkoutListNotifier>(
          create: (_) => WorkoutListNotifier(pbRepository)..load(),
        ),
      ],
      child: FitnessClubApp(authNotifier: authNotifier),
    ),
  );
}

class FitnessClubApp extends StatelessWidget {
  final AuthNotifier authNotifier;
  const FitnessClubApp({super.key, required this.authNotifier});

  @override
  Widget build(BuildContext context) {
    return InactivityWatcher(
      timeout: const Duration(minutes: 3),
      warningBefore: const Duration(seconds: 30),
      onTimeout: () => authNotifier.logout(),
      child: MaterialApp.router(
        title: 'Фитнес-клуб (PocketBase)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        routerConfig: buildAppRouter(authNotifier),
      ),
    );
  }
}