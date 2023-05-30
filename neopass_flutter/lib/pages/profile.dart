import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

import '../main.dart' as main;
import '../protocol.pb.dart' as protocol;
import '../queries.dart' as queries;
import '../shared_ui.dart' as shared_ui;
import 'backup.dart';
import 'claim.dart';
import 'create_claim.dart';
import 'new_or_import_profile.dart';
import 'vouch.dart';

class ProfilePage extends StatefulWidget {
  final int identityIndex;

  const ProfilePage({Key? key, required this.identityIndex}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController usernameController = TextEditingController();
  String newUsername = "";

  Future<void> editUsername(
    BuildContext context,
    main.PolycentricModel state,
    main.ProcessSecret identity,
  ) async {
    await showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Edit Username"),
            content: TextField(
              onChanged: (next) {
                setState(() {
                  newUsername = next;
                });
              },
              controller: usernameController,
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Submit"),
                onPressed: () async {
                  if (usernameController.text.isEmpty) {
                    return;
                  }

                  await state.db.transaction((transaction) async {
                    await main.setUsername(
                        transaction, identity, usernameController.text);
                  });

                  await state.mLoadIdentities();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  final TextEditingController descriptionController = TextEditingController();
  String newDescription = "";

  Future<void> editDescription(
    BuildContext context,
    main.PolycentricModel state,
    main.ProcessSecret identity,
  ) async {
    await showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Edit Description"),
            content: TextField(
              onChanged: (next) {
                setState(() {
                  newDescription = next;
                });
              },
              controller: descriptionController,
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Submit"),
                onPressed: () async {
                  if (descriptionController.text.isEmpty) {
                    return;
                  }

                  await state.db.transaction((transaction) async {
                    await main.setDescription(
                        transaction, identity, descriptionController.text);
                  });

                  await state.mLoadIdentities();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  Future<void> deleteAccountDialog(
    BuildContext context,
    main.PolycentricModel state,
    main.ProcessInfo identity,
  ) async {
    await showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Account"),
            content: const Text("Are you sure you want to delete your account? "
                "This action cannot be undone."),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () async {
                  final public =
                      await identity.processSecret.system.extractPublicKey();

                  await state.db.transaction((transaction) async {
                    await queries.deleteIdentity(transaction, public.bytes,
                        identity.processSecret.process);
                  });

                  if (context.mounted) {
                    Navigator.push(context,
                        MaterialPageRoute<NewOrImportProfilePage>(
                            builder: (context) {
                      return const NewOrImportProfilePage();
                    }));
                  }

                  await state.mLoadIdentities();
                },
              ),
            ],
          );
        });
  }

  Future<void> deleteClaimDialog(
    BuildContext context,
    main.PolycentricModel state,
    main.ProcessInfo identity,
    protocol.Pointer pointer,
  ) async {
    await showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Claim"),
            content: const Text("Are you sure you want to delete this claim? "
                "This action cannot be undone."),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text("Delete"),
                  onPressed: () async {
                    await state.db.transaction((transaction) async {
                      await main.deleteEvent(
                          transaction, identity.processSecret, pointer);
                    });

                    await state.mLoadIdentities();

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<main.PolycentricModel>();
    final identity = state.identities[widget.identityIndex];

    List<StatelessWidget> renderClaims(
      List<main.ClaimInfo> claims,
    ) {
      List<StatelessWidget> result = [];

      for (var i = 0; i < claims.length; i++) {
        result.add(shared_ui.StandardButtonGeneric(
          actionText: claims[i].claimType,
          actionDescription: claims[i].text,
          left: Container(
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            child: shared_ui.claimTypeToVisual(claims[i].claimType),
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute<ClaimPage>(builder: (context) {
              return ClaimPage(
                identityIndex: widget.identityIndex,
                claimIndex: i,
              );
            }));
          },
          onDelete: () async {
            deleteClaimDialog(context, state, identity, claims[i].pointer);
          },
        ));
      }

      return result;
    }

    List<Widget> listViewChildren = [
      InkWell(
        child: Container(
          margin: const EdgeInsets.only(top: 50),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 50,
            foregroundImage:
                identity.avatar != null ? identity.avatar!.image : null,
            child: const Text(
              'Tap to set avatar',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        onTap: () async {
          file_picker.FilePickerResult? result =
              await file_picker.FilePicker.platform.pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: ['png', 'jpg'],
          );

          if (result != null) {
            final bytes = await File(result.files.single.path!).readAsBytes();

            await state.db.transaction((transaction) async {
              final pointer = await main.publishBlob(
                transaction,
                identity.processSecret,
                "image/jpeg",
                bytes,
              );

              await main.setAvatar(
                transaction,
                identity.processSecret,
                pointer,
              );
            });

            await state.mLoadIdentities();
          }
        },
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 30),
          Text(
            identity.username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'inter',
              fontWeight: FontWeight.w300,
              fontSize: 32,
              color: Colors.white,
            ),
          ),
          OutlinedButton(
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              semanticLabel: "edit",
              color: Colors.white,
            ),
            onPressed: () {
              editUsername(context, state, identity.processSecret);
            },
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          "About",
          style: TextStyle(
            fontFamily: 'inter',
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: shared_ui.tokenColor,
          foregroundColor: Colors.black,
        ),
        child: Stack(children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(identity.description,
                    style: const TextStyle(
                      fontFamily: 'inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    )),
              ),
              const SizedBox(height: 10),
            ],
          ),
          const Positioned(
            right: 0,
            bottom: 10,
            child: Icon(
              Icons.edit_outlined,
              size: 15,
              semanticLabel: "edit",
              color: Colors.white,
            ),
          ),
        ]),
        onPressed: () {
          editDescription(context, state, identity.processSecret);
        },
      ),
    ];

    if (identity.claims.isNotEmpty) {
      listViewChildren.addAll([
        const SizedBox(height: 10),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'Claims',
            style: TextStyle(
              fontFamily: 'inter',
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
        ),
      ]);
      listViewChildren.addAll(renderClaims(identity.claims));
    }

    listViewChildren.addAll([
      const SizedBox(height: 10),
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'Actions',
          style: TextStyle(
            fontFamily: 'inter',
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ),
      shared_ui.StandardButtonGeneric(
        actionText: 'Make a claim',
        actionDescription: 'Make a new claim for your profile',
        left: shared_ui.makeSVG('person_add.svg', 'Claim'),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute<CreateClaimPage>(builder: (context) {
            return CreateClaimPage(identityIndex: widget.identityIndex);
          }));
        },
      ),
      shared_ui.StandardButtonGeneric(
        actionText: 'Vouch for a claim',
        actionDescription: 'Vouch for someone elses claim',
        left: shared_ui.makeSVG('check_box.svg', 'Vouch'),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute<VouchPage>(builder: (context) {
            return VouchPage(processSecret: identity.processSecret);
          }));
        },
      ),
      shared_ui.StandardButtonGeneric(
        actionText: 'Change account',
        actionDescription: 'Switch to a different account',
        left: shared_ui.makeSVG('switch_account.svg', 'Switch'),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute<NewOrImportProfilePage>(builder: (context) {
            return const NewOrImportProfilePage();
          }));
        },
      ),
      shared_ui.StandardButtonGeneric(
        actionText: 'Backup',
        actionDescription: 'Make a backup of your identity',
        left: shared_ui.makeSVG('save.svg', 'Backup'),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute<BackupPage>(builder: (context) {
            return BackupPage(processSecret: identity.processSecret);
          }));
        },
      ),
      shared_ui.StandardButtonGeneric(
        actionText: 'Delete account',
        actionDescription: 'Permanently delete account from this device',
        left: shared_ui.makeSVG('delete.svg', 'Delete'),
        onPressed: () async {
          deleteAccountDialog(context, state, identity);
        },
      ),
      const SizedBox(height: 30),
    ]);

    return Scaffold(
        body: Container(
      padding: shared_ui.scaffoldPadding,
      child: SingleChildScrollView(
        child: Column(
          children: listViewChildren,
        ),
      ),
    ));
  }
}
