class CrashLog {
  final int? id;
  final String timestamp;
  final String location;

  CrashLog({this.id, required this.timestamp, required this.location});

  Map<String, dynamic> toMap() {
    return {'id': id, 'timestamp': timestamp, 'location': location};
  }

  factory CrashLog.fromMap(Map<String, dynamic> map) {
    return CrashLog(
      id: map['id'],
      timestamp: map['timestamp'],
      location: map['location'],
    );
  }
}