class AlarmGroup {
  const AlarmGroup({required this.id, required this.name, required this.color,
    this.icon = 'alarm', this.sortOrder = 0});

  final String id;
  final String name;
  final int color;
  final String icon;
  final int sortOrder;

  AlarmGroup copyWith({String? name, int? color, String? icon, int? sortOrder}) =>
    AlarmGroup(id: id, name: name ?? this.name, color: color ?? this.color,
      icon: icon ?? this.icon, sortOrder: sortOrder ?? this.sortOrder);

  Map<String, Object> toJson() => {
    'id': id, 'name': name, 'color': color, 'icon': icon, 'sortOrder': sortOrder,
  };

  factory AlarmGroup.fromJson(Map<String, dynamic> json) => AlarmGroup(
    id: json['id'] as String, name: json['name'] as String? ?? 'گروه',
    color: (json['color'] as num?)?.toInt() ?? 0xff3b82f6,
    icon: json['icon'] as String? ?? 'alarm',
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );
}
