class RestaurantChoice {
  final int id;
  final String name;

  RestaurantChoice({required this.id, required this.name});

  factory RestaurantChoice.fromJson(Map<String, dynamic> json) {
    return RestaurantChoice(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? json['label'] ?? '').toString(),
    );
  }
}
