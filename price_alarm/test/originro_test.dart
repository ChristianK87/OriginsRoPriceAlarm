// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:price_alarm/originro/originro.dart';

import 'package:price_alarm/shared.dart';

void main() {
  test('findAndExtractIcon should find corect item', () {
    var itemId = 1234;
    var item = new Item(itemId.toString(), "", "", "", 10, "", 0);

    var icon = {
      'item_id': itemId,
      'icon': "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAP1BMVEX/AP/XqpHDkHqudmL////ox6X/9LxJSUm3t7eSkpLb29tubm7Kt6//8+u+QzDTjG7tZEfyhVmPIhi4o5v/8OVQ35yOAAAAAXRSTlMAQObYZgAAAAFiS0dEBI9o2VEAAAAHdElNRQfjCwIOOR3mwfZ/AAAAmElEQVQoz7WP2w6DIBAFsSyedavLRf//W7uQVmk0afvQeSIzOQSc+wfDcPOXnigE/1MYxxBw0szTYAMwv2kikunuPcBEc+8XknkCVNXOfHhADOYYVYG9mE92V2y08iksQBbRp+/CDM3CSRulKNb9E5o4p/QK6/Fe0WyhpVI6bxORZK7SD+pELn0t7ZqTd25raT35mrZL/TUPifEKODGf6AcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTktMTEtMDJUMTQ6NTc6MjkrMDA6MDD4t/0HAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE5LTExLTAyVDE0OjU3OjI5KzAwOjAwiepFuwAAAABJRU5ErkJggg==",
    };
    List<dynamic> icons= new List();
    icons.add(icon);

    expect(item.icon, null);
    new OriginRoService().findAndExtractIcon(icons, item);

    expect(item.icon, "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAP1BMVEX/AP/XqpHDkHqudmL////ox6X/9LxJSUm3t7eSkpLb29tubm7Kt6//8+u+QzDTjG7tZEfyhVmPIhi4o5v/8OVQ35yOAAAAAXRSTlMAQObYZgAAAAFiS0dEBI9o2VEAAAAHdElNRQfjCwIOOR3mwfZ/AAAAmElEQVQoz7WP2w6DIBAFsSyedavLRf//W7uQVmk0afvQeSIzOQSc+wfDcPOXnigE/1MYxxBw0szTYAMwv2kikunuPcBEc+8XknkCVNXOfHhADOYYVYG9mE92V2y08iksQBbRp+/CDM3CSRulKNb9E5o4p/QK6/Fe0WyhpVI6bxORZK7SD+pELn0t7ZqTd25raT35mrZL/TUPifEKODGf6AcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTktMTEtMDJUMTQ6NTc6MjkrMDA6MDD4t/0HAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE5LTExLTAyVDE0OjU3OjI5KzAwOjAwiepFuwAAAABJRU5ErkJggg==");

  });

  test('findAndExtractIcon should set no Icon if not matching Id', () {
    var itemId = 1234;
    var item = new Item("5", "", "", "", 10, "", 0);

    var icon = {
      'item_id': itemId,
      'icon': "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAP1BMVEX/AP/XqpHDkHqudmL////ox6X/9LxJSUm3t7eSkpLb29tubm7Kt6//8+u+QzDTjG7tZEfyhVmPIhi4o5v/8OVQ35yOAAAAAXRSTlMAQObYZgAAAAFiS0dEBI9o2VEAAAAHdElNRQfjCwIOOR3mwfZ/AAAAmElEQVQoz7WP2w6DIBAFsSyedavLRf//W7uQVmk0afvQeSIzOQSc+wfDcPOXnigE/1MYxxBw0szTYAMwv2kikunuPcBEc+8XknkCVNXOfHhADOYYVYG9mE92V2y08iksQBbRp+/CDM3CSRulKNb9E5o4p/QK6/Fe0WyhpVI6bxORZK7SD+pELn0t7ZqTd25raT35mrZL/TUPifEKODGf6AcAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTktMTEtMDJUMTQ6NTc6MjkrMDA6MDD4t/0HAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE5LTExLTAyVDE0OjU3OjI5KzAwOjAwiepFuwAAAABJRU5ErkJggg==",
    };
    List<dynamic> icons= new List();
    icons.add(icon);

    expect(item.icon, null);
    new OriginRoService().findAndExtractIcon(icons, item);

    expect(item.icon, null);

  });
}