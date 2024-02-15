import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'send_page1.dart';

class SendingScreen extends StatefulWidget {
  final Wallet wallet;
  final int? balance;
  final Blockchain? blockchain;

  SendingScreen({Key? key, required this.wallet, this.balance, this.blockchain}) : super(key: key);

  @override
  _SendingScreenState createState() => _SendingScreenState();
}

class _SendingScreenState extends State<SendingScreen> {
  late FocusNode _focusNode;
  late double enteredAmount;
  late double maxAmountToSpend;
  final NumberFormat satoshiFormat = NumberFormat('#,### sats');
  bool isAmountIncreased = false;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    enteredAmount = 0.0;
    maxAmountToSpend = widget.balance?.toDouble() ?? 0.0;
    _focusNode.addListener(handleFocusChange);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void handleFocusChange() {
    if (!_focusNode.hasFocus) {
      double newValue = double.tryParse(_controller.text) ?? 0.0;
      if (newValue <= maxAmountToSpend) {
        setState(() => enteredAmount = newValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Sending Screen'),
        backgroundColor: Colors.black, // Black app bar
        iconTheme: IconThemeData(color: Colors.grey), // Bright gray back arrow
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            padding: EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                AmountSection(
                  enteredAmount: enteredAmount,
                  onAmountChanged: handleTextFieldChange,
                  maxAmountToSpend: maxAmountToSpend,
                  satoshiFormat: satoshiFormat,
                  onTap: () {
                    _focusNode.requestFocus();
                  },
                ),
                SizedBox(height: 16),
                SliderSection(
                  enteredAmount: enteredAmount,
                  maxAmountToSpend: maxAmountToSpend,
                  onSliderChanged: onSliderChanged,
                ),
                SizedBox(height: 24), // Add space between slider and button
                ElevatedButton(
                  onPressed: isAmountIncreased
                      ? () {
                          // Navigate to the Sending.dart page with necessary parameters
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Sending(wallet: widget.wallet, balance: widget.balance, amount: enteredAmount, blockchain: widget.blockchain),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    'Next',
                    style: TextStyle(color: Colors.white, fontSize: 20), // White text, bigger font size
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        isAmountIncreased ? Colors.orange : Colors.grey),
                    minimumSize: MaterialStateProperty.all<Size>(
                        Size(double.infinity, 50)),
                  ),
                ),
                SizedBox(height: 16), // Adjust the height as needed
                InvisibleTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: handleTextFieldChange,
                  onSubmitted: (_) => printEnteredAmount(),
                ),
              ],
            ),
          ),
          if (widget.balance == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'You have no funds.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onSliderChanged(double value) {
    setState(() {
      enteredAmount = value;
      isAmountIncreased = true; // Set to true when slider changes
    });
  }

  void handleTextFieldChange(String value) {
    if (value.isEmpty) {
      setState(() => enteredAmount = 0.0);
    } else {
      double newValue = double.tryParse(value) ?? 0.0;
      if (newValue > maxAmountToSpend) {
        showExceedBalanceWarning();
      } else {
        setState(() {
          enteredAmount = newValue;
          isAmountIncreased = true; // Set to true when text field changes
        });
      }
    }
  }

  void printEnteredAmount() {
    print('Entered amount: $enteredAmount');
  }

  void showExceedBalanceWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Warning"),
          content: Container(
            child: Text(
              "You have exceeded your balance.",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class AmountSection extends StatelessWidget {
  final double enteredAmount;
  final ValueChanged<String> onAmountChanged;
  final double maxAmountToSpend;
  final NumberFormat satoshiFormat;
  final VoidCallback onTap;

  AmountSection({
    required this.enteredAmount,
    required this.onAmountChanged,
    required this.maxAmountToSpend,
    required this.satoshiFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '${satoshiFormat.format(enteredAmount)}',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Tap the amount to edit',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 48.0,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SliderSection extends StatelessWidget {
  final double enteredAmount;
  final double maxAmountToSpend;
  final ValueChanged<double> onSliderChanged;

  SliderSection({
    required this.enteredAmount,
    required this.maxAmountToSpend,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Slider(
          value: enteredAmount,
          min: 0.0,
          max: maxAmountToSpend,
          onChanged: onSliderChanged,
          label: '\$${enteredAmount.toStringAsFixed(2)}',
          activeColor: Colors.blue,
          inactiveColor: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          'Slide to increase amount',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}

class InvisibleTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  InvisibleTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(color: Colors.transparent),
        cursorColor: Colors.transparent,
        keyboardType: TextInputType.numberWithOptions(decimal: true), // Set keyboardType to TextInputType.numberWithOptions(decimal: true)
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}
