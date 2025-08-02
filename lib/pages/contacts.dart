import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<String> contacts = ['+123456789'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (_, index) => ListTile(
            title: Text(contacts[index]),
            trailing: IconButton(
              onPressed: (){
                setState(() => contacts.removeAt(index));
              },
              icon: Icon(Icons.delete),
            ),
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: Icon(Icons.add),
      ),
    );
  }
}
