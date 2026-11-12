import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/profile_service.dart';
import '../constants/skills_list.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  String _experienceLevel = '';
  String? _newAvatarUrl;
  bool _avatarUploading = false;
  bool _isSaving = false;

  late Set<String> _teachingSkills;
  late Set<String> _learningSkills;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _experienceLevel = profile?.experienceLevel ?? '';
    _teachingSkills = profile?.teachingSkills.toSet() ?? {};
    _learningSkills = profile?.learningSkills.toSet() ?? {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() => _avatarUploading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;
      final storageService = ref.read(storageServiceProvider);
      final url = await storageService.uploadAvatar(picked, user.id, updateProfileTable: true);
      if (url != null) {
        setState(() => _newAvatarUrl = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(LucideIcons.checkCircle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Photo updated!')]),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 1. Update profile details
      await ref.read(userProfileProvider.notifier).updateProfileDetails(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
      );

      // 2. Update experience_level directly (not in updateProfileDetails)
      if (_experienceLevel.isNotEmpty) {
        final profileService = ref.read(profileServiceProvider);
        await profileService.upsertProfile(user.id, {
          'experience_level': _experienceLevel,
        });
      }

      // 3. Update skills
      final profileService = ref.read(profileServiceProvider);
      List<Map<String, dynamic>> userSkillsData = [];

      for (String skillName in _teachingSkills) {
        final skillId = await profileService.getOrCreateSkill(skillName);
        if (skillId != null) {
          userSkillsData.add({
            'user_id': user.id,
            'skill_id': skillId,
            'type': 'TEACH',
            'proficiency_level': _experienceLevel.isNotEmpty ? _experienceLevel : 'Intermediate',
          });
        }
      }

      for (String skillName in _learningSkills) {
        final skillId = await profileService.getOrCreateSkill(skillName);
        if (skillId != null) {
          userSkillsData.add({
            'user_id': user.id,
            'skill_id': skillId,
            'type': 'LEARN',
          });
        }
      }

      if (userSkillsData.isNotEmpty) {
        await profileService.saveUserSkills(user.id, userSkillsData);
      } else {
        // If all skills removed, delete existing ones
        final client = ref.read(supabaseClientProvider);
        await client.from('user_skills').delete().eq('user_id', user.id);
      }

      // 4. Refresh
      await ref.read(userProfileProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(LucideIcons.checkCircle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Profile saved successfully!')]),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSkillPicker({required bool isTeaching}) {
    final selectedSkills = isTeaching ? _teachingSkills : _learningSkills;
    final title = isTeaching ? 'Edit Teaching Skills' : 'Edit Learning Skills';
    final accentColor = isTeaching ? AppColors.primary : const Color(0xFF6366F1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SkillPickerSheet(
        title: title,
        accentColor: accentColor,
        initialSelected: selectedSkills.toSet(),
        onSave: (updated) {
          setState(() {
            if (isTeaching) {
              _teachingSkills = updated;
            } else {
              _learningSkills = updated;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : AppColors.surfaceBg;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest;
    final strokeColor = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textPrimary = isDark ? Colors.white : AppColors.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    final currentAvatarUrl = _newAvatarUrl ?? profile?.avatarUrl ?? '';
    final hasAvatar = currentAvatarUrl.isNotEmpty;
    final displayInitial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: screenBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTypography.headlineLg.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(LucideIcons.check, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // ─── AVATAR SECTION ───
          Center(
            child: GestureDetector(
              onTap: _avatarUploading ? null : _pickAndUploadAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: hasAvatar ? NetworkImage(currentAvatarUrl) : null,
                      child: _avatarUploading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : (!hasAvatar
                              ? Text(displayInitial, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))
                              : null),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: screenBg, width: 3),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Tap to change photo',
              style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 24),

          // ─── PERSONAL DETAILS SECTION ───
          _buildSectionHeader('Personal Details', LucideIcons.user, textPrimary),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: strokeColor),
            ),
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: LucideIcons.user,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: LucideIcons.atSign,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  prefix: '@',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: LucideIcons.fileText,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  maxLines: 3,
                  hint: 'Tell others about yourself...',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: LucideIcons.mapPin,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  hint: 'e.g. Bangalore, India',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── EXPERIENCE LEVEL ───
          _buildSectionHeader('Experience Level', LucideIcons.barChart2, textPrimary),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: strokeColor),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Beginner', 'Intermediate', 'Advanced', 'Expert'].map((level) {
                final isSelected = _experienceLevel == level;
                return GestureDetector(
                  onTap: () => setState(() => _experienceLevel = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : strokeColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          level,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ─── TEACHING SKILLS ───
          _buildSkillSection(
            title: 'Skills I Teach',
            icon: LucideIcons.graduationCap,
            accentColor: AppColors.primary,
            skills: _teachingSkills.toList(),
            onEdit: () => _showSkillPicker(isTeaching: true),
            onRemove: (s) => setState(() => _teachingSkills.remove(s)),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            strokeColor: strokeColor,
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // ─── LEARNING SKILLS ───
          _buildSkillSection(
            title: 'Skills I Want to Learn',
            icon: LucideIcons.bookOpen,
            accentColor: const Color(0xFF6366F1),
            skills: _learningSkills.toList(),
            onEdit: () => _showSkillPicker(isTeaching: false),
            onRemove: (s) => setState(() => _learningSkills.remove(s)),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            strokeColor: strokeColor,
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // ─── SAVE BUTTON ───
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.save, size: 18),
              label: Text(_isSaving ? 'Saving Changes...' : 'Save All Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    int maxLines = 1,
    String? hint,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon, size: 18, color: textSecondary),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSkillSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<String> skills,
    required VoidCallback onEdit,
    required void Function(String) onRemove,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color strokeColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.4) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: strokeColor, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 28, color: textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'No skills added yet',
                    style: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      'Tap + Add to get started',
                      style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) {
                return Container(
                  padding: const EdgeInsets.only(left: 14, right: 6, top: 7, bottom: 7),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, size: 13, color: accentColor),
                      const SizedBox(width: 6),
                      Text(s, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => onRemove(s),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.x, size: 14, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── SKILL PICKER BOTTOM SHEET ───
class _SkillPickerSheet extends StatefulWidget {
  final String title;
  final Color accentColor;
  final Set<String> initialSelected;
  final void Function(Set<String>) onSave;

  const _SkillPickerSheet({
    required this.title,
    required this.accentColor,
    required this.initialSelected,
    required this.onSave,
  });

  @override
  State<_SkillPickerSheet> createState() => _SkillPickerSheetState();
}

class _SkillPickerSheetState extends State<_SkillPickerSheet> {
  late Set<String> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toSet();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredSkills {
    final allSkills = <String>{...popularSkills, ..._selected};
    if (_searchQuery.isEmpty) return allSkills.toList();
    return allSkills.where((s) => s.toLowerCase().contains(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;
    final strokeColor = isDark ? const Color(0xFF334155) : Colors.grey.shade300;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.headlineMd.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selected.length} selected',
                    style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search skills...',
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: textSecondary),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: strokeColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Add custom skill option
          if (_searchQuery.isNotEmpty && !popularSkills.any((s) => s.toLowerCase() == _searchQuery))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InkWell(
                onTap: () {
                  final capitalizedSkill = _searchController.text.trim().split(' ').map((w) {
                    if (w.isEmpty) return w;
                    return w[0].toUpperCase() + w.substring(1);
                  }).join(' ');
                  setState(() {
                    _selected.add(capitalizedSkill);
                    _searchController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.plusCircle, size: 18, color: widget.accentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Add "${_searchController.text.trim()}" as custom skill',
                        style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Skills grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filteredSkills.map((skill) {
                    final isSelected = _selected.contains(skill);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(skill);
                          } else {
                            _selected.add(skill);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.accentColor : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? widget.accentColor : strokeColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: widget.accentColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              skill,
                              style: TextStyle(
                                color: isSelected ? Colors.white : textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onSave(_selected);
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.check, size: 18),
                label: Text('Done (${_selected.length} skills)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

