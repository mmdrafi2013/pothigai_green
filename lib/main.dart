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

        if (user == null) {
          return const AuthPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _BusyScreen(
                message: 'Loading profile...',
              );
            }

            if (profileSnapshot.hasError) {
              return MissingProfilePage(
                message:
                    'Unable to load your profile: ${profileSnapshot.error}',
              );
            }

            final profile = profileSnapshot.data?.data();

            if (profile == null) {
              return const _BusyScreen(
                message: 'Creating customer profile...',
              );
            }

            final role =
                '${profile['role'] ?? 'customer'}'.toLowerCase();

            final isAdmin = role == 'admin' ||
                isPothigaiAdminIdentity(
                  email:
                      '${profile['email'] ?? user.email ?? ''}',
                  phone:
                      '${profile['phone'] ?? ''}',
                );

            if (isAdmin) {
              if (role != 'admin') {
                Future.microtask(
                  () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set(
                        {
                          'role': 'admin',
                          'adminGrantedByIdentity': true,
                          'adminUpdatedAt':
                              FieldValue.serverTimestamp(),
                        },
                        SetOptions(
                          merge: true,
                        ),
                      );
                    } catch (e) {
                      debugPrint(
                        'Unable to persist admin role: $e',
                      );
                    }
                  },
                );
              }

              final adminProfile =
                  Map<String, dynamic>.from(
                profile,
              );

              adminProfile['role'] = 'admin';

              return AdminHome(
                profile: adminProfile,
              );
            }

            return CustomerShell(
              profile: profile,
            );
          },
        );
      },
    );
  }
}

class _BusyScreen extends StatelessWidget {
  const _BusyScreen({
    required this.message,
  });

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
  const MissingProfilePage({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pothigai Green'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 70,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  FirebaseAuth.instance.signOut(),
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
  State<AuthPage> createState() =>
      _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

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
    final counterRef =
        FirebaseFirestore.instance
            .collection('system')
            .doc('customer_counter');

    return FirebaseFirestore.instance
        .runTransaction<String>(
      (transaction) async {
        final snapshot =
            await transaction.get(
          counterRef,
        );

        final current =
            (snapshot.data()?[
                        'nextCustomerNumber']
                    as num?)
                ?.toInt() ??
            1;

        transaction.set(
          counterRef,
          {
            'nextCustomerNumber':
                current + 1,
          },
          SetOptions(
            merge: true,
          ),
        );

        return 'PG${current.toString().padLeft(6, '0')}';
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final email =
          _emailController.text.trim();

      final password =
          _passwordController.text;

      if (_registerMode) {
        final credential =
            await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final customerId =
            await _nextCustomerId();

        final phone =
            _phoneController.text.trim();

        final registrationRole =
            isPothigaiAdminIdentity(
          email: email,
          phone: phone,
        )
                ? 'admin'
                : 'customer';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid':
              credential.user!.uid,
          'customerId':
              customerId,
          'name':
              _nameController.text.trim(),
          'phone':
              phone,
          'email':
              email,
          'role':
              registrationRole,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
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
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    22,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        const Icon(
                          Icons.recycling,
                          size: 62,
                          color:
                              pothigaiGreen,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Pothigai Green',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'பொதிகை பசுமை',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                pothigaiGreen,
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          _registerMode
                              ? 'Create Customer Account'
                              : 'Customer / Admin Login',
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        if (_registerMode) ...[
                          TextFormField(
                            controller:
                                _nameController,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Customer name',
                              border:
                                  OutlineInputBorder(),
                            ),
                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Enter customer name';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          TextFormField(
                            controller:
                                _phoneController,
                            keyboardType:
                                TextInputType.phone,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Phone number',
                              border:
                                  OutlineInputBorder(),
                            ),
                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                          .trim()
                                          .length <
                                      8) {
                                return 'Enter a valid phone number';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                        ],
                        TextFormField(
                          controller:
                              _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Email',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                !value.contains('@')) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextFormField(
                          controller:
                              _passwordController,
                          obscureText:
                              _hidePassword,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Password',
                            border:
                                const OutlineInputBorder(),
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  _hidePassword =
                                      !_hidePassword;
                                });
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            _error!,
                            style:
                                const TextStyle(
                              color:
                                  Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(
                          height: 18,
                        ),
                        FilledButton.icon(
                          onPressed:
                              _busy
                                  ? null
                                  : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _registerMode
                                      ? Icons.person_add
                                      : Icons.login,
                                ),
                          label: Text(
                            _registerMode
                                ? 'REGISTER'
                                : 'LOGIN',
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _busy
                                  ? null
                                  : () {
                                      setState(() {
                                        _registerMode =
                                            !_registerMode;
                                        _error =
                                            null;
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
  const CustomerShell({
    super.key,
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  State<CustomerShell> createState() =>
      _CustomerShellState();
}

class _CustomerShellState
    extends State<CustomerShell> {
  int _index = 0;
  bool _tamil = false;

  @override
  Widget build(BuildContext context) {
    final customerId =
        '${widget.profile['customerId'] ?? ''}';

    final customerName =
        '${widget.profile['name'] ?? 'Customer'}';

    final pages = <Widget>[
      CustomerHomePage(
        tamil: _tamil,
        customerId: customerId,
        customerName: customerName,
        onScan: () {
          setState(() {
            _index = 1;
          });
        },
        onPickup: () {
          setState(() {
            _index = 2;
          });
        },
      ),
      ScannerPage(
        tamil: _tamil,
        profile: widget.profile,
      ),
      PickupPage(
        tamil: _tamil,
        profile: widget.profile,
      ),
      CustomerHistoryPage(
        tamil: _tamil,
        profile: widget.profile,
      ),
      InfoPage(
        tamil: _tamil,
        profile: widget.profile,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              _tamil
                  ? 'பொதிகை பசுமை'
                  : 'Pothigai Green',
            ),
            Text(
              '$customerId • $customerName',
              style:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _tamil = !_tamil;
              });
            },
            child: Text(
              _tamil ? 'EN' : 'தமிழ்',
              style:
                  const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                FirebaseAuth.instance
                    .signOut(),
            icon:
                const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: _index,
        onDestinationSelected:
            (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon:
                const Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
                const Icon(
              Icons.home,
            ),
            label: _tamil
                ? 'முகப்பு'
                : 'Home',
          ),
          NavigationDestination(
            icon:
                const Icon(
              Icons.center_focus_weak,
            ),
            selectedIcon:
                const Icon(
              Icons.center_focus_strong,
            ),
            label: _tamil
                ? 'ஸ்கேன்'
                : 'Scan',
          ),
          NavigationDestination(
            icon:
                const Icon(
              Icons.local_shipping_outlined,
            ),
            selectedIcon:
                const Icon(
              Icons.local_shipping,
            ),
            label: _tamil
                ? 'பிக்கப்'
                : 'Pickup',
          ),
          NavigationDestination(
            icon:
                const Icon(
              Icons.receipt_long_outlined,
            ),
            selectedIcon:
                const Icon(
              Icons.receipt_long,
            ),
            label: _tamil
                ? 'வரலாறு'
                : 'History',
          ),
          NavigationDestination(
            icon:
                const Icon(
              Icons.info_outline,
            ),
            selectedIcon:
                const Icon(
              Icons.info,
            ),
            label: _tamil
                ? 'தகவல்'
                : 'Info',
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
            border: Border.all(
              color: const Color(0xFFC8E6C9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item[0],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
  });

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
      options: ImageLabelerOptions(
        confidenceThreshold: 0.55,
      ),
    );

    _initCamera();
    _initTts();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _result = 'No camera available';
        });
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

      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _result = 'Camera initialization failed';
        });
      }
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _scan() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _scanning) {
      return;
    }

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

      _result = widget.tamil
          ? '3 படங்கள் ஆய்வு செய்யப்படுகிறது...'
          : 'Analyzing 3 frames...';

      _details = '';
      _rateText = '';
      _confidenceText = '';
    });

    try {
      final decisions = <ScanDecision>[];

      for (int i = 0; i < 3; i++) {
        final picture = await _controller!.takePicture();

        _lastCapturedPath = picture.path;

        final inputImage = InputImage.fromFilePath(
          picture.path,
        );

        final labels = await _imageLabeler.processImage(
          inputImage,
        );

        decisions.add(
          _classifyLabels(
            labels,
          ),
        );

        if (i < 2) {
          await Future.delayed(
            const Duration(
              milliseconds: 350,
            ),
          );
        }
      }

      _combineDecisions(
        decisions,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _result = 'SCAN FAILED';
        _details = '$e';
      });
    }
  }

  ScanDecision _classifyLabels(
    List<ImageLabel> sourceLabels,
  ) {
    if (sourceLabels.isEmpty) {
      return const ScanDecision(
        category: 'unknown',
        confidence: 0,
      );
    }

    final labels = sourceLabels.toList()
      ..sort(
        (a, b) => b.confidence.compareTo(
          a.confidence,
        ),
      );

    final topLabels = labels.take(10).toList();

    double findBest(
      List<String> words,
    ) {
      double best = 0;

      for (final label in topLabels) {
        final text = label.label.toLowerCase();

        for (final word in words) {
          if (text.contains(word) &&
              label.confidence > best) {
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
      'battery': findBest([
        'battery',
        'battery charger',
      ]),
      'cardboard': findBest([
        'cardboard',
        'carton',
        'shipping box',
      ]),
      'paper': findBest([
        'paper',
        'newspaper',
        'document',
        'magazine',
        'book',
      ]),
      'bottle': findBest([
        'plastic bottle',
        'water bottle',
        'bottle',
      ]),
      'plastic': findBest([
        'plastic',
        'plastic container',
        'container',
      ]),
    };

    String bestCategory = 'unknown';
    double bestConfidence = 0;

    scores.forEach(
      (category, confidence) {
        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestCategory = category;
        }
      },
    );
    scores.forEach(
      (category, confidence) {
        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestCategory = category;
        }
      },
    );
    if (bestConfidence < minimumConfidence) {
      return ScanDecision(
        category: 'unknown',
        confidence: bestConfidence,
      );
    }

    return ScanDecision(
      category: bestCategory,
      confidence: bestConfidence,
    );
  }

  void _combineDecisions(
    List<ScanDecision> decisions,
  ) {
    final counts = <String, int>{};
    final totals = <String, double>{};

    for (final decision in decisions) {
      counts[decision.category] =
          (counts[decision.category] ?? 0) + 1;

      totals[decision.category] =
          (totals[decision.category] ?? 0) +
              decision.confidence;
    }

    String winningCategory = 'unknown';
    int winningVotes = 0;

    counts.forEach(
      (category, votes) {
        if (votes > winningVotes) {
          winningVotes = votes;
          winningCategory = category;
        }
      },
    );

    final average =
        (totals[winningCategory] ?? 0) /
            (counts[winningCategory] ?? 1);

    _averageConfidence = average;

    if (winningCategory == 'unknown' ||
        winningVotes < 2 ||
        average < minimumConfidence) {
      _showUnknown(
        winningVotes,
        average,
      );

      return;
    }

    _showDetectedResult(
      winningCategory,
      winningVotes,
      average,
    );
  }

  void _showDetectedResult(
    String category,
    int votes,
    double confidence,
  ) {
    String result;
    String details;
    String rate = '';

    bool requiresResin = false;

    switch (category) {
      case 'bottle':
        result = 'BOTTLE DETECTED';

        details =
            'Bottle detected. PET is not confirmed until the resin code is checked.';

        requiresResin = true;

        break;

      case 'plastic':
        result = 'PLASTIC ITEM DETECTED';

        details =
            'Confirm PET / HDPE / LDPE / PP using the resin code.';

        requiresResin = true;

        break;

      case 'paper':
        result = 'PAPER DETECTED';

        details =
            'AI identified this as paper. Confirm before saving.';

        rate = 'Paper: ₹8/kg';

        break;

      case 'cardboard':
        result = 'CARDBOARD DETECTED';

        details =
            'AI identified this as cardboard. Confirm before saving.';

        rate = 'Cardboard: ₹6/kg';

        break;

      case 'ewaste':
        result = 'E-WASTE DETECTED';

        details =
            'Electronic equipment detected. Admin will verify the final rate.';

        rate = 'E-Waste: Admin valuation';

        break;

      case 'battery':
        result = 'BATTERY DETECTED';

        details =
            'Battery detected. Keep it separate for safe recycling.';

        rate = 'Battery: Admin valuation';

        break;

      default:
        _showUnknown(
          votes,
          confidence,
        );

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

      _needsResinConfirmation =
          requiresResin;

      _confidenceText =
          '$votes/3 frames agreed • ${(confidence * 100).toStringAsFixed(0)}% average confidence';
    });
  }

  void _showUnknown(
    int votes,
    double confidence,
  ) {
    if (!mounted) return;

    setState(() {
      _scanning = false;
      _hasResult = true;
      _resultConfirmed = false;
      _needsResinConfirmation = false;
      _needsPetCondition = false;

      _detectedCategory = 'unknown';

      _result =
          'UNKNOWN / MATERIAL CHECK REQUIRED';

      _details =
          'AI confidence is not high enough. Choose the correct material manually.';

      _rateText =
          'No automatic rate';

      _confidenceText =
          '$votes/3 frames agreed • ${(confidence * 100).toStringAsFixed(0)}% confidence';
    });
  }

  double _suggestedRate(
    String material, {
    String? petCondition,
  }) {
    switch (material) {
      case 'PET':
        return petCondition == 'Crushed'
            ? 14
            : 12;

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

  void _confirmResin(
    String code,
    String material,
  ) {
    if (material == 'PET') {
      setState(() {
        _confirmedMaterial = 'PET';
        _resinCode = code;

        _resultConfirmed = false;
        _needsResinConfirmation = false;
        _needsPetCondition = true;

        _result = 'PET CONFIRMED';

        _details =
            'Select whether the PET is crushed or uncrushed.';

        _rateText = '';
      });

      return;
    }

    final rate = _suggestedRate(
      material,
    );

    setState(() {
      _confirmedMaterial = material;
      _resinCode = code;
      _resultConfirmed = true;
      _needsResinConfirmation = false;
      _needsPetCondition = false;
      _confirmedRate = rate;

      _result = '$material CONFIRMED';

      _details =
          'Material confirmed using resin code $code.';

      _rateText = rate > 0
          ? '$material: ₹${rate.toStringAsFixed(0)}/kg'
          : 'Admin valuation';
    });
  }

  void _confirmPetCondition(
    String condition,
  ) {
    final rate = _suggestedRate(
      'PET',
      petCondition: condition,
    );

    setState(() {
      _petCondition = condition;
      _resultConfirmed = true;
      _needsPetCondition = false;
      _confirmedRate = rate;

      _result =
          'PET $condition CONFIRMED';

      _details =
          'PET resin code 1 confirmed.';

      _rateText =
          'PET $condition: ₹${rate.toStringAsFixed(0)}/kg';
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

    final rate =
        _suggestedRate(
      material,
    );

    setState(() {
      _confirmedMaterial = material;
      _confirmedRate = rate;
      _resultConfirmed = true;

      _result =
          '$material CONFIRMED';

      _details =
          'Result confirmed by customer. Admin will cross-check the image.';

      _rateText = rate > 0
          ? '$material: ₹${rate.toStringAsFixed(0)}/kg'
          : 'Admin valuation';
    });
  }

  Future<void> _manualCorrection() async {
    final selected =
        await showModalBottomSheet<String>(
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...options.map(
                (item) => ListTile(
                  leading:
                      const Icon(
                    Icons.recycling,
                  ),
                  title:
                      Text(item),
                  onTap: () {
                    Navigator.pop(
                      context,
                      item,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    if (selected == 'PET') {
      setState(() {
        _confirmedMaterial = 'PET';
        _resinCode = '1';
        _resultConfirmed = false;
        _needsResinConfirmation = false;
        _needsPetCondition = true;

        _result = 'PET SELECTED';

        _details =
            'Select crushed or uncrushed.';

        _rateText = '';
      });

      return;
    }

    final rate =
        _suggestedRate(
      selected,
    );

    setState(() {
      _confirmedMaterial = selected;
      _confirmedRate = rate;
      _resultConfirmed = true;
      _needsResinConfirmation = false;
      _needsPetCondition = false;

      _result =
          '$selected CONFIRMED';

      _details =
          'Corrected manually by customer. Admin will cross-check the image.';

      _rateText = rate > 0
          ? '$selected: ₹${rate.toStringAsFixed(0)}/kg'
          : 'Admin valuation';
    });
  }

  Future<Map<String, dynamic>>
      _uploadToCloudinary(
    String filePath,
  ) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );

    final request =
        http.MultipartRequest(
      'POST',
      uri,
    )
          ..fields['upload_preset'] =
              cloudinaryUploadPreset
          ..files.add(
            await http.MultipartFile.fromPath(
              'file',
              filePath,
            ),
          );

    final streamed =
        await request.send();

    final body =
        await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 ||
        streamed.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed (${streamed.statusCode}): $body',
      );
    }

    return jsonDecode(body)
        as Map<String, dynamic>;
  }

  Future<void> _saveScan() async {
    if (!_resultConfirmed ||
        _confirmedMaterial == null ||
        _lastCapturedPath == null ||
        _saving) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final cloudinary =
          await _uploadToCloudinary(
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
        'scannedAt':
            FieldValue.serverTimestamp(),

        'material':
            _confirmedMaterial,

        'materialGrade':
            'Standard',

        'resinCode':
            _resinCode,

        'petCondition':
            _petCondition,

        'aiCategory':
            _detectedCategory,

        'aiConfidence':
            _averageConfidence,

        'imageUrl':
            imageUrl,

        'cloudinaryPublicId':
            cloudinary['public_id'],

        'ratePerKg':
            _confirmedRate,

        'customerWeight':
            null,

        'confirmedWeight':
            null,

        'amount':
            0.0,

        'adminVerified':
            false,

        'status':
            'Pending Verification',

        'paymentStatus':
            'Not Payable Yet',

        'paymentReference':
            null,

        'receiptNumber':
            null,

        'paidAt':
            null,

        'pickedUp':
            false,

        'pickupWeightKg':
            0.0,

        'createdAtClient':
            now.toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Scan saved under Customer ID $customerId on ${displayDate(now)}',
          ),
        ),
      );

      _clearScan();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save scan: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please scan an item first',
          ),
        ),
      );

      return;
    }

    await _tts.stop();

    await _tts.speak(
      '$_result. $_details. $_rateText',
    );
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
          if (_ready &&
              _controller != null)
            CameraPreview(
              _controller!,
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(
                  0xFF43A047,
                ),
              ),
            ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(
                  0.68,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Text(
                'Place ONE item clearly in the camera. Scan → Confirm material → Save Scan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                76,
                20,
                190,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.76,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color: _hasResult
                        ? Colors.greenAccent
                        : Colors.white54,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      _result,
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: _hasResult
                            ? Colors.greenAccent
                            : Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (_details.isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        _details,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                    ],

                    if (_confidenceText
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        _confidenceText,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (_rateText
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        _rateText,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],

                    if (_needsResinConfirmation) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'Check recycling symbol / resin code',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment:
                            WrapAlignment.center,
                        children: [
                          ActionChip(
                            label:
                                const Text(
                              '1 PET',
                            ),
                            onPressed: () {
                              _confirmResin(
                                '1',
                                'PET',
                              );
                            },
                          ),
                          ActionChip(
                            label:
                                const Text(
                              '2 HDPE',
                            ),
                            onPressed: () {
                              _confirmResin(
                                '2',
                                'HDPE',
                              );
                            },
                          ),
                          ActionChip(
                            label:
                                const Text(
                              '4 LDPE',
                            ),
                            onPressed: () {
                              _confirmResin(
                                '4',
                                'LDPE',
                              );
                            },
                          ),
                          ActionChip(
                            label:
                                const Text(
                              '5 PP',
                            ),
                            onPressed: () {
                              _confirmResin(
                                '5',
                                'PP',
                              );
                            },
                          ),
                        ],
                      ),
                    ],

                    if (_needsPetCondition) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'PET condition',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          ActionChip(
                            label:
                                const Text(
                              'CRUSHED ₹14/kg',
                            ),
                            onPressed: () {
                              _confirmPetCondition(
                                'Crushed',
                              );
                            },
                          ),
                          ActionChip(
                            label:
                                const Text(
                              'UNCRUSHED ₹12/kg',
                            ),
                            onPressed: () {
                              _confirmPetCondition(
                                'Uncrushed',
                              );
                            },
                          ),
                        ],
                      ),
                    ],

                    if (_hasResult &&
                        !_needsResinConfirmation &&
                        !_needsPetCondition &&
                        !_resultConfirmed &&
                        _detectedCategory !=
                            'unknown') ...[
                      const SizedBox(
                        height: 14,
                      ),
                      FilledButton.icon(
                        onPressed:
                            _confirmDetectedResult,
                        icon:
                            const Icon(
                          Icons.check,
                        ),
                        label:
                            const Text(
                          'CONFIRM RESULT',
                        ),
                      ),
                    ],

                    if (_hasResult) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      TextButton.icon(
                        onPressed:
                            _manualCorrection,
                        icon:
                            const Icon(
                          Icons.edit,
                          color:
                              Colors.white,
                        ),
                        label:
                            const Text(
                          'WRONG RESULT / CHOOSE MANUALLY',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                    ],

                    if (_resultConfirmed) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons.verified,
                            color:
                                Colors.greenAccent,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            'Material confirmed — ready to save',
                            style:
                                TextStyle(
                              color:
                                  Colors.greenAccent,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            FilledButton.icon(
                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.greenAccent,
                            foregroundColor:
                                Colors.black,
                          ),
                          onPressed:
                              _saving
                                  ? null
                                  : _saveScan,
                          icon: _saving
                              ? const SizedBox(
                                  width:
                                      18,
                                  height:
                                      18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons.cloud_upload,
                                ),
                          label:
                              Text(
                            _saving
                                ? 'SAVING...'
                                : 'SAVE SCAN TO HISTORY',
                          ),
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
                      child:
                          FilledButton.icon(
                        onPressed:
                            _scanning ||
                                    _saving
                                ? null
                                : _scan,
                        icon: _scanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.center_focus_strong,
                              ),
                        label:
                            Text(
                          _scanning
                              ? 'ANALYZING...'
                              : 'SCAN',
                        ),
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              pothigaiGreen,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child:
                          FilledButton.tonalIcon(
                        onPressed:
                            _speak,
                        icon:
                            const Icon(
                          Icons.volume_up,
                        ),
                        label:
                            const Text(
                          'TAMIL VOICE',
                        ),
                        style:
                            FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_hasResult) ...[
                  const SizedBox(
                    height: 8,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _saving
                              ? null
                              : _clearScan,
                      icon:
                          const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text(
                        'CLEAR & NEW SCAN',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            pothigaiGreen,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
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

    _phoneController.text =
        '${widget.profile['phone'] ?? ''}';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _busy) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final quantityText =
          _quantityController.text.trim();

      final requestedWeightKg =
          firstNumberFromText(
        quantityText,
      );

      await FirebaseFirestore.instance
          .collection('pickup_requests')
          .add({
        'customerUid': user.uid,
        'customerId':
            widget.profile['customerId'],
        'customerName':
            widget.profile['name'],
        'category': _category,

        'quantity':
            quantityText,

        'requestedWeightKg':
            requestedWeightKg,

        'actualPickedUpWeightKg':
            0.0,

        'phone':
            _phoneController.text.trim(),

        'address':
            _addressController.text.trim(),

        'status':
            'Requested',

        'collectorReference':
            null,

        'vehicleReference':
            null,

        'pickupNotes':
            null,

        'createdAt':
            FieldValue.serverTimestamp(),

        'assignedAt':
            null,

        'enRouteAt':
            null,

        'arrivedAt':
            null,

        'weighedAt':
            null,

        'pickedUpAt':
            null,

        'closedAt':
            null,

        'cancelledAt':
            null,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Pickup request saved',
          ),
        ),
      );

      _quantityController.clear();
      _addressController.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save pickup request: $e',
          ),
        ),
      );
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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.tamil
                ? 'கழிவு சேகரிப்பு பதிவு'
                : 'Book Waste Pickup',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            value: _category,
            decoration:
                const InputDecoration(
              labelText:
                  'Waste category',
              border:
                  OutlineInputBorder(),
            ),
            items: categories
                .map(
                  (item) =>
                      DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _category = value;
              });
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller:
                _quantityController,
            decoration:
                const InputDecoration(
              labelText:
                  'Approx. quantity / weight',
              hintText:
                  'Example: 8 kg or 2 bags',
              border:
                  OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter quantity';
              }

              return null;
            },
          ),

          const SizedBox(height: 8),

          const Text(
            'If you enter weight such as 8 kg, the app will use 8 kg as the requested pickup weight.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller:
                _phoneController,
            keyboardType:
                TextInputType.phone,
            decoration:
                const InputDecoration(
              labelText:
                  'Phone number',
              border:
                  OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().length < 8) {
                return 'Please enter a valid phone number';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller:
                _addressController,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText:
                  'Pickup address',
              border:
                  OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter pickup address';
              }

              return null;
            },
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed:
                _busy
                    ? null
                    : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons
                        .check_circle_outline,
                  ),
            label:
                const Text(
              'CONFIRM PICKUP',
            ),
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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Not signed in',
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('scans')
          .where(
            'customerUid',
            isEqualTo: user.uid,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'History error: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final docs =
            snapshot.data!.docs.toList()
              ..sort(
                (a, b) {
                  final aDate =
                      timestampToDate(
                    a.data()['scannedAt'],
                  );

                  final bDate =
                      timestampToDate(
                    b.data()['scannedAt'],
                  );

                  return bDate.compareTo(
                    aDate,
                  );
                },
              );

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No saved scans yet',
            ),
          );
        }

        final grouped =
            <String,
                List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>>{};

        for (final doc in docs) {
          final key =
              '${doc.data()['scanDate'] ?? dateKey(timestampToDate(doc.data()['scannedAt']))}';

          grouped
              .putIfAbsent(
                key,
                () => [],
              )
              .add(doc);
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children:
              grouped.entries.map(
            (entry) {
              final dailyTotal =
                  entry.value.fold<double>(
                0,
                (
                  sum,
                  doc,
                ) =>
                    sum +
                    asDouble(
                      doc.data()['amount'],
                    ),
              );

              final dailyPaid =
                  entry.value.fold<double>(
                0,
                (
                  sum,
                  doc,
                ) {
                  final data =
                      doc.data();

                  final paymentStatus =
                      '${data['paymentStatus'] ?? ''}';

                  if (paymentStatus ==
                      'Paid') {
                    return sum +
                        asDouble(
                          data['amount'],
                        );
                  }

                  return sum;
                },
              );

              final dailyPending =
                  dailyTotal -
                      dailyPaid;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          '₹${dailyTotal.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar:
                            const Icon(
                          Icons.payments,
                          size: 16,
                        ),
                        label: Text(
                          'Paid ₹${dailyPaid.toStringAsFixed(2)}',
                        ),
                      ),
                      Chip(
                        avatar:
                            const Icon(
                          Icons.pending_actions,
                          size: 16,
                        ),
                        label: Text(
                          'Pending ₹${dailyPending.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  ...entry.value.map(
                    (doc) =>
                        CustomerScanCard(
                      data: doc.data(),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              );
            },
          ).toList(),
        );
      },
    );
  }
}

class CustomerScanCard extends StatelessWidget {
  const CustomerScanCard({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        '${data['imageUrl'] ?? ''}';

    final material =
        '${data['material'] ?? '-'}';

    final materialGrade =
        '${data['materialGrade'] ?? 'Standard'}';

    final status =
        '${data['status'] ?? 'Pending Verification'}';

    final paymentStatus =
        '${data['paymentStatus'] ?? 'Not Payable Yet'}';

    final paymentReference =
        '${data['paymentReference'] ?? ''}';

    final receiptNumber =
        '${data['receiptNumber'] ?? ''}';

    final verified =
        data['adminVerified'] == true;

    final rate =
        asDouble(
      data['ratePerKg'],
    );

    final weight =
        asDouble(
      data['confirmedWeight'],
    );

    final amount =
        asDouble(
      data['amount'],
    );

    final confidence =
        asDouble(
      data['aiConfidence'],
    );

    final paid =
        paymentStatus == 'Paid';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          12,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              child: imageUrl.isEmpty
                  ? Container(
                      width: 90,
                      height: 90,
                      color:
                          Colors.grey.shade200,
                      child:
                          const Icon(
                        Icons
                            .image_not_supported,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        _,
                        __,
                        ___,
                      ) {
                        return Container(
                          width: 90,
                          height: 90,
                          color: Colors
                              .grey
                              .shade200,
                          child:
                              const Icon(
                            Icons.broken_image,
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    material,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Grade: $materialGrade',
                  ),

                  Text(
                    'AI confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                  ),

                  Text(
                    'Rate: ₹${rate.toStringAsFixed(2)}/kg',
                  ),

                  if (verified)
                    Text(
                      'Verified weight: ${weight.toStringAsFixed(2)} kg',
                    ),

                  if (verified)
                    Text(
                      'Payable: ₹${amount.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        color:
                            pothigaiGreen,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 4),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar:
                            Icon(
                          verified
                              ? Icons.verified
                              : Icons.schedule,
                          size: 18,
                        ),
                        label:
                            Text(
                          status,
                        ),
                      ),

                      Chip(
                        avatar:
                            Icon(
                          paid
                              ? Icons
                                  .check_circle
                              : Icons
                                  .pending_actions,
                          size: 18,
                        ),
                        label:
                            Text(
                          paymentStatus,
                        ),
                      ),
                    ],
                  ),

                  if (paymentReference
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Payment ref: $paymentReference',
                    ),
                  ],

                  if (receiptNumber
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Receipt: $receiptNumber',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
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
          tamil
              ? 'பசுமை வழிகாட்டி'
              : 'Green Guide',
          style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.badge,
              color: pothigaiGreen,
            ),
            title:
                const Text(
              'Customer ID',
            ),
            subtitle:
                Text(
              '${profile['customerId'] ?? ''}',
            ),
          ),
        ),

        const Card(
          child: ListTile(
            leading: Icon(
              Icons.recycling,
              color: pothigaiGreen,
            ),
            title:
                Text(
              'Plastic resin codes',
            ),
            subtitle:
                Text(
              '1 = PET • 2 = HDPE • 4 = LDPE • 5 = PP',
            ),
          ),
        ),

        const Card(
          child: ListTile(
            leading: Icon(
              Icons
                  .verified_user_outlined,
              color: pothigaiGreen,
            ),
            title:
                Text(
              'Payment verification',
            ),
            subtitle:
                Text(
              'AI classification is guidance. Admin verifies the scan image, material, grade, final weight and rate before payment.',
            ),
          ),
        ),

        const Card(
          child: ListTile(
            leading: Icon(
              Icons.local_shipping,
              color: pothigaiGreen,
            ),
            title:
                Text(
              'Pickup tracking',
            ),
            subtitle:
                Text(
              'Pickup requests can move through Requested, Assigned, En Route, Arrived, Weighed, Picked Up and Closed.',
            ),
          ),
        ),
      ],
    );
  }
}

class CustomerSummaryData {
  CustomerSummaryData({
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  int scanCount = 0;
  double verifiedKg = 0;
  double pickedUpKg = 0;
  double payable = 0;
  double paid = 0;
  int openPickupCount = 0;

  double get awaitingPickupKg {
    final value =
        verifiedKg - pickedUpKg;

    return value < 0
        ? 0
        : value;
  }

  double get pendingPayment {
    final value =
        payable - paid;

    return value < 0
        ? 0
        : value;
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({
    super.key,
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  State<AdminHome> createState() =>
      _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? _selectedCustomerId;
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Pothigai Green Admin',
            ),
            Text(
              'Operations • Verification • Pickup • Payment',
              style:
                  TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip:
                'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance
                  .signOut();
            },
            icon:
                const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder:
            (context, usersSnapshot) {
          if (usersSnapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load users:\n${usersSnapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          if (!usersSnapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          return StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('scans')
                .snapshots(),
            builder:
                (context, scansSnapshot) {
              if (scansSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load scans:\n${scansSnapshot.error}',
                    textAlign:
                        TextAlign.center,
                  ),
                );
              }

              if (!scansSnapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              return StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(
                      'pickup_requests',
                    )
                    .snapshots(),
                builder:
                    (context, pickupSnapshot) {
                  if (pickupSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load pickups:\n${pickupSnapshot.error}',
                        textAlign:
                            TextAlign.center,
                      ),
                    );
                  }

                  if (!pickupSnapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final userDocs =
                      usersSnapshot.data!.docs;

                  final scanDocs =
                      scansSnapshot.data!.docs
                          .toList()
                        ..sort(
                          (a, b) {
                            final aDate =
                                timestampToDate(
                              a.data()[
                                  'scannedAt'],
                            );

                            final bDate =
                                timestampToDate(
                              b.data()[
                                  'scannedAt'],
                            );

                            return bDate
                                .compareTo(
                              aDate,
                            );
                          },
                        );

                  final pickupDocs =
                      pickupSnapshot.data!.docs
                          .toList();

                  final customers =
                      <String,
                          Map<String, dynamic>>{};

                  for (final userDoc
                      in userDocs) {
                    final data =
                        userDoc.data();

                    final role =
                        '${data['role'] ?? 'customer'}'
                            .toLowerCase();

                    final email =
                        '${data['email'] ?? ''}';

                    final phone =
                        '${data['phone'] ?? ''}';

                    final isAdmin =
                        role == 'admin' ||
                            isPothigaiAdminIdentity(
                              email: email,
                              phone: phone,
                            );

                    if (isAdmin) {
                      continue;
                    }

                    final customerId =
                        '${data['customerId'] ?? ''}'
                            .trim();

                    if (customerId
                        .isEmpty) {
                      continue;
                    }

                    customers[customerId] =
                        data;
                  }

                  final summaries =
                      <String,
                          CustomerSummaryData>{};

                  for (final entry
                      in customers.entries) {
                    final customerId =
                        entry.key;

                    final customerName =
                        '${entry.value['name'] ?? ''}'
                            .trim();

                    summaries[
                            customerId] =
                        CustomerSummaryData(
                      customerId:
                          customerId,
                      customerName:
                          customerName,
                    );
                  }

                  for (final scan
                      in scanDocs) {
                    final data =
                        scan.data();

                    final customerId =
                        '${data['customerId'] ?? ''}'
                            .trim();

                    if (customerId
                        .isEmpty) {
                      continue;
                    }

                    summaries.putIfAbsent(
                      customerId,
                      () =>
                          CustomerSummaryData(
                        customerId:
                            customerId,
                        customerName:
                            '${data['customerName'] ?? ''}',
                      ),
                    );

                    final summary =
                        summaries[
                            customerId]!;

                    summary.scanCount += 1;

                    if (data['adminVerified'] ==
                        true) {
                      summary.verifiedKg +=
                          asDouble(
                        data[
                            'confirmedWeight'],
                      );

                      summary.payable +=
                          asDouble(
                        data['amount'],
                      );

                      if ('${data['paymentStatus'] ?? ''}' ==
                          'Paid') {
                        summary.paid +=
                            asDouble(
                          data['amount'],
                        );
                      }
                    }
                  }

                  for (final pickup
                      in pickupDocs) {
                    final data =
                        pickup.data();

                    final customerId =
                        '${data['customerId'] ?? ''}'
                            .trim();

                    if (customerId
                        .isEmpty) {
                      continue;
                    }

                    summaries.putIfAbsent(
                      customerId,
                      () =>
                          CustomerSummaryData(
                        customerId:
                            customerId,
                        customerName:
                            '${data['customerName'] ?? ''}',
                      ),
                    );

                    final summary =
                        summaries[
                            customerId]!;

                    summary.pickedUpKg +=
                        asDouble(
                      data[
                          'actualPickedUpWeightKg'],
                    );

                    final status =
                        '${data['status'] ?? 'Requested'}';

                    if (status !=
                            'Closed' &&
                        status !=
                            'Cancelled') {
                      summary
                              .openPickupCount +=
                          1;
                    }
                  }

                  final customerIds =
                      summaries.keys
                          .toList()
                        ..sort();

                  if (_selectedCustomerId !=
                          null &&
                      !summaries.containsKey(
                        _selectedCustomerId,
                      )) {
                    _selectedCustomerId =
                        null;
                    _selectedDate =
                        null;
                  }

                  final selectedSummary =
                      _selectedCustomerId ==
                              null
                          ? null
                          : summaries[
                              _selectedCustomerId];

                  final selectedScanDocs =
                      _selectedCustomerId ==
                              null
                          ? <QueryDocumentSnapshot<
                              Map<String,
                                  dynamic>>>[]
                          : scanDocs
                              .where(
                                (doc) =>
                                    '${doc.data()['customerId'] ?? ''}' ==
                                    _selectedCustomerId,
                              )
                              .toList();

                  final availableDates =
                      selectedScanDocs
                          .map(
                            (doc) =>
                                '${doc.data()['scanDate'] ?? ''}',
                          )
                          .where(
                            (date) =>
                                date.isNotEmpty,
                          )
                          .toSet()
                          .toList()
                        ..sort(
                          (a, b) =>
                              b.compareTo(
                            a,
                          ),
                        );

                  if (_selectedDate !=
                          null &&
                      !availableDates.contains(
                        _selectedDate,
                      )) {
                    _selectedDate =
                        null;
                  }

                  final filteredScanDocs =
                      selectedScanDocs.where(
                    (doc) {
                      if (_selectedDate ==
                          null) {
                        return true;
                      }

                      return '${doc.data()['scanDate'] ?? ''}' ==
                          _selectedDate;
                    },
                  ).toList();

                  final selectedPickupDocs =
                      _selectedCustomerId ==
                              null
                          ? <QueryDocumentSnapshot<
                              Map<String,
                                  dynamic>>>[]
                          : pickupDocs
                              .where(
                                (doc) =>
                                    '${doc.data()['customerId'] ?? ''}' ==
                                    _selectedCustomerId,
                              )
                              .toList();

                  final customersWithScans =
                      summaries.values
                          .where(
                            (summary) =>
                                summary.scanCount >
                                0,
                          )
                          .length;

                  final totalVerifiedKg =
                      summaries.values
                          .fold<double>(
                    0,
                    (
                      sum,
                      summary,
                    ) =>
                        sum +
                        summary
                            .verifiedKg,
                  );

                  final totalPickedUpKg =
                      summaries.values
                          .fold<double>(
                    0,
                    (
                      sum,
                      summary,
                    ) =>
                        sum +
                        summary
                            .pickedUpKg,
                  );

                  final totalAwaitingKg =
                      summaries.values
                          .fold<double>(
                    0,
                    (
                      sum,
                      summary,
                    ) =>
                        sum +
                        summary
                            .awaitingPickupKg,
                  );

                  final totalPayable =
                      summaries.values
                          .fold<double>(
                    0,
                    (
                      sum,
                      summary,
                    ) =>
                        sum +
                        summary
                            .payable,
                  );

                  final totalPaid =
                      summaries.values
                          .fold<double>(
                    0,
                    (
                      sum,
                      summary,
                    ) =>
                        sum +
                        summary
                            .paid,
                  );

                  final totalPending =
                      totalPayable -
                          totalPaid;

                  return Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          14,
                          14,
                          14,
                          8,
                        ),
                        child:
                            DropdownButtonFormField<
                                String>(
                          value:
                              _selectedCustomerId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Select customer',
                            border:
                                OutlineInputBorder(),
                            prefixIcon:
                                Icon(
                              Icons
                                  .person_search,
                            ),
                          ),
                          hint:
                              const Text(
                            'All customers - summary only',
                          ),
                          items: [
                            const DropdownMenuItem<
                                String>(
                              value: null,
                              child:
                                  Text(
                                'All customers - summary only',
                              ),
                            ),
                            ...customerIds.map(
                              (
                                customerId,
                              ) {
                                final summary =
                                    summaries[
                                        customerId]!;

                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      customerId,
                                  child:
                                      Text(
                                    summary.customerName.isEmpty
                                        ? customerId
                                        : '$customerId • ${summary.customerName}',
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ],
                          onChanged:
                              (value) {
                            setState(() {
                              _selectedCustomerId =
                                  value;
                              _selectedDate =
                                  null;
                            });
                          },
                        ),
                      ),

                      Expanded(
                        child:
                            _selectedCustomerId ==
                                    null
                                ? AdminOverallDashboard(
                                    customersEnrolled:
                                        summaries.length,
                                    customersWithScans:
                                        customersWithScans,
                                    verifiedKg:
                                        totalVerifiedKg,
                                    pickedUpKg:
                                        totalPickedUpKg,
                                    awaitingPickupKg:
                                        totalAwaitingKg,
                                    totalPayable:
                                        totalPayable,
                                    totalPaid:
                                        totalPaid,
                                    pendingPayment:
                                        totalPending <
                                                0
                                            ? 0
                                            : totalPending,
                                    summaries:
                                        summaries.values
                                            .toList()
                                          ..sort(
                                            (
                                              a,
                                              b,
                                            ) =>
                                                a.customerId.compareTo(
                                              b.customerId,
                                            ),
                                          ),
                                    onCustomerSelected:
                                        (
                                      customerId,
                                    ) {
                                      setState(() {
                                        _selectedCustomerId =
                                            customerId;
                                        _selectedDate =
                                            null;
                                      });
                                    },
                                  )
                                : AdminSelectedCustomerView(
                                    summary:
                                        selectedSummary!,
                                    availableDates:
                                        availableDates,
                                    selectedDate:
                                        _selectedDate,
                                    onDateChanged:
                                        (value) {
                                      setState(() {
                                        _selectedDate =
                                            value;
                                      });
                                    },
                                    scanDocs:
                                        filteredScanDocs,
                                    pickupDocs:
                                        selectedPickupDocs,
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
class AdminOverallDashboard extends StatelessWidget {
  const AdminOverallDashboard({
    super.key,
    required this.customersEnrolled,
    required this.customersWithScans,
    required this.verifiedKg,
    required this.pickedUpKg,
    required this.awaitingPickupKg,
    required this.totalPayable,
    required this.totalPaid,
    required this.pendingPayment,
    required this.summaries,
    required this.onCustomerSelected,
  });

  final int customersEnrolled;
  final int customersWithScans;

  final double verifiedKg;
  final double pickedUpKg;
  final double awaitingPickupKg;

  final double totalPayable;
  final double totalPaid;
  final double pendingPayment;

  final List<CustomerSummaryData> summaries;

  final ValueChanged<String> onCustomerSelected;

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: pothigaiGreen,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        24,
      ),
      children: [
        Text(
          'Operations Dashboard',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Overall business status. Select a customer above to view individual scans and pickups.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: [
            _metricCard(
              title:
                  'Customers enrolled',
              value:
                  '$customersEnrolled',
              icon:
                  Icons.people_alt_outlined,
            ),
            _metricCard(
              title:
                  'Customers with scans',
              value:
                  '$customersWithScans',
              icon:
                  Icons.qr_code_scanner,
            ),
            _metricCard(
              title:
                  'Verified scanned',
              value:
                  '${verifiedKg.toStringAsFixed(2)} kg',
              icon:
                  Icons.scale,
            ),
            _metricCard(
              title:
                  'Picked up',
              value:
                  '${pickedUpKg.toStringAsFixed(2)} kg',
              icon:
                  Icons.local_shipping,
            ),
            _metricCard(
              title:
                  'Awaiting pickup',
              value:
                  '${awaitingPickupKg.toStringAsFixed(2)} kg',
              icon:
                  Icons.hourglass_bottom,
            ),
            _metricCard(
              title:
                  'Total payable',
              value:
                  '₹${totalPayable.toStringAsFixed(2)}',
              icon:
                  Icons.receipt_long,
            ),
            _metricCard(
              title:
                  'Paid',
              value:
                  '₹${totalPaid.toStringAsFixed(2)}',
              icon:
                  Icons.task_alt,
            ),
            _metricCard(
              title:
                  'Pending payment',
              value:
                  '₹${pendingPayment.toStringAsFixed(2)}',
              icon:
                  Icons.pending_actions,
            ),
          ],
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Text(
                'Customer Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
            ),
            Chip(
              label: Text(
                '${summaries.length} customers',
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (summaries.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(18),
              child: Text(
                'No customers enrolled yet.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          )
        else
          ...summaries.map(
            (summary) {
              return CustomerSummaryCard(
                summary:
                    summary,
                onTap: () {
                  onCustomerSelected(
                    summary.customerId,
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  final CustomerSummaryData summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pendingPickup =
        summary.awaitingPickupKg;

    final pendingPayment =
        summary.pendingPayment;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(
            14,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        const Color(
                      0xFFE8F5E9,
                    ),
                    child: const Icon(
                      Icons.person,
                      color:
                          pothigaiGreen,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          summary
                                  .customerName
                                  .isEmpty
                              ? summary
                                  .customerId
                              : '${summary.customerId} • ${summary.customerName}',
                          style:
                              const TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        Text(
                          '${summary.scanCount} scan${summary.scanCount == 1 ? '' : 's'}',
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                    ),
                ],
              ),

              const Divider(
                height: 24,
              ),

              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _summaryItem(
                    'Verified',
                    '${summary.verifiedKg.toStringAsFixed(2)} kg',
                  ),
                  _summaryItem(
                    'Picked up',
                    '${summary.pickedUpKg.toStringAsFixed(2)} kg',
                  ),
                  _summaryItem(
                    'Awaiting',
                    '${pendingPickup.toStringAsFixed(2)} kg',
                  ),
                  _summaryItem(
                    'Open pickups',
                    '${summary.openPickupCount}',
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF1F8E9,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _moneyItem(
                        title:
                            'Payable',
                        amount:
                            summary.payable,
                      ),
                    ),
                    Expanded(
                      child:
                          _moneyItem(
                        title:
                            'Paid',
                        amount:
                            summary.paid,
                      ),
                    ),
                    Expanded(
                      child:
                          _moneyItem(
                        title:
                            'Pending',
                        amount:
                            pendingPayment,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
  ) {
    return SizedBox(
      width: 135,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyItem({
    required String title,
    required double amount,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style:
              const TextStyle(
            color:
                pothigaiGreen,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class AdminSelectedCustomerView
    extends StatelessWidget {
  const AdminSelectedCustomerView({
    super.key,
    required this.summary,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateChanged,
    required this.scanDocs,
    required this.pickupDocs,
  });

  final CustomerSummaryData summary;

  final List<String> availableDates;
  final String? selectedDate;

  final ValueChanged<String?>
      onDateChanged;

  final List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>
      scanDocs;

  final List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>
      pickupDocs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        24,
      ),
      children: [
        CustomerSummaryCard(
          summary: summary,
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<
            String>(
          value: selectedDate,
          isExpanded: true,
          decoration:
              const InputDecoration(
            labelText:
                'Select scanned date',
            border:
                OutlineInputBorder(),
            prefixIcon:
                Icon(
              Icons.calendar_month,
            ),
          ),
          hint:
              const Text(
            'All scanned dates',
          ),
          items: [
            const DropdownMenuItem<
                String>(
              value: null,
              child: Text(
                'All scanned dates',
              ),
            ),
            ...availableDates.map(
              (date) {
                return DropdownMenuItem<
                    String>(
                  value: date,
                  child: Text(date),
                );
              },
            ),
          ],
          onChanged:
              onDateChanged,
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            const Icon(
              Icons.local_shipping,
              color:
                  pothigaiGreen,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              'Pickup Workflow',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (pickupDocs.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(
                16,
              ),
              child: Text(
                'No pickup requests for this customer.',
              ),
            ),
          )
        else
          ...pickupDocs.map(
            (doc) {
              return AdminPickupCard(
                docId: doc.id,
                data: doc.data(),
              );
            },
          ),

        const SizedBox(height: 20),

        Row(
          children: [
            const Icon(
              Icons.photo_library,
              color:
                  pothigaiGreen,
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                selectedDate == null
                    ? 'Scanned Items'
                    : 'Scanned Items • $selectedDate',
                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
              ),
            ),
            Chip(
              label: Text(
                '${scanDocs.length}',
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (scanDocs.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(
                16,
              ),
              child: Text(
                'No scans for this customer/date.',
              ),
            ),
          )
        else
          ...scanDocs.map(
            (doc) {
              return AdminScanCard(
                docId: doc.id,
                data: doc.data(),
              );
            },
          ),
      ],
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
    final requestedKg =
        asDouble(
      data['requestedWeightKg'],
    );

    final pickedUpKg =
        asDouble(
      data['actualPickedUpWeightKg'] ??
          data['pickedUpWeightKg'],
    );

    final status =
        '${data['status'] ?? data['pickupStatus'] ?? 'Requested'}';

    final category =
        '${data['category'] ?? ''}';

    final collector =
        '${data['collectorReference'] ?? data['assignedCollector'] ?? ''}';

    final vehicle =
        '${data['vehicleReference'] ?? ''}';

    final notes =
        '${data['pickupNotes'] ?? ''}';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          12,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor:
                      Color(
                    0xFFE8F5E9,
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color:
                        pothigaiGreen,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        category.isEmpty
                            ? 'Pickup Request'
                            : category,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize:
                              16,
                        ),
                      ),
                      Text(
                        'Status: $status',
                      ),
                    ],
                  ),
                ),
                PickupStatusChip(
                  status: status,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child:
                      _pickupMetric(
                    'Requested',
                    '${requestedKg.toStringAsFixed(2)} kg',
                  ),
                ),
                Expanded(
                  child:
                      _pickupMetric(
                    'Picked Up',
                    '${pickedUpKg.toStringAsFixed(2)} kg',
                  ),
                ),
              ],
            ),

            if (collector.isNotEmpty ||
                vehicle.isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),
              Text(
                [
                  if (collector.isNotEmpty)
                    'Collector: $collector',
                  if (vehicle.isNotEmpty)
                    'Vehicle: $vehicle',
                ].join(' • '),
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey,
                ),
              ),
            ],

            if (notes.isNotEmpty) ...[
              const SizedBox(
                height: 6,
              ),
              Text(
                'Notes: $notes',
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width:
                  double.infinity,
              child:
                  FilledButton.tonalIcon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) =>
                        AdminPickupDialog(
                      docId: docId,
                      initialData: data,
                    ),
                  );
                },
                icon:
                    const Icon(
                  Icons.manage_accounts,
                ),
                label:
                    const Text(
                  'MANAGE PICKUP',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickupMetric(
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        10,
      ),
      margin:
          const EdgeInsets.only(
        right: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PickupStatusChip extends StatelessWidget {
  const PickupStatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (status) {
      case 'Assigned':
        icon =
            Icons.assignment_ind;
        break;

      case 'En Route':
        icon =
            Icons.route;
        break;

      case 'Arrived':
        icon =
            Icons.location_on;
        break;

      case 'Weighed':
        icon =
            Icons.scale;
        break;

      case 'Picked Up':
        icon =
            Icons.inventory_2;
        break;

      case 'Closed':
        icon =
            Icons.check_circle;
        break;

      case 'Cancelled':
        icon =
            Icons.cancel;
        break;

      default:
        icon =
            Icons.schedule;
    }

    return Chip(
      avatar: Icon(
        icon,
        size: 17,
      ),
      label: Text(
        status,
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
  State<AdminPickupDialog>
      createState() =>
          _AdminPickupDialogState();
}

class _AdminPickupDialogState
    extends State<AdminPickupDialog> {
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

  late final TextEditingController
      _weightController;

  late final TextEditingController
      _collectorController;

  late final TextEditingController
      _vehicleController;

  late final TextEditingController
      _notesController;

  late String _status;

  bool _busy = false;

  @override
  void initState() {
    super.initState();

    final existingWeight =
        asDouble(
      widget.initialData[
              'actualPickedUpWeightKg'] ??
          widget.initialData[
              'pickedUpWeightKg'],
    );

    final requestedWeight =
        asDouble(
      widget.initialData[
          'requestedWeightKg'],
    );

    _weightController =
        TextEditingController(
      text: existingWeight > 0
          ? existingWeight
              .toStringAsFixed(
                2,
              )
          : requestedWeight > 0
              ? requestedWeight
                  .toStringAsFixed(
                    2,
                  )
              : '',
    );

    _collectorController =
        TextEditingController(
      text:
          '${widget.initialData['collectorReference'] ?? widget.initialData['assignedCollector'] ?? ''}',
    );

    _vehicleController =
        TextEditingController(
      text:
          '${widget.initialData['vehicleReference'] ?? ''}',
    );

    _notesController =
        TextEditingController(
      text:
          '${widget.initialData['pickupNotes'] ?? ''}',
    );

    final initialStatus =
        '${widget.initialData['status'] ?? widget.initialData['pickupStatus'] ?? 'Requested'}';

    _status =
        statuses.contains(
      initialStatus,
    )
            ? initialStatus
            : 'Requested';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _collectorController.dispose();
    _vehicleController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  bool get _requiresWeight =>
      _status == 'Weighed' ||
      _status == 'Picked Up' ||
      _status == 'Closed';

  Future<void> _save() async {
    final weight =
        double.tryParse(
              _weightController.text
                  .trim(),
            ) ??
            0;

    if (_requiresWeight &&
        weight <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the actual pickup weight before continuing.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final update =
          <String, dynamic>{
        'status':
            _status,

        'pickupStatus':
            _status,

        'collectorReference':
            _collectorController
                .text
                .trim(),

        'assignedCollector':
            _collectorController
                .text
                .trim(),

        'vehicleReference':
            _vehicleController
                .text
                .trim(),

        'pickupNotes':
            _notesController
                .text
                .trim(),

        'lastUpdatedAt':
            FieldValue
                .serverTimestamp(),

        'lastUpdatedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,
      };

      if (_status ==
              'Weighed' ||
          _status ==
              'Picked Up' ||
          _status ==
              'Closed') {
        update[
                'actualPickedUpWeightKg'] =
            weight;
      }

      if (_status ==
              'Picked Up' ||
          _status ==
              'Closed') {
        update[
                'pickedUpWeightKg'] =
            weight;

        update['pickedUpAt'] =
            FieldValue
                .serverTimestamp();

        update['pickedUpBy'] =
            FirebaseAuth
                .instance
                .currentUser
                ?.uid;
      }

      if (_status ==
          'Assigned') {
        update['assignedAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (_status ==
          'En Route') {
        update['enRouteAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (_status ==
          'Arrived') {
        update['arrivedAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (_status ==
          'Weighed') {
        update['weighedAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (_status ==
          'Closed') {
        update['closedAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (_status ==
          'Cancelled') {
        update['cancelledAt'] =
            FieldValue
                .serverTimestamp();
      }

      await FirebaseFirestore
          .instance
          .collection(
            'pickup_requests',
          )
          .doc(
            widget.docId,
          )
          .update(
            update,
          );

      await FirebaseFirestore
          .instance
          .collection(
            'audit_logs',
          )
          .add({
        'entityType':
            'pickup',

        'entityId':
            widget.docId,

        'action':
            'Pickup status changed to $_status',

        'customerId':
            widget.initialData[
                'customerId'],

        'actualWeightKg':
            weight,

        'collectorReference':
            _collectorController
                .text
                .trim(),

        'vehicleReference':
            _vehicleController
                .text
                .trim(),

        'performedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,

        'createdAt':
            FieldValue
                .serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Pickup updated to $_status',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Pickup update failed: $e',
          ),
        ),
      );
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
    final customerId =
        '${widget.initialData['customerId'] ?? ''}';

    final customerName =
        '${widget.initialData['customerName'] ?? ''}';

    final requestedWeight =
        asDouble(
      widget.initialData[
          'requestedWeightKg'],
    );

    return AlertDialog(
      title: const Text(
        'Manage Pickup',
      ),
      content:
          SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
            children: [
              Text(
                customerName.isEmpty
                    ? customerId
                    : '$customerId • $customerName',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              if (requestedWeight >
                  0) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Requested: ${requestedWeight.toStringAsFixed(2)} kg',
                ),
              ],

              const SizedBox(
                height: 16,
              ),

              DropdownButtonFormField<
                  String>(
                value:
                    _status,
                isExpanded:
                    true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Pickup status',
                  border:
                      OutlineInputBorder(),
                ),
                items: statuses
                    .map(
                      (status) =>
                          DropdownMenuItem<
                              String>(
                        value:
                            status,
                        child:
                            Text(
                          status,
                        ),
                      ),
                    )
                    .toList(),
                onChanged:
                    _busy
                        ? null
                        : (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(() {
                              _status =
                                  value;
                            });
                          },
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    _collectorController,
                enabled:
                    !_busy,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Collector reference / name',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(
                    Icons.person_pin,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    _vehicleController,
                enabled:
                    !_busy,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Vehicle reference',
                  hintText:
                      'Example: TN-72-AB-1234',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(
                    Icons.local_shipping,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    _weightController,
                enabled:
                    !_busy,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    InputDecoration(
                  labelText:
                      _requiresWeight
                          ? 'Actual pickup weight (kg) *'
                          : 'Actual pickup weight (kg)',
                  border:
                      const OutlineInputBorder(),
                  prefixIcon:
                      const Icon(
                    Icons.scale,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    _notesController,
                enabled:
                    !_busy,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Pickup notes',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(
                    Icons.notes,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _busy
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                      );
                    },
          child:
              const Text(
            'CANCEL',
          ),
        ),
        FilledButton.icon(
          onPressed:
              _busy
                  ? null
                  : _save,
          icon: _busy
              ? const SizedBox(
                  width:
                      16,
                  height:
                      16,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                  ),
                )
              : const Icon(
                  Icons.save,
                ),
          label:
              Text(
            _busy
                ? 'SAVING...'
                : 'SAVE',
          ),
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

  void _showImage(
    BuildContext context,
    String url,
  ) {
    if (url.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Future<void> _openReview(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) =>
          AdminReviewSheet(
        docId: docId,
        initialData: data,
      ),
    );
  }

  Future<void> _markPaid(
    BuildContext context,
  ) async {
    final referenceController =
        TextEditingController();

    final amount =
        asDouble(
      data['amount'],
    );

    final customerId =
        '${data['customerId'] ?? ''}';

    final receiptNo =
        'PG-${DateTime.now().millisecondsSinceEpoch}';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            const Text(
          'Mark payment as paid',
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Customer: $customerId',
            ),
            Text(
              'Amount: ₹${amount.toStringAsFixed(2)}',
            ),
            const SizedBox(
              height: 12,
            ),
            TextField(
              controller:
                  referenceController,
              decoration:
                  const InputDecoration(
                labelText:
                    'UPI / cash / transaction reference',
                border:
                    OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text(
              'CANCEL',
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text(
              'MARK PAID',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      referenceController
          .dispose();
      return;
    }

    try {
      await FirebaseFirestore
          .instance
          .collection('scans')
          .doc(docId)
          .update({
        'paymentStatus':
            'Paid',

        'paidAmount':
            amount,

        'paidAt':
            FieldValue
                .serverTimestamp(),

        'paymentReference':
            referenceController.text
                .trim(),

        'receiptNo':
            receiptNo,

        'paidBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,
      });

      await FirebaseFirestore
          .instance
          .collection(
            'audit_logs',
          )
          .add({
        'entityType':
            'scan',

        'entityId':
            docId,

        'action':
            'Payment marked Paid',

        'customerId':
            customerId,

        'amount':
            amount,

        'receiptNo':
            receiptNo,

        'performedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,

        'createdAt':
            FieldValue
                .serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      _showReceipt(
        context,
        receiptNo,
        amount,
        referenceController.text
            .trim(),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Payment update failed: $e',
          ),
        ),
      );
    } finally {
      referenceController
          .dispose();
    }
  }

  void _showReceipt(
    BuildContext context,
    String receiptNo,
    double amount,
    String reference,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            const Text(
          'Payment receipt',
        ),
        content:
            SelectableText(
          'Pothigai Green\n'
          'Receipt: $receiptNo\n'
          'Customer: ${data['customerId'] ?? ''} • ${data['customerName'] ?? ''}\n'
          'Material: ${data['material'] ?? ''}\n'
          'Weight: ${asDouble(data['confirmedWeight']).toStringAsFixed(2)} kg\n'
          'Rate: ₹${asDouble(data['ratePerKg']).toStringAsFixed(2)}/kg\n'
          'Paid: ₹${amount.toStringAsFixed(2)}\n'
          'Reference: ${reference.isEmpty ? 'Cash / not entered' : reference}',
        ),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              context,
            ),
            child:
                const Text(
              'DONE',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final imageUrl =
        '${data['imageUrl'] ?? ''}';

    final customerId =
        '${data['customerId'] ?? ''}';

    final customerName =
        '${data['customerName'] ?? ''}';

    final material =
        '${data['material'] ?? ''}';

    final grade =
        '${data['materialGrade'] ?? ''}';

    final scanDate =
        '${data['scanDate'] ?? ''}';

    final status =
        '${data['status'] ?? ''}';

    final amount =
        asDouble(
      data['amount'],
    );

    final weight =
        asDouble(
      data['confirmedWeight'],
    );

    final rate =
        asDouble(
      data['ratePerKg'],
    );

    final verified =
        data['adminVerified'] ==
            true;

    final paymentStatus =
        '${data['paymentStatus'] ?? (verified ? 'Pending' : 'Not ready')}';

    final receiptNo =
        '${data['receiptNo'] ?? ''}';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          12,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () =>
                  _showImage(
                context,
                imageUrl,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child: imageUrl.isEmpty
                    ? Container(
                        width: 105,
                        height: 105,
                        color:
                            Colors.grey.shade200,
                        child:
                            const Icon(
                          Icons
                              .image_not_supported,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: 105,
                        height: 105,
                        fit:
                            BoxFit.cover,
                        errorBuilder:
                            (
                          _,
                          __,
                          ___,
                        ) =>
                                Container(
                          width: 105,
                          height: 105,
                          color:
                              Colors.grey.shade200,
                          child:
                              const Icon(
                            Icons.broken_image,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$customerId • $customerName',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    '$scanDate • $material${grade.isEmpty ? '' : ' • $grade'}',
                  ),

                  Text(
                    'Status: $status',
                  ),

                  if (verified) ...[
                    Text(
                      'Weight: ${weight.toStringAsFixed(2)} kg',
                    ),
                    Text(
                      'Rate: ₹${rate.toStringAsFixed(2)}/kg',
                    ),
                    Text(
                      'Payable ₹${amount.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        color:
                            pothigaiGreen,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Payment: $paymentStatus',
                    ),
                    if (receiptNo
                        .isNotEmpty)
                      Text(
                        'Receipt: $receiptNo',
                      ),
                  ],

                  const SizedBox(
                    height: 8,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton
                          .tonalIcon(
                        onPressed: () =>
                            _openReview(
                          context,
                        ),
                        icon:
                            const Icon(
                          Icons.fact_check,
                        ),
                        label:
                            Text(
                          verified
                              ? 'REVIEW'
                              : 'VERIFY',
                        ),
                      ),

                      if (verified &&
                          paymentStatus !=
                              'Paid')
                        FilledButton
                            .icon(
                          onPressed: () =>
                              _markPaid(
                            context,
                          ),
                          icon:
                              const Icon(
                            Icons.payments,
                          ),
                          label:
                              const Text(
                            'MARK PAID',
                          ),
                        ),

                      if (paymentStatus ==
                              'Paid' &&
                          receiptNo
                              .isNotEmpty)
                        OutlinedButton
                            .icon(
                          onPressed: () =>
                              _showReceipt(
                            context,
                            receiptNo,
                            asDouble(
                              data['paidAmount'] ??
                                  amount,
                            ),
                            '${data['paymentReference'] ?? ''}',
                          ),
                          icon:
                              const Icon(
                            Icons.receipt_long,
                          ),
                          label:
                              const Text(
                            'RECEIPT',
                          ),
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

class AdminReviewSheet
    extends StatefulWidget {
  const AdminReviewSheet({
    super.key,
    required this.docId,
    required this.initialData,
  });

  final String docId;

  final Map<String, dynamic>
      initialData;

  @override
  State<AdminReviewSheet>
      createState() =>
          _AdminReviewSheetState();
}

class _AdminReviewSheetState
    extends State<AdminReviewSheet> {
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

  String _petCondition =
      'Uncrushed';

  late TextEditingController
      _weightController;

  late TextEditingController
      _rateController;

  bool _busy = false;

  double _previewAmount = 0;

  @override
  void initState() {
    super.initState();

    final initialMaterial =
        '${widget.initialData['material'] ?? 'Other'}';

    _material =
        materials.contains(
      initialMaterial,
    )
            ? initialMaterial
            : 'Other';

    final initialGrade =
        '${widget.initialData['materialGrade'] ?? 'Standard'}';

    _grade =
        grades.contains(
      initialGrade,
    )
            ? initialGrade
            : 'Standard';

    _petCondition =
        '${widget.initialData['petCondition'] ?? 'Uncrushed'}';

    if (_petCondition !=
            'Crushed' &&
        _petCondition !=
            'Uncrushed') {
      _petCondition =
          'Uncrushed';
    }

    final existingWeight =
        asDouble(
      widget.initialData[
          'confirmedWeight'],
    );

    _weightController =
        TextEditingController(
      text: existingWeight > 0
          ? existingWeight
              .toStringAsFixed(
                2,
              )
          : '',
    );

    final existingRate =
        asDouble(
      widget.initialData[
          'ratePerKg'],
    );

    _rateController =
        TextEditingController(
      text: existingRate > 0
          ? existingRate
              .toStringAsFixed(
                2,
              )
          : _defaultRate()
              .toStringAsFixed(
                2,
              ),
    );

    _weightController
        .addListener(
      _recalculatePreview,
    );

    _rateController
        .addListener(
      _recalculatePreview,
    );

    _recalculatePreview();
  }

  @override
  void dispose() {
    _weightController
        .removeListener(
      _recalculatePreview,
    );

    _rateController
        .removeListener(
      _recalculatePreview,
    );

    _weightController
        .dispose();

    _rateController
        .dispose();

    super.dispose();
  }

  double _defaultRate() {
    switch (_material) {
      case 'PET':
        return _petCondition ==
                'Crushed'
            ? 14
            : 12;

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
    final weight =
        double.tryParse(
              _weightController.text
                  .trim(),
            ) ??
            0;

    final rate =
        double.tryParse(
              _rateController.text
                  .trim(),
            ) ??
            0;

    final amount =
        weight * rate;

    if (mounted &&
        amount !=
            _previewAmount) {
      setState(() {
        _previewAmount =
            amount;
      });
    }
  }

  void _applySuggestedRate() {
    _rateController.text =
        _defaultRate()
            .toStringAsFixed(
      2,
    );

    _recalculatePreview();
  }

  Future<void> _approve() async {
    FocusScope.of(context)
        .unfocus();

    final weight =
        double.tryParse(
      _weightController.text
          .trim(),
    );

    final rate =
        double.tryParse(
      _rateController.text
          .trim(),
    );

    if (weight == null ||
        weight <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter verified weight in kg',
          ),
        ),
      );

      return;
    }

    if (rate == null ||
        rate < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid rate',
          ),
        ),
      );

      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final amount =
          weight * rate;

      final beforeMaterial =
          '${widget.initialData['material'] ?? ''}';

      final beforeWeight =
          asDouble(
        widget.initialData[
            'confirmedWeight'],
      );

      final beforeRate =
          asDouble(
        widget.initialData[
            'ratePerKg'],
      );

      await FirebaseFirestore
          .instance
          .collection('scans')
          .doc(
            widget.docId,
          )
          .update({
        'material':
            _material,

        'materialGrade':
            _grade,

        'petCondition':
            _material == 'PET'
                ? _petCondition
                : null,

        'ratePerKg':
            rate,

        'confirmedWeight':
            weight,

        'amount':
            amount,

        'adminVerified':
            true,

        'status':
            'Verified',

        'paymentStatus':
            widget.initialData[
                    'paymentStatus'] ??
                'Pending',

        'verifiedAt':
            FieldValue
                .serverTimestamp(),

        'verifiedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,
      });

      await FirebaseFirestore
          .instance
          .collection(
            'audit_logs',
          )
          .add({
        'entityType':
            'scan',

        'entityId':
            widget.docId,

        'action':
            'Scan verified',

        'customerId':
            widget.initialData[
                'customerId'],

        'before': {
          'material':
              beforeMaterial,
          'weight':
              beforeWeight,
          'rate':
              beforeRate,
        },

        'after': {
          'material':
              _material,
          'grade':
              _grade,
          'weight':
              weight,
          'rate':
              rate,
          'amount':
              amount,
        },

        'performedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,

        'createdAt':
            FieldValue
                .serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Verified: ${weight.toStringAsFixed(2)} kg × ₹${rate.toStringAsFixed(2)} = ₹${amount.toStringAsFixed(2)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Verification failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    setState(() {
      _busy = true;
    });

    try {
      await FirebaseFirestore
          .instance
          .collection('scans')
          .doc(
            widget.docId,
          )
          .update({
        'amount':
            0.0,

        'confirmedWeight':
            null,

        'adminVerified':
            false,

        'paymentStatus':
            'Not payable',

        'status':
            'Rejected',

        'verifiedAt':
            FieldValue
                .serverTimestamp(),

        'verifiedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,
      });

      await FirebaseFirestore
          .instance
          .collection(
            'audit_logs',
          )
          .add({
        'entityType':
            'scan',

        'entityId':
            widget.docId,

        'action':
            'Scan rejected',

        'customerId':
            widget.initialData[
                'customerId'],

        'performedBy':
            FirebaseAuth
                .instance
                .currentUser
                ?.uid,

        'createdAt':
            FieldValue
                .serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(
          context,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Reject failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final imageUrl =
        '${widget.initialData['imageUrl'] ?? ''}';

    final customerId =
        '${widget.initialData['customerId'] ?? ''}';

    final customerName =
        '${widget.initialData['customerName'] ?? ''}';

    final scanDate =
        '${widget.initialData['scanDate'] ?? ''}';

    final confidence =
        asDouble(
      widget.initialData[
          'aiConfidence'],
    );

    final bottomInset =
        MediaQuery.of(
      context,
    ).viewInsets.bottom;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            bottomInset,
      ),
      child:
          FractionallySizedBox(
        heightFactor:
            0.94,
        child: Column(
          children: [
            Container(
              width:
                  46,
              height:
                  5,
              margin:
                  const EdgeInsets.only(
                top: 10,
                bottom: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade400,
                borderRadius:
                    BorderRadius.circular(
                  5,
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify $customerId',
                          style:
                              const TextStyle(
                            fontSize:
                                23,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$customerName • $scanDate',
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed:
                        _busy
                            ? null
                            : () =>
                                Navigator.pop(
                              context,
                            ),
                    icon:
                        const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
            ),

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    if (imageUrl
                        .isNotEmpty)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        child:
                            Image.network(
                          imageUrl,
                          height:
                              180,
                          fit:
                              BoxFit.contain,
                          errorBuilder:
                              (
                            _,
                            __,
                            ___,
                          ) =>
                                  const SizedBox(
                            height:
                                120,
                            child:
                                Center(
                              child:
                                  Icon(
                                Icons.broken_image,
                                size:
                                    50,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'AI confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      value:
                          _material,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Verified material',
                        prefixIcon:
                            Icon(
                          Icons.recycling,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: materials
                          .map(
                            (item) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  item,
                              child:
                                  Text(
                                item,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          _busy
                              ? null
                              : (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setState(() {
                                    _material =
                                        value;
                                  });

                                  _applySuggestedRate();
                                },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    DropdownButtonFormField<
                        String>(
                      value:
                          _grade,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Material grade / quality',
                        prefixIcon:
                            Icon(
                          Icons.grade_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: grades
                          .map(
                            (item) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  item,
                              child:
                                  Text(
                                item,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          _busy
                              ? null
                              : (value) {
                                  setState(() {
                                    _grade =
                                        value ??
                                            _grade;
                                  });
                                },
                    ),

                    if (_material ==
                        'PET') ...[
                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value:
                            _petCondition,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'PET condition',
                          prefixIcon:
                              Icon(
                            Icons.inventory_2_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            const [
                          DropdownMenuItem<
                              String>(
                            value:
                                'Crushed',
                            child:
                                Text(
                              'Crushed',
                            ),
                          ),
                          DropdownMenuItem<
                              String>(
                            value:
                                'Uncrushed',
                            child:
                                Text(
                              'Uncrushed',
                            ),
                          ),
                        ],
                        onChanged:
                            _busy
                                ? null
                                : (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      _petCondition =
                                          value;
                                    });

                                    _applySuggestedRate();
                                  },
                      ),
                    ],

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          _weightController,
                      enabled:
                          !_busy,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal:
                            true,
                      ),
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Verified weight (kg)',
                        hintText:
                            'Example: 2.50',
                        prefixIcon:
                            Icon(
                          Icons.scale,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          _rateController,
                      enabled:
                          !_busy,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal:
                            true,
                      ),
                      textInputAction:
                          TextInputAction.done,
                      onSubmitted:
                          (_) =>
                              FocusScope.of(
                            context,
                          ).unfocus(),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Rate per kg (₹)',
                        hintText:
                            'Example: 12.00',
                        prefixIcon:
                            Icon(
                          Icons.currency_rupee,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child:
                          TextButton.icon(
                        onPressed:
                            _busy
                                ? null
                                : _applySuggestedRate,
                        icon:
                            const Icon(
                          Icons.price_change,
                        ),
                        label:
                            const Text(
                          'USE SUGGESTED RATE',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Card(
                      color:
                          const Color(
                        0xFFE8F5E9,
                      ),
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calculate,
                              color:
                                  pothigaiGreen,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                                  Text(
                                'Calculated payable: ₹${_previewAmount.toStringAsFixed(2)}',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed:
                                _busy
                                    ? null
                                    : _reject,
                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.red,
                            ),
                            label:
                                const Text(
                              'REJECT',
                              style:
                                  TextStyle(
                                color:
                                    Colors.red,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          flex: 2,
                          child:
                              FilledButton.icon(
                            onPressed:
                                _busy
                                    ? null
                                    : _approve,
                            icon: _busy
                                ? const SizedBox(
                                    width:
                                        18,
                                    height:
                                        18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.verified,
                                  ),
                            label:
                                Text(
                              _busy
                                  ? 'SAVING...'
                                  : 'VERIFY & CALCULATE',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),
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