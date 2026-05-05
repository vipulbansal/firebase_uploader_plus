import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_uploader_plus/firebase_uploader_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? bootstrapError;
  try {
    await _initializeFirebase();
  } catch (e) {
    bootstrapError = e.toString();
  }

  runApp(MyApp(bootstrapError: bootstrapError));
}

Future<void> _initializeFirebase() async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    await Firebase.initializeApp();
    return;
  }

  const appId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  const apiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  final hasDartDefines =
      appId.isNotEmpty &&
      projectId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      apiKey.isNotEmpty;

  if (hasDartDefines) {
    final options = FirebaseOptions(
      appId: appId,
      projectId: projectId,
      messagingSenderId: messagingSenderId,
      apiKey: apiKey,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
    );
    await Firebase.initializeApp(options: options);
    return;
  }

  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.bootstrapError});

  final String? bootstrapError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Uploader Plus Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: bootstrapError == null
          ? const AuthWrapper()
          : FirebaseSetupScreen(error: bootstrapError!),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase setup required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'The example app could not initialize Firebase.\n',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SelectableText(
              'Do one of these:\n\n'
              '1) Add android/app/google-services.json for this example app\n'
              '2) Run with --dart-define values:\n'
              '   --dart-define=FIREBASE_ANDROID_APP_ID=...\n'
              '   --dart-define=FIREBASE_PROJECT_ID=...\n'
              '   --dart-define=FIREBASE_MESSAGING_SENDER_ID=...\n'
              '   --dart-define=FIREBASE_ANDROID_API_KEY=...\n'
              '   --dart-define=FIREBASE_STORAGE_BUCKET=... (optional)\n\n'
              'Then restart the app.',
            ),
            const SizedBox(height: 12),
            Text(
              'Startup error:\n$error',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Uploader Plus Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Firebase Uploader Plus',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'All-in-One Firebase File & Metadata Uploader',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _signInAnonymously(context),
                  child: const Text('Sign In Anonymously'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showEmailSignIn(context),
                child: const Text('Sign In with Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign in: $e')));
    }
  }

  void _showEmailSignIn(BuildContext context) {
    // Simple email/password implementation
    showDialog(
      context: context,
      builder: (context) => const EmailSignInDialog(),
    );
  }
}

class EmailSignInDialog extends StatefulWidget {
  const EmailSignInDialog({Key? key}) : super(key: key);

  @override
  State<EmailSignInDialog> createState() => _EmailSignInDialogState();
}

class _EmailSignInDialogState extends State<EmailSignInDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
              });
            },
            child: Text(
              _isSignUp
                  ? 'Already have account? Sign In'
                  : 'Need account? Sign Up',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAuth,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        ),
      ],
    );
  }

  Future<void> _handleAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Uploader Plus'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Sign Out (${user?.email ?? 'Anonymous'})'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Files', icon: Icon(Icons.folder)),
            Tab(text: 'Images', icon: Icon(Icons.image)),
            Tab(text: 'Documents', icon: Icon(Icons.description)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Files Tab
          FirebaseUploader(
            firestorePath: 'user_uploads',
            firebaseStoragePath: 'uploads/users',
            enablePreview: true,
            enableCamera: true,
            enableMultipleFiles: true,
            maxFileSize: 10 * 1024 * 1024, // 10MB
            onUploadComplete: (metadata) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Uploaded: ${metadata.fileName}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onUploadError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            customMetadata: {
              'app_version': '1.0.0',
              'platform': 'flutter_demo',
            },
          ),

          // Images Only Tab
          FirebaseUploader(
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
            firestorePath: 'image_uploads',
            firebaseStoragePath: 'uploads/images',
            enablePreview: true,
            enableCamera: true,
            enableMultipleFiles: true,
            maxFileSize: 5 * 1024 * 1024, // 5MB
            onUploadComplete: (metadata) {
              print('Image uploaded: ${metadata.downloadUrl}');
            },
            headerBuilder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Image Gallery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Custom image picker logic
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Custom camera logic
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Documents Only Tab
          FirebaseUploader(
            allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
            firestorePath: 'document_uploads',
            firebaseStoragePath: 'uploads/documents',
            enablePreview: false,
            enableCamera: false,
            enableMultipleFiles: true,
            maxFileSize: 25 * 1024 * 1024, // 25MB
            onUploadComplete: (metadata) {
              print('Document uploaded: ${metadata.fileName}');
            },
            fileTileBuilder: (context, upload) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.description, color: Colors.blue[700]),
                ),
                title: Text(upload.fileName),
                subtitle: Text(
                  '${upload.formattedFileSize} • ${upload.fileType.toUpperCase()}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        // Handle download
                        print('Download: ${upload.downloadUrl}');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // Handle share
                        print('Share: ${upload.fileName}');
                      },
                    ),
                  ],
                ),
              ),
            ),
            emptyStateBuilder: (context) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No documents uploaded', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Upload PDFs, Word docs, and text files',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
