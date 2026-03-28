import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<UserDatabaseService>(
    () => UserDatabaseService(),
  );
}
