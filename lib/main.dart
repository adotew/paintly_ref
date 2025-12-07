import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/board_overview_screen.dart';
import 'state/board_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We wait here for Hive initialization
    final initStatus = ref.watch(initializationProvider);

    return MaterialApp(
      title: 'PaintlyRef',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        brightness: Brightness.dark, // Moodboard apps often look better dark
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: initStatus.when(
        data: (_) => const BoardOverviewScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('Error starting app: $err'))),
      ),
    );
  }
}
