import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

import 'automated_verification.dart';
import '../main.dart' as main;
import '../shared_ui.dart' as shared_ui;

class AddTokenPage extends StatelessWidget {
  final main.ClaimInfo claim;
  final int identityIndex;

  const AddTokenPage(
      {Key? key, required this.claim, required this.identityIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final token = convert.base64.encode(claim.pointer.system.key);

    return Scaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Add Token'),
      ),
      body: Container(
        padding: shared_ui.scaffoldPadding,
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                "Token",
                style: TextStyle(
                  fontFamily: 'inter',
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 5),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: shared_ui.tokenColor,
                foregroundColor: Colors.black,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  Text(token,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'inter',
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      "Tap to copy",
                      style: TextStyle(
                        fontFamily: 'inter',
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              onPressed: () async {
                await services.Clipboard.setData(
                    services.ClipboardData(text: token));

                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Copied')));
                }
              },
            ),
            const SizedBox(height: 450),
            Align(
              alignment: AlignmentDirectional.center,
              child: shared_ui.OblongTextButton(
                  text: 'Verify',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute<AutomatedVerificationPage>(
                            builder: (BuildContext context) {
                      return AutomatedVerificationPage(
                        claim: claim,
                        identityIndex: identityIndex,
                      );
                    }));
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
