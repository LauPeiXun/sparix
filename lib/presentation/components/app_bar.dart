import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparix/presentation/screens/notification/notification_page.dart';
import 'package:sparix/application/providers/notification_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icons/Sparix_logo.png',
              height: 32,
              width: 32,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SPARIX',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 24,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notif, _) {
            final int unread = notif.unreadCount;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black,
                    size: 33,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                ),

                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
