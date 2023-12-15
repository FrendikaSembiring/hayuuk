import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String text = 'Stop Service';



  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Countdown Service'),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder(
              stream: FlutterBackgroundService().on('update'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(
                    '60 s',
                    style: TextStyle(fontSize: 40),
                  );
                }
                final data = snapshot.data!;
                String? count = data['count'].toString() + ' s';
                return Text(
                  count,
                  style: TextStyle(fontSize: 40),
                );
              }),
          ElevatedButton(onPressed: () async{
            final service = FlutterBackgroundService();
            var isRunning = await service.isRunning();
            if (isRunning) {
              service.invoke('stopService');
              text = 'Restart Service';
            } else {
              service.startService();
              text = 'Stop Service';
            }
            setState(() {
              
            });
          }, child: Text(text))
        ],
      )),
    );
  }
}
