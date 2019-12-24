import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo 2',
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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

class PriceAlarmState extends State<PriceAlarmWidget> {

  final _priceAlarams = <PriceAlarm>[];
  final _biggerFont = const TextStyle(fontSize: 18.0);


  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider(); /*2*/

          final index = i ~/ 2; /*3*/
          if (index >= _priceAlarams.length) {
            _priceAlarams.add(new PriceAlarm(Random.secure().nextInt(10000).toString(),Random.secure().nextDouble())); /*4*/
          }
          return _buildRow(_priceAlarams[index]);
        });
  }

  Widget _buildRow(PriceAlarm priceAlarm) {
    return ListTile(
      title: Text(
        priceAlarm.getId() + ' - '+ priceAlarm.getPrice().toString(),
        style: _biggerFont,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
      ),
      body: _buildSuggestions(),
    );
  }
}

class PriceAlarmWidget extends StatefulWidget {
  @override
  PriceAlarmState createState() => PriceAlarmState();
}

class PriceAlarm {
  String _id;
  double _price;

  PriceAlarm(this._id, this._price);

  getId(){
    return _id;
  }
  setId(String id){
    this._id = id;
  }

  getPrice(){
    return _price;
  }
  setPrice(double price){
    this._price = price;
  }
}
