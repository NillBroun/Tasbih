import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:home_widget/home_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TasbihApp());
}

class DhikrItem {
  String title;
  String arabic;
  String meaning;
  int target;
  int lifetimeCount;

  DhikrItem({
    required this.title,
    required this.arabic,
    required this.meaning,
    this.target = 33,
    this.lifetimeCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'arabic': arabic,
    'meaning': meaning,
    'target': target,
    'lifetimeCount': lifetimeCount,
  };

  factory DhikrItem.fromJson(Map<String, dynamic> json) => DhikrItem(
    title: json['title'] ?? '',
    arabic: json['arabic'] ?? '',
    meaning: json['meaning'] ?? '',
    target: json['target'] ?? 33,
    lifetimeCount: json['lifetimeCount'] ?? 0,
  );
}

class HijriCalculator {
  static const List<String> hijriMonths = [
    "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
    "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
    "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
  ];

  static Map<String, dynamic> calculate(DateTime date, int offsetDays) {
    // Islamic date changes at Maghrib (approx 18:00 / 6 PM local)
    int maghribHour = 18;
    int maghribMinute = 15;
    bool isAfterMaghrib = (date.hour > maghribHour) ||
        (date.hour == maghribHour && date.minute >= maghribMinute);

    DateTime adjusted = date.add(Duration(days: offsetDays + (isAfterMaghrib ? 1 : 0)));

    int day = adjusted.day;
    int month = adjusted.month;
    int year = adjusted.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    int jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;

    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j = ((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor() +
        (l / 5670).floor() * ((43 * l) / 15238).floor();
    l = l - ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() + 29;
    int hMonth = ((24 * l) / 709).floor();
    int hDay = l - ((709 * hMonth) / 24).floor();
    int hYear = 30 * n + j - 30;

    String monthName = (hMonth >= 1 && hMonth <= 12) ? hijriMonths[hMonth - 1] : "Hijri";

    return {
      'day': hDay,
      'month': monthName,
      'year': hYear,
      'isNight': isAfterMaghrib || date.hour < 5,
      'formatted': "$hDay $monthName $hYear AH"
    };
  }
}

class SalahForbiddenTime {
  static Map<String, dynamic> checkStatus(DateTime now) {
    int curMin = now.hour * 60 + now.minute;

    // Approximate solar events (can be localized)
    // 1. Sunrise forbidden time: 05:40 - 06:00 (approx 20 mins)
    int sunriseStart = 5 * 60 + 40;
    int sunriseEnd = 6 * 60 + 0;

    // 2. Zawwal (Zenith) forbidden time: 11:45 - 12:00 (approx 15 mins)
    int zawwalStart = 11 * 60 + 45;
    int zawwalEnd = 12 * 60 + 0;

    // 3. Sunset (Ifrar) forbidden time: 17:55 - 18:15 (approx 20 mins)
    int sunsetStart = 17 * 60 + 55;
    int sunsetEnd = 18 * 60 + 15;

    if (curMin >= sunriseStart && curMin <= sunriseEnd) {
      return {'isForbidden': true, 'title': 'Sunrise (No Salah)', 'reason': 'Forbidden prayer time'};
    } else if (curMin >= zawwalStart && curMin <= zawwalEnd) {
      return {'isForbidden': true, 'title': 'Zawwal (No Salah)', 'reason': 'Forbidden prayer time'};
    } else if (curMin >= sunsetStart && curMin <= sunsetEnd) {
      return {'isForbidden': true, 'title': 'Sunset (No Salah)', 'reason': 'Forbidden prayer time'};
    }

    return {'isForbidden': false, 'title': 'Salah Open', 'reason': 'Normal time'};
  }
}

class TasbihApp extends StatelessWidget {
  const TasbihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasbih',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF161719),
        primaryColor: const Color(0xFF00B074),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00B074),
          surface: Color(0xFF222428),
        ),
      ),
      home: const TasbihHomeScreen(),
    );
  }
}

class TasbihHomeScreen extends StatefulWidget {
  const TasbihHomeScreen({super.key});

  @override
  State<TasbihHomeScreen> createState() => _TasbihHomeScreenState();
}

class _TasbihHomeScreenState extends State<TasbihHomeScreen> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<DhikrItem> _dhikrList = [];
  int _currentIndex = 0;
  int _currentCount = 0;

  bool _isSoundOn = true;
  bool _isVibrateOn = true;
  double _fontScale = 1.0;
  int _hijriOffset = 0;

  Map<String, int> _dailyHistory = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
    _loadAllData();
  }

  void _initAudio() {
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayer.setSource(AssetSource('audio/click.wav'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveAllData();
      _syncWidget();
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundOn = prefs.getBool('isSoundOn') ?? true;
    _isVibrateOn = prefs.getBool('isVibrateOn') ?? true;
    _fontScale = prefs.getDouble('fontScale') ?? 1.0;
    _hijriOffset = prefs.getInt('hijriOffset') ?? 0;
    _currentIndex = prefs.getInt('currentIndex') ?? 0;
    _currentCount = prefs.getInt('currentCount') ?? 0;

    final dhikrString = prefs.getString('dhikrList');
    if (dhikrString != null) {
      final List decoded = jsonDecode(dhikrString);
      _dhikrList = decoded.map((e) => DhikrItem.fromJson(e)).toList();
    } else {
      _dhikrList = [
        DhikrItem(
          title: "Subhanallah",
          arabic: "سُبْحَانَ ٱللَّٰهِ",
          meaning: "Glory be to Allah",
          target: 33,
        ),
        DhikrItem(
          title: "Alhamdulillah",
          arabic: "ٱلْحَمْدُ لِلَّٰهِ",
          meaning: "Praise be to Allah",
          target: 33,
        ),
        DhikrItem(
          title: "Allahu Akbar",
          arabic: "ٱللَّٰهُ أَكْبَرُ",
          meaning: "Allah is the Greatest",
          target: 34,
        ),
        DhikrItem(
          title: "Kalima Tayyibah",
          arabic: "لَا إِلَٰهَ إِلَّا ٱللَّٰهُ مُحَمَّدٌ رَّسُولُ ٱللَّٰهِ",
          meaning: "There is no god but Allah, Muhammad is the Messenger of Allah",
          target: 100,
        ),
        DhikrItem(
          title: "Astaghfirullah",
          arabic: "أَسْتَغْفِرُ ٱللَّٰهَ",
          meaning: "I seek forgiveness from Allah",
          target: 100,
        ),
      ];
    }

    if (_currentIndex >= _dhikrList.length) _currentIndex = 0;

    final historyString = prefs.getString('dailyHistory');
    if (historyString != null) {
      final Map<String, dynamic> decoded = jsonDecode(historyString);
      _dailyHistory = decoded.map((k, v) => MapEntry(k, v as int));
    }

    setState(() {});
    _syncWidget();
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundOn', _isSoundOn);
    await prefs.setBool('isVibrateOn', _isVibrateOn);
    await prefs.setDouble('fontScale', _fontScale);
    await prefs.setInt('hijriOffset', _hijriOffset);
    await prefs.setInt('currentIndex', _currentIndex);
    await prefs.setInt('currentCount', _currentCount);
    await prefs.setString('dhikrList', jsonEncode(_dhikrList.map((e) => e.toJson()).toList()));
    await prefs.setString('dailyHistory', jsonEncode(_dailyHistory));
  }

  Future<void> _syncWidget() async {
    try {
      final now = DateTime.now();
      final hijri = HijriCalculator.calculate(now, _hijriOffset);
      final salah = SalahForbiddenTime.checkStatus(now);

      final todayKey = _getTodayKey();
      final todayTotal = _dailyHistory[todayKey] ?? 0;

      await HomeWidget.saveWidgetData<int>('widget_today_count', todayTotal);
      await HomeWidget.saveWidgetData<String>('widget_hijri_date', hijri['formatted']);
      await HomeWidget.saveWidgetData<String>('widget_greg_date', "${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)}");

      String celestialIcon = hijri['isNight'] ? "🌙✨" : "☀️";
      if (salah['isForbidden']) celestialIcon = "⛔";

      await HomeWidget.saveWidgetData<String>('widget_celestial_icon', celestialIcon);
      await HomeWidget.saveWidgetData<String>('widget_prayer_status', salah['title']);

      await HomeWidget.updateWidget(
        name: 'TasbihWidgetProvider',
        androidName: 'TasbihWidgetProvider',
      );
    } catch (_) {}
  }

  String _getDayName(int day) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[(day - 1) % 7];
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[(month - 1) % 12];
  }

  void _onTapCounter() {
    if (_dhikrList.isEmpty) return;

    if (_isSoundOn) {
      _audioPlayer.stop();
      _audioPlayer.play(AssetSource('audio/click.wav'));
    }

    if (_isVibrateOn) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _currentCount++;
      _dhikrList[_currentIndex].lifetimeCount++;

      final today = _getTodayKey();
      _dailyHistory[today] = (_dailyHistory[today] ?? 0) + 1;

      final target = _dhikrList[_currentIndex].target;
      if (target > 0 && _currentCount == target) {
        if (_isVibrateOn) HapticFeedback.heavyImpact();
      }
    });

    _saveAllData();
    _syncWidget();
  }

  void _resetCurrentCount() {
    setState(() {
      _currentCount = 0;
    });
    _saveAllData();
  }

  void _resetLifetimeCount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Total Count?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Do you want to reset total count for "${_dhikrList[_currentIndex].title}" to 0?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700),
            onPressed: () {
              setState(() {
                _dhikrList[_currentIndex].lifetimeCount = 0;
              });
              _saveAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _nextDhikr() {
    if (_dhikrList.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _dhikrList.length;
      _currentCount = 0;
    });
    _saveAllData();
  }

  void _prevDhikr() {
    if (_dhikrList.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _dhikrList.length) % _dhikrList.length;
      _currentCount = 0;
    });
    _saveAllData();
  }

  // Encrypted Backup Logic (ColorNote Style PIN / Password)
  String _xorEncrypt(String text, String key) {
    if (key.isEmpty) return text;
    final textBytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final encrypted = List<int>.generate(textBytes.length, (i) {
      return textBytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return base64Encode(encrypted);
  }

  String _xorDecrypt(String base64Text, String key) {
    if (key.isEmpty) return base64Text;
    final encryptedBytes = base64Decode(base64Text);
    final keyBytes = utf8.encode(key);
    final decrypted = List<int>.generate(encryptedBytes.length, (i) {
      return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return utf8.decode(decrypted);
  }

  void _showEncryptedBackupDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Backup with PIN / Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a 4-digit PIN or password to secure your backup data (Optional):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'PIN / Password',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF1E2024),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B074)),
            onPressed: () {
              final pin = pinCtrl.text.trim();
              final rawJson = jsonEncode({
                'dhikrList': _dhikrList.map((e) => e.toJson()).toList(),
                'dailyHistory': _dailyHistory,
                'hasPin': pin.isNotEmpty,
              });

              final encryptedData = pin.isNotEmpty ? "ENC:${_xorEncrypt(rawJson, pin)}" : rawJson;
              Clipboard.setData(ClipboardData(text: encryptedData));

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secure backup copied to clipboard!')),
              );
            },
            child: const Text('Copy Backup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEncryptedRestoreDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore Data', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup from clipboard. If it was PIN protected, enter your PIN below:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'PIN / Password (if protected)',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF1E2024),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B074)),
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              final clip = await Clipboard.getData(Clipboard.kTextPlain);
              if (clip?.text == null) return;

              try {
                String text = clip!.text!.trim();
                if (text.startsWith("ENC:")) {
                  text = _xorDecrypt(text.substring(4), pin);
                }
                final decoded = jsonDecode(text);
                if (decoded['dhikrList'] != null) {
                  final List list = decoded['dhikrList'];
                  _dhikrList = list.map((e) => DhikrItem.fromJson(e)).toList();
                }
                if (decoded['dailyHistory'] != null) {
                  final Map<String, dynamic> hist = decoded['dailyHistory'];
                  _dailyHistory = hist.map((k, v) => MapEntry(k, v as int));
                }

                setState(() {
                  _currentIndex = 0;
                  _currentCount = 0;
                });
                _saveAllData();
                _syncWidget();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data restored successfully!')),
                );
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid backup or wrong PIN.')),
                );
              }
            },
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openDhikrListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2024),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dhikr Collection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00B074), size: 28),
                      onPressed: () => _showAddEditDhikrDialog(setModalState),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _dhikrList.length,
                  itemBuilder: (context, index) {
                    final item = _dhikrList[index];
                    final isSelected = index == _currentIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00B074).withOpacity(0.12) : const Color(0xFF26282D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00B074) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                            _currentCount = 0;
                          });
                          _saveAllData();
                          Navigator.pop(ctx);
                        },
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF00B074) : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          "${item.arabic}\nTarget: ${item.target > 0 ? item.target : '∞'}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.white70),
                              onPressed: () => _showAddEditDhikrDialog(setModalState, item: item, index: index),
                            ),
                            if (_dhikrList.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDeleteDhikr(index, setModalState),
                              ),
                          ],
                        ),
                      ),
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

  void _confirmDeleteDhikr(int index, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Dhikr?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${_dhikrList[index].title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700),
            onPressed: () {
              setState(() {
                _dhikrList.removeAt(index);
                if (_currentIndex >= _dhikrList.length) {
                  _currentIndex = 0;
                }
                _currentCount = 0;
              });
              setModalState(() {});
              _saveAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDhikrDialog(StateSetter setModalState, {DhikrItem? item, int? index}) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final arabicCtrl = TextEditingController(text: item?.arabic ?? '');
    final meaningCtrl = TextEditingController(text: item?.meaning ?? '');
    final targetCtrl = TextEditingController(text: item?.target.toString() ?? '33');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item == null ? 'Add New Dhikr' : 'Edit Dhikr', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title (e.g., Tahmid)', labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: arabicCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Arabic Text', labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: meaningCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Meaning (Translation)', labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Target Count (e.g. 33, 100, 0 for ∞)', labelStyle: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B074)),
            onPressed: () {
              final title = titleCtrl.text.trim();
              final arabic = arabicCtrl.text.trim();
              final meaning = meaningCtrl.text.trim();
              final target = int.tryParse(targetCtrl.text.trim()) ?? 33;

              if (title.isEmpty || arabic.isEmpty) return;

              setState(() {
                if (item == null) {
                  _dhikrList.add(DhikrItem(title: title, arabic: arabic, meaning: meaning, target: target));
                } else if (index != null) {
                  _dhikrList[index].title = title;
                  _dhikrList[index].arabic = arabic;
                  _dhikrList[index].meaning = meaning;
                  _dhikrList[index].target = target;
                }
              });
              setModalState(() {});
              _saveAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2024),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSettingsState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Color(0xFF00B074)),
                    SizedBox(width: 10),
                    Text('Settings & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SwitchListTile(
                      activeColor: const Color(0xFF00B074),
                      title: const Text('Sound Feedback', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Play click sound on each count', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      value: _isSoundOn,
                      onChanged: (val) {
                        setState(() => _isSoundOn = val);
                        setSettingsState(() {});
                        _saveAllData();
                      },
                    ),
                    SwitchListTile(
                      activeColor: const Color(0xFF00B074),
                      title: const Text('Vibration Feedback', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Light haptic impact on tap', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      value: _isVibrateOn,
                      onChanged: (val) {
                        setState(() => _isVibrateOn = val);
                        setSettingsState(() {});
                        _saveAllData();
                      },
                    ),
                    const Divider(color: Colors.white12),

                    // Font Size Scale
                    ListTile(
                      title: const Text('Font Size Scaling', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Current: ${(_fontScale * 100).toInt()}%', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ),
                    Slider(
                      value: _fontScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      activeColor: const Color(0xFF00B074),
                      inactiveColor: Colors.white12,
                      label: "${(_fontScale * 100).toInt()}%",
                      onChanged: (val) {
                        setState(() => _fontScale = val);
                        setSettingsState(() {});
                        _saveAllData();
                      },
                    ),
                    const Divider(color: Colors.white12),

                    // Hijri Adjustment
                    ListTile(
                      title: const Text('Hijri Date Adjustment', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Moon Sighting Offset: ${_hijriOffset >= 0 ? "+$_hijriOffset" : "$_hijriOffset"} Days',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [-2, -1, 0, 1, 2].map((offset) {
                        final isSel = _hijriOffset == offset;
                        return ChoiceChip(
                          label: Text(offset == 0 ? "0" : (offset > 0 ? "+$offset" : "$offset")),
                          selected: isSel,
                          selectedColor: const Color(0xFF00B074),
                          onSelected: (_) {
                            setState(() => _hijriOffset = offset);
                            setSettingsState(() {});
                            _saveAllData();
                            _syncWidget();
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(color: Colors.white12),

                    // Last 7 Days Bars
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Last 7 Days Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    _buildHistoryBars(),
                    const Divider(color: Colors.white12),

                    // ColorNote Style Encrypted Backup & Restore
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Color(0xFF00B074)),
                      title: const Text('PIN Protected Backup', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Copy encrypted data to clipboard', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      onTap: () => _showEncryptedBackupDialog(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_open, color: Color(0xFF00B074)),
                      title: const Text('Restore Protected Backup', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Paste encrypted data using PIN', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      onTap: () => _showEncryptedRestoreDialog(),
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

  Widget _buildHistoryBars() {
    final now = DateTime.now();
    final List<MapEntry<String, int>> last7Days = [];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      last7Days.add(MapEntry(k, _dailyHistory[k] ?? 0));
    }

    final maxVal = last7Days.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222428),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: last7Days.map((entry) {
          final count = entry.value;
          final double factor = maxVal > 0 ? (count / maxVal) : 0.0;
          final parts = entry.key.split('-');
          final dayLabel = "${parts[1]}/${parts[2]}";

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count > 999 ? "${(count / 1000).toStringAsFixed(1)}k" : "$count",
                style: const TextStyle(fontSize: 10, color: Colors.white60),
              ),
              const SizedBox(height: 4),
              Container(
                width: 16,
                height: 60 * factor + 4,
                decoration: BoxDecoration(
                  color: factor > 0 ? const Color(0xFF00B074) : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(dayLabel, style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Tasbih', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '"Verily, in the remembrance of Allah do hearts find rest."',
                style: TextStyle(color: Color(0xFF00B074), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Away from the noise of a busy life, this Tasbih is created to keep your moments devoted to the remembrance of your Lord. May every tap bring profound tranquility to your soul and illuminate your heart with faith.\n\nO Allah, keep our tongues moist with Your constant remembrance. Ameen.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const Divider(color: Colors.white12, height: 24),
              const Text('Developer: AHM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://www.facebook.com/ahm.79316');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1877F2).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Follow Facebook Page',
                          style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    final now = DateTime.now();
    final hijri = HijriCalculator.calculate(now, _hijriOffset);
    final salah = SalahForbiddenTime.checkStatus(now);

    final currentDhikr = _dhikrList.isNotEmpty
        ? _dhikrList[_currentIndex]
        : DhikrItem(title: "Tasbih", arabic: "سُبْحَانَ ٱللَّٰهِ", meaning: "Glory be to Allah", target: 33);

    final target = currentDhikr.target;
    final double progress = target > 0 ? (_currentCount / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTapCounter,
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white70),
                      onPressed: _showAboutDialog,
                    ),
                    const Text(
                      'Tasbih',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted, color: Color(0xFF00B074)),
                          onPressed: _openDhikrListModal,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white70),
                          onPressed: _openSettingsModal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dynamic Home Screen Hijri & Salah Status Pill Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: salah['isForbidden']
                        ? const Color(0xFFD32F2F).withOpacity(0.18)
                        : const Color(0xFF222428),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: salah['isForbidden']
                          ? const Color(0xFFD32F2F).withOpacity(0.4)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        salah['isForbidden'] ? "⛔" : (hijri['isNight'] ? "🌙✨" : "☀️"),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hijri['formatted'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (salah['isForbidden']) ...[
                        const SizedBox(width: 6),
                        Text(
                          "• ${salah['title']}",
                          style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Circular Dhikr Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222428),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.white60),
                            onPressed: _prevDhikr,
                          ),
                          Expanded(
                            child: Text(
                              currentDhikr.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00B074),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18, color: Colors.white60),
                            onPressed: _nextDhikr,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentDhikr.arabic,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 24 * _fontScale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      if (currentDhikr.meaning.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          currentDhikr.meaning,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12 * _fontScale,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Counter Circle Area
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: target > 0 ? progress : 0.0,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFF222428),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B074)),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_currentCount',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            target > 0 ? 'Target: $target' : 'Target: ∞',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF00B074),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 26),
                      onPressed: _resetCurrentCount,
                    ),
                    GestureDetector(
                      onTap: _resetLifetimeCount,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222428),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Total: ${currentDhikr.lifetimeCount}',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.history, size: 14, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSoundOn ? Icons.volume_up : Icons.volume_off,
                        color: _isSoundOn ? const Color(0xFF00B074) : Colors.white38,
                        size: 26,
                      ),
                      onPressed: () {
                        setState(() => _isSoundOn = !_isSoundOn);
                        _saveAllData();
                      },
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
}
