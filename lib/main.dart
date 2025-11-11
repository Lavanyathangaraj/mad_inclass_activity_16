import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pastelLilac = Color(0xFFB39EB5);
    const Color darkText = Color(0xFF4A6572);
    const Color pastelBackground = Color(0xFFF7F7F7);

    return MaterialApp(
      title: 'ICA 16 Firebase Auth',
      theme: ThemeData(
        primarySwatch: Colors.indigo, 
        primaryColor: pastelLilac, 
        inputDecorationTheme: InputDecorationTheme( 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide.none,
          ),
          filled: true, 
          fillColor: Colors.white, 
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            minimumSize: const Size(double.infinity, 50), 
            backgroundColor: pastelLilac, 
            foregroundColor: Colors.white,
          ),
        ),
        // Removed problematic cardTheme definition for compatibility
        scaffoldBackgroundColor: pastelBackground, 
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: pastelBackground, 
          foregroundColor: darkText, 
          titleTextStyle: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold
          )
        )
      ),
      home: const AuthGate(),
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> changePassword({required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user is currently signed in.");
    }
    await user.updatePassword(newPassword);
  }
}

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

        if (snapshot.hasData) {
          return const ProfileScreen();
        }

        return const AuthenticationScreen();
      },
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Welcome Back!' : 'Create New Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card( 
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: isLogin ? SignInForm() : RegistrationForm(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? 'No account yet? Register Here'
                      : 'Already have an account? Sign In',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  RegistrationForm({super.key});
  final AuthService _authService = AuthService();

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email (e.g., test@gsu.com).';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget._authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Logging you in...')),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Registration Failed.';
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else {
           message = 'Registration failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Register Account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password (min 6 chars)', prefixIcon: Icon(Icons.lock)),
            obscureText: true,
            validator: _validatePassword,
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitRegistration,
                  child: const Text('Register', style: TextStyle(fontSize: 18)),
                ),
        ],
      ),
    );
  }
}

class SignInForm extends StatefulWidget {
  SignInForm({super.key});
  final AuthService _authService = AuthService();

  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    return null;
  }

  void _submitSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget._authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign In Successful!')),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Sign In Failed.';
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message = 'Invalid credentials. Please check your email and password.';
        } else {
          message = 'Sign in failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
            obscureText: true,
            validator: _validatePassword,
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitSignIn,
                  child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final user = FirebaseAuth.instance.currentUser;
  
  static const Color pastelLilac = Color(0xFFB39EB5);
  static const Color veryLightLilac = Color(0xFFEBE0EC);
  static const Color pastelPink = Color(0xFFFFB6C1);
  static const Color darkText = Color(0xFF4A6572);

  void _logout() async {
    try {
      await _authService.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPasswordController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password (min 6 chars)',
                prefixIcon: Icon(Icons.lock_open),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pastelLilac,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
              ),
              child: const Text('Submit'),
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _changePassword(newPasswordController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(String newPassword) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attempting to change password...')),
    );
    try {
      await _authService.changePassword(newPassword: newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Password change failed.';
      if (e.code == 'requires-recent-login') {
        message = 'Password change failed. Please sign out and sign back in to re-authenticate.';
      } else {
        message = 'Password change failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
            color: darkText,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(
                    Icons.person_pin,
                    size: 100,
                    color: pastelLilac,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Welcome!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: veryLightLilac,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: pastelLilac),
                    ),
                    child: Text(
                      'Email: ${user?.email ?? 'N/A'}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Change Password'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pastelPink,
                      foregroundColor: darkText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}