import 'package:flutter/material.dart';

class PayWall extends StatefulWidget {
  const PayWall({Key? key}) : super(key: key);

  @override
  PayWallState createState() => PayWallState();
}

class PayWallState extends State<PayWall> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayWall', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
    );
  }
}
