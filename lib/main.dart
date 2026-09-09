import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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

class CountryPreset {
  final String name;
  final double lat;
  final double lng;

  const CountryPreset(this.name, this.lat, this.lng);
}

class SolarCalculator {
  static const List<CountryPreset> worldCountries = [
    CountryPreset("Afghanistan", 34.5553, 69.2075),
    CountryPreset("Albania", 41.3275, 19.8187),
    CountryPreset("Algeria", 36.7538, 3.0588),
    CountryPreset("Argentina", -34.6037, -58.3816),
    CountryPreset("Australia", -35.2809, 149.1300),
    CountryPreset("Austria", 48.2082, 16.3738),
    CountryPreset("Azerbaijan", 40.4093, 49.8671),
    CountryPreset("Bahrain", 26.2285, 50.5860),
    CountryPreset("Bangladesh", 23.8103, 90.4125),
    CountryPreset("Belgium", 50.8503, 4.3517),
    CountryPreset("Bosnia and Herzegovina", 43.8563, 18.4131),
    CountryPreset("Brazil", -15.7975, -47.8919),
    CountryPreset("Brunei", 4.9031, 114.9398),
    CountryPreset("Canada", 45.4215, -75.6972),
    CountryPreset("China", 39.9042, 116.4074),
    CountryPreset("Cyprus", 35.1856, 33.3823),
    CountryPreset("Denmark", 55.6761, 12.5683),
    CountryPreset("Egypt", 30.0444, 31.2357),
    CountryPreset("Finland", 60.1699, 24.9384),
    CountryPreset("France", 48.8566, 2.3522),
    CountryPreset("Germany", 52.5200, 13.4050),
    CountryPreset("Ghana", 5.6037, -0.1870),
    CountryPreset("Greece", 37.9838, 23.7275),
    CountryPreset("Hong Kong", 22.3193, 114.1694),
    CountryPreset("India", 28.6139, 77.2090),
    CountryPreset("Indonesia", -6.2088, 106.8456),
    CountryPreset("Iran", 35.6892, 51.3890),
    CountryPreset("Iraq", 33.3152, 44.3661),
    CountryPreset("Ireland", 53.3498, -6.2603),
    CountryPreset("Italy", 41.9028, 12.4964),
    CountryPreset("Japan", 35.6762, 139.6503),
    CountryPreset("Jordan", 31.9454, 35.9284),
    CountryPreset("Kazakhstan", 51.1694, 71.4491),
    CountryPreset("Kenya", -1.2921, 36.8219),
    CountryPreset("Kuwait", 29.3759, 47.9774),
    CountryPreset("Kyrgyzstan", 42.8746, 74.5698),
    CountryPreset("Lebanon", 33.8938, 35.5018),
    CountryPreset("Libya", 32.8872, 13.1913),
    CountryPreset("Malaysia", 3.1390, 101.6869),
    CountryPreset("Maldives", 4.1755, 73.5093),
    CountryPreset("Morocco", 34.0209, -6.8416),
    CountryPreset("Myanmar", 19.7633, 96.0785),
    CountryPreset("Nepal", 27.7172, 85.3240),
    CountryPreset("Netherlands", 52.3676, 4.9041),
    CountryPreset("New Zealand", -41.2865, 174.7762),
    CountryPreset("Nigeria", 9.0765, 7.3986),
    CountryPreset("Norway", 59.9139, 10.7522),
    CountryPreset("Oman", 23.5859, 58.4059),
    CountryPreset("Pakistan", 33.6844, 73.0479),
    CountryPreset("Palestine", 31.7683, 35.2137),
    CountryPreset("Philippines", 14.5995, 120.9842),
    CountryPreset("Poland", 52.2297, 21.0122),
    CountryPreset("Portugal", 38.7223, -9.1393),
    CountryPreset("Qatar", 25.2854, 51.5310),
    CountryPreset("Russia", 55.7558, 37.6173),
    CountryPreset("Saudi Arabia", 24.7136, 46.6753),
    CountryPreset("Singapore", 1.3521, 103.8198),
    CountryPreset("South Africa", -25.7479, 28.2293),
    CountryPreset("South Korea", 37.5665, 126.9780),
    CountryPreset("Spain", 40.4168, -3.7038),
    CountryPreset("Sri Lanka", 6.9271, 79.8612),
    CountryPreset("Sudan", 15.5007, 32.5599),
    CountryPreset("Sweden", 59.3293, 18.0686),
    CountryPreset("Switzerland", 46.9480, 7.4474),
    CountryPreset("Syria", 33.5138, 36.2765),
    CountryPreset("Taiwan", 25.0330, 121.5654),
    CountryPreset("Tajikistan", 38.5598, 68.7870),
    CountryPreset("Thailand", 13.7563, 100.5018),
    CountryPreset("Tunisia", 36.8065, 10.1815),
    CountryPreset("Turkey", 39.9334, 32.8597),
    CountryPreset("Turkmenistan", 37.9601, 58.3261),
    CountryPreset("Uganda", 0.3476, 32.5825),
    CountryPreset("United Arab Emirates", 24.4539, 54.3773),
    CountryPreset("United Kingdom", 51.5074, -0.1278),
    CountryPreset("United States", 38.9072, -77.0369),
    CountryPreset("Uzbekistan", 41.2995, 69.2401),
    CountryPreset("Yemen", 15.3694, 44.1910),
  ];

  static Map<String, int> getTimes(DateTime date, {required double lat, required double lng, int offsetMin = 0}) {
    int dayOfYear = int.parse("${date.difference(DateTime(date.year, 1, 1)).inDays + 1}");
    double b = 2 * pi * (dayOfYear - 81) / 365.0;
    
    double eot = 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b);
    double declination = 23.45 * sin(2 * pi * (284 + dayOfYear) / 365.0);
    double declRad = declination * pi / 180.0;
    double latRad = lat * pi / 180.0;

    double tzOffsetHours = date.timeZoneOffset.inMinutes / 60.0;
    double solarNoonMin = 720.0 - (lng * 4.0) - eot + (tzOffsetHours * 60.0);

    double cosHa = (sin(-0.833 * pi / 180.0) - sin(latRad) * sin(declRad)) / (cos(latRad) * cos(declRad));
    cosHa = cosHa.clamp(-1.0, 1.0);
    double haMin = acos(cosHa) * 180.0 / pi * 4.0;

    double cosFajr = (sin(-18.0 * pi / 180.0) - sin(latRad) * sin(declRad)) / (cos(latRad) * cos(declRad));
    cosFajr = cosFajr.clamp(-1.0, 1.0);
    double fajrMin = acos(cosFajr) * 180.0 / pi * 4.0;

    int sunrise = (solarNoonMin - haMin).round() + offsetMin;
    int sunset = (solarNoonMin + haMin).round() + offsetMin;
    int noon = solarNoonMin.round() + offsetMin;
    int fajr = (solarNoonMin - fajrMin).round() + offsetMin;
    int sehriEnd = fajr - 3;
    int iftar = sunset + 1;

    return {
      'sehriEnd': sehriEnd,
      'sunrise': sunrise,
      'noon': noon,
      'sunset': sunset,
      'iftar': iftar,
    };
  }

  static String formatMin(int totalMinutes) {
    int m = (totalMinutes % 1440 + 1440) % 1440;
    int h = m ~/ 60;
    int min = m % 60;
    String period = h >= 12 ? 'PM' : 'AM';
    int displayH = h % 12 == 0 ? 12 : h % 12;
    return "$displayH:${min.toString().padLeft(2, '0')} $period";
  }

  static Map<String, dynamic> evaluateStatus(DateTime now, {required double lat, required double lng, int offsetMin = 0}) {
    final times = getTimes(now, lat: lat, lng: lng, offsetMin: offsetMin);
    int cur = now.hour * 60 + now.minute;

    int sehriEnd = times['sehriEnd']!;
    int sunrise = times['sunrise']!;
    int noon = times['noon']!;
    int sunset = times['sunset']!;
    int iftar = times['iftar']!;

    if (cur >= sunrise && cur < sunrise + 18) {
      return {
        'statusType': 2,
        'icon': '⛔',
        'title': 'Sunrise (No Salah)',
        'isForbidden': true,
      };
    }
    if (cur >= noon - 12 && cur < noon) {
      return {
        'statusType': 2,
        'icon': '⛔',
        'title': 'Zawwal (No Salah)',
        'isForbidden': true,
      };
    }
    if (cur >= sunset - 15 && cur < sunset) {
      return {
        'statusType': 2,
        'icon': '⛔',
        'title': 'Sunset (No Salah)',
        'isForbidden': true,
      };
    }

    if (cur >= iftar && cur < iftar + 35) {
      return {
        'statusType': 1,
        'icon': '🍽️',
        'title': 'Iftar Now (${formatMin(iftar)})',
        'isForbidden': false,
      };
    }

    if (cur >= sehriEnd - 60 && cur <= sehriEnd) {
      int left = sehriEnd - cur;
      return {
        'statusType': 1,
        'icon': '🥣',
        'title': left <= 20 ? 'Sehri: ${left}m left' : 'Sehri Ends ${formatMin(sehriEnd)}',
        'isForbidden': false,
      };
    }

    if (cur >= noon + 240 && cur < sunset - 15) {
      return {
        'statusType': 0,
        'icon': '🌇',
        'title': 'Iftar: ${formatMin(iftar)}',
        'isForbidden': false,
      };
    }

    bool isNight = cur < sunrise || cur >= sunset;
    return {
      'statusType': 0,
      'icon': isNight ? '🌙' : '☀️',
      'title': 'Salah Open',
      'isForbidden': false,
    };
  }
}

class HijriCalculator {
  static const List<String> hijriMonths = [
    "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
    "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
    "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
  ];

  static Map<String, dynamic> calculate(DateTime date, int offsetDays, {int sunsetMin = 1095}) {
    int curMin = date.hour * 60 + date.minute;
    bool isAfterMaghrib = curMin >= sunsetMin;

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
      'formatted': "$hDay $monthName $hYear AH"
    };
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
  List<DhikrItem> _dhikrList = [];
  int _currentIndex = 0;
  int _currentCount = 0;

  double _fontScale = 1.0;
  int _hijriOffset = 0;

  String _countryName = "Bangladesh";
  double _userLat = 23.8103;
  double _userLng = 90.4125;
  int _districtOffsetMin = 0;

  Map<String, int> _dailyHistory = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllData().then((_) {
      _checkTimeNoticePrompt();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveAllData();
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontScale = prefs.getDouble('fontScale') ?? 1.0;
      _hijriOffset = prefs.getInt('hijriOffset') ?? 0;

      _countryName = prefs.getString('countryName') ?? "Bangladesh";
      _userLat = prefs.getDouble('userLat') ?? 23.8103;
      _userLng = prefs.getDouble('userLng') ?? 90.4125;
      _districtOffsetMin = prefs.getInt('districtOffsetMin') ?? 0;

      _currentIndex = prefs.getInt('currentIndex') ?? 0;
      _currentCount = prefs.getInt('currentCount') ?? 0;

      final dhikrString = prefs.getString('dhikrList');
      if (dhikrString != null) {
        final List decoded = jsonDecode(dhikrString);
        _dhikrList = decoded.map((e) => DhikrItem.fromJson(e)).toList();
      } else {
        _dhikrList = [
          DhikrItem(title: "Subhanallah", arabic: "سُبْحَانَ ٱللَّٰهِ", meaning: "Glory be to Allah", target: 33),
          DhikrItem(title: "Alhamdulillah", arabic: "ٱلْحَمْدُ لِلَّٰهِ", meaning: "Praise be to Allah", target: 33),
          DhikrItem(title: "Allahu Akbar", arabic: "ٱللَّٰهُ أَكْبَرُ", meaning: "Allah is the Greatest", target: 34),
          DhikrItem(title: "Kalima Tayyibah", arabic: "لَا إِلَٰهَ إِلَّا ٱللَّٰهُ مُحَمَّدٌ رَّسُولُ ٱللَّٰهِ", meaning: "There is no god but Allah, Muhammad is the Messenger of Allah", target: 100),
          DhikrItem(title: "Astaghfirullah", arabic: "أَسْتَغْفِرُ ٱللَّٰهَ", meaning: "I seek forgiveness from Allah", target: 100),
        ];
      }

      if (_currentIndex >= _dhikrList.length) _currentIndex = 0;

      final historyString = prefs.getString('dailyHistory');
      if (historyString != null) {
        final Map<String, dynamic> decoded = jsonDecode(historyString);
        _dailyHistory = decoded.map((k, v) => MapEntry(k, v as int));
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _checkTimeNoticePrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hidePrompt = prefs.getBool('hide_time_notice_prompt') ?? false;
      if (!hidePrompt && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showInitialTimeNoticeDialog();
        });
      }
    } catch (_) {}
  }

  void _showInitialTimeNoticeDialog() {
    bool doNotShowAgain = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF222428),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.access_time_filled, color: Color(0xFF00B074)),
              SizedBox(width: 10),
              Text(
                'Set Your Local Time',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prayer and Iftar times are calculated offline based on your country\'s capital. If your local mosque differs by a few minutes, adjust the offset in Settings.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  setDlgState(() {
                    doNotShowAgain = !doNotShowAgain;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: doNotShowAgain,
                      activeColor: const Color(0xFF00B074),
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setDlgState(() {
                          doNotShowAgain = val ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Don\'t show again',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (doNotShowAgain) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hide_time_notice_prompt', true);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Later', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B074),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hide_time_notice_prompt', true);
                Navigator.pop(ctx);
                _openSettingsModal();
              },
              child: const Text('Adjust Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontScale', _fontScale);
      await prefs.setInt('hijriOffset', _hijriOffset);

      await prefs.setString('countryName', _countryName);
      await prefs.setDouble('userLat', _userLat);
      await prefs.setDouble('userLng', _userLng);
      await prefs.setInt('districtOffsetMin', _districtOffsetMin);

      await prefs.setInt('currentIndex', _currentIndex);
      await prefs.setInt('currentCount', _currentCount);
      await prefs.setString('dhikrList', jsonEncode(_dhikrList.map((e) => e.toJson()).toList()));
      await prefs.setString('dailyHistory', jsonEncode(_dailyHistory));
    } catch (_) {}
  }

  void _onTapCounter() {
    if (_dhikrList.isEmpty) return;

    setState(() {
      _currentCount++;
      _dhikrList[_currentIndex].lifetimeCount++;

      final today = _getTodayKey();
      _dailyHistory[today] = (_dailyHistory[today] ?? 0) + 1;
    });

    _saveAllData();
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
          mainAxisSize: minAxisSize,
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

  static const MainAxisSize minAxisSize = MainAxisSize.min;

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

  void _openCountrySearchDialog(StateSetter setSettingsState) {
    String query = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2024),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredCountries = SolarCalculator.worldCountries.where((c) {
            return c.name.toLowerCase().contains(query.toLowerCase());
          }).toList();

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    autofocus: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00B074)),
                      filled: true,
                      fillColor: const Color(0xFF26282D),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        query = val;
                      });
                    },
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected = country.name == _countryName;
                      return ListTile(
                        onTap: () {
                          setState(() {
                            _countryName = country.name;
                            _userLat = country.lat;
                            _userLng = country.lng;
                            _districtOffsetMin = 0;
                          });
                          setSettingsState(() {});
                          _saveAllData();
                          Navigator.pop(ctx);
                        },
                        leading: Icon(
                          Icons.public,
                          color: isSelected ? const Color(0xFF00B074) : Colors.white38,
                          size: 20,
                        ),
                        title: Text(
                          country.name,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00B074) : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF00B074), size: 20)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
                decoration: const InputDecoration(labelText: 'Meaning', labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Target Count', labelStyle: TextStyle(color: Colors.white60)),
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
              final practicalMeaning = meaningCtrl.text.trim();
              final target = int.tryParse(targetCtrl.text.trim()) ?? 33;

              if (title.isEmpty || arabic.isEmpty) return;

              setState(() {
                if (item == null) {
                  _dhikrList.add(DhikrItem(title: title, arabic: arabic, meaning: practicalMeaning, target: target));
                } else if (index != null) {
                  _dhikrList[index].title = title;
                  _dhikrList[index].arabic = arabic;
                  _dhikrList[index].meaning = practicalMeaning;
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
          height: MediaQuery.of(context).size.height * 0.88,
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
                    Text('Settings & Calculations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.public, color: Color(0xFF00B074)),
                      title: const Text('Country / Region', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(_countryName, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                      onTap: () => _openCountrySearchDialog(setSettingsState),
                    ),
                    const Divider(color: Colors.white12),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'District / Mosque Time Offset',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Adjust if your local district or mosque azan differs from capital standard time:',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26282D),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.white70, size: 28),
                                  onPressed: () {
                                    if (_districtOffsetMin > -30) {
                                      setState(() => _districtOffsetMin--);
                                      setSettingsState(() {});
                                      _saveAllData();
                                    }
                                  },
                                ),
                                Column(
                                  children: [
                                    Text(
                                      _districtOffsetMin == 0
                                          ? "Standard (0m)"
                                          : (_districtOffsetMin > 0
                                              ? "+$_districtOffsetMin Minutes"
                                              : "$_districtOffsetMin Minutes"),
                                      style: TextStyle(
                                        color: _districtOffsetMin == 0 ? Colors.white : const Color(0xFF00B074),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _districtOffsetMin == 0
                                          ? "Capital standard time"
                                          : (_districtOffsetMin > 0 ? "Added to local prayers" : "Subtracted from local prayers"),
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Color(0xFF00B074), size: 28),
                                  onPressed: () {
                                    if (_districtOffsetMin < 30) {
                                      setState(() => _districtOffsetMin++);
                                      setSettingsState(() {});
                                      _saveAllData();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12),

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
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(color: Colors.white12),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Last 7 Days Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    _buildHistoryBars(),
                    const Divider(color: Colors.white12),

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
                    const Divider(color: Colors.white12),

                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Color(0xFF00B074)),
                      title: const Text('About Tasbih', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('App dedication & developer credits', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAboutDialog();
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
    final times = SolarCalculator.getTimes(now, lat: _userLat, lng: _userLng, offsetMin: _districtOffsetMin);
    final hijri = HijriCalculator.calculate(now, _hijriOffset, sunsetMin: times['sunset']!);
    final status = SolarCalculator.evaluateStatus(now, lat: _userLat, lng: _userLng, offsetMin: _districtOffsetMin);

    final currentDhikr = _dhikrList.isNotEmpty
        ? _dhikrList[_currentIndex]
        : DhikrItem(title: "Tasbih", arabic: "سُبْحَانَ ٱللَّٰهِ", meaning: "Glory be to Allah", target: 33);

    final target = currentDhikr.target;
    final double progress = target > 0 ? (_currentCount / target).clamp(0.0, 1.0) : 0.0;

    Color badgeBg = const Color(0xFF222428);
    Color badgeBorder = Colors.white12;
    Color badgeText = Colors.white70;

    if (status['statusType'] == 1) {
      badgeBg = const Color(0xFF00B074).withOpacity(0.2);
      badgeBorder = const Color(0xFF00B074).withOpacity(0.5);
      badgeText = const Color(0xFF00B074);
    } else if (status['statusType'] == 2) {
      badgeBg = const Color(0xFFD32F2F).withOpacity(0.2);
      badgeBorder = const Color(0xFFD32F2F).withOpacity(0.5);
      badgeText = Colors.redAccent;
    }

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTapCounter,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text(
                      'Tasbih',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(status['icon'], style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  status['statusType'] != 0
                                      ? "${hijri['day']} ${hijri['month']} • ${status['title']}"
                                      : "${hijri['day']} ${hijri['month']} ${hijri['year']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted, color: Color(0xFF00B074)),
                      onPressed: _openDhikrListModal,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      onPressed: _openSettingsModal,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

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
                    const SizedBox(width: 26),
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
