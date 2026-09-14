import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
      PickupPage(tamil: _tamil, onSubmit: _addRequest),
      HistoryPage(tamil: _tamil, requests: _requests),
      InfoPage(tamil: _tamil),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tamil ? 'பொதிகை பசுமை' : 'Pothigai Green'),
            const Text(
              'Nagercoil • Tirunelveli • Kanyakumari',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _tamil = !_tamil),
            icon: const Icon(Icons.language, color: Colors.white),
            label: Text(
              _tamil ? 'EN' : 'தமிழ்',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: _tamil ? 'முகப்பு' : 'Home'),
          NavigationDestination(icon: const Icon(Icons.center_focus_strong), label: _tamil ? 'ஸ்கேன்' : 'Scan'),
          NavigationDestination(icon: const Icon(Icons.local_shipping), label: _tamil ? 'பிக்கப்' : 'Pickup'),
          NavigationDestination(icon: const Icon(Icons.receipt_long), label: _tamil ? 'வரலாறு' : 'History'),
          NavigationDestination(icon: const Icon(Icons.recycling), label: _tamil ? 'தகவல்' : 'Info'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.tamil, required this.onScan, required this.onPickup});

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
            gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF43A047)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tamil ? 'குப்பையிலும் காசு உண்டு' : 'Kuppaiyilum kaasu undu',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tamil ? 'கழிவுகளை பிரித்து விற்போம். பசுமையை காப்போம்.' : 'Scan, sort, sell and recycle waste responsibly.',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2E7D32)),
                      onPressed: onScan,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(tamil ? 'ஸ்கேன் செய்ய' : 'Scan Waste'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      onPressed: onPickup,
                      icon: const Icon(Icons.local_shipping),
                      label: Text(tamil ? 'பிக்கப் பதிவு' : 'Book Pickup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(tamil ? 'இன்றைய விலை' : 'Today\'s Waste Rates', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const RateGrid(),
        const SizedBox(height: 18),
        Text(tamil ? 'எப்படி செயல்படுகிறது?' : 'How it works', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _step(Icons.camera_alt_outlined, tamil ? '1. பொருளை ஸ்கேன் செய்யவும்' : '1. Scan the waste item', tamil ? 'வகை மற்றும் விலையை அறியவும்' : 'Identify type and estimated rate'),
        _step(Icons.scale_outlined, tamil ? '2. எடையை குறிப்பிடவும்' : '2. Enter approximate weight', tamil ? 'கிலோ / பைகள் / எண்ணிக்கை' : 'Kg / bags / number of items'),
        _step(Icons.local_shipping_outlined, tamil ? '3. பிக்கப் பதிவு செய்யவும்' : '3. Book a pickup', tamil ? 'உங்கள் முகவரியில் சேகரிப்பு' : 'Collection from your address'),
        _step(Icons.currency_rupee, tamil ? '4. எடை & பணம்' : '4. Weigh & get paid', tamil ? 'உறுதி செய்யப்பட்ட எடைக்கு பணம்' : 'Payment based on confirmed weight'),
      ],
    );
  }

  Widget _step(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: Icon(icon, color: const Color(0xFF2E7D32))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.25, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (context, index) {
        final item = rates[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFC8E6C9))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item[0], style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(item[1], style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        );
      },
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.tamil});
  final bool tamil;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _detected = false;
  String _result = 'Point camera at a waste item';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      if (mounted) setState(() => _result = 'No camera available');
      return;
    }
    _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _result = 'Camera initialization failed');
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.45);
  }

  void _scan() {
    setState(() {
      _detected = true;
      _result = widget.tamil ? 'PET பாட்டில் கண்டறியப்பட்டது' : 'PET BOTTLE DETECTED / பிஇடி பாட்டில்';
    });
  }

  Future<void> _speak() async {
    await _tts.speak('PET bottle kandupidikkappattathu. Crushed rate pathinaalu rupaai per kilo. Uncrushed rate pannirandu rupaai per kilo.');
  }

  @override
  void dispose() {
    _controller?.dispose();
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
          if (_ready && _controller != null) CameraPreview(_controller!) else const Center(child: CircularProgressIndicator(color: Color(0xFF43A047))),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(14)),
              child: Text(widget.tamil ? 'பொருளை கேமரா பெட்டிக்குள் வைக்கவும்' : 'Place the waste item inside the camera view', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.68), borderRadius: BorderRadius.circular(18), border: Border.all(color: _detected ? Colors.greenAccent : Colors.white54, width: 2)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_result, textAlign: TextAlign.center, style: TextStyle(color: _detected ? Colors.greenAccent : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_detected) ...[
                    const SizedBox(height: 14),
                    const Text('Crushed PET: ₹14/kg ✅', style: TextStyle(color: Colors.white, fontSize: 17)),
                    const Text('Uncrushed PET: ₹12/kg', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('AI detection is currently simulated', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 18,
            right: 18,
            child: Row(
              children: [
                Expanded(child: FilledButton.icon(onPressed: _scan, icon: const Icon(Icons.center_focus_strong), label: Text(widget.tamil ? 'ஸ்கேன்' : 'SCAN'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 16)))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.tonalIcon(onPressed: _speak, icon: const Icon(Icons.volume_up), label: Text(widget.tamil ? 'தமிழ் குரல்' : 'TAMIL VOICE'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PickupPage extends StatefulWidget {
  const PickupPage({super.key, required this.tamil, required this.onSubmit});
  final bool tamil;
  final ValueChanged<PickupRequest> onSubmit;

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = 'PET Bottles';

  static const categories = ['PET Bottles', 'HDPE Plastic', 'LDPE Plastic', 'PP Plastic', 'Paper', 'Cardboard', 'E-Waste', 'Mixed Recyclables'];

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(PickupRequest(category: _category, quantity: _quantityController.text.trim(), address: _addressController.text.trim(), phone: _phoneController.text.trim(), date: DateTime.now()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.tamil ? 'பிக்கப் கோரிக்கை பதிவு செய்யப்பட்டது' : 'Pickup request created successfully')));
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
          Text(widget.tamil ? 'கழிவு சேகரிப்பு பதிவு' : 'Book Waste Pickup', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(widget.tamil ? 'உங்கள் வீட்டிலிருந்து அல்லது கடையிலிருந்து சேகரிப்பதற்கு பதிவு செய்யவும்.' : 'Request collection from your home, shop, school or office.'),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(labelText: widget.tamil ? 'கழிவு வகை' : 'Waste category', border: const OutlineInputBorder()),
            items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 14),
          TextFormField(controller: _quantityController, decoration: InputDecoration(labelText: widget.tamil ? 'அளவு / எடை' : 'Approx. quantity / weight', hintText: 'Example: 8 kg or 2 bags', border: const OutlineInputBorder()), validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter quantity' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: widget.tamil ? 'தொலைபேசி எண்' : 'Phone number', border: const OutlineInputBorder()), validator: (value) => (value == null || value.trim().length < 8) ? 'Please enter a valid phone number' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _addressController, maxLines: 3, decoration: InputDecoration(labelText: widget.tamil ? 'பிக்கப் முகவரி' : 'Pickup address', hintText: 'Nagercoil / Tirunelveli / Kanyakumari', border: const OutlineInputBorder()), validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter pickup address' : null),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check_circle_outline), label: Text(widget.tamil ? 'பிக்கப் பதிவு செய்யவும்' : 'CONFIRM PICKUP'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))),
          const SizedBox(height: 12),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Row(children: [Icon(Icons.info_outline, color: Color(0xFF2E7D32)), SizedBox(width: 10), Expanded(child: Text('Final payment depends on actual category, condition and verified weight at collection.'))]))),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.tamil, required this.requests});
  final bool tamil;
  final List<PickupRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long, size: 72, color: Color(0xFF81C784)),
            const SizedBox(height: 12),
            Text(tamil ? 'பிக்கப் வரலாறு இல்லை' : 'No pickup history yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(tamil ? 'பிக்கப் பதிவு செய்ததும் இங்கே காணலாம்.' : 'Your pickup requests will appear here.', textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(request.category, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))), Chip(label: Text(request.status), avatar: const Icon(Icons.schedule, size: 18))]),
              Text('${tamil ? 'அளவு' : 'Quantity'}: ${request.quantity}'),
              const SizedBox(height: 4),
              Text('${tamil ? 'முகவரி' : 'Address'}: ${request.address}'),
              const SizedBox(height: 4),
              Text('${tamil ? 'தொலைபேசி' : 'Phone'}: ${request.phone}'),
            ]),
          ),
        );
      },
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.tamil});
  final bool tamil;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tamil ? 'பசுமை வழிகாட்டி' : 'Green Guide', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _info(Icons.water_drop_outlined, tamil ? 'பாட்டில்களை காலி செய்யவும்' : 'Empty bottles before pickup', tamil ? 'PET பாட்டில்களில் தண்ணீர் அல்லது பானம் இருக்கக் கூடாது.' : 'Remove liquids from PET bottles before handing them over.'),
        _info(Icons.compress, tamil ? 'PET பாட்டில்களை நசுக்கவும்' : 'Crush PET bottles', tamil ? 'நசுக்கிய PET அதிக மதிப்பும் குறைந்த சேமிப்பு இடமும் தரும்.' : 'Crushed PET saves space and has a higher listed rate.'),
        _info(Icons.delete_sweep_outlined, tamil ? 'கழிவுகளை பிரிக்கவும்' : 'Keep waste separated', tamil ? 'PET, HDPE, காகிதம், கார்ட்போர்டு மற்றும் மின்கழிவுகளை தனித்தனியாக வைக்கவும்.' : 'Separate PET, HDPE, paper, cardboard and e-waste.'),
        _info(Icons.battery_alert_outlined, tamil ? 'பேட்டரிகளை தனியாக வைக்கவும்' : 'Handle batteries separately', tamil ? 'பேட்டரிகளை மற்ற கழிவுகளுடன் கலக்க வேண்டாம்.' : 'Do not mix batteries with general recyclable waste.'),
        _info(Icons.phonelink_erase_outlined, tamil ? 'மின்கழிவுகளில் தரவை அழிக்கவும்' : 'Erase data from electronics', tamil ? 'மொபைல் மற்றும் கணினி கொடுக்கும் முன் தனிப்பட்ட தரவை அழிக்கவும்.' : 'Remove personal data from phones and computers before recycling.'),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFE8F5E9),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Icon(Icons.park, color: Color(0xFF2E7D32), size: 42),
              const SizedBox(height: 8),
              Text('Pothigai Hills Eco', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(tamil ? 'நாகர்கோவில் • திருநெல்வேலி • கன்னியாகுமரி பகுதிக்கான உள்ளூர் மறுசுழற்சி முயற்சி.' : 'A local waste collection and recycling initiative for Nagercoil, Tirunelveli and Kanyakumari region.', textAlign: TextAlign.center),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: Icon(icon, color: const Color(0xFF2E7D32))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(body),
      ),
    );
  }
}
