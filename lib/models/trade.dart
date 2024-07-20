class Trade {
  final int id;
  final String ticker;
  final String company;
  final double unitPrice;
  final double quantity;
  final DateTime date;
  final String type;

  Trade({
    required this.id,
    required this.ticker,
    required this.company,
    required this.unitPrice,
    required this.quantity,
    required this.date,
    required this.type,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'],
      ticker: json['ticker'],
      company: json['company'],
      unitPrice: json['unit_price'].toDouble(),
      quantity: json['quantity'].toDouble(),
      date: DateTime.parse(json['date']),
      type: json['type'],
    );
  }
}
