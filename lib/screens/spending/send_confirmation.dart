import 'package:flutter/material.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'spending_dashboard.dart';

class SendingConfirmation extends StatefulWidget {
  const SendingConfirmation({
    super.key,
  });

  @override
  SendingConfirmationState createState() => SendingConfirmationState();
}

class SendingConfirmationState extends State<SendingConfirmation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sending Confirmation',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
