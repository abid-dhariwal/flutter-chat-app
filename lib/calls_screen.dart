import 'package:flutter/material.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.call, color: Colors.white),
            ),
            title: Text('Call with User ${index + 1}'),
            subtitle: const Text('Yesterday, 6:45 PM'),
            trailing: const Icon(Icons.call_received, color: Colors.green),
          );
        },
      ),
    );
  }
}
