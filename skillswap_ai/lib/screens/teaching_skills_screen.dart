import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/chips.dart';
import '../widgets/buttons.dart';
import '../providers/profile_provider.dart';
import '../constants/skills_list.dart';

class TeachingSkillsScreen extends ConsumerStatefulWidget {
  const TeachingSkillsScreen({super.key});

  @override
  ConsumerState<TeachingSkillsScreen> createState() => _TeachingSkillsScreenState();
}

class _TeachingSkillsScreenState extends ConsumerState<TeachingSkillsScreen> {
  late final Set<String> _selectedSkills;

  @override
  void initState() {
    super.initState();
    _selectedSkills = ref.read(userProfileProvider).value?.teachingSkills.toSet() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Skills'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What can you teach?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select skills you are proficient in and willing to share.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return popularSkills.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase()) && 
                         !_selectedSkills.contains(option);
                });
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedSkills.add(selection);
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (String value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        _selectedSkills.add(value.trim());
                        textEditingController.clear();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search or add skills...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: AppColors.surfaceStroke),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: MediaQuery.of(context).size.width - 40, // 20 padding on each side
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._selectedSkills.map((skill) {
                    return SkillChip(
                      label: skill,
                      isSelected: true,
                      onTap: () {
                        setState(() {
                          _selectedSkills.remove(skill);
                        });
                      },
                    );
                  }),
                  ...popularSkills.take(50).where((s) => !_selectedSkills.contains(s)).map((skill) {
                    return SkillChip(
                      label: skill,
                      isSelected: false,
                      onTap: () {
                        setState(() {
                          _selectedSkills.add(skill);
                        });
                      },
                    );
                  })
                ],
              ),
            ),
            ),
            
            PrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: () {
                final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
                ref.read(userProfileProvider.notifier).updateLocalState(
                  currentProfile.copyWith(teachingSkills: _selectedSkills.toList())
                );
                context.push('/proficiency');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
