import 'package:flutter/material.dart';

import 'new_or_import_profile.dart';
import '../main.dart' as Main;
import '../api_methods.dart' as APIMethods;
import '../protocol.pb.dart' as Protocol;

class AutomatedVerificationPage extends StatefulWidget {
  final Main.ClaimInfo claim;

  AutomatedVerificationPage({Key? key, required this.claim}) : super(key: key);

  @override
  State<AutomatedVerificationPage> createState() =>
      _AutomatedVerificationPageState();
}

class _AutomatedVerificationPageState extends State<AutomatedVerificationPage> {
  int page = 0;

  void initState() {
    doVerification();
  }

  Future<void> doVerification() async {
    setState(() {
      page = 0;
    });

    final success = await APIMethods.requestVerification(
      widget.claim.pointer,
      widget.claim.claimType,
    );

    setState(() {
      if (success) {
        page = 1;
      } else {
        page = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [
      SizedBox(height: 100),
      Main.neopassLogoAndText,
      SizedBox(height: 150),
    ];

    if (page == 0) {
      columnChildren.addAll([
        CircularProgressIndicator(
          color: Colors.white,
        ),
        SizedBox(height: 20),
        Text(
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
        Icon(
          Icons.done,
          size: 75,
          semanticLabel: "success",
          color: Colors.green,
        ),
        Text(
          "Success!",
          style: TextStyle(
            fontFamily: 'inter',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 120),
        Align(
          alignment: AlignmentDirectional.center,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Main.blueButtonColor,
              shape: StadiumBorder(),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return NewOrImportProfilePage();
              }));
            },
          ),
        ),
      ]);
    } else if (page == 2) {
      columnChildren.addAll([
        Icon(
          Icons.close,
          size: 75,
          semanticLabel: "failure",
          color: Colors.red,
        ),
        Text(
          "Verification failed.",
          style: TextStyle(
            fontFamily: 'inter',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 120),
        Align(
          alignment: AlignmentDirectional.center,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Main.blueButtonColor,
              shape: StadiumBorder(),
            ),
            child: Text(
              'Retry verification',
              style: TextStyle(
                fontFamily: 'inter',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              doVerification();
            },
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Main.makeAppBarTitleText('Verifying Claim'),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: columnChildren,
        ),
      ),
    );
  }
}
