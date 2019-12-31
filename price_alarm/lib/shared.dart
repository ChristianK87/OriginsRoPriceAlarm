
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Shared {

 static Future<Database> getDatabase() async {
    return await openDatabase(
      // Set the path to the database.
      join(await getDatabasesPath(), 'price_alarm_database2.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) async {
        // Run the CREATE TABLE statement on the database.
        await db.execute(
          "CREATE TABLE price_alarm(id TEXT PRIMARY KEY, price INTEGER, found INTEGER, name TEXT)",
        );
        return db.execute(
          "CREATE TABLE item(id TEXT PRIMARY KEY, uniqueName TEXT, name TEXT, type TEXT, npcPrice INTEGER, subtype TEXT, slots INTEGER);",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // Run the CREATE TABLE statement on the database.
        if(oldVersion < newVersion) {
          db.execute(
            "ALTER TABLE price_alarm ADD name TEXT",
          );
        }
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 5,
    );
  }
  
  static intToStringWithSeparator(int value){
   var text = value.toString();
   String formattedText = "";
   int startIndex = text.length;
   while(startIndex > 3){
     var part = text.substring(startIndex-3, startIndex);
     part = "," + part;
     formattedText = part+formattedText;
     startIndex -=3;
   }
   var part = text.substring(0, startIndex);
   formattedText = part+formattedText;

   return formattedText;
  }

}