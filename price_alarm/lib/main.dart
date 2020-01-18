

import 'package:flutter/material.dart';
import 'package:price_alarm/pricealarm/price_alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:price_alarm/settings/settings.dart';
import 'package:workmanager/workmanager.dart';
import 'package:price_alarm/pricealarm/price_alarm_data.dart';
import 'package:price_alarm/originro/originro.dart';

void backgroundFetchHeadlessTask() {
  Workmanager.executeTask((task, inputData) async {
    var settings = await new SettingsService().getSettings();
    if(settings.apiKey == null || settings.apiKey == ''){
      return true;
    }
    var service = new PriceAlarmService();
    var pricealarmRepository = new PriceAlarmRepository();
    List<PriceAlarm> priceAlarms = await service.getPriceAlarms();

    Market market =  await new OriginRoService().getMarket();
    List<MarketItem> items = new List<MarketItem>();
    market.shops.where((Shop shop) => shop.type == ShopType.V).forEach((Shop shop) => items.addAll(shop.items));

    await Future.forEach(priceAlarms,(PriceAlarm priceAlarm) async {
      var oldFound = priceAlarm.found;
      service.updatePriceAlarmState(items, priceAlarm);
      await pricealarmRepository.updatePriceAlarm(priceAlarm);
      if (priceAlarm.found && !oldFound) {
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.Max,
            priority: Priority.High,
            ticker: 'ticker');
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(0, 'Found item',
            'An item on your wishlist is on sale', platformChannelSpecifics,
            payload: priceAlarm.id.toString());
      }
    });
    return Future.value(true);
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager.initialize(
      backgroundFetchHeadlessTask, // The top level function, aka callbackDispatcher
      isInDebugMode: false // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );
  Workmanager.registerPeriodicTask("1", "checkMarket", frequency: Duration(minutes: 15), inputData: null);
  runApp(MyApp());

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
    return FutureBuilder<Settings>(
      future: new SettingsService().getSettings(),
      builder: (BuildContext context, AsyncSnapshot<Settings> snapshot){
        if(snapshot.hasData){
          if(snapshot.data.apiKey != null){
            return PriceAlarmWidget();
          }else{
            return Scaffold(
                appBar: AppBar(
                title: Text('Settings'),
            ),
              body: new SettingsForm(),
            );
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('oRO Price Alarm'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Awaiting result...'),
              )
            ],
          ),
        );
    });

  }
}


