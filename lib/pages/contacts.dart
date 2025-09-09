import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/emergency_contact.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final dbHelper = DatabaseHelper();
  List<EmergencyContact> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final data = await dbHelper.getContacts();
    setState(() => contacts = data);
  }

  void _addContact() {
    String name = '';
    String phone = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Emergency Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(hintText: "Enter name"),
              onChanged: (val) => name = val,
            ),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: "Enter phone number"),
              onChanged: (val) => phone = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (name.isNotEmpty && phone.isNotEmpty) {
                await dbHelper.insertContact(EmergencyContact(name: name, phone: phone));
                _loadContacts();
              }
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteContact(int id) async {
    await dbHelper.deleteContact(id);
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emergency Contacts")),
      body: contacts.isEmpty
          ? Center(child: Text("No contacts yet"))
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (_, index) {
          final contact = contacts[index];
          return ListTile(
            title: Text(contact.name),
            subtitle: Text(contact.phone),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteContact(contact.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: Icon(Icons.add),
      ),
    );
  }
}