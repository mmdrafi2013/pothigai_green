import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'roadmap1.dart';

late List<CameraDescription> cameras;

const String cloudinaryCloudName = 'ni61iafo';
const String cloudinaryUploadPreset = 'pothigai_scans';
const Color pothigaiGreen = Color(0xFF2E7D32);

const String pothigaiAdminEmail = 'mmdrafi2013@gmail.com';
const String pothigaiAdminPhone = '8056583814';

String _digitsOnly(String value) =>
    value.replaceAll(RegExp(r'[^0-9]'), '');

bool isPothigaiAdminIdentity({
  String? email,
  String? phone,
}) {
  final normalizedEmail = (email ?? '').trim().toLowerCase();
  final normalizedPhone = _digitsOnly(phone ?? '');
  final adminPhone = _digitsOnly(pothigaiAdminPhone);

  final emailMatch = normalizedEmail == pothigaiAdminEmail.toLowerCase();

  final phoneMatch = normalizedPhone == adminPhone ||
      (normalizedPhone.length >= 10 &&
          normalizedPhone.substring(normalizedPhone.length - 10) == adminPhone);

  return emailMatch || phoneMatch;
}

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

double firstNumberFromText(String value) {
  final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(value);
  if (match == null) return 0.0;
  return double.tryParse(match.group(1) ?? '') ?? 0.0;
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
      title: 'Pothigai Green Project 2',
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
                '\u0BAA\u0BCA\u0BA4\u0BBF\u0B95\u0BC8 \u0BAA\u0B9A\u0BC1\u0BAE\u0BC8',
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

            final isAdmin = role == 'admin';

            if (isAdmin) {
              return AdminHome(
                profile: Map<String, dynamic>.from(profile),
              );
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
  bool _tamil = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _customerIdFromUid(String uid) {
    final cleaned = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final token = cleaned.length >= 12
        ? cleaned.substring(0, 12)
        : cleaned.padRight(12, '0');
    return 'PG$token';
  }

  String t(String english, String tamil) => _tamil ? tamil : english;

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
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = credential.user!.uid;
        final customerId = _customerIdFromUid(uid);
        final phone = _phoneController.text.trim();

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'customerId': customerId,
          'name': _nameController.text.trim(),
          'phone': phone,
          'email': email,
          'role': 'customer',
          'preferredLanguage': _tamil ? 'ta' : 'en',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: pothigaiGreen),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      labelStyle: const TextStyle(color: Color(0xFF4E5B4F)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFA5C8A8), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: pothigaiGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  Widget _languageToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageChip('English', !_tamil, () => setState(() => _tamil = false)),
          _languageChip('\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD', _tamil, () => setState(() => _tamil = true)),
        ],
      ),
    );
  }

  Widget _languageChip(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? pothigaiGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1B5E20),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _PothigaiMountainBackgroundPainter()),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.05),
                  const Color(0xFF0A3D22).withOpacity(0.18),
                  const Color(0xFF052D19).withOpacity(0.48),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _languageToggle(),
                      ),
                      const SizedBox(height: 30),
                      const Icon(
                        Icons.recycling,
                        color: Colors.white,
                        size: 72,
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pothigai Green',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          shadows: [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(
                          'Recycle today for a cleaner Tamil Nadu tomorrow',
                          '\u0B87\u0BA9\u0BCD\u0BB1\u0BC7 \u0BAE\u0BB1\u0BC1\u0B9A\u0BC1\u0BB4\u0BB1\u0BCD\u0B9A\u0BBF \u0B9A\u0BC6\u0BAF\u0BCD\u0BB5\u0BCB\u0BAE\u0BCD\n\u0BA8\u0BBE\u0BB3\u0BC8 \u0B9A\u0BC1\u0BA4\u0BCD\u0BA4\u0BAE\u0BBE\u0BA9 \u0BA4\u0BAE\u0BBF\u0BB4\u0BCD\u0BA8\u0BBE\u0B9F\u0BC1',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FFF8).withOpacity(0.94),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.75),
                            width: 1.3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3D000000),
                              blurRadius: 26,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _registerMode
                                    ? t('Create Customer Account', '\u0BAA\u0BC1\u0BA4\u0BBF\u0BAF \u0BB5\u0BBE\u0B9F\u0BBF\u0B95\u0BCD\u0B95\u0BC8\u0BAF\u0BBE\u0BB3\u0BB0\u0BCD \u0B95\u0BA3\u0B95\u0BCD\u0B95\u0BC1')
                                    : t('Customer / Admin Login', '\u0BB5\u0BBE\u0B9F\u0BBF\u0B95\u0BCD\u0B95\u0BC8\u0BAF\u0BBE\u0BB3\u0BB0\u0BCD / \u0BA8\u0BBF\u0BB0\u0BCD\u0BB5\u0BBE\u0B95\u0BBF \u0B89\u0BB3\u0BCD\u0BA8\u0BC1\u0BB4\u0BC8\u0BB5\u0BC1'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF123A20),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _registerMode
                                    ? t('Join Pothigai Green', '\u0BAA\u0BCA\u0BA4\u0BBF\u0B95\u0BC8 \u0BAA\u0B9A\u0BC1\u0BAE\u0BC8\u0BAF\u0BBF\u0BB2\u0BCD \u0B87\u0BA3\u0BC8\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD')
                                    : t('Welcome back', '\u0BAE\u0BC0\u0BA3\u0BCD\u0B9F\u0BC1\u0BAE\u0BCD \u0BB5\u0BB0\u0BB5\u0BC7\u0BB1\u0BCD\u0B95\u0BBF\u0BB1\u0BCB\u0BAE\u0BCD'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF52705A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_registerMode) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: _fieldDecoration(
                                    label: t('Customer name', '\u0BB5\u0BBE\u0B9F\u0BBF\u0B95\u0BCD\u0B95\u0BC8\u0BAF\u0BBE\u0BB3\u0BB0\u0BCD \u0BAA\u0BC6\u0BAF\u0BB0\u0BCD'),
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? t('Enter customer name', '\u0BB5\u0BBE\u0B9F\u0BBF\u0B95\u0BCD\u0B95\u0BC8\u0BAF\u0BBE\u0BB3\u0BB0\u0BCD \u0BAA\u0BC6\u0BAF\u0BB0\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BB5\u0BC1\u0BAE\u0BCD')
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  decoration: _fieldDecoration(
                                    label: t('Phone number', '\u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD'),
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().length < 8
                                          ? t('Enter a valid phone number', '\u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD\u0BA3\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BB5\u0BC1\u0BAE\u0BCD')
                                          : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: t('Email', '\u0BAE\u0BBF\u0BA9\u0BCD\u0BA9\u0B9E\u0BCD\u0B9A\u0BB2\u0BCD'),
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) =>
                                    value == null || !value.contains('@')
                                        ? t('Enter a valid email', '\u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0BAE\u0BBF\u0BA9\u0BCD\u0BA9\u0B9E\u0BCD\u0B9A\u0BB2\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BB5\u0BC1\u0BAE\u0BCD')
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _fieldDecoration(
                                  label: t('Password', '\u0B95\u0B9F\u0BB5\u0BC1\u0B9A\u0BCD\u0B9A\u0BCA\u0BB2\u0BCD'),
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    tooltip: _hidePassword
                                        ? t('Show password', '\u0B95\u0B9F\u0BB5\u0BC1\u0B9A\u0BCD\u0B9A\u0BCA\u0BB2\u0BCD\u0BB2\u0BC8 \u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1')
                                        : t('Hide password', '\u0B95\u0B9F\u0BB5\u0BC1\u0B9A\u0BCD\u0B9A\u0BCA\u0BB2\u0BCD\u0BB2\u0BC8 \u0BAE\u0BB1\u0BC8'),
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.length < 6
                                        ? t(
                                            'Password must be at least 6 characters',
                                            '\u0B95\u0B9F\u0BB5\u0BC1\u0B9A\u0BCD\u0B9A\u0BCA\u0BB2\u0BCD \u0B95\u0BC1\u0BB1\u0BC8\u0BA8\u0BCD\u0BA4\u0BA4\u0BC1 6 \u0B8E\u0BB4\u0BC1\u0BA4\u0BCD\u0BA4\u0BC1\u0B95\u0BB3\u0BCD \u0B87\u0BB0\u0BC1\u0B95\u0BCD\u0B95 \u0BB5\u0BC7\u0BA3\u0BCD\u0B9F\u0BC1\u0BAE\u0BCD',
                                          )
                                        : null,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F6F32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: _busy ? null : _submit,
                                  icon: _busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          _registerMode
                                              ? Icons.person_add_alt_1
                                              : Icons.login,
                                        ),
                                  label: Text(
                                    _registerMode
                                        ? t('CREATE ACCOUNT', '\u0B95\u0BA3\u0B95\u0BCD\u0B95\u0BC1 \u0B89\u0BB0\u0BC1\u0BB5\u0BBE\u0B95\u0BCD\u0B95\u0BC1')
                                        : t('LOGIN', '\u0B89\u0BB3\u0BCD\u0BA8\u0BC1\u0BB4\u0BC8'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                      ? t(
                                          'Already registered? Login',
                                          '\u0B8F\u0BB1\u0BCD\u0B95\u0BA9\u0BB5\u0BC7 \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BA4\u0BC1\u0BB3\u0BCD\u0BB3\u0BC0\u0BB0\u0BCD\u0B95\u0BB3\u0BBE? \u0B89\u0BB3\u0BCD\u0BA8\u0BC1\u0BB4\u0BC8\u0BAF\u0BB5\u0BC1\u0BAE\u0BCD',
                                        )
                                      : t(
                                          'New customer? Create account',
                                          '\u0BAA\u0BC1\u0BA4\u0BBF\u0BAF \u0BB5\u0BBE\u0B9F\u0BBF\u0B95\u0BCD\u0B95\u0BC8\u0BAF\u0BBE\u0BB3\u0BB0\u0BBE? \u0B95\u0BA3\u0B95\u0BCD\u0B95\u0BC1 \u0B89\u0BB0\u0BC1\u0BB5\u0BBE\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD',
                                        ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E4B2B).withOpacity(0.80),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                t(
                                  'Green today \u2022 Healthy tomorrow',
                                  '\u0B87\u0BA9\u0BCD\u0BB1\u0BC1 \u0BAA\u0B9A\u0BC1\u0BAE\u0BC8 \u2022 \u0BA8\u0BBE\u0BB3\u0BC8 \u0B86\u0BB0\u0BCB\u0B95\u0BCD\u0B95\u0BBF\u0BAF\u0BAE\u0BCD',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PothigaiMountainBackgroundPainter extends CustomPainter {
  const _PothigaiMountainBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFBFE7F5),
          Color(0xFFE8F4E8),
          Color(0xFF76A66A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final sun = Paint()..color = const Color(0x55FFF9C4);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.13),
      size.width * 0.18,
      sun,
    );

    void ridge({
      required double base,
      required Color color,
      required List<Offset> peaks,
    }) {
      final path = Path()..moveTo(0, size.height * base);
      for (final point in peaks) {
        path.lineTo(size.width * point.dx, size.height * point.dy);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    ridge(
      base: 0.48,
      color: const Color(0xFF6F9A72),
      peaks: const [
        Offset(0.08, 0.39),
        Offset(0.18, 0.31),
        Offset(0.30, 0.40),
        Offset(0.43, 0.22),
        Offset(0.54, 0.34),
        Offset(0.68, 0.18),
        Offset(0.78, 0.30),
        Offset(0.90, 0.23),
        Offset(1.00, 0.36),
      ],
    );

    ridge(
      base: 0.58,
      color: const Color(0xFF3E7E50),
      peaks: const [
        Offset(0.05, 0.50),
        Offset(0.17, 0.40),
        Offset(0.27, 0.49),
        Offset(0.41, 0.34),
        Offset(0.54, 0.45),
        Offset(0.67, 0.32),
        Offset(0.79, 0.43),
        Offset(0.91, 0.35),
        Offset(1.00, 0.47),
      ],
    );

    ridge(
      base: 0.70,
      color: const Color(0xFF1F5A35),
      peaks: const [
        Offset(0.00, 0.63),
        Offset(0.13, 0.53),
        Offset(0.25, 0.61),
        Offset(0.38, 0.49),
        Offset(0.50, 0.60),
        Offset(0.63, 0.48),
        Offset(0.76, 0.59),
        Offset(0.88, 0.49),
        Offset(1.00, 0.60),
      ],
    );

    final mist = Paint()..color = Colors.white.withOpacity(0.16);
    for (int i = 0; i < 7; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (0.08 + i * 0.15),
            size.height * (0.34 + (i % 2) * 0.025),
          ),
          width: size.width * 0.28,
          height: size.height * 0.055,
        ),
        mist,
      );
    }

    final foreground = Paint()..color = const Color(0xFF0A3D22);
    final foregroundPath = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.76,
        size.width * 0.48,
        size.height * 0.86,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.96,
        size.width,
        size.height * 0.80,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(foregroundPath, foreground);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            Text(_tamil ? '\u0BAA\u0BCA\u0BA4\u0BBF\u0B95\u0BC8 \u0BAA\u0B9A\u0BC1\u0BAE\u0BC8' : 'Pothigai Green'),
            Text(
              'Project 2 \u2022 $customerId \u2022 $customerName',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _tamil = !_tamil),
            child: Text(
              _tamil ? 'EN' : '\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            tooltip: 'Roadmap-1',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Roadmap1HubPage(
                    profile: widget.profile,
                    isAdmin: false,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
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
            label: _tamil ? '\u0BAE\u0BC1\u0B95\u0BAA\u0BCD\u0BAA\u0BC1' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.center_focus_weak),
            selectedIcon: const Icon(Icons.center_focus_strong),
            label: _tamil ? '\u0BB8\u0BCD\u0B95\u0BC7\u0BA9\u0BCD' : 'Scan',
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: _tamil ? '\u0BAA\u0BBF\u0B95\u0BCD\u0B95\u0BAA\u0BCD' : 'Pickup',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: _tamil ? '\u0BB5\u0BB0\u0BB2\u0BBE\u0BB1\u0BC1' : 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: _tamil ? '\u0BA4\u0B95\u0BB5\u0BB2\u0BCD' : 'Info',
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
                tamil ? '\u0B95\u0BC1\u0BAA\u0BCD\u0BAA\u0BC8\u0BAF\u0BBF\u0BB2\u0BC1\u0BAE\u0BCD \u0B95\u0BBE\u0B9A\u0BC1 \u0B89\u0BA3\u0BCD\u0B9F\u0BC1' : 'Kuppaiyilum kaasu undu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$customerName \u2022 $customerId',
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
          tamil ? '\u0B87\u0BA9\u0BCD\u0BB1\u0BC8\u0BAF \u0BB5\u0BBF\u0BB2\u0BC8' : 'Current Rates',
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
    ['PET Crushed', '\u20B914/kg'],
    ['PET Uncrushed', '\u20B912/kg'],
    ['HDPE', '\u20B918/kg'],
    ['LDPE', '\u20B910/kg'],
    ['PP', '\u20B912/kg'],
    ['Paper', '\u20B98/kg'],
    ['Cardboard', '\u20B96/kg'],
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
  const ScanDecision({
    required this.category,
    required this.confidence,
    this.subtype,
    this.objectType,
    this.source = 'ai',
  });

  final String category;
  final double confidence;
  final String? subtype;
  final String? objectType;
  final String source;
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

  Interpreter? _v3Interpreter;
  Interpreter? _v4Interpreter;
  Interpreter? _v5Interpreter;

  bool _v3Ready = false;
  bool _v4Ready = false;
  bool _v5Ready = false;

  bool _ready = false;
  bool _scanning = false;
  bool _saving = false;

  String _aiSuggestion = '';
  double _aiConfidence = 0;
  String _aiSource = '';
  String? _collectorSelection;
  String? _lastCapturedPath;

  final TextEditingController _weightController = TextEditingController();

  static const List<String> _modelLabels = <String>[
    'cardboard',
    'glass',
    'metal',
    'paper',
    'plastic',
  ];

  static const List<String> _collectorChoices = <String>[
    'Plastic',
    'Bottle',
    'Paper',
    'Cardboard',
    'Glass',
    'Metal',
    'E-Waste',
    'Battery',
    'Textile',
    'Other',
  ];

  static const Map<String, double> _defaultRates = <String, double>{
    'Plastic': 12.0,
    'Bottle': 12.0,
    'Paper': 8.0,
    'Cardboard': 6.0,
    'Glass': 5.0,
    'Metal': 25.0,
    'E-Waste': 15.0,
    'Battery': 10.0,
    'Textile': 5.0,
    'Other': 0.0,
  };

  @override
  void initState() {
    super.initState();

    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.45),
    );

    _initHybridModels();
    _initCamera();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initHybridModels() async {
    await Future.wait<void>([
      _loadModel(
        asset: 'assets/ai/pothigai_waste_classifier_v3_fp16.tflite',
        assign: (interpreter) {
          _v3Interpreter = interpreter;
          _v3Ready = interpreter != null;
        },
      ),
      _loadModel(
        asset: 'assets/ai/pothigai_waste_classifier_v4_fp16.tflite',
        assign: (interpreter) {
          _v4Interpreter = interpreter;
          _v4Ready = interpreter != null;
        },
      ),
      _loadModel(
        asset: 'assets/ai/pothigai_waste_classifier_v5_fp16.tflite',
        assign: (interpreter) {
          _v5Interpreter = interpreter;
          _v5Ready = interpreter != null;
        },
      ),
    ]);
  }

  Future<void> _loadModel({
    required String asset,
    required void Function(Interpreter?) assign,
  }) async {
    try {
      final interpreter = await Interpreter.fromAsset(asset);

      if (!mounted) {
        interpreter.close();
        return;
      }

      assign(interpreter);
    } catch (e) {
      debugPrint('Project 2 model load failed for $asset: $e');
      if (mounted) assign(null);
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        setState(() => _ready = false);
      }
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

      if (!mounted) return;

      setState(() => _ready = true);
    } catch (e) {
      debugPrint('Project 2 camera initialization failed: $e');

      if (!mounted) return;

      setState(() => _ready = false);
    }
  }

  String _mapModelLabel(String label) {
    switch (label) {
      case 'cardboard':
        return 'Cardboard';
      case 'glass':
        return 'Glass';
      case 'metal':
        return 'Metal';
      case 'paper':
        return 'Paper';
      case 'plastic':
        return 'Plastic';
      default:
        return 'Other';
    }
  }

  Future<ScanDecision> _predictBroadModel({
    required Interpreter interpreter,
    required String filePath,
    required int imageSize,
    required String source,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return ScanDecision(
        category: 'Other',
        confidence: 0,
        source: source,
      );
    }

    final resized = img.copyResize(
      decoded,
      width: imageSize,
      height: imageSize,
      interpolation: img.Interpolation.linear,
    );

    final input = <dynamic>[
      List<dynamic>.generate(
        imageSize,
        (y) => List<dynamic>.generate(
          imageSize,
          (x) {
            final pixel = resized.getPixel(x, y);

            return <double>[
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
          growable: false,
        ),
        growable: false,
      ),
    ];

    final output = <List<double>>[
      List<double>.filled(_modelLabels.length, 0.0),
    ];

    interpreter.run(input, output);

    final scores = output.first;

    int bestIndex = 0;
    double bestScore = scores.first;

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    return ScanDecision(
      category: _mapModelLabel(_modelLabels[bestIndex]),
      confidence: bestScore,
      source: source,
    );
  }

  Future<ScanDecision?> _hybridSuggestion(String filePath) async {
    final decisions = <ScanDecision>[];

    if (_v3Ready && _v3Interpreter != null) {
      try {
        decisions.add(
          await _predictBroadModel(
            interpreter: _v3Interpreter!,
            filePath: filePath,
            imageSize: 224,
            source: 'V3',
          ),
        );
      } catch (e) {
        debugPrint('Project 2 V3 inference failed: $e');
      }
    }

    if (_v4Ready && _v4Interpreter != null) {
      try {
        decisions.add(
          await _predictBroadModel(
            interpreter: _v4Interpreter!,
            filePath: filePath,
            imageSize: 256,
            source: 'V4',
          ),
        );
      } catch (e) {
        debugPrint('Project 2 V4 inference failed: $e');
      }
    }

    if (_v5Ready && _v5Interpreter != null) {
      try {
        decisions.add(
          await _predictBroadModel(
            interpreter: _v5Interpreter!,
            filePath: filePath,
            imageSize: 256,
            source: 'V5',
          ),
        );
      } catch (e) {
        debugPrint('Project 2 V5 inference failed: $e');
      }
    }

    if (decisions.isEmpty) return null;

    final groups = <String, List<ScanDecision>>{};

    for (final decision in decisions) {
      groups
          .putIfAbsent(
            decision.category,
            () => <ScanDecision>[],
          )
          .add(decision);
    }

    String bestCategory = decisions.first.category;
    List<ScanDecision> bestGroup = groups[bestCategory]!;

    for (final entry in groups.entries) {
      if (entry.value.length > bestGroup.length) {
        bestCategory = entry.key;
        bestGroup = entry.value;
      }
    }

    final average = bestGroup
            .map((decision) => decision.confidence)
            .fold<double>(0.0, (a, b) => a + b) /
        bestGroup.length;

    return ScanDecision(
      category: bestCategory,
      confidence: average,
      source: bestGroup.length >= 2
          ? 'V3/V4/V5 consensus'
          : bestGroup.first.source,
    );
  }

  ScanDecision _genericSuggestion(List<ImageLabel> labels) {
    if (labels.isEmpty) {
      return const ScanDecision(
        category: 'Other',
        confidence: 0,
        source: 'ML Kit',
      );
    }

    final sorted = labels.toList()
      ..sort(
        (a, b) => b.confidence.compareTo(a.confidence),
      );

    double scoreFor(List<String> words) {
      double best = 0;

      for (final label in sorted.take(12)) {
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
      'Bottle': scoreFor([
        'bottle',
        'water bottle',
        'plastic bottle',
        'container',
      ]),
      'Paper': scoreFor([
        'paper',
        'newspaper',
        'document',
        'book',
        'magazine',
      ]),
      'Cardboard': scoreFor([
        'cardboard',
        'carton',
        'shipping box',
        'box',
      ]),
      'Glass': scoreFor([
        'glass',
        'glass bottle',
        'jar',
      ]),
      'Metal': scoreFor([
        'metal',
        'aluminium',
        'aluminum',
        'steel',
        'tin',
        'can',
      ]),
      'E-Waste': scoreFor([
        'electronic',
        'mobile phone',
        'cell phone',
        'laptop',
        'computer',
        'keyboard',
        'charger',
        'cable',
      ]),
      'Battery': scoreFor([
        'battery',
      ]),
      'Textile': scoreFor([
        'textile',
        'fabric',
        'cloth',
        'yarn',
        'wool',
        'thread',
      ]),
      'Plastic': scoreFor([
        'plastic',
        'plastic container',
        'bucket',
        'toy',
      ]),
    };

    String category = 'Other';
    double confidence = 0;

    for (final entry in scores.entries) {
      if (entry.value > confidence) {
        category = entry.key;
        confidence = entry.value;
      }
    }

    return ScanDecision(
      category: category,
      confidence: confidence,
      source: 'ML Kit',
    );
  }

  ScanDecision _combineAi(
    ScanDecision? hybrid,
    ScanDecision generic,
  ) {
    if (generic.category != 'Other' &&
        generic.confidence >= 0.70 &&
        (hybrid == null ||
            generic.category == 'Bottle' ||
            generic.category == 'E-Waste' ||
            generic.category == 'Battery' ||
            generic.category == 'Textile')) {
      return generic;
    }

    if (hybrid != null) return hybrid;

    return generic;
  }

  ScanDecision _combineFrames(List<ScanDecision> items) {
    final counts = <String, int>{};
    final totals = <String, double>{};

    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
      totals[item.category] =
          (totals[item.category] ?? 0) + item.confidence;
    }

    String category = items.first.category;
    int votes = 0;

    for (final entry in counts.entries) {
      if (entry.value > votes) {
        votes = entry.value;
        category = entry.key;
      }
    }

    final average =
        (totals[category] ?? 0) / (counts[category] ?? 1);

    return ScanDecision(
      category: category,
      confidence: average,
      source: '$votes/3 frames',
    );
  }

  Future<void> _scan() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _scanning) {
      return;
    }

    setState(() {
      _scanning = true;
      _aiSuggestion = '';
      _aiConfidence = 0;
      _aiSource = '';
      _collectorSelection = null;
      _lastCapturedPath = null;
      _weightController.clear();
    });

    try {
      final frameResults = <ScanDecision>[];

      for (int i = 0; i < 3; i++) {
        final picture = await _controller!.takePicture();

        _lastCapturedPath = picture.path;

        final hybrid = await _hybridSuggestion(picture.path);

        final labels = await _imageLabeler.processImage(
          InputImage.fromFilePath(picture.path),
        );

        final generic = _genericSuggestion(labels);

        frameResults.add(
          _combineAi(hybrid, generic),
        );

        if (i < 2) {
          await Future.delayed(
            const Duration(milliseconds: 300),
          );
        }
      }

      final result = _combineFrames(frameResults);

      if (!mounted) return;

      setState(() {
        _scanning = false;
        _aiSuggestion = result.category;
        _aiConfidence = result.confidence;
        _aiSource = result.source;
      });

      await _speakSuggestion();
    } catch (e) {
      debugPrint('Project 2 scan failed: $e');

      if (!mounted) return;

      setState(() {
        _scanning = false;
        _aiSuggestion = 'Other';
        _aiConfidence = 0;
        _aiSource = 'manual confirmation';
      });
    }
  }

  Future<void> _speakSuggestion() async {
    if (_aiSuggestion.isEmpty) return;

    await _tts.stop();

    final message = widget.tamil
        ? '${_tamilCategory(_aiSuggestion)} \u0B8E\u0BA9 \u0B9A\u0BC6\u0BAF\u0BB2\u0BBF \u0BAA\u0BB0\u0BBF\u0BA8\u0BCD\u0BA4\u0BC1\u0BB0\u0BC8\u0B95\u0BCD\u0B95\u0BBF\u0BB1\u0BA4\u0BC1. \u0B95\u0BC0\u0BB4\u0BC7 \u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0BB5\u0B95\u0BC8\u0BAF\u0BC8 \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD.'
        : 'The app suggests $_aiSuggestion. Please choose the correct category below.';

    await _tts.speak(message);
  }

  String _tamilCategory(String category) {
    switch (category) {
      case 'Plastic':
        return '\u0BAA\u0BBF\u0BB3\u0BBE\u0BB8\u0BCD\u0B9F\u0BBF\u0B95\u0BCD';
      case 'Bottle':
        return '\u0BAA\u0BBE\u0B9F\u0BCD\u0B9F\u0BBF\u0BB2\u0BCD';
      case 'Paper':
        return '\u0B95\u0BBE\u0B95\u0BBF\u0BA4\u0BAE\u0BCD';
      case 'Cardboard':
        return '\u0B85\u0B9F\u0BCD\u0B9F\u0BC8';
      case 'Glass':
        return '\u0B95\u0BA3\u0BCD\u0BA3\u0BBE\u0B9F\u0BBF';
      case 'Metal':
        return '\u0B89\u0BB2\u0BCB\u0B95\u0BAE\u0BCD';
      case 'E-Waste':
        return '\u0BAE\u0BBF\u0BA9\u0BCD\u0BA9\u0BA3\u0BC1 \u0B95\u0BB4\u0BBF\u0BB5\u0BC1';
      case 'Battery':
        return '\u0BAA\u0BC7\u0B9F\u0BCD\u0B9F\u0BB0\u0BBF';
      case 'Textile':
        return '\u0BA4\u0BC1\u0BA3\u0BBF';
      default:
        return '\u0BAE\u0BB1\u0BCD\u0BB1\u0BB5\u0BC8';
    }
  }

  String _displayCategory(String category) {
    return widget.tamil
        ? _tamilCategory(category)
        : category;
  }

  double get _selectedRate {
    final category = _collectorSelection;

    if (category == null) return 0;

    return _defaultRates[category] ?? 0;
  }

  double get _weight {
    return double.tryParse(
          _weightController.text.trim(),
        ) ??
        0;
  }

  double get _amount => _weight * _selectedRate;

  void _selectCategory(String category) {
    setState(() {
      _collectorSelection = category;
    });
  }

  Future<Map<String, dynamic>> _uploadToCloudinary(
    String filePath,
  ) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$cloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    )
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
        ),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 ||
        streamed.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed '
        '(${streamed.statusCode}): $body',
      );
    }

    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> _saveScan() async {
    if (_saving) return;

    if (_collectorSelection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tamil
                ? '\u0BAE\u0BC1\u0BA4\u0BB2\u0BBF\u0BB2\u0BCD \u0BAA\u0BCA\u0BB0\u0BC1\u0BB3\u0BCD \u0BB5\u0B95\u0BC8\u0BAF\u0BC8 \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD.'
                : 'Choose the material category first.',
          ),
        ),
      );
      return;
    }

    if (_weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tamil
                ? '\u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0B8E\u0B9F\u0BC8\u0BAF\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BC1\u0B95.'
                : 'Enter a valid weight in kg.',
          ),
        ),
      );
      return;
    }

    if (_lastCapturedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tamil
                ? '\u0BAE\u0BC1\u0BA4\u0BB2\u0BBF\u0BB2\u0BCD \u0BAA\u0BCA\u0BB0\u0BC1\u0BB3\u0BC8 \u0BB8\u0BCD\u0B95\u0BC7\u0BA9\u0BCD \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BB5\u0BC1\u0BAE\u0BCD.'
                : 'Scan the item first.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => _saving = true);

    try {
      final cloudinary = await _uploadToCloudinary(
        _lastCapturedPath!,
      );

      final imageUrl =
          '${cloudinary['secure_url'] ?? ''}';

      if (imageUrl.isEmpty) {
        throw Exception(
          'Cloudinary did not return an image URL',
        );
      }

      final now = DateTime.now();

      final customerId =
          '${widget.profile['customerId'] ?? ''}';

      final customerName =
          '${widget.profile['name'] ?? ''}';

      await FirebaseFirestore.instance
          .collection('scans')
          .add({
        'customerUid': user.uid,
        'customerId': customerId,
        'customerName': customerName,
        'scanDate': dateKey(now),
        'scannedAt': FieldValue.serverTimestamp(),

        'projectVersion': 'Project 2',
        'scanWorkflowVersion': 'project2-simple-broad-v1',

        'material': _collectorSelection,
        'materialSubtype': null,
        'resinCode': null,
        'petCondition': null,

        'aiCategory': _aiSuggestion,
        'aiSubtype': null,
        'aiConfidence': _aiConfidence,
        'modelVersion': 'project2-v3-v4-v5-broad-suggestion',

        'collectorConfirmedMaterial':
            _collectorSelection,
        'customerConfirmedMaterial':
            _collectorSelection,

        'ratePerKg': _selectedRate,
        'customerWeight': _weight,
        'confirmedWeight': null,

        'estimatedAmount': _amount,
        'amount': _amount,

        'paymentStatus': 'Pending',
        'paidAmount': 0.0,
        'receiptNo': null,

        'adminVerified': false,
        'status': 'Pending Verification',

        'trainingEligible': false,
        'adminFinalMaterial': null,
        'aiBroadCorrect': null,
        'trainingLabelSource': null,
        'trainingReviewedAt': null,

        'imageUrl': imageUrl,
        'cloudinaryPublicId':
            cloudinary['public_id'],

        'createdAtClient':
            now.toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tamil
                ? '\u0BB8\u0BCD\u0B95\u0BC7\u0BA9\u0BCD \u0B9A\u0BC7\u0BAE\u0BBF\u0B95\u0BCD\u0B95\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F\u0BA4\u0BC1.'
                : 'Scan saved to history.',
          ),
        ),
      );

      _clearScan();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save scan: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _clearScan() {
    _tts.stop();

    if (!mounted) return;

    setState(() {
      _aiSuggestion = '';
      _aiConfidence = 0;
      _aiSource = '';
      _collectorSelection = null;
      _lastCapturedPath = null;
      _weightController.clear();
    });
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Plastic':
        return Icons.recycling;
      case 'Bottle':
        return Icons.local_drink_outlined;
      case 'Paper':
        return Icons.description_outlined;
      case 'Cardboard':
        return Icons.inventory_2_outlined;
      case 'Glass':
        return Icons.wine_bar_outlined;
      case 'Metal':
        return Icons.hardware_outlined;
      case 'E-Waste':
        return Icons.devices_other;
      case 'Battery':
        return Icons.battery_std;
      case 'Textile':
        return Icons.checkroom_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _categoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _collectorChoices.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.18,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final category = _collectorChoices[index];

        final selected =
            category == _collectorSelection;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectCategory(category),
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? pothigaiGreen
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? pothigaiGreen
                    : const Color(0xFFC8E6C9),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(category),
                  color: selected
                      ? Colors.white
                      : pothigaiGreen,
                  size: 30,
                ),
                const SizedBox(height: 6),
                Text(
                  _displayCategory(category),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF173D21),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _aiSuggestionCard() {
    if (_aiSuggestion.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.tamil
                ? '\u0B92\u0BB0\u0BC1 \u0BAA\u0BCA\u0BB0\u0BC1\u0BB3\u0BC8 \u0BAE\u0B9F\u0BCD\u0B9F\u0BC1\u0BAE\u0BCD \u0B95\u0BC7\u0BAE\u0BB0\u0BBE\u0BB5\u0BBF\u0BB2\u0BCD \u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BBF SCAN \u0B85\u0BB4\u0BC1\u0BA4\u0BCD\u0BA4\u0BB5\u0BC1\u0BAE\u0BCD.'
                : 'Show ONE item clearly to the camera and tap SCAN.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.tamil
                  ? '\u0B9A\u0BC6\u0BAF\u0BB2\u0BBF \u0BAA\u0BB0\u0BBF\u0BA8\u0BCD\u0BA4\u0BC1\u0BB0\u0BC8'
                  : 'APP SUGGESTION',
              style: const TextStyle(
                color: Color(0xFF4E6E55),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _displayCategory(_aiSuggestion),
              style: const TextStyle(
                color: pothigaiGreen,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_aiConfidence * 100).toStringAsFixed(0)}% \u2022 $_aiSource',
            ),
            const SizedBox(height: 8),
            Text(
              widget.tamil
                  ? '\u0B87\u0BA4\u0BC1 \u0B92\u0BB0\u0BC1 \u0BAA\u0BB0\u0BBF\u0BA8\u0BCD\u0BA4\u0BC1\u0BB0\u0BC8 \u0BAE\u0B9F\u0BCD\u0B9F\u0BC1\u0BAE\u0BCD. \u0B95\u0BC0\u0BB4\u0BC7 \u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0BB5\u0B95\u0BC8\u0BAF\u0BC8 \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD.'
                  : 'This is only a suggestion. Collector chooses the final broad category.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateAndWeightCard() {
    final category = _collectorSelection;

    if (category == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFFF1F8E9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: pothigaiGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.tamil
                        ? '\u0BA4\u0BC7\u0BB0\u0BCD\u0BB5\u0BC1: ${_displayCategory(category)}'
                        : 'Selected: $category',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.tamil ? '\u0B87\u0BAF\u0BB2\u0BCD\u0BAA\u0BC1\u0BA8\u0BBF\u0BB2\u0BC8 \u0BB5\u0BBF\u0BB2\u0BC8' : 'Default rate'}: '
              '\u20B9${_selectedRate.toStringAsFixed(2)}/kg',
              style: const TextStyle(
                color: pothigaiGreen,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.tamil
                    ? '\u0B8E\u0B9F\u0BC8 (kg)'
                    : 'Weight (kg)',
                prefixIcon:
                    const Icon(Icons.scale_outlined),
                border:
                    const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pothigaiGreen,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    widget.tamil
                        ? '\u0B95\u0BA3\u0B95\u0BCD\u0B95\u0BBF\u0B9F\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F \u0BA4\u0BCA\u0B95\u0BC8'
                        : 'Calculated amount',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u20B9${_amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : _saveScan,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.cloud_upload,
                    ),
              label: Text(
                _saving
                    ? (widget.tamil
                        ? '\u0B9A\u0BC7\u0BAE\u0BBF\u0B95\u0BCD\u0B95\u0BBF\u0BB1\u0BA4\u0BC1...'
                        : 'SAVING...')
                    : (widget.tamil
                        ? '\u0BB5\u0BB0\u0BB2\u0BBE\u0BB1\u0BCD\u0BB1\u0BBF\u0BB2\u0BCD \u0B9A\u0BC7\u0BAE\u0BBF'
                        : 'SAVE TO HISTORY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _controller?.dispose();
    _v3Interpreter?.close();
    _v4Interpreter?.close();
    _v5Interpreter?.close();
    _imageLabeler.close();
    _tts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8F4),
      child: Column(
        children: [
          SizedBox(
            height: 245,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_ready && _controller != null)
                  CameraPreview(_controller!)
                else
                  Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: pothigaiGreen,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    onPressed:
                        _scanning ? null : _scan,
                    icon: _scanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.center_focus_strong,
                          ),
                    label: Text(
                      _scanning
                          ? (widget.tamil
                              ? '\u0BB8\u0BCD\u0B95\u0BC7\u0BA9\u0BCD \u0B9A\u0BC6\u0BAF\u0BCD\u0B95\u0BBF\u0BB1\u0BA4\u0BC1...'
                              : 'SCANNING...')
                          : (widget.tamil
                              ? '\u0BAA\u0BCA\u0BB0\u0BC1\u0BB3\u0BC8 \u0BB8\u0BCD\u0B95\u0BC7\u0BA9\u0BCD \u0B9A\u0BC6\u0BAF\u0BCD'
                              : 'SCAN MATERIAL'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _aiSuggestionCard(),
                const SizedBox(height: 10),
                Text(
                  widget.tamil
                      ? '\u0B9A\u0BC7\u0B95\u0BB0\u0BBF\u0BAA\u0BCD\u0BAA\u0BB5\u0BB0\u0BCD: \u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0BB5\u0B95\u0BC8\u0BAF\u0BC8 \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD'
                      : 'Collector: choose the correct category',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _categoryGrid(),
                const SizedBox(height: 12),
                _rateAndWeightCard(),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: Text(
                    widget.tamil
                        ? '\u0B87\u0BAF\u0BB2\u0BCD\u0BAA\u0BC1\u0BA8\u0BBF\u0BB2\u0BC8 \u0BB5\u0BBF\u0BB2\u0BC8 \u0BAA\u0B9F\u0BCD\u0B9F\u0BBF\u0BAF\u0BB2\u0BCD'
                        : 'Default rate list',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: _defaultRates.entries
                      .map(
                        (entry) => ListTile(
                          dense: true,
                          title: Text(
                            _displayCategory(
                              entry.key,
                            ),
                          ),
                          trailing: Text(
                            '\u20B9${entry.value.toStringAsFixed(2)}/kg',
                            style: const TextStyle(
                              color: pothigaiGreen,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                OutlinedButton.icon(
                  onPressed: _clearScan,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    widget.tamil
                        ? '\u0BAA\u0BC1\u0BA4\u0BBF\u0BAF \u0BB8\u0BCD\u0B95\u0BC7\u0BA9\u0BCD'
                        : 'CLEAR & NEW SCAN',
                  ),
                ),
                const SizedBox(height: 18),
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
        'requestedWeightKg': firstNumberFromText(_quantityController.text.trim()),
        'pickedUpWeightKg': 0.0,
        'pickupStatus': 'Requested',
        'assignedCollector': null,
        'pickupNotes': '',
        'paymentStatus': 'Pending',
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'status': 'Requested',
        'pickupOtp': '${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}',
        'pickupVerificationStatus': 'Pending',
        'collectorReference': null,
        'vehicleReference': null,
        'assignedAt': null,
        'enRouteAt': null,
        'arrivedAt': null,
        'weighedAt': null,
        'pickedUpAt': null,
        'closedAt': null,
        'cancelledAt': null,
        'roadmap1Version': '1.0',
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
            widget.tamil ? '\u0B95\u0BB4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BC7\u0B95\u0BB0\u0BBF\u0BAA\u0BCD\u0BAA\u0BC1 \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1' : 'Book Waste Pickup',
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
                    Chip(label: Text('Verified total \u20B9${dailyTotal.toStringAsFixed(2)}')),
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
    final paymentStatus = '${data['paymentStatus'] ?? (verified ? 'Pending' : 'Not ready')}';

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
                  Text('Rate: \u20B9${rate.toStringAsFixed(2)}/kg'),
                  if (verified) Text('Verified weight: ${weight.toStringAsFixed(2)} kg'),
                  if (verified)
                    Text(
                      'Payable: \u20B9${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: pothigaiGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (verified) Text('Payment: $paymentStatus'),
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
          tamil ? '\u0BAA\u0B9A\u0BC1\u0BAE\u0BC8 \u0BB5\u0BB4\u0BBF\u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BBF' : 'Green Guide',
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
            subtitle: Text('1 = PET \u2022 2 = HDPE \u2022 4 = LDPE \u2022 5 = PP'),
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

class _CustomerSummaryStats {
  const _CustomerSummaryStats({
    required this.customerId,
    required this.customerName,
    required this.scanCount,
    required this.verifiedKg,
    required this.pickedUpKg,
    required this.payable,
    required this.paid,
    required this.pendingPayment,
    required this.pendingPickupCount,
  });

  final String customerId;
  final String customerName;
  final int scanCount;
  final double verifiedKg;
  final double pickedUpKg;
  final double payable;
  final double paid;
  final double pendingPayment;
  final int pendingPickupCount;

  double get pendingPickupKg {
    final value = verifiedKg - pickedUpKg;
    return value > 0 ? value : 0;
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? _selectedCustomerId;
  String? _selectedDate;

  _CustomerSummaryStats _buildCustomerStats({
    required String customerId,
    required String customerName,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> scans,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> pickups,
  }) {
    final customerScans = scans
        .where((doc) => '${doc.data()['customerId'] ?? ''}' == customerId)
        .toList();
    final customerPickups = pickups
        .where((doc) => '${doc.data()['customerId'] ?? ''}' == customerId)
        .toList();

    final verifiedKg = customerScans.fold<double>(0, (sum, doc) {
      final data = doc.data();
      if (data['adminVerified'] != true) return sum;
      return sum + asDouble(data['confirmedWeight']);
    });

    final payable = customerScans.fold<double>(
      0,
      (sum, doc) => sum + asDouble(doc.data()['amount']),
    );

    final paid = customerScans.fold<double>(0, (sum, doc) {
      final data = doc.data();
      if ('${data['paymentStatus'] ?? ''}'.toLowerCase() != 'paid') return sum;
      return sum + asDouble(data['paidAmount'] ?? data['amount']);
    });

    final pickedUpKg = customerPickups.fold<double>(0, (sum, doc) {
      return sum + asDouble(doc.data()['pickedUpWeightKg']);
    });

    final pendingPickupCount = customerPickups.where((doc) {
      final status = '${doc.data()['pickupStatus'] ?? doc.data()['status'] ?? 'Requested'}';
      return status != 'Picked Up' && status != 'Closed' && status != 'Cancelled';
    }).length;

    return _CustomerSummaryStats(
      customerId: customerId,
      customerName: customerName,
      scanCount: customerScans.length,
      verifiedKg: verifiedKg,
      pickedUpKg: pickedUpKg,
      payable: payable,
      paid: paid,
      pendingPayment: (payable - paid) > 0 ? payable - paid : 0,
      pendingPickupCount: pendingPickupCount,
    );
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
              'Customers \u2022 Scans \u2022 Pickups \u2022 Payments',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Roadmap-1',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Roadmap1HubPage(
                    profile: widget.profile,
                    isAdmin: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.hasError) {
            return Center(child: Text('Unable to load customers: ${usersSnapshot.error}'));
          }
          if (!usersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('scans').snapshots(),
            builder: (context, scansSnapshot) {
              if (scansSnapshot.hasError) {
                return Center(child: Text('Unable to load scans: ${scansSnapshot.error}'));
              }
              if (!scansSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('pickup_requests').snapshots(),
                builder: (context, pickupsSnapshot) {
                  if (pickupsSnapshot.hasError) {
                    return Center(child: Text('Unable to load pickups: ${pickupsSnapshot.error}'));
                  }
                  if (!pickupsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userDocs = usersSnapshot.data!.docs;
                  final scanDocs = scansSnapshot.data!.docs.toList()
                    ..sort((a, b) => timestampToDate(b.data()['scannedAt'])
                        .compareTo(timestampToDate(a.data()['scannedAt'])));
                  final pickupDocs = pickupsSnapshot.data!.docs.toList();

                  final customerMap = <String, String>{};
                  final adminCustomerIds = <String>{};
                  for (final doc in userDocs) {
                    final data = doc.data();
                    final id = '${data['customerId'] ?? ''}'.trim();
                    final role = '${data['role'] ?? 'customer'}'.toLowerCase();
                    final isAdminUser = role == 'admin' ||
                        isPothigaiAdminIdentity(
                          email: '${data['email'] ?? ''}',
                          phone: '${data['phone'] ?? ''}',
                        );
                    if (isAdminUser) {
                      if (id.isNotEmpty) adminCustomerIds.add(id);
                      continue;
                    }
                    final name = '${data['name'] ?? ''}'.trim();
                    if (id.isNotEmpty) customerMap[id] = name;
                  }

                  for (final doc in scanDocs) {
                    final data = doc.data();
                    final id = '${data['customerId'] ?? ''}'.trim();
                    final name = '${data['customerName'] ?? ''}'.trim();
                    if (id.isNotEmpty && !adminCustomerIds.contains(id)) {
                      customerMap.putIfAbsent(id, () => name);
                    }
                  }

                  final customerIds = customerMap.keys.toList()..sort();
                  if (_selectedCustomerId != null &&
                      !customerIds.contains(_selectedCustomerId)) {
                    _selectedCustomerId = null;
                    _selectedDate = null;
                  }

                  final summaries = customerIds.map((id) {
                    return _buildCustomerStats(
                      customerId: id,
                      customerName: customerMap[id] ?? '',
                      scans: scanDocs,
                      pickups: pickupDocs,
                    );
                  }).toList();

                  final totalEnrolled = summaries.length;
                  final customersWithScans = summaries.where((s) => s.scanCount > 0).length;
                  final totalVerifiedKg = summaries.fold<double>(0, (sum, s) => sum + s.verifiedKg);
                  final totalPickedUpKg = summaries.fold<double>(0, (sum, s) => sum + s.pickedUpKg);
                  final totalPendingKg = summaries.fold<double>(0, (sum, s) => sum + s.pendingPickupKg);
                  final totalPayable = summaries.fold<double>(0, (sum, s) => sum + s.payable);
                  final totalPaid = summaries.fold<double>(0, (sum, s) => sum + s.paid);
                  final totalPendingPayment = summaries.fold<double>(0, (sum, s) => sum + s.pendingPayment);

                  final selectedSummary = _selectedCustomerId == null
                      ? null
                      : summaries.where((s) => s.customerId == _selectedCustomerId).cast<_CustomerSummaryStats?>().firstWhere(
                            (e) => e != null,
                            orElse: () => null,
                          );

                  final selectedScans = _selectedCustomerId == null
                      ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
                      : scanDocs.where((doc) {
                          return '${doc.data()['customerId'] ?? ''}' == _selectedCustomerId;
                        }).toList();

                  final availableDates = selectedScans
                      .map((doc) => '${doc.data()['scanDate'] ?? ''}'.trim())
                      .where((date) => date.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort((a, b) => b.compareTo(a));

                  if (_selectedDate != null && !availableDates.contains(_selectedDate)) {
                    _selectedDate = null;
                  }

                  final visibleScans = selectedScans.where((doc) {
                    if (_selectedDate == null) return true;
                    return '${doc.data()['scanDate'] ?? ''}' == _selectedDate;
                  }).toList();

                  final selectedPickups = _selectedCustomerId == null
                      ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
                      : pickupDocs.where((doc) {
                          return '${doc.data()['customerId'] ?? ''}' == _selectedCustomerId;
                        }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCustomerId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select customer',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_search),
                              ),
                              hint: const Text('Select a customer to view details'),
                              items: customerIds.map((customerId) {
                                final name = customerMap[customerId] ?? '';
                                return DropdownMenuItem<String>(
                                  value: customerId,
                                  child: Text(
                                    name.isEmpty ? customerId : '$customerId \u2022 $name',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCustomerId = value;
                                  _selectedDate = null;
                                });
                              },
                            ),
                            if (_selectedCustomerId != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedDate,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Select scanned date',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.calendar_month),
                                      ),
                                      hint: const Text('All scanned dates'),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('All scanned dates'),
                                        ),
                                        ...availableDates.map(
                                          (date) => DropdownMenuItem<String>(
                                            value: date,
                                            child: Text(date),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) => setState(() => _selectedDate = value),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    tooltip: 'Clear customer selection',
                                    onPressed: () {
                                      setState(() {
                                        _selectedCustomerId = null;
                                        _selectedDate = null;
                                      });
                                    },
                                    icon: const Icon(Icons.dashboard_outlined),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedCustomerId == null
                            ? _AdminOverallSummary(
                                totalEnrolled: totalEnrolled,
                                customersWithScans: customersWithScans,
                                totalVerifiedKg: totalVerifiedKg,
                                totalPickedUpKg: totalPickedUpKg,
                                totalPendingKg: totalPendingKg,
                                totalPayable: totalPayable,
                                totalPaid: totalPaid,
                                totalPendingPayment: totalPendingPayment,
                                summaries: summaries,
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                                children: [
                                  if (selectedSummary != null)
                                    _CustomerSummaryCard(stats: selectedSummary),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Pickup workflow',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (selectedPickups.isEmpty)
                                    const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No pickup requests for this customer.'),
                                      ),
                                    )
                                  else
                                    ...selectedPickups.map(
                                      (doc) => AdminPickupCard(docId: doc.id, data: doc.data()),
                                    ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Scanned items${_selectedDate == null ? '' : ' \u2022 $_selectedDate'}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (visibleScans.isEmpty)
                                    const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No scans for this selection.'),
                                      ),
                                    )
                                  else
                                    ...visibleScans.map(
                                      (doc) => AdminScanCard(docId: doc.id, data: doc.data()),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminOverallSummary extends StatelessWidget {
  const _AdminOverallSummary({
    required this.totalEnrolled,
    required this.customersWithScans,
    required this.totalVerifiedKg,
    required this.totalPickedUpKg,
    required this.totalPendingKg,
    required this.totalPayable,
    required this.totalPaid,
    required this.totalPendingPayment,
    required this.summaries,
  });

  final int totalEnrolled;
  final int customersWithScans;
  final double totalVerifiedKg;
  final double totalPickedUpKg;
  final double totalPendingKg;
  final double totalPayable;
  final double totalPaid;
  final double totalPendingPayment;
  final List<_CustomerSummaryStats> summaries;

  Widget _metric(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: pothigaiGreen),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
        Text(
          'Operations dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.65,
          children: [
            _metric('Customers enrolled', '$totalEnrolled', Icons.people_alt_outlined),
            _metric('Customers with scans', '$customersWithScans', Icons.qr_code_scanner),
            _metric('Verified scanned', '${totalVerifiedKg.toStringAsFixed(2)} kg', Icons.scale),
            _metric('Picked up', '${totalPickedUpKg.toStringAsFixed(2)} kg', Icons.local_shipping),
            _metric('Awaiting pickup', '${totalPendingKg.toStringAsFixed(2)} kg', Icons.hourglass_bottom),
            _metric('Total payable', '\u20B9${totalPayable.toStringAsFixed(2)}', Icons.receipt_long),
            _metric('Paid', '\u20B9${totalPaid.toStringAsFixed(2)}', Icons.task_alt),
            _metric('Pending payment', '\u20B9${totalPendingPayment.toStringAsFixed(2)}', Icons.pending_actions),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Customer summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (summaries.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No customers enrolled.')))
        else
          ...summaries.map((stats) => _CustomerSummaryCard(stats: stats)),
      ],
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({required this.stats});

  final _CustomerSummaryStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stats.customerName.isEmpty
                  ? stats.customerId
                  : '${stats.customerId} \u2022 ${stats.customerName}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('Scans: ${stats.scanCount}'),
                Text('Verified: ${stats.verifiedKg.toStringAsFixed(2)} kg'),
                Text('Picked up: ${stats.pickedUpKg.toStringAsFixed(2)} kg'),
                Text('Awaiting: ${stats.pendingPickupKg.toStringAsFixed(2)} kg'),
                Text('Open pickups: ${stats.pendingPickupCount}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Payable: \u20B9${stats.payable.toStringAsFixed(2)}'),
            Text(
              'Paid: \u20B9${stats.paid.toStringAsFixed(2)} \u2022 Pending: \u20B9${stats.pendingPayment.toStringAsFixed(2)}',
              style: const TextStyle(color: pothigaiGreen, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPickupCard extends StatelessWidget {
  const AdminPickupCard({
    super.key,
    required this.docId,
    required this.data,
  });

  final String docId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final requestedKg = asDouble(data['requestedWeightKg']);
    final pickedUpKg = asDouble(data['pickedUpWeightKg']);
    final status = '${data['pickupStatus'] ?? data['status'] ?? 'Requested'}';
    final category = '${data['category'] ?? ''}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_shipping, color: pothigaiGreen),
        title: Text(category.isEmpty ? 'Pickup request' : category),
        subtitle: Text(
          'Requested: ${requestedKg.toStringAsFixed(2)} kg \u2022 Picked up: ${pickedUpKg.toStringAsFixed(2)} kg\n$status',
        ),
        isThreeLine: true,
        trailing: FilledButton.tonal(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AdminPickupDialog(docId: docId, initialData: data),
          ),
          child: const Text('MANAGE'),
        ),
      ),
    );
  }
}

class AdminPickupDialog extends StatefulWidget {
  const AdminPickupDialog({
    super.key,
    required this.docId,
    required this.initialData,
  });

  final String docId;
  final Map<String, dynamic> initialData;

  @override
  State<AdminPickupDialog> createState() => _AdminPickupDialogState();
}

class _AdminPickupDialogState extends State<AdminPickupDialog> {
  static const statuses = [
    'Requested',
    'Assigned',
    'En Route',
    'Arrived',
    'Weighed',
    'Picked Up',
    'Closed',
    'Cancelled',
  ];

  late final TextEditingController _weightController;
  late final TextEditingController _collectorController;
  late final TextEditingController _notesController;
  late String _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = asDouble(widget.initialData['pickedUpWeightKg']);
    final requested = asDouble(widget.initialData['requestedWeightKg']);
    _weightController = TextEditingController(
      text: existing > 0
          ? existing.toStringAsFixed(2)
          : (requested > 0 ? requested.toStringAsFixed(2) : ''),
    );
    _collectorController = TextEditingController(
      text: '${widget.initialData['assignedCollector'] ?? ''}',
    );
    _notesController = TextEditingController(
      text: '${widget.initialData['pickupNotes'] ?? ''}',
    );
    final initial = '${widget.initialData['pickupStatus'] ?? widget.initialData['status'] ?? 'Requested'}';
    _status = statuses.contains(initial) ? initial : 'Requested';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _collectorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    if ((_status == 'Weighed' || _status == 'Picked Up' || _status == 'Closed') && weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter actual weight before completing pickup')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final update = <String, dynamic>{
        'pickedUpWeightKg': (_status == 'Picked Up' || _status == 'Closed') ? weight : asDouble(widget.initialData['pickedUpWeightKg']),
        'pickupStatus': _status,
        'status': _status,
        'assignedCollector': _collectorController.text.trim(),
        'pickupNotes': _notesController.text.trim(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
      };
      if (_status == 'Picked Up' || _status == 'Closed') {
        update['pickedUpAt'] = FieldValue.serverTimestamp();
        update['pickedUpBy'] = FirebaseAuth.instance.currentUser?.uid;
      }

      await FirebaseFirestore.instance
          .collection('pickup_requests')
          .doc(widget.docId)
          .update(update);

      await FirebaseFirestore.instance.collection('audit_logs').add({
        'entityType': 'pickup',
        'entityId': widget.docId,
        'action': 'Pickup status changed to $_status',
        'customerId': widget.initialData['customerId'],
        'performedBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pickup update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage pickup'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Pickup status',
                border: OutlineInputBorder(),
              ),
              items: statuses
                  .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              onChanged: _busy ? null : (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _collectorController,
              decoration: const InputDecoration(
                labelText: 'Collector / vehicle reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Actual pickup weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Pickup notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'SAVING...' : 'SAVE'),
        ),
      ],
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
        child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
      ),
    );
  }

  Future<void> _openReview(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AdminReviewSheet(docId: docId, initialData: data),
    );
  }

  Future<void> _markPaid(BuildContext context) async {
    final referenceController = TextEditingController();
    final amount = asDouble(data['amount']);
    final customerId = '${data['customerId'] ?? ''}';
    final receiptNo = 'PG-${DateTime.now().millisecondsSinceEpoch}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark payment as paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: $customerId'),
            Text('Amount: \u20B9${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'UPI / cash / transaction reference',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('MARK PAID')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('scans').doc(docId).update({
        'paymentStatus': 'Paid',
        'paidAmount': amount,
        'paidAt': FieldValue.serverTimestamp(),
        'paymentReference': referenceController.text.trim(),
        'receiptNo': receiptNo,
        'paidBy': FirebaseAuth.instance.currentUser?.uid,
      });
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'entityType': 'scan',
        'entityId': docId,
        'action': 'Payment marked Paid',
        'customerId': customerId,
        'amount': amount,
        'receiptNo': receiptNo,
        'performedBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      _showReceipt(context, receiptNo, amount, referenceController.text.trim());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment update failed: $e')));
    } finally {
      referenceController.dispose();
    }
  }

  void _showReceipt(BuildContext context, String receiptNo, double amount, String reference) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment receipt'),
        content: SelectableText(
          'Pothigai Green\n'
          'Receipt: $receiptNo\n'
          'Customer: ${data['customerId'] ?? ''} \u2022 ${data['customerName'] ?? ''}\n'
          'Material: ${data['material'] ?? ''}\n'
          'Weight: ${asDouble(data['confirmedWeight']).toStringAsFixed(2)} kg\n'
          'Rate: \u20B9${asDouble(data['ratePerKg']).toStringAsFixed(2)}/kg\n'
          'Paid: \u20B9${amount.toStringAsFixed(2)}\n'
          'Reference: ${reference.isEmpty ? 'Cash / not entered' : reference}',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${data['imageUrl'] ?? ''}';
    final customerId = '${data['customerId'] ?? ''}';
    final customerName = '${data['customerName'] ?? ''}';
    final material = '${data['material'] ?? ''}';
    final grade = '${data['materialGrade'] ?? ''}';
    final scanDate = '${data['scanDate'] ?? ''}';
    final status = '${data['status'] ?? ''}';
    final amount = asDouble(data['amount']);
    final weight = asDouble(data['confirmedWeight']);
    final rate = asDouble(data['ratePerKg']);
    final verified = data['adminVerified'] == true;
    final paymentStatus = '${data['paymentStatus'] ?? (verified ? 'Pending' : 'Not ready')}';
    final receiptNo = '${data['receiptNo'] ?? ''}';

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
                    '$customerId \u2022 $customerName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$scanDate \u2022 $material${grade.isEmpty ? '' : ' \u2022 $grade'}'),
                  Text('Status: $status'),
                  if (verified) ...[
                    Text('Weight: ${weight.toStringAsFixed(2)} kg'),
                    Text('Rate: \u20B9${rate.toStringAsFixed(2)}/kg'),
                    Text(
                      'Payable \u20B9${amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: pothigaiGreen, fontWeight: FontWeight.bold),
                    ),
                    Text('Payment: $paymentStatus'),
                    if (receiptNo.isNotEmpty) Text('Receipt: $receiptNo'),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _openReview(context),
                        icon: const Icon(Icons.fact_check),
                        label: Text(verified ? 'REVIEW' : 'VERIFY'),
                      ),
                      if (verified && paymentStatus != 'Paid')
                        FilledButton.icon(
                          onPressed: () => _markPaid(context),
                          icon: const Icon(Icons.payments),
                          label: const Text('MARK PAID'),
                        ),
                      if (paymentStatus == 'Paid' && receiptNo.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _showReceipt(
                            context,
                            receiptNo,
                            asDouble(data['paidAmount'] ?? amount),
                            '${data['paymentReference'] ?? ''}',
                          ),
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('RECEIPT'),
                        ),
                    ],
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

class AdminReviewSheet extends StatefulWidget {
  const AdminReviewSheet({
    super.key,
    required this.docId,
    required this.initialData,
  });

  final String docId;
  final Map<String, dynamic> initialData;

  @override
  State<AdminReviewSheet> createState() => _AdminReviewSheetState();
}

class _AdminReviewSheetState extends State<AdminReviewSheet> {
  static const materials = [
    'PET',
    'HDPE',
    'LDPE',
    'PP',
    'Other Plastic',
    'Paper',
    'Cardboard',
    'Glass',
    'Metal',
    'Textile',
    'Rubber',
    'Foam',
    'Wood',
    'E-Waste',
    'Battery',
    'Organic',
    'Mixed',
    'Unknown',
    'Other',
  ];

  static const grades = [
    'Standard',
    'Clean',
    'Contaminated',
    'Clear',
    'Colored',
    'Mixed',
    'Damaged',
  ];

  late String _material;
  late String _grade;
  String _petCondition = 'Uncrushed';
  late TextEditingController _weightController;
  late TextEditingController _rateController;
  bool _busy = false;
  double _previewAmount = 0;

  @override
  void initState() {
    super.initState();
    final initialMaterial = '${widget.initialData['material'] ?? 'Other'}';
    _material = materials.contains(initialMaterial) ? initialMaterial : 'Other';
    final initialGrade = '${widget.initialData['materialGrade'] ?? 'Standard'}';
    _grade = grades.contains(initialGrade) ? initialGrade : 'Standard';

    _petCondition = '${widget.initialData['petCondition'] ?? 'Uncrushed'}';
    if (_petCondition != 'Crushed' && _petCondition != 'Uncrushed') {
      _petCondition = 'Uncrushed';
    }

    _weightController = TextEditingController(
      text: asDouble(widget.initialData['confirmedWeight']) > 0
          ? asDouble(widget.initialData['confirmedWeight']).toStringAsFixed(2)
          : '',
    );
    final existingRate = asDouble(widget.initialData['ratePerKg']);
    _rateController = TextEditingController(
      text: existingRate > 0
          ? existingRate.toStringAsFixed(2)
          : _defaultRate().toStringAsFixed(2),
    );
    _weightController.addListener(_recalculatePreview);
    _rateController.addListener(_recalculatePreview);
    _recalculatePreview();
  }

  @override
  void dispose() {
    _weightController.removeListener(_recalculatePreview);
    _rateController.removeListener(_recalculatePreview);
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

  void _recalculatePreview() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final amount = weight * rate;
    if (mounted && amount != _previewAmount) {
      setState(() => _previewAmount = amount);
    }
  }

  void _applySuggestedRate() {
    _rateController.text = _defaultRate().toStringAsFixed(2);
    _recalculatePreview();
  }

  Future<void> _approve() async {
    FocusScope.of(context).unfocus();
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
      final beforeMaterial = '${widget.initialData['material'] ?? ''}';
      final beforeWeight = asDouble(widget.initialData['confirmedWeight']);
      final beforeRate = asDouble(widget.initialData['ratePerKg']);

      final aiCategory = '${widget.initialData['aiCategory'] ?? ''}'.toLowerCase();
      final aiBroadCorrect =
          (aiCategory == 'paper' && _material == 'Paper') ||
          (aiCategory == 'cardboard' && _material == 'Cardboard') ||
          (aiCategory == 'glass' && _material == 'Glass') ||
          (aiCategory == 'metal' && _material == 'Metal') ||
          (aiCategory == 'textile' && _material == 'Textile') ||
          (aiCategory == 'rubber' && _material == 'Rubber') ||
          (aiCategory == 'foam' && _material == 'Foam') ||
          (aiCategory == 'wood' && _material == 'Wood') ||
          (aiCategory == 'organic' && _material == 'Organic') ||
          (aiCategory == 'mixed' && _material == 'Mixed') ||
          (aiCategory == 'ewaste' && _material == 'E-Waste') ||
          (aiCategory == 'battery' && _material == 'Battery') ||
          ((aiCategory == 'bottle' || aiCategory == 'plastic') &&
              const ['PET', 'HDPE', 'LDPE', 'PP', 'Other Plastic']
                  .contains(_material));

      await FirebaseFirestore.instance.collection('scans').doc(widget.docId).update({
        'material': _material,
        'materialGrade': _grade,
        'petCondition': _material == 'PET' ? _petCondition : null,
        'ratePerKg': rate,
        'confirmedWeight': weight,
        'amount': amount,
        'adminVerified': true,
        'status': 'Verified',
        'paymentStatus': widget.initialData['paymentStatus'] ?? 'Pending',
        'adminFinalMaterial': _material,
        'aiBroadCorrect': aiBroadCorrect,
        'trainingEligible': true,
        'trainingLabelSource': 'admin_verified',
        'trainingReviewedAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      await FirebaseFirestore.instance.collection('audit_logs').add({
        'entityType': 'scan',
        'entityId': widget.docId,
        'action': 'Scan verified',
        'customerId': widget.initialData['customerId'],
        'before': {
          'material': beforeMaterial,
          'weight': beforeWeight,
          'rate': beforeRate,
        },
        'after': {
          'material': _material,
          'grade': _grade,
          'weight': weight,
          'rate': rate,
          'amount': amount,
        },
        'performedBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verified: ${weight.toStringAsFixed(2)} kg \u00D7 \u20B9${rate.toStringAsFixed(2)} = \u20B9${amount.toStringAsFixed(2)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('scans').doc(widget.docId).update({
        'amount': 0.0,
        'confirmedWeight': null,
        'adminVerified': false,
        'paymentStatus': 'Not payable',
        'status': 'Rejected',
        'trainingEligible': false,
        'trainingLabelSource': 'admin_rejected',
        'trainingReviewedAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'entityType': 'scan',
        'entityId': widget.docId,
        'action': 'Scan rejected',
        'customerId': widget.initialData['customerId'],
        'performedBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${widget.initialData['imageUrl'] ?? ''}';
    final customerId = '${widget.initialData['customerId'] ?? ''}';
    final customerName = '${widget.initialData['customerName'] ?? ''}';
    final scanDate = '${widget.initialData['scanDate'] ?? ''}';
    final confidence = asDouble(widget.initialData['aiConfidence']);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify $customerId',
                          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                        ),
                        Text('$customerName \u2022 $scanDate'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 120,
                            child: Center(child: Icon(Icons.broken_image, size: 50)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'AI confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _material,
                      decoration: const InputDecoration(
                        labelText: 'Verified material',
                        prefixIcon: Icon(Icons.recycling),
                        border: OutlineInputBorder(),
                      ),
                      items: materials
                          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _material = value);
                              _applySuggestedRate();
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _grade,
                      decoration: const InputDecoration(
                        labelText: 'Material grade / quality',
                        prefixIcon: Icon(Icons.grade_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: grades
                          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                          .toList(),
                      onChanged: _busy ? null : (value) => setState(() => _grade = value ?? _grade),
                    ),
                    if (_material == 'PET') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _petCondition,
                        decoration: const InputDecoration(
                          labelText: 'PET condition',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Crushed', child: Text('Crushed')),
                          DropdownMenuItem(value: 'Uncrushed', child: Text('Uncrushed')),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _petCondition = value);
                                _applySuggestedRate();
                              },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _weightController,
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Verified weight (kg)',
                        hintText: 'Example: 2.50',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Rate per kg (\u20B9)',
                        hintText: 'Example: 12.00',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _applySuggestedRate,
                        icon: const Icon(Icons.price_change),
                        label: const Text('USE SUGGESTED RATE'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Card(
                      color: const Color(0xFFE8F5E9),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate, color: pothigaiGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Calculated payable: \u20B9${_previewAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _reject,
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('REJECT', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _approve,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.verified),
                            label: Text(_busy ? 'SAVING...' : 'VERIFY & CALCULATE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}