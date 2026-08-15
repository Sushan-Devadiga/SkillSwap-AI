import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';

class SwapRequestScreen extends StatefulWidget {
  final String userId;
  const SwapRequestScreen({super.key, required this.userId});

  @override
  State<SwapRequestScreen> createState() => _SwapRequestScreenState();
}

class _SwapRequestScreenState extends State<SwapRequestScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Skill Swap'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propose a Swap',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Introduce yourself and propose how you can help each other achieve your learning goals.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Initial Message',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Hi! I saw you want to learn Python and you know Graphic Design. I would love to do a 1-on-1 swap...',
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.surfaceStroke),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Send Request',
              icon: Icons.send,
              onPressed: () {
                // Submit request to Supabase then navigate to chat
                context.go('/chat');
              },
            ),
          ],
        ),
      ),
    );
  }
}
