class ServiceModel {
  final bool isActive;
  final int rating;
  final String id;
  final String title;
  final String slug;
  final String description;
  final String imageUrl;
  final bool isPopular;
  final String price;
  final String code;
  final List<dynamic> packages;

  ServiceModel({
    required this.isActive,
    required this.rating,
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.imageUrl,
    required this.isPopular,
    required this.price,
    required this.code,
    required this.packages,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      isActive: json['isActive'] ?? false,
      rating: json['rating'] ?? 0,
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isPopular: json['isPopular'] ?? false,
      price: json['price'] ?? '0',
      code: json['code'] ?? '',
      packages: json['packages'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'rating': rating,
      '_id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'price': price,
      'code': code,
      'packages': packages,
    };
  }
}
