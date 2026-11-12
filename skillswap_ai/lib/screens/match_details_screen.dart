import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../services/api_service.dart';

class MatchDetailsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String fullName;
  final String skillName;
  final String similarity;
  final String? avatarUrl;

  const MatchDetailsScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.skillName,
    required this.similarity,
    this.avatarUrl,
  });

  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  void _showCurriculumModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurriculumModalSheet(
        userId: widget.userId,
        peerName: widget.fullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty 
                  ? NetworkImage(widget.avatarUrl!) 
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty 
                  ? Text(
                      widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ) 
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.fullName,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, color: AppColors.primaryContainer),
                const SizedBox(width: 8),
                Text(
                  '${widget.similarity}% Compatibility',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            AiSuggestedCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Why this is a great match',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Based on our AI analysis, ${widget.fullName} excels at ${widget.skillName} which aligns with your learning goals. You also possess skills they are eager to acquire.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // 4-DIMENSION AI PRECISION MATCHING CARD (Slide 5)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.compass, size: 16, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AI Precision Matching (4 Dimensions)',
                        style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDimensionBar(
                    icon: LucideIcons.eye,
                    title: 'Learning Style Compatibility',
                    score: 94,
                    subtitle: 'Visual & Kinesthetic learning synergy',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildDimensionBar(
                    icon: LucideIcons.clock,
                    title: 'Timezone Alignment',
                    score: 98,
                    subtitle: 'Aligned local working hours (0h UTC offset)',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _buildDimensionBar(
                    icon: LucideIcons.scale,
                    title: 'Proficiency Balancing',
                    score: 90,
                    subtitle: 'Balanced reciprocal skill exchange ratio',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  _buildDimensionBar(
                    icon: LucideIcons.star,
                    title: 'Success Feedback Loop',
                    score: 96,
                    subtitle: 'High swap completion rate & 5-star history',
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AI CURRICULUM BUTTON
            OutlinedButton.icon(
              onPressed: _showCurriculumModal,
              icon: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
              label: const Text('View AI Session Curriculum'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: AppTypography.labelMd,
              ),
            ),

            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Pass', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: 'Request Swap',
                    icon: Icons.handshake,
                    onPressed: () {
                      context.push('/swap-request/${widget.userId}');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionBar({
    required IconData icon,
    required String title,
    required int score,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score%',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}

class _CurriculumModalSheet extends ConsumerStatefulWidget {
  final String userId;
  final String peerName;

  const _CurriculumModalSheet({
    required this.userId,
    required this.peerName,
  });

  @override
  ConsumerState<_CurriculumModalSheet> createState() => _CurriculumModalSheetState();
}

class _CurriculumModalSheetState extends ConsumerState<_CurriculumModalSheet> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _curriculum = [];

  @override
  void initState() {
    super.initState();
    _fetchCurriculum();
  }

  Future<void> _fetchCurriculum() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.getSessionPlan(widget.userId);

      if (!mounted) return;

      setState(() {
        _curriculum = result;
        _isLoading = false;
        if (_curriculum.isEmpty) {
          _error = 'No curriculum generated yet. Try again in a moment.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to generate curriculum: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Session Roadmap', style: AppTypography.headlineMd),
                      Text(
                        'Curated curriculum for you & ${widget.peerName}',
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceStroke),

          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Generating collaborative curriculum...',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 36),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center, style: AppTypography.bodyMd),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _fetchCurriculum,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        itemCount: _curriculum.length,
                        itemBuilder: (context, index) {
                          final step = _curriculum[index];
                          final order = step['order'] ?? (index + 1);
                          final title = step['title'] ?? 'Session $order';
                          final description = step['description'] ?? '';
                          final isLast = index == _curriculum.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      '$order',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 60,
                                      color: AppColors.surfaceStroke,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.surfaceStroke),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: AppTypography.labelMd),
                                        if (description.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            description,
                                            style: AppTypography.bodySm.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

