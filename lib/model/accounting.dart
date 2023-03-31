import 'package:conduit/conduit.dart';
import 'package:pr_api/model/user.dart';
import 'package:conduit_core/conduit_core.dart';

class Accounting extends ManagedObject<_Accounting> implements _Accounting {}

class _Accounting {
  @primaryKey
  int? id;
  @Column(nullable: false)
  int? numberOperation;
  @Column(unique: true, indexed: true)
  String? nameOperation;
  @Column(nullable: false)
  String? description;
  @Column(nullable: false)
  String? category;
  @Column(nullable: false)
  String? dateOfOperation;
  @Column(nullable: false)
  int? transactionAmount;
  @Column(nullable: false)
  bool? deleted;
  @Relate(#accountingList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
}
