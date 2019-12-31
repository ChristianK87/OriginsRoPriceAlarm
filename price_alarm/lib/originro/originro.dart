import 'dart:convert';

import 'package:price_alarm/settings/settings.dart';
import 'package:price_alarm/shared.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

const String ApiBaseUrl = 'https://api.originsro.org/api/v1/';

class OriginRoService{
  Future<Market> getMarket() async {
    var settings = await new SettingsService().getSettings();
    http.Response response = await http.get(ApiBaseUrl+ 'market/list', headers: {'x-api-key':settings.apiKey});
    if(response.statusCode == 200){
      return Market.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Failed to get markets');
    }
  }

  syncItems() async {
    var settings = await new SettingsService().getSettings();
    http.Response response = await http.get(ApiBaseUrl+ 'items/list', headers: {'x-api-key':settings.apiKey});
    if(response.statusCode == 200){
      var itemRepo = new ItemRepository();
      var items = (jsonDecode(response.body)['items'] as List<dynamic>).map((dynamic item) =>Item.fromJson(item)).toList();
      await itemRepo.insertItems(items);
    }else{
      throw Exception('Failed to get markets');
    }
  }
}

class ItemRepository{

  Future<void> insertItem(Item item) async {
    final Database db = await Shared.getDatabase();

    await db.insert(
      'item',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  insertItems(List<Item> items) async {
    final Database db = await Shared.getDatabase();
    db.transaction((Transaction txn) async{
      items.forEach((Item item){
        txn.insert(
          'item',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    });
  }

  Future<List<Item>> items(String pattern) async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();
    List<Map<String, dynamic>> maps;
    if(pattern == null || pattern.isEmpty){
      maps = await db.query('item');
    }else{
      maps = await db.query('item', where: "name LIKE '%"+ pattern +"%'");
    }

    return List.generate(maps.length, (i) {
      return Item(
        maps[i]['id'],
        maps[i]['uniqueName'],
        maps[i]['name'],
        maps[i]['type'],
        maps[i]['npcPrice'],
        maps[i]['subtype'],
        maps[i]['slots'],
      );
    });
  }

  Future<void> removeItem(id) async {
    final db = await Shared.getDatabase();

    await db.delete(
      'item',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  void updateItem(Item item) async {
    final db = await Shared.getDatabase();

    await db.update(
      'item',
      item.toMap(),
      where: "id = ?",
      whereArgs: [item.itemId],
    );
  }

}

class Market{

  List<Shop> shops;
  Market(this.shops);

  factory Market.fromJson(Map<String, dynamic> json){
    List<dynamic> shopsJson =  json['shops'];
    var shops = shopsJson.map((dynamic item) => Shop.fromJson(item),
    ).toList();
    return Market(shops);
  }
}

class Shop{
  String title;
  String owner;
  Location location;
  DateTime creationDate;
  String type;
  List<MarketItem> items;

  Shop(this.title, this.owner, this.location, this.creationDate, this.type,
      this.items);

  factory  Shop.fromJson(Map<String, dynamic> json) {
    var location = Location.fromJson(json['location']);
    var items = (json['items'] as List<dynamic>).map((dynamic item) => MarketItem.fromJson(item)).toList();
    return Shop(
      json['title'],
      json['owner'],
      location,
      json['creationDate'],
      json['type'],
      items
    );
  }
}

class Location{
  String map;
  int x;
  int y;

  Location(this.map, this.x, this.y);

  factory  Location.fromJson(Map<String, dynamic> json) {
    return Location(
        json['map'],
        json['x'],
        json['y']
    );
  }
}

class MarketItem{
  String itemId;
  int amount;
  int price;
  int refine;
  List<dynamic> cards;
  String element;
  int starCrumbs;
  int creator;

  MarketItem(this.itemId, this.amount, this.price, this.refine, this.cards,
      this.element, this.starCrumbs, this.creator);

  factory  MarketItem.fromJson(Map<String, dynamic> json) {
    List<dynamic> cards = (json['cards'] as List<dynamic>);

    return MarketItem(
      (json['item_id'] as int).toString(),
        json['amount'],
        json['price'],
        json['refine'],
        cards,
        json['element'],
        json['star_crumbs'],
        json['creator'],
    );
  }
}

class Item{
  String itemId;
  String uniqueName;
  String name;
  String type;
  String subtype;
  int npcPrice;
  int slots;

  Item(this.itemId, this.uniqueName, this.name, this.type, this.npcPrice, this.subtype, this.slots);

  factory  Item.fromJson(Map<String, dynamic> json) {
    return Item(
      (json['item_id'] as int).toString(),
      json['unique_name'],
      json['name'],
      json['type'],
      json['npc_price'],
      json['subtype'],
      json['slots'],
    );
  }

  toString(){
    return subtype != null ? '$name [$slots]':'$name';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': itemId,
      'uniqueName': uniqueName,
      'name': name,
      'type': type,
      'npcPrice': npcPrice,
      'subtype': subtype,
      'slots': slots,
    };
  }
}