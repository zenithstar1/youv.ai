import 'package:flutter/material.dart';
import 'package:skin_analysis_app/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFD4999F),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(r.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: r.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: r.h(12)),
              const Text('• Notifications: On'),
              SizedBox(height: r.h(8)),
              const Text('• Account: Manage your account settings'),
            ],
          ),
        ),
      ),
    );
  }
}
