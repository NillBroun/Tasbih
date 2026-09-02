import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF161719),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TasbihApp());
}

class TasbihApp extends StatelessWidget {
  const TasbihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasbih',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF161719),
        cardColor: const Color(0xFF222428),
        dialogBackgroundColor: const Color(0xFF222428),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00B074),
          surface: Color(0xFF222428),
        ),
      ),
      home: const TasbihScreen(),
    );
  }
}

class DhikrItem {
  String title;
  String arabic;
  String meaning;
  int count;
  int total;

  DhikrItem({
    required this.title,
    required this.arabic,
    required this.meaning,
    this.count = 0,
    this.total = 0,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'arabic': arabic,
        'meaning': meaning,
        'count': count,
        'total': total,
      };

  factory DhikrItem.fromMap(Map<String, dynamic> map) => DhikrItem(
        title: map['title'] ?? '',
        arabic: map['arabic'] ?? '',
        meaning: map['meaning'] ?? '',
        count: map['count'] ?? 0,
        total: map['total'] ?? 0,
      );
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  List<DhikrItem> dhikrList = [
    DhikrItem(
      title: 'SubhanAllah',
      arabic: 'سُبْحَانَ اللّٰهِ',
      meaning: 'Glory be to Allah',
    ),
    DhikrItem(
      title: 'Alhamdulillah',
      arabic: 'الْحَمْدُ لِلّٰهِ',
      meaning: 'All praise is due to Allah',
    ),
    DhikrItem(
      title: 'Allahu Akbar',
      arabic: 'اللّٰهُ أَكْبَرُ',
      meaning: 'Allah is the Greatest',
    ),
    DhikrItem(
      title: 'Kalima Tayyibah',
      arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ مُحَمَّدٌ رَسُولُ اللّٰهِ',
      meaning: 'There is no god but Allah, Muhammad is the Messenger of Allah',
    ),
    DhikrItem(
      title: 'Istighfar',
      arabic: 'أَسْتَغْفِرُ اللّٰهَ وَأَتُوبُ إِلَيْهِ',
      meaning: 'I seek forgiveness from Allah and turn to Him in repentance',
    ),
    DhikrItem(
      title: 'Durood Sharif',
      arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ',
      meaning: 'O Allah, send blessings upon Muhammad and the family of Muhammad',
    ),
    DhikrItem(
      title: 'Hawqala',
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
      meaning: 'There is no power nor strength except with Allah',
    ),
  ];

  int currentIndex = 0;
  int targetCount = 33;
  bool isSoundOn = true;
  bool isVibrationOn = true;

  final String fbPageUrl = 'https://www.facebook.com/profile.php?id=61581691871822';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('tasbih_dhikr_data');
    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      setState(() {
        dhikrList = decoded.map((e) => DhikrItem.fromMap(e)).toList();
      });
    }
    setState(() {
      currentIndex = prefs.getInt('current_index') ?? 0;
      targetCount = prefs.getInt('target_count') ?? 33;
      isSoundOn = prefs.getBool('sound_on') ?? true;
      isVibrationOn = prefs.getBool('vibration_on') ?? true;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(dhikrList.map((e) => e.toMap()).toList());
    await prefs.setString('tasbih_dhikr_data', encoded);
    await prefs.setInt('current_index', currentIndex);
    await prefs.setInt('target_count', targetCount);
    await prefs.setBool('sound_on', isSoundOn);
    await prefs.setBool('vibration_on', isVibrationOn);
  }

  void _incrementCounter() {
    setState(() {
      dhikrList[currentIndex].count++;
      dhikrList[currentIndex].total++;
    });

    if (isSoundOn) {
      SystemSound.play(SystemSoundType.click);
    }

    if (isVibrationOn) {
      if (dhikrList[currentIndex].count % targetCount == 0) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    _saveData();
  }

  void _resetCurrentCount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        title: const Text('Reset Counter', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to reset the current count to 0?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                dhikrList[currentIndex].count = 0;
              });
              _saveData();
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDhikrListModal() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF1E2024),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Dhikr',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00B074)),
                    tooltip: 'Add Custom Dhikr',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddDhikrDialog();
                    },
                  )
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: dhikrList.length,
                itemBuilder: (context, idx) {
                  final item = dhikrList[idx];
                  final isSelected = idx == currentIndex;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.white.withOpacity(0.05),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF00B074) : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      item.arabic,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    trailing: Text(
                      'Total: ${item.total}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    onTap: () {
                      setState(() => currentIndex = idx);
                      _saveData();
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    final backupData = {
      'dhikr_list': dhikrList.map((e) => e.toMap()).toList(),
      'target_count': targetCount,
      'app': 'Tasbih',
      'developer': 'AHM',
    };
    await Clipboard.setData(ClipboardData(text: jsonEncode(backupData)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup code copied to clipboard! Keep it safe.'),
          backgroundColor: Color(0xFF00B074),
        ),
      );
    }
  }

  void _showRestoreDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        title: const Text('Restore Backup', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your backup code below to restore counts:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Paste JSON code here...',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B074)),
            onPressed: () {
              try {
                final Map<String, dynamic> decoded = jsonDecode(textController.text.trim());
                if (decoded.containsKey('dhikr_list')) {
                  final List list = decoded['dhikr_list'];
                  setState(() {
                    dhikrList = list.map((e) => DhikrItem.fromMap(e)).toList();
                    currentIndex = 0;
                    if (decoded.containsKey('target_count')) {
                      targetCount = decoded['target_count'];
                    }
                  });
                  _saveData();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data restored successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception();
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid backup format!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('📿', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Text('About Tasbih', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A digital tasbih application designed for seamless daily Dhikr & Remembrance of Allah.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Divider(color: Colors.white12, height: 22),
            const Text(
              'Developer: AHM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(fbPageUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.facebook, color: Colors.blueAccent, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Follow Facebook Page',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00B074))),
          ),
        ],
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF222428),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settings & Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text('Sound', style: TextStyle(color: Colors.white)),
                  secondary: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off, color: Colors.lightBlueAccent),
                  value: isSoundOn,
                  onChanged: (val) {
                    setState(() => isSoundOn = val);
                    setModalState(() {});
                    _saveData();
                  },
                ),
                SwitchListTile(
                  title: const Text('Vibration', style: TextStyle(color: Colors.white)),
                  secondary: Icon(isVibrationOn ? Icons.vibration : Icons.mobile_off, color: const Color(0xFF00B074)),
                  value: isVibrationOn,
                  onChanged: (val) {
                    setState(() => isVibrationOn = val);
                    setModalState(() {});
                    _saveData();
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.tealAccent),
                  title: const Text('Backup Data', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Copy backup code', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportBackup();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.amberAccent),
                  title: const Text('Restore Data', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Import from backup code', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRestoreDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
                  title: const Text('About Developer', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddDhikrDialog() {
    final titleController = TextEditingController();
    final arabicController = TextEditingController();
    final meaningController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        title: const Text('Add Custom Dhikr', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title (e.g., Ayat al-Kursi)'),
              ),
              TextField(
                controller: arabicController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Arabic Text'),
              ),
              TextField(
                controller: meaningController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'English Meaning'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B074)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  dhikrList.add(DhikrItem(
                    title: titleController.text.trim(),
                    arabic: arabicController.text.trim(),
                    meaning: meaningController.text.trim(),
                  ));
                  currentIndex = dhikrList.length - 1;
                });
                _saveData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDhikr = dhikrList[currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161719),
        elevation: 0,
        title: const Row(
          children: [
            Text('📿', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Tasbih', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Color(0xFF00B074)),
            tooltip: 'All Dhikr List',
            onPressed: _showDhikrListModal,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _incrementCounter,
        child: Column(
          children: [
            InkWell(
              onTap: _showDhikrListModal,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF222428),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentDhikr.title,
                          style: const TextStyle(
                            color: Color(0xFF00B074),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00B074), size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentDhikr.arabic,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (currentDhikr.meaning.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        currentDhikr.meaning,
                        style: const TextStyle(fontSize: 13, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ]
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [33, 100, 1000].map((t) {
                  final isSelected = targetCount == t;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text('$t'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00B074),
                      backgroundColor: const Color(0xFF222428),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setState(() => targetCount = t);
                        _saveData();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2024),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B074).withOpacity(0.12),
                      blurRadius: 25,
                      spreadRadius: 8,
                    )
                  ],
                  border: Border.all(color: const Color(0xFF00B074).withOpacity(0.5), width: 6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${currentDhikr.count}',
                      style: const TextStyle(
                        fontSize: 62,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Target: $targetCount',
                      style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                    tooltip: 'Reset Count',
                    onPressed: _resetCurrentCount,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222428),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'Total: ${currentDhikr.total}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 28,
                    icon: Icon(
                      isSoundOn ? Icons.volume_up : Icons.volume_off,
                      color: isSoundOn ? const Color(0xFF00B074) : Colors.white30,
                    ),
                    onPressed: () {
                      setState(() => isSoundOn = !isSoundOn);
                      _saveData();
                    },
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
