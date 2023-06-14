import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' as main;
import '../shared_ui.dart' as shared_ui;
import 'profile.dart';

class CreateOccupationClaimPage extends StatefulWidget {
  final int identityIndex;

  const CreateOccupationClaimPage({Key? key, required this.identityIndex})
      : super(key: key);

  @override
  State<CreateOccupationClaimPage> createState() =>
      _CreateOccupationClaimPageState();
}

class _CreateOccupationClaimPageState extends State<CreateOccupationClaimPage> {
  TextEditingController textControllerOrganization = TextEditingController();
  TextEditingController textControllerRole = TextEditingController();
  TextEditingController textControllerLocation = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<main.PolycentricModel>();
    final identity = state.identities[widget.identityIndex];

    return shared_ui.StandardScaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Occupation'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text("Save"),
            onPressed: () async {
              if (textControllerOrganization.text.isEmpty &&
                  textControllerRole.text.isEmpty &&
                  textControllerLocation.text.isEmpty) {
                shared_ui.showSnackBar(context, "You must fill out a field");
                return;
              }

              await state.db.transaction((transaction) async {
                await main.makeOccupationClaim(
                  transaction,
                  identity.processSecret,
                  textControllerOrganization.text,
                  textControllerRole.text,
                  textControllerLocation.text,
                );
              });

              await state.mLoadIdentities();

              if (context.mounted) {
                Navigator.push(context,
                    MaterialPageRoute<ProfilePage>(builder: (context) {
                  return ProfilePage(
                    identityIndex: widget.identityIndex,
                  );
                }));
              }
            },
          ),
        ],
      ),
      children: [
        const SizedBox(height: 20),
        shared_ui.LabeledTextField(
          controller: textControllerOrganization,
          title: "Organization",
          label: "Stanford University, Amazon, Goldman Sachs, ...",
        ),
        const SizedBox(height: 20),
        shared_ui.LabeledTextField(
          controller: textControllerRole,
          title: "Role",
          label: "Professor of Physics, Engineer, Analyst, ...",
        ),
        const SizedBox(height: 20),
        shared_ui.LabeledTextField(
          controller: textControllerLocation,
          title: "Location",
          label: "Midwest, Massachusetts, New York City, ...",
        ),
      ],
    );
  }
}
