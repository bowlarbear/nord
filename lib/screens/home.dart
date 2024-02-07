// screens/home.dart

import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:nord/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'welcome.dart';
import 'receive.dart';

//import the bdk_lib.dart library
import '../bdk_lib.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    onPageLoad();
  }

  //instantiate the bdk_lib.dart library
  BdkLibrary bdk = BdkLibrary();
  late Wallet wallet;
  Blockchain? blockchain;
  TextEditingController recipientAddress = TextEditingController();
  TextEditingController amount = TextEditingController();
  String mnemonic = '';
  String? displayText;
  int balance = 0;
  List<LocalUtxo>? txHistory;

  //initializes the remote blockchain db config
  blockchainInit(bool isElectrumBlockchain) async {
    blockchain = await bdk.initializeBlockchain(isElectrumBlockchain);
  }

  //reads a 12 word mnemonic seed phrase from the users local files
  //TODO prints are for debugging only and should be removed
  Future<void> readSeedFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFile = File('${directory.path}/seed');

      if (await seedFile.exists()) {
        final content = await seedFile.readAsString();
        setState(() {
          mnemonic = content;
          print('Seed file read to memory.');
        });
      } else {
        print('Seed file does not exist.');
        // Handle the case where the file doesn't exist
      }
    } catch (e) {
      print('Error reading seed file: $e');
      // Handle any errors
    }
  }

  //delete the existing seed file (this will only be used in testing probably)
  //TODO prints are for debugging only and should be removed
  Future<void> deleteSeedFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFile = File('${directory.path}/seed');

      if (await seedFile.exists()) {
        await seedFile.delete();
        print('Seed file deleted successfully.');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Welcome()));
      } else {
        print('Seed file does not exist.');
      }
    } catch (e) {
      print('Error deleting seed file: $e');
    }
  }

  //note this currently does not restore an existing wallet, it can only create, but for now it functions as both until we want to preserve wallet state
  //TODO this needs to be refactored to use bdk_lib.dart & to fire on page load, need to determine whether or not this needs a logic loop which prevents it being run again if navigating back to home screen from within the app
  Future<void> createOrRestoreWallet(
      String mnemonic, Network network, String? password) async {
    try {
      final descriptors = await bdk.getDescriptors(mnemonic);
      //establish the blockchain connection
      await blockchainInit(true);
      //this call returns a Wallet object
      final res = await Wallet.create(
          descriptor: descriptors[0],
          changeDescriptor: descriptors[1],
          network: network,
          databaseConfig: const DatabaseConfig.memory());
      var addressInfo =
          await res.getAddress(addressIndex: const AddressIndex());
      setState(() {
        // address = addressInfo.address;
        wallet = res;
        displayText = "Wallet Created: ${addressInfo.address}";
      });
      print('Wallet Created.');
    } on Exception catch (e) {
      setState(() {
        displayText = "Error: ${e.toString()}";
      });
    }
  }

  //returns the balance of the currently loaded wallet
  //TODO prints are for debugging only and should be removed
  getBalance() async {
    await syncWallet();
    final bal = await bdk.getBalance(wallet);
    print(bal.total);
    setState(() {
      balance = bal.total;
      displayText =
          "Total Balance: ${bal.total} sats \n Immature Balance: ${bal.immature} sats";
    });
  }

  //Sync the currently loaded wallet with the blockchain
  syncWallet() async {
    if (blockchain == null) {
      await blockchainInit(true);
    }
    print('syncing wallet...');
    await bdk.sync(blockchain!, wallet);
  }

  //generate and send a single sig tx with the tx builder class
  sendTx(String addressStr, int amount) async {
    await bdk.sendBitcoin(blockchain!, wallet, addressStr, amount);
    setState(() {
      displayText = "Successfully broadcast $amount Sats to $addressStr";
    });
  }

  //TODO prints are for debugging only and should be removed
  listConfirmedTransactions() async {
    await syncWallet();
    final confirmed = await bdk.getConfirmedTransactions(wallet);
    setState(() {
      displayText = "You have ${confirmed.length} confirmed transactions";
    });
    if (confirmed.length == 0) {
      print("No confirmed transactions");
    } else {
      for (var e in confirmed) {
        print(" txid: ${e.txid}");
        print(" confirmationTime: ${e.confirmationTime?.timestamp}");
        print(" confirmationTime Height: ${e.confirmationTime?.height}");
        final txIn = await e.transaction!.input();
        final txOut = await e.transaction!.output();
        print("         =============TxIn==============");
        for (var e in txIn) {
          print("         previousOutout Txid: ${e.previousOutput.txid}");
          print("         previousOutout vout: ${e.previousOutput.vout}");
          print("         witness: ${e.witness}");
        }
        print("         =============TxOut==============");
        for (var e in txOut) {
          print("         script: ${e.scriptPubkey}");
          print("         value: ${e.value}");
        }
        print("========================================");
      }
    }
  }

  //TODO prints are for debugging only and should be removed
  listUnconfirmedTransactions() async {
    await syncWallet();
    final unConfirmed = await bdk.getUnConfirmedTransactions(wallet);
    setState(() {
      displayText = "You have ${unConfirmed.length} unConfirmed transactions";
    });
    if (unConfirmed.length == 0) {
      print("No unconfirmed transactions");
    } else {
      for (var e in unConfirmed) {
        final txOut = await e.transaction!.output();
        print(" txid: ${e.txid}");
        print(" fee: ${e.fee}");
        print(" received: ${e.received}");
        print(" send: ${e.sent}");
        print(" output address: ${txOut.last.scriptPubkey}");
        print("===========================");
      }
    }
  }

  //execute all init logic here on welcome screen page load
  //TODO need to divise some logic here that will ensure this does not re init if the user is coming back from another page mid session
  void onPageLoad() async {
    print('Home Page loaded');
    //TODO if wallet not loaded {}
    print('Reading Seed...');
    //read the seed from the users device
    await readSeedFile();
    print('Loading Wallet...');
    //create/load the wallet
    await createOrRestoreWallet(
      mnemonic,
      Network.Testnet,
      "password",
    );
    //TODO need to figure out how to wait for syncWallet to resolve before proceeding, this is not currently working with just nested async await calls
    print('Getting Balance...');
    await getBalance();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        /* AppBar */
        appBar: buildAppBar(context),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                /* Balance */
                BalanceContainer(
                  text: "${balance} Sats",
                ),
                /* Result */
                ResponseContainer(
                  text: displayText ?? "No Response",
                ),
                /* Create Wallet */
                StyledContainer(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      SubmitButton(
                        callback: () async {
                          await getBalance();
                        },
                        text: "Get Balance",
                      ),
                      SubmitButton(
                          callback: () async {
                            await listConfirmedTransactions();
                          },
                          text: "List Confirmed TX History"),
                      SubmitButton(
                          callback: () async {
                            await listUnconfirmedTransactions();
                          },
                          text: "List Unconfirmed TX History"),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Receive(wallet: this.wallet)),
                          );
                        },
                        child: Text('Receive'),
                      ),
                    ])),

                /* Send Transaction */
                StyledContainer(
                    child: Form(
                  key: _formKey,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFieldContainer(
                          child: TextFormField(
                            controller: recipientAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                            style: Theme.of(context).textTheme.bodyText1,
                            decoration: const InputDecoration(
                              hintText: "Enter Address",
                            ),
                          ),
                        ),
                        TextFieldContainer(
                          child: TextFormField(
                            controller: amount,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the amount';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            style: Theme.of(context).textTheme.bodyText1,
                            decoration: const InputDecoration(
                              hintText: "Enter Amount",
                            ),
                          ),
                        ),
                        SubmitButton(
                          text: "Send Bitcoin",
                          callback: () async {
                            if (_formKey.currentState!.validate()) {
                              await sendTx(recipientAddress.text,
                                  int.parse(amount.text));
                            }
                          },
                        )
                      ]),
                )),
                /* Delete Seed */
                StyledContainer(
                  child: Column(children: [
                    SubmitButton(
                      callback: () async {
                        await deleteSeedFile();
                      },
                      text: "Delete Seed",
                    ),
                  ]),
                )
              ],
            ),
          ),
        ));
  }
}
