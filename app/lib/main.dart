import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:microlaudo/core/theme/app_theme.dart';
import 'package:microlaudo/core/router/app_router.dart';

const _supabaseUrl = 'https://jynkunhfbvkttpvkvoxi.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5bmt1bmhmYnZrdHRwdmt2b3hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MTM3MDEsImV4cCI6MjA4OTk4OTcwMX0.HPr8nSRJzNJ2zwFf9C8uCMjL5jk0EtwDonZxh86sqnQ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MicroLaudoApp()));
}

class MicroLaudoApp extends ConsumerWidget {
  const MicroLaudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MicroLaudo',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}
