import 'dart:isolate';

import 'dart:math';

import 'dart:io' show Platform;
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/model/userdata.dart';

import 'view_model.dart';
import 'events.dart';
import 'package:pulsdatenapp/model/activitydata.dart';
import 'package:pulsdatenapp/model/dbHandler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pulsdatenapp/main.dart';

class HomeViewModel extends EventViewModel {
  final DBHandler dbHandler; // <-- Model mit Daten
  UserData? user;
  BluetoothDevice device = BluetoothDevice.fromId("remoteId");
  bool popUpOpen = false;
  Random random = Random();
  HomeViewModel({
    required this.dbHandler,
  }) {
    //FlutterBackgroundService().invoke('stopService');
    startPulseDataCollection();
  } // <-- Konstruktor initalisieren

  void clearDB() {
    dbHandler.clearDB().then((value) => loadActivityData());
  }

  Future<void> connectWithBLE() async {
    // first, check if bluetooth is supported by your hardware
// Note: The platform is initialized on the first call to any FlutterBluePlus method.
    if (await FlutterBluePlus.isSupported == false) {
      //print("Bluetooth not supported by this device");
      return;
    }

// handle bluetooth on & off
// note: for iOS the initial state is typically BluetoothAdapterState.unknown
// note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    var subscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState state) async {
      //print(state);
      if (state == BluetoothAdapterState.on) {
        // usually start scanning, connecting, etc
        await showBLEDevices();
      } else {
        // show an error to the user, etc
      }
    });

// turn on bluetooth ourself if we can
// for iOS, the user controls bluetooth enable/disable
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

// cancel to prevent duplicate listeners
    subscription.cancel();
  }

  Future<void> showBLEDevices() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        List<BluetoothDevice> r = results
            .map((e) => e.device)
            .toList(); // the most recently found device
        notify(BLEDevicesLoadedEvent(result: r));
      },
      onError: (e) => print(e),
    );
    // show already connected devices
    List<BluetoothDevice> systemDevices = await FlutterBluePlus.systemDevices;
    // filter out devices without the correct service
    systemDevices = systemDevices
        .where(
          (device) => device.servicesList.any(
            (service) => service.uuid == Guid("180D"),
          ),
        )
        .toList();
    notify(BLEDevicesLoadedEvent(result: systemDevices));

// cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

// Start scanning w/ timeout
// optional: use `stopScan()` to stop the scan at anytime
    await FlutterBluePlus.startScan(
        withServices: [Guid("180D")],
        timeout: Duration(seconds: 15));

// wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  void connectToDevice(BluetoothDevice d) async {
    await d.connect();
    dbHandler.setDevice(d);
    device = d;
    print(device.advName);
    user = await dbHandler.getFirstUserData();

    double maxHR = 0;
    int currentHR = 0;
    int activityDuration = 0;
    if (device.isConnected) {
      if (user != null) {
        int age = DateTime.now().year - user!.birthDate.year;
        maxHR = 208 - (age * 0.7);
      }
      print("success");
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service1 in services) {
        if (service1.uuid == Guid("180D")) {
          for (BluetoothCharacteristic characteristic
              in service1.characteristics) {
            if (characteristic.uuid == Guid("2A37")) {
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) {
                print('Notification received: $value');
                if (value[0] % 2 == 0) //HR als Uint8 übermittelt
                {
                  currentHR = value[1];
                  dbHandler.insertPulsDaten(PulseDataPoint(
                    currentHR, DateTime.now().millisecondsSinceEpoch));
                  if (maxHR != 0) {
                    if (currentHR > maxHR / 2) {
                      activityDuration++;
                    }
                  }
                } else //HR als Uint16 übermittelt
                {
                  currentHR = (value[1] + value[2] << 8);
                  dbHandler.insertPulsDaten(PulseDataPoint(
                    currentHR, DateTime.now().millisecondsSinceEpoch));
                  if (maxHR != 0) {
                    if (currentHR > maxHR / 2) {
                      activityDuration++;
                    }
                  }
                }
                if ((currentHR <= maxHR / 2)) {
                  if (activityDuration >= 300) {
                    dbHandler.setErkanntTrue();
                  }
                }
              });
            }
          }
        }
      }
    }
  }

  //UserData laden um anzuzeigen und zu bearbeiten
  //Zurückgegeben (über den Notify) wird "UserData?"
  //Bei leerer Tabelle wird null übermittelt
  Future<void> getUser() async {
    //notify(LoadingEvent(isLoading: true));
    dbHandler.getFirstUserData().then((value) {
      notify(
        UserDataLoadedEvent(user: value),
      );
      //notify(LoadingEvent(isLoading: isLoading));
    });
  }

  ///Pulsdaten-Übersicht generieren**
// Zum Laden der letzten 300 Datenpunkte Async methode im model benötigt
  void loadPulsedataList() {
    notify(LoadingEvent(isLoading: true));
    dbHandler.getPulsPoints().then((value) {
      notify(
        PulsedataLoadedEvent(points: value),
      ); //<-- Hier die async-Methode zum aufrufen der letzten 300 Datenpunkte aufrufen
      notify(LoadingEvent(isLoading: false));
    });
  }

  ///Aktivitätsdaten speichern
  void createActivity(
      String activityName, int timeSinceEpochFrom, int timeSinceEpochTill) {
    print(
        "Activity created: ${activityName}, from ${timeSinceEpochFrom} till ${timeSinceEpochTill}"); // DEBUG PRINT
    notify(LoadingEvent(isLoading: true));
    getCalories(timeSinceEpochFrom, timeSinceEpochTill).then((value) {
      ActivityData activity = ActivityData(
          activityName, timeSinceEpochFrom, timeSinceEpochTill, value);
      // Hier Setter vonModel aufrufen
      notify(ActivityCreatedEvent(activity));
      notify(LoadingEvent(isLoading: false));
    });
  }

  /// Aktuelle Pulsdaten Speichern und Anzeigen
  Future<void>
      startPulseDataCollection() async //Ruft currentPulseData als Isolate auf um als Background-Service zu agieren
  {
    ReceivePort receivePort = ReceivePort();
    Isolate.spawn(currentPulseData, receivePort.sendPort);
    receivePort.listen((data) {
      //get newest Pulsedata from Sensor/DB
      //print('Received data from background task: $data'); // Debug message

      if ((dbHandler.getDevice().isConnected)) {
          //    dbHandler.insertPulsDaten(
          //PulseDataPoint(data, DateTime.now().millisecondsSinceEpoch));
        dbHandler.getCurrentPuls().then((value) {
          if (!(value.isEmpty)) {
            notify(CurrentPulseLoadedEvent(point: value[0]));
          }
          if (dbHandler.getrecActivity() && (!popUpOpen)) {
            notify(activityErkanntEvent(erkannt: dbHandler.getrecActivity()));
          }
        });
      }

      // Für Praesentationszwecke

      //Notify für das Update
      // You can handle the data received from the background task here
    });
  }

  //hindert weitere notifies mit activityErkanntEvent
  void openPopUp() {
    popUpOpen = true;
  }

  //gibt weitere notifies mit activityErkanntEvent frei und released Erkannt-flag
  void closePopUp() {
    popUpOpen = true;
    dbHandler.setErkanntFalse();
  }

  Future<void> currentPulseData(SendPort mainSentPort) async {
    while (true) {
      mainSentPort.send(1);
      await Future.delayed(const Duration(
          seconds: 1)); //Wartet 1 Sekunde für den nächsten schleifendurchlauf
    }
  }

  void loadActivityData() {
    notify(LoadingEvent(isLoading: true));
    dbHandler.getActivities().then((value) {
      notify(
        ActivityLoadedEvent(
          activities: value,
        ),
      ); //<-- Hier die async-Methode zum aufrufen der letzten 300 Datenpunkte aufrufen
      notify(LoadingEvent(isLoading: false));
    });
  }

  Future<int> getCalories(int timeBegin, int timeEnd) async {
    UserData? user = await dbHandler.getFirstUserData();
    int age;
    double weight;
    Gender gender;
    double calories;
    int duration = timeBegin - timeEnd;
    double avgHeartRate = 0;

    if (user != null) {
      age = DateTime.now().year - user.birthDate.year;
      weight = user.weightInKG;
      gender = user.gender;
    } else {
      return (0);
    }

    List<PulseDataPoint> pulsList =
        await dbHandler.getPulsByDate(timeBegin, timeEnd);

    for (PulseDataPoint p in pulsList) {
      avgHeartRate += p.pulsValue;
    }
    avgHeartRate = avgHeartRate / pulsList.length;

    if (gender == Gender.m) {
      calories = ((-55.0969 +
                  (0.6309 * avgHeartRate) +
                  (0.1988 * weight) +
                  (0.2017 * age)) /
              4.184) *
          duration;
      return (calories.toInt());
    }

    if (gender == Gender.f) {
      calories = ((-20.4022 +
                  (0.4472 * avgHeartRate) +
                  (0.1263 * weight) +
                  (0.074 * age)) /
              4.184) *
          duration;
      return (calories.toInt());
    }

    if (gender == Gender.d) {
      calories = ((-37.74955 +
                  (0.53905 * avgHeartRate) +
                  (0.1612 * weight) +
                  (0.13785 * age)) /
              4.184) *
          duration;
      return (calories.toInt());
    }

    return (0);
  }

  int createRandomData(int startingValue) {
    //Creates random Pulse-Data in the range from 40-240 without large jumps.

    if (random.nextBool()) {
      startingValue += random.nextInt(5);
      if (startingValue > 240) {
        startingValue = 240;
      }

      return startingValue;
    } else {
      startingValue -= random.nextInt(5);
      if (startingValue < 40) {
        startingValue = 40;
      }
      return startingValue;
    }
  }
}
