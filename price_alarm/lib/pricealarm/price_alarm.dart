import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:price_alarm/settings/settings.dart';
import 'package:price_alarm/originro/originro.dart';
import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:price_alarm/shared.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';

class PriceAlarmState extends State<PriceAlarmWidget> {
  BuildContext context;
  var _priceAlarms = List<PriceAlarm>();
  List<MarketItem> items = new List();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
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
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    initPlatformState();
  }

  void backgroundFetchHeadlessTask() async {
    print('[BackgroundFetch] Headless event received.');
    await checkMarket();
    BackgroundFetch.finish();
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
    setState(() {

    });
  }

  Future onDidReceiveLocalNotification(int id, String title, String body, String payload) {
    return Future.value(true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: false,
    ), () async {
      // This is the fetch-event callback.
      setState(() async {
        await checkMarket();
      });
      // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish();
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  checkMarket() async {
    var priceAlarmRepository = new PriceAlarmRepository();
    List<PriceAlarm> priceAlarms = await priceAlarmRepository.priceAlarms();
    Market market = await new OriginRoService().getMarket();
    List<MarketItem> items = new List();
    market.shops.forEach((Shop shop) => items.addAll(shop.items));
    priceAlarms.forEach((PriceAlarm priceAlarm){
      priceAlarm.found = items.firstWhere((MarketItem item) => item.itemId == priceAlarm.id && item.price <= priceAlarm.price, orElse: ()=> null)!= null;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PriceAlarm>>(
      future: new PriceAlarmRepository().priceAlarms(),
      builder: (BuildContext context, AsyncSnapshot<List<PriceAlarm>> snapshot){
        if(snapshot.hasData){
          this.context = context;
          this._priceAlarms = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              title: Text('Your watched items'),
              actions: <Widget>[
                IconButton(icon: Icon(Icons.settings), onPressed: _settings),
                IconButton(icon: Icon(Icons.add), onPressed: _pushNewEntry),
              ],
            ),
            body: _buildSuggestions(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('Your watched items'),
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
      },
    );
  }

  void _pushNewEntry() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Add new item'),
              ),
              body: new PriceAlarmForm(),
            );
          },
        ));
  }

  void _settings() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Settings'),
              ),
              body: new SettingsForm(),
            );
          },
        ));
  }

  removeEntry(id) {
    new PriceAlarmRepository().removeEntry(id);
  }

  Widget _buildSuggestions()  {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: this._priceAlarms.length,
        itemBuilder: /*1*/ (context, i) {
          return _buildRow(_priceAlarms.elementAt(i));
        });
  }

  Widget _buildRow(PriceAlarm priceAlarm) {
    return Container(
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10.0),
          color: priceAlarm.found ? Colors.lightGreenAccent: Colors.white,
          boxShadow: [
            new BoxShadow(
                color: Colors.grey,
                offset: new Offset(2.0, 2.0),
                blurRadius: 2.0,
                spreadRadius: 2.0
            )
          ]
        ),
    child: ListTile(
      title: Text(
        priceAlarm.name,
        style: TextStyle(fontSize: 18.0),
      ),
      subtitle:
      Text(
        '${Shared.intToStringWithSeparator(priceAlarm.price)} Zeny',
        style: TextStyle(fontSize: 16.0),
      ),
      leading:  priceAlarm.icon != null ? Image.memory(base64Decode(priceAlarm.icon)): null
      ,
      trailing: IconButton(
        icon: Icon(
          Icons.delete,
        ),
        onPressed: () {
          setState(() {
            removeEntry(priceAlarm.id);
          });
        },
      ),
    )
    );
  }

}

class PriceAlarmWidget extends StatefulWidget {
  @override
  PriceAlarmState createState() => PriceAlarmState();
}

class PriceAlarm {
  String id;
  int price;
  bool found;
  String name;
  String icon;

  PriceAlarm();

  PriceAlarm.withIdAndPrice(this.id, this.price, this.found, this.name, this.icon);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'price': price,
      'found': found,
      'name': name,
      'icon': icon,
    };
  }
}

// Define a custom Form widget.
class PriceAlarmForm extends StatefulWidget {

  PriceAlarmForm();

  @override
  PriceAlarmFormState createState() {
    return PriceAlarmFormState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class PriceAlarmFormState extends State<PriceAlarmForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  final newPriceAlarm = new PriceAlarm();

  final TextEditingController _typeAheadController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypeAheadField(
            textFieldConfiguration: TextFieldConfiguration(
                autofocus: true,
                controller: _typeAheadController,
                style: DefaultTextStyle.of(context).style.copyWith(
                    fontStyle: FontStyle.italic
                ),
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  labelText: 'Item'
                )
            ),
            suggestionsCallback: (pattern) async {
              return await new ItemRepository().items(pattern);
            },
            itemBuilder: (context, Item suggestion) {
              return ListTile(
                leading: suggestion.icon != null ? Image.memory(base64Decode(suggestion.icon)) : null,
                title: Text(suggestion.toString()),
                subtitle: Text(suggestion.itemId),
              );
            },
            onSuggestionSelected: (Item suggestion) {
              newPriceAlarm.id = suggestion.itemId;
              newPriceAlarm.name = suggestion.toString();
              newPriceAlarm.icon = suggestion.icon;
              _typeAheadController.text = suggestion.toString();
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              icon: const Icon(Icons.attach_money),
              hintText: 'Enter the pricelimit',
              labelText: 'Price',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
            onSaved: (val) => newPriceAlarm.price = int.tryParse(val),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: () async {
                // Validate returns true if the form is valid, or false
                // otherwise.
                final FormState form = _formKey.currentState;
                if (form.validate()) {
                  // If the form is valid, display a Snackbar.
                  form.save();
                  newPriceAlarm.found = false;
                  var priceAlarmService = new PriceAlarmRepository();
                  await priceAlarmService.insertPriceAlarm(newPriceAlarm);
                  Scaffold.of(context)
                      .showSnackBar(SnackBar(content: Text('Processing Data')));
                  Navigator.pop(context);
                }
              },
              child: Text('Submit'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class PriceAlarmRepository{

  Future<void> insertPriceAlarm(PriceAlarm priceAlarm) async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'price_alarm',
      priceAlarm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PriceAlarm>> priceAlarms() async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('price_alarm');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return PriceAlarm.withIdAndPrice(
        maps[i]['id'],
        maps[i]['price'],
        maps[i]['found'] == 1,
        maps[i]['name'],
        maps[i]['icon'],
      );
    });
  }

  Future<void> removeEntry(id) async {
    final db = await Shared.getDatabase();

    await db.delete(
      'price_alarm',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  void updatePriceAlarm(PriceAlarm priceAlarm) async {
    final db = await Shared.getDatabase();

    await db.update(
      'price_alarm',
      priceAlarm.toMap(),
      where: "id = ?",
      whereArgs: [priceAlarm.id],
    );
  }
}