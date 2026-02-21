class PayType {
  final int? id;
  final String name;

  PayType({this.id, required this.name});

  PayType copyWith({int? id, String? name}) => PayType(id: id ?? this.id, name: name ?? this.name);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory PayType.fromMap(Map<String, dynamic> m) => PayType(id: m['id'] as int?, name: m['name'] as String);
}
