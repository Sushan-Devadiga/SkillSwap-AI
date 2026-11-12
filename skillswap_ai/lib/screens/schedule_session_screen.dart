import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../services/session_service.dart';
import '../services/discover_service.dart';
import '../providers/session_provider.dart';
import 'home_screen.dart';

class ScheduleSessionScreen extends ConsumerStatefulWidget {
  final String peerName;
  const ScheduleSessionScreen({super.key, required this.peerName});

  @override
  ConsumerState<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends ConsumerState<ScheduleSessionScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isSubmitting = false;

  final List<String> _availableTimes = [
    '09:00 AM', '10:00 AM', '11:00 AM',
    '01:00 PM', '02:00 PM', '04:00 PM',
    '06:00 PM', '07:30 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meet with ${widget.peerName}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a date and time that works for both of you based on their availability.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            // Date Picker Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceStroke),
              ),
              child: CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),

            if (_selectedDate != null) ...[
              Text(
                'Available Times',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableTimes.map((time) {
                  final isSelected = _selectedTime == time;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceStroke,
                        ),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                PrimaryButton(
                  text: 'Confirm Session',
                  icon: Icons.check_circle_outline,
                  onPressed: () async {
                    if (_selectedTime != null && _selectedDate != null) {
                      setState(() => _isSubmitting = true);
                      try {
                        // Parse time string "09:00 AM" to DateTime
                        final timeParts = _selectedTime!.split(' ');
                        final hm = timeParts[0].split(':');
                        int h = int.parse(hm[0]);
                        final m = int.parse(hm[1]);
                        if (timeParts[1] == 'PM' && h < 12) h += 12;
                        if (timeParts[1] == 'AM' && h == 12) h = 0;
                        
                        final sessionTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, h, m);
                        
                        // Get peer ID (supports username or UUID with case-insensitive match)
                        final discoverService = ref.read(discoverServiceProvider);
                        final peerData = await discoverService.getProfile(widget.peerName);
                        
                        if (peerData != null) {
                          final sessionService = ref.read(sessionServiceProvider);
                          final peerDisplayName = peerData['full_name'] ?? widget.peerName;
                          final success = await sessionService.proposeSession(
                            peerId: peerData['id'],
                            title: 'Skill Swap with $peerDisplayName',
                            time: sessionTime,
                            durationMinutes: 45,
                          );
                          
                          if (success && mounted) {
                            // Instantly invalidate providers so Active Swaps & Home screen update with zero delay
                            ref.invalidate(activeSwapsProvider);
                            ref.invalidate(upcomingSessionsProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Session scheduled successfully!'),
                                backgroundColor: AppColors.primaryContainer,
                              ),
                            );
                            context.pop();
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not schedule session. Please try again.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not find profile for "${widget.peerName}".'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                         debugPrint('Schedule session error: $e');
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text('Error scheduling session: $e'),
                               backgroundColor: AppColors.error,
                             ),
                           );
                         }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    }
                  },
                ),
            ]
          ],
        ),
      ),
    );
  }
}
