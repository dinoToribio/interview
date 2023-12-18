import 'package:balance/core/database/database.dart';
import 'package:balance/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'transactions_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<Database>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future insert({
    required String groupId,
    required bool isIncome,
    required int amount,
  }) {
    return into(transactions).insert(
      TransactionsCompanion.insert(
        id: const Uuid().v1(),
        createdAt: DateTime.now(),
        groupId: groupId,
        isIncome: Value(isIncome),
        amount: Value(amount),
      ),
    );
  }

  Future adjustAmount({
    required String id,
    required int amount,
  }) {
    final companion = TransactionsCompanion(amount: Value(amount));
    return (update(transactions)..where((tbl) => tbl.id.equals(id)))
        .write(companion);
  }

  Stream<List<Transaction>> watch({
    required String groupId,
  }) {
    return (select(transactions)..where((tbl) => tbl.groupId.equals(groupId)))
        .watch();
  }
}
