import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder(
        stream: _groupsDao.watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text("Loading...");
          }

          return Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                ..._buildCreateGroup(),
                _buildGroups(snapshot),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCreateGroup() {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 25),
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _groupsDao.insert(_controller.text);
                  _controller.text = "";
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                "Create",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildGroups(snapshot) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: snapshot.requireData.length,
        itemBuilder: (context, index) => _buildGroup(
          snapshot.requireData[index],
        ),
      ),
    );
  }

  Widget _buildGroup(group) {
    return GestureDetector(
      onTap: () {
        GoRouterHelper(context).push(
          "/groups/${group.id}/${group.name}",
        );
      },
      child: Container(
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
                    group.name,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Balance: \$${group.balance.toString()}",
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}
