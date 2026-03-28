import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

class Locator extends ChangeNotifier {
  Locator._internal();
  static final Locator _instance = Locator._internal();
  factory Locator() => _instance;

  static void setUpServices() {
    if (!GetIt.instance.isRegistered<Locator>()) {
      GetIt.instance.registerSingleton<Locator>(Locator());
    }
    GetIt.instance.registerLazySingleton<UserDatabaseService>(
      () => UserDatabaseService(),
    );
    // GetIt.instance.registerLazySingleton(() => StartupServices());
  }

  static Locator get instance => GetIt.I<Locator>();
  // static StartupServices get startupServices => GetIt.I<StartupServices>();
  static UserDatabaseService get userDatabaseService =>
      GetIt.I<UserDatabaseService>();
}
