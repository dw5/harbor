import 'dart:convert';

import 'package:flutter/services.dart' as services;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

import '../main.dart' as main;
import '../models.dart' as models;
import '../shared_ui.dart' as shared_ui;
import '../protocol.pb.dart' as protocol;

Future<void> handlePresentClipboard(
  final main.PolycentricModel state,
  final protocol.Pointer pointer,
  final BuildContext context,
) async {
  final link = await main.makeEventLink(
      state.db, pointer.system, pointer.process, pointer.logicalClock);

  await services.Clipboard.setData(services.ClipboardData(text: link));

  if (context.mounted) {
    shared_ui.showSnackBar(context, 'Copied to clipboard');
  }
}

Future<void> handlePresentShare(
  final main.PolycentricModel state,
  final protocol.Pointer pointer,
) async {
  final link = await main.makeEventLink(
      state.db, pointer.system, pointer.process, pointer.logicalClock);

  share_plus.Share.share(link);
}

class PresentPage extends StatelessWidget {
  final int identityIndex;
  final int claimIndex;

  const PresentPage(
      {Key? key, required this.identityIndex, required this.claimIndex})
      : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final state = context.watch<main.PolycentricModel>();
    final identity = state.identities[identityIndex];
    final claim = identity.claims[claimIndex];
    final encodedClaim = base64.encode(claim.pointer.writeToBuffer());
    final pointer = claim.pointer;

    return shared_ui.StandardScaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Request Verification'),
      ),
      children: [
        Center(
            child: Container(
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
        )),
        Center(
            child: Container(
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                child: Text(
                  identity.username,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ))),
        const Center(
            child: Text(
          "Wants you to verify this claim",
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 20,
            color: Colors.grey,
          ),
        )),
        const SizedBox(height: 10),
        Center(
            child: Text(
          models.ClaimType.claimTypeToString(claim.claim.claimType),
          style: const TextStyle(
            fontWeight: FontWeight.w200,
            fontSize: 24,
            color: Colors.white,
          ),
        )),
        const SizedBox(height: 10),
        ...shared_ui.renderClaim(claim),
        const SizedBox(height: 5),
        Center(
          child: QrImage(
            backgroundColor: Colors.white,
            data: encodedClaim,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
        const SizedBox(height: 15),
        const Center(
            child: Text(
          "Scan to Verify",
          style: TextStyle(
            fontWeight: FontWeight.w200,
            fontSize: 20,
            color: Colors.grey,
          ),
        )),
        shared_ui.StandardButtonGeneric(
          actionText: 'Copy',
          actionDescription: 'Share this unique code with others to verify',
          left: shared_ui.makeSVG('content_copy.svg', 'Copy'),
          onPressed: () async {
            await handlePresentClipboard(state, pointer, context);
          },
        ),
        shared_ui.StandardButtonGeneric(
          actionText: 'Share',
          actionDescription: 'Share code for verification',
          left: shared_ui.makeSVG('share.svg', 'Share'),
          onPressed: () async {
            await handlePresentShare(state, pointer);
          },
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
