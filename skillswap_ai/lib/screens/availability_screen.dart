import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/profile_provider.dart';
import '../widgets/buttons.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _selectedDays = {};
  
  String _selectedDuration = '60 min';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When are you free?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us find matches whose schedule aligns with yours.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Available Days',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _days.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceStroke,
                      ),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Preferred Session Duration',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.surfaceStroke),
                ),
              ),
              items: ['30 min', '45 min', '60 min'].map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDuration = val;
                  });
                }
              },
            ),
            
            const Spacer(),
            PrimaryButton(
              text: 'Preview Profile',
              icon: Icons.check_circle_outline,
              onPressed: () {
                final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
                final _selectedAvailability = '${_selectedDays.join(", ")} - $_selectedDuration';
                ref.read(userProfileProvider.notifier).updateLocalState(
                  currentProfile.copyWith(availability: _selectedAvailability)
                );
                context.push('/profile-preview');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
