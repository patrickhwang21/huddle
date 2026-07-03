import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/availability_grid_screen.dart';
import 'screens/create_event_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/edit_event_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/guest_login_screen.dart';
import 'screens/join_event_screen.dart';
import 'screens/launch_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/results_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HuddleApp());
}

class HuddleApp extends StatelessWidget {
  const HuddleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huddle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
      routes: {
        '/': (context) => const LaunchScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/join-event': (context) => const JoinEventScreen(),
        '/guest-login': (context) => const GuestLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/create-event': (context) => const CreateEventScreen(),
        '/edit-event': (context) => const EditEventScreen(),
        '/availability': (context) => const AvailabilityGridScreen(),
        '/results': (context) => const ResultsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}

/// Routes to the dashboard if a registered user is already signed in
/// (e.g. app relaunch), otherwise starts at the launch screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data != null ? const DashboardScreen() : const LaunchScreen();
      },
    );
  }
}
