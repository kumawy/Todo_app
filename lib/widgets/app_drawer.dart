import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {


    return Drawer(
      backgroundColor: const Color(0xFF4143D1),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Color(0xFF4143D1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(radius: 30),
                SizedBox(height: 10),
                Text("aslan", style: TextStyle(color: Colors.white)),
                Text("aslanmuratov@gmail.com", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
              leading: Icon(Icons.home, color: Colors.white),
              title: Text("Home", style: TextStyle(color: Colors.white)),
              onTap: () {
                context.push('/');
              }
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text("Settings", style: TextStyle(color: Colors.white)),
            onTap: (){
              context.push('/settings');
            },
          ),
          ListTile(
              leading: Icon(Icons.calendar_month, color: Colors.white),
              title: Text("Calendar", style: TextStyle(color: Colors.white)),
              onTap: (){
                context.push('/calendar');
              }
          ),
          ListTile(
              leading: Icon(Icons.notifications, color: Colors.white),
              title: Text("Notifications", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications');
              }
          ),
        ],
      ),
    );
  }
}
