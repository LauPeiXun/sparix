// lib/presentation/models/receive_item.dart
class ReceiveItem {
  final String name;
  final String imageUrl;
  final double unitPriceRm;
  final int orderedQty;

  const ReceiveItem({
    required this.name,
    required this.orderedQty,
    this.imageUrl = '',
    this.unitPriceRm = 0.0,
  });
}
