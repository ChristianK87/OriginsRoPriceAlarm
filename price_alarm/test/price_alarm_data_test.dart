// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:price_alarm/originro/originro.dart';
import 'package:price_alarm/pricealarm/price_alarm_data.dart';


void main() {
  test('updatePriceAlarmState with matched id, price, refinement and cards should set found to true', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "1234", 100, false, "", "", 7);
    priceAlarm.cards = List.generate(2, (int index) => new PriceAlarmCard(1, 12, index.toString(), ""));
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 100, 7, [0,1], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, true);
  });

  test('updatePriceAlarmState with matched id, price, refinement and cards not defined should set found to true', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "1234", 100, false, "", "", 7);
    priceAlarm.cards = new List();
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 100, 7, [10,11], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, true);
  });

  test('updatePriceAlarmState with matched id, price, refinement but not cards should set found to false', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "1234", 100, false, "", "", 7);
    priceAlarm.cards = List.generate(2, (int index) => new PriceAlarmCard(1, 12, index.toString(), ""));
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 100, 7, [2,3], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, false);
  });

  test('updatePriceAlarmState with matched id, price and refinement anything should set found to true', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "1234", 100, false, "", "", -1);
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 100, 6, [], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, true);
  });

  test('updatePriceAlarmState with matched id and price but not refinement should set found to false', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "1234", 100, false, "", "", 7);
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 100, 6, [], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, false);
  });

  test('updatePriceAlarmState with matched id but not price should set found to false', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "1234", 100, false, "", "", 7);
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 101, 6, [], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, false);
  });

  test('updatePriceAlarmState without matching id should set found to false', () {
    var priceAlarm = new PriceAlarm.withIdAndPrice(12, "5678", 100, false, "", "", 7);
    var items = List.generate(1, (int index) => new MarketItem("1234", 1, 100, 6, [], "", 0, 0));
    new PriceAlarmService().updatePriceAlarmState(items, priceAlarm);
    expect(priceAlarm.found, false);
  });
}