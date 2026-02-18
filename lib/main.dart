import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screen/login_screen.dart';
import 'screen/admin_screen.dart';
import 'screen/supervisor_screen.dart';
import 'screen/encoder_screen.dart';
import 'screen/agent_screen.dart';

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
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in, get their role and navigate
      try {
        final profile = await Supabase.instance.client
            .from('users_db')
            .select('role, status')
            .eq('user_id', session.user.id)
            .single();

        if (!mounted) return;

        if (profile['status'] != 1) {
          await Supabase.instance.client.auth.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          return;
        }

        Widget destinationScreen;
        final String role = profile['role']?.toString().toLowerCase() ?? '';

        switch (role) {
          case 'admin':
            destinationScreen = const AdminScreen();
            break;
          case 'supervisor':
            destinationScreen = const SupervisorScreen();
            break;
          case 'encoder':
            destinationScreen = const EncoderScreen();
            break;
          case 'agent':
            destinationScreen = const AgentScreen();
            break;
          default:
            await Supabase.instance.client.auth.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
            return;
        }

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => destinationScreen));
      } catch (e) {
        // If offline and can't fetch profile, still try to navigate based on cached data
        // For now, just go to login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } else {
      // No session, go to login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
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
