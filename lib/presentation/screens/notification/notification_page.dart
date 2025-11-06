import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/application/providers/notification_provider.dart';
import 'package:sparix/data/models/notification.dart' as model;
import 'package:sparix/presentation/screens/spare_parts/spare_part_details_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().start();
    });
  }

  @override
  void dispose() {
    context.read<NotificationProvider>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text('Error: ${provider.error}'));
                }
                final items = provider.items;
                if (items.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }
                return ListView.separated(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final n = items[index];
                    return _NotificationCard(
                      item: n,
                      onOpen: () async {
                        await context
                            .read<NotificationProvider>()
                            .markRead(n.notifId, value: true);
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SparePartDetailsPage(productId: n.productId),
                          ),
                        );
                      },
                      onDelete: () async {
                        await context
                            .read<NotificationProvider>()
                            .remove(n.notifId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final model.Notification item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(item);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: item.read ? Colors.grey[600] : Colors.black87,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: item.read ? Colors.grey[500] : Colors.black87,
    );
    final dateStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: item.read ? Colors.grey[400] : Colors.grey[700],
    );

    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      color: item.read ? Colors.grey[100] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        onLongPress: () => _showActionSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _buildThumbnail(item),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!item.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: dateStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete notification?'),
          backgroundColor: Colors.white,
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) onDelete();
    }
  }

  Widget _buildThumbnail(model.Notification n) {
    final url = n.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Image.asset(
        'assets/icons/Sparix_logo.png',
        fit: BoxFit.cover,
      );
    }
    return FadeInImage.assetNetwork(
      placeholder: 'assets/icons/Sparix_logo.png',
      image: url,
      fit: BoxFit.cover,
      imageErrorBuilder: (_, __, ___) => Image.asset(
        'assets/icons/Sparix_logo.png',
        fit: BoxFit.cover,
      ),
    );
  }

  String _formatDate(model.Notification n) {
    final dt = n.createdAt;
    return DateFormat('yMMMd • HH:mm').format(dt);
  }
}
