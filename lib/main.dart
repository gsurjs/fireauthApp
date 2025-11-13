import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


// Background message handler
Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}'); 
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
debugShowCheckedModeBanner: false,
      title: 'Firebase Auth & Messaging', // Updated title
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
              RegisterEmailSection(auth: _auth),
              SizedBox(height: 20),
              EmailPasswordForm(auth: _auth),
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
  final User? user = FirebaseAuth.instance.currentUser;
  String _message = '';
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() {
    messaging = FirebaseMessaging.instance;
    messaging.subscribeToTopic("messaging");
    messaging.getToken().then((value) {
      print("--- YOUR FCM TOKEN ---");
      print(value);
      print("----------------------");
    });

    // This handles notifications when the app is IN THE FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message recieved");
      print(event.notification!.body);
      
      // CALL NEW CUSTOM FUNCTION
      _showNotificationDialog(event);
    });

    // This handles when a user CLICKS a notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
      // CALL NEW CUSTOM FUNCTION
      _showNotificationDialog(message);
    });
  }

  // Custom dialog function to handle different types 
  void _showNotificationDialog(RemoteMessage message) {
    // Check the custom data payload for the 'type' 
    String type = message.data['type'] ?? 'regular'; // Default to 'regular'

    // Customize appearance based on type 
    Color titleColor = (type == 'important') ? Colors.red : Colors.blue;
    IconData titleIcon = (type == 'important') ? Icons.warning : Icons.info;
    String title = (type == 'important') ? "Important Notification" : "New Notification"; 

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(titleIcon, color: titleColor),
              SizedBox(width: 10),
              Text(title, style: TextStyle(color: titleColor)),
            ],
          ),
          content: Text(message.notification?.body ?? "No body"),
          actions: [
            TextButton(
              child: Text("Ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }
  // Logout Functionality 
  void _signOut() async {
    await messaging.unsubscribeFromTopic("messaging");
    await FirebaseAuth.instance.signOut(); 
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
        title: Text('Profile & Messaging'),
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
            // status section for FCM
            SizedBox(height: 32),
            Text(
              'Cloud Messaging',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text('You are subscribed to the "messaging" topic.'),
            Text('You will receive "regular" and "important" quotes.'), 


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


class _RegisterEmailSectionState extends State<RegisterEmailSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 
  bool _success = false; 
  bool _initialState = true; 
  String? _userEmail; 

  void _register() async {
    try {
      await widget.auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
      // Login is automatic upon successful registration,
      // so AuthWrapper will navigate to ProfileScreen.
    } catch (e) {
      setState(() { 
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
            obscureText: true, // hide password
            validator: (value) {
              if (value?.isEmpty ?? true) { 
                return 'Please enter some text';
              }
              if (value!.length < 6) { 
                 return 'Password should be 6 characters or more';
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
                  _register();
                }
              },
              child: Text('Submit'), 
            ),
          ),
          Container( 
            alignment: Alignment.center,
            child: Text(
              _initialState
                  ? 'Please Register'
                  : _success
                      ? 'Successfully registered $_userEmail'
                      : 'Registration failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red), 
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success = false; 
  bool _initialState = true; 
  String _userEmail = '';

  void _signInWithEmailAndPassword() async {
    try {
      await widget.auth.signInWithEmailAndPassword( 
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
      // Successful sign-in will be detected by AuthWrapper,
      // which will navigate to ProfileScreen.
    } catch (e) {
      setState(() { 
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
            obscureText: true, //hide password
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
              style: TextStyle(color: _success ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}