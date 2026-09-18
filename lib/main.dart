  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // অ্যান্ড্রয়েড ১৩+ এ স্ক্রিনে পারমিশন ডায়ালগ শো করানো
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    // নোটিফিকেশন চ্যানেল তৈরি
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_alerts_critical',
      'Prayer & Sehri Alerts',
      description: 'Alerts for Sehri, Iftar and Forbidden times',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation?.createNotificationChannel(channel);
  }
