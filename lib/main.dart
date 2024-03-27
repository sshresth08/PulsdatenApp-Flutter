import 'package:flutter/material.dart';
import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/model/userdata.dart';
import 'package:pulsdatenapp/viewmodel/userpage.viewmodel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'model/dbHandler.dart';
import 'view/theme.dart';
import 'view/homepage.view.dart';
import 'locator.dart';
import 'package:pulsdatenapp/viewmodel/homepage.viewmodel.dart';
import 'package:pulsdatenapp/viewmodel/activitypage.viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:math';

void main() async {
  // Initialize FFI
//print('0');
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  DBHandler.dbFactory = databaseFactoryFfi;

  setupLocator();

 // await initializeService();

  runApp(
    MultiProvider(
      providers: [
        //initialisieren der Provider für verschiedene Views
        Provider<HomeViewModel>(
            create: (_) => HomeViewModel(dbHandler: locator<DBHandler>())),
        Provider<ActivityViewModel>(
            create: (_) => ActivityViewModel(dbHandler: locator<DBHandler>())),
          Provider<UserViewModel>(
            create: (_) => UserViewModel(dbHandler: locator<DBHandler>())),
      ],
      child: const MyApp(),
    ),
  );

}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration:
          AndroidConfiguration(onStart: onStart, isForegroundMode: false));
}

void onStart(ServiceInstance service) async {
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  DBHandler dbHandler_Bg = new DBHandler();
double maxHR = 0;
  int currentHR = 0;
  //DateTime activityStart = DateTime(1970);
  int activityDuration = 0;
  UserData? user =await dbHandler_Bg.getFirstUserData();
  if(user != null)
  {
  int age = DateTime.now().year - user.birthDate.year;
   maxHR = 208 - (age*0.7);
  }
  BluetoothDevice device = BluetoothDevice.fromId(await dbHandler_Bg.getRemoteID());
  if (device.isConnected) {
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
currentHR= value[1]; 
                dbHandler_Bg.insertPulsDaten(PulseDataPoint(
                    currentHR, DateTime.now().millisecondsSinceEpoch));
if(maxHR != 0)
                    {
                      if(currentHR > maxHR/2)
                      {
                        activityDuration++;
                      }
                    }
              } else //HR als Uint16 übermittelt
              {
currentHR= (value[1]+value[2] <<8);
                dbHandler_Bg.insertPulsDaten(PulseDataPoint(
                    currentHR, DateTime.now().millisecondsSinceEpoch));
if(maxHR != 0)
                    {
                      if(currentHR > maxHR/2)
                      {
                        activityDuration++;
                      }
                    }
              }
              if( (currentHR <= maxHR/2))
              {
                if(activityDuration >= 300)
                {
                  dbHandler_Bg.setErkanntTrue();
                }
              }
            });
          }
        }
      }
    }
    }
    else{
    int i = 90;
    while (true) {
      i = createRandomData(i);
      dbHandler_Bg.insertPulsDaten(
          PulseDataPoint(i, DateTime.now().millisecondsSinceEpoch));
      await Future.delayed(const Duration(
          seconds: 1)); //Wartet 1 Sekunde für den nächsten schleifendurchlauf
    }
    }
  
}

int createRandomData(int startingValue) {
  //Creates random Pulse-Data in the range from 40-240 without large jumps.
  Random random = Random();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulsdaten',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
        ),
        child: HomePage(),
      ),
    );
  }
}
