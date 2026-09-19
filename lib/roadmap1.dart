import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color roadmapGreen = Color(0xFF2E7D32);

double _r1Double(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

DateTime _r1Date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _r1Money(double value) => '鈧�${value.toStringAsFixed(2)}';
String _r1Kg(double value) => '${value.toStringAsFixed(2)} kg';

class Roadmap1HubPage extends StatelessWidget {
  const Roadmap1HubPage({
    super.key,
    required this.profile,
    required this.isAdmin,
  });

  final Map<String, dynamic> profile;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final tabs = isAdmin
        ? const [
            Tab(text: 'Overview'),
            Tab(text: 'Rates'),
            Tab(text: 'Logistics'),
            Tab(text: 'AI'),
            Tab(text: 'Inventory'),
            Tab(text: 'ESG / EPR'),
          ]
        : const [
            Tab(text: 'Overview'),
            Tab(text: 'Rates'),
            Tab(text: 'Pickup'),
            Tab(text: 'Rewards'),
            Tab(text: 'Guide'),
          ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Roadmap-1'),
              Text(
                isAdmin
                    ? 'Operations 鈥� AI 鈥� Recycler 鈥� ESG'
                    : 'Scan 鈥� Sell 鈥� Collect 鈥� Pay 鈥� Learn',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: isAdmin
              ? [
                  Roadmap1Overview(profile: profile, isAdmin: true),
                  const Roadmap1RatesPage(isAdmin: true),
                  Roadmap1PickupTracker(profile: profile, isAdmin: true),
                  const Roadmap1AiQualityPage(),
                  const Roadmap1InventoryPage(),
                  const Roadmap1EsgPage(isAdmin: true),
                ]
              : [
                  Roadmap1Overview(profile: profile, isAdmin: false),
                  const Roadmap1RatesPage(isAdmin: false),
                  Roadmap1PickupTracker(profile: profile, isAdmin: false),
                  Roadmap1RewardsPage(profile: profile),
                  const Roadmap1DisposalGuidePage(),
                ],
        ),
      ),
    );
  }
}

class Roadmap1Overview extends StatelessWidget {
  const Roadmap1Overview({
    super.key,
    required this.profile,
    required this.isAdmin,
  });

  final Map<String, dynamic> profile;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final scanStream = isAdmin
        ? FirebaseFirestore.instance.collection('scans').snapshots()
        : FirebaseFirestore.instance
            .collection('scans')
            .where('customerUid', isEqualTo: uid)
            .snapshots();

    final pickupStream = isAdmin
        ? FirebaseFirestore.instance.collection('pickup_requests').snapshots()
        : FirebaseFirestore.instance
            .collection('pickup_requests')
            .where('customerUid', isEqualTo: uid)
            .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: scanStream,
      builder: (context, scanSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: pickupStream,
          builder: (context, pickupSnapshot) {
            if (scanSnapshot.hasError) {
              return Center(child: Text('Unable to load scans: ${scanSnapshot.error}'));
            }
            if (pickupSnapshot.hasError) {
              return Center(child: Text('Unable to load pickups: ${pickupSnapshot.error}'));
            }
            if (!scanSnapshot.hasData || !pickupSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final scans = scanSnapshot.data!.docs;
            final pickups = pickupSnapshot.data!.docs;

            final verifiedKg = scans.fold<double>(0, (sum, doc) {
              final d = doc.data();
              return d['adminVerified'] == true
                  ? sum + _r1Double(d['confirmedWeight'])
                  : sum;
            });

            final payable = scans.fold<double>(
              0,
              (sum, doc) => sum + _r1Double(doc.data()['amount']),
            );

            final paid = scans.fold<double>(0, (sum, doc) {
              final d = doc.data();
              final status = '${d['paymentStatus'] ?? ''}'.toLowerCase();
              if (status != 'paid') return sum;
              return sum + _r1Double(d['paidAmount'] ?? d['amount']);
            });

            final pickedUpKg = pickups.fold<double>(
              0,
              (sum, doc) => sum + _r1Double(doc.data()['pickedUpWeightKg']),
            );

            final openPickups = pickups.where((doc) {
              final d = doc.data();
              final status =
                  '${d['pickupStatus'] ?? d['status'] ?? 'Requested'}';
              return status != 'Closed' &&
                  status != 'Cancelled' &&
                  status != 'Picked Up';
            }).length;

            final reviewedAi = scans.where((doc) {
              final d = doc.data();
              return d['adminFinalMaterial'] != null ||
                  d['aiBroadCorrect'] != null;
            }).length;

            final correctAi = scans.where((doc) {
              return doc.data()['aiBroadCorrect'] == true;
            }).length;

            final aiAccuracy = reviewedAi == 0
                ? null
                : (correctAi / reviewedAi) * 100;

            final points = (pickedUpKg * 10).floor();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(
                  title: isAdmin
                      ? 'Pothigai Green Control Center'
                      : 'Your Green Dashboard',
                  subtitle: isAdmin
                      ? 'Roadmap-1 combines operations, AI, material recovery and ESG.'
                      : 'One place for recycling, pickup, payment and rewards.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Verified',
                      value: _r1Kg(verifiedKg),
                      icon: Icons.verified,
                    ),
                    _MetricCard(
                      label: 'Picked Up',
                      value: _r1Kg(pickedUpKg),
                      icon: Icons.local_shipping,
                    ),
                    _MetricCard(
                      label: 'Payable',
                      value: _r1Money(payable),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _MetricCard(
                      label: 'Paid',
                      value: _r1Money(paid),
                      icon: Icons.payments_outlined,
                    ),
                    _MetricCard(
                      label: 'Open Pickups',
                      value: '$openPickups',
                      icon: Icons.pending_actions,
                    ),
                    _MetricCard(
                      label: isAdmin ? 'AI Reviewed' : 'Green Points',
                      value: isAdmin
                          ? '$reviewedAi'
                          : '$points',
                      icon: isAdmin
                          ? Icons.psychology_alt_outlined
                          : Icons.stars_outlined,
                    ),
                  ],
                ),
                if (isAdmin && aiAccuracy != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.analytics_outlined,
                        color: roadmapGreen,
                      ),
                      title: const Text('Real-world AI verification accuracy'),
                      subtitle: Text(
                        '${aiAccuracy.toStringAsFixed(1)}% from $reviewedAi admin-reviewed scans',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Roadmap-1 preserves the existing scanner, pickup, admin verification and payment flows. New intelligence is derived from the same verified Firestore records, so existing data remains compatible.',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Roadmap1RatesPage extends StatelessWidget {
  const Roadmap1RatesPage({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  static const fallbackRates = <Map<String, dynamic>>[
    {'material': 'PET Crushed', 'ratePerKg': 14.0},
    {'material': 'PET Uncrushed', 'ratePerKg': 12.0},
    {'material': 'HDPE', 'ratePerKg': 18.0},
    {'material': 'LDPE', 'ratePerKg': 10.0},
    {'material': 'PP', 'ratePerKg': 12.0},
    {'material': 'Paper', 'ratePerKg': 8.0},
    {'material': 'Cardboard', 'ratePerKg': 6.0},
  ];

  String _docId(String material) {
    return material
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _editRate(
    BuildContext context,
    String material,
    double current,
  ) async {
    final controller = TextEditingController(
      text: current.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update $material'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Rate per kg',
            prefixText: '鈧� ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                double.tryParse(controller.text.trim()),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value < 0) return;

    await FirebaseFirestore.instance
        .collection('rates')
        .doc(_docId(material))
        .set({
      'material': material,
      'ratePerKg': value,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$material rate updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('rates').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load rates: ${snapshot.error}'));
        }

        final live = <String, double>{};
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final d = doc.data();
            if (d['active'] == false) continue;
            final material = '${d['material'] ?? doc.id}'.trim();
            if (material.isEmpty) continue;
            live[material] = _r1Double(d['ratePerKg']);
          }
        }

        final items = <Map<String, dynamic>>[];

        if (live.isEmpty) {
          items.addAll(fallbackRates);
        } else {
          final known = <String>{};
          for (final fallback in fallbackRates) {
            final material = '${fallback['material']}';
            known.add(material);
            items.add({
              'material': material,
              'ratePerKg':
                  live[material] ?? _r1Double(fallback['ratePerKg']),
            });
          }

          for (final entry in live.entries) {
            if (!known.contains(entry.key)) {
              items.add({
                'material': entry.key,
                'ratePerKg': entry.value,
              });
            }
          }
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final material = '${items[index]['material']}';
            final rate = _r1Double(items[index]['ratePerKg']);

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.currency_rupee),
                ),
                title: Text(material),
                subtitle: const Text('Live rate master'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '鈧�${rate.toStringAsFixed(2)}/kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: roadmapGreen,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Edit rate',
                        onPressed: () => _editRate(
                          context,
                          material,
                          rate,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class Roadmap1PickupTracker extends StatelessWidget {
  const Roadmap1PickupTracker({
    super.key,
    required this.profile,
    required this.isAdmin,
  });

  final Map<String, dynamic> profile;
  final bool isAdmin;

  Future<void> _verifyOtp(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final controller = TextEditingController();

    final typed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verify pickup OTP'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Customer OTP',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (typed == null || typed.isEmpty) return;

    final expected = '${doc.data()['pickupOtp'] ?? ''}'.trim();

    if (expected.isEmpty || typed != expected) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP does not match')),
      );
      return;
    }

    await doc.reference.update({
      'pickupVerificationStatus': 'Verified',
      'pickupVerifiedAt': FieldValue.serverTimestamp(),
      'pickupVerifiedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pickup OTP verified')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final stream = isAdmin
        ? FirebaseFirestore.instance
            .collection('pickup_requests')
            .snapshots()
        : FirebaseFirestore.instance
            .collection('pickup_requests')
            .where('customerUid', isEqualTo: uid)
            .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load pickups: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList()
          ..sort(
            (a, b) => _r1Date(b.data()['createdAt'])
                .compareTo(_r1Date(a.data()['createdAt'])),
          );

        if (docs.isEmpty) {
          return const Center(
            child: Text('No pickup requests yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final d = doc.data();
            final status =
                '${d['pickupStatus'] ?? d['status'] ?? 'Requested'}';
            final otp = '${d['pickupOtp'] ?? ''}'.trim();
            final verified =
                '${d['pickupVerificationStatus'] ?? 'Pending'}' == 'Verified';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${d['category'] ?? 'Recyclables'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        _StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAdmin
                          ? '${d['customerId'] ?? ''} 鈥� ${d['customerName'] ?? ''}'
                          : 'Pickup ID: ${doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Requested: ${d['quantity'] ?? ''}  鈥�  Picked: ${_r1Kg(_r1Double(d['pickedUpWeightKg']))}',
                    ),
                    if ('${d['assignedCollector'] ?? ''}'.trim().isNotEmpty)
                      Text('Collector: ${d['assignedCollector']}'),
                    if ('${d['vehicleReference'] ?? ''}'.trim().isNotEmpty)
                      Text('Vehicle: ${d['vehicleReference']}'),
                    if (otp.isNotEmpty) ...[
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAdmin
                                  ? 'Pickup OTP available'
                                  : 'Pickup OTP: $otp',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: verified
                                    ? Colors.green
                                    : roadmapGreen,
                              ),
                            ),
                          ),
                          if (verified)
                            const Chip(
                              avatar: Icon(
                                Icons.verified,
                                size: 16,
                              ),
                              label: Text('Verified'),
                            )
                          else if (isAdmin)
                            FilledButton.tonal(
                              onPressed: () => _verifyOtp(
                                context,
                                doc,
                              ),
                              child: const Text('VERIFY OTP'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class Roadmap1RewardsPage extends StatelessWidget {
  const Roadmap1RewardsPage({
    super.key,
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('customerUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load rewards: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final kg = snapshot.data!.docs.fold<double>(
          0,
          (sum, doc) => sum + _r1Double(doc.data()['pickedUpWeightKg']),
        );

        final earned = (kg * 10).floor();
        final adjustment = _r1Double(profile['greenPointsAdjustment']).round();
        final redeemed = _r1Double(profile['greenPointsRedeemed']).round();
        final balance = earned + adjustment - redeemed;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(
              title: '$balance Green Points',
              subtitle: '10 points for every verified kilogram picked up.',
            ),
            const SizedBox(height: 14),
            _RewardRow(
              label: 'Recovered material',
              value: _r1Kg(kg),
            ),
            _RewardRow(
              label: 'Earned points',
              value: '$earned',
            ),
            _RewardRow(
              label: 'Bonus adjustment',
              value: '$adjustment',
            ),
            _RewardRow(
              label: 'Redeemed',
              value: '$redeemed',
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Rewards are calculated from completed pickup weight. Redemption products can be connected later without changing the existing pickup/payment records.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Roadmap1DisposalGuidePage extends StatelessWidget {
  const Roadmap1DisposalGuidePage({super.key});

  static const items = <Map<String, String>>[
    {
      'title': 'PET / HDPE / LDPE / PP',
      'body':
          'Empty the container, remove food residue, keep it dry and confirm the resin code before sale. Do not guess the resin from appearance alone.',
    },
    {
      'title': 'Paper & Cardboard',
      'body':
          'Keep clean and dry. Separate heavily food-soiled paper. Flatten cartons to reduce collection volume.',
    },
    {
      'title': 'Glass',
      'body':
          'Keep separate from flexible plastics. Handle broken glass in a rigid container and label it clearly.',
    },
    {
      'title': 'Metal',
      'body':
          'Separate cans, foil and scrap metal. Remove liquids and sharp loose contaminants when safe to do so.',
    },
    {
      'title': 'E-Waste',
      'body':
          'Do not dismantle batteries or circuit boards at home. Use an authorized e-waste collection or recycling channel.',
    },
    {
      'title': 'Batteries',
      'body':
          'Keep terminals protected where appropriate, isolate damaged batteries and never mix leaking batteries with household recyclables.',
    },
    {
      'title': 'Wet / Organic Waste',
      'body':
          'Keep separate from dry recyclables. Compost suitable food and garden waste where local facilities support it.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ExpansionTile(
            leading: const Icon(
              Icons.recycling,
              color: roadmapGreen,
            ),
            title: Text(
              item['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(item['body']!),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Roadmap1AiQualityPage extends StatelessWidget {
  const Roadmap1AiQualityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('scans').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load AI data: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final reviewed = docs.where((doc) {
          final d = doc.data();
          return d['aiBroadCorrect'] != null ||
              '${d['adminFinalMaterial'] ?? ''}'.trim().isNotEmpty;
        }).toList();

        final correct =
            reviewed.where((doc) => doc.data()['aiBroadCorrect'] == true).length;

        final candidates = docs.where((doc) {
          final d = doc.data();
          return d['trainingEligible'] == true ||
              '${d['trainingLabelSource'] ?? ''}' == 'admin_verified';
        }).length;

        final modelCounts = <String, int>{};
        for (final doc in docs) {
          final version =
              '${doc.data()['modelVersion'] ?? 'unknown'}'.trim();
          modelCounts[version] = (modelCounts[version] ?? 0) + 1;
        }

        final duplicateMap = <String, int>{};
        for (final doc in docs) {
          final imageUrl = '${doc.data()['imageUrl'] ?? ''}'.trim();
          if (imageUrl.isEmpty) continue;
          duplicateMap[imageUrl] = (duplicateMap[imageUrl] ?? 0) + 1;
        }
        final duplicateFlags =
            duplicateMap.values.where((count) => count > 1).length;

        final accuracy =
            reviewed.isEmpty ? 0.0 : (correct / reviewed.length) * 100;

        final modelEntries = modelCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  label: 'Reviewed',
                  value: '${reviewed.length}',
                  icon: Icons.fact_check_outlined,
                ),
                _MetricCard(
                  label: 'Correct',
                  value: '$correct',
                  icon: Icons.check_circle_outline,
                ),
                _MetricCard(
                  label: 'Accuracy',
                  value: reviewed.isEmpty
                      ? 'No data'
                      : '${accuracy.toStringAsFixed(1)}%',
                  icon: Icons.analytics_outlined,
                ),
                _MetricCard(
                  label: 'Training Queue',
                  value: '$candidates',
                  icon: Icons.model_training,
                ),
                _MetricCard(
                  label: 'Duplicate Flags',
                  value: '$duplicateFlags',
                  icon: Icons.copy_all_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Model-path usage',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...modelEntries.map(
              (entry) => Card(
                child: ListTile(
                  leading: const Icon(Icons.memory),
                  title: Text(entry.key),
                  trailing: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'The hybrid scanner runs on-device. Admin corrections remain the trusted labels for future retraining. Low-confidence scans continue to use the existing fallback/manual confirmation path.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Roadmap1InventoryPage extends StatelessWidget {
  const Roadmap1InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('scans').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load material ledger: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final kgByMaterial = <String, double>{};
        final valueByMaterial = <String, double>{};

        for (final doc in snapshot.data!.docs) {
          final d = doc.data();
          if (d['adminVerified'] != true) continue;

          final material =
              '${d['adminFinalMaterial'] ?? d['material'] ?? 'Other'}';
          kgByMaterial[material] =
              (kgByMaterial[material] ?? 0) +
                  _r1Double(d['confirmedWeight']);
          valueByMaterial[material] =
              (valueByMaterial[material] ?? 0) +
                  _r1Double(d['amount']);
        }

        final entries = kgByMaterial.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (entries.isEmpty) {
          return const Center(
            child: Text('No verified material inventory yet'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Material Recovery Ledger 鈥� derived from Admin-verified scans. This provides a safe inventory foundation without changing existing scan records.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(entry.key),
                  subtitle: Text(
                    'Recorded value: ${_r1Money(valueByMaterial[entry.key] ?? 0)}',
                  ),
                  trailing: Text(
                    _r1Kg(entry.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: roadmapGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Roadmap1EsgPage extends StatelessWidget {
  const Roadmap1EsgPage({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load ESG data: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final kg = snapshot.data!.docs.fold<double>(
          0,
          (sum, doc) => sum + _r1Double(doc.data()['pickedUpWeightKg']),
        );

        final landfillDiverted = kg;
        final estimatedCo2e = kg * 1.5;
        final points = (kg * 10).floor();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(
              title: 'Impact & EPR Foundation',
              subtitle:
                  'Operational recycling data converted into auditable sustainability indicators.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  label: 'Recovered',
                  value: _r1Kg(kg),
                  icon: Icons.recycling,
                ),
                _MetricCard(
                  label: 'Landfill diverted',
                  value: _r1Kg(landfillDiverted),
                  icon: Icons.delete_outline,
                ),
                _MetricCard(
                  label: 'Est. CO鈧俥 avoided',
                  value: '${estimatedCo2e.toStringAsFixed(1)} kg',
                  icon: Icons.eco_outlined,
                ),
                _MetricCard(
                  label: 'Green points',
                  value: '$points',
                  icon: Icons.stars_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'CO鈧俥 is an indicative planning estimate, not a certified carbon claim. Formal EPR/ESG reporting should use recycler certificates, material-specific verified factors and applicable regulatory records.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF43A047),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: roadmapGreen,
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 3),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.stars_outlined,
          color: roadmapGreen,
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final done = status == 'Picked Up' || status == 'Closed';
    final cancelled = status == 'Cancelled';

    return Chip(
      avatar: Icon(
        done
            ? Icons.check_circle
            : cancelled
                ? Icons.cancel
                : Icons.timelapse,
        size: 16,
      ),
      label: Text(status),
    );
  }
}