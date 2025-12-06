import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/board_overview_screen.dart';
import 'state/board_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wir warten hier auf die Initialisierung von Hive
    final initStatus = ref.watch(initializationProvider);

    return MaterialApp(
      title: 'PaintlyRef',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        brightness:
            Brightness.dark, // Moodboard-Apps sehen dunkel oft besser aus
      ),
      home: initStatus.when(
        data: (_) => const BoardOverviewScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('Fehler beim Starten: $err'))),
      ),
    );
  }
}
