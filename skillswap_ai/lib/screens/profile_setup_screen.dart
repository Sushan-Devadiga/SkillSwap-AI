import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _timezoneController = TextEditingController();

  String _selectedLearningStyle = 'Visual';
  bool _isUploading = false;
  bool _isCheckingUsername = false;

  final List<Map<String, dynamic>> _learningStyles = const [
    {
      'style': 'Visual',
      'desc': 'Diagrams, charts, screenshares & visual mindmaps',
      'icon': LucideIcons.eye,
    },
    {
      'style': 'Auditory',
      'desc': 'Audio discussions, podcast-style explanations & Q&A',
      'icon': LucideIcons.headphones,
    },
    {
      'style': 'Kinesthetic',
      'desc': 'Hands-on live coding, instant debugging & building',
      'icon': LucideIcons.hammer,
    },
    {
      'style': 'Reading/Writing',
      'desc': 'Documentation, markdown notes & code snippets',
      'icon': LucideIcons.bookOpen,
    },
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _usernameController.text = profile.username;
      _fullNameController.text = profile.fullName;
      _bioController.text = profile.bio;
      _locationController.text = profile.location;
      _timezoneController.text = profile.timezone;
      if (profile.learningStyle.isNotEmpty) {
        _selectedLearningStyle = profile.learningStyle;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_isCheckingUsername) return;
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a username.')),
      );
      return;
    }

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be at least 3 characters.')),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username can only contain letters, numbers, and underscores.')),
      );
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    try {
      final currentUserId = ref.read(authServiceProvider).currentUser?.id ?? '';
      final profileService = ref.read(profileServiceProvider);
      final isAvailable = await profileService.isUsernameAvailable(username, currentUserId);

      if (!mounted) return;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The username "@$username" is already taken. Please choose another one.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
      ref.read(userProfileProvider.notifier).updateLocalState(
            currentProfile.copyWith(
              username: username,
              fullName: _fullNameController.text.trim().isNotEmpty
                  ? _fullNameController.text.trim()
                  : currentProfile.fullName,
              bio: _bioController.text.trim(),
              location: _locationController.text.trim(),
              timezone: _timezoneController.text.trim(),
              learningStyle: _selectedLearningStyle,
            ),
          );
      context.push('/teaching-skills');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error validating username: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    if (_isUploading) return;
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
          final imageUrl = await storageService.uploadAvatar(image, userId, updateProfileTable: false);
          if (imageUrl != null) {
            final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
            ref.read(userProfileProvider.notifier).updateLocalState(
                  currentProfile.copyWith(avatarUrl: imageUrl),
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture selected successfully!')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image. Please try again.')),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryEmerald = Color(0xFF059669);

    final profile = ref.watch(userProfileProvider).value;
    final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Profile Setup',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1 / 7, // Step 1 of 7
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryEmerald),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STEP BADGE
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryEmerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'STEP 1 OF 7',
                                style: TextStyle(
                                  color: primaryEmerald,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Basic Information',
                              style: AppTypography.bodySm.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // HEADLINE & SUBTITLE
                        Text(
                          'Tell us about yourself',
                          style: AppTypography.headlineLg.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Set up your public identity and learning preferences so our AI matches you with compatible peers.',
                          style: AppTypography.bodyMd.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // AVATAR PICKER
                        Center(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    border: Border.all(
                                      color: primaryEmerald,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryEmerald.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                    image: hasAvatar && !_isUploading
                                        ? DecorationImage(
                                            image: NetworkImage(profile.avatarUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: !hasAvatar || _isUploading
                                      ? Center(
                                          child: _isUploading
                                              ? const SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(primaryEmerald),
                                                  ),
                                                )
                                              : Icon(
                                                  LucideIcons.user,
                                                  size: 40,
                                                  color: textSecondary,
                                                ),
                                        )
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    color: primaryEmerald,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Tap to upload photo',
                            style: AppTypography.bodySm.copyWith(color: textSecondary),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // USERNAME FIELD
                        Text(
                          'Username *',
                          style: AppTypography.bodySm.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: strokeColor),
                          ),
                          child: TextField(
                            controller: _usernameController,
                            style: TextStyle(color: textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'alex_codes',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8)),
                              prefixIcon: const Icon(LucideIcons.atSign, size: 18, color: primaryEmerald),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // FULL NAME FIELD
                        Text(
                          'Full Name',
                          style: AppTypography.bodySm.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: strokeColor),
                          ),
                          child: TextField(
                            controller: _fullNameController,
                            style: TextStyle(color: textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Alex Johnson',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8)),
                              prefixIcon: const Icon(LucideIcons.user, size: 18, color: primaryEmerald),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // BIO FIELD
                        Text(
                          'Bio',
                          style: AppTypography.bodySm.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: strokeColor),
                          ),
                          child: TextField(
                            controller: _bioController,
                            maxLines: 3,
                            style: TextStyle(color: textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Fullstack developer learning UI/UX. Passionate about AI agents and clean code architecture...',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // LOCATION & TIMEZONE ROW
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location',
                                    style: AppTypography.bodySm.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: bgCard,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: strokeColor),
                                    ),
                                    child: TextField(
                                      controller: _locationController,
                                      style: TextStyle(color: textPrimary, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'City, Country',
                                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8)),
                                        prefixIcon: const Icon(LucideIcons.mapPin, size: 16, color: primaryEmerald),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Timezone',
                                    style: AppTypography.bodySm.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: bgCard,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: strokeColor),
                                    ),
                                    child: TextField(
                                      controller: _timezoneController,
                                      style: TextStyle(color: textPrimary, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'UTC+5:30 (IST)',
                                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8)),
                                        prefixIcon: const Icon(LucideIcons.globe, size: 16, color: primaryEmerald),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // LEARNING STYLE SELECTOR (4D Matchmaking Algorithm)
                        Row(
                          children: [
                            const Icon(LucideIcons.brain, color: primaryEmerald, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Your Primary Learning Style',
                              style: AppTypography.headlineMd.copyWith(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SkillSwap Matchmaking uses this dimension to calculate style synergy.',
                          style: AppTypography.bodySm.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 12),

                        ..._learningStyles.map((item) {
                          final style = item['style'] as String;
                          final desc = item['desc'] as String;
                          final icon = item['icon'] as IconData;
                          final isSelected = _selectedLearningStyle == style;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedLearningStyle = style;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                          : const Color(0xFFECFDF5))
                                      : bgCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? primaryEmerald : strokeColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryEmerald.withValues(alpha: 0.18)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 18,
                                        color: isSelected ? primaryEmerald : textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            style,
                                            style: TextStyle(
                                              color: isSelected ? primaryEmerald : textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            desc,
                                            style: TextStyle(color: textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? primaryEmerald : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? primaryEmerald : strokeColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // STICKY BOTTOM CONTINUE BUTTON
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgCard,
                    border: Border(top: BorderSide(color: strokeColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingUsername ? null : _handleContinue,
                          icon: _isCheckingUsername
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(LucideIcons.arrowRight, size: 18),
                          label: Text(
                            _isCheckingUsername ? 'Validating Username...' : 'Continue to Teaching Skills',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
