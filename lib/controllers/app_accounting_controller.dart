import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:pr_api/model/accounting.dart';
import 'package:pr_api/model/user.dart';

import 'package:pr_api/utils/AppUtils.dart';
import 'package:pr_api/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';

class AppAccountingController extends ResourceController {
  AppAccountingController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> createAccounting(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() Accounting accounting) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final accountingQuery = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.user!.id).equalTo(id);
      final accountings = await accountingQuery.fetch();

      final accountingNumber = accountings.length;

      final fUser = Query<User>(managedContext)
        ..where((user) => user.id).equalTo(id);

      final user = await fUser.fetchOne();

      await managedContext.transaction((transaction) async {
        final qCreateAccounting = Query<Accounting>(transaction)
          ..values.numberOperation = accountingNumber + 1
          ..values.nameOperation = accounting.nameOperation
          ..values.description = accounting.description
          ..values.category = accounting.category
          ..values.dateOfOperation = DateTime.now().toString()
          ..values.transactionAmount = accounting.transactionAmount
          ..values.deleted = false
          ..values.user = user;

        await qCreateAccounting.insert();
      });

      return AppResponse.ok(message: 'Успешное создание учета');
    } catch (error) {
      return AppResponse.serverError(error, message: 'Ошибка создания учета');
    }
  }

  @Operation.get()
  Future<Response> getAccountings(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      {@Bind.query("deleted") int? deleted,
      @Bind.query("search") String? search,
      @Bind.query("limit") int? limit,
      @Bind.query("pages") int? pages}) async {
    try {
      final id = AppUtils.getIdFromHeader(header);

      Query<Accounting>? qAccountings;

      qAccountings = Query<Accounting>(managedContext)
        // ..where((accounting) => accounting.deleted).notEqualTo(true)
        ..where((accounting) => accounting.user!.id).equalTo(id);
      // ..offset = limit!
      // ..fetchLimit = pages!;

      if (limit != null && limit > 0) {
        qAccountings.fetchLimit = limit;
      }
      if (pages != null && pages > 0) {
        qAccountings.offset = pages;
      }

      // if (deleted == 0) {
      //   qAccountings.where((accounting) => accounting.deleted).equalTo(false);
      // } else{
      //   qAccountings.where((accounting) => accounting.deleted).equalTo(true);
      // }

      switch (deleted) {
        case 1:
          qAccountings.where((accounting) => accounting.deleted).equalTo(false);
          break;
        case 0:
          qAccountings
              .where((accounting) => accounting.deleted)
              .notEqualTo(false);
          break;
        default:
          qAccountings
              .where((accounting) => accounting.deleted)
              .notEqualTo(false);
          break;
      }

      if (search != null && search != '') {
        qAccountings
            .where((accounting) => accounting.nameOperation)
            .contains(search);
      }

      final List<Accounting> accountingList = await qAccountings.fetch();

      List notesJson = List.empty(growable: true);
      for (final accounting in accountingList) {
        accounting.removePropertiesFromBackingMap(["user", "id"]);
        notesJson.add(accounting.backing.contents);
      }

      if (notesJson.isEmpty) {
        return AppResponse.ok(message: "Учеты не найдены");
      }
      return AppResponse.ok(message: 'Успешное получение', body: notesJson);
      // return Response.ok(accountingList);
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.get("numberOperation")
  Future<Response> getAccounting(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("numberOperation") int numberOperation,
      {@Bind.query("delete") bool? delete}) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final deletedAccountingQuery = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.numberOperation)
            .equalTo(numberOperation)
        ..where((accounting) => accounting.user!.id).equalTo(currentUserId)
        ..where((accounting) => accounting.deleted).equalTo(true);
      final deletedAccounting = await deletedAccountingQuery.fetchOne();
      String message = "Запись получена";
      if (deletedAccounting != null && delete != null && delete) {
        deletedAccountingQuery.values.deleted = false;
        deletedAccountingQuery.update();
        message = "Учет восстановлен";
      }
      final currentAuthorId = AppUtils.getIdFromHeader(header);
      // final accountingg =
      //     await managedContext.fetchObjectWithID<Accounting>(numberOperation);
      final accountings = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.numberOperation)
            .equalTo(numberOperation)
        ..where((accounting) => accounting.user!.id).equalTo(currentUserId)
        ..where((accounting) => accounting.deleted).notEqualTo(true);
      final accountingg = await accountings.fetchOne();
      if (accountingg == null) {
        return AppResponse.ok(message: "Учет не найден");
      }
      // if (accountingg == null) {
      //   return AppResponse.ok(message: "Учет не найден");
      // }
      if (accountingg.user?.id != currentAuthorId ||
          accountingg.deleted == true) {
        return AppResponse.ok(message: "Нет доступа к учету");
      }
      accountingg.backing.removeProperty("user");
      return AppResponse.ok(
          body: accountingg.backing.contents, message: message);
    } catch (error) {
      return AppResponse.serverError(error, message: "Ошибка вывода учета");
    }
  }

  @Operation.put("numberOperation")
  Future<Response> updateAccounting(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("numberOperation") int numberOperation,
      @Bind.body() Accounting accounting) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final accountingQuery = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.numberOperation)
            .equalTo(numberOperation)
        ..where((accounting) => accounting.user!.id).equalTo(currentUserId)
        ..where((accounting) => accounting.deleted).equalTo(false);
      final accountingBase = await accountingQuery.fetchOne();
      if (accountingBase == null) {
        return AppResponse.ok(message: "Учет не найдет");
      }
      final qUpdateAccounting = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.id).equalTo(accountingBase.id)
        ..values.nameOperation = accounting.nameOperation
        ..values.description = accounting.description
        ..values.category = accounting.category
        ..values.transactionAmount = accounting.transactionAmount;
      await qUpdateAccounting.update();
      return AppResponse.ok(
          body: accounting.backing.contents,
          message: "Успешное обновление учета");
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка получения учета');
    }
  }

  @Operation.delete("numberOperation")
  Future<Response> deleteAccounting(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("numberOperation") int numberOperation,
  ) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final accountingQuery = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.numberOperation)
            .equalTo(numberOperation)
        ..where((accounting) => accounting.user!.id).equalTo(currentUserId)
        ..where((accounting) => accounting.deleted).equalTo(false);
      final accountingBase = await accountingQuery.fetchOne();
      if (accountingBase == null) {
        return AppResponse.ok(message: "Учет не найдет");
      }
      final qUpdateAccounting = Query<Accounting>(managedContext)
        ..where((accounting) => accounting.id).equalTo(accountingBase.id)
        ..values.deleted = true;
      await qUpdateAccounting.update();
      return AppResponse.ok(message: "Успешное удаление учета");
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка удаления учета');
    }
  }
}
