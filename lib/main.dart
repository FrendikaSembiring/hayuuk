import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:minggu12/home.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

String text = 'Stop Service';

@pragma('vm:entry-point')
Future<bool> onIosbackground(ServiceInstance service) async {
  return true;
}

void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  int sum = 60;
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    sum--;
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
            888,
            'Countdown Service',
            'remaining ${sum} times ...',
            const NotificationDetails(
                android: AndroidNotificationDetails(
                    'foreground', 'Foreground Service',
                    icon: 'ic_bg_service_small', ongoing: true)));
      }
    }
    print('Background Service: ${sum}');

    service.invoke('update', {
      'count': sum,
    });
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'foreground',
        initialNotificationTitle: 'Foreground Service',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosbackground,
      ));
  service.startService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'foreground', 'Foreground Service',
      description: 'This channel is used for important notifications.',
      importance: Importance.low);
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void backgroundCompute(args) {
    print('background compute callback');
    print('calculating fibonacci from a background process');

    int first = 0;
    int second = 1;

    for (var i = 2; i <= 50; i++) {
      var temp = second;
      second = first + second;
      first = temp;
      sleep(Duration(milliseconds: 200));
      print('first: $first, second: $second');
    }
    print('finished calculating fibo');
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
      /* Scaffold(body: Center(child: ElevatedButton(onPressed: () {
        compute(backgroundCompute, null);
      }, child: Text('Calculate fibo on compute isolate')),),) */
    );
  }
}
