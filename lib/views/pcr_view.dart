import 'package:flutter/material.dart';

class PCRView extends StatelessWidget {
  const PCRView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'PCR View',
          style: TextStyle(fontSize: 18, color: Color(0xFF8B909A)),
        ),
      ),
    );
  }
}