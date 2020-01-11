import 'package:flutter/material.dart';
import 'package:price_alarm/originro/originro.dart';
import 'package:price_alarm/pricealarm/price_alarm_data.dart';
import 'package:price_alarm/shared.dart';

class ShopsWidget extends StatefulWidget {
  List<Shop> shops;
  PriceAlarm priceAlarm;

  ShopsWidget(this.shops, this.priceAlarm);

  @override
  ShopsState createState() => ShopsState(this.shops, this.priceAlarm);
}

class ShopsState extends State<ShopsWidget> {
  List<Shop> shops;
  PriceAlarm priceAlarm;
  PriceAlarmService priceAlarmService = new PriceAlarmService();
  ItemRepository itemRepo = new ItemRepository();

  ShopsState(this.shops, this.priceAlarm);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: this.shops.length,
        itemBuilder: /*1*/ (context, i) {
          return buildRow(shops.elementAt(i));
        });
  }

  Widget buildRow(Shop shop) {
    var marketItem =
        priceAlarmService.findCheapestPriceAlarmInShop(shop.items, priceAlarm);
    var lookingItems = List.of([marketItem.itemId]);
    if(marketItem.cards != null){
      lookingItems.addAll(marketItem.cards.map((dynamic i)=>i.toString()));
    }
    return Container(
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(10.0),
            color: priceAlarm.price >= marketItem.price
                ? Colors.lightGreenAccent
                : Colors.white,
            boxShadow: [
              new BoxShadow(
                  color: Colors.grey,
                  offset: new Offset(2.0, 2.0),
                  blurRadius: 2.0,
                  spreadRadius: 2.0)
            ]),
        child: FutureBuilder(
          future: itemRepo.getItemsById(lookingItems),
          builder: (BuildContext context, AsyncSnapshot<Map<String,Item>> snapshot) {
            if(snapshot.hasData){
              var items = snapshot.data;
              var cards = '';
              if(marketItem.cards != null){
                cards = marketItem.cards.map((dynamic card) => '[${items[card.toString()].name}]\n').join(' ');
              }
              return ListTile(
                title: Text(
                  'Shop: ${shop.title}\nVender: ${shop.owner}',
                  style: TextStyle(fontSize: 18.0),
                ),
                subtitle: Text(
                  '${shop.location.toString()} \n${marketItem.refine == null ? '': '+${marketItem.refine} '}${items[marketItem.itemId].toString()}\n $cards${Shared.intToStringWithSeparator(marketItem.price)}',
                  style: TextStyle(fontSize: 16.0),
                ),
                isThreeLine: true,
              );
            }
            return SizedBox();
          },
        ));
  }
}
