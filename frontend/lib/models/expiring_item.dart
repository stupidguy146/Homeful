/// Model for an item returned by analytics /expiring-soon.
class ExpiringItem {
  final String itemId;
  final String name;
  final String? category;
  final int quantity;
  final DateTime? expiryDate;
  final int? daysUntilExpiry;
  final String? imageBase64;
  final bool notifyRecurring;

  ExpiringItem({
    required this.itemId,
    required this.name,
    this.category,
    required this.quantity,
    this.expiryDate,
    this.daysUntilExpiry,
    this.imageBase64,
    this.notifyRecurring = false,
  });

  factory ExpiringItem.fromJson(Map<String, dynamic> json) {
    return ExpiringItem(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      daysUntilExpiry: json['daysUntilExpiry'] != null
          ? (json['daysUntilExpiry'] as num).toInt()
          : null,
      imageBase64: json['imageBase64'] as String?,
      notifyRecurring: (json['notifyRecurring'] ?? false) as bool,
    );
  }
}
