import 'package:flutter/material.dart';
import 'package:sparix/presentation/screens/spare_parts/spare_part_list.dart';
import 'package:sparix/presentation/screens/spare_parts/menu_page.dart';
import 'package:sparix/presentation/screens/qr_scanner/qr_scanner_page.dart';
import 'package:sparix/presentation/screens/profile/user_profile_page.dart';
import 'package:sparix/presentation/screens/report/report_menu_page.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({super.key, required this.currentIndex});

  void _onTabSelected(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MenuPage()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const QRScannerPage()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ReportMenuPage()));
        break;
      case 4:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const UserProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(context, Icons.search, 0),
          _navIcon(context, Icons.inventory, 1),
          _navIcon(context, Icons.qr_code_scanner, 2),
          _navIcon(context, Icons.dashboard, 3),
          _navIcon(context, Icons.person, 4),
        ],
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, int index) {
    return IconButton(
      icon: Icon(icon),
      iconSize:  30.0,
      color: currentIndex == index ? Colors.green : Colors.grey,
      onPressed: () => _onTabSelected(context, index),
    );
  }
}
