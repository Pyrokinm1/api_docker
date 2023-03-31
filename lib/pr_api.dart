import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:pr_api/controllers/app_accounting_controller.dart';
import 'package:pr_api/controllers/app_post_controller.dart';
import 'package:pr_api/controllers/app_token_contoller.dart';
import 'package:pr_api/controllers/app_user_contoller.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import 'controllers/app_auth_controller.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final PersistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), PersistentStore);
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user')
        .link(AppTokenContoller.new)!
        .link(() => AppUserConttolelr(managedContext))
    ..route('accounting/[:numberOperation]')
        .link(AppTokenContoller.new)!
        .link(() => AppAccountingController(managedContext));

  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? '12345678';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'newDB';
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
