import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:file_picker/file_picker.dart' as FilePicker;

import '../main.dart' as Main;
import '../protocol.pb.dart' as Protocol;
import 'backup.dart';

class ProfilePage extends StatefulWidget {
  final int identityIndex;

  const ProfilePage({Key? key, required this.identityIndex}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<StatelessWidget> _renderClaims(List<Main.ClaimInfo> claims) {
    List<StatelessWidget> result = [];

    for (var i = 0; i < claims.length; i++) {
      result.add(Main.StandardButton(
        actionText: claims[i].claimType,
        actionDescription: claims[i].text,
        icon: Icons.format_quote,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Main.ClaimPage(
              identityIndex: widget.identityIndex,
              claimIndex: i,
            );
          }));
        },
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    var state2 = context.watch<Main.PolycentricModel>();
    var identity2 = state2.identities[widget.identityIndex];

    List<StatelessWidget> listViewChildren = [
      Container(
        margin: const EdgeInsets.only(left: 20),
        child: Text(
          'Claims',
          textAlign: TextAlign.left,
          style: TextStyle(
            height: 1.2,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    ];

    listViewChildren.addAll(_renderClaims(identity2.claims));

    listViewChildren.addAll([
      Container(
        margin: const EdgeInsets.only(left: 20, top: 20),
        child: Text(
          'Other',
          textAlign: TextAlign.left,
          style: TextStyle(
            height: 1.2,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      Main.StandardButton(
        actionText: 'Make a claim',
        actionDescription: 'Make a new claim for your profile',
        icon: Icons.person_add,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Main.CreateClaimPage(identityIndex: widget.identityIndex);
          }));
        },
      ),
      Main.StandardButton(
        actionText: 'Vouch for a claim',
        actionDescription: 'Vouch for someone elses claim',
        icon: Icons.video_call,
        onPressed: () async {
          try {
            final String rawScan = await FlutterBarcodeScanner.scanBarcode(
                "#ff6666", 'cancel', false, ScanMode.QR);
            final List<int> buffer = base64.decode(rawScan);
            final Protocol.Pointer pointer =
                Protocol.Pointer.fromBuffer(buffer);

            await Main.makeVouch(state2.db, identity2.processSecret, pointer);
          } catch (err) {
            print(err);
          }
        },
      ),
      Main.StandardButton(
        actionText: 'Change account',
        actionDescription: 'Switch to a different account',
        icon: Icons.switch_account,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Main.NewOrImportProfilePage();
          }));
        },
      ),
      Main.StandardButton(
        actionText: 'Backup',
        actionDescription: 'Make a backup of your identity',
        icon: Icons.save,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return BackupPage();
          }));
        },
      ),
      Main.StandardButton(
        actionText: 'Delete account',
        actionDescription: 'Permanently account from this device',
        icon: Icons.delete,
        onPressed: () async {
          final public =
              await identity2.processSecret.system.extractPublicKey();

          await Main.deleteIdentity(
              state2.db, public.bytes, identity2.processSecret.process);

          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Main.NewOrImportProfilePage();
          }));

          await state2.mLoadIdentities();
        },
      ),
    ]);

    return Scaffold(
      body: Column(
        children: [
          InkWell(
            child: Container(
              margin: const EdgeInsets.only(top: 50),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 50,
                foregroundImage:
                    identity2.avatar != null ? identity2.avatar!.image : null,
              ),
            ),
            onTap: () async {
              FilePicker.FilePickerResult? result =
                  await FilePicker.FilePicker.platform.pickFiles(
                type: FilePicker.FileType.custom,
                allowedExtensions: ['png', 'jpg'],
              );

              if (result != null) {
                final bytes =
                    await File(result.files.single.path!).readAsBytes();

                final pointer = await Main.publishBlob(
                  state2.db,
                  identity2.processSecret,
                  "image/jpeg",
                  bytes,
                );

                await Main.setAvatar(
                  state2.db,
                  identity2.processSecret,
                  pointer,
                );

                print("set avatar");
              }
            },
          ),
          Container(
              margin: const EdgeInsets.only(bottom: 30, top: 10),
              child: Text(
                identity2.username,
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.2,
                  fontSize: 30,
                  color: Colors.white,
                ),
              )),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: listViewChildren,
            ),
          ),
        ],
      ),
    );
  }
}


