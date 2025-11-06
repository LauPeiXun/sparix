import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/presentation/screens/supplier_order/supplier_order_main_page.dart';
import 'package:sparix/presentation/screens/workshop_order/workshop_order_main_page.dart';

import '../damange_spare_part/damage_spare_part_report_list.dart';
import 'add_edit_spare_part_screens.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.white,
      appBar: const CustomAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Option Cards
                  _buildOptionCard(
                    context: context,
                    title: 'Supplier Orders',
                    subtitle: 'Manage and track supplier orders',
                    icon: Icons.local_shipping,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3498DB), Color(0xFF5DADE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const SupplierOrderMainPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  _buildOptionCard(
                    context: context,
                    title: 'Workshop Orders',
                    subtitle: 'Handle workshop service requests',
                    icon: Icons.build,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B59B6), Color(0xFFBB8FCE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const WorkshopOrderMainPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.88,
                      height: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildOptionCard(
                    context: context,
                    title: 'Add New Spare Part',
                    subtitle: 'Register and manage spare parts inventory',
                    icon: Icons.add,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF568F87),
                        Color(0xFF76AFA7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AddEditSparePartScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.88,
                      height: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildOptionCard(
                    context: context,
                    title: 'Damage Report',
                    subtitle: 'Log and track damaged spare parts',
                    icon: Icons.report_problem,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF5252),
                        Color(0xFFFF867C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const DamageSparePartReportList(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[100]!,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),

                      const SizedBox(width: 15),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),

                            Text(
                              subtitle,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 14,
                                color: gradient.colors.first,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      const SizedBox(width: 15),

                      // Arrow Icon
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF2C3E50),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}