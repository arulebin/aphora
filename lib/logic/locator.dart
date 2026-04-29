import 'package:aphora/data/aphora_api_service.dart';
import 'package:aphora/data/database_service/booking_database_service.dart';
import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

class Locator extends ChangeNotifier {
  Locator._internal();
  static final Locator _instance = Locator._internal();
  factory Locator() => _instance;

  static UserDatabaseService get userDatabaseService =>
      userDatabaseServiceInstance;
  static BookingDatabaseService get bookingDatabaseService =>
      bookingDatabaseServiceInstance;
  static AphoraApiService get aphoraApiService => aphoraApiServiceInstance;

  static late UserDatabaseService userDatabaseServiceInstance;
  static late BookingDatabaseService bookingDatabaseServiceInstance;
  static late AphoraApiService aphoraApiServiceInstance;

  static void setUpServices() {
    if (!GetIt.instance.isRegistered<Locator>()) {
      GetIt.instance.registerSingleton<Locator>(Locator());
    }
    GetIt.instance.registerLazySingleton<UserDatabaseService>(
      () => UserDatabaseService(),
    );
    GetIt.instance.registerLazySingleton<BookingDatabaseService>(
      () => BookingDatabaseService(),
    );
    GetIt.instance.registerLazySingleton<AphoraApiService>(
      () => AphoraApiService(),
    );

    userDatabaseServiceInstance = GetIt.instance<UserDatabaseService>();
    bookingDatabaseServiceInstance = GetIt.instance<BookingDatabaseService>();
    aphoraApiServiceInstance = GetIt.instance<AphoraApiService>();
  }

  static Locator get instance => GetIt.I<Locator>();
}
