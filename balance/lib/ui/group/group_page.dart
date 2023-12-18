import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/core/database/dao/transactions_dao.dart';
import 'package:balance/core/database/database.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupPage(this.groupId, this.groupName, {super.key});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  late final TransactionsDao _groupTransactionsDao =
      getIt.get<TransactionsDao>();

  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();

  void addIncome(snapshot) {
    if (_incomeController.text.isNotEmpty) {
      final amount = int.parse(_incomeController.text);
      final balance = snapshot.data?.balance ?? 0;
      _groupsDao.adjustBalance(
        balance + amount,
        widget.groupId,
      );
      _groupTransactionsDao.insert(
        groupId: widget.groupId,
        isIncome: true,
        amount: amount,
      );
      _incomeController.text = "";
    }
  }

  void addExpense(snapshot) {
    final amount = int.parse(_expenseController.text);
    final balance = snapshot.data?.balance ?? 0;
    _groupsDao.adjustBalance(
      balance - amount,
      widget.groupId,
    );
    _groupTransactionsDao.insert(
      groupId: widget.groupId,
      isIncome: false,
      amount: amount,
    );
    _expenseController.text = "";
  }

  void updateIncomeOrExpenseAmount({
    required Transaction transaction,
    required TextEditingController controller,
    required List<Transaction> transactions,
  }) {
    final amount = int.parse(controller.text);
    int balance = 0;
    //adjust amount in the transaction;
    _groupTransactionsDao.adjustAmount(
      id: transaction.id,
      amount: amount,
    );
    //compute all amount in transactions
    for (var i = 0; i < transactions.length; i++) {
      Transaction item = transactions[i];
      if (item.id == transaction.id) {
        item = item.copyWith(amount: amount);
      }
      item.isIncome ? balance += item.amount : balance -= item.amount;
    }
    //adjust balnce of the group
    _groupsDao.adjustBalance(
      balance,
      widget.groupId,
    );
    controller.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder(
        stream: _groupsDao.watchGroup(widget.groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text("Loading...");
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                ..._buildBalance(snapshot),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAddIncomeDialog(
                          snapshot,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Add Income",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAddExpensesDialog(
                          snapshot,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Add Expense",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildTransactions(),
              ],
            ),
          );
        },
      ),
    );
  }

  _showAddIncomeDialog(snapshot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(20),
          title: const Text(
            'Add Income',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              suffixText: "\$",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                addIncome(snapshot);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _showAddExpensesDialog(snapshot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(20),
          title: const Text(
            "Add Expense",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _expenseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              suffixText: "\$",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                addExpense(snapshot);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _showEditAmountDialog({
    required Transaction transaction,
    required TextEditingController controller,
    required List<Transaction> transactions,
  }) {
    controller.text = transaction.amount.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(20),
          title: Text(
            "Edit ${transaction.isIncome ? "Income" : "Expense"} Amount",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              suffixText: "\$",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Update',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                updateIncomeOrExpenseAmount(
                  transaction: transaction,
                  controller: controller,
                  transactions: transactions,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildBalance(snapshot) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "\$${snapshot.data?.balance.toString() ?? ''}",
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Balance",
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildTransactions() {
    return Expanded(
      child: StreamBuilder(
        stream: _groupTransactionsDao.watch(groupId: widget.groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text("Loading...");
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: snapshot.requireData.length,
            itemBuilder: (context, index) => _buildTransaction(
              transaction: snapshot.requireData[index],
              transactions: snapshot.requireData,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransaction({
    required Transaction transaction,
    required List<Transaction> transactions,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${transaction.isIncome ? "+" : "-"} \$${transaction.amount.toString()}",
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transaction.isIncome ? "Income" : "Expense",
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditAmountDialog(
              transaction: transaction,
              controller:
                  transaction.isIncome ? _incomeController : _expenseController,
              transactions: transactions,
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.blue,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}
