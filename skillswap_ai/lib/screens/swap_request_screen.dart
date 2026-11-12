import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/offline_banner.dart';
import '../services/connection_service.dart';
import '../services/connectivity_service.dart';
import '../providers/session_provider.dart';

class SwapRequestScreen extends ConsumerStatefulWidget {
  final String userId;
  const SwapRequestScreen({super.key, required this.userId});

  @override
  ConsumerState<SwapRequestScreen> createState() => _SwapRequestScreenState();
}

class _SwapRequestScreenState extends ConsumerState<SwapRequestScreen> {
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSendRequest() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final connService = ref.read(connectionServiceProvider);
      final success = await connService.sendRequest(widget.userId);

      if (!mounted) return;

      if (success) {
        ref.invalidate(activeSwapsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swap request sent successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/chat');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send swap request. You may already have a pending connection with this user.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Skill Swap'),
      ),
      body: OfflineBanner(
        child: SingleChildScrollView(
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
                enabled: !_isSubmitting && isOnline,
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
                text: !isOnline
                    ? 'Offline (No Connection)'
                    : (_isSubmitting ? 'Sending Request...' : 'Send Request'),
                icon: !isOnline ? Icons.wifi_off : (_isSubmitting ? null : Icons.send),
                onPressed: (!isOnline || _isSubmitting) ? () {} : _handleSendRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

