import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:bdk_flutter/bdk_flutter.dart';
import '../bdk_lib.dart';
import 'receive.dart';
import 'send_page2.dart';
import 'settings.dart';
import 'vault.dart';
import 'loan.dart';
import 'package:page_view_indicators/page_view_indicators.dart';

class ExpandableTransaction {
  final TransactionDetails transaction;
  bool isExpanded;

  ExpandableTransaction({
    required this.transaction,
    this.isExpanded = false,
  });
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late BdkLibrary bdk;
  late Wallet wallet;
  Blockchain? blockchain;
  String mnemonic = '';
  String? displayText;
  List<ExpandableTransaction> transactions = [];
  int balance = 0;
  bool _isLoading = false;
  int price = 47085;
  late AnimationController _controller;
  int _currentIndex = 0;
  late PageController _pageController;
  bool _expanded = false;
  int _currentPage = 0;
  final _pageViewNotifier = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    bdk = BdkLibrary();
    _pageController = PageController(initialPage: _currentIndex);
    onPageLoad();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
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

  Future<void> syncWallet() async {
    if (blockchain == null) {
      await blockchainInit(true);
    }
    print('Syncing wallet...');
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
      transactions = tx.map((transaction) {
        return ExpandableTransaction(transaction: transaction);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_currentIndex == 0
            ? 'Bitcoin Wallet'
            : _currentIndex == 1
                ? 'Loan'
                : 'Vault'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(
                      wallet: this.wallet,
                      blockchain: this.blockchain,
                      balance: this.balance),
                ),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                              _currentPage = index;
                              _showPageIndicators(); // Show indicators when sliding
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
                                        "${((balance / 100000000) * price).toStringAsFixed(2)}\$",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    "${balance} Sats",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 10),
                                    height: 1,
                                    color: Colors.white,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Receive(
                                                    wallet: this.wallet),
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
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          child: Text(
                                            'Receive',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SendingScreen(
                                                        wallet: this.wallet,
                                                        blockchain:
                                                            this.blockchain,
                                                        balance: this.balance),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          child: Text(
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
                                  Divider(
                                    color: Colors.white,
                                    thickness: 1,
                                  ),
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
                            LoanPage(),
                            VaultPage(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: AnimatedOpacity(
                          opacity: _expanded ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: CirclePageIndicator(
                            itemCount: 3,
                            currentPageNotifier: _pageViewNotifier,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Loan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Vault',
          ),
        ],
      ),
    );
  }

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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              if (expandableTransaction
                  .isExpanded) // Show details only if expanded
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TXID: ${transaction.txid}',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Timestamp: ${transaction.confirmationTime?.timestamp ?? "Pending"}',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Fee: ${transaction.fee}',
                      style: TextStyle(
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

  void _showPageIndicators() {
    setState(() {
      _expanded = true;
    });

    // Cancel the existing timer
    _timer?.cancel();

    // Set a new timer to hide the indicators after 1 second
    _timer = Timer(Duration(seconds: 1), () {
      setState(() {
        _expanded = false;
      });
    });
  }
}
