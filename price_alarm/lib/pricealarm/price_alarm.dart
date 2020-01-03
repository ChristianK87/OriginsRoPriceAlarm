import 'package:flutter/material.dart';
import 'package:price_alarm/settings/settings.dart';
import 'package:price_alarm/pricealarm/price_alarm_data.dart';
import 'package:price_alarm/originro/originro.dart';
import 'package:price_alarm/shared.dart';
import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';

class PriceAlarmState extends State<PriceAlarmWidget> {
  BuildContext context;
  var _priceAlarms = List<PriceAlarm>();
  List<MarketItem> items = new List();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var service = new PriceAlarmService();

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
    setState(() {});
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {
    return Future.value(true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(
        BackgroundFetchConfig(
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
    items = new List();
    market.shops.forEach((Shop shop) => items.addAll(shop.items));
    updatePriceAlarms(priceAlarms);

    //Return true when the task executed successfully or not
  }

  void updatePriceAlarms(List<PriceAlarm> priceAlarms) {
    var priceAlarmRepository = new PriceAlarmRepository();

    priceAlarms.forEach((PriceAlarm priceAlarm) {
      service.updatePriceAlarmState(items, priceAlarm);
      if (priceAlarm.found) {
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.Max,
            priority: Priority.High,
            ticker: 'ticker');
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(0, 'Found item',
            'An Item on your wishlist is on sale', platformChannelSpecifics,
            payload: '');
      }
      priceAlarmRepository.updatePriceAlarm(priceAlarm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PriceAlarm>>(
      future: new PriceAlarmService().getPriceAlarms(),
      builder:
          (BuildContext context, AsyncSnapshot<List<PriceAlarm>> snapshot) {
        if (snapshot.hasData) {
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
    Navigator.of(context).push(MaterialPageRoute<void>(
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
    Navigator.of(context).push(MaterialPageRoute<void>(
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

  removeEntry(PriceAlarm priceAlarm) {
    new PriceAlarmService().removePriceAlarm(priceAlarm);
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: this._priceAlarms.length,
        itemBuilder: /*1*/ (context, i) {
          return _buildRow(_priceAlarms.elementAt(i));
        });
  }

  Widget _buildRow(PriceAlarm priceAlarm) {
    service.updatePriceAlarmState(items, priceAlarm);
    String priceAlarmSubtitle =
        '${Shared.intToStringWithSeparator(priceAlarm.price)} Zeny';
    if (priceAlarm.cards != null && priceAlarm.cards.length > 0) {
      var cards = priceAlarm.cards
          .map((PriceAlarmCard card) => '[${card.name}]')
          .join("\n");
      priceAlarmSubtitle = '$cards \n $priceAlarmSubtitle';
    }
    return Container(
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(10.0),
            color: priceAlarm.found ? Colors.lightGreenAccent : Colors.white,
            boxShadow: [
              new BoxShadow(
                  color: Colors.grey,
                  offset: new Offset(2.0, 2.0),
                  blurRadius: 2.0,
                  spreadRadius: 2.0)
            ]),
        child: ListTile(
          title: Text(
            priceAlarm.name,
            style: TextStyle(fontSize: 18.0),
          ),
          subtitle: Text(
            priceAlarmSubtitle,
            style: TextStyle(fontSize: 16.0),
          ),
          isThreeLine: true,
          leading: priceAlarm.icon != null
              ? Image.memory(base64Decode(priceAlarm.icon))
              : null,
          trailing: IconButton(
            icon: Icon(
              Icons.delete,
            ),
            onPressed: () {
              setState(() {
                removeEntry(priceAlarm);
              });
            },
          ),
        ));
  }
}

class PriceAlarmWidget extends StatefulWidget {
  @override
  PriceAlarmState createState() => PriceAlarmState();
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
  bool isRefinable = false;
  List<Item> cards = new List();
  final newPriceAlarm = new PriceAlarm();

  int maxCards = 0;

  final TextEditingController _typeAheadController = TextEditingController();
  final TextEditingController cardsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                      autofocus: true,
                      controller: _typeAheadController,
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(fontStyle: FontStyle.italic),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(), labelText: 'Item')),
                  suggestionsCallback: (pattern) async {
                    return await new ItemRepository().items(pattern);
                  },
                  itemBuilder: (context, Item suggestion) {
                    return ListTile(
                      leading: suggestion.icon != null
                          ? Image.memory(base64Decode(suggestion.icon))
                          : null,
                      title: Text(suggestion.toString()),
                      subtitle: Text(suggestion.itemId),
                    );
                  },
                  onSuggestionSelected: (Item suggestion) {
                    newPriceAlarm.itemId = suggestion.itemId;
                    newPriceAlarm.name = suggestion.toString();
                    newPriceAlarm.icon = suggestion.icon;
                    cards = new List();
                    _typeAheadController.text = suggestion.toString();
                    setState(() {
                      isRefinable = suggestion.type == "IT_WEAPON" ||
                          suggestion.type == "IT_ARMOR";
                      maxCards =
                          suggestion.slots != null ? suggestion.slots : 0;
                    });
                  },
                ),
                isRefinable
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Container(
                          width: 130.0,
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                                labelText: 'Refinerate',
                                border: OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15.0)),
                            value: newPriceAlarm.refinement,
                            icon: null,
                            iconSize: 24,
                            elevation: 10,
                            isDense: true,
                            style: TextStyle(
                                fontSize: 18.0, color: Colors.black87),
                            onChanged: (int newValue) {
                              setState(() {
                                newPriceAlarm.refinement = newValue;
                              });
                            },
                            onSaved: (val) => newPriceAlarm.refinement = val,
                            items: <int>[-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                                .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  value == -1 ? 'any' : '+$value',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              );
                            }).toList(),
                          ),
                        ))
                    : SizedBox(),
                maxCards > 0
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: this.cards.length,
                        shrinkWrap: true,
                        itemBuilder: /*1*/ (context, i) {
                          var card = this.cards.elementAt(i);
                          return Container(
                            margin: const EdgeInsets.all(5.0),
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white,
                                boxShadow: [
                                  new BoxShadow(
                                      color: Colors.grey,
                                      offset: new Offset(2.0, 2.0),
                                      blurRadius: 2.0,
                                      spreadRadius: 2.0)
                                ]),
                            child: ListTile(
                                title: Text(
                                  card.toString(),
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                trailing: ButtonBar(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                        Icons.content_copy,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (cards.length < maxCards) {
                                            cards.add(card);
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            cards.removeAt(i);
                                          });
                                        }),
                                  ],
                                )),
                          );
                        })
                    : SizedBox(),
                maxCards > 0
                    ? TypeAheadField(
                        textFieldConfiguration: TextFieldConfiguration(
                            autofocus: true,
                            controller: cardsController,
                            style: DefaultTextStyle.of(context)
                                .style
                                .copyWith(fontStyle: FontStyle.italic),
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Card')),
                        autoFlipDirection: true,
                        suggestionsCallback: (pattern) async {
                          return await new ItemRepository().cards(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion.toString()),
                            subtitle: Text(suggestion.itemId),
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            if (cards.length < maxCards) {
                              cards.add(suggestion);
                            }
                          });
                        },
                      )
                    : SizedBox(),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.attach_money),
                    hintText: 'Enter the pricelimit',
                    labelText: 'Price',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter a price';
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
                        setState(() async {
                          newPriceAlarm.name = newPriceAlarm.refinement == -1
                              ? newPriceAlarm.name
                              : '+${newPriceAlarm.refinement} ${newPriceAlarm.name}';
                          newPriceAlarm.found = false;
                          newPriceAlarm.cards = cards
                              .map((Item card) => new PriceAlarmCard(
                                  1,
                                  newPriceAlarm.id,
                                  card.itemId,
                                  card.toString()))
                              .toList();
                          var priceAlarmService = new PriceAlarmService();
                          await priceAlarmService
                              .insertPriceAlarm(newPriceAlarm);
                          Scaffold.of(context).showSnackBar(
                              SnackBar(content: Text('Processing Data')));
                          Navigator.pop(context);
                        });
                      }
                    },
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
