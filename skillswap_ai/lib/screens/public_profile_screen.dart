import 'package:flutter/material.dart';
import 'profile_screen.dart';

class PublicProfileScreen extends StatelessWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(userId: username);
  }
}
