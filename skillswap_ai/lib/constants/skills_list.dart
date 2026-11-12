import 'package:flutter/material.dart';

const List<String> popularSkills = [
  'Python', 'UI/UX Design', 'Flutter', 'React', 'Photography', 'Marketing', 'SQL', 
  'Spanish', 'Java', 'C++', 'JavaScript', 'TypeScript', 'Node.js', 'Express.js',
  'MongoDB', 'PostgreSQL', 'Machine Learning', 'Data Analysis', 'Data Science',
  'Graphic Design', 'Figma', 'Adobe Illustrator', 'Video Editing', 'Premiere Pro',
  'SEO', 'Copywriting', 'Content Writing', 'Public Speaking', 'Digital Marketing',
  'Social Media Marketing', 'Project Management', 'Agile', 'Scrum', 'Leadership',
  'Accounting', 'Finance', 'Investing', 'French', 'German', 'Mandarin', 'Japanese',
  'Guitar', 'Piano', 'Singing', 'Cooking', 'Baking', 'Fitness', 'Yoga', 'Meditation',
  'AWS', 'Docker', 'Kubernetes', 'Cybersecurity', 'Ethical Hacking', 'Blockchain',
  'Web3', 'Solidity', 'Go', 'Rust', 'Swift', 'Kotlin', 'Android Development',
  'iOS Development', 'Game Development', 'Unity', 'Unreal Engine', '3D Modeling',
  'Blender', 'Animation', 'Illustration', 'Drawing', 'Painting', 'Dancing'
];

/// Curated top picks shown on the screen to avoid overwhelming users with 50+ chips.
const List<String> trendingSkills = [
  'Python',
  'UI/UX Design',
  'Flutter',
  'Machine Learning',
  'Video Editing',
  'Figma',
  'Digital Marketing',
  'Spanish',
  'Data Science',
  'Web3',
];

String getSkillCategory(String skill) {
  final s = skill.toLowerCase();
  if (s.contains('python') || s.contains('flutter') || s.contains('react') || s.contains('sql') ||
      s.contains('java') || s.contains('c++') || s.contains('script') || s.contains('node') ||
      s.contains('mongo') || s.contains('postgres') || s.contains('learning') || s.contains('data') ||
      s.contains('aws') || s.contains('docker') || s.contains('kubernetes') || s.contains('security') ||
      s.contains('blockchain') || s.contains('web3') || s.contains('solidity') || s.contains('go') ||
      s.contains('rust') || s.contains('swift') || s.contains('kotlin') || s.contains('development') ||
      s.contains('unity') || s.contains('engine')) {
    return 'Development';
  }
  if (s.contains('design') || s.contains('figma') || s.contains('illustrator') || s.contains('video') ||
      s.contains('premiere') || s.contains('photo') || s.contains('blender') || s.contains('animation') ||
      s.contains('drawing') || s.contains('painting') || s.contains('3d') || s.contains('illustration')) {
    return 'Design';
  }
  if (s.contains('marketing') || s.contains('seo') || s.contains('writing') || s.contains('speaking') ||
      s.contains('management') || s.contains('agile') || s.contains('scrum') || s.contains('leadership') ||
      s.contains('finance') || s.contains('accounting') || s.contains('investing')) {
    return 'Business';
  }
  if (s.contains('spanish') || s.contains('french') || s.contains('german') || s.contains('mandarin') ||
      s.contains('japanese') || s.contains('english')) {
    return 'Languages';
  }
  return 'Lifestyle & Arts';
}

Color getSkillCategoryColor(String category) {
  switch (category) {
    case 'Development':
      return const Color(0xFF10B981); // Emerald
    case 'Design':
      return const Color(0xFF8B5CF6); // Violet
    case 'Business':
      return const Color(0xFFF59E0B); // Amber
    case 'Languages':
      return const Color(0xFF3B82F6); // Blue
    default:
      return const Color(0xFFEC4899); // Pink
  }
}

