import 'package:pulsdatenapp/model/dbHandler.dart';
import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/model/userdata.dart';
import 'package:pulsdatenapp/viewmodel/events.dart';
import 'package:pulsdatenapp/viewmodel/view_model.dart';

class UserViewModel extends EventViewModel {

  final DBHandler dbHandler; // <-- Model mit Daten
  UserViewModel({
    required this.dbHandler,
  }) {} // <-- Konstruktor initalisieren

    void getRestingHeartRate() {
    dbHandler.getPulsPoints().then((value) {
      List<PulseDataPoint> lastFewSeconds = value.sublist(0,
          15); //<-- Hier die async-Methode zum aufrufen der letzten 15 Datenpunkte aufrufen
      int avg = 0;
      for (PulseDataPoint p in lastFewSeconds) {
        avg += p.pulsValue;
      }
      avg = avg ~/ lastFewSeconds.length;
      notify(rhrLoadedEvent(rhr: avg));
      notify(LoadingEvent(isLoading: false));
    });
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

  ///UserDaten Speichern
  void createUser(String name, DateTime birthDate, double heightInCM,
      double weightInKG, Gender gender, int dailyGoal, int restingHeartRate) {
    notify(LoadingEvent(isLoading: true));
    UserData user = UserData(name, birthDate, heightInCM, weightInKG, gender,
        dailyGoal, restingHeartRate);
    dbHandler.insertUserData(user); // Hier Setter vonModel aufrufen
    notify(UserCreatedEvent(user));
    notify(LoadingEvent(isLoading: false));
  }
}