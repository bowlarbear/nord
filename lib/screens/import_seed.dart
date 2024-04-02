import 'package:flutter/material.dart';
import 'home.dart';
import 'welcome.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ImportSeed extends StatefulWidget {
  const ImportSeed({super.key});
  @override
  ImportSeedState createState() => ImportSeedState();
}

class ImportSeedState extends State<ImportSeed> {
  String seed = ''; // State variable for the text input

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import a 12 word seed phrase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Seed',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter 12 word seed here',
              ),
              onChanged: (value) {
                setState(() {
                  seed = value;
                });
              },
            ),
            const SizedBox(height: 20), // Space between text field and buttons
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    writeSeedToFile(seed);
                    print('Proceed button pressed');
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const Home()));
                  },
                  child: const Text('Proceed'),
                ),
                const SizedBox(width: 10), // Space between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Welcome()));
                    print('Back button pressed');
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
