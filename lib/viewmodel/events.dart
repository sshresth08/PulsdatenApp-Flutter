import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pulsdatenapp/model/activitydata.dart';
import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/model/userdata.dart';

import 'observer.dart';

class LoadingEvent extends ViewEvent {
  bool isLoading;

  LoadingEvent({required this.isLoading}) : super("LoadingEvent");
}

class PulsedataLoadedEvent extends ViewEvent {
  final List<PulseDataPoint> points;

  PulsedataLoadedEvent({required this.points}) : super("PulseDataLoadedEvent");
}

class UserDataLoadedEvent extends ViewEvent {
  final UserData? user;

  UserDataLoadedEvent({required this.user}) : super("UserDataLoadedEvent");
}

// should be emitted when
class UserCreatedEvent extends ViewEvent {
  final UserData userData;

  UserCreatedEvent(this.userData) : super("UserCreatedEvent");
}

class ActivityCreatedEvent extends ViewEvent {
  final ActivityData activityData;

  ActivityCreatedEvent(this.activityData) : super("ActivityCreatedEvent");
}

class ActivityLoadedEvent extends ViewEvent {
  final List<ActivityData> activities;

  ActivityLoadedEvent({required this.activities})
      : super("ActivityLoadedEvent");
}

class CurrentPulseLoadedEvent extends ViewEvent {
  final PulseDataPoint point;

  CurrentPulseLoadedEvent({required this.point})
      : super("currentPulseLoadedEvent");
}

class BLEDevicesLoadedEvent extends ViewEvent {
  final List<BluetoothDevice> result;

  BLEDevicesLoadedEvent({required this.result})
      : super("BLEDevicesLoadedEvent");
}

class rhrLoadedEvent extends ViewEvent {
  final int rhr;

  rhrLoadedEvent({required this.rhr})
      : super("rhrLoadedEvent");
}

class activityErkanntEvent extends ViewEvent {
  final bool erkannt;

  activityErkanntEvent({required this.erkannt})
      : super("activityErkanntEvent");
}
