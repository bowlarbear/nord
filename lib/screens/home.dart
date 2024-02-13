import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:nord/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'welcome.dart';
import 'receive.dart';
import '../bdk_lib.dart';
import 'amount_sendpage.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  BdkLibrary bdk = BdkLibrary();
  late Wallet wallet;
  Blockchain? blockchain;
  String mnemonic = '';
  String? displayText;
  List<TransactionDetails> transactions = [];
  int balance = 0;
  bool _isLoading = false;
  int price = 47085;

  @override
  void initState() {
    super.initState();
    onPageLoad();
  }

  void onPageLoad() async {
    setState(() => _isLoading = true);
    await readSeedFile();
    await createOrRestoreWallet(
      mnemonic,
      Network.Testnet,
      "password",
    );
    await syncWallet();
    await getBalance();
    await listTransactions();
    setState(() => _isLoading = false);
  }

  Future<void> readSeedFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFile = File('${directory.path}/seed');

      if (await seedFile.exists()) {
        final content = await seedFile.readAsString();
        setState(() {
          mnemonic = content;
        });
      } else {
        print('Seed file does not exist.');
      }
    } catch (e) {
      print('Error reading seed file: $e');
    }
  }

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

  Future<void> createOrRestoreWallet(
      String mnemonic, Network network, String? password) async {
    try {
      final descriptors = await bdk.getDescriptors(mnemonic);
      await blockchainInit(true);
      final res = await Wallet.create(
          descriptor: descriptors[0],
          changeDescriptor: descriptors[1],
          network: network,
          databaseConfig: const DatabaseConfig.memory());
      var addressInfo =
          await res.getAddress(addressIndex: const AddressIndex());
      setState(() {
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

  Future<void> getBalance() async {
    final bal = await bdk.getBalance(wallet);
    setState(() {
      balance = bal.total;
      displayText =
          "Total Balance: ${bal.total} sats \n Immature Balance: ${bal.immature} sats";
    });
  }

  Future<void> handleRefresh() async {
    print('Pulldown Refresh Initiatied...');
    await syncWallet();
    print('Getting Balance...');
    await getBalance();
    print('Getting Transactions...');
    await listTransactions();
  }

  Future<void> syncWallet() async {
    if (blockchain == null) {
      await blockchainInit(true);
    }
    print('syncing wallet...');
    await bdk.sync(blockchain!, wallet);
  }

  Future<void> listTransactions() async {
    final tx = await bdk.getTransactions(wallet);
    tx.sort((a, b) {
      if (a.confirmationTime == null && b.confirmationTime == null) return 0;
      if (a.confirmationTime == null) return -1;
      if (b.confirmationTime == null) return 1;
      return b.confirmationTime!.timestamp
          .compareTo(a.confirmationTime!.timestamp);
    });
    setState(() {
      transactions = tx;
    });
  }

  Future<void> sendTx(String addressStr, int amount) async {
    await bdk.sendBitcoin(blockchain!, wallet, addressStr, amount);
    setState(() {
      displayText = "Successfully broadcast $amount Sats to $addressStr";
    });
  }

  Future<void> blockchainInit(bool isElectrumBlockchain) async {
    blockchain = await bdk.initializeBlockchain(isElectrumBlockchain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      BalanceContainer(
                        text:
                            "${balance} Sats (\$ ${((balance / 100000000) * price).toStringAsFixed(2)})",
                      ),
                      transactions.isEmpty
                          ? Center(
                              child: Text("No transaction history"),
                            )
                          : Column(
                              children: transactions
                                  .map(
                                    (transaction) => Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Value: ${transaction.received - transaction.sent} sats (\$ ${(((transaction.received - transaction.sent) / 100000000) * price).toStringAsFixed(2)})",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text('TXID: ${transaction.txid}'),
                                            Text(
                                              'Timestamp: ${transaction.confirmationTime?.timestamp ?? "Pending"}',
                                            ),
                                            Text('Fee: ${transaction.fee}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      StyledContainer(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Receive(wallet: this.wallet),
                                  ),
                                );
                              },
                              child: Text('Receive'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SendingScreen(
                                        wallet: this.wallet,
                                        blockchain: this.blockchain,
                                        balance: this.balance),
                                  ),
                                );
                              },
                              child: Text('send'),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                await deleteSeedFile();
                              },
                              child: Text("Delete Seed"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
