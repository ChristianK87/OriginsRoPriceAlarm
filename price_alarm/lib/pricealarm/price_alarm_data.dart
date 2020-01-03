import 'package:price_alarm/originro/originro.dart';
import 'package:sqflite/sqflite.dart';
import 'package:price_alarm/shared.dart';

class PriceAlarmService{

  Future<List<PriceAlarm>> getPriceAlarms() async{
    var priceAlarms = await new PriceAlarmRepository().priceAlarms();
    var priceAlarmCardRepo = new PriceAlarmCardRepository();
    await Future.forEach(priceAlarms, (PriceAlarm priceAlarm) async =>priceAlarm.cards = await priceAlarmCardRepo.priceAlarmCardsByPriceAlarm(priceAlarm.id));
    return priceAlarms;
  }

  Future<void> insertPriceAlarm(PriceAlarm priceAlarm) async{
    var priceAlarmid = await new PriceAlarmRepository().insertPriceAlarm(priceAlarm);
    var priceAlarmCardRepo = new PriceAlarmCardRepository();
    if(priceAlarm.cards != null){
      await Future.forEach(priceAlarm.cards, (PriceAlarmCard priceAlarmCard) async {
        priceAlarmCard.priceAlarmId = priceAlarmid;
        await priceAlarmCardRepo.insertPriceAlarmCard(priceAlarmCard);
      });
    }

  }

  Future<void> removePriceAlarm(PriceAlarm priceAlarm) async{
    await new PriceAlarmRepository().removeEntry(priceAlarm.id);
    var priceAlarmCardRepo = new PriceAlarmCardRepository();
    if(priceAlarm.cards != null) {
      priceAlarm.cards.forEach((PriceAlarmCard priceAlarmCard) async =>
          priceAlarmCardRepo.removeEntry(priceAlarmCard.id));
    }
  }

  void updatePriceAlarmState(List<MarketItem> items, PriceAlarm priceAlarm) {
    var marketItem = items.firstWhere((MarketItem item){
      var idMatched = item.itemId == priceAlarm.itemId;
      if(!idMatched){
        return false;
      }
      var priceMatched = item.price <= priceAlarm.price;
      if(!priceMatched){
        return false;
      }
      var refinementMatched = true;
      if(priceAlarm.refinement != null && priceAlarm.refinement != -1){
       if(item.refine == null){
         refinementMatched = false;
       }else{
         refinementMatched = priceAlarm.refinement <= item.refine;
       }
      }
      if(!refinementMatched){
        return false;
      }
      var cardMatched = true;
      if(priceAlarm.cards != null){
        if(item.cards == null){
          cardMatched = false;
        }else{
          cardMatched = !priceAlarm.cards.any((PriceAlarmCard card) => !item.cards.contains(int.parse(card.cardId)));
        }
      }
      if(!cardMatched){
        return false;
      }
      return true;
    } , orElse: ()=> null);
    priceAlarm.found = marketItem != null;
  }
}

class PriceAlarm {
  int id;
  String itemId;
  int price;
  bool found;
  String name;
  String icon;
  int refinement;
  List<PriceAlarmCard> cards;

  PriceAlarm(){
    this.refinement = -1;
  }

  PriceAlarm.withIdAndPrice(this.id ,this.itemId, this.price, this.found, this.name, this.icon, this.refinement);

  Map<String, dynamic> toMap() {
    return {
      'id': itemId,
      'price': price,
      'found': found,
      'name': name,
      'icon': icon,
      'refinement': refinement,
    };
  }
}

class PriceAlarmCard {
  int id;
  int priceAlarmId;
  String cardId;
  String name;


  PriceAlarmCard(this.id ,this.priceAlarmId, this.cardId, this.name);

  Map<String, dynamic> toMap() {
    return {
      'price_alarm_id': priceAlarmId,
      'card_id': cardId,
      'name': name,
    };
  }
}

class PriceAlarmRepository{

  Future<int> insertPriceAlarm(PriceAlarm priceAlarm) async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    return await db.insert(
      'price_alarm',
      priceAlarm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PriceAlarm>> priceAlarms() async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('price_alarm', columns: ['rowid','id','price','found','name','icon','refinement']);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return PriceAlarm.withIdAndPrice(
        maps[i]['rowid'],
        maps[i]['id'],
        maps[i]['price'],
        maps[i]['found'] == 1,
        maps[i]['name'],
        maps[i]['icon'],
        maps[i]['refinement'],
      );
    });
  }

  Future<void> removeEntry(id) async {
    final db = await Shared.getDatabase();

    await db.delete(
      'price_alarm',
      where: "rowid = ?",
      whereArgs: [id],
    );
  }

  void updatePriceAlarm(PriceAlarm priceAlarm) async {
    final db = await Shared.getDatabase();

    await db.update(
      'price_alarm',
      priceAlarm.toMap(),
      where: "rowid = ?",
      whereArgs: [priceAlarm.id],
    );
  }
}

class PriceAlarmCardRepository{

  Future<void> insertPriceAlarmCard(PriceAlarmCard priceAlarmCard) async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();

    await db.insert(
      'price_alarm_card',
      priceAlarmCard.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PriceAlarmCard>> priceAlarmCardsByPriceAlarm(int priceAlarmId) async {
    // Get a reference to the database.
    final Database db = await Shared.getDatabase();

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('price_alarm_card', columns: ['rowid','price_alarm_id','card_id','name'], where: 'price_alarm_id = ?', whereArgs: [priceAlarmId]);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return PriceAlarmCard(
        maps[i]['rowid'],
        maps[i]['price_alarm_id'],
        maps[i]['card_id'],
        maps[i]['name'],
      );
    });
  }

  Future<void> removeEntry(id) async {
    final db = await Shared.getDatabase();

    await db.delete(
      'price_alarm_card',
      where: "rowid = ?",
      whereArgs: [id],
    );
  }
}