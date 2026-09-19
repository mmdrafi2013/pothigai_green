import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

late List<CameraDescription> cameras;

const Color project2Green = Color(0xFF2E7D32);

const Map<String, double> defaultRates = <String, double>{
  'Plastic': 12.0,
  'Bottle': 12.0,
  'Paper': 8.0,
  'Cardboard': 6.0,
  'Glass': 5.0,
  'Metal': 25.0,
  'E-Waste': 15.0,
  'Textile': 5.0,
  'Other': 0.0,
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = <CameraDescription>[];
  }

  runApp(const Project2App());
}

class Project2App extends StatelessWidget {
  const Project2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pothigai Green Project 2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: project2Green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F8F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: project2Green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const Project2ScannerPage(),
    );
  }
}

class AiSuggestion {
  const AiSuggestion({
    required this.category,
    required this.confidence,
    required this.source,
  });

  final String category;
  final double confidence;
  final String source;
}

class Project2ScannerPage extends StatefulWidget {
  const Project2ScannerPage({super.key});

  @override
  State<Project2ScannerPage> createState() => _Project2ScannerPageState();
}

class _Project2ScannerPageState extends State<Project2ScannerPage> {
  CameraController? _camera;
  final FlutterTts _tts = FlutterTts();

  late final ImageLabeler _imageLabeler;

  Interpreter? _v3Interpreter;
  Interpreter? _v4Interpreter;
  Interpreter? _v5Interpreter;

  bool _v3Ready = false;
  bool _v4Ready = false;
  bool _v5Ready = false;

  bool _cameraReady = false;
  bool _scanning = false;
  bool _tamil = false;

  String _aiSuggestion = '';
  double _aiConfidence = 0.0;
  String _aiSource = '';
  String? _collectorSelection;

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
    'Textile',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.45),
    );

    _initTts();
    _initModels();
    _initCamera();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _initModels() async {
    await Future.wait<void>([
      _loadModel(
        asset: 'assets/ai/pothigai_waste_classifier_v3_fp16.tflite',
        assign: (value) {
          _v3Interpreter = value;
          _v3Ready = value != null;
        },
      ),
      _loadModel(
        asset: 'assets/ai/pothigai_waste_classifier_v4_fp16.tflite',
        assign: (value) {
          _v4Interpreter = value;
          _v4Ready = value != null;
        },
      ),
      _loadModel(
        asset: 'assets/ai/pothigai_waste_classifier_v5_fp16.tflite',
        assign: (value) {
          _v5Interpreter = value;
          _v5Ready = value != null;
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
    } catch (_) {
      if (mounted) assign(null);
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _camera = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cameraReady = false);
      }
    }
  }

  Future<AiSuggestion> _predictModel({
    required Interpreter interpreter,
    required String filePath,
    required int imageSize,
    required String source,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return const AiSuggestion(
        category: 'Other',
        confidence: 0,
        source: 'decode-failed',
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

    var bestIndex = 0;
    var bestScore = scores.first;

    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    return AiSuggestion(
      category: _mapModelLabel(_modelLabels[bestIndex]),
      confidence: bestScore,
      source: source,
    );
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

  Future<AiSuggestion?> _hybridSuggestion(String filePath) async {
    final decisions = <AiSuggestion>[];

    if (_v3Ready && _v3Interpreter != null) {
      try {
        decisions.add(
          await _predictModel(
            interpreter: _v3Interpreter!,
            filePath: filePath,
            imageSize: 224,
            source: 'V3',
          ),
        );
      } catch (_) {}
    }

    if (_v4Ready && _v4Interpreter != null) {
      try {
        decisions.add(
          await _predictModel(
            interpreter: _v4Interpreter!,
            filePath: filePath,
            imageSize: 256,
            source: 'V4',
          ),
        );
      } catch (_) {}
    }

    if (_v5Ready && _v5Interpreter != null) {
      try {
        decisions.add(
          await _predictModel(
            interpreter: _v5Interpreter!,
            filePath: filePath,
            imageSize: 256,
            source: 'V5',
          ),
        );
      } catch (_) {}
    }

    if (decisions.isEmpty) return null;

    final groups = <String, List<AiSuggestion>>{};

    for (final item in decisions) {
      groups.putIfAbsent(item.category, () => <AiSuggestion>[]).add(item);
    }

    String bestCategory = decisions.first.category;
    List<AiSuggestion> bestGroup = groups[bestCategory]!;

    for (final entry in groups.entries) {
      if (entry.value.length > bestGroup.length) {
        bestCategory = entry.key;
        bestGroup = entry.value;
      }
    }

    final average = bestGroup
            .map((e) => e.confidence)
            .fold<double>(0.0, (a, b) => a + b) /
        bestGroup.length;

    return AiSuggestion(
      category: bestCategory,
      confidence: average,
      source: bestGroup.length >= 2 ? 'V3/V4/V5 consensus' : bestGroup.first.source,
    );
  }

  AiSuggestion _genericSuggestion(List<ImageLabel> labels) {
    if (labels.isEmpty) {
      return const AiSuggestion(
        category: 'Other',
        confidence: 0,
        source: 'ML Kit',
      );
    }

    final sorted = labels.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    double scoreFor(List<String> words) {
      var best = 0.0;

      for (final label in sorted.take(12)) {
        final value = label.label.toLowerCase();

        for (final word in words) {
          if (value.contains(word) && label.confidence > best) {
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

    var category = 'Other';
    var confidence = 0.0;

    for (final entry in scores.entries) {
      if (entry.value > confidence) {
        category = entry.key;
        confidence = entry.value;
      }
    }

    return AiSuggestion(
      category: category,
      confidence: confidence,
      source: 'ML Kit',
    );
  }

  AiSuggestion _combineAi(
    AiSuggestion? hybrid,
    AiSuggestion generic,
  ) {
    if (generic.category != 'Other' &&
        generic.confidence >= 0.70 &&
        (hybrid == null ||
            generic.category == 'Bottle' ||
            generic.category == 'E-Waste' ||
            generic.category == 'Textile')) {
      return generic;
    }

    if (hybrid != null) {
      return hybrid;
    }

    return generic;
  }

  Future<void> _scan() async {
    if (_camera == null ||
        !_camera!.value.isInitialized ||
        _scanning) {
      return;
    }

    setState(() {
      _scanning = true;
      _aiSuggestion = '';
      _aiConfidence = 0;
      _aiSource = '';
      _collectorSelection = null;
      _weightController.clear();
    });

    try {
      final frameResults = <AiSuggestion>[];

      for (var i = 0; i < 3; i++) {
        final picture = await _camera!.takePicture();

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

      final finalSuggestion = _combineFrames(frameResults);

      if (!mounted) return;

      setState(() {
        _scanning = false;
        _aiSuggestion = finalSuggestion.category;
        _aiConfidence = finalSuggestion.confidence;
        _aiSource = finalSuggestion.source;
      });

      await _speakSuggestion();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _aiSuggestion = 'Other';
        _aiConfidence = 0;
        _aiSource = 'manual';
      });
    }
  }

  AiSuggestion _combineFrames(List<AiSuggestion> items) {
    final counts = <String, int>{};
    final totals = <String, double>{};

    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
      totals[item.category] =
          (totals[item.category] ?? 0) + item.confidence;
    }

    var category = items.first.category;
    var votes = 0;

    for (final entry in counts.entries) {
      if (entry.value > votes) {
        votes = entry.value;
        category = entry.key;
      }
    }

    final average =
        (totals[category] ?? 0) / (counts[category] ?? 1);

    return AiSuggestion(
      category: category,
      confidence: average,
      source: '$votes/3 frames',
    );
  }

  Future<void> _speakSuggestion() async {
    if (_aiSuggestion.isEmpty) return;

    await _tts.stop();

    final message = _tamil
        ? '${_tamilCategory(_aiSuggestion)} 喈庎喁嵿喁� 喈氞瘑喈喈� 喈喈苦喁嵿喁佮喁堗畷喁嵿畷喈苦喈む瘉. 喈氞喈苦喈距 喈掂畷喁堗喁� 喈曕瘈喈脆瘒 喈む瘒喈班瘝喈掂瘉 喈氞瘑喈瘝喈喁佮喁�.'
        : 'The app suggests $_aiSuggestion. Please choose the correct category below.';

    await _tts.speak(message);
  }

  String _tamilCategory(String category) {
    switch (category) {
      case 'Plastic':
        return '喈喈赤喈膏瘝喈熰喈曕瘝';
      case 'Bottle':
        return '喈喈熰瘝喈熰喈侧瘝';
      case 'Paper':
        return '喈曕喈曕喈む喁�';
      case 'Cardboard':
        return '喈呧疅喁嵿疅喁�';
      case 'Glass':
        return '喈曕喁嵿喈距疅喈�';
      case 'Metal':
        return '喈夃喁嬥畷喈瘝';
      case 'E-Waste':
        return '喈喈┼瘝喈┼喁� 喈曕喈苦喁�';
      case 'Textile':
        return '喈む瘉喈｀';
      default:
        return '喈喁嵿喈掂瘓';
    }
  }

  String _displayCategory(String category) {
    if (!_tamil) return category;
    return _tamilCategory(category);
  }

  double get _selectedRate {
    final category = _collectorSelection;
    if (category == null) return 0;
    return defaultRates[category] ?? 0;
  }

  double get _weight =>
      double.tryParse(_weightController.text.trim()) ?? 0;

  double get _amount => _weight * _selectedRate;

  void _selectCategory(String category) {
    setState(() {
      _collectorSelection = category;
    });
  }

  void _clear() {
    setState(() {
      _aiSuggestion = '';
      _aiConfidence = 0;
      _aiSource = '';
      _collectorSelection = null;
      _weightController.clear();
    });
  }

  Widget _cameraArea() {
    if (!_cameraReady || _camera == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'Opening camera...',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_camera!);
  }

  Widget _categoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _collectorChoices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.25,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final category = _collectorChoices[index];
        final selected = category == _collectorSelection;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectCategory(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? project2Green
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? project2Green
                    : const Color(0xFFC8E6C9),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(category),
                  color: selected
                      ? Colors.white
                      : project2Green,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      case 'Textile':
        return Icons.checkroom_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _resultCard() {
    if (_aiSuggestion.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _tamil
                ? '喈掄喁� 喈瘖喈班瘉喈赤瘓 喈疅喁嵿疅喁佮喁� 喈曕瘒喈喈距喈苦喁� 喈曕喈熰瘝喈熰 SCAN 喈呧喁佮喁嵿喈掂瘉喈瘝.'
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
              _tamil
                  ? '喈氞瘑喈喈� 喈喈苦喁嵿喁佮喁�'
                  : 'AI SUGGESTION',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E6E55),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _displayCategory(_aiSuggestion),
              style: const TextStyle(
                fontSize: 26,
                color: project2Green,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_aiConfidence * 100).toStringAsFixed(0)}% 鈥� $_aiSource',
              style: const TextStyle(
                color: Color(0xFF5E6A60),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tamil
                  ? '喈囙喁� 喈掄喁� 喈喈苦喁嵿喁佮喁� 喈疅喁嵿疅喁佮喁�. 喈曕瘈喈脆瘒 喈氞喈苦喈距 喈掂畷喁堗喁� 喈ㄠ瘈喈權瘝喈曕喁� 喈む瘒喈班瘝喈掂瘉 喈氞瘑喈瘝喈喁佮喁�.'
                  : 'This is only a suggestion. Collector must choose the correct category below.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateCard() {
    final category = _collectorSelection;

    if (category == null) {
      return const SizedBox.shrink();
    }

    final rate = _selectedRate;

    return Card(
      color: const Color(0xFFF1F8E9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: project2Green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tamil
                        ? '喈む瘒喈班瘝喈掂瘉: ${_displayCategory(category)}'
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
              rate > 0
                  ? '${_tamil ? '喈囙喈侧瘝喈瘉喈ㄠ喈侧瘓 喈掂喈侧瘓' : 'Default rate'}: 鈧�${rate.toStringAsFixed(2)}/kg'
                  : (_tamil
                      ? '喈囙喈侧瘝喈瘉喈ㄠ喈侧瘓 喈掂喈侧瘓 喈囙喁嵿喁�'
                      : 'No default rate'),
              style: const TextStyle(
                color: project2Green,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _tamil
                    ? '喈庎疅喁� (喈曕喈侧瘚)'
                    : 'Weight (kg)',
                prefixIcon: const Icon(Icons.scale_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: project2Green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _tamil
                        ? '喈曕喈曕瘝喈曕喈熰喁嵿喈熰瘝喈� 喈む瘖喈曕瘓'
                        : 'Calculated amount',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '鈧�${_amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateTable() {
    return ExpansionTile(
      title: Text(
        _tamil
            ? '喈囙喈侧瘝喈瘉喈ㄠ喈侧瘓 喈掂喈侧瘓 喈疅喁嵿疅喈苦喈侧瘝'
            : 'Default rate list',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: defaultRates.entries.map((entry) {
        return ListTile(
          dense: true,
          title: Text(
            _displayCategory(entry.key),
          ),
          trailing: Text(
            entry.value > 0
                ? '鈧�${entry.value.toStringAsFixed(2)}/kg'
                : '鈧�0.00/kg',
            style: const TextStyle(
              color: project2Green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _camera?.dispose();
    _v3Interpreter?.close();
    _v4Interpreter?.close();
    _v5Interpreter?.close();
    _imageLabeler.close();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pothigai Green',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Project 2 鈥� Simple Collector',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
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
              _tamil ? 'EN' : '喈む喈苦喁�',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 245,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _cameraArea(),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: project2Green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    onPressed: _scanning ? null : _scan,
                    icon: _scanning
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.center_focus_strong,
                          ),
                    label: Text(
                      _scanning
                          ? (_tamil
                              ? '喈膏瘝喈曕瘒喈┼瘝 喈氞瘑喈瘝喈曕喈编喁�...'
                              : 'SCANNING...')
                          : (_tamil
                              ? '喈瘖喈班瘉喈赤瘓 喈膏瘝喈曕瘒喈┼瘝 喈氞瘑喈瘝'
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
                _resultCard(),
                const SizedBox(height: 10),
                Text(
                  _tamil
                      ? '喈氞喈苦喈距 喈掂畷喁堗喁� 喈む瘒喈班瘝喈掂瘉 喈氞瘑喈瘝喈喁佮喁�'
                      : 'Collector: choose the correct category',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _categoryGrid(),
                const SizedBox(height: 12),
                _rateCard(),
                const SizedBox(height: 8),
                Card(
                  child: _rateTable(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _tamil
                        ? '喈瘉喈む喈� 喈膏瘝喈曕瘒喈┼瘝'
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