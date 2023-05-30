import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

import 'new_or_import_profile.dart';
import '../main.dart' as main;
import '../shared_ui.dart' as shared_ui;
import '../api_methods.dart' as api_methods;
import '../synchronizer.dart' as synchronizer;
import '../protocol.pb.dart' as protocol;
import '../logger.dart';

class AutomatedVerificationPage extends StatefulWidget {
  final main.ClaimInfo claim;
  final int identityIndex;

  const AutomatedVerificationPage(
      {Key? key, required this.claim, required this.identityIndex})
      : super(key: key);

  @override
  State<AutomatedVerificationPage> createState() =>
      _AutomatedVerificationPageState();
}

class _AutomatedVerificationPageState extends State<AutomatedVerificationPage> {
  int page = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      doVerification(context);
    });
  }

  Future<void> doVerification(BuildContext context) async {
    setState(() {
      page = 0;
    });

    try {
      final state = Provider.of<main.PolycentricModel>(context, listen: false);
      final identity = state.identities[widget.identityIndex];

      final public = await identity.processSecret.system.extractPublicKey();
      final systemProto = protocol.PublicKey();
      systemProto.keyType = fixnum.Int64(1);
      systemProto.key = public.bytes;

      await synchronizer.backfillServers(state.db, systemProto);

      await api_methods.requestVerification(
        widget.claim.pointer,
        widget.claim.claimType,
      );

      setState(() {
        page = 1;
      });
    } catch (err) {
      logger.e(err);

      setState(() {
        page = 2;
      });

      shared_ui.errorDialog(context, err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [
      const SizedBox(height: 100),
      shared_ui.neopassLogoAndText,
      const SizedBox(height: 150),
    ];

    if (page == 0) {
      columnChildren.addAll([
        const CircularProgressIndicator(
          color: Colors.white,
        ),
        const SizedBox(height: 20),
        const Text(
          "Waiting for verification",
          style: TextStyle(
            fontFamily: 'inter',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ]);
    } else if (page == 1) {
      columnChildren.addAll([
        const Icon(
          Icons.done,
          size: 75,
          semanticLabel: "success",
          color: Colors.green,
        ),
        const Text(
          "Success!",
          style: TextStyle(
            fontFamily: 'inter',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 120),
        Align(
          alignment: AlignmentDirectional.center,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: shared_ui.blueButtonColor,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              Navigator.push(context,
                  MaterialPageRoute<NewOrImportProfilePage>(builder: (context) {
                return const NewOrImportProfilePage();
              }));
            },
          ),
        ),
      ]);
    } else if (page == 2) {
      columnChildren.addAll([
        const Icon(
          Icons.close,
          size: 75,
          semanticLabel: "failure",
          color: Colors.red,
        ),
        const Text(
          "Verification failed.",
          style: TextStyle(
            fontFamily: 'inter',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 120),
        Align(
          alignment: AlignmentDirectional.center,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: shared_ui.blueButtonColor,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Retry verification',
              style: TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              doVerification(context);
            },
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Verifying Claim'),
      ),
      body: Container(
        padding: shared_ui.scaffoldPadding,
        width: double.infinity,
        child: Column(
          children: columnChildren,
        ),
      ),
    );
  }
}
