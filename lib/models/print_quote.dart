class PrintQuote {
  final String id;
  final String customerName;
  final String paperType;
  final String format;
  final int pages;
  final bool isColor;
  final bool doubleSided;
  final int quantity;
  final String binding;
  final double paperCost;
  final double inkCost;
  final double laborCost;
  final double totalCost;
  final double suggestedPrice;
  final DateTime createdAt;

  PrintQuote({
    required this.id,
    required this.customerName,
    required this.paperType,
    required this.format,
    required this.pages,
    required this.isColor,
    required this.doubleSided,
    required this.quantity,
    required this.binding,
    required this.paperCost,
    required this.inkCost,
    required this.laborCost,
    required this.totalCost,
    required this.suggestedPrice,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'paperType': paperType,
      'format': format,
      'pages': pages,
      'isColor': isColor,
      'doubleSided': doubleSided,
      'quantity': quantity,
      'binding': binding,
      'paperCost': paperCost,
      'inkCost': inkCost,
      'laborCost': laborCost,
      'totalCost': totalCost,
      'suggestedPrice': suggestedPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PrintQuote.fromMap(Map<String, dynamic> map) {
    return PrintQuote(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      paperType: map['paperType'] ?? '',
      format: map['format'] ?? '',
      pages: map['pages'] ?? 0,
      isColor: map['isColor'] ?? false,
      doubleSided: map['doubleSided'] ?? false,
      quantity: map['quantity'] ?? 0,
      binding: map['binding'] ?? '',
      paperCost: (map['paperCost'] ?? 0).toDouble(),
      inkCost: (map['inkCost'] ?? 0).toDouble(),
      laborCost: (map['laborCost'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      suggestedPrice: (map['suggestedPrice'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
