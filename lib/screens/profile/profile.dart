import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 52,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/200?img=12',
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'FlowLy User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _ProfileTile(
            icon: Icons.palette_outlined,
            title: 'Themes',
            subtitle: 'Customize your FlowLy look',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Playback, privacy and preferences',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Manage your alerts',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
