import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:nord/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'welcome.dart';
import 'receive.dart';
import '../bdk_lib.dart';
import 'send_page2.dart';
import 'dart:async';

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
  int _tapCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    //initialization
    onPageLoad();
  }

  //initialization function
  //TODO determine under what (if any) conditions this will rerun mid session, handle appropiately with conditionals
  void onPageLoad() async {
    setState(() => _isLoading = true);
    //read seed from local filesystem
    await readSeedFile();
    //create or restore the wallet from seed
    await createOrRestoreWallet(
      mnemonic,
      Network.Testnet,
      "password",
    );
    //seed the wallet db
    await syncWallet();
    //fetch the latest balance data
    await getBalance();
    //fetch the latest tx history
    await listTransactions();
    //TODO refresh exchange rate
    //disable the loading indicator
    setState(() => _isLoading = false);
  }

  //reads a 12 word mnemonic  seed phrase from the local file system
  //TODO prints are for debugging only and should be removed
  Future<void> readSeedFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFile = File('${directory.path}/seed');

      if (await seedFile.exists()) {
        final content = await seedFile.readAsString();
        setState(() {
          mnemonic = content;
          print('Seed File read to memory');
        });
      } else {
        //handle cases where the file for some reason does not exist (should not occur here)
        print('Seed file does not exist.');
      }
    } catch (e) {
      //handle errors
      print('Error reading seed file: $e');
    }
  }

  //Delete the existing seed file (this will probably only be used for testing)
  //TODO prints are for debugging only and should be removed
  Future<void> deleteSeedFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final seedFile = File('${directory.path}/seed');

      if (await seedFile.exists()) {
        await seedFile.delete();
        print('Seed file deleted successfully.');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Welcome()));
      } else {
        print('Seed file does not exist.');
      }
    } catch (e) {
      print('Error deleting seed file: $e');
    }
  }

  //note this currently does not restore an existing wallet, but always creates the wallet from scratch from the provided mnemonic
  //TODO this may need a logic loop which checks first if the wallet state already exists before being run
  Future<void> createOrRestoreWallet(
      String mnemonic, Network network, String? password) async {
    try {
      final descriptors = await bdk.getDescriptors(mnemonic);
      //init the blockchain connection
      await blockchainInit(true);
      //create the wallet
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

  //returns the balance of the currently loaded wallet
  //TODO prints are for debugging only and should be removed
  Future<void> getBalance() async {
    final bal = await bdk.getBalance(wallet);
    print(bal.total);
    setState(() {
      balance = bal.total;
      displayText =
          "Total Balance: ${bal.total} sats \n Immature Balance: ${bal.immature} sats";
    });
  }

  //handles a manual refresh initiated by the user with a pull down request
  //TODO prints are for debugging only and should be removed
  Future<void> handleRefresh() async {
    //sync & fetch the latest balance and transaction data
    print('Pulldown Refresh Initiatied...');
    await syncWallet();
    print('Getting Balance...');
    await getBalance();
    print('Getting Transactions...');
    await listTransactions();
    //TODO eventually have this refresh exchange rate
  }

  //sync the wallet db with the currently loaded wallet
  Future<void> syncWallet() async {
    if (blockchain == null) {
      await blockchainInit(true);
    }
    print('syncing wallet...');
    await bdk.sync(blockchain!, wallet);
  }

  //returns a chronologically sorted list of transaction history from the currently loaded wallet
  Future<void> listTransactions() async {
    final tx = await bdk.getTransactions(wallet);
    //sort txs in descending order
    tx.sort((a, b) {
      //both confirmation times are null, consider them equal in terms of sorting
      //null here indicates that a tx is currently unconfirmed, these txs have the highest order precedence
      if (a.confirmationTime == null && b.confirmationTime == null) return 0;
      //if A's confirmation time is null and B is not, A goes first
      if (a.confirmationTime == null) return -1;
      //if B's confirmation time is null and A is not, B goes first
      if (b.confirmationTime == null) return 1;
      //if neither confirmation time is null, the value is now safe to access
      return b.confirmationTime!.timestamp
          .compareTo(a.confirmationTime!.timestamp);
    });
    setState(() {
      transactions = tx;
    });
  }

  //handle the 5 quick taps for seed clear
  void _handleUserTap() {
    _tapCount++;
    if (_tapCount == 1) {
      // Start a timer on the first tap
      _timer = Timer(const Duration(seconds: 2), () {
        // Reset count after 2 seconds of inactivity
        _tapCount = 0;
      });
    } else if (_tapCount == 6) {
      // If user tapped 5 times, cancel timer and fire the function
      _timer?.cancel();
      deleteSeedFile();
      _tapCount = 0; // Reset tap count after action is performed
    }
  }

  //initialize the blockchain connection with a remote electrum server (currently configured to blockstream's public testnet backend)
  Future<void> blockchainInit(bool isElectrumBlockchain) async {
    blockchain = await bdk.initializeBlockchain(isElectrumBlockchain);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleUserTap,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: RefreshIndicator(
          onRefresh: handleRefresh,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        BalanceContainer(
                          text:
                              "$balance Sats (\$ ${((balance / 100000000) * price).toStringAsFixed(2)})",
                        ),
                        transactions.isEmpty
                            ? const Center(
                                //conditionally display this string when tx history is empty
                                child: Text("No transaction history"),
                              )
                            : Column(
                                //display transactions in descending order
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
                                                style: const TextStyle(
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
                                          Receive(wallet: wallet),
                                    ),
                                  );
                                },
                                child: const Text('Receive'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SendingScreen(
                                          wallet: wallet,
                                          blockchain: blockchain,
                                          balance: balance),
                                    ),
                                  );
                                },
                                child: const Text('send'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
