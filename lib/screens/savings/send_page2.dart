import 'package:flutter/material.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'savings_dashboard.dart';

class Sending extends StatefulWidget {
  final Wallet wallet;
  final int? balance;
  final double amount;
  final Blockchain? blockchain;

  const Sending({
    super.key,
    required this.wallet,
    this.balance,
    required this.amount,
    required this.blockchain,
  });

  @override
  SendingState createState() => SendingState();
}

class SendingState extends State<Sending> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  final TextEditingController _recipientAddressController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _canSend = false;
  bool _isSuccessDisplayed = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _recipientAddressController.addListener(_checkCanSend);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Sending Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  _startQRScanner();
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 0, 0, 131),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _recipientAddressController,
                decoration: InputDecoration(
                  hintText: 'Enter recipient address',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[800]!),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[800]!),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[800]!),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[800]!),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              _isSending
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _canSend ? _sendTransaction : null,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey; // Gray when disabled
                            }
                            return Colors.orange; // Bright orange when enabled
                          },
                        ),
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQRScanner() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _stopQRScanner();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      print('Scanned Data: ${scanData.code}');
      _recipientAddressController.text = scanData.code ?? '';
      _canSend = true;
      await controller.stopCamera(); // Stop the camera
      Navigator.of(context).pop(); // Close the QR code scanner dialog
    });
  }

  void _checkCanSend() {
    setState(() {
      _canSend = _recipientAddressController.text.isNotEmpty;
    });
  }

  void _sendTransaction() async {
    setState(() {
      _isSending = true;
    });
    String recipientAddress = _recipientAddressController.text;
    // String note = _noteController.text;
    double amount = widget.amount;

    // Convert the double amount to an integer
    int amountInSatoshis = amount.toInt(); // Convert to int

    try {
      final txBuilder = TxBuilder();
      final address = await Address.create(address: recipientAddress);
      final script = await address.scriptPubKey();
      final feeRate = await widget.blockchain!.estimateFee(25);
      final txBuilderResult = await txBuilder
          .addRecipient(script, amountInSatoshis) // Pass the integer value
          .feeRate(feeRate.asSatPerVb())
          .finish(widget.wallet);
      final sbt = await widget.wallet.sign(psbt: txBuilderResult.psbt);
      final tx = await sbt.extractTx();

      // Broadcasting transaction
      await widget.blockchain!.broadcast(tx);

      // Success message to user
      _showSuccessAnimation(context);
      _recipientAddressController.clear();
      _noteController.clear();
      setState(() {
        _isSending = false;
      });
    } catch (e, stackTrace) {
      // Error handling
      print('Error sending Bitcoin: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send Bitcoin: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSuccessAnimation(BuildContext context) {
    if (_isSuccessDisplayed) return;
    _isSuccessDisplayed = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Saving()),
      );
    });
  }

  void _stopQRScanner() {
    Navigator.pop(context);
    controller.dispose();
  }

  @override
  void dispose() {
    _recipientAddressController.dispose();
    _noteController.dispose();
    _stopQRScanner();
    super.dispose();
  }
}
