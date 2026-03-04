import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

// Bandera global para verificar si Firebase está inicializado
bool _isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Habilitar descarga de fuentes desde Google Fonts en tiempo de ejecución
  GoogleFonts.config.allowRuntimeFetching = true;
  
  // NOTE: You must provide a google-services.json for Android
  // or use 'flutterfire configure' to initialize Firebase correctly.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
  } catch (e) {
    print("Firebase initialization error: $e");
    _isFirebaseInitialized = false;
  }
  runApp(const SecurePOSApp());
}

class SecurePOSApp extends StatelessWidget {
  const SecurePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudRecord',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Si Firebase no está inicializado, Ir directo a HomeScreen
    if (!_isFirebaseInitialized) {
      return const HomeScreen();
    }

    return StreamBuilder(
      stream: AuthService().user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
