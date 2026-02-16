import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screen/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = SupabaseConfig.supabaseUrl.trim();
  final supabaseAnonKey = SupabaseConfig.supabaseAnonKey.trim();

  if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
    throw Exception(
      'Invalid SUPABASE_URL. Set it to your project URL (https://<id>.supabase.co).',
    );
  }

  if (supabaseAnonKey.isEmpty) {
    throw Exception('Invalid SUPABASE_ANON_KEY. Set your anon key.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bancon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00529B),
          primary: const Color(0xFF00529B),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/img.png',
              width: 250,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.business,
                  size: 100,
                  color: Color(0xFF00529B),
                );
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00529B)),
            ),
          ],
        ),
      ),
    );
  }
}
