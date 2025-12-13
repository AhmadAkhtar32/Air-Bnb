class Property {
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final int stayDays;

  Property({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.stayDays,
  });

  // Optional: Add a factory constructor for creating from JSON/Map
  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      imageUrl: map['imageUrl'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      price: map['price'] as String,
      stayDays: map['stayDays'] as int,
    );
  }

  // Optional: Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'price': price,
      'stayDays': stayDays,
    };
  }

  // Optional: Override toString for debugging
  @override
  String toString() {
    return 'Property{imageUrl: $imageUrl, title: $title, description: $description, price: $price, stayDays: $stayDays}';
  }
}
