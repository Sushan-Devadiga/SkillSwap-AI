import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';

class DayInfo {
  final String short;
  final String full;

  const DayInfo(this.short, this.full);
}

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final List<DayInfo> _allDays = const [
    DayInfo('Mon', 'Monday'),
    DayInfo('Tue', 'Tuesday'),
    DayInfo('Wed', 'Wednesday'),
    DayInfo('Thu', 'Thursday'),
    DayInfo('Fri', 'Friday'),
    DayInfo('Sat', 'Saturday'),
    DayInfo('Sun', 'Sunday'),
  ];

  final Set<String> _selectedDays = {'Mon', 'Wed', 'Fri'};
  String _selectedDuration = '60 min';
  final Set<String> _preferredTimeSlots = {'Evening'};

  final List<Map<String, dynamic>> _durationOptions = const [
    {
      'value': '30 min',
      'label': '30 mins',
      'tag': 'Quick Sprint',
      'desc': 'Fast sync, direct Q&A, and concise code review.',
      'icon': LucideIcons.timer,
    },
    {
      'value': '45 min',
      'label': '45 mins',
      'tag': 'Popular',
      'desc': 'Ideal peer learning balance with room for hands-on practice.',
      'icon': LucideIcons.clock,
    },
    {
      'value': '60 min',
      'label': '60 mins',
      'tag': 'Deep Dive',
      'desc': 'Full exchange: pair programming, debugging, and milestone feedback.',
      'icon': LucideIcons.hourglass,
    },
  ];

  final List<Map<String, dynamic>> _timeSlotOptions = const [
    {'name': 'Morning', 'time': '8 AM - 12 PM', 'icon': LucideIcons.sunMedium},
    {'name': 'Afternoon', 'time': '12 PM - 5 PM', 'icon': LucideIcons.sun},
    {'name': 'Evening', 'time': '5 PM - 10 PM', 'icon': LucideIcons.moon},
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && profile.availability.isNotEmpty) {
      // Parse saved availability e.g. "Mon, Wed, Fri - 60 min"
      final parts = profile.availability.split(' - ');
      if (parts.isNotEmpty) {
        final days = parts[0].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        if (days.isNotEmpty) {
          _selectedDays.clear();
          _selectedDays.addAll(days);
        }
      }
      if (parts.length > 1) {
        _selectedDuration = parts[1].trim();
      }
    }
  }

  void _handleContinue() {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
    final selectedAvailability = '${_selectedDays.join(", ")} - $_selectedDuration';

    ref.read(userProfileProvider.notifier).updateLocalState(
          currentProfile.copyWith(availability: selectedAvailability),
        );
    context.push('/profile-preview');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryEmerald = Color(0xFF059669);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Availability',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 6 / 7, // Step 6 of 7
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
                                'STEP 6 OF 7',
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
                              'Schedule Matching',
                              style: AppTypography.bodySm.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // HEADLINE & SUBTITLE
                        Text(
                          'When are you free?',
                          style: AppTypography.headlineLg.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This helps SkillSwap AI match you with peers whose weekly routines align with yours.',
                          style: AppTypography.bodyMd.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // SECTION 1: DAYS SELECTION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Days',
                              style: AppTypography.headlineMd.copyWith(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDays.clear();
                                      _selectedDays.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      'Weekdays',
                                      style: TextStyle(
                                        color: primaryEmerald,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDays.clear();
                                      _selectedDays.addAll(['Sat', 'Sun']);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      'Weekends',
                                      style: TextStyle(
                                        color: primaryEmerald,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDays.clear();
                                      _selectedDays.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      'All Days',
                                      style: TextStyle(
                                        color: primaryEmerald,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 7 DAYS TILES GRID
                        Row(
                          children: _allDays.map((day) {
                            final isSelected = _selectedDays.contains(day.short);

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        if (_selectedDays.length > 1) {
                                          _selectedDays.remove(day.short);
                                        }
                                      } else {
                                        _selectedDays.add(day.short);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                                              : const Color(0xFFECFDF5))
                                          : bgCard,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? primaryEmerald : strokeColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? primaryEmerald.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          day.short,
                                          style: TextStyle(
                                            color: isSelected ? primaryEmerald : textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected ? primaryEmerald : Colors.transparent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // SECTION 2: PREFERRED DURATION CARDS
                        Text(
                          'Preferred Session Duration',
                          style: AppTypography.headlineMd.copyWith(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Each completed hour of swap exchanges 1 Time Token.',
                          style: AppTypography.bodySm.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 14),

                        Column(
                          children: _durationOptions.map((opt) {
                            final isSelected = _selectedDuration == opt['value'];
                            final icon = opt['icon'] as IconData;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDuration = opt['value'] as String;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                              : const Color(0xFFECFDF5))
                                          : bgCard,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? primaryEmerald : strokeColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? primaryEmerald.withValues(alpha: 0.18)
                                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: isSelected ? primaryEmerald : textSecondary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    opt['label'] as String,
                                                    style: AppTypography.headlineMd.copyWith(
                                                      color: textPrimary,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? primaryEmerald.withValues(alpha: 0.15)
                                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      opt['tag'] as String,
                                                      style: TextStyle(
                                                        color: isSelected ? primaryEmerald : textSecondary,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                opt['desc'] as String,
                                                style: AppTypography.bodySm.copyWith(color: textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected ? primaryEmerald : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected ? primaryEmerald : strokeColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // SECTION 3: TIME OF DAY SLOTS
                        Text(
                          'Preferred Time Window',
                          style: AppTypography.headlineMd.copyWith(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _timeSlotOptions.map((slot) {
                            final name = slot['name'] as String;
                            final isSelected = _preferredTimeSlots.contains(name);
                            final icon = slot['icon'] as IconData;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        if (_preferredTimeSlots.length > 1) {
                                          _preferredTimeSlots.remove(name);
                                        }
                                      } else {
                                        _preferredTimeSlots.add(name);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
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
                                    child: Column(
                                      children: [
                                        Icon(
                                          icon,
                                          color: isSelected ? primaryEmerald : textSecondary,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: isSelected ? primaryEmerald : textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          slot['time'] as String,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // STICKY BOTTOM BUTTON
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
                          onPressed: _handleContinue,
                          icon: const Icon(LucideIcons.sparkles, size: 18),
                          label: Text(
                            'Preview Profile (${_selectedDays.length} Days • $_selectedDuration)',
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
