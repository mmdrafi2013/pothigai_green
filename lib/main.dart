import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = <CameraDescription>[];
  }

  runApp(const PothigaiGreenApp());
}

class PothigaiGreenApp extends StatelessWidget {
  const PothigaiGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pothigai Green',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F8F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class PickupRequest {
  PickupRequest({
    required this.category,
    required this.quantity,
    required this.address,
    required this.phone,
    required this.date,
    this.status = 'Requested',
  });

  final String category;
  final String quantity;
  final String address;
  final String phone;
  final DateTime date;
  String status;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _tamil = false;

  final List<PickupRequest> _requests = [];

  void _addRequest(PickupRequest request) {
    setState(() {
      _requests.insert(0, request);
      _index = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        tamil: _tamil,
        onScan: () => setState(() => _index = 1),
        onPickup: () => setState(() => _index = 2),
      ),
      ScannerPage(tamil: _tamil),
      PickupPage(
        tamil: _tamil,
        onSubmit: _addRequest,
      ),
      HistoryPage(
        tamil: _tamil,
        requests: _requests,
      ),
      InfoPage(tamil: _tamil),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tamil ? 'பொதிகை பசுமை' : 'Pothigai Green',
            ),
            const Text(
              'Nagercoil • Tirunelveli • Kanyakumari',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _tamil = !_tamil;
              });
            },
            icon: const Icon(
              Icons.language,
              color: Colors.white,
            ),
            label: Text(
              _tamil ? 'EN' : 'தமிழ்',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
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
            icon: const Icon(Icons.recycling_outlined),
            selectedIcon: const Icon(Icons.recycling),
            label: _tamil ? 'தகவல்' : 'Info',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.tamil,
    required this.onScan,
    required this.onPickup,
  });

  final bool tamil;
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
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF43A047),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tamil
                    ? 'குப்பையிலும் காசு உண்டு'
                    : 'Kuppaiyilum kaasu undu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tamil
                    ? 'கழிவுகளை பிரித்து விற்போம். பசுமையை காப்போம்.'
                    : 'Scan, sort, sell and recycle waste responsibly.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                      ),
                      onPressed: onScan,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        tamil ? 'ஸ்கேன் செய்ய' : 'Scan Waste',
                      ),
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
                      label: Text(
                        tamil ? 'பிக்கப் பதிவு' : 'Book Pickup',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          tamil ? 'இன்றைய விலை' : 'Today\'s Waste Rates',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const RateGrid(),
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
    ['E-Waste', 'Check item'],
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rates.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
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
                  color: Color(0xFF2E7D32),
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

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    required this.tamil,
  });

  final bool tamil;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  final FlutterTts _tts = FlutterTts();

  late final ImageLabeler _imageLabeler;

  bool _ready = false;
  bool _detected = false;
  bool _scanning = false;

  String _result = 'Point camera at a waste item';
  String _details = '';
  String _rate = '';
  String _confidenceText = '';

  @override
  void initState() {
    super.initState();

    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.60,
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
      _detected = false;

      _result = widget.tamil
          ? 'பொருள் ஆய்வு செய்யப்படுகிறது...'
          : 'Analyzing item...';

      _details = '';
      _rate = '';
      _confidenceText = '';
    });

    try {
      final picture =
          await _controller!.takePicture();

      final inputImage =
          InputImage.fromFilePath(
        picture.path,
      );

      final labels =
          await _imageLabeler.processImage(
        inputImage,
      );

      _interpretLabels(labels);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _detected = false;

        _result = widget.tamil
            ? 'ஸ்கேன் செய்ய முடியவில்லை'
            : 'SCAN FAILED';

        _details = widget.tamil
            ? 'மீண்டும் முயற்சிக்கவும்.'
            : 'Please try again.';
      });
    }
  }

  void _interpretLabels(
    List<ImageLabel> labels,
  ) {
    if (labels.isEmpty) {
      _setUnknown();
      return;
    }

    labels.sort(
      (a, b) =>
          b.confidence.compareTo(
        a.confidence,
      ),
    );

    final topLabels =
        labels.take(8).toList();

    final labelMap = <String, double>{};

    for (final label in topLabels) {
      labelMap[
          label.label.toLowerCase()] =
          label.confidence;
    }

    bool hasAny(
      List<String> words, {
      double minimum = 0.60,
    }) {
      for (final entry
          in labelMap.entries) {
        if (entry.value < minimum) {
          continue;
        }

        for (final word in words) {
          if (entry.key.contains(word)) {
            return true;
          }
        }
      }

      return false;
    }

    double bestConfidenceFor(
      List<String> words,
    ) {
      double best = 0;

      for (final entry
          in labelMap.entries) {
        for (final word in words) {
          if (entry.key.contains(word) &&
              entry.value > best) {
            best = entry.value;
          }
        }
      }

      return best;
    }

    String result;
    String details;
    String rate;
    double confidence = 0;

    if (hasAny([
      'mobile phone',
      'cell phone',
      'smartphone',
      'laptop',
      'computer',
      'tablet',
      'keyboard',
      'television',
      'monitor',
      'electronic device',
    ])) {
      result = widget.tamil
          ? 'மின்கழிவு கண்டறியப்பட்டது'
          : 'E-WASTE DETECTED';

      details = widget.tamil
          ? 'மின்னணு சாதனம் கண்டறியப்பட்டது. தரவை அழித்து பேட்டரியை தனியாக கையாளவும்.'
          : 'Electronic device identified. Erase personal data and handle batteries separately.';

      rate = 'E-Waste: Manual valuation';

      confidence = bestConfidenceFor([
        'mobile phone',
        'cell phone',
        'smartphone',
        'laptop',
        'computer',
        'tablet',
        'keyboard',
        'television',
        'monitor',
        'electronic device',
      ]);
    } else if (hasAny([
      'cardboard',
      'carton',
      'shipping box',
      'package',
      'box',
    ])) {
      result = widget.tamil
          ? 'கார்ட்போர்டு கண்டறியப்பட்டது'
          : 'CARDBOARD DETECTED';

      details = widget.tamil
          ? 'கார்ட்போர்டை உலர வைத்துக் கொண்டு தட்டையாக மடிக்கவும்.'
          : 'Keep cardboard dry and flatten it before collection.';

      rate = 'Cardboard: ₹6/kg';

      confidence = bestConfidenceFor([
        'cardboard',
        'carton',
        'shipping box',
        'package',
        'box',
      ]);
    } else if (hasAny([
      'paper',
      'newspaper',
      'document',
      'book',
      'magazine',
      'printed material',
    ])) {
      result = widget.tamil
          ? 'காகிதம் கண்டறியப்பட்டது'
          : 'PAPER DETECTED';

      details = widget.tamil
          ? 'காகிதத்தை உலர வைத்துக் கொண்டு மற்ற கழிவுகளில் இருந்து பிரிக்கவும்.'
          : 'Keep paper dry and separated from other waste.';

      rate = 'Paper: ₹8/kg';

      confidence = bestConfidenceFor([
        'paper',
        'newspaper',
        'document',
        'book',
        'magazine',
        'printed material',
      ]);
    } else if (hasAny([
      'bottle',
      'water bottle',
      'plastic bottle',
    ])) {
      result = widget.tamil
          ? 'பாட்டில் கண்டறியப்பட்டது'
          : 'BOTTLE DETECTED';

      details = widget.tamil
          ? 'இது PET என்று தானாக உறுதி செய்யப்படவில்லை. பாட்டிலின் கீழே உள்ள resin code 1 ஐ சரிபார்க்கவும்.'
          : 'Bottle detected, but PET is NOT automatically confirmed. Check for resin code 1 (PET) on the bottle.';

      rate =
          'If PET: Crushed ₹14/kg • Uncrushed ₹12/kg';

      confidence = bestConfidenceFor([
        'bottle',
        'water bottle',
        'plastic bottle',
      ]);
    } else if (hasAny([
      'plastic',
      'plastic container',
      'container',
      'food container',
    ])) {
      result = widget.tamil
          ? 'பிளாஸ்டிக் பொருள் கண்டறியப்பட்டது'
          : 'PLASTIC ITEM DETECTED';

      details = widget.tamil
          ? 'PET / HDPE / LDPE / PP வகையை தோற்றத்தால் மட்டும் உறுதி செய்ய முடியாது. Resin code ஐ சரிபார்க்கவும்.'
          : 'PET / HDPE / LDPE / PP cannot be reliably confirmed by appearance alone. Check the resin identification code.';

      rate =
          'PET ₹12–14 | HDPE ₹18 | LDPE ₹10 | PP ₹12';

      confidence = bestConfidenceFor([
        'plastic',
        'plastic container',
        'container',
        'food container',
      ]);
    } else if (hasAny([
      'battery',
      'battery charger',
    ])) {
      result = widget.tamil
          ? 'பேட்டரி / மின்கழிவு கண்டறியப்பட்டது'
          : 'BATTERY / E-WASTE DETECTED';

      details = widget.tamil
          ? 'பேட்டரியை பொதுக் கழிவுடன் கலக்க வேண்டாம்.'
          : 'Do not mix batteries with general recyclable waste.';

      rate = 'Battery: Manual valuation';

      confidence = bestConfidenceFor([
        'battery',
        'battery charger',
      ]);
    } else {
      _setUnknown(
        labels: topLabels,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _detected = true;
      _scanning = false;

      _result = result;
      _details = details;
      _rate = rate;

      _confidenceText =
          confidence > 0
              ? 'Recognition confidence: ${(confidence * 100).toStringAsFixed(0)}%'
              : '';
    });
  }

  void _setUnknown({
    List<ImageLabel>? labels,
  }) {
    String debugLabels = '';

    if (labels != null &&
        labels.isNotEmpty) {
      debugLabels = labels
          .take(3)
          .map(
            (e) =>
                '${e.label} ${(e.confidence * 100).toStringAsFixed(0)}%',
          )
          .join(' • ');
    }

    if (!mounted) return;

    setState(() {
      _detected = true;
      _scanning = false;

      _result = widget.tamil
          ? 'அடையாளம் காணப்படாத பொருள்'
          : 'UNKNOWN / MATERIAL CHECK REQUIRED';

      _details = widget.tamil
          ? 'இந்த பொருளை நம்பகமாக கழிவு வகையாக அடையாளம் காண முடியவில்லை.'
          : 'The scanner cannot confidently classify this item as one of the supported waste categories.';

      _rate = 'No automatic rate';

      _confidenceText =
          debugLabels.isEmpty
              ? ''
              : 'AI labels: $debugLabels';
    });
  }

  void _clearScan() {
    _tts.stop();

    setState(() {
      _detected = false;
      _scanning = false;

      _result = widget.tamil
          ? 'புதிய பொருளை கேமரா முன் வைக்கவும்'
          : 'Point camera at a new waste item';

      _details = '';
      _rate = '';
      _confidenceText = '';
    });
  }

  Future<void> _speak() async {
    if (!_detected) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            widget.tamil
                ? 'முதலில் பொருளை ஸ்கேன் செய்யவும்'
                : 'Please scan an item first',
          ),
        ),
      );

      return;
    }

    await _tts.stop();

    await _tts.speak(
      '$_result. $_details. $_rate',
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
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF43A047),
              ),
            ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black
                    .withOpacity(0.68),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                widget.tamil
                    ? 'ஒரு பொருளை மட்டும் கேமரா முன் தெளிவாக வைக்கவும்'
                    : 'Place one waste item clearly inside the camera view',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black
                    .withOpacity(0.72),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: _detected
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
                      color: _detected
                          ? Colors.greenAccent
                          : Colors.white,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (_details.isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
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

                  if (_rate.isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      _rate,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],

                  if (_confidenceText
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 10,
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
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 18,
            right: 18,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          FilledButton.icon(
                        onPressed:
                            _scanning
                                ? null
                                : _scan,
                        icon: _scanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .center_focus_strong,
                              ),
                        label: Text(
                          _scanning
                              ? (widget.tamil
                                  ? 'ஆய்வு...'
                                  : 'ANALYZING...')
                              : (widget.tamil
                                  ? 'ஸ்கேன்'
                                  : 'SCAN'),
                        ),
                        style:
                            FilledButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF2E7D32,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          FilledButton
                              .tonalIcon(
                        onPressed:
                            _speak,
                        icon: const Icon(
                          Icons.volume_up,
                        ),
                        label: Text(
                          widget.tamil
                              ? 'தமிழ் குரல்'
                              : 'TAMIL VOICE',
                        ),
                        style:
                            FilledButton
                                .styleFrom(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_detected) ...[
                  const SizedBox(
                    height: 10,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _clearScan,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: Text(
                        widget.tamil
                            ? 'அழித்து புதிய ஸ்கேன்'
                            : 'CLEAR & NEW SCAN',
                      ),
                      style:
                          OutlinedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            const Color(
                          0xFF2E7D32,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFF2E7D32,
                          ),
                          width: 2,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
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
    required this.onSubmit,
  });

  final bool tamil;
  final ValueChanged<PickupRequest> onSubmit;

  @override
  State<PickupPage> createState() =>
      _PickupPageState();
}

class _PickupPageState
    extends State<PickupPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _quantityController =
      TextEditingController();

  final _addressController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  String _category = 'PET Bottles';

  static const categories = [
    'PET Bottles',
    'HDPE Plastic',
    'LDPE Plastic',
    'PP Plastic',
    'Paper',
    'Cardboard',
    'E-Waste',
    'Mixed Recyclables',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    widget.onSubmit(
      PickupRequest(
        category: _category,
        quantity:
            _quantityController.text.trim(),
        address:
            _addressController.text.trim(),
        phone:
            _phoneController.text.trim(),
        date: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          widget.tamil
              ? 'பிக்கப் கோரிக்கை பதிவு செய்யப்பட்டது'
              : 'Pickup request created successfully',
        ),
      ),
    );

    _quantityController.clear();
    _addressController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
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
                InputDecoration(
              labelText: widget.tamil
                  ? 'கழிவு வகை'
                  : 'Waste category',
              border:
                  const OutlineInputBorder(),
            ),
            items: categories
                .map(
                  (item) =>
                      DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _category =
                    value ?? _category;
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
                  value.trim().length <
                      8) {
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
              hintText:
                  'Nagercoil / Tirunelveli / Kanyakumari',
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
            onPressed: _submit,
            icon: const Icon(
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

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.tamil,
    required this.requests,
  });

  final bool tamil;
  final List<PickupRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          tamil
              ? 'பிக்கப் வரலாறு இல்லை'
              : 'No pickup history yet',
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (
        context,
        index,
      ) {
        final request =
            requests[index];

        return Card(
          child: ListTile(
            title:
                Text(request.category),
            subtitle: Text(
              '${request.quantity}\n${request.address}',
            ),
            trailing: Chip(
              label: Text(
                request.status,
              ),
            ),
          ),
        );
      },
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.tamil,
  });

  final bool tamil;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        Text(
          tamil
              ? 'பசுமை வழிகாட்டி'
              : 'Green Guide',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        const Card(
          child: ListTile(
            leading: Icon(
              Icons.recycling,
              color:
                  Color(0xFF2E7D32),
            ),
            title: Text(
              'Separate waste before pickup',
            ),
            subtitle: Text(
              'Keep PET, paper, cardboard, e-waste and batteries separate.',
            ),
          ),
        ),
      ],
    );
  }
}
