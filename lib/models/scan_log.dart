class ScanLog {
  final int idElev;
  final DateTime scanTime;
  final String token;
  final String name;

  ScanLog({
    required this.idElev,
    required this.scanTime,
    required this.token,
    required this.name,
  });

  factory ScanLog.fromJson(Map<String, dynamic> json) {
    return ScanLog(
      idElev: json['id_elev'] as int,
      scanTime: DateTime.parse(json['scan_time'] as String),
      token: json['token'] as String,
      name: json['name'] as String,
    );
  }
}

class ScanLogResponse {
  final int count;
  final DateTime start;
  final DateTime end;
  final List<ScanLog> data;

  ScanLogResponse({
    required this.count,
    required this.start,
    required this.end,
    required this.data,
  });

  factory ScanLogResponse.fromJson(Map<String, dynamic> json) {
    return ScanLogResponse(
      count: json['count'] as int,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      data: (json['data'] as List<dynamic>)
          .map((e) => ScanLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
