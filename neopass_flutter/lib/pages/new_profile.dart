import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' as main;
import 'new_or_import_profile.dart';

class NewProfilePage extends StatefulWidget {
  const NewProfilePage({Key? key}) : super(key: key);

  @override
  State<NewProfilePage> createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<NewProfilePage> {
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<main.PolycentricModel>();

    return Scaffold(
      body: Container(
          padding: main.scaffoldPadding,
          child: Column(
            children: [
              const SizedBox(height: 150),
              main.neopassLogoAndText,
              const SizedBox(height: 100),
              main.LabeledTextField(
                controller: textController,
                title: "Profile Name",
                label: "Alice, Bob, ...",
              ),
              const SizedBox(height: 120),
              Container(
                alignment: Alignment.center,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: main.blueButtonColor,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () async {
                    if (textController.text.isEmpty) {
                      return;
                    }
                    final identity = await main.createNewIdentity(state.db);
                    await main.setUsername(
                        state.db, identity, textController.text);
                    await state.mLoadIdentities();
                    if (context.mounted) {
                      Navigator.push(context,
                          MaterialPageRoute<NewOrImportProfilePage>(
                              builder: (context) {
                        return const NewOrImportProfilePage();
                      }));
                    }
                  },
                  child: const Text(
                    "Create Profile",
                    style: TextStyle(
                      fontFamily: 'inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(flex: 1, child: Container()),
              main.futoLogoAndText,
              const SizedBox(height: 50),
            ],
          )),
    );
  }
}
