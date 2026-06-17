import 'package:flutter/material.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {

  String selectedPayment = "COD";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "💳 Payment",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [

            paymentTile(
              "Cash on Delivery",
              "COD",
              Icons.money,
            ),

            paymentTile(
              "UPI",
              "UPI",
              Icons.account_balance,
            ),

            paymentTile(
              "Credit / Debit Card",
              "CARD",
              Icons.credit_card,
            ),

            paymentTile(
              "Wallet",
              "WALLET",
              Icons.account_balance_wallet,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const OrderSuccessScreen(),
    ),
  );
},
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
                child: const Text(
                  "Place Order",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentTile(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
              bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: RadioListTile(
        value: value,
        groupValue:
            selectedPayment,
        onChanged: (val) {
          setState(() {
            selectedPayment =
                val.toString();
          });
        },
        title: Text(title),
        secondary: Icon(
          icon,
          color:
              Colors.deepPurple,
        ),
      ),
    );
  }
}