import "dart:math";
import "package:flutter/gestures.dart";
import "package:pulsdatenapp/model/activitydata.dart";
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import "package:path/path.dart";
import "dart:async";
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import "pulsedatapoint.dart";
import "userdata.dart";

class DBHandler {
  static BluetoothDevice device = BluetoothDevice.fromId("");
  static bool activityErkannt = false;
  static const dbName = "appDB.db";
  static const dbVersion = 1;
  static DatabaseFactory? dbFactory;
  //static List<ActivityData> Activities = <ActivityData>[];

  /*//KeyMethode zur Interaction mit der DB
  Future<Database> open() async{
    final dbpath = await getDatabasesPath();
    final path = join(dbpath,dbName);

    return openDatabase(path, version: dbVersion, onCreate: createDB);
  }*/

  /// debug method to clear all data from database
  Future<void> clearDB() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    await db.execute('DELETE FROM IF EXISTS PulsDaten');
    await db.execute('DELETE FROM IF EXISTS UserDaten');
    await db.execute('DELETE FROM IF EXISTS ActivityDaten');
    await db.execute('DELETE FROM IF EXISTS LatestActivityDaten');
    await db.execute('DELETE FROM IF EXISTS TestPulsDaten');
  }

  //Diese Methode wird automatisch ausgeführt, wenn keine Datenbank existiert.
  Future<void> createDB(Database db, int version) async {
    //Erstellung der Tabellen

    await db.execute('''
      CREATE TABLE IF NOT EXISTS PulsDaten(
        zeitpunkt INTEGER PRIMARY KEY,
        pulsvalue INTEGER
      )
    ''');

     await db.execute('''
      CREATE TABLE IF NOT EXISTS BTDevice(
        RemoteID TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS UserDaten (
      name TEXT,
      birthDate INTEGER,
      height REAL,
      weight REAL,
      gender TEXT CHECK(gender IN ('m', 'f', 'd')),
      dailyGoal INTEGER,
      restingHeartRate INTEGER
    )
  ''');

    //Erstellt Activitydata
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ActivityDaten (
        activityName TEXT,
        timeSinceEpochFrom INTEGER,
        timeSinceEpochTill INTEGER,
        calories INTEGER
    )
  ''');

    //Erstellt Tablle 'LatesActivityDaten'
    //Sie beinhaltet alle jemals getätigten Aktivitäten
    //Die Liste soll sortiert sein nach 'neuste Aktivität oben', daher muss die Endzeit bekannt sein
    await db.execute('''
      CREATE TABLE IF NOT EXISTS LatestActivityDaten (
        activityName TEXT,
        timeSinceEpochEnd INTEGER
      )
  ''');

    //createTestDB();
    //Erstellung der TestPulsdatentabelle
    await db.execute('''
      CREATE TABLE IF NOT EXISTS TestPulsDaten(
        pulsvalue INTEGER PRIMARY KEY,
        zeitpunkt INTEGER
      )
    ''');
  }

  Future<void> insertUserData(UserData userData) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final isUser = await db.query("UserDaten", limit: 1);

    //Wenn es noch keinen Nutzer gibt, wird ein neuer erstellt
    if (isUser.isEmpty) {
      await db.insert(
        "UserDaten",
        {
          "name": userData.name,
          "birthDate": userData.birthDate.microsecondsSinceEpoch,
          "height": userData.heightInCM,
          "weight": userData.weightInKG,
          "gender": userData.gender.name,
          "dailyGoal": userData.dailyGoal,
          "restingHeartRate": userData.restingHeartRate,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      //Ansonsten wird der User überarbeitet
    } else {
      await db.update(
        "UserDaten",
        {
          "name": userData.name,
          "birthDate": userData.birthDate
              .microsecondsSinceEpoch, //Hier wird das geburtsdatum in einen int convertiert
          "height": userData.heightInCM,
          "weight": userData.weightInKG,
          "gender": userData.gender.name,
          "dailyGoal": userData.dailyGoal,
          "restingHeartRate": userData.restingHeartRate,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> setDevice(BluetoothDevice d) async {
    device = d;
    
  }
  

  BluetoothDevice getDevice() {
    return device;
  }

  Future<String> getRemoteID() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> rows = await db.query(
      "BTDevice",
      limit: 1,
    );

    List<BluetoothDevice> entries = rows.map((row) {
      return BluetoothDevice.fromId(row["RemoteID"]);
    }).toList();

    if (entries.isEmpty) return "";


    return entries[0].remoteId.toString();
  }

  Future<void> setErkanntTrue() async {
    activityErkannt = true;
  }

  Future<void> setErkanntFalse() async {
    activityErkannt = true;
  }

  bool getrecActivity() {
    return activityErkannt;
  }

  Future<void> insertPulsDaten(PulseDataPoint point) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    await db.insert(
      "PulsDaten",
      {"zeitpunkt": point.zeitPunkt, "pulsvalue": point.pulsValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  ///HIER DB ZUGRIFF FÜR PERSISTENZ
  Future<void> insertActivity(ActivityData activity) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    await db.insert(
      "ActivityDaten",
      {
        "activityName": activity.activityName,
        "timeSinceEpochFrom": activity.timeSinceEpochFrom,
        "timeSinceEpochTill": activity.timeSinceEpochTill,
        "calories": activity.calories,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    //Nun wird die auch die Tabelle für die neuste Activität geupdated.
    insertLatestActivity(activity);
    //Activities.add(activity);
  }

  //Pfelgen der 'LatestActivityData' Tabelle
  Future<void> insertLatestActivity(ActivityData activity) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion);

    //Hier wird geprüft, ob der Eintrag ereits existiert:
    //Es wird eine Liste aus allen vorhanden Einträgen erstellt die den namen "activity.activityName" teilen.
    //Dies dürfte eigentlich immer maximal 1 Eintrag sein, aber zur Sicherheit vor Fehlern wird trotzdem eine Liste erstellt.
    List<Map<String, dynamic>> existingEntry = await db.query(
      "LatestActivityDaten",
      where: "activityName = ?",
      whereArgs: [activity.activityName],
    );

    //Falls die # an Einträgen der Liste > 0 ist, dann werden alle Einträge die den Namen der neustes Aktivität haben gelöscht.
    if (existingEntry.isNotEmpty) {
      await db.delete(
        "LatestActivityDaten",
        where: "activityName = ?",
        whereArgs: [activity.activityName],
      );
    }

    //Zuletzt wird der neue Eintrag eingefügt
    //Die Endzeit wird hinzugefügt, damit die Tabelle sortiert ausgegeben werden kann.
    await db.insert(
      "LatestActivityDaten",
      {
        "activityName": activity.activityName,
        "timeSinceEpochEnd": activity.timeSinceEpochTill
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBulkTestPulsDaten(List<PulseDataPoint> points) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    Batch batch = db.batch();

    for (var point in points) {
      batch.insert(
        "TestPulsDaten",
        {"pulsvalue": point.pulsValue, "zeitpunkt": point.zeitPunkt},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> dummyInsertion() async {
    // Generating 600 PulseDataPoint objects with random values
    List<PulseDataPoint> pulsesList = [];
    Random random = Random();

    for (int i = 0; i < 600; i++) {
      int zeitPunkt = DateTime.now().millisecondsSinceEpoch -
          random.nextInt(
              1000000); // Random time within a range (adjust as needed)
      int pulsValue = random.nextInt(
          150); // Random pulse value between 0 and 149 (adjust range as needed)

      PulseDataPoint pulse = PulseDataPoint(pulsValue, zeitPunkt);
      pulsesList.add(pulse);
    }
    //Sortieren der Liste nach den Zeitpunkten
    pulsesList.sort((a, b) => a.zeitPunkt.compareTo(b.zeitPunkt));

    // Inserting 600 pulse data points into the database
    await insertBulkTestPulsDaten(pulsesList);

    //Showing the sorted list (for verification purposes)
    pulsesList.forEach((point) {
      print("Puls: ${point.pulsValue}, Zeitpunkt: ${point.zeitPunkt}");
    });
  }

  ///Use this to get a list of every User
  Future<List<UserData>> getUserData() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> maps = await db.query("UserDaten");

    return List.generate(maps.length, (index) {
      return UserData(
        maps[index]["name"] as String,
        DateTime.fromMicrosecondsSinceEpoch(maps[index]["birthDate"]
            as int), //Hier wird DateTime aus einem int convertiert
        maps[index]["height"] as double,
        maps[index]["weight"] as double,
        Gender.values.byName(maps[index]["gender"]),
        maps[index]["dailyGoal"] as int,
        maps[index]["restingHeartRate"] as int,
      );
    });
  }

  ///Use this to get the UserData of the first User(if any)
  ///
  Future<UserData?> getFirstUserData() async {
    List<UserData> userList = await getUserData();

    if (userList.isEmpty) {
      return null;
    }

    return userList.first;
  }

  ///Get the newest 300 PulsPoints
  ///Only handles points which are not older then 1 minute in relation to the previous point
  Future<List<PulseDataPoint>> getPulsPoints() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> rows = await db.query(
      "PulsDaten",
      orderBy: "zeitpunkt DESC",
      limit: 300,
    );

    List<PulseDataPoint> entries = rows.map((row) {
      return PulseDataPoint(row["pulsvalue"], row["zeitpunkt"]);
    }).toList();

    if (entries.isEmpty) return [];

    //int index = 0;
    for (int i = 0; i < entries.length - 1; i++) {
      int currentTime = entries[i].zeitPunkt;
      int nextTime = entries[i + 1].zeitPunkt;

      if (nextTime - currentTime > 60000) {
        //index = i;
        break;
      }
    }

    //300 Datenpunkte gleichzeitig ausgeben. AUßer ein 60000 millisekunden skip ist swichen 2 datenpunkten vorhanden.
    //return entries.sublist(0,index +1);
    return entries;
  }

  //Methode zum erhalten aller PulsDatenPunkte zwichen Zeitpunkt A und Zeitpunkt B
  Future<List<PulseDataPoint>> getPulsByDate(int timeBegin, int timeEnd) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> rows = await db.query(
      "PulsDaten",
      orderBy: "zeitpunkt DESC",
      where: "zeitpunkt >= ? AND zeitpunkt <= ?",
      whereArgs: [timeBegin, timeEnd],
    );

    List<PulseDataPoint> pulseDataList = rows.map((row) {
      return PulseDataPoint(row["pulsvalue"], row["zeitpunkt"]);
    }).toList();

    return pulseDataList;
  }

  Future<List<PulseDataPoint>> getCurrentPuls() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> rows = await db.query(
      "PulsDaten",
      orderBy: "zeitpunkt DESC",
      limit: 1,
    );

    List<PulseDataPoint> entries = rows.map((row) {
      return PulseDataPoint(row["pulsvalue"], row["zeitpunkt"]);
    }).toList();

    if (entries.isEmpty) return [];

    return entries;
  }

  ///HIER LETZTE 24H AKTIVITÄT ALS LISTE AUSGEBEN
  Future<List<ActivityData>> getActivities() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo = now - const Duration(hours: 24).inMilliseconds;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ActivityDaten WHERE timeSinceEpochFrom >= ? AND timeSinceEpochFrom <= ?',
      [twentyFourHoursAgo, now],
    );

    return List.generate(maps.length, (index) {
      return ActivityData(
        maps[index]["activityName"] as String,
        maps[index]["timeSinceEpochFrom"] as int,
        maps[index]["timeSinceEpochTill"] as int,
        maps[index]["calories"] as int,
      );
    });
    //return Activities;
  }

  //Die Methode gibt eine Liste der Namen aller getätigen Aktivitäten wieder,
  //Sortiert anhand des letzten Datums
  Future<List<String>> getLatestActivities() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> maps = await db
        .query('LatestActivityDaten', orderBy: 'timeSinceEpochEnd DESC');

    return List.generate(maps.length, (index) {
      return maps[index]["activityName"] as String;
    });
  }

  Future<PulseDataPoint?> getDummywertPulsPoints() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    final List<Map<String, dynamic>> rows = await db.query(
      "TestPulsDaten",
      orderBy: "zeitpunkt DESC",
      limit: 600,
    );
    if (rows.isEmpty) return null;

    final latestDataPoint =
        PulseDataPoint(rows[0]["pulsvalue"], rows[0]["zeitpunkt"]);

    // Delete the latest record from the database
    await db.delete(
      "TestPulsDaten",
      where: "zeitpunkt = ?",
      whereArgs: [rows[0]["zeitpunkt"]],
    );

    return latestDataPoint;
  }

  Future<List<PulseDataPoint>> getPulsDataForLast12Hours() async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, dbName);

    final db = await openDatabase(path, version: dbVersion, onCreate: createDB);

    // Berechnet Zeitstamp für 12 Stunden
    DateTime twelveHoursAgo = DateTime.now().subtract(Duration(hours: 12));
    int twelveHoursAgoTimestamp = twelveHoursAgo.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> rows = await db.query(
      "PulsDaten",
      where: "zeitpunkt >= ?",
      whereArgs: [twelveHoursAgoTimestamp],
      orderBy: "zeitpunkt ASC", // Order by timestamp in ascending order
    );

    List<PulseDataPoint> entries = rows.map((row) {
      return PulseDataPoint(row["pulsvalue"], row["zeitpunkt"]);
    }).toList();

    if (entries.isEmpty) return [];

    // Berechnet der Durchnitt für jeder 5 minuten Daten
    List<PulseDataPoint> averagedData = [];
    int scaler = 120; //Maximum of 360 Values on Page
    if (entries.length <= 360) {
      scaler = 1;
    } else if (entries.length <= 43200) {
      scaler = (entries.length ~/ 360) + 1;
    }
    int interval = scaler *
        1000; // Scale time intervall to always include roughly 360 values
    int currentIntervalStart = entries[0].zeitPunkt;
    int sum = 0;
    int count = 0;

    for (int i = 0; i < entries.length; i++) {
      int currentTime = entries[i].zeitPunkt;

      if (currentTime - currentIntervalStart <= interval) {
        // Fügt Daten zum aktuellsten Intervall hinzu
        sum += entries[i].pulsValue;
        count++;
      } else {
        // Berechnen Sie den Durchschnitt für das aktuelle Intervall und setzen Sie die Zähler zurück
        if (count > 0) {
          int average =
              sum ~/ count; // Verwendung von ~/ für die Ganzzahldivision
          averagedData.add(PulseDataPoint(average, currentIntervalStart));
        }
        // Zum nächsten Intervall wechseln
        currentIntervalStart += interval;
        sum = entries[i].pulsValue;
        count = 1;
      }
    }

    // Wenn nach der Schleife noch Daten vorhanden sind, berechnen Sie den Durchschnitt für das letzte Intervall
    if (count > 0) {
      int average = sum ~/ count;
      averagedData.add(PulseDataPoint(average, currentIntervalStart));
    }

    return averagedData;
  }
}
