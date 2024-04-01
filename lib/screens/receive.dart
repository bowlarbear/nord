import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../bdk_lib.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/services.dart'; // Import for ClipboardData and Clipboard

class Receive extends StatefulWidget {
  final Wallet wallet;

  Receive({Key? key, required this.wallet}) : super(key: key);

  @override
  _ReceiveState createState() => _ReceiveState();
}

class _ReceiveState extends State<Receive> {
  late String _address = ''; // Initialize _address

  final BdkLibrary _bdk = BdkLibrary();

  @override
  void initState() {
    super.initState();
    _getNewAddress(); // Call _getNewAddress() when the widget is initialized
  }

  void _getNewAddress() async {
    final res = await _bdk.getAddress(widget.wallet);
    setState(() {
      _address = res.address;
    });
  }

  String _getShortenedAddress() {
    if (_address.length <= 30) {
      return _address;
    } else {
      final firstPart = _address.substring(0, 15);
      final lastPart = _address.substring(_address.length - 15);
      return '$firstPart...$lastPart';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receive', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 30, color: Colors.grey[400]),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: _address ?? '',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your Address:',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _getShortenedAddress(), // Display shortened address
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 5),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Address copied to clipboard')),
                      );
                    },
                    icon: Icon(Icons.content_copy, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getNewAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Generate New Address',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
