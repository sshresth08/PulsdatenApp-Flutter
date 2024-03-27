import 'dart:isolate';

import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/model/userdata.dart';

import 'events.dart';
import 'view_model.dart';
import 'package:pulsdatenapp/model/activitydata.dart';
import 'package:pulsdatenapp/model/dbHandler.dart';

class ActivityViewModel extends EventViewModel {
  final DBHandler dbHandler; // <-- Model mit Daten
  ActivityViewModel({
    required this.dbHandler,
  }) {} // <-- Konstruktor initalisieren

//Pulsdaten-Übersicht generieren
// Zum Laden der letzten 300 Datenpunkte Async methode im model benötigt
  void loadPulsedataList() {
    notify(LoadingEvent(isLoading: true));
    dbHandler.getPulsDataForLast12Hours().then((value) {
      notify(
        PulsedataLoadedEvent(
          points: value,
        ),
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
      dbHandler.insertActivity(activity);
      notify(ActivityCreatedEvent(activity));
      notify(LoadingEvent(isLoading: false));
    });
  }

  Future<int> getCalories(int timeBegin, int timeEnd) async {
    UserData? user = await dbHandler.getFirstUserData();
    int age;
    double weight;
    Gender gender;
    double calories;
    int duration = Duration(milliseconds: timeEnd - timeBegin).inMinutes;
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

  void getLast24hActivity() {
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

  ///// Aktuelle Pulsdaten Speichern und Anzeigen
  //Future<void>
  //    startPulseDataCollection() async //Ruft currentPulseData als Isolate auf um als Background-Service zu agieren
  //{
  //  ReceivePort receivePort = ReceivePort();
  //  Isolate.spawn(currentPulseData, receivePort.sendPort);
  //  receivePort.listen((data) {
  //    //get newest Pulsedata from Sensor/DB
  //    //print('Received data from background task: $data'); // Debug message
  //    //Erzeugt PulseDataPoint aus Daten von Sensor/DB
  //    dbHandler.insertPulsDaten(point); // push Pulsedata to Model
  //    notify(CurrentPulseLoadedEvent(point: point)); //Notify für das Update
  //    // You can handle the data received from the background task here
  //  });
  //}

  Future<void> currentPulseData(SendPort mainSentPort) async {
    int i = 50;
    while (true) {
      mainSentPort.send(i);
      i++;
      await Future.delayed(const Duration(
          seconds: 1)); //Wartet 1 Sekunde für den nächsten schleifendurchlauf
    }
  }
}
