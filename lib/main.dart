import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo', 
      // use an AuthWrapper to decide which screen to show.
      home: AuthWrapper(),
    );
  }
}

// widget handles the navigation logic.
// listens to auth state changes and shows the correct screen.
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // while checking auth state, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // if a user is logged in, show the ProfileScreen 
        if (snapshot.hasData) {
          return ProfileScreen();
        }

        // if no user is logged in, show the AuthenticationScreen
        return AuthenticationScreen(title: 'Firebase Auth Demo');
      },
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  AuthenticationScreen({Key? key, required this.title}) : super(key: key); // 
  final String title;

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}


class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // 
        // The 'Sign Out' button  is removed from this screen.
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              RegisterEmailSection(auth: _auth), // [cite: 65]
              SizedBox(height: 20),
              EmailPasswordForm(auth: _auth), // [cite: 65]
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Get the current user from FirebaseAuth
  final User? user = FirebaseAuth.instance.currentUser;
  String _message = '';

  // Logout Functionality [cite: 53]
  void _signOut() async {
    await FirebaseAuth.instance.signOut(); // [cite: 54]
    // The AuthWrapper will automatically detect the sign-out
    // and navigate back to the AuthenticationScreen.
  }

  // Change Password Functionality 
  // This function sends a password reset email.
  void _sendPasswordReset() async {
    setState(() {
      _message = ''; // Clear previous message
    });
    try {
      if (user != null && user!.email != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        setState(() {
          _message = 'Password reset email sent. Check your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error sending password reset email.';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: <Widget>[
          // Logout Button 
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            // Display User 
            Text(
              'Email: ${user?.email ?? 'Email not found'}', 
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 32),
            // Change Password Functionality 
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text('Click the button below to send a password reset link to your email.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sendPasswordReset,
              child: Text('Send Password Reset Email'),
            ),
            SizedBox(height: 12),
            Text(
              _message,
              style: TextStyle(
                color: _message.startsWith('Error') ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    ); // Scaffold 
  }
}

class RegisterEmailSection extends StatefulWidget {
  RegisterEmailSection({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;

  @override
  _RegisterEmailSectionState createState() => _RegisterEmailSectionState();
}

// [cite: 68]
class _RegisterEmailSectionState extends State<RegisterEmailSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // [cite: 68]
  final TextEditingController _emailController = TextEditingController(); // [cite: 69]
  final TextEditingController _passwordController = TextEditingController(); // [cite: 69]
  bool _success = false; // [cite: 69]
  bool _initialState = true; // [cite: 69]
  String? _userEmail; // [cite: 69]

  void _register() async { // [cite: 70]
    try {
      await widget.auth.createUserWithEmailAndPassword( // [cite: 70]
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() { // [cite: 71]
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
      // Login is automatic upon successful registration,
      // so AuthWrapper will navigate to ProfileScreen.
    } catch (e) {
      setState(() { // [cite: 72]
        _success = false;
        _initialState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form( // [cite: 73]
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField( // [cite: 73]
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) { // [cite: 74]
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField( // [cite: 74]
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true, // Good practice to hide password
            validator: (value) {
              if (value?.isEmpty ?? true) { // [cite: 75]
                return 'Please enter some text';
              }
              if (value!.length < 6) { // [cite: 40]
                 return 'Password should be 6 characters or more';
              }
              return null;
            },
          ),
          Container( // [cite: 76]
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) { // [cite: 77]
                  _register();
                }
              },
              child: Text('Submit'), // [cite: 78]
            ),
          ),
          Container( // [cite: 78]
            alignment: Alignment.center,
            child: Text( // [cite: 79]
              _initialState
                  ? 'Please Register'
                  : _success
                      ? 'Successfully registered $_userEmail'
                      : 'Registration failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red), // [cite: 79]
            ),
          ),
        ],
      ),
    );
  }
}

class EmailPasswordForm extends StatefulWidget {
  EmailPasswordForm({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;

  @override
  _EmailPasswordFormState createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // [cite: 82]
  final TextEditingController _emailController = TextEditingController(); // [cite: 83]
  final TextEditingController _passwordController = TextEditingController(); // [cite: 83]
  bool _success = false; // [cite: 83]
  bool _initialState = true; // [cite: 83]
  String _userEmail = ''; // [cite: 84]

  void _signInWithEmailAndPassword() async { // [cite: 84]
    try {
      await widget.auth.signInWithEmailAndPassword( // [cite: 84]
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() { // [cite: 85]
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
      // Successful sign-in will be detected by AuthWrapper,
      // which will navigate to ProfileScreen.
    } catch (e) {
      setState(() { // [cite: 86]
        _success = false;
        _initialState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Text('Test sign in with email and password'),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
          ),
          TextFormField( 
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true, // Good practice to hide password
            validator: (value) { 
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Container( 
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center, 
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _signInWithEmailAndPassword();
                }
              },
              child: Text('Submit'),
            ),
          ),
          Container( 
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text( 
              _initialState
                  ? 'Please sign in'
                  : _success
                      ? 'Successfully signed in $_userEmail'
                      : 'Sign in failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red), // [cite: 94]
            ),
          ),
        ],
      ),
    );
  }
}