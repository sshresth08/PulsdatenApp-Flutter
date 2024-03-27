import 'package:get_it/get_it.dart';
import 'package:pulsdatenapp/model/dbHandler.dart';


final GetIt locator = GetIt.instance;

void setupLocator() {

  locator.registerLazySingleton<DBHandler>(() => DBHandler());
  
}