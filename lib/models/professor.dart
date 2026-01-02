class Professor {
  final int id;
  final String email;
  final String name;
  final int admin;

  Professor({
    required this.id,
    required this.email,
    required this.name,
    this.admin = 0,
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      email: json['Email'] as String? ?? json['email'] as String? ?? '',
      name: json['Name'] as String? ?? json['nume'] as String? ?? '',
      admin: json['Admin'] as int? ?? json['admin'] as int? ?? 0,
    );
  }
}

class AdminListResponse {
  final String requestedBy;
  final int count;
  final List<Professor> admins;

  AdminListResponse({
    required this.requestedBy,
    required this.count,
    required this.admins,
  });

  factory AdminListResponse.fromJson(Map<String, dynamic> json) {
    return AdminListResponse(
      requestedBy: json['requested_by'] as String,
      count: json['count'] as int,
      admins: (json['admins'] as List<dynamic>)
          .map((e) => Professor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
