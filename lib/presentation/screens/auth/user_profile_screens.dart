import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/presentation/screens/spare_parts/spare_part_list.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: const Center(child: Text("Profile Page")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomePage()));
        },
        child: const Icon(Icons.home),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomNavBar(currentIndex: 4),
    );
  }
}
