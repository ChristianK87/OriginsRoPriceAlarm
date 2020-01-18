import 'package:flutter/material.dart';
import 'package:price_alarm/pricealarm/shops.dart';
import 'package:price_alarm/settings/settings.dart';
import 'package:price_alarm/pricealarm/price_alarm_data.dart';
import 'package:price_alarm/originro/originro.dart';
import 'package:price_alarm/shared.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class PriceAlarmState extends State<PriceAlarmWidget> {
  BuildContext context;
  var _priceAlarms = List<PriceAlarm>();
  Market market;
  int priceAlarmId;
  var service = new PriceAlarmService();
  PriceAlarmRepository priceAlarmRepository = new PriceAlarmRepository();

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@mipmap/notification');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    // method is called 2 times, don't know why
    if (payload != null && int.parse(payload) != priceAlarmId) {
      priceAlarmId = int.parse(payload);
      this.market = await new OriginRoService().getMarket();
      var priceAlarm = await priceAlarmRepository.findById(priceAlarmId);
      showShops(priceAlarm);
      debugPrint('notification payload: ' + payload);
    }
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {
    return Future.value(true);
  }

  checkMarket() async {
    var priceAlarmRepository = new PriceAlarmService();
    List<PriceAlarm> priceAlarms = await priceAlarmRepository.getPriceAlarms();
    try {
      market = await new OriginRoService().getMarket();
      updatePriceAlarms(priceAlarms);
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 10),
          content: Text(
            e.toString(),
            style: TextStyle(color: Colors.redAccent),
          )));
    }
  }

  void updatePriceAlarms(List<PriceAlarm> priceAlarms) {
    List<MarketItem> items = new List<MarketItem>();
    market.shops.where((Shop shop) => shop.type == ShopType.V).forEach((Shop shop) => items.addAll(shop.items));
    var priceAlarmRepository = new PriceAlarmRepository();

    priceAlarms.forEach((PriceAlarm priceAlarm) {
      var oldFound = priceAlarm.found;
      service.updatePriceAlarmState(items, priceAlarm);
      if (!oldFound && priceAlarm.found) {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Found item')));
      }
      priceAlarmRepository.updatePriceAlarm(priceAlarm);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Text('Your watched items'),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    checkMarket();
                  });
                }),
            IconButton(icon: Icon(Icons.settings), onPressed: _settings),
            IconButton(icon: Icon(Icons.add), onPressed: _pushNewEntry),
          ],
        ),
        body: FutureBuilder<List<PriceAlarm>>(
            future: new PriceAlarmService().getPriceAlarms(),
            builder: (BuildContext context,
                AsyncSnapshot<List<PriceAlarm>> snapshot) {
              if (snapshot.hasData) {
                this.context = context;
                this._priceAlarms = snapshot.data;
                return _buildSuggestions();
              }
              return Column(
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
              );
            }));
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

  void showShops(PriceAlarm priceAlarm) {
    if(market == null){
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('Market not loaded')));
    }else{
      List<Shop> shops = market.shops.where((Shop shop) => shop.type == ShopType.V).where((Shop shop) => service.findCheapestPriceAlarmInShop(shop.items, priceAlarm) != null).toList();
      shops.sort((Shop a, Shop b) => service.findCheapestPriceAlarmInShop(a.items, priceAlarm).price.compareTo(service.findCheapestPriceAlarmInShop(b.items, priceAlarm).price));
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(priceAlarm.name),
            ),
            body: new ShopsWidget(shops, priceAlarm),
          );
        },
      ));
    }
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
    if(market != null) {
      List<MarketItem> items = new List();
      market.shops.forEach((Shop shop) => items.addAll(shop.items));
      service.updatePriceAlarmState(items, priceAlarm);
    }
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
          onTap: () => showShops(priceAlarm),
        ));
  }
}

class PriceAlarmWidget extends StatefulWidget {
  PriceAlarmWidget();


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
