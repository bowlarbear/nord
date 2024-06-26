import 'package:flutter/material.dart';
import 'spending/spending_dashboard.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'import_seed.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  WelcomeState createState() => WelcomeState();
}

class WelcomeState extends State<Welcome> {
  bool isLoading = false;
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
            context, MaterialPageRoute(builder: (context) => const Spending()));
        // Seed file exists, send user home
      } else {
        print('Seed file does not exist.');
        // Seed file does not exist, create new seed
        // await generateSeed();
        setState(() {
          isLoading = false;
        });
        //send user to spending wallet
        // Navigator.pushReplacement(
        //     context, MaterialPageRoute(builder: (context) => const Spending()));
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
    // checkForSeed();
  }

  void importSeed() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const ImportSeed()));
  }

  void navigateDashboard() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Spending()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
                      onPressed: importSeed, child: const Text('Import Seed')),
                  const SizedBox(
                      height: 30), // Add space between text and first button
                  ElevatedButton(
                      onPressed: navigateDashboard,
                      child: const Text('Dashboard')),
                ],
              ),
            ),
    );
  }
}
