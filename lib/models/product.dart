class Product {
  final int? id;
  final String name;
  final double buyingPrice;
  final double price;
  final int quantity;
  final int minimumStockLevel;
  final String? barcode;
  final String? category;
  final String? supplier;
  final String? dateAdded;
  final String? expiryDate;

  Product({
    this.id,
    required this.name,
    required this.buyingPrice,
    required this.price,
    required this.quantity,
    this.minimumStockLevel = 10,
    this.barcode,
    this.category,
    this.supplier,
    this.dateAdded,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'buyingPrice': buyingPrice,
      'price': price,
      'quantity': quantity,
      'minimum_stock_level': minimumStockLevel,
      'barcode': barcode,
      'category': category,
      'supplier': supplier,
      'date_added': dateAdded ?? DateTime.now().toIso8601String(),
      'expiry_date': expiryDate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      minimumStockLevel: map['minimum_stock_level'] as int? ?? 10,
      barcode: map['barcode'] as String?,
      category: map['category'] as String?,
      supplier: map['supplier'] as String?,
      dateAdded: map['date_added'] as String?,
      expiryDate: map['expiry_date'] as String?,
    );
  }
}
