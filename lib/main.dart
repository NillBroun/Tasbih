import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await NotificationService.instance.init();
  runApp(const TasbihApp());
}

// ============================================================================
// 1. DATA MODELS
// ============================================================================

class DhikrItem {
  final String id;
  final String title;
  final String arabic;
  final String meaning;
  final int target;

  const DhikrItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.meaning,
    required this.target,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabic': arabic,
        'meaning': meaning,
        'target': target,
      };

  factory DhikrItem.fromJson(Map<String, dynamic> json) => DhikrItem(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? 'Dhikr',
        arabic: json['arabic']?.toString() ?? '',
        meaning: json['meaning']?.toString() ?? '',
        target: (json['target'] is int)
            ? json['target']
            : int.tryParse(json['target'].toString()) ?? 33,
      );
}

class RegionInfo {
  final String name;
  final String timezone;
  final String utcLabel;
  final double lat;
  final double lng;

  const RegionInfo(this.name, this.timezone, this.utcLabel, this.lat, this.lng);
}

// 95+ Muslim-majority & global Muslim-populated regions with exact coordinates & IANA Timezones
const List<RegionInfo> kGlobalRegions = [
  // South Asia
  RegionInfo('Bangladesh - Dhaka', 'Asia/Dhaka', 'UTC+6', 23.8103, 90.4125),
  RegionInfo('Bangladesh - Chattogram', 'Asia/Dhaka', 'UTC+6', 22.3569, 91.7832),
  RegionInfo('Bangladesh - Sylhet', 'Asia/Dhaka', 'UTC+6', 24.8949, 91.8687),
  RegionInfo('Bangladesh - Rajshahi', 'Asia/Dhaka', 'UTC+6', 24.3745, 88.6042),
  RegionInfo('Bangladesh - Khulna', 'Asia/Dhaka', 'UTC+6', 22.8456, 89.5403),
  RegionInfo('Bangladesh - Barishal', 'Asia/Dhaka', 'UTC+6', 22.7010, 90.3535),
  RegionInfo('Bangladesh - Rangpur', 'Asia/Dhaka', 'UTC+6', 25.7439, 89.2752),
  RegionInfo('Bangladesh - Mymensingh', 'Asia/Dhaka', 'UTC+6', 24.7471, 90.4203),
  RegionInfo('India - Kolkata (East)', 'Asia/Kolkata', 'UTC+5:30', 22.5726, 88.3639),
  RegionInfo('India - New Delhi (North)', 'Asia/Kolkata', 'UTC+5:30', 28.6139, 77.2090),
  RegionInfo('India - Mumbai (West)', 'Asia/Kolkata', 'UTC+5:30', 19.0760, 72.8777),
  RegionInfo('India - Hyderabad (South)', 'Asia/Kolkata', 'UTC+5:30', 17.3850, 78.4867),
  RegionInfo('Pakistan - Islamabad', 'Asia/Karachi', 'UTC+5', 33.6844, 73.0479),
  RegionInfo('Pakistan - Karachi', 'Asia/Karachi', 'UTC+5', 24.8607, 67.0011),
  RegionInfo('Pakistan - Lahore', 'Asia/Karachi', 'UTC+5', 31.5204, 74.3587),
  RegionInfo('Maldives - Male', 'Indian/Maldives', 'UTC+5', 4.1755, 73.5093),
  RegionInfo('Afghanistan - Kabul', 'Asia/Kabul', 'UTC+4:30', 34.5553, 69.2075),
  RegionInfo('Sri Lanka - Colombo', 'Asia/Colombo', 'UTC+5:30', 6.9271, 79.8612),
  RegionInfo('Nepal - Kathmandu', 'Asia/Kathmandu', 'UTC+5:45', 27.7172, 85.3240),

  // Middle East (Including Holy Cities Makkah & Madinah)
  RegionInfo('Saudi Arabia - Makkah', 'Asia/Riyadh', 'UTC+3', 21.4225, 39.8262),
  RegionInfo('Saudi Arabia - Madinah', 'Asia/Riyadh', 'UTC+3', 24.4672, 39.6111),
  RegionInfo('Saudi Arabia - Riyadh', 'Asia/Riyadh', 'UTC+3', 24.7136, 46.6753),
  RegionInfo('Saudi Arabia - Jeddah', 'Asia/Riyadh', 'UTC+3', 21.4858, 39.1925),
  RegionInfo('UAE - Dubai', 'Asia/Dubai', 'UTC+4', 25.2048, 55.2708),
  RegionInfo('UAE - Abu Dhabi', 'Asia/Dubai', 'UTC+4', 24.4539, 54.3773),
  RegionInfo('Qatar - Doha', 'Asia/Qatar', 'UTC+3', 25.2854, 51.5310),
  RegionInfo('Kuwait - Kuwait City', 'Asia/Kuwait', 'UTC+3', 29.3759, 47.9774),
  RegionInfo('Oman - Muscat', 'Asia/Muscat', 'UTC+4', 23.5880, 58.3829),
  RegionInfo('Bahrain - Manama', 'Asia/Bahrain', 'UTC+3', 26.2285, 50.5860),
  RegionInfo('Turkey - Istanbul', 'Europe/Istanbul', 'UTC+3', 41.0082, 28.9784),
  RegionInfo('Turkey - Ankara', 'Europe/Istanbul', 'UTC+3', 39.9334, 32.8597),
  RegionInfo('Palestine - Jerusalem (Al-Quds)', 'Asia/Jerusalem', 'UTC+2', 31.7683, 35.2137),
  RegionInfo('Jordan - Amman', 'Asia/Amman', 'UTC+3', 31.9454, 35.9284),
  RegionInfo('Lebanon - Beirut', 'Asia/Beirut', 'UTC+2', 33.8938, 35.5018),
  RegionInfo('Iraq - Baghdad', 'Asia/Baghdad', 'UTC+3', 33.3152, 44.3661),
  RegionInfo('Iran - Tehran', 'Asia/Tehran', 'UTC+3:30', 35.6892, 51.3890),
  RegionInfo('Syria - Damascus', 'Asia/Damascus', 'UTC+3', 33.5138, 36.2765),
  RegionInfo('Yemen - Sanaa', 'Asia/Aden', 'UTC+3', 15.3694, 44.1910),

  // Southeast & East Asia
  RegionInfo('Indonesia - Jakarta', 'Asia/Jakarta', 'UTC+7', -6.2088, 106.8456),
  RegionInfo('Indonesia - Makassar', 'Asia/Makassar', 'UTC+8', -5.1477, 119.4327),
  RegionInfo('Malaysia - Kuala Lumpur', 'Asia/Kuala_Lumpur', 'UTC+8', 3.1390, 101.6869),
  RegionInfo('Brunei - Bandar Seri Begawan', 'Asia/Brunei', 'UTC+8', 4.9031, 114.9398),
  RegionInfo('Singapore', 'Asia/Singapore', 'UTC+8', 1.3521, 103.8198),
  RegionInfo('China - Beijing / Shanghai', 'Asia/Shanghai', 'UTC+8', 31.2304, 121.4737),
  RegionInfo('China - Guangzhou', 'Asia/Shanghai', 'UTC+8', 23.1291, 113.2644),
  RegionInfo('China - Urumqi (Xinjiang)', 'Asia/Urumqi', 'UTC+6', 43.8256, 87.6168),
  RegionInfo('Japan - Tokyo', 'Asia/Tokyo', 'UTC+9', 35.6762, 139.6503),
  RegionInfo('South Korea - Seoul', 'Asia/Seoul', 'UTC+9', 37.5665, 126.9780),
  RegionInfo('Thailand - Bangkok', 'Asia/Bangkok', 'UTC+7', 13.7563, 100.5018),
  RegionInfo('Philippines - Manila', 'Asia/Manila', 'UTC+8', 14.5995, 120.9842),
  RegionInfo('Myanmar - Yangon', 'Asia/Yangon', 'UTC+6:30', 16.8409, 96.1735),
  RegionInfo('Hong Kong', 'Asia/Hong_Kong', 'UTC+8', 22.3193, 114.1694),
  RegionInfo('Taiwan - Taipei', 'Asia/Taipei', 'UTC+8', 25.0330, 121.5654),

  // Central Asia
  RegionInfo('Uzbekistan - Tashkent', 'Asia/Tashkent', 'UTC+5', 41.2995, 69.2401),
  RegionInfo('Kazakhstan - Astana', 'Asia/Almaty', 'UTC+5', 51.1694, 71.4491),
  RegionInfo('Kazakhstan - Almaty', 'Asia/Almaty', 'UTC+5', 43.2220, 76.8512),
  RegionInfo('Kyrgyzstan - Bishkek', 'Asia/Bishkek', 'UTC+6', 42.8746, 74.5698),
  RegionInfo('Tajikistan - Dushanbe', 'Asia/Dushanbe', 'UTC+5', 38.5598, 68.7870),
  RegionInfo('Turkmenistan - Ashgabat', 'Asia/Ashgabat', 'UTC+5', 37.9601, 58.3261),
  RegionInfo('Azerbaijan - Baku', 'Asia/Baku', 'UTC+4', 40.4093, 49.8671),

  // Europe
  RegionInfo('United Kingdom - London', 'Europe/London', 'UTC+0', 51.5074, -0.1278),
  RegionInfo('United Kingdom - Birmingham', 'Europe/London', 'UTC+0', 52.4862, -1.8904),
  RegionInfo('Germany - Berlin', 'Europe/Berlin', 'UTC+1', 52.5200, 13.4050),
  RegionInfo('Germany - Frankfurt', 'Europe/Berlin', 'UTC+1', 50.1109, 8.6821),
  RegionInfo('France - Paris', 'Europe/Paris', 'UTC+1', 48.8566, 2.3522),
  RegionInfo('Italy - Rome', 'Europe/Rome', 'UTC+1', 41.9028, 12.4964),
  RegionInfo('Spain - Madrid', 'Europe/Madrid', 'UTC+1', 40.4168, -3.7038),
  RegionInfo('Netherlands - Amsterdam', 'Europe/Amsterdam', 'UTC+1', 52.3676, 4.9041),
  RegionInfo('Belgium - Brussels', 'Europe/Brussels', 'UTC+1', 50.8503, 4.3517),
  RegionInfo('Sweden - Stockholm', 'Europe/Stockholm', 'UTC+1', 59.3293, 18.0686),
  RegionInfo('Norway - Oslo', 'Europe/Oslo', 'UTC+1', 59.9139, 10.7522),
  RegionInfo('Denmark - Copenhagen', 'Europe/Copenhagen', 'UTC+1', 55.6761, 12.5683),
  RegionInfo('Switzerland - Zurich', 'Europe/Zurich', 'UTC+1', 47.3769, 8.5417),
  RegionInfo('Austria - Vienna', 'Europe/Vienna', 'UTC+1', 48.2082, 16.3738),
  RegionInfo('Ireland - Dublin', 'Europe/Dublin', 'UTC+0', 53.3498, -6.2603),
  RegionInfo('Bosnia & Herzegovina - Sarajevo', 'Europe/Sarajevo', 'UTC+1', 43.8563, 18.4131),
  RegionInfo('Albania - Tirana', 'Europe/Tirane', 'UTC+1', 41.3275, 19.8187),
  RegionInfo('Kosovo - Pristina', 'Europe/Belgrade', 'UTC+1', 42.6629, 21.1655),
  RegionInfo('Russia - Moscow', 'Europe/Moscow', 'UTC+3', 55.7558, 37.6173),
  RegionInfo('Greece - Athens', 'Europe/Athens', 'UTC+2', 37.9838, 23.7275),
  RegionInfo('Portugal - Lisbon', 'Europe/Lisbon', 'UTC+0', 38.7223, -9.1393),

  // Africa
  RegionInfo('Egypt - Cairo', 'Africa/Cairo', 'UTC+2', 30.0444, 31.2357),
  RegionInfo('Morocco - Casablanca', 'Africa/Casablanca', 'UTC+1', 33.5731, -7.5898),
  RegionInfo('Algeria - Algiers', 'Africa/Algiers', 'UTC+1', 36.7538, 3.0588),
  RegionInfo('Tunisia - Tunis', 'Africa/Tunis', 'UTC+1', 36.8065, 10.1815),
  RegionInfo('Libya - Tripoli', 'Africa/Tripoli', 'UTC+2', 32.8872, 13.1913),
  RegionInfo('Sudan - Khartoum', 'Africa/Khartoum', 'UTC+2', 15.5007, 32.5599),
  RegionInfo('Nigeria - Abuja', 'Africa/Lagos', 'UTC+1', 9.0765, 7.3986),
  RegionInfo('Nigeria - Lagos', 'Africa/Lagos', 'UTC+1', 6.5244, 3.3792),
  RegionInfo('South Africa - Johannesburg', 'Africa/Johannesburg', 'UTC+2', -26.2041, 28.0473),
  RegionInfo('South Africa - Cape Town', 'Africa/Johannesburg', 'UTC+2', -33.9249, 18.4241),
  RegionInfo('Kenya - Nairobi', 'Africa/Nairobi', 'UTC+3', -1.2921, 36.8219),
  RegionInfo('Somalia - Mogadishu', 'Africa/Mogadishu', 'UTC+3', 2.0469, 45.3182),
  RegionInfo('Ethiopia - Addis Ababa', 'Africa/Addis_Ababa', 'UTC+3', 9.0320, 38.7469),
  RegionInfo('Senegal - Dakar', 'Africa/Dakar', 'UTC+0', 14.7167, -17.4677),

  // Americas & Oceania
  RegionInfo('USA - New York (EST)', 'America/New_York', 'UTC-5', 40.7128, -74.0060),
  RegionInfo('USA - Chicago (CST)', 'America/Chicago', 'UTC-6', 41.8781, -87.6298),
  RegionInfo('USA - Houston (CST)', 'America/Chicago', 'UTC-6', 29.7604, -95.3698),
  RegionInfo('USA - Los Angeles (PST)', 'America/Los_Angeles', 'UTC-8', 34.0522, -118.2437),
  RegionInfo('Canada - Toronto', 'America/Toronto', 'UTC-5', 43.6532, -79.3832),
  RegionInfo('Canada - Vancouver', 'America/Vancouver', 'UTC-8', 49.2827, -123.1207),
  RegionInfo('Brazil - Sao Paulo', 'America/Sao_Paulo', 'UTC-3', -23.5505, -46.6333),
  RegionInfo('Australia - Sydney', 'Australia/Sydney', 'UTC+10', -33.8688, 151.2093),
  RegionInfo('Australia - Melbourne', 'Australia/Melbourne', 'UTC+10', -37.8136, 144.9631),
  RegionInfo('Australia - Perth', 'Australia/Perth', 'UTC+8', -31.9505, 115.8605),
  RegionInfo('New Zealand - Auckland', 'Pacific/Auckland', 'UTC+12', -36.8485, 174.7633),
];

// ============================================================================
// 2. OFFLINE SOLAR & TIMING ENGINE (WITH 3-MIN SEHRI-FAJR GAP & 30-MIN IFTAR)
// ============================================================================

class DailySolarTimes {
  final int sehriEndMin; // Imsak / Sehri ends (3 mins before Fajr)
  final int fajrStartMin; // Fajr begins
  final int sunriseMin; // Sunrise begins (Forbidden 15m)
  final int zawwalStartMin; // Solar Noon - 8m (Forbidden 16m)
  final int solarNoonMin; // Dhuhr / Midday
  final int sunsetMin; // Sunset / Maghrib / Iftar begins (Forbidden 15m before sunset)

  const DailySolarTimes({
    required this.sehriEndMin,
    required this.fajrStartMin,
    required this.sunriseMin,
    required this.zawwalStartMin,
    required this.solarNoonMin,
    required this.sunsetMin,
  });
}

class LiveTimingStatus {
  final String icon;
  final String label;
  final String colorHex;
  final bool isForbidden;
  final String dayPhase; // 'sunrise', 'midday', 'sunset', 'night'
  final String hijriFormatted;
  final String gregFormatted;

  const LiveTimingStatus({
    required this.icon,
    required this.label,
    required this.colorHex,
    required this.isForbidden,
    required this.dayPhase,
    required this.hijriFormatted,
    required this.gregFormatted,
  });
}

class SolarEngine {
  static tz.TZDateTime nowInRegion(RegionInfo region) {
    try {
      final location = tz.getLocation(region.timezone);
      return tz.TZDateTime.now(location);
    } catch (_) {
      final now = DateTime.now();
      return tz.TZDateTime.from(now, tz.local);
    }
  }

  static DailySolarTimes calculate(
    DateTime localDate,
    RegionInfo region,
    int manualOffsetMinutes,
  ) {
    double tzOffsetHours = 6.0;
    try {
      final loc = tz.getLocation(region.timezone);
      final tzDate = tz.TZDateTime(loc, localDate.year, localDate.month, localDate.day, 12, 0);
      tzOffsetHours = tzDate.timeZoneOffset.inMinutes / 60.0;
    } catch (_) {
      tzOffsetHours = DateTime.now().timeZoneOffset.inMinutes / 60.0;
    }

    final int dayOfYear = int.parse(DateFormat('D').format(localDate));
    final double gamma = (2.0 * math.pi / 365.0) * (dayOfYear - 1);

    final double eqTime = 229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));

    final double decl = 0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma) +
        0.000907 * math.sin(2 * gamma) -
        0.002697 * math.cos(3 * gamma) +
        0.00148 * math.sin(3 * gamma);

    final double latRad = region.lat * math.pi / 180.0;
    final double noonMinutes = 720.0 - 4.0 * region.lng - eqTime + (tzOffsetHours * 60.0);

    double hourAngleForZenith(double zenithDeg) {
      final double zenithRad = zenithDeg * math.pi / 180.0;
      double cosH = (math.cos(zenithRad) - math.sin(latRad) * math.sin(decl)) /
          (math.cos(latRad) * math.cos(decl));
      cosH = cosH.clamp(-0.999, 0.999);
      return math.acos(cosH) * 180.0 / math.pi;
    }

    final double haSunrise = hourAngleForZenith(90.833);
    final double haFajr = hourAngleForZenith(108.0);

    final int sunrise = (noonMinutes - 4.0 * haSunrise).round() + manualOffsetMinutes;
    final int sunset = (noonMinutes + 4.0 * haSunrise).round() + manualOffsetMinutes;
    final int fajrStart = (noonMinutes - 4.0 * haFajr).round() + manualOffsetMinutes;
    final int sehriEnd = fajrStart - 3;
    final int noon = noonMinutes.round() + manualOffsetMinutes;
    final int zawwalStart = noon - 8;

    return DailySolarTimes(
      sehriEndMin: sehriEnd,
      fajrStartMin: fajrStart,
      sunriseMin: sunrise,
      zawwalStartMin: zawwalStart,
      solarNoonMin: noon,
      sunsetMin: sunset,
    );
  }

  static String formatMinutes12h(int totalMinutes) {
    int normalized = totalMinutes % 1440;
    if (normalized < 0) normalized += 1440;
    final int h24 = normalized ~/ 60;
    final int m = normalized % 60;
    final String period = h24 >= 12 ? 'PM' : 'AM';
    int h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  static LiveTimingStatus getLiveStatus({
    required RegionInfo region,
    required int manualOffsetMinutes,
    required int hijriDayAdjustment,
  }) {
    final now = nowInRegion(region);
    final int currentMin = now.hour * 60 + now.minute;
    final times = calculate(now, region, manualOffsetMinutes);

    DateTime hijriBaseDate = DateTime(now.year, now.month, now.day);
    if (currentMin >= times.sunsetMin) {
      hijriBaseDate = hijriBaseDate.add(const Duration(days: 1));
    }
    hijriBaseDate = hijriBaseDate.add(Duration(days: hijriDayAdjustment));
    final hijri = HijriCalendar.fromDate(hijriBaseDate);
    final String hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
    final String gregStr = DateFormat('EEE, d MMM').format(now);

    String phase = 'night';
    if (currentMin >= times.fajrStartMin && currentMin < times.sunriseMin + 150) {
      phase = 'sunrise';
    } else if (currentMin >= times.sunriseMin + 150 && currentMin < times.sunsetMin - 60) {
      phase = 'midday';
    } else if (currentMin >= times.sunsetMin - 60 && currentMin < times.sunsetMin + 45) {
      phase = 'sunset';
    } else {
      phase = 'night';
    }

    if (currentMin >= times.sunriseMin && currentMin < times.sunriseMin + 15) {
      return LiveTimingStatus(
        icon: '⛔',
        label: 'Sunrise (No Salah)',
        colorHex: '#FB7185',
        isForbidden: true,
        dayPhase: 'sunrise',
        hijriFormatted: hijriStr,
        gregFormatted: gregStr,
      );
    }

    if (currentMin >= times.zawwalStartMin && currentMin < times.solarNoonMin + 8) {
      return LiveTimingStatus(
        icon: '⛔',
        label: 'Zawwal (No Salah)',
        colorHex: '#FB7185',
        isForbidden: true,
        dayPhase: 'midday',
        hijriFormatted: hijriStr,
        gregFormatted: gregStr,
      );
    }

    if (currentMin >= times.sunsetMin - 15 && currentMin < times.sunsetMin) {
      return LiveTimingStatus(
        icon: '⛔',
        label: 'Sunset (No Salah)',
        colorHex: '#FB7185',
        isForbidden: true,
        dayPhase: 'sunset',
        hijriFormatted: hijriStr,
        gregFormatted: gregStr,
      );
    }

    if (currentMin >= times.sehriEndMin && currentMin < times.fajrStartMin) {
      final int rem = times.fajrStartMin - currentMin;
      return LiveTimingStatus(
        icon: '⏳',
        label: 'Fajr in ${rem}m (Pause)',
        colorHex: '#FBBF24',
        isForbidden: false,
        dayPhase: 'sunrise',
        hijriFormatted: hijriStr,
        gregFormatted: gregStr,
      );
    }

    if (currentMin >= times.sehriEndMin - 30 && currentMin < times.sehriEndMin) {
      final int rem = times.sehriEndMin - currentMin;
      return LiveTimingStatus(
        icon: '🥣',
        label: 'Sehri: ${rem}m left',
        colorHex: '#38BDF8',
        isForbidden: false,
        dayPhase: 'night',
        hijriFormatted: hijriStr,
        gregFormatted: gregStr,
      );
    }

    if (currentMin >= times.sunsetMin && currentMin < times.sunsetMin + 30) {
      return LiveTimingStatus(
        icon: '🍽️',
        label: 'Iftar Now (${formatMinutes12h(times.sunsetMin)})',
        colorHex: '#34D399',
        isForbidden: false,
        dayPhase: 'sunset',
        hijriFormatted: hijriStr,
        gregFormatted: gregStr,
      );
    }

    final String openIcon = phase == 'sunrise'
        ? '🌅'
        : phase == 'midday'
            ? '☀️'
            : phase == 'sunset'
                ? '🌇'
                : '🌙';

    return LiveTimingStatus(
      icon: openIcon,
      label: 'Salah Open',
      colorHex: '#F8FAFC',
      isForbidden: false,
      dayPhase: phase,
      hijriFormatted: hijriStr,
      gregFormatted: gregStr,
    );
  }
}

// ============================================================================
// 3. TIMEZONE-AWARE NOTIFICATION SERVICE (4 TOGGLEABLE SWITCHES)
// ============================================================================

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
      _initialized = true;
    } catch (_) {}
  }

  Future<void> rescheduleAll({
    required RegionInfo region,
    required int manualOffsetMinutes,
    required bool notifSehriStart,
    required bool notifSehriEnd,
    required bool notifIftar,
    required bool notifForbidden,
  }) async {
    try {
      await init();
      await _plugin.cancelAll();

      if (!notifSehriStart && !notifSehriEnd && !notifIftar && !notifForbidden) {
        return;
      }

      tz.Location location;
      try {
        location = tz.getLocation(region.timezone);
      } catch (_) {
        location = tz.local;
      }

      final now = tz.TZDateTime.now(location);
      int idCounter = 100;

      for (int dayOffset = 0; dayOffset <= 1; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        final solar = SolarEngine.calculate(targetDate, region, manualOffsetMinutes);

        Future<void> scheduleAtMinute(int minuteOfDay, String title, String body) async {
          final int h = (minuteOfDay ~/ 60).clamp(0, 23);
          final int m = (minuteOfDay % 60).clamp(0, 59);
          final scheduled = tz.TZDateTime(
            location,
            targetDate.year,
            targetDate.month,
            targetDate.day,
            h,
            m,
          );

          if (scheduled.isAfter(now)) {
            const androidDetails = AndroidNotificationDetails(
              'tasbih_solar_alerts',
              'Solar & Fasting Reminders',
              channelDescription: 'Notifications for Sehri, Iftar, and Forbidden Salah times',
              importance: Importance.high,
              priority: Priority.high,
            );
            await _plugin.zonedSchedule(
              idCounter++,
              title,
              body,
              scheduled,
              const NotificationDetails(android: androidDetails),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        }

        if (notifSehriStart) {
          await scheduleAtMinute(
            solar.sehriEndMin - 60,
            '🥣 Sehri Time Started',
            'Sehri ends at ${SolarEngine.formatMinutes12h(solar.sehriEndMin)} (${region.name})',
          );
        }

        if (notifSehriEnd) {
          await scheduleAtMinute(
            solar.sehriEndMin - 20,
            '⏳ 20 Minutes Left for Sehri',
            'Finish eating before ${SolarEngine.formatMinutes12h(solar.sehriEndMin)}. Fajr begins 3 mins later.',
          );
        }

        if (notifIftar) {
          await scheduleAtMinute(
            solar.sunsetMin,
            '🍽️ Iftar Time Now',
            'Sunset reached at ${SolarEngine.formatMinutes12h(solar.sunsetMin)} (${region.name})',
          );
        }

        if (notifForbidden) {
          await scheduleAtMinute(
            solar.sunriseMin,
            '⛔ Forbidden Time: Sunrise',
            'Avoid voluntary Salah for 15 minutes during sunrise.',
          );
          await scheduleAtMinute(
            solar.zawwalStartMin,
            '⛔ Forbidden Time: Zawwal (Midday)',
            'Solar zenith window (~16 mins). Avoid Salah until Dhuhr begins.',
          );
          await scheduleAtMinute(
            solar.sunsetMin - 15,
            '⛔ Forbidden Time: Sunset',
            'Avoid Salah during the last 15 minutes before sunset.',
          );
        }
      }
    } catch (_) {}
  }
}

// ============================================================================
// 4. HOME WIDGET SYNC HELPER (4x1 ULTRA-SLIM CAPSULE)
// ============================================================================

class WidgetSyncService {
  static Future<void> sync({
    required int todayCount,
    required LiveTimingStatus status,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('today_text', '📿 Today: $todayCount');
      await HomeWidget.saveWidgetData<String>(
          'status_text', '${status.icon} ${status.label}');
      await HomeWidget.saveWidgetData<String>('status_color', status.colorHex);
      await HomeWidget.saveWidgetData<String>('hijri_text', status.hijriFormatted);
      await HomeWidget.saveWidgetData<String>('greg_text', status.gregFormatted);
      await HomeWidget.saveWidgetData<String>('day_phase', status.dayPhase);

      await HomeWidget.updateWidget(
        name: 'TasbihWidgetProvider',
        qualifiedAndroidName: 'com.ahm.tasbih.TasbihWidgetProvider',
      );
    } catch (_) {}
  }
}

// ============================================================================
// 5. MAIN APPLICATION & THEME ENGINE (DARK / LIGHT PORCELAIN / AMOLED)
// ============================================================================

enum AppThemeMode { dark, light, amoled }

class TasbihApp extends StatefulWidget {
  const TasbihApp({super.key});

  @override
  State<TasbihApp> createState() => _TasbihAppState();
}

class _TasbihAppState extends State<TasbihApp> with WidgetsBindingObserver {
  List<DhikrItem> _dhikrList = [];
  int _selectedDhikrIndex = 0;
  int _sessionCount = 0;
  int _todayCount = 0;
  int _lifetimeCount = 0;
  Map<String, int> _weeklyHistory = {};

  AppThemeMode _themeMode = AppThemeMode.dark;
  double _fontScale = 1.0;
  int _regionIndex = 0;
  int _manualTimeOffset = 0;
  int _hijriDayOffset = 0;

  bool _notifSehriStart = false;
  bool _notifSehriEnd = false;
  bool _notifIftar = false;
  bool _notifForbidden = true;

  Timer? _clockTimer;
  late LiveTimingStatus _liveStatus;

  static const List<DhikrItem> _defaultDhikrs = [
    DhikrItem(
      id: '1',
      title: 'SubhanAllah',
      arabic: 'سُبْحَانَ اللَّهِ',
      meaning: 'Glory be to Allah',
      target: 33,
    ),
    DhikrItem(
      id: '2',
      title: 'Alhamdulillah',
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
      meaning: 'Praise be to Allah',
      target: 33,
    ),
    DhikrItem(
      id: '3',
      title: 'Allahu Akbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      meaning: 'Allah is the Greatest',
      target: 34,
    ),
    DhikrItem(
      id: '4',
      title: 'Astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      meaning: 'I seek forgiveness from Allah',
      target: 100,
    ),
    DhikrItem(
      id: '5',
      title: 'La ilaha illallah',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      meaning: 'There is no deity worthy of worship except Allah',
      target: 100,
    ),
    DhikrItem(
      id: '6',
      title: 'SubhanAllahi wa bihamdihi',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      meaning: 'Glory and praise be to Allah',
      target: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dhikrList = List.from(_defaultDhikrs);
    _liveStatus = SolarEngine.getLiveStatus(
      region: kGlobalRegions[_regionIndex],
      manualOffsetMinutes: _manualTimeOffset,
      hijriDayAdjustment: _hijriDayOffset,
    );
    _loadData();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshLiveStatusAndWidget();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLiveStatusAndWidget();
    }
  }

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = prefs.getString('dhikr_list');
    if (rawList != null) {
      try {
        final decoded = jsonDecode(rawList) as List;
        if (decoded.isNotEmpty) {
          _dhikrList = decoded.map((e) => DhikrItem.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    _selectedDhikrIndex =
        (prefs.getInt('selected_dhikr_index') ?? 0).clamp(0, _dhikrList.length - 1);
    _sessionCount = prefs.getInt('session_count') ?? 0;
    _lifetimeCount = prefs.getInt('lifetime_count') ?? 0;

    final rawHistory = prefs.getString('weekly_history');
    if (rawHistory != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(rawHistory);
        _weeklyHistory = map.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }
    _todayCount = _weeklyHistory[_todayKey()] ?? 0;

    final themeIdx = prefs.getInt('theme_mode') ?? 0;
    _themeMode = AppThemeMode.values[themeIdx.clamp(0, AppThemeMode.values.length - 1)];
    _fontScale = prefs.getDouble('font_scale') ?? 1.0;
    _regionIndex =
        (prefs.getInt('region_index') ?? 0).clamp(0, kGlobalRegions.length - 1);
    _manualTimeOffset = (prefs.getInt('manual_time_offset') ?? 0).clamp(-30, 30);
    _hijriDayOffset = (prefs.getInt('hijri_day_offset') ?? 0).clamp(-2, 2);

    _notifSehriStart = prefs.getBool('notif_sehri_start') ?? false;
    _notifSehriEnd = prefs.getBool('notif_sehri_end') ?? false;
    _notifIftar = prefs.getBool('notif_iftar') ?? false;
    _notifForbidden = prefs.getBool('notif_forbidden') ?? true;

    if (mounted) {
      setState(() {});
      _refreshLiveStatusAndWidget();
      _rescheduleNotifications();
    }
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'dhikr_list', jsonEncode(_dhikrList.map((e) => e.toJson()).toList()));
    await prefs.setInt('selected_dhikr_index', _selectedDhikrIndex);
    await prefs.setInt('session_count', _sessionCount);
    await prefs.setInt('lifetime_count', _lifetimeCount);
    await prefs.setString('weekly_history', jsonEncode(_weeklyHistory));

    await prefs.setInt('theme_mode', _themeMode.index);
    await prefs.setDouble('font_scale', _fontScale);
    await prefs.setInt('region_index', _regionIndex);
    await prefs.setInt('manual_time_offset', _manualTimeOffset);
    await prefs.setInt('hijri_day_offset', _hijriDayOffset);

    await prefs.setBool('notif_sehri_start', _notifSehriStart);
    await prefs.setBool('notif_sehri_end', _notifSehriEnd);
    await prefs.setBool('notif_iftar', _notifIftar);
    await prefs.setBool('notif_forbidden', _notifForbidden);
  }

  void _refreshLiveStatusAndWidget() {
    final status = SolarEngine.getLiveStatus(
      region: kGlobalRegions[_regionIndex],
      manualOffsetMinutes: _manualTimeOffset,
      hijriDayAdjustment: _hijriDayOffset,
    );
    if (mounted) {
      setState(() {
        _liveStatus = status;
        _todayCount = _weeklyHistory[_todayKey()] ?? 0;
      });
    }
    WidgetSyncService.sync(todayCount: _todayCount, status: status);
  }

  void _rescheduleNotifications() {
    NotificationService.instance.rescheduleAll(
      region: kGlobalRegions[_regionIndex],
      manualOffsetMinutes: _manualTimeOffset,
      notifSehriStart: _notifSehriStart,
      notifSehriEnd: _notifSehriEnd,
      notifIftar: _notifIftar,
      notifForbidden: _notifForbidden,
    );
  }

  void _incrementCounter() {
    final currentDhikr = _dhikrList[_selectedDhikrIndex];
    setState(() {
      if (_sessionCount >= currentDhikr.target) {
        _sessionCount = 1;
      } else {
        _sessionCount++;
      }

      if (_sessionCount == currentDhikr.target) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }

      _lifetimeCount++;
      final key = _todayKey();
      _todayCount = (_weeklyHistory[key] ?? 0) + 1;
      _weeklyHistory[key] = _todayCount;
    });

    _saveAll();
    WidgetSyncService.sync(todayCount: _todayCount, status: _liveStatus);
  }

  void _resetSession() {
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionCount = 0;
    });
    _saveAll();
  }

  void _resetLifetime() {
    HapticFeedback.heavyImpact();
    setState(() {
      _lifetimeCount = 0;
    });
    _saveAll();
  }

  void _switchDhikr(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDhikrIndex =
          (_selectedDhikrIndex + delta + _dhikrList.length) % _dhikrList.length;
      _sessionCount = 0;
    });
    _saveAll();
  }

  Color get _bgColor {
    switch (_themeMode) {
      case AppThemeMode.light:
        return const Color(0xFFF8F9FA);
      case AppThemeMode.amoled:
        return const Color(0xFF000000);
      case AppThemeMode.dark:
        return const Color(0xFF0F131A);
    }
  }

  Color get _cardColor {
    switch (_themeMode) {
      case AppThemeMode.light:
        return const Color(0xFFFFFFFF);
      case AppThemeMode.amoled:
        return const Color(0xFF0D0F12);
      case AppThemeMode.dark:
        return const Color(0xFF171D26);
    }
  }

  Color get _primaryText =>
      _themeMode == AppThemeMode.light ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

  Color get _secondaryText =>
      _themeMode == AppThemeMode.light ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  Color get _accentEmerald =>
      _themeMode == AppThemeMode.light ? const Color(0xFF059669) : const Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    final isLight = _themeMode == AppThemeMode.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasbih',
      theme: ThemeData(
        brightness: isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: _bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentEmerald,
          brightness: isLight ? Brightness.light : Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildHomeScreen(),
    );
  }

  // ==========================================================================
  // HOME SCREEN
  // ==========================================================================

  Widget _buildHomeScreen() {
    final currentDhikr = _dhikrList[_selectedDhikrIndex];
    final double progress =
        currentDhikr.target > 0 ? (_sessionCount / currentDhikr.target).clamp(0.0, 1.0) : 0.0;
    final bool isTargetHit = _sessionCount >= currentDhikr.target;

    return Builder(
      builder: (navContext) => Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _incrementCounter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Tasbih',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _primaryText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _liveStatus.isForbidden
                                  ? const Color(0xFFFB7185).withOpacity(0.5)
                                  : _secondaryText.withOpacity(0.18),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_liveStatus.icon} ${_liveStatus.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _liveStatus.isForbidden
                                      ? const Color(0xFFFB7185)
                                      : _accentEmerald,
                                ),
                              ),
                              Text(
                                _liveStatus.hijriFormatted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.of(navContext).push(
                            MaterialPageRoute(
                              builder: (_) => _buildSettingsPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings_rounded, color: _primaryText, size: 26),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _secondaryText.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                currentDhikr.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15 * _fontScale,
                                  fontWeight: FontWeight.w700,
                                  color: _accentEmerald,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentDhikr.arabic,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 30 * _fontScale,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                  color: _primaryText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                currentDhikr.meaning,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5 * _fontScale,
                                  color: _secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _switchDhikr(-1),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.keyboard_arrow_up_rounded,
                                    color: _secondaryText, size: 28),
                              ),
                            ),
                            Text(
                              '${_selectedDhikrIndex + 1}/${_dhikrList.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _secondaryText,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _switchDhikr(1),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.keyboard_arrow_down_rounded,
                                    color: _secondaryText, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 230,
                            height: 230,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: _secondaryText.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isTargetHit ? const Color(0xFFFBBF24) : _accentEmerald,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_sessionCount',
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryText,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isTargetHit
                                    ? 'Target Reached • Tap for 1'
                                    : 'Target: ${currentDhikr.target}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isTargetHit
                                      ? const Color(0xFFFBBF24)
                                      : _secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _resetSession,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _secondaryText.withOpacity(0.18)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 18, color: _secondaryText),
                              const SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _confirmResetTotal(navContext),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _accentEmerald.withOpacity(0.35)),
                          ),
                          child: Text(
                            'Today: $_todayCount  •  Total: $_lifetimeCount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _accentEmerald,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmResetTotal(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('Reset Lifetime Total?', style: TextStyle(color: _primaryText)),
        content: Text(
          'This will reset your lifetime counter ($_lifetimeCount) back to 0.',
          style: TextStyle(color: _secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel', style: TextStyle(color: _secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _resetLifetime();
            },
            child: const Text('Reset', style: TextStyle(color: Color(0xFFFB7185))),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SETTINGS PAGE
  // ==========================================================================

  Widget _buildSettingsPage() {
    return StatefulBuilder(
      builder: (ctx, setModalState) {
        final region = kGlobalRegions[_regionIndex];
        final todaySolar =
            SolarEngine.calculate(SolarEngine.nowInRegion(region), region, _manualTimeOffset);

        void updateSetting(VoidCallback fn) {
          setState(fn);
          setModalState(() {});
          _saveAll();
          _refreshLiveStatusAndWidget();
        }

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor,
            elevation: 0,
            title: Text('Settings',
                style: TextStyle(color: _primaryText, fontWeight: FontWeight.w700)),
            iconTheme: IconThemeData(color: _primaryText),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Dhikr Collection'),
              _settingsCard(
                child: ListTile(
                  leading: Icon(Icons.format_list_bulleted_rounded, color: _accentEmerald),
                  title: Text('Manage Dhikr List (${_dhikrList.length})',
                      style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600)),
                  subtitle: Text('Add, edit, or delete custom Dhikr items',
                      style: TextStyle(color: _secondaryText, fontSize: 12.5)),
                  trailing: Icon(Icons.chevron_right_rounded, color: _secondaryText),
                  onTap: () async {
                    await Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => _buildDhikrManagerPage(),
                      ),
                    );
                    setModalState(() {});
                  },
                ),
              ),

              const SizedBox(height: 18),

              _sectionHeader('Location, Timezone & Solar Sync'),
              _settingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _openRegionPicker(ctx, () {
                          setModalState(() {});
                          _rescheduleNotifications();
                        }),
                        child: Row(
                          children: [
                            Icon(Icons.public_rounded, color: _accentEmerald),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(region.name,
                                      style: TextStyle(
                                          color: _primaryText,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  Text('${region.timezone} (${region.utcLabel})',
                                      style: TextStyle(
                                          color: _secondaryText, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.search_rounded, color: _accentEmerald),
                          ],
                        ),
                      ),
                      const Divider(height: 22),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _accentEmerald.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Sehri Ends: ${SolarEngine.formatMinutes12h(todaySolar.sehriEndMin)}  •  Fajr: ${SolarEngine.formatMinutes12h(todaySolar.fajrStartMin)}',
                              style: TextStyle(
                                  color: _primaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Iftar / Sunset: ${SolarEngine.formatMinutes12h(todaySolar.sunsetMin)}',
                              style: TextStyle(
                                  color: _accentEmerald,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Local Mosque Offset',
                                style: TextStyle(
                                    color: _primaryText, fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _manualTimeOffset > -30
                                    ? () {
                                        updateSetting(() => _manualTimeOffset--);
                                        _rescheduleNotifications();
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                              ),
                              Text(
                                '${_manualTimeOffset >= 0 ? '+' : ''}$_manualTimeOffset min',
                                style: TextStyle(
                                    color: _accentEmerald,
                                    fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                onPressed: _manualTimeOffset < 30
                                    ? () {
                                        updateSetting(() => _manualTimeOffset++);
                                        _rescheduleNotifications();
                                      }
                                    : null,
                                icon: const Icon(Icons.add_circle_outline_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Hijri Moon Sighting',
                                style: TextStyle(
                                    color: _primaryText, fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _hijriDayOffset > -2
                                    ? () => updateSetting(() => _hijriDayOffset--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                              ),
                              Text(
                                '${_hijriDayOffset >= 0 ? '+' : ''}$_hijriDayOffset d',
                                style: TextStyle(
                                    color: _accentEmerald,
                                    fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                onPressed: _hijriDayOffset < 2
                                    ? () => updateSetting(() => _hijriDayOffset++)
                                    : null,
                                icon: const Icon(Icons.add_circle_outline_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _sectionHeader('Smart Notifications'),
              _settingsCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: _accentEmerald,
                      title: Text('Sehri Start Reminder',
                          style: TextStyle(color: _primaryText, fontSize: 14.5)),
                      subtitle: Text('60 mins before Sehri ends',
                          style: TextStyle(color: _secondaryText, fontSize: 12)),
                      value: _notifSehriStart,
                      onChanged: (v) {
                        updateSetting(() => _notifSehriStart = v);
                        _rescheduleNotifications();
                      },
                    ),
                    Divider(height: 1, color: _secondaryText.withOpacity(0.12)),
                    SwitchListTile(
                      activeColor: _accentEmerald,
                      title: Text('Sehri Ending Warning',
                          style: TextStyle(color: _primaryText, fontSize: 14.5)),
                      subtitle: Text('20 mins before Sehri ends',
                          style: TextStyle(color: _secondaryText, fontSize: 12)),
                      value: _notifSehriEnd,
                      onChanged: (v) {
                        updateSetting(() => _notifSehriEnd = v);
                        _rescheduleNotifications();
                      },
                    ),
                    Divider(height: 1, color: _secondaryText.withOpacity(0.12)),
                    SwitchListTile(
                      activeColor: _accentEmerald,
                      title: Text('Iftar / Sunset Alert',
                          style: TextStyle(color: _primaryText, fontSize: 14.5)),
                      subtitle: Text('Exact sunset time in selected timezone',
                          style: TextStyle(color: _secondaryText, fontSize: 12)),
                      value: _notifIftar,
                      onChanged: (v) {
                        updateSetting(() => _notifIftar = v);
                        _rescheduleNotifications();
                      },
                    ),
                    Divider(height: 1, color: _secondaryText.withOpacity(0.12)),
                    SwitchListTile(
                      activeColor: _accentEmerald,
                      title: Text('Forbidden Salah Times',
                          style: TextStyle(color: _primaryText, fontSize: 14.5)),
                      subtitle: Text('Sunrise, Zawwal (Midday) & Sunset alerts',
                          style: TextStyle(color: _secondaryText, fontSize: 12)),
                      value: _notifForbidden,
                      onChanged: (v) {
                        updateSetting(() => _notifForbidden = v);
                        _rescheduleNotifications();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _sectionHeader('Appearance & Font Scaling'),
              _settingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('App Theme',
                          style: TextStyle(
                              color: _primaryText, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _themeChip('Dark', AppThemeMode.dark, updateSetting),
                          const SizedBox(width: 8),
                          _themeChip('Light', AppThemeMode.light, updateSetting),
                          const SizedBox(width: 8),
                          _themeChip('AMOLED', AppThemeMode.amoled, updateSetting),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Arabic & Text Size',
                              style: TextStyle(
                                  color: _primaryText, fontWeight: FontWeight.w600)),
                          Text('${(_fontScale * 100).round()}%',
                              style: TextStyle(
                                  color: _accentEmerald, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Slider(
                        value: _fontScale,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        activeColor: _accentEmerald,
                        onChanged: (v) => updateSetting(() => _fontScale = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _sectionHeader('Last 7 Days Progress'),
              _settingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _build7DayChart(),
                ),
              ),

              const SizedBox(height: 18),

              _sectionHeader('About Tasbih'),
              _settingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _accentEmerald.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _accentEmerald.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '"Verily, in the remembrance of Allah do hearts find rest." (Surah Ar-Ra\'d 13:28)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: _secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Developed by AHM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please remember the developer in your sincere Duas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: _secondaryText),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('https://www.facebook.com/ahm.79316');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: Icon(Icons.open_in_new_rounded,
                            size: 16, color: _accentEmerald),
                        label: Text('Connect on Facebook',
                            style: TextStyle(color: _accentEmerald)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: _secondaryText,
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _secondaryText.withOpacity(0.15)),
      ),
      child: child,
    );
  }

  Widget _themeChip(
      String label, AppThemeMode mode, void Function(VoidCallback) updateSetting) {
    final selected = _themeMode == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => updateSetting(() => _themeMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accentEmerald : _bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _accentEmerald : _secondaryText.withOpacity(0.25),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : _primaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _build7DayChart() {
    final now = DateTime.now();
    final List<DateTime> days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    int maxVal = 10;
    for (final d in days) {
      final count = _weeklyHistory[DateFormat('yyyy-MM-dd').format(d)] ?? 0;
      if (count > maxVal) maxVal = count;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((d) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        final count = _weeklyHistory[key] ?? 0;
        final double barHeight = (count / maxVal * 70).clamp(6.0, 70.0);
        final bool isToday = key == _todayKey();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isToday ? _accentEmerald : _secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: barHeight,
              decoration: BoxDecoration(
                color: isToday ? _accentEmerald : _accentEmerald.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('E').format(d),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? _primaryText : _secondaryText,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ==========================================================================
  // SEARCHABLE COUNTRY / CITY / TIMEZONE PICKER
  // ==========================================================================

  void _openRegionPicker(BuildContext ctx, VoidCallback onSelected) {
    String query = '';
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final filtered = kGlobalRegions
              .asMap()
              .entries
              .where((entry) =>
                  entry.value.name.toLowerCase().contains(query.toLowerCase()) ||
                  entry.value.timezone.toLowerCase().contains(query.toLowerCase()))
              .toList();

          return SizedBox(
            height: MediaQuery.of(sheetCtx).size.height * 0.78,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _secondaryText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    autofocus: true,
                    style: TextStyle(color: _primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search Makkah, Madinah, Dhaka, Kolkata, London...',
                      hintStyle: TextStyle(color: _secondaryText, fontSize: 13.5),
                      prefixIcon: Icon(Icons.search_rounded, color: _accentEmerald),
                      filled: true,
                      fillColor: _bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setSheetState(() => query = val),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: _secondaryText.withOpacity(0.1)),
                    itemBuilder: (_, idx) {
                      final entry = filtered[idx];
                      final isSelected = entry.key == _regionIndex;
                      return ListTile(
                        title: Text(
                          entry.value.name,
                          style: TextStyle(
                            color: isSelected ? _accentEmerald : _primaryText,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${entry.value.timezone} • ${entry.value.utcLabel}',
                          style: TextStyle(color: _secondaryText, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: _accentEmerald)
                            : null,
                        onTap: () {
                          setState(() {
                            _regionIndex = entry.key;
                          });
                          _saveAll();
                          _refreshLiveStatusAndWidget();
                          Navigator.pop(sheetCtx);
                          onSelected();
                        },
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

  // ==========================================================================
  // DHIKR COLLECTION MANAGER
  // ==========================================================================

  Widget _buildDhikrManagerPage() {
    return StatefulBuilder(
      builder: (ctx, setMgrState) {
        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor,
            elevation: 0,
            title: Text('Dhikr Collection',
                style: TextStyle(color: _primaryText, fontWeight: FontWeight.w700)),
            iconTheme: IconThemeData(color: _primaryText),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _accentEmerald,
            foregroundColor: Colors.black,
            onPressed: () => _openDhikrEditor(ctx, null, () => setMgrState(() {})),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Dhikr', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: _dhikrList.length,
            itemBuilder: (_, idx) {
              final item = _dhikrList[idx];
              final isSelected = idx == _selectedDhikrIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _accentEmerald
                        : _secondaryText.withOpacity(0.15),
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedDhikrIndex = idx;
                      _sessionCount = 0;
                    });
                    _saveAll();
                    Navigator.pop(ctx);
                  },
                  title: Text(
                    '${item.title} (Target: ${item.target})',
                    style: TextStyle(
                      color: isSelected ? _accentEmerald : _primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        item.arabic,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                            color: _primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.meaning,
                        style: TextStyle(color: _secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_rounded, color: _secondaryText, size: 20),
                        onPressed: () =>
                            _openDhikrEditor(ctx, idx, () => setMgrState(() {})),
                      ),
                      if (_dhikrList.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFFB7185), size: 20),
                          onPressed: () {
                            showDialog(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: _cardColor,
                                title: Text('Delete Dhikr?',
                                    style: TextStyle(color: _primaryText)),
                                content: Text(
                                  'Are you sure you want to delete "${item.title}"?',
                                  style: TextStyle(color: _secondaryText),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: Text('Cancel',
                                        style: TextStyle(color: _secondaryText)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dCtx);
                                      setState(() {
                                        _dhikrList.removeAt(idx);
                                        if (_selectedDhikrIndex >= _dhikrList.length) {
                                          _selectedDhikrIndex = _dhikrList.length - 1;
                                        }
                                      });
                                      setMgrState(() {});
                                      _saveAll();
                                    },
                                    child: const Text('Delete',
                                        style: TextStyle(color: Color(0xFFFB7185))),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openDhikrEditor(BuildContext ctx, int? editIndex, VoidCallback onSaved) {
    final existing = editIndex != null ? _dhikrList[editIndex] : null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final arabicCtrl = TextEditingController(text: existing?.arabic ?? '');
    final meaningCtrl = TextEditingController(text: existing?.meaning ?? '');
    final targetCtrl =
        TextEditingController(text: (existing?.target ?? 33).toString());

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(existing == null ? 'Add New Dhikr' : 'Edit Dhikr',
            style: TextStyle(color: _primaryText)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: _primaryText),
                decoration: const InputDecoration(labelText: 'Title (e.g., SubhanAllah)'),
              ),
              TextField(
                controller: arabicCtrl,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: _primaryText, fontSize: 20),
                decoration: const InputDecoration(labelText: 'Arabic Text'),
              ),
              TextField(
                controller: meaningCtrl,
                style: TextStyle(color: _primaryText),
                decoration: const InputDecoration(labelText: 'English Meaning'),
              ),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _primaryText),
                decoration: const InputDecoration(labelText: 'Target Count (e.g., 33, 100)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel', style: TextStyle(color: _secondaryText)),
          ),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final arabic = arabicCtrl.text.trim();
              if (title.isEmpty || arabic.isEmpty) return;

              final target = int.tryParse(targetCtrl.text.trim()) ?? 33;
              setState(() {
                if (existing == null) {
                  _dhikrList.add(DhikrItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    arabic: arabic,
                    meaning: meaningCtrl.text.trim(),
                    target: target > 0 ? target : 33,
                  ));
                } else {
                  _dhikrList[editIndex!] = DhikrItem(
                    id: existing.id,
                    title: title,
                    arabic: arabic,
                    meaning: meaningCtrl.text.trim(),
                    target: target > 0 ? target : 33,
                  );
                }
              });
              _saveAll();
              Navigator.pop(dCtx);
              onSaved();
            },
            child: Text('Save', style: TextStyle(color: _accentEmerald)),
          ),
        ],
      ),
    );
  }
}
