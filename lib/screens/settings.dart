import 'package:flutter/material.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'welcome.dart';

class Settings extends StatelessWidget {
  final Wallet wallet;
  final int? balance;
  final Blockchain? blockchain;

  const Settings({Key? key, required this.wallet, this.balance, this.blockchain}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Dangerous Settings',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSeedFile(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Delete Seed', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSeedFile(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFile = File('${directory.path}/seed');

      if (await seedFile.exists()) {
        await seedFile.delete();
        print('Seed file deleted successfully.');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Welcome()));
      } else {
        print('Seed file does not exist.');
      }
    } catch (e) {
      print('Error deleting seed file: $e');
    }
  }
}
