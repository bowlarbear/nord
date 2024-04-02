import 'package:flutter/material.dart';
import 'home.dart';
import 'import_seed.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:bdk_flutter/bdk_flutter.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  WelcomeState createState() => WelcomeState();
}

class WelcomeState extends State<Welcome> {
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
            context, MaterialPageRoute(builder: (context) => const Home()));
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
    print('Welcome Page loaded');
    print('Checking for seed...');
    checkForSeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to Nord!',
              // style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(
                height: 30), // Add space between text and first button
            ElevatedButton(
              onPressed: () {
                print('New User button pressed');
                generateSeed();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const Home()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(
                    double.infinity, 50), // Set button width and height
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15), // Add padding
              ),
              child: const Text(
                'New User',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20), // Add space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ImportSeed()));
                print('Import button pressed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(
                    double.infinity, 50), // Set button width and height
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15), // Add padding
              ),
              child: const Text(
                'Import',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
