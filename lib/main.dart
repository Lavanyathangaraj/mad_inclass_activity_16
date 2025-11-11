import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// NOTE: cloud_firestore is imported but not strictly necessary for Auth only,
// keeping it here as it was in the original snippet.
import 'package:cloud_firestore/cloud_firestore.dart';
// This assumes 'firebase_options.dart' was generated using the FlutterFire CLI.
import 'firebase_options.dart'; 

// --- Step 2: Initialize Firebase (Completed) ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Basic error handling for Firebase initialization
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        // Global styling for inputs for better aesthetic
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
      // --- Step 3: AuthGate is the new starting point ---
      home: const AuthGate(),
    );
  }
}

// --- Step 3: Implement the Authentication State Listener ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to real-time authentication changes.
    return StreamBuilder<User?>(
      // The stream provided by Firebase Auth that emits an event 
      // whenever the user's sign-in state changes (sign in, sign out, etc.).
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a simple loading indicator while waiting for the connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if the snapshot has user data (meaning the user is logged in).
        if (snapshot.hasData) {
          // If logged in, navigate to the main content screen.
          return const HomeScreen();
        } else {
          // If not logged in (user is null), show the authentication screen.
          return const AuthenticationScreen(title: 'Firebase Auth Demo');
        }
      },
    );
  }
}

// --- Authenticated State Screen ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Sign Out function
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Inform the user upon successful sign out
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully signed out.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error signing out: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              onPressed: () => _signOut(context),
            ),
          ),
        ],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.check_circle, color: Colors.indigo, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'You are successfully signed in.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'User Email: ${user?.email ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'User ID: ${user?.uid ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Unauthenticated State Screen (Forms) ---
class AuthenticationScreen extends StatelessWidget {
  final String title;
  const AuthenticationScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Registration Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RegisterEmailSection(auth: auth),
                  ),
                ),
                const Divider(height: 32),
                // Sign-In Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: EmailPasswordForm(auth: auth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Register Component ---
class RegisterEmailSection extends StatefulWidget {
  final FirebaseAuth auth;
  const RegisterEmailSection({super.key, required this.auth});

  @override
  State<RegisterEmailSection> createState() => _RegisterEmailSectionState();
}

class _RegisterEmailSectionState extends State<RegisterEmailSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = 'Create a new account';
  Color _messageColor = Colors.grey;
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _message = 'Registering...';
      _messageColor = Colors.blue;
    });

    try {
      await widget.auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // The AuthGate will handle navigation to HomeScreen on success
      setState(() {
        _message = 'Success! Redirecting...';
        _messageColor = Colors.green;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = 'Registration Failed: ${e.message ?? 'Unknown error'}';
        _messageColor = Colors.red;
      });
    } catch (e) {
       setState(() {
        _message = 'An unexpected error occurred.';
        _messageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('New User Registration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Address'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (min 6 characters)'),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Register', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _message,
              style: TextStyle(color: _messageColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sign In Component ---
class EmailPasswordForm extends StatefulWidget {
  final FirebaseAuth auth;
  const EmailPasswordForm({super.key, required this.auth});

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = 'Sign in with existing credentials';
  Color _messageColor = Colors.grey;
  bool _isLoading = false;

  void _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _message = 'Signing in...';
      _messageColor = Colors.blue;
    });

    try {
      await widget.auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // The AuthGate will handle navigation to HomeScreen on success
      setState(() {
        _message = 'Success! Redirecting...';
        _messageColor = Colors.green;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = 'Sign In Failed: ${e.message ?? 'Invalid credentials'}';
        _messageColor = Colors.red;
      });
    } catch (e) {
       setState(() {
        _message = 'An unexpected error occurred.';
        _messageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Existing User Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Address'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _signInWithEmailAndPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign In', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _message,
              style: TextStyle(color: _messageColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}