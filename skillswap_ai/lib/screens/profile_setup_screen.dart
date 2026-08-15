import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/cards.dart';
import '../widgets/inputs.dart';
import '../widgets/buttons.dart';
import '../providers/profile_provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _timezoneController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _usernameController.text = profile.username;
      _bioController.text = profile.bio;
      _locationController.text = profile.location;
      _timezoneController.text = profile.timezone;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: StandardCard(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar upload
              GestureDetector(
                onTap: _isUploading
                    ? null
                    : () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 80,
                        );

                        if (image != null) {
                          setState(() {
                            _isUploading = true;
                          });
                          try {
                            final storageService = ref.read(storageServiceProvider);
                            final userId = ref.read(authServiceProvider).currentUser?.id;
                            if (userId != null) {
                              await storageService.uploadAvatar(image, userId);
                              // Refresh profile provider so it gets the new avatar URL
                              ref.invalidate(userProfileProvider);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile picture updated')),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to upload image')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isUploading = false;
                              });
                            }
                          }
                        }
                      },
                child: Consumer(builder: (context, ref, _) {
                  final profile = ref.watch(userProfileProvider).value;
                  final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty;
                  
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surfaceStroke),
                          image: hasAvatar && !_isUploading
                              ? DecorationImage(
                                  image: NetworkImage(profile.avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !hasAvatar || _isUploading
                            ? const Icon(Icons.add_a_photo, size: 32, color: AppColors.outline)
                            : null,
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps people understand who they are matching with.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              CustomInputField(
                label: 'Username',
                hintText: 'cool_dev_99',
                controller: _usernameController,
                prefixIcon: const Icon(Icons.alternate_email, color: AppColors.outline),
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Bio',
                hintText: 'I am a software developer looking to learn design...',
                controller: _bioController,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Location (Optional)',
                hintText: 'City, Country',
                controller: _locationController,
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.outline),
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Timezone (Optional)',
                hintText: 'UTC-5, EST, etc.',
                controller: _timezoneController,
                prefixIcon: const Icon(Icons.schedule, color: AppColors.outline),
              ),
              
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: () {
                  if (_usernameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a username.')),
                    );
                    return;
                  }
                  
                  final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
                  ref.read(userProfileProvider.notifier).updateLocalState(
                    currentProfile.copyWith(
                      username: _usernameController.text.trim(),
                      bio: _bioController.text,
                      location: _locationController.text,
                      timezone: _timezoneController.text,
                    )
                  );
                  context.push('/teaching-skills');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
