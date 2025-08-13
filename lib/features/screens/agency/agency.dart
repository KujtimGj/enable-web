import 'package:flutter/material.dart';
import '../../components/auth_status_widget.dart';
import '../../../core/auth_utils.dart';

class AgencyView extends StatefulWidget {
  const AgencyView({super.key});

  @override
  State<AgencyView> createState() => _AgencyViewState();
}

class _AgencyViewState extends State<AgencyView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Dashboard'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authentication status widget
            const AuthStatusWidget(),

          ],
        ),
      ),
    );
  }
}
