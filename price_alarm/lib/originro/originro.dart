import 'dart:convert';

import 'package:price_alarm/settings/settings.dart';
import 'package:http/http.dart' as http;

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
  List<Item> items;

  Shop(this.title, this.owner, this.location, this.creationDate, this.type,
      this.items);

  factory  Shop.fromJson(Map<String, dynamic> json) {
    var location = Location.fromJson(json['location']);
    var items = (json['items'] as List<dynamic>).map((dynamic item) => Item.fromJson(item)).toList();
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

class Item{
  String itemId;
  int amount;
  int price;
  int refine;
  List<dynamic> cards;
  String element;
  int starCrumbs;
  int creator;

  Item(this.itemId, this.amount, this.price, this.refine, this.cards,
      this.element, this.starCrumbs, this.creator);

  factory  Item.fromJson(Map<String, dynamic> json) {
    List<dynamic> cards = (json['cards'] as List<dynamic>);

    return Item(
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