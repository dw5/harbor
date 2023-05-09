import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' as main;
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

    return Scaffold(
      appBar: AppBar(
        title: main.makeAppBarTitleText('Occupation'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text("Save"),
            onPressed: () async {
              await main.makeOccupationClaim(
                state.db,
                identity.processSecret,
                textControllerOrganization.text,
                textControllerRole.text,
                textControllerLocation.text,
              );

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
      body: Container(
        padding: main.scaffoldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            main.LabeledTextField(
              controller: textControllerOrganization,
              title: "Organization",
              label: "Stanford University, Amazon, Goldman Sachs, ...",
            ),
            const SizedBox(height: 20),
            main.LabeledTextField(
              controller: textControllerRole,
              title: "Role",
              label: "Professor of Physics, Engineer, Analyst, ...",
            ),
            const SizedBox(height: 20),
            main.LabeledTextField(
              controller: textControllerLocation,
              title: "Location",
              label: "Midwest, Massachusetts, New York City, ...",
            ),
          ],
        ),
      ),
    );
  }
}
