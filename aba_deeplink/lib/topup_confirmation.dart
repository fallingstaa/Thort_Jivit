import 'package:flutter/material.dart';

class TopUpConfirmationScreen extends StatelessWidget {
  const TopUpConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5D34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F5D34),
        title: Text('Confirmation',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        leading: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_back_ios,color: Colors.white,),),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Main Content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),

                      // Wallet Icon
                      Image.asset('assets/logos/wallet-check.png'),

                      const SizedBox(height: 24),

                      // Top up details heading
                      const Text(
                        'Top up details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        'Amount are ready to send',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Transaction details
                      _buildDetailRow('Amount', '\$50.00'),

                      _buildDetailRow('Account name', 'Vannputhika Suon'),

                      _buildDetailRow('Account number', '00000000'),

                      _buildDetailRow('Date', 'Jul 7, 2024'),

                      _buildDetailRow('Time', '5:00 pm'),

                      _buildDetailRow(
                        'Status',
                        'Ready to sent',
                        valueColor: const Color(0xFF0F5D34),
                        valueFontWeight: FontWeight.bold,
                      ),

                      const SizedBox(height: 40),

                      // Check out button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.person,
                                color: Color(0xFF0F5D34),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Check out',
                                style: TextStyle(
                                  color: Color(0xFF0F5D34),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value, {
        Color valueColor = Colors.black87,
        FontWeight valueFontWeight = FontWeight.w600,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor,
              fontWeight: valueFontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
