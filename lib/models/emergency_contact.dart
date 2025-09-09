class EmergencyContact {
  final int? id;
  final String name;
  final String phone;
  EmergencyContact({this.id, required this.name, required this.phone});
  Map<String, dynamic> toMap(){
    return {'id': id, 'name': name, 'phone': phone};
  }
  factory EmergencyContact.fromMap(Map<String, dynamic> map){
    return EmergencyContact(id: map['id'], name: map['name'], phone: map['phone'],);
  }
}