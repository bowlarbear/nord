import 'package:flutter/material.dart';
import 'home.dart';
import 'importSeed.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:bdk_flutter/bdk_flutter.dart';

class Welcome extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  void initState() {
    super.initState();
    onPageLoad();
  }

  Future<void> checkForSeed() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFilePath = '${directory.path}/seed';
      final seedFile = File(seedFilePath);

      if (await seedFile.exists()) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()));
        // Seed file exists, send user home
      } else {
        print('Seed file does not exist.');
        // Seed file does not exist, create new seed or import?
      }
    } catch (e) {
      print('Error checking seed file: $e');
    }
  }

  Future<void> generateSeed() async {
    var res = await Mnemonic.create(WordCount.Words12);
    var seed = res.asString();
    //TODO REMOVE THIS PRINT OF SEED TO THE CONSOLE, THIS IS FOR DEBUGGING ONLY
    print('$seed');
    //TODO REMOVE THIS PRINT OF SEED TO THE CONSOLE, THIS IS FOR DEBUGGING ONLY
    writeSeedToFile(seed);
  }

  Future<void> writeSeedToFile(String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/seed');
      await file.writeAsString(content);
      print('File written successfully');
    } catch (e) {
      print('Error writing file: $e');
    }
  }

  //execute all init logic here on welcome screen page load
  void onPageLoad() async {
    checkForSeed();
    print('Welcome Page loaded, function executed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to Nord!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30), // Add space between text and first button
            ElevatedButton(
              onPressed: () {
                print('New User button pressed');
                generateSeed();
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => Home()));
              },
              child: Text('New User'),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    Size(double.infinity, 50), // Set button width and height
                padding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15), // Add padding
              ),
            ),
            SizedBox(height: 20), // Add space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => ImportSeed()));
                print('Import button pressed');
              },
              child: Text('Import'),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    Size(double.infinity, 50), // Set button width and height
                padding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15), // Add padding
              ),
            ),
          ],
        ),
      ),
    );
  }
}
