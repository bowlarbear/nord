import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'receive.dart';
import '../bdk_lib.dart';
import 'send_page1.dart';
import 'dart:async';
import 'settings.dart';
import 'savings.dart';

class ExpandableTransaction {
  final TransactionDetails transaction;
  bool isExpanded;

  ExpandableTransaction({
    required this.transaction,
    this.isExpanded = false,
  });
}

class Spending extends StatefulWidget {
  const Spending({Key? key}) : super(key: key);

  @override
  State<Spending> createState() => _SpendingState();
}

class _SpendingState extends State<Spending> with TickerProviderStateMixin {
  BdkLibrary bdk = BdkLibrary();
  late Wallet wallet;
  Blockchain? blockchain;
  String mnemonic = '';
  String? displayText;
  // List<TransactionDetails> transactions = [];
  List<ExpandableTransaction> transactions = [];
  int balance = 0;
  bool _isLoading = false;
  int price = 47085;
  late AnimationController _controller;
  int _currentIndex = 0;
  late PageController _pageController;
  final bool _expanded = false;
  final _pageViewNotifier = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    bdk = BdkLibrary();
    _pageController = PageController(initialPage: _currentIndex);
    //initialization
    onPageLoad();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
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
    transactions = tx.map((transaction) {
      return ExpandableTransaction(transaction: transaction);
    }).toList();
  }

  //initialize the blockchain connection with a remote electrum server (currently configured to blockstream's public testnet backend)
  Future<void> blockchainInit(bool isElectrumBlockchain) async {
    blockchain = await bdk.initializeBlockchain(isElectrumBlockchain);
  }

  Widget _buildTransactionCard(
      ExpandableTransaction expandableTransaction, int price) {
    final TransactionDetails transaction = expandableTransaction.transaction;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandableTransaction.isExpanded = !expandableTransaction.isExpanded;
        });
      },
      child: Card(
        color: Colors.grey[900],
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Value: ${transaction.received - transaction.sent} sats (\$ ${(((transaction.received - transaction.sent) / 100000000) * price).toStringAsFixed(2)})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              if (expandableTransaction
                  .isExpanded) // Show details only if expanded
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TXID: ${transaction.txid}',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Timestamp: ${transaction.confirmationTime?.timestamp ?? "Pending"}',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fee: ${transaction.fee}',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_currentIndex == 0 ? 'Spending' : 'Savings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(
                      wallet: wallet, blockchain: blockchain, balance: balance),
                ),
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: true,
                    fillOverscroll: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                              _pageViewNotifier.value = index;
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, child) {
                                        return Text(
                                          "\$ ${((balance / 100000000) * price).toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      "$balance Sats",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      Receive(wallet: wallet),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors
                                                  .orange, // Set the background color here
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                            ),
                                            child: const Text(
                                              'Receive',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SendingScreen(
                                                          wallet: wallet,
                                                          blockchain:
                                                              blockchain,
                                                          balance: balance),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                            ),
                                            child: const Text(
                                              'Send',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: transactions.length,
                                        itemBuilder: (context, index) {
                                          return _buildTransactionCard(
                                              transactions[index], price);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SavingsPage(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: AnimatedOpacity(
                            opacity: _expanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[800],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Spending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Savings',
          ),
        ],
      ),
    );
  }
}
