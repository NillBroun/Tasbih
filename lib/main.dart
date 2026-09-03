import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
  String id;
  String title;
  String arabic;
  String meaning;
  int count;
  int total;
  bool isCustom;

  DhikrItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.meaning,
    this.count = 0,
    this.total = 0,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'arabic': arabic,
        'meaning': meaning,
        'count': count,
        'total': total,
        'isCustom': isCustom,
      };

  factory DhikrItem.fromMap(Map<String, dynamic> map) => DhikrItem(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'] ?? '',
        arabic: map['arabic'] ?? '',
        meaning: map['meaning'] ?? '',
        count: map['count'] ?? 0,
        total: map['total'] ?? 0,
        isCustom: map['isCustom'] ?? false,
      );
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  List<DhikrItem> dhikrList = [
    DhikrItem(id: '1', title: 'SubhanAllah', arabic: 'سُبْحَانَ اللّٰهِ', meaning: 'Glory be to Allah'),
    DhikrItem(id: '2', title: 'Alhamdulillah', arabic: 'الْحَمْدُ لِلّٰهِ', meaning: 'All praise is due to Allah'),
    DhikrItem(id: '3', title: 'Allahu Akbar', arabic: 'اللّٰهُ أَكْبَرُ', meaning: 'Allah is the Greatest'),
    DhikrItem(id: '4', title: 'Kalima Tayyibah', arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ مُحَمَّدٌ رَسُولُ اللّٰهِ', meaning: 'There is no god but Allah, Muhammad is the Messenger of Allah'),
    DhikrItem(id: '5', title: 'Istighfar', arabic: 'أَسْتَغْفِرُ اللّٰهَ وَأَتُوبُ إِلَيْهِ', meaning: 'I seek forgiveness from Allah'),
    DhikrItem(id: '6', title: 'Durood Sharif', arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ', meaning: 'Blessings upon Muhammad'),
    DhikrItem(id: '7', title: 'Hawqala', arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ', meaning: 'No power nor strength except with Allah'),
  ];

  int currentIndex = 0;
  int targetCount = 33;
  bool isSoundOn = true;
  Map<String, int> dailyHistory = {};

  final String fbPageUrl = 'https://www.facebook.com/profile.php?id=61581691871822';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

    final historyData = prefs.getString('tasbih_history_log');
    if (historyData != null) {
      setState(() {
        dailyHistory = Map<String, int>.from(jsonDecode(historyData));
      });
    }

    setState(() {
      currentIndex = (prefs.getInt('current_index') ?? 0).clamp(0, dhikrList.isNotEmpty ? dhikrList.length - 1 : 0);
      targetCount = prefs.getInt('target_count') ?? 33;
      isSoundOn = prefs.getBool('sound_on') ?? true;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasbih_dhikr_data', jsonEncode(dhikrList.map((e) => e.toMap()).toList()));
    await prefs.setString('tasbih_history_log', jsonEncode(dailyHistory));
    await prefs.setInt('current_index', currentIndex);
    await prefs.setInt('target_count', targetCount);
    await prefs.setBool('sound_on', isSoundOn);
  }

  void _playSound({bool isTargetReached = false}) {
    if (!isSoundOn) return;
    if (isTargetReached) {
      SystemSound.play(SystemSoundType.alert);
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _nextDhikr() {
    if (dhikrList.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % dhikrList.length;
    });
    _saveData();
  }

  void _previousDhikr() {
    if (dhikrList.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex - 1 + dhikrList.length) % dhikrList.length;
    });
    _saveData();
  }

  void _incrementCounter() {
    final today = _getTodayKey();
    setState(() {
      dhikrList[currentIndex].count++;
      dhikrList[currentIndex].total++;
      dailyHistory[today] = (dailyHistory[today] ?? 0) + 1;
    });

    final isTargetReached = (dhikrList[currentIndex].count % targetCount == 0);
    _playSound(isTargetReached: isTargetReached);
    _saveData();
  }

  void _resetCurrentCount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        title: const Text('Reset Current Counter', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Reset active session count to 0? (Total count will remain unchanged)',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700),
            onPressed: () {
              setState(() => dhikrList[currentIndex].count = 0);
              _saveData();
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetTotalCount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        title: const Text('Reset Total Count', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to reset the Lifetime Total of "${dhikrList[currentIndex].title}" to 0?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700),
            onPressed: () {
              setState(() => dhikrList[currentIndex].total = 0);
              _saveData();
              Navigator.pop(ctx);
            },
            child: const Text('Reset Total', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCustomTargetDialog() {
    final controller = TextEditingController(text: targetCount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        title: const Text('Custom Target', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Enter Target Count', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B074)),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                setState(() => targetCount = val);
                _saveData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    final backupData = {
      'dhikr_list': dhikrList.map((e) => e.toMap()).toList(),
      'daily_history': dailyHistory,
      'target_count': targetCount,
      'app': 'Tasbih',
      'developer': 'AHM',
    };
    await Clipboard.setData(ClipboardData(text: jsonEncode(backupData)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup code copied to clipboard successfully!'),
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
              'Paste your backup code below to restore your data:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
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
                    if (decoded.containsKey('daily_history')) {
                      dailyHistory = Map<String, int>.from(decoded['daily_history']);
                    }
                  });
                  _saveData();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data restored successfully!'),
                      backgroundColor: Color(0xFF00B074),
                    ),
                  );
                } else {
                  throw Exception();
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid backup code!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dhikr List',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B074),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Add Dhikr', style: TextStyle(color: Colors.white)),
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
                      subtitle: Text(item.arabic, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total: ${item.total}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          if (dhikrList.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() {
                                  dhikrList.removeAt(idx);
                                  if (currentIndex >= dhikrList.length) {
                                    currentIndex = dhikrList.length - 1;
                                  }
                                });
                                setModalState(() {});
                                _saveData();
                              },
                            )
                        ],
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
        title: const Text('Add New Dhikr', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title (e.g. Astaghfirullah)'),
              ),
              TextField(
                controller: arabicController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Arabic Text'),
              ),
              TextField(
                controller: meaningController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Meaning'),
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
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    arabic: arabicController.text.trim(),
                    meaning: meaningController.text.trim(),
                    isCustom: true,
                  ));
                  currentIndex = dhikrList.length - 1;
                });
                _saveData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistoryModal() {
    final sortedKeys = dailyHistory.keys.toList()..sort((a, b) => b.compareTo(a));
    final recent7Days = sortedKeys.take(7).toList();
    final int todayCount = dailyHistory[_getTodayKey()] ?? 0;

    showModalBottomSheet(
      backgroundColor: const Color(0xFF1E2024),
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Color(0xFF00B074)),
                SizedBox(width: 8),
                Text('Dhikr History & Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF222428), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Total Dhikr:", style: TextStyle(color: Colors.white70, fontSize: 15)),
                  Text("$todayCount", style: const TextStyle(color: Color(0xFF00B074), fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Last 7 Days Activity:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recent7Days.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No history logged yet.', style: TextStyle(color: Colors.white30)),
                ),
              )
            else
              ...recent7Days.map((date) {
                final count = dailyHistory[date] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 90, child: Text(date, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (count / 500).clamp(0.05, 1.0),
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF00B074)),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 45,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF222428),
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Settings & Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Sound Feedback', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Plays click tone on count', style: TextStyle(color: Colors.white38, fontSize: 12)),
                secondary: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off, color: Colors.lightBlueAccent),
                value: isSoundOn,
                onChanged: (val) {
                  setState(() => isSoundOn = val);
                  setModalState(() {});
                  _saveData();
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded, color: Colors.amberAccent),
                title: const Text('History & Statistics', style: TextStyle(color: Colors.white)),
                subtitle: const Text('View daily & weekly activity', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showHistoryModal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: Colors.tealAccent),
                title: const Text('Backup Data', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Copy backup code to clipboard', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportBackup();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined, color: Colors.greenAccent),
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
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Tasbih', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A digital tasbih application designed for seamless daily Dhikr & Remembrance of Allah.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Divider(color: Colors.white12, height: 22),
            const Text('Developer: AHM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
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
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.facebook, color: Colors.blueAccent, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Follow Facebook Page',
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final currentDhikr = dhikrList.isNotEmpty ? dhikrList[currentIndex] : DhikrItem(id: '0', title: 'Empty', arabic: '', meaning: '');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161719),
        elevation: 0,
        title: const Text('📿 Tasbih', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
        actions: [
          IconButton(icon: const Icon(Icons.list_alt, color: Color(0xFF00B074)), tooltip: 'All Dhikr List', onPressed: _showDhikrListModal),
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white70), tooltip: 'Settings', onPressed: _showSettingsModal),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _incrementCounter,
        child: Column(
          children: [
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _nextDhikr();
                } else if (details.primaryVelocity! > 0) {
                  _previousDhikr();
                }
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222428),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.white54),
                          tooltip: 'Previous Dhikr',
                          onPressed: _previousDhikr,
                        ),
                        Text(currentDhikr.title, style: const TextStyle(color: Color(0xFF00B074), fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 18, color: Colors.white54),
                          tooltip: 'Next Dhikr',
                          onPressed: _nextDhikr,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(currentDhikr.arabic, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                    if (currentDhikr.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(currentDhikr.meaning, style: const TextStyle(fontSize: 12, color: Colors.white60), textAlign: TextAlign.center),
                    ]
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...[33, 100, 1000].map((t) {
                    final isSelected = targetCount == t;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$t'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00B074),
                        backgroundColor: const Color(0xFF222428),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
                        onSelected: (_) {
                          setState(() => targetCount = t);
                          _saveData();
                        },
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.edit, size: 14, color: Colors.white70),
                      label: Text(![33, 100, 1000].contains(targetCount) ? 'Target: $targetCount' : '+ Custom', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: ![33, 100, 1000].contains(targetCount) ? const Color(0xFF00B074) : const Color(0xFF222428),
                      onPressed: _showCustomTargetDialog,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2024),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00B074).withOpacity(0.12), blurRadius: 25, spreadRadius: 8)
                  ],
                  border: Border.all(color: const Color(0xFF00B074).withOpacity(0.5), width: 6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${currentDhikr.count}', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Target: $targetCount', style: const TextStyle(color: Colors.white38, fontSize: 14)),
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
                    iconSize: 30,
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                    tooltip: 'Reset Active Count',
                    onPressed: _resetCurrentCount,
                  ),
                  InkWell(
                    onTap: _resetTotalCount,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222428),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Text('Total: ${currentDhikr.total}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70)),
                          const SizedBox(width: 4),
                          const Icon(Icons.restore, size: 14, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 26,
                    icon: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off, color: isSoundOn ? const Color(0xFF00B074) : Colors.white30),
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
