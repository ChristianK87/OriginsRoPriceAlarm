

import 'package:flutter/material.dart';
import 'package:price_alarm/pricealarm/price_alarm.dart';
import 'package:price_alarm/originro/originro.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  var initializationSettingsAndroid =
  new AndroidInitializationSettings('@mipmap/notification');
  var initializationSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: onSelectNotification);
  Timer.periodic(Duration(minutes: 6), (Timer t)  => callbackDispatcher());
  runApp(MyApp());
}


Future onSelectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: ' + payload);
  }
}

Future onDidReceiveLocalNotification(int id, String title, String body, String payload) {
  return Future.value(true);
}

callbackDispatcher() async {
    var priceAlarmRepository = new PriceAlarmRepository();
    List<PriceAlarm> priceAlarms = await priceAlarmRepository.priceAlarms();
    Market market = await new OriginRoService().getMarket();
    List<Item> items = new List();
    market.shops.forEach((Shop shop) => items.addAll(shop.items));
    priceAlarms.forEach((PriceAlarm priceAlarm){
      priceAlarm.found = items.firstWhere((Item item) => item.itemId == priceAlarm.id && item.price <= priceAlarm.price, orElse: ()=> null)!= null;
      if(priceAlarm.found){
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(
            0, 'Found item', 'An Item on your wishlist is on sale', platformChannelSpecifics,
            payload: '');
      }
      priceAlarmRepository.updatePriceAlarm(priceAlarm);
    });

    //Return true when the task executed successfully or not
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Price Alarm',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Price Alarm'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return PriceAlarmWidget();
  }
}


