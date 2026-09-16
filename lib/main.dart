import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;

late List<CameraDescription> cameras;

const String cloudinaryCloudName = 'ni61iafo';
const String cloudinaryUploadPreset = 'pothigai_scans';
const Color pothigaiGreen = Color(0xFF2E7D32);

String twoDigits(int value) => value.toString().padLeft(2, '0');

String dateKey(DateTime date) {
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
}

String displayDate(DateTime date) {
  return '${twoDigits(date.day)}-${twoDigits(date.month)}-${date.year}';
}

DateTime timestampToDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return DateTime.now();
}

double asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0.0;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = <CameraDescription>[];
  runApp(const PothigaiGreenBootstrap());
}

class PothigaiGreenBootstrap extends StatefulWidget {
  const PothigaiGreenBootstrap({super.key});

  @override
  State<PothigaiGreenBootstrap> createState() =>
      _PothigaiGreenBootstrapState();
}

class _PothigaiGreenBootstrapState extends State<PothigaiGreenBootstrap> {
  bool _starting = true;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyBP_NwpV1PsKMld9ncWOAa69XUHJysO5Qo',
            appId: '1:406426275932:android:2d416b209c24cf29415699',
            messagingSenderId: '406426275932',
            projectId: 'pothigai-green',
            storageBucket: 'pothigai-green.firebasestorage.app',
          ),
        );
      }

      try {
        cameras = await availableCameras();
      } catch (_) {
        cameras = <CameraDescription>[];
      }

      if (!mounted) return;

      setState(() {
        _startupError = null;
        _starting = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Pothigai Green startup error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _startupError = e.toString();
        _starting = false;
      });
    }
  }

  Future<void> _retry() async {
    if (!mounted) return;

    setState(() {
      _startupError = null;
      _starting = true;
    });

    await _initializeServices();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pothigai Green',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: pothigaiGreen),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F8F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: pothigaiGreen,
          foregroundColor: Colors.white,
        ),
      ),
      home: _starting
          ? const PothigaiStartupPage()
          : _startupError != null
              ? FirebaseStartupErrorPage(
                  error: _startupError!,
                  onRetry: _retry,
                )
              : const AuthGate(),
    );
  }
}

class PothigaiStartupPage extends StatelessWidget {
  const PothigaiStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: pothigaiGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.recycling,
                size: 90,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Pothigai Green',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'பொதிகை பசுமை',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                ),
              ),
              SizedBox(height: 28),
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 14),
              Text(
                'Starting...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FirebaseStartupErrorPage extends StatelessWidget {
  const FirebaseStartupErrorPage({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pothigai Green')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 75,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Firebase startup problem',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pothigai Green itself is running, but Firebase could not initialize.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      error,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      onRetry();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('RETRY'),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _BusyScreen(message: 'Checking login...');
        }

        final user = authSnapshot.data;
        if (user == null) return const AuthPage();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _BusyScreen(message: 'Loading profile...');
            }

            if (profileSnapshot.hasError) {
              return MissingProfilePage(
                message: 'Unable to load your profile: ${profileSnapshot.error}',
              );
            }

            final profile = profileSnapshot.data?.data();
            if (profile == null) {
              return const _BusyScreen(message: 'Creating customer profile...');
            }

            final role = '${profile['role'] ?? 'customer'}'.toLowerCase();
            if (role == 'admin') {
              return AdminHome(profile: profile);
            }

            return CustomerShell(profile: profile);
          },
        );
      },
    );
  }
}

class _BusyScreen extends StatelessWidget {
  const _BusyScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class MissingProfilePage extends StatelessWidget {
  const MissingProfilePage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pothigai Green')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 70, color: Colors.orange),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('SIGN OUT'),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _registerMode = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _nextCustomerId() async {
    final counterRef = FirebaseFirestore.instance.collection('system').doc('customer_counter');

    return FirebaseFirestore.instance.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final current = (snapshot.data()?['nextCustomerNumber'] as num?)?.toInt() ?? 1;
      transaction.set(
        counterRef,
        {'nextCustomerNumber': current + 1},
        SetOptions(merge: true),
      );
      return 'PG${current.toString().padLeft(6, '0')}';
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_registerMode) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final customerId = await _nextCustomerId();
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'customerId': customerId,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': email,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? e.code;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.recycling, size: 62, color: pothigaiGreen),
                        const SizedBox(height: 8),
                        const Text(
                          'Pothigai Green',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'பொதிகை பசுமை',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: pothigaiGreen),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _registerMode ? 'Create Customer Account' : 'Customer / Admin Login',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 14),
                        if (_registerMode) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Enter customer name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.trim().length < 8
                                ? 'Enter a valid phone number'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(
                                _hidePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(_registerMode ? Icons.person_add : Icons.login),
                          label: Text(_registerMode ? 'REGISTER' : 'LOGIN'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _registerMode = !_registerMode;
                                    _error = null;
                                  });
                                },
                          child: Text(
                            _registerMode
                                ? 'Already registered? Login'
                                : 'New customer? Create account',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  bool _tamil = false;

  @override
  Widget build(BuildContext context) {
    final customerId = '${widget.profile['customerId'] ?? ''}';
    final customerName = '${widget.profile['name'] ?? 'Customer'}';

    final pages = <Widget>[
      CustomerHomePage(
        tamil: _tamil,
        customerId: customerId,
        customerName: customerName,
        onScan: () => setState(() => _index = 1),
        onPickup: () => setState(() => _index = 2),
      ),
      ScannerPage(tamil: _tamil, profile: widget.profile),
      PickupPage(tamil: _tamil, profile: widget.profile),
      CustomerHistoryPage(tamil: _tamil, profile: widget.profile),
      InfoPage(tamil: _tamil, profile: widget.profile),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tamil ? 'பொதிகை பசுமை' : 'Pothigai Green'),
            Text(
              '$customerId • $customerName',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _tamil = !_tamil),
            child: Text(
              _tamil ? 'EN' : 'தமிழ்',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: _tamil ? 'முகப்பு' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.center_focus_weak),
            selectedIcon: const Icon(Icons.center_focus_strong),
            label: _tamil ? 'ஸ்கேன்' : 'Scan',
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: _tamil ? 'பிக்கப்' : 'Pickup',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: _tamil ? 'வரலாறு' : 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: _tamil ? 'தகவல்' : 'Info',
          ),
        ],
      ),
    );
  }
}

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({
    super.key,
    required this.tamil,
    required this.customerId,
    required this.customerName,
    required this.onScan,
    required this.onPickup,
  });

  final bool tamil;
  final String customerId;
  final String customerName;
  final VoidCallback onScan;
  final VoidCallback onPickup;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tamil ? 'குப்பையிலும் காசு உண்டு' : 'Kuppaiyilum kaasu undu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$customerName • $customerId',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: pothigaiGreen,
                      ),
                      onPressed: onScan,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('SCAN WASTE'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: onPickup,
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('BOOK PICKUP'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          tamil ? 'இன்றைய விலை' : 'Current Rates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        const RateGrid(),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: pothigaiGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scans are saved under your Customer ID. Final payment is based on Admin-verified material, weight and rate.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RateGrid extends StatelessWidget {
  const RateGrid({super.key});

  static const rates = <List<String>>[
    ['PET Crushed', '₹14/kg'],
    ['PET Uncrushed', '₹12/kg'],
    ['HDPE', '₹18/kg'],
    ['LDPE', '₹10/kg'],
    ['PP', '₹12/kg'],
    ['Paper', '₹8/kg'],
    ['Cardboard', '₹6/kg'],
    ['E-Waste', 'Admin rate'],
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.25,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = rates[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item[0], style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                item[1],
                style: const TextStyle(
                  color: pothigaiGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScanDecision {
  const ScanDecision({required this.category, required this.confidence});

  final String category;
  final double confidence;
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    required this.tamil,
    required this.profile,
  });

  final bool tamil;
  final Map<String, dynamic> profile;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  final FlutterTts _tts = FlutterTts();
  late final ImageLabeler _imageLabeler;

  bool _ready = false;
  bool _scanning = false;
  bool _saving = false;
  bool _hasResult = false;
  bool _resultConfirmed = false;
  bool _needsResinConfirmation = false;
  bool _needsPetCondition = false;

  String _result = 'Point camera at a waste item';
  String _details = '';
  String _rateText = '';
  String _confidenceText = '';

  String? _detectedCategory;
  String? _confirmedMaterial;
  String? _resinCode;
  String? _petCondition;
  String? _lastCapturedPath;

  double _averageConfidence = 0;
  double _confirmedRate = 0;

  static const double minimumConfidence = 0.72;

  @override
  void initState() {
    super.initState();
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.55),
    );
    _initCamera();
    _initTts();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      if (mounted) setState(() => _result = 'No camera available');
      return;
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _result = 'Camera initialization failed');
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _scan() async {
    if (_controller == null || !_controller!.value.isInitialized || _scanning) return;

    setState(() {
      _scanning = true;
      _hasResult = false;
      _resultConfirmed = false;
      _needsResinConfirmation = false;
      _needsPetCondition = false;
      _confirmedMaterial = null;
      _resinCode = null;
      _petCondition = null;
      _confirmedRate = 0;
      _detectedCategory = null;
      _lastCapturedPath = null;
      _result = widget.tamil ? '3 படங்கள் ஆய்வு செய்யப்படுகிறது...' : 'Analyzing 3 frames...';
      _details = '';
      _rateText = '';
      _confidenceText = '';
    });

    try {
      final decisions = <ScanDecision>[];

      for (int i = 0; i < 3; i++) {
        final picture = await _controller!.takePicture();
        _lastCapturedPath = picture.path;
        final inputImage = InputImage.fromFilePath(picture.path);
        final labels = await _imageLabeler.processImage(inputImage);
        decisions.add(_classifyLabels(labels));

        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 350));
        }
      }

      _combineDecisions(decisions);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _result = 'SCAN FAILED';
        _details = '$e';
      });
    }
  }

  ScanDecision _classifyLabels(List<ImageLabel> sourceLabels) {
    if (sourceLabels.isEmpty) {
      return const ScanDecision(category: 'unknown', confidence: 0);
    }

    final labels = sourceLabels.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final topLabels = labels.take(10).toList();

    double findBest(List<String> words) {
      double best = 0;
      for (final label in topLabels) {
        final text = label.label.toLowerCase();
        for (final word in words) {
          if (text.contains(word) && label.confidence > best) {
            best = label.confidence;
          }
        }
      }
      return best;
    }

    final scores = <String, double>{
      'ewaste': findBest([
        'mobile phone',
        'cell phone',
        'smartphone',
        'laptop',
        'computer',
        'keyboard',
        'tablet',
        'television',
        'monitor',
        'electronic device',
      ]),
      'battery': findBest(['battery', 'battery charger']),
      'cardboard': findBest(['cardboard', 'carton', 'shipping box']),
      'paper': findBest(['paper', 'newspaper', 'document', 'magazine', 'book']),
      'bottle': findBest(['plastic bottle', 'water bottle', 'bottle']),
      'plastic': findBest(['plastic', 'plastic container', 'container']),
    };

    String bestCategory = 'unknown';
    double bestConfidence = 0;

    scores.forEach((category, confidence) {
      if (confidence > bestConfidence) {
        bestConfidence = confidence;
        bestCategory = category;
      }
    });

    if (bestConfidence < minimumConfidence) {
      return ScanDecision(category: 'unknown', confidence: bestConfidence);
    }

    return ScanDecision(category: bestCategory, confidence: bestConfidence);
  }

  void _combineDecisions(List<ScanDecision> decisions) {
    final counts = <String, int>{};
    final totals = <String, double>{};

    for (final decision in decisions) {
      counts[decision.category] = (counts[decision.category] ?? 0) + 1;
      totals[decision.category] = (totals[decision.category] ?? 0) + decision.confidence;
    }

    String winningCategory = 'unknown';
    int winningVotes = 0;

    counts.forEach((category, votes) {
      if (votes > winningVotes) {
        winningVotes = votes;
        winningCategory = category;
      }
    });

    final average = (totals[winningCategory] ?? 0) / (counts[winningCategory] ?? 1);
    _averageConfidence = average;

    if (winningCategory == 'unknown' ||
        winningVotes < 2 ||
        average < minimumConfidence) {
      _showUnknown(winningVotes, average);
      return;
    }

    _showDetectedResult(winningCategory, winningVotes, average);
  }

  void _showDetectedResult(String category, int votes, double confidence) {
    String result;
    String details;
    String rate = '';
    bool requiresResin = false;

    switch (category) {
      case 'bottle':
        result = 'BOTTLE DETECTED';
        details = 'Bottle detected. PET is not confirmed until the resin code is checked.';
        requiresResin = true;
        break;
      case 'plastic':
        result = 'PLASTIC ITEM DETECTED';
        details = 'Confirm PET / HDPE / LDPE / PP using the resin code.';
        requiresResin = true;
        break;
      case 'paper':
        result = 'PAPER DETECTED';
        details = 'AI identified this as paper. Confirm before saving.';
        rate = 'Paper: ₹8/kg';
        break;
      case 'cardboard':
        result = 'CARDBOARD DETECTED';
        details = 'AI identified this as cardboard. Confirm before saving.';
        rate = 'Cardboard: ₹6/kg';
        break;
      case 'ewaste':
        result = 'E-WASTE DETECTED';
        details = 'Electronic equipment detected. Admin will verify the final rate.';
        rate = 'E-Waste: Admin valuation';
        break;
      case 'battery':
        result = 'BATTERY DETECTED';
        details = 'Battery detected. Keep it separate for safe recycling.';
        rate = 'Battery: Admin valuation';
        break;
      default:
        _showUnknown(votes, confidence);
        return;
    }

    if (!mounted) return;
    setState(() {
      _scanning = false;
      _hasResult = true;
      _detectedCategory = category;
      _result = result;
      _details = details;
      _rateText = rate;
      _needsResinConfirmation = requiresResin;
      _confidenceText =
          '$votes/3 frames agreed • ${(confidence * 100).toStringAsFixed(0)}% average confidence';
    });
  }

  void _showUnknown(int votes, double confidence) {
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _hasResult = true;
      _resultConfirmed = false;
      _needsResinConfirmation = false;
      _needsPetCondition = false;
      _detectedCategory = 'unknown';
      _result = 'UNKNOWN / MATERIAL CHECK REQUIRED';
      _details = 'AI confidence is not high enough. Choose the correct material manually.';
      _rateText = 'No automatic rate';
      _confidenceText =
          '$votes/3 frames agreed • ${(confidence * 100).toStringAsFixed(0)}% confidence';
    });
  }

  double _suggestedRate(String material, {String? petCondition}) {
    switch (material) {
      case 'PET':
        return petCondition == 'Crushed' ? 14 : 12;
      case 'HDPE':
        return 18;
      case 'LDPE':
        return 10;
      case 'PP':
        return 12;
      case 'Paper':
        return 8;
      case 'Cardboard':
        return 6;
      default:
        return 0;
    }
  }

  void _confirmResin(String code, String material) {
    if (material == 'PET') {
      setState(() {
        _confirmedMaterial = 'PET';
        _resinCode = code;
        _resultConfirmed = false;
        _needsResinConfirmation = false;
        _needsPetCondition = true;
        _result = 'PET CONFIRMED';
        _details = 'Select whether the PET is crushed or uncrushed.';
        _rateText = '';
      });
      return;
    }

    final rate = _suggestedRate(material);
    setState(() {
      _confirmedMaterial = material;
      _resinCode = code;
      _resultConfirmed = true;
      _needsResinConfirmation = false;
      _needsPetCondition = false;
      _confirmedRate = rate;
      _result = '$material CONFIRMED';
      _details = 'Material confirmed using resin code $code.';
      _rateText = rate > 0 ? '$material: ₹${rate.toStringAsFixed(0)}/kg' : 'Admin valuation';
    });
  }

  void _confirmPetCondition(String condition) {
    final rate = _suggestedRate('PET', petCondition: condition);
    setState(() {
      _petCondition = condition;
      _resultConfirmed = true;
      _needsPetCondition = false;
      _confirmedRate = rate;
      _result = 'PET $condition CONFIRMED';
      _details = 'PET resin code 1 confirmed.';
      _rateText = 'PET $condition: ₹${rate.toStringAsFixed(0)}/kg';
    });
  }

  void _confirmDetectedResult() {
    String material;
    switch (_detectedCategory) {
      case 'paper':
        material = 'Paper';
        break;
      case 'cardboard':
        material = 'Cardboard';
        break;
      case 'ewaste':
        material = 'E-Waste';
        break;
      case 'battery':
        material = 'Battery';
        break;
      default:
        return;
    }

    final rate = _suggestedRate(material);
    setState(() {
      _confirmedMaterial = material;
      _confirmedRate = rate;
      _resultConfirmed = true;
      _result = '$material CONFIRMED';
      _details = 'Result confirmed by customer. Admin will cross-check the image.';
      _rateText = rate > 0 ? '$material: ₹${rate.toStringAsFixed(0)}/kg' : 'Admin valuation';
    });
  }

  Future<void> _manualCorrection() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        const options = [
          'PET',
          'HDPE',
          'LDPE',
          'PP',
          'Paper',
          'Cardboard',
          'E-Waste',
          'Battery',
          'Other',
        ];

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose correct material',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...options.map(
                (item) => ListTile(
                  leading: const Icon(Icons.recycling),
                  title: Text(item),
                  onTap: () => Navigator.pop(context, item),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    if (selected == 'PET') {
      setState(() {
        _confirmedMaterial = 'PET';
        _resinCode = '1';
        _resultConfirmed = false;
        _needsResinConfirmation = false;
        _needsPetCondition = true;
        _result = 'PET SELECTED';
        _details = 'Select crushed or uncrushed.';
        _rateText = '';
      });
      return;
    }

    final rate = _suggestedRate(selected);
    setState(() {
      _confirmedMaterial = selected;
      _confirmedRate = rate;
      _resultConfirmed = true;
      _needsResinConfirmation = false;
      _needsPetCondition = false;
      _result = '$selected CONFIRMED';
      _details = 'Corrected manually by customer. Admin will cross-check the image.';
      _rateText = rate > 0 ? '$selected: ₹${rate.toStringAsFixed(0)}/kg' : 'Admin valuation';
    });
  }

  Future<Map<String, dynamic>> _uploadToCloudinary(String filePath) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> _saveScan() async {
    if (!_resultConfirmed ||
        _confirmedMaterial == null ||
        _lastCapturedPath == null ||
        _saving) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final cloudinary = await _uploadToCloudinary(_lastCapturedPath!);
      final imageUrl = '${cloudinary['secure_url'] ?? ''}';
      if (imageUrl.isEmpty) throw Exception('Cloudinary did not return an image URL');

      final now = DateTime.now();
      final customerId = '${widget.profile['customerId'] ?? ''}';
      final customerName = '${widget.profile['name'] ?? ''}';

      await FirebaseFirestore.instance.collection('scans').add({
        'customerUid': user.uid,
        'customerId': customerId,
        'customerName': customerName,
        'scanDate': dateKey(now),
        'scannedAt': FieldValue.serverTimestamp(),
        'material': _confirmedMaterial,
        'resinCode': _resinCode,
        'petCondition': _petCondition,
        'aiCategory': _detectedCategory,
        'aiConfidence': _averageConfidence,
        'imageUrl': imageUrl,
        'cloudinaryPublicId': cloudinary['public_id'],
        'ratePerKg': _confirmedRate,
        'customerWeight': null,
        'confirmedWeight': null,
        'amount': 0.0,
        'adminVerified': false,
        'status': 'Pending Verification',
        'createdAtClient': now.toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan saved under Customer ID $customerId on ${displayDate(now)}',
          ),
        ),
      );

      _clearScan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save scan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearScan() {
    _tts.stop();
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _hasResult = false;
      _resultConfirmed = false;
      _needsResinConfirmation = false;
      _needsPetCondition = false;
      _detectedCategory = null;
      _confirmedMaterial = null;
      _resinCode = null;
      _petCondition = null;
      _lastCapturedPath = null;
      _averageConfidence = 0;
      _confirmedRate = 0;
      _result = widget.tamil
          ? 'புதிய பொருளை கேமரா முன் வைக்கவும்'
          : 'Point camera at a new waste item';
      _details = '';
      _rateText = '';
      _confidenceText = '';
    });
  }

  Future<void> _speak() async {
    if (!_hasResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan an item first')),
      );
      return;
    }
    await _tts.stop();
    await _tts.speak('$_result. $_details. $_rateText');
  }

  @override
  void dispose() {
    _controller?.dispose();
    _imageLabeler.close();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF43A047)),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.68),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Place ONE item clearly in the camera. Scan → Confirm material → Save Scan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 76, 20, 190),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.76),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _hasResult ? Colors.greenAccent : Colors.white54,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _hasResult ? Colors.greenAccent : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_details.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _details,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    if (_confidenceText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _confidenceText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ],
                    if (_rateText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _rateText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    if (_needsResinConfirmation) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Check recycling symbol / resin code',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ActionChip(
                            label: const Text('1 PET'),
                            onPressed: () => _confirmResin('1', 'PET'),
                          ),
                          ActionChip(
                            label: const Text('2 HDPE'),
                            onPressed: () => _confirmResin('2', 'HDPE'),
                          ),
                          ActionChip(
                            label: const Text('4 LDPE'),
                            onPressed: () => _confirmResin('4', 'LDPE'),
                          ),
                          ActionChip(
                            label: const Text('5 PP'),
                            onPressed: () => _confirmResin('5', 'PP'),
                          ),
                        ],
                      ),
                    ],
                    if (_needsPetCondition) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'PET condition',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          ActionChip(
                            label: const Text('CRUSHED ₹14/kg'),
                            onPressed: () => _confirmPetCondition('Crushed'),
                          ),
                          ActionChip(
                            label: const Text('UNCRUSHED ₹12/kg'),
                            onPressed: () => _confirmPetCondition('Uncrushed'),
                          ),
                        ],
                      ),
                    ],
                    if (_hasResult &&
                        !_needsResinConfirmation &&
                        !_needsPetCondition &&
                        !_resultConfirmed &&
                        _detectedCategory != 'unknown') ...[
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _confirmDetectedResult,
                        icon: const Icon(Icons.check),
                        label: const Text('CONFIRM RESULT'),
                      ),
                    ],
                    if (_hasResult) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _manualCorrection,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'WRONG RESULT / CHOOSE MANUALLY',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    if (_resultConfirmed) ...[
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.greenAccent),
                          SizedBox(width: 6),
                          Text(
                            'Material confirmed — ready to save',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _saving ? null : _saveScan,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(_saving ? 'SAVING...' : 'SAVE SCAN TO HISTORY'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _scanning || _saving ? null : _scan,
                        icon: _scanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.center_focus_strong),
                        label: Text(_scanning ? 'ANALYZING...' : 'SCAN'),
                        style: FilledButton.styleFrom(
                          backgroundColor: pothigaiGreen,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _speak,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('TAMIL VOICE'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_hasResult) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _clearScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('CLEAR & NEW SCAN'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: pothigaiGreen,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PickupPage extends StatefulWidget {
  const PickupPage({
    super.key,
    required this.tamil,
    required this.profile,
  });

  final bool tamil;
  final Map<String, dynamic> profile;

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = 'PET Bottles';
  bool _busy = false;

  static const categories = [
    'PET Bottles',
    'HDPE Plastic',
    'LDPE Plastic',
    'PP Plastic',
    'Paper',
    'Cardboard',
    'E-Waste',
    'Battery',
    'Mixed Recyclables',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.text = '${widget.profile['phone'] ?? ''}';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);

    try {
      await FirebaseFirestore.instance.collection('pickup_requests').add({
        'customerUid': user.uid,
        'customerId': widget.profile['customerId'],
        'customerName': widget.profile['name'],
        'category': _category,
        'quantity': _quantityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'status': 'Requested',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup request saved')),
      );
      _quantityController.clear();
      _addressController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save pickup request: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.tamil ? 'கழிவு சேகரிப்பு பதிவு' : 'Book Waste Pickup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Waste category',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Approx. quantity / weight',
              hintText: 'Example: 8 kg or 2 bags',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter quantity'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().length < 8
                ? 'Please enter a valid phone number'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Pickup address',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter pickup address'
                : null,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('CONFIRM PICKUP'),
          ),
        ],
      ),
    );
  }
}

class CustomerHistoryPage extends StatelessWidget {
  const CustomerHistoryPage({
    super.key,
    required this.tamil,
    required this.profile,
  });

  final bool tamil;
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('scans')
          .where('customerUid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('History error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aDate = timestampToDate(a.data()['scannedAt']);
            final bDate = timestampToDate(b.data()['scannedAt']);
            return bDate.compareTo(aDate);
          });

        if (docs.isEmpty) {
          return const Center(child: Text('No saved scans yet'));
        }

        final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
        for (final doc in docs) {
          final key = '${doc.data()['scanDate'] ?? dateKey(timestampToDate(doc.data()['scannedAt']))}';
          grouped.putIfAbsent(key, () => []).add(doc);
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: grouped.entries.map((entry) {
            final dailyTotal = entry.value.fold<double>(
              0,
              (sum, doc) => sum + asDouble(doc.data()['amount']),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Chip(label: Text('Verified total ₹${dailyTotal.toStringAsFixed(2)}')),
                  ],
                ),
                const SizedBox(height: 6),
                ...entry.value.map((doc) => CustomerScanCard(data: doc.data())),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class CustomerScanCard extends StatelessWidget {
  const CustomerScanCard({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${data['imageUrl'] ?? ''}';
    final material = '${data['material'] ?? '-'}';
    final status = '${data['status'] ?? 'Pending Verification'}';
    final verified = data['adminVerified'] == true;
    final rate = asDouble(data['ratePerKg']);
    final weight = asDouble(data['confirmedWeight']);
    final amount = asDouble(data['amount']);
    final confidence = asDouble(data['aiConfidence']);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isEmpty
                  ? Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    )
                  : Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text('AI confidence: ${(confidence * 100).toStringAsFixed(0)}%'),
                  Text('Rate: ₹${rate.toStringAsFixed(2)}/kg'),
                  if (verified) Text('Verified weight: ${weight.toStringAsFixed(2)} kg'),
                  if (verified)
                    Text(
                      'Payable: ₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: pothigaiGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Chip(
                    avatar: Icon(
                      verified ? Icons.verified : Icons.schedule,
                      size: 18,
                    ),
                    label: Text(status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.tamil,
    required this.profile,
  });

  final bool tamil;
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tamil ? 'பசுமை வழிகாட்டி' : 'Green Guide',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge, color: pothigaiGreen),
            title: const Text('Customer ID'),
            subtitle: Text('${profile['customerId'] ?? ''}'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.recycling, color: pothigaiGreen),
            title: Text('Plastic resin codes'),
            subtitle: Text('1 = PET • 2 = HDPE • 4 = LDPE • 5 = PP'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.verified_user_outlined, color: pothigaiGreen),
            title: Text('Payment verification'),
            subtitle: Text(
              'AI classification is guidance. Admin verifies the scan image, final material, weight and rate before payment.',
            ),
          ),
        ),
      ],
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _customerFilterController = TextEditingController();
  final _dateFilterController = TextEditingController();

  @override
  void dispose() {
    _customerFilterController.dispose();
    _dateFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pothigai Green Admin'),
            Text(
              'Scan Verification & Payment',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerFilterController,
                    decoration: const InputDecoration(
                      labelText: 'Customer ID filter',
                      hintText: 'PG000001',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dateFilterController,
                    decoration: const InputDecoration(
                      labelText: 'Date filter',
                      hintText: '2026-09-15',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('scans').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Admin data error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customerFilter = _customerFilterController.text.trim().toUpperCase();
                final dateFilter = _dateFilterController.text.trim();

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final customerId = '${data['customerId'] ?? ''}'.toUpperCase();
                  final scanDate = '${data['scanDate'] ?? ''}';
                  final customerOk = customerFilter.isEmpty || customerId.contains(customerFilter);
                  final dateOk = dateFilter.isEmpty || scanDate == dateFilter;
                  return customerOk && dateOk;
                }).toList()
                  ..sort((a, b) {
                    final aDate = timestampToDate(a.data()['scannedAt']);
                    final bDate = timestampToDate(b.data()['scannedAt']);
                    return bDate.compareTo(aDate);
                  });

                final totalPayable = docs.fold<double>(
                  0,
                  (sum, doc) => sum + asDouble(doc.data()['amount']),
                );

                if (docs.isEmpty) {
                  return const Center(child: Text('No scans match the selected filters'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Card(
                        color: const Color(0xFFE8F5E9),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.payments, color: pothigaiGreen),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Filtered total payable: ₹${totalPayable.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text('${docs.length} scans'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return AdminScanCard(
                            docId: doc.id,
                            data: doc.data(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminScanCard extends StatelessWidget {
  const AdminScanCard({
    super.key,
    required this.docId,
    required this.data,
  });

  final String docId;
  final Map<String, dynamic> data;

  void _showImage(BuildContext context, String url) {
    if (url.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${data['imageUrl'] ?? ''}';
    final customerId = '${data['customerId'] ?? ''}';
    final customerName = '${data['customerName'] ?? ''}';
    final material = '${data['material'] ?? ''}';
    final scanDate = '${data['scanDate'] ?? ''}';
    final status = '${data['status'] ?? ''}';
    final amount = asDouble(data['amount']);
    final verified = data['adminVerified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showImage(context, imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isEmpty
                    ? Container(
                        width: 105,
                        height: 105,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      )
                    : Image.network(
                        imageUrl,
                        width: 105,
                        height: 105,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 105,
                          height: 105,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$customerId • $customerName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$scanDate • $material'),
                  Text('Status: $status'),
                  if (verified)
                    Text(
                      'Payable ₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: pothigaiGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AdminReviewDialog(
                          docId: docId,
                          initialData: data,
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check),
                    label: Text(verified ? 'REVIEW / EDIT' : 'VERIFY SCAN'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminReviewDialog extends StatefulWidget {
  const AdminReviewDialog({
    super.key,
    required this.docId,
    required this.initialData,
  });

  final String docId;
  final Map<String, dynamic> initialData;

  @override
  State<AdminReviewDialog> createState() => _AdminReviewDialogState();
}

class _AdminReviewDialogState extends State<AdminReviewDialog> {
  static const materials = [
    'PET',
    'HDPE',
    'LDPE',
    'PP',
    'Paper',
    'Cardboard',
    'E-Waste',
    'Battery',
    'Other',
  ];

  late String _material;
  String _petCondition = 'Uncrushed';
  late TextEditingController _weightController;
  late TextEditingController _rateController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final initialMaterial = '${widget.initialData['material'] ?? 'Other'}';
    _material = materials.contains(initialMaterial) ? initialMaterial : 'Other';
    _petCondition = '${widget.initialData['petCondition'] ?? 'Uncrushed'}';
    if (_petCondition != 'Crushed' && _petCondition != 'Uncrushed') {
      _petCondition = 'Uncrushed';
    }
    _weightController = TextEditingController(
      text: asDouble(widget.initialData['confirmedWeight']) > 0
          ? asDouble(widget.initialData['confirmedWeight']).toStringAsFixed(2)
          : '',
    );
    _rateController = TextEditingController(
      text: asDouble(widget.initialData['ratePerKg']).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double _defaultRate() {
    switch (_material) {
      case 'PET':
        return _petCondition == 'Crushed' ? 14 : 12;
      case 'HDPE':
        return 18;
      case 'LDPE':
        return 10;
      case 'PP':
        return 12;
      case 'Paper':
        return 8;
      case 'Cardboard':
        return 6;
      default:
        return 0;
    }
  }

  void _applySuggestedRate() {
    _rateController.text = _defaultRate().toStringAsFixed(2);
  }

  Future<void> _approve() async {
    final weight = double.tryParse(_weightController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter verified weight in kg')),
      );
      return;
    }
    if (rate == null || rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid rate')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final amount = weight * rate;
      await FirebaseFirestore.instance.collection('scans').doc(widget.docId).update({
        'material': _material,
        'petCondition': _material == 'PET' ? _petCondition : null,
        'ratePerKg': rate,
        'confirmedWeight': weight,
        'amount': amount,
        'adminVerified': true,
        'status': 'Verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('scans').doc(widget.docId).update({
        'amount': 0.0,
        'adminVerified': false,
        'status': 'Rejected',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${widget.initialData['imageUrl'] ?? ''}';
    final confidence = asDouble(widget.initialData['aiConfidence']);

    return AlertDialog(
      title: Text('Verify ${widget.initialData['customerId'] ?? ''}'),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 120,
                      child: Center(child: Icon(Icons.broken_image, size: 50)),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text('AI confidence: ${(confidence * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _material,
                decoration: const InputDecoration(
                  labelText: 'Verified material',
                  border: OutlineInputBorder(),
                ),
                items: materials
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _material = value;
                    _applySuggestedRate();
                  });
                },
              ),
              if (_material == 'PET') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _petCondition,
                  decoration: const InputDecoration(
                    labelText: 'PET condition',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Crushed', child: Text('Crushed')), 
                    DropdownMenuItem(value: 'Uncrushed', child: Text('Uncrushed')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _petCondition = value;
                      _applySuggestedRate();
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Confirmed weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Rate per kg (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _applySuggestedRate,
                icon: const Icon(Icons.price_change),
                label: const Text('USE SUGGESTED RATE'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: _busy ? null : _reject,
          child: const Text('REJECT', style: TextStyle(color: Colors.red)),
        ),
        FilledButton(
          onPressed: _busy ? null : _approve,
          child: Text(_busy ? 'SAVING...' : 'VERIFY & CALCULATE'),
        ),
      ],
    );
  }
}
