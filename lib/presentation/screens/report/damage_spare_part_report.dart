import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';

class DamageSparePartReport extends StatefulWidget {
  const DamageSparePartReport({super.key});

  @override
  State<DamageSparePartReport> createState() => _DamageSparePartReportState();
}

class _DamageSparePartReportState extends State<DamageSparePartReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text("dasdsa")
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
    );
  }
}