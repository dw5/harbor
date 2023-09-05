import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'profile.dart';
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
  String errorMessage = "";

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
      errorMessage = "";
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
        widget.claim.claim.claimType,
      );

      setState(() {
        page = 1;
      });
    } on api_methods.AuthorityException catch (err) {
      logger.e(err);

      setState(() {
        page = 2;
        errorMessage = err.message;
      });
    } catch (err) {
      logger.e(err);

      setState(() {
        page = 2;
        errorMessage =
            "An unknown error occurred with the verification server.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [
      const SizedBox(height: 100),
      shared_ui.appLogoAndText,
      const SizedBox(height: 120),
    ];

    if (page == 0) {
      columnChildren.addAll([
        const Center(
            child: CircularProgressIndicator(
          color: Colors.white,
        )),
        const SizedBox(height: 20),
        const Center(
            child: Text(
          "Waiting for verification",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        )),
      ]);
    } else if (page == 1) {
      columnChildren.addAll([
        const Center(
            child: Icon(
          Icons.done,
          size: 75,
          semanticLabel: "success",
          color: Colors.green,
        )),
        const Center(
            child: Text(
          "Success!",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        )),
        const SizedBox(height: 120),
        Align(
          alignment: AlignmentDirectional.center,
          child: shared_ui.OblongTextButton(
            text: 'Continue',
            onPressed: () async {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute<ProfilePage>(builder: (context) {
                return ProfilePage(
                  identityIndex: widget.identityIndex,
                );
              }), (Route route) => false);
            },
          ),
        ),
      ]);
    } else if (page == 2) {
      columnChildren.addAll([
        const Center(
            child: Icon(
          Icons.close,
          size: 75,
          semanticLabel: "failure",
          color: Colors.red,
        )),
        const Center(
            child: Text(
          "Verification failed.",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        )),
        Center(
            child: Text(
          errorMessage,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        )),
        const SizedBox(height: 120),
        Align(
          alignment: AlignmentDirectional.center,
          child: shared_ui.OblongTextButton(
            text: 'Retry verification',
            onPressed: () async {
              await doVerification(context);
            },
          ),
        ),
      ]);
    }

    return shared_ui.StandardScaffold(
      appBar: AppBar(
        title: shared_ui.makeAppBarTitleText('Verifying Claim'),
      ),
      children: columnChildren,
    );
  }
}
