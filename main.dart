import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FriendsPaymentApp());
}

class FriendsPaymentApp extends StatelessWidget {
  const FriendsPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Գումարի հավաք',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// Տվյալների մոդել
// ============================================================

class Friend {
  String name;
  bool paid;

  Friend({
    required this.name,
    this.paid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'paid': paid,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      name: json['name'] ?? '',
      paid: json['paid'] ?? false,
    );
  }
}

// ============================================================
// Գլխավոր էջ
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final countController = TextEditingController();
  final amountController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  @override
  void dispose() {
    countController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Պահված տվյալների ստացում
  // ----------------------------------------------------------

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('payment_data');

    if (saved != null) {
      final data = jsonDecode(saved);

      final names = List<String>.from(data['names'] ?? []);
      final amount = (data['amount'] ?? 0).toDouble();

      if (names.isNotEmpty && amount > 0) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              names: names,
              amount: amount,
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      loading = false;
    });
  }

  // ----------------------------------------------------------
  // Սկսել նոր հավաք
  // ----------------------------------------------------------

  void continueToNames() {
    final count = int.tryParse(
      countController.text.trim(),
    );

    final amount = double.tryParse(
      amountController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (count == null || count <= 0) {
      showMessage(
        'Մուտքագրիր ընկերների ճիշտ քանակը։',
      );
      return;
    }

    if (amount == null || amount <= 0) {
      showMessage(
        'Մուտքագրիր ճիշտ գումար։',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NamesPage(
          count: count,
          amount: amount,
        ),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Գումարի հավաք'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.account_balance_wallet,
              size: 75,
              color: Colors.blue,
            ),

            const SizedBox(height: 25),

            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ընկերների քանակ',
                hintText: 'Օրինակ՝ 5',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Մեկ հոգուց հավաքվող գումար',
                hintText: 'Օրինակ՝ 2000',
                suffixText: '֏',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: continueToNames,
                child: const Text(
                  'Շարունակել',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Անունների էջ
// ============================================================

class NamesPage extends StatefulWidget {
  final int count;
  final double amount;

  const NamesPage({
    super.key,
    required this.count,
    required this.amount,
  });

  @override
  State<NamesPage> createState() => _NamesPageState();
}

class _NamesPageState extends State<NamesPage> {
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    controllers = List.generate(
      widget.count,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void createList() {
    final names = controllers
        .map((controller) => controller.text.trim())
        .toList();

    for (int i = 0; i < names.length; i++) {
      if (names[i].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${i + 1}-րդ ընկերոջ անունը մուտքագրիր։',
            ),
          ),
        );

        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          names: names,
          amount: widget.amount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ընկերների անունները'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${widget.count} ընկեր',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView.builder(
                itemCount: widget.count,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: TextField(
                      controller: controllers[index],
                      decoration: InputDecoration(
                        labelText:
                            'Ընկեր ${index + 1}',
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: createList,
                child: const Text(
                  'Ստեղծել ցուցակը',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Վճարումների էջ
// ============================================================

class PaymentPage extends StatefulWidget {
  final List<String> names;
  final double amount;

  const PaymentPage({
    super.key,
    required this.names,
    required this.amount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late List<Friend> friends;

  @override
  void initState() {
    super.initState();

    friends = widget.names
        .map(
          (name) => Friend(
            name: name,
          ),
        )
        .toList();

    loadPaymentState();
  }

  // ----------------------------------------------------------
  // Վճարումների վիճակի պահպանում
  // ----------------------------------------------------------

  Future<void> savePaymentState() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'amount': widget.amount,
      'names': friends.map((friend) => friend.name).toList(),
      'paid': friends.map((friend) => friend.paid).toList(),
    };

    await prefs.setString(
      'payment_data',
      jsonEncode(data),
    );
  }

  // ----------------------------------------------------------
  // Վճարումների վիճակի վերականգնում
  // ----------------------------------------------------------

  Future<void> loadPaymentState() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('payment_data');

    if (saved == null) return;

    try {
      final data = jsonDecode(saved);

      final savedNames =
          List<String>.from(data['names'] ?? []);

      final savedPaid =
          List<bool>.from(data['paid'] ?? []);

      if (savedNames.length == friends.length) {
        setState(() {
          for (int i = 0;
              i < friends.length;
              i++) {
            friends[i].name = savedNames[i];

            if (i < savedPaid.length) {
              friends[i].paid =
                  savedPaid[i];
            }
          }
        });
      }
    } catch (_) {
      // Եթե պահված տվյալը սխալ է,
      // պարզապես շարունակում ենք առանց դրա։
    }
  }

  // ----------------------------------------------------------
  // Վճարված / չվճարված
  // ----------------------------------------------------------

  Future<void> changePaidStatus(
    int index,
    bool value,
  ) async {
    setState(() {
      friends[index].paid = value;
    });

    await savePaymentState();
  }

  // ----------------------------------------------------------
  // Հաշվարկներ
  // ----------------------------------------------------------

  double get totalAmount {
    return friends.length * widget.amount;
  }

  double get collectedAmount {
    double total = 0;

    for (final friend in friends) {
      if (friend.paid) {
        total += widget.amount;
      }
    }

    return total;
  }

  double get remainingAmount {
    return totalAmount - collectedAmount;
  }

  String formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ----------------------------------------------------------
  // Նոր հավաք
  // ----------------------------------------------------------

  Future<void> newCollection() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Նոր հավաք'),
          content: const Text(
            'Հին հավաքի տվյալները կջնջվեն։ '
            'Շարունակե՞լ։',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Չեղարկել'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Այո'),
            ),
          ],
        );
      },
    );

    if (answer != true) return;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('payment_data');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
      (route) => false,
    );
  }

  // ----------------------------------------------------------
  // Գումարի ցուցադրում
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final total = totalAmount;
    final collected = collectedAmount;
    final remaining = remainingAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Վճարումների ցուցակ',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --------------------------------------------------
          // Ընդհանուր գումար
          // --------------------------------------------------

          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Ընդհանուր՝ '
                  '${formatMoney(total)} ֏',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Հավաքված՝ '
                  '${formatMoney(collected)} ֏',
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Մնացել է՝ '
                  '${formatMoney(remaining)} ֏',
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // Ընկերների ցուցակ
          // --------------------------------------------------

          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend =
                    friends[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          friend.paid
                              ? Colors.green
                              : Colors.red,
                      child: Icon(
                        friend.paid
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                      ),
                    ),

                    title: Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    subtitle: Text(
                      friend.paid
                          ? 'Վճարված է'
                          : 'Դեռ չի վճարել',
                    ),

                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          '${friend.paid ? '+' : '-'}'
                          '${formatMoney(widget.amount)} ֏',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                            color: friend.paid
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Checkbox(
                          value: friend.paid,
                          onChanged:
                              (value) {
                            changePaidStatus(
                              index,
                              value ?? false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --------------------------------------------------
          // Նոր հավաք
          // --------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: newCollection,
                child: const Text(
                  'Նոր հավաք',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
