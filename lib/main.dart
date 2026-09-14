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
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
        ),
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

class ScanDecision {
  const ScanDecision({
    required this.category,
    required this.confidence,
  });

  final String category;
  final double confidence;
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
      ScannerPage(
        tamil: _tamil,
      ),
      PickupPage(
        tamil: _tamil,
        onSubmit: _addRequest,
      ),
      HistoryPage(
        tamil: _tamil,
        requests: _requests,
      ),
      InfoPage(
        tamil: _tamil,
      ),
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
                        side: const BorderSide(
                          color: Colors.white,
                        ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
  bool _scanning = false;
  bool _hasResult = false;
  bool _resultConfirmed = false;
  bool _needsResinConfirmation = false;

  String _result = 'Point camera at a waste item';
  String _details = '';
  String _rate = '';
  String _confidenceText = '';

  String? _detectedCategory;
  String? _confirmedMaterial;

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
      _confirmedMaterial = null;
      _detectedCategory = null;

      _result = widget.tamil
          ? '3 படங்கள் ஆய்வு செய்யப்படுகிறது...'
          : 'Analyzing 3 frames...';

      _details = '';
      _rate = '';
      _confidenceText = '';
    });

    try {
      final decisions = <ScanDecision>[];

      for (int i = 0; i < 3; i++) {
        final decision = await _analyzeSingleFrame();

        decisions.add(decision);

        if (i < 2) {
          await Future.delayed(
            const Duration(milliseconds: 350),
          );
        }
      }

      _combineDecisions(decisions);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _result = widget.tamil
            ? 'ஸ்கேன் தோல்வி'
            : 'SCAN FAILED';
        _details = widget.tamil
            ? 'மீண்டும் முயற்சிக்கவும்.'
            : 'Please try again.';
      });
    }
  }

  Future<ScanDecision> _analyzeSingleFrame() async {
    final picture = await _controller!.takePicture();

    final inputImage = InputImage.fromFilePath(
      picture.path,
    );

    final labels = await _imageLabeler.processImage(
      inputImage,
    );

    return _classifyLabels(labels);
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

    double findBest(List<String> words) {
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
      ]),
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

    counts.forEach((category, votes) {
      if (votes > winningVotes) {
        winningVotes = votes;
        winningCategory = category;
      }
    });

    final averageConfidence =
        (totals[winningCategory] ?? 0) /
            (counts[winningCategory] ?? 1);

    if (winningCategory == 'unknown' ||
        winningVotes < 2 ||
        averageConfidence < minimumConfidence) {
      _showUnknown(
        winningVotes,
        averageConfidence,
      );
      return;
    }

    _showDetectedResult(
      winningCategory,
      winningVotes,
      averageConfidence,
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
        result = widget.tamil
            ? 'பாட்டில் கண்டறியப்பட்டது'
            : 'BOTTLE DETECTED';

        details = widget.tamil
            ? 'பாட்டில் வகை கண்டறியப்பட்டது. PET என்று இன்னும் உறுதி செய்யப்படவில்லை.'
            : 'Bottle detected. PET has NOT been confirmed yet. Check the resin code.';

        requiresResin = true;
        break;

      case 'plastic':
        result = widget.tamil
            ? 'பிளாஸ்டிக் பொருள் கண்டறியப்பட்டது'
            : 'PLASTIC ITEM DETECTED';

        details = widget.tamil
            ? 'பிளாஸ்டிக் வகையை resin code மூலம் உறுதி செய்யவும்.'
            : 'Confirm the plastic type using the resin identification code.';

        requiresResin = true;
        break;

      case 'paper':
        result = widget.tamil
            ? 'காகிதம் கண்டறியப்பட்டது'
            : 'PAPER DETECTED';

        details = widget.tamil
            ? 'காகிதம் என்று AI கண்டறிந்துள்ளது. உறுதி செய்யவும்.'
            : 'AI identified this as paper. Please confirm.';

        rate = 'Paper: ₹8/kg';
        break;

      case 'cardboard':
        result = widget.tamil
            ? 'கார்ட்போர்டு கண்டறியப்பட்டது'
            : 'CARDBOARD DETECTED';

        details = widget.tamil
            ? 'கார்ட்போர்டு என்று AI கண்டறிந்துள்ளது.'
            : 'AI identified this as cardboard.';

        rate = 'Cardboard: ₹6/kg';
        break;

      case 'ewaste':
        result = widget.tamil
            ? 'மின்கழிவு கண்டறியப்பட்டது'
            : 'E-WASTE DETECTED';

        details = widget.tamil
            ? 'மின்னணு சாதனம் என்று கண்டறியப்பட்டது.'
            : 'Electronic equipment detected.';

        rate = 'E-Waste: Manual valuation';
        break;

      case 'battery':
        result = widget.tamil
            ? 'பேட்டரி கண்டறியப்பட்டது'
            : 'BATTERY DETECTED';

        details = widget.tamil
            ? 'பேட்டரியை தனியாக பாதுகாப்பாக சேகரிக்கவும்.'
            : 'Keep batteries separate for safe recycling.';

        rate = 'Battery: Manual valuation';
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
      _rate = rate;

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
      _detectedCategory = 'unknown';

      _result = widget.tamil
          ? 'அடையாளம் உறுதி செய்ய முடியவில்லை'
          : 'UNKNOWN / MATERIAL CHECK REQUIRED';

      _details = widget.tamil
          ? 'AI போதுமான நம்பிக்கையுடன் இந்த பொருளை அடையாளம் காணவில்லை.'
          : 'The AI does not have enough confidence to classify this item safely.';

      _rate = 'No automatic rate';

      _confidenceText =
          '$votes/3 frames agreed • ${(confidence * 100).toStringAsFixed(0)}% confidence';
    });
  }

  void _confirmResin(
    String code,
    String material,
  ) {
    String rate;

    switch (code) {
      case '1':
        rate =
            'PET: Crushed ₹14/kg • Uncrushed ₹12/kg';
        break;

      case '2':
        rate = 'HDPE: ₹18/kg';
        break;

      case '4':
        rate = 'LDPE: ₹10/kg';
        break;

      case '5':
        rate = 'PP: ₹12/kg';
        break;

      default:
        rate = 'Manual material valuation';
    }

    setState(() {
      _confirmedMaterial = material;
      _resultConfirmed = true;

      _result = '$material CONFIRMED';

      _details =
          'Material confirmed using resin code $code.';

      _rate = rate;

      _needsResinConfirmation = false;
    });
  }

  void _confirmDetectedResult() {
    setState(() {
      _resultConfirmed = true;

      _details =
          '${_details.trim()} Result confirmed by user.';
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
          'Unknown',
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
                  leading: const Icon(
                    Icons.recycling,
                  ),
                  title: Text(item),
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

    if (selected == null) return;

    String rate;

    switch (selected) {
      case 'PET':
        rate =
            'Crushed ₹14/kg • Uncrushed ₹12/kg';
        break;
      case 'HDPE':
        rate = '₹18/kg';
        break;
      case 'LDPE':
        rate = '₹10/kg';
        break;
      case 'PP':
        rate = '₹12/kg';
        break;
      case 'Paper':
        rate = '₹8/kg';
        break;
      case 'Cardboard':
        rate = '₹6/kg';
        break;
      case 'E-Waste':
      case 'Battery':
        rate = 'Manual valuation';
        break;
      default:
        rate = 'No automatic rate';
    }

    setState(() {
      _resultConfirmed =
          selected != 'Unknown';

      _confirmedMaterial = selected;

      _result = selected == 'Unknown'
          ? 'UNKNOWN / MATERIAL CHECK REQUIRED'
          : '$selected CONFIRMED';

      _details =
          'Corrected manually by user.';

      _rate = rate;

      _needsResinConfirmation = false;
    });
  }

  void _clearScan() {
    _tts.stop();

    setState(() {
      _scanning = false;
      _hasResult = false;
      _resultConfirmed = false;
      _needsResinConfirmation = false;

      _detectedCategory = null;
      _confirmedMaterial = null;

      _result = widget.tamil
          ? 'புதிய பொருளை கேமரா முன் வைக்கவும்'
          : 'Point camera at a new waste item';

      _details = '';
      _rate = '';
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
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.all(10),
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
                    ? 'ஒரு பொருளை மட்டும் தெளிவாக கேமரா முன் வைக்கவும்'
                    : 'Place ONE item clearly in the camera. Good lighting improves accuracy.',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Center(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                80,
                22,
                170,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.black
                      .withOpacity(
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

                    if (_details
                        .isNotEmpty) ...[
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
                          color: Colors
                              .orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (_rate
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        _rate,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .bold,
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
                          color:
                              Colors.white,
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
                            WrapAlignment
                                .center,
                        children: [
                          ActionChip(
                            label:
                                const Text(
                              '1 PET',
                            ),
                            onPressed: () =>
                                _confirmResin(
                              '1',
                              'PET',
                            ),
                          ),
                          ActionChip(
                            label:
                                const Text(
                              '2 HDPE',
                            ),
                            onPressed: () =>
                                _confirmResin(
                              '2',
                              'HDPE',
                            ),
                          ),
                          ActionChip(
                            label:
                                const Text(
                              '4 LDPE',
                            ),
                            onPressed: () =>
                                _confirmResin(
                              '4',
                              'LDPE',
                            ),
                          ),
                          ActionChip(
                            label:
                                const Text(
                              '5 PP',
                            ),
                            onPressed: () =>
                                _confirmResin(
                              '5',
                              'PP',
                            ),
                          ),
                          ActionChip(
                            label:
                                const Text(
                              'OTHER',
                            ),
                            onPressed: () =>
                                _confirmResin(
                              '?',
                              'OTHER PLASTIC',
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_hasResult &&
                        !_needsResinConfirmation &&
                        !_resultConfirmed &&
                        _detectedCategory !=
                            'unknown') ...[
                      const SizedBox(
                        height: 14,
                      ),

                      FilledButton.icon(
                        onPressed:
                            _confirmDetectedResult,
                        icon: const Icon(
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
                        height: 10,
                      ),

                      TextButton.icon(
                        onPressed:
                            _manualCorrection,
                        icon: const Icon(
                          Icons.edit,
                          color:
                              Colors.white,
                        ),
                        label:
                            const Text(
                          'WRONG RESULT / CHOOSE MANUALLY',
                          style: TextStyle(
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
                            Icons
                                .verified,
                            color: Colors
                                .greenAccent,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            'Material confirmed',
                            style:
                                TextStyle(
                              color: Colors
                                  .greenAccent,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
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
                            _scanning
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
                                Icons
                                    .center_focus_strong,
                              ),
                        label: Text(
                          _scanning
                              ? 'ANALYZING 3 FRAMES...'
                              : 'SCAN',
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
                          FilledButton
                              .tonalIcon(
                        onPressed:
                            _speak,
                        icon: const Icon(
                          Icons.volume_up,
                        ),
                        label: const Text(
                          'TAMIL VOICE',
                        ),
                        style:
                            FilledButton
                                .styleFrom(
                          padding:
                              const EdgeInsets
                                  .symmetric(
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
                          _clearScan,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text(
                        'CLEAR & NEW SCAN',
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
                        padding:
                            const EdgeInsets
                                .symmetric(
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
    required this.onSubmit,
  });

  final bool tamil;
  final ValueChanged<PickupRequest> onSubmit;

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  final _formKey = GlobalKey<FormState>();

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
    'Battery',
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSubmit(
      PickupRequest(
        category: _category,
        quantity: _quantityController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        date: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pickup request created successfully',
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.tamil
                ? 'கழிவு சேகரிப்பு பதிவு'
                : 'Book Waste Pickup',
            style:
                Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _category = value ?? _category;
              });
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Approx. quantity / weight',
              hintText: 'Example: 8 kg or 2 bags',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter quantity';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 8) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Pickup address',
              hintText: 'Nagercoil / Tirunelveli / Kanyakumari',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter pickup address';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(
              Icons.check_circle_outline,
            ),
            label: const Text(
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
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];

        return Card(
          child: ListTile(
            title: Text(
              request.category,
            ),
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tamil ? 'பசுமை வழிகாட்டி' : 'Green Guide',
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(
              Icons.recycling,
              color: Color(0xFF2E7D32),
            ),
            title: Text(
              'Plastic resin codes',
            ),
            subtitle: Text(
              '1 = PET • 2 = HDPE • 4 = LDPE • 5 = PP. '
              'Use the recycling symbol on the product to confirm the plastic type.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF2E7D32),
            ),
            title: Text(
              'Improve scan accuracy',
            ),
            subtitle: Text(
              'Scan one object at a time, use good lighting, keep the object close and avoid busy backgrounds.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(
              Icons.warning_amber,
              color: Colors.orange,
            ),
            title: Text(
              'AI is guidance, not final proof',
            ),
            subtitle: Text(
              'When confidence is low or the material cannot be verified, the app will return UNKNOWN instead of guessing.',
            ),
          ),
        ),
      ],
    );
  }
}
