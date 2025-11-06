import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sparix/application/providers/employee_provider.dart';
import 'package:sparix/core/services/firebase_auth_service.dart';
import 'package:sparix/data/models/employee.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/presentation/screens/auth/login_screen.dart';
import 'package:sparix/presentation/screens/auth/change_password_screen.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  void _loadEmployeeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final employeeProvider = context.read<EmployeeProvider>();
        await employeeProvider.getEmployeeById(user.uid);
        
        // Load profile image using Firebase Auth UID (since images are stored by UID, not employee ID)
        await employeeProvider.getEmployeeProfileImage(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Consumer<EmployeeProvider>(
        builder: (context, employeeProvider, child) {
          if (employeeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileImageSection(),
                  const SizedBox(height: 30),
                  _buildUserInfoSection(employeeProvider.currentEmployee),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 4),
    );
  }

  Widget _buildProfileImageSection() {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, child) {
        return Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: employeeProvider.profileImageUrl.isNotEmpty 
                        ? NetworkImage(employeeProvider.profileImageUrl)
                        : null,
                    child: employeeProvider.profileImageUrl.isEmpty 
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoSection(Employee? employee) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.credit_card,
          title: 'Employee ID',
          value: employee?.employeeId ?? 'Not available',
        ),
        const SizedBox(height: 1),
        _buildInfoCard(
          icon: Icons.person_outline,
          title: 'Name',
          value: employee?.name ?? user?.displayName ?? 'Not available',
        ),
        const SizedBox(height: 1),
        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          value: employee?.gmail ?? user?.email ?? 'Not available',
        ),
        const SizedBox(height: 15),
        _buildActionInfoCard(
          icon: Icons.password,
          title: 'Change Password',
        ),
        /*
        const SizedBox(height: 15),
        _buildActionInfoCard(
          icon: Icons.admin_panel_settings,
          title: 'Role & Permission',
        ),
         */
      ],
    );
  }

  Widget _buildActionInfoCard({
    required IconData icon,
    required String title,
  }) {
    return InkWell(
      onTap: () {
        if (title == 'Change Password') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        }
        // Add other navigation logic here for other cards if needed
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[500],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _authService.signOut();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to logout: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}