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
      var text = 'Failed to get markets';
      if(response.statusCode == 401){
        text = 'Invalid API Key';
      }
      if(response.statusCode == 429){
        text = 'Too many requests - only 12 requests per hour allowed';
      }
      throw Exception(text);
    }
  }

  Future<void> syncItems() async {
    var settings = await new SettingsService().getSettings();
    http.Response itemResponse = await http.get(ApiBaseUrl+ 'items/list', headers: {'x-api-key':settings.apiKey});
    if(itemResponse.statusCode == 200){
      var itemRepo = new ItemRepository();

      http.Response iconResponse = await http.get(ApiBaseUrl+ 'items/icons', headers: {'x-api-key':settings.apiKey});
      List<Item> items;
      if(iconResponse.statusCode == 200){
        var icons = (jsonDecode(iconResponse.body)['icons'] as List<dynamic>);
        items = (jsonDecode(itemResponse.body)['items'] as List<dynamic>).map((dynamic item) {
          var itemWithicon = Item.fromJson(item);
          findAndExtractIcon(icons, itemWithicon);
          return itemWithicon;
        }).toList();
      }else{
         items = (jsonDecode(itemResponse.body)['items'] as List<dynamic>).map((dynamic item) =>Item.fromJson(item)).toList();
      }
      await itemRepo.insertItems(items);
    }else{
      var text = 'Failed to sync items';
      if(itemResponse.statusCode == 401){
        text = 'Invalid API Key';
      }
      if(itemResponse.statusCode == 429){
        text = 'Too many requests - only 6 requests per day allowed';
      }
      throw Exception(text);
    }
  }

  void findAndExtractIcon(List icons, Item itemWithicon) {
    var icon = icons.firstWhere((dynamic i) => (i['item_id'] as int).toString() == itemWithicon.itemId, orElse: () => null);
    if(icon != null){
      String base64Icon = icon['icon'];
      base64Icon = base64Icon.substring(22, base64Icon.length);
      itemWithicon.icon = base64Icon;
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
      return Item.withIcon(
        maps[i]['id'],
        maps[i]['uniqueName'],
        maps[i]['name'],
        maps[i]['type'],
        maps[i]['npcPrice'],
        maps[i]['subtype'],
        maps[i]['slots'],
        maps[i]['icon'],
      );
    });
  }

  cards(String pattern) async {
    final Database db = await Shared.getDatabase();
    List<Map<String, dynamic>>  maps = await db.query('item', where: "name LIKE '%"+ pattern +"%' AND type = 'IT_CARD'");


    return List.generate(maps.length, (i) {
      return Item.withIcon(
        maps[i]['id'],
        maps[i]['uniqueName'],
        maps[i]['name'],
        maps[i]['type'],
        maps[i]['npcPrice'],
        maps[i]['subtype'],
        maps[i]['slots'],
        maps[i]['icon'],
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

  Future<Item> getItemById(String itemId) async {
    final Database db = await Shared.getDatabase();
    List<Map<String, dynamic>>  maps = await db.query('item', where: "id = ?", whereArgs: [itemId]);


    return List.generate(maps.length, (i) {
      return Item.withIcon(
        maps[i]['id'],
        maps[i]['uniqueName'],
        maps[i]['name'],
        maps[i]['type'],
        maps[i]['npcPrice'],
        maps[i]['subtype'],
        maps[i]['slots'],
        maps[i]['icon'],
      );
    }).first;
  }

  Future<Map<String, Item>> getItemsById(List<String> itemId) async {
    final Database db = await Shared.getDatabase();
    List<Map<String, dynamic>>  maps = await db.query('item', where: "id in (${itemId.map((String i) =>"'$i'").join(',')})");


    var items = List.generate(maps.length, (i) {
      return Item.withIcon(
        maps[i]['id'],
        maps[i]['uniqueName'],
        maps[i]['name'],
        maps[i]['type'],
        maps[i]['npcPrice'],
        maps[i]['subtype'],
        maps[i]['slots'],
        maps[i]['icon'],
      );
    });
    return Map.fromEntries(itemId.map((String itemId) => MapEntry(itemId, items.singleWhere((Item item)=> item.itemId == itemId))).toList());
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

enum ShopType{
    V,
    B,
}

class Shop{
  String title;
  String owner;
  Location location;
  DateTime creationDate;
  ShopType type;
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

  @override
  String toString(){
    return '$map: X:$x, Y:$y';
  }

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
  String icon;

  Item(this.itemId, this.uniqueName, this.name, this.type, this.npcPrice, this.subtype, this.slots);


  Item.withIcon(this.itemId, this.uniqueName, this.name, this.type,

      this.npcPrice, this.subtype, this.slots, this.icon);

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
    return slots != null ? '$name [$slots]':'$name';
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
      'icon': icon,
    };
  }
}