import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'present.dart';
import 'add_token.dart';
import '../main.dart' as main;
import '../shared_ui.dart' as shared_ui;

const Set<String> manualVerificationClaimTypes = {
  "Generic",
  "Skill",
  "Occupation"
};

class ClaimPage extends StatefulWidget {
  final int identityIndex;
  final int claimIndex;

  const ClaimPage(
      {Key? key, required this.identityIndex, required this.claimIndex})
      : super(key: key);

  @override
  State<ClaimPage> createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<main.PolycentricModel>();
    final identity = state.identities[widget.identityIndex];
    final claim = identity.claims[widget.claimIndex];

    return Scaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Claim'),
      ),
      body: Container(
        padding: shared_ui.scaffoldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 50,
                foregroundImage:
                    identity.avatar != null ? identity.avatar!.image : null,
                child: const SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Icon(Icons.person),
                  ),
                ),
              ),
            ),
            Container(
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                child: Text(
                  identity.username,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'inter',
                    fontWeight: FontWeight.w300,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                )),
            const Text(
              "Claims",
              style: TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w300,
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              claim.claimType,
              style: const TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w200,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              claim.text,
              style: const TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w200,
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              alignment: AlignmentDirectional.centerStart,
              child: const Text(
                "Request Verification",
                style: TextStyle(
                  fontFamily: 'inter',
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (!manualVerificationClaimTypes.contains(claim.claimType))
              shared_ui.StandardButtonGeneric(
                actionText: 'Automated',
                actionDescription:
                    'Get an automated authority to vouch for this claim',
                left: shared_ui.makeSVG('smart_toy.svg', 'Automated'),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute<AddTokenPage>(builder: (context) {
                    return AddTokenPage(
                      claim: claim,
                    );
                  }));
                },
              ),
            shared_ui.StandardButtonGeneric(
              actionText: 'Manual',
              actionDescription:
                  'Get a manual authority to vouch for this claim',
              left: shared_ui.makeSVG('refresh.svg', 'Manual'),
              onPressed: () async {
                Navigator.push(context,
                    MaterialPageRoute<PresentPage>(builder: (context) {
                  return PresentPage(
                    identityIndex: widget.identityIndex,
                    claimIndex: widget.claimIndex,
                  );
                }));
              },
            ),
          ],
        ),
      ),
    );
  }
}
