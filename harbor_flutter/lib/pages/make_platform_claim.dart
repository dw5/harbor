import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'add_token.dart';
import '../main.dart' as main;
import '../shared_ui.dart' as shared_ui;
import '../handle_validation.dart' as handle_validation;

class MakePlatformClaimPage extends StatefulWidget {
  final int identityIndex;
  final String claimType;

  const MakePlatformClaimPage(
      {Key? key, required this.identityIndex, required this.claimType})
      : super(key: key);

  @override
  State<MakePlatformClaimPage> createState() => _MakePlatformClaimPageState();
}

class _MakePlatformClaimPageState extends State<MakePlatformClaimPage> {
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<main.PolycentricModel>();
    final identity = state.identities[widget.identityIndex];

    return shared_ui.StandardScaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Make Claim'),
      ),
      children: [
        const SizedBox(height: 105),
        Center(child: shared_ui.claimTypeToVisual(widget.claimType)),
        const SizedBox(height: 25),
        Center(
            child: Text(
          widget.claimType,
          style: const TextStyle(
            fontSize: 30,
            color: Colors.white,
          ),
        )),
        const SizedBox(height: 100),
        shared_ui.LabeledTextField(
          controller: textController,
          title: "Profile information",
          label: "Profile handle",
        ),
        const SizedBox(height: 150),
        Align(
          alignment: AlignmentDirectional.center,
          child: shared_ui.OblongTextButton(
              text: 'Next step',
              onPressed: () async {
                if (!handle_validation.isHandleValid(
                    widget.claimType, textController.text)) {
                  shared_ui.showSnackBar(context, "Invalid handle");
                  return;
                }

                final claim = await state.db.transaction((transaction) async {
                  return await main.makePlatformClaim(
                      transaction,
                      identity.processSecret,
                      widget.claimType,
                      textController.text);
                });

                await state.mLoadIdentities();

                if (context.mounted) {
                  Navigator.push(context,
                      MaterialPageRoute<AddTokenPage>(builder: (context) {
                    return AddTokenPage(
                      claim: claim,
                      identityIndex: widget.identityIndex,
                    );
                  }));
                }
              }),
        ),
      ],
    );
  }
}
