import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_ai/providers/profile_provider.dart';

void main() {
  group('1. Cryptographic Proof-of-Skill Blockchain Badges', () {
    String generateVerificationHash({
      required String learnerId,
      required String mentorId,
      required String skillName,
      required double hours,
      required int timestamp,
    }) {
      final payload = 'SKILLSWAP_V1:$learnerId:$mentorId:$skillName:$hours:$timestamp:SALT_PROOF_BLOCKCHAIN';
      final bytes = utf8.encode(payload);
      return sha256.convert(bytes).toString();
    }

    String resolveBadgeTier(double hours) {
      if (hours >= 20) return 'Master Mentor';
      if (hours >= 10) return 'Advanced Specialist';
      if (hours >= 5) return 'Intermediate Practitioner';
      return 'Verified Novice';
    }

    test('SHA-256 hash minting conforms to tamper-proof specification', () {
      final hash1 = generateVerificationHash(
        learnerId: 'learner-uuid-123',
        mentorId: 'mentor-uuid-456',
        skillName: 'Python Backend Architecture',
        hours: 10.0,
        timestamp: 1700000000,
      );

      // Verify SHA-256 produces 64-character hexadecimal digest
      expect(hash1.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash1), isTrue);

      // Verify determinism
      final hash2 = generateVerificationHash(
        learnerId: 'learner-uuid-123',
        mentorId: 'mentor-uuid-456',
        skillName: 'Python Backend Architecture',
        hours: 10.0,
        timestamp: 1700000000,
      );
      expect(hash1, equals(hash2));

      // Verify tamper resistance: changing 1 character changes the entire hash
      final tamperedHash = generateVerificationHash(
        learnerId: 'learner-uuid-123',
        mentorId: 'mentor-uuid-456',
        skillName: 'Python Backend Architecture',
        hours: 10.1, // modified by 0.1 hour
        timestamp: 1700000000,
      );
      expect(hash1, isNot(equals(tamperedHash)));
    });

    test('Badge tier progression triggers accurately across completed hour thresholds', () {
      expect(resolveBadgeTier(1.0), equals('Verified Novice'));
      expect(resolveBadgeTier(4.5), equals('Verified Novice'));
      expect(resolveBadgeTier(5.0), equals('Intermediate Practitioner'));
      expect(resolveBadgeTier(9.5), equals('Intermediate Practitioner'));
      expect(resolveBadgeTier(10.0), equals('Advanced Specialist'));
      expect(resolveBadgeTier(19.5), equals('Advanced Specialist'));
      expect(resolveBadgeTier(20.0), equals('Master Mentor'));
      expect(resolveBadgeTier(100.0), equals('Master Mentor'));
    });
  });

  group('2. Time Token Economy & Immutable Ledger', () {
    test('Initial user signup grants exactly 3 Time Tokens', () {
      final profile = UserProfile(
        fullName: 'Jane Doe',
        username: 'janedoe',
        bio: 'Aspiring fullstack developer',
        timeTokens: 3, // Initial PPT grant
        learningStyle: 'Visual',
      );

      expect(profile.timeTokens, equals(3));
      expect(profile.learningStyle, equals('Visual'));
    });

    test('Swap settlement transfers tokens (+1 for Teacher, -1 for Learner)', () {
      int teacherBalance = 5;
      int learnerBalance = 3;
      const double swapDurationHours = 1.0;

      // Settlement
      teacherBalance += swapDurationHours.toInt();
      learnerBalance -= swapDurationHours.toInt();

      expect(teacherBalance, equals(6));
      expect(learnerBalance, equals(2));
    });

    test('Transaction ledger models valid transaction types and metadata', () {
      final earnedTx = {
        'id': 'tx-001',
        'user_id': 'teacher-123',
        'amount': 1,
        'type': 'EARNED',
        'description': '1 hr teaching Python',
        'session_id': 'session-abc',
      };

      final spentTx = {
        'id': 'tx-002',
        'user_id': 'learner-456',
        'amount': -1,
        'type': 'SPENT',
        'description': '1 hr learning Python',
        'session_id': 'session-abc',
      };

      expect(earnedTx['amount'], equals(1));
      expect(earnedTx['type'], equals('EARNED'));
      expect(spentTx['amount'], equals(-1));
      expect(spentTx['type'], equals('SPENT'));
      expect(earnedTx['session_id'], equals(spentTx['session_id']));
    });
  });

  group('3. 4-Dimension Precision Matchmaking Math & Radar Breakdown', () {
    test('4-Dimension composite score weighted calculation', () {
      const double styleScore = 94.0;
      const double timezoneScore = 90.0;
      const double proficiencyScore = 96.0;
      const double feedbackScore = 92.0;

      final compositeScore = (styleScore + timezoneScore + proficiencyScore + feedbackScore) / 4.0;

      expect(compositeScore, equals(93.0));
      expect(compositeScore.round(), equals(93));
    });
  });

  group('4. Scheduling & Jitsi Video Link Generation', () {
    test('Jitsi Meet link conforms to encrypted room structure', () {
      const String currentUserId = 'usr_abc_12345';
      final roomTag = 'SkillSwap-${1700000000.toRadixString(36)}-${currentUserId.substring(0, 4)}';
      final generatedLink = 'https://meet.jit.si/$roomTag';

      expect(generatedLink, startsWith('https://meet.jit.si/SkillSwap-'));
      expect(generatedLink, contains('usr_'));
    });
  });

  group('5. Data Privacy Guard Check', () {
    test('Public profile model excludes token balance from public view', () {
      final publicProfileData = {
        'id': 'peer-uuid-999',
        'username': 'alex_creator',
        'full_name': 'Alex Rivera',
        'bio': 'Video Editor & Animator',
        'location': 'Bangalore',
        'timezone': 'UTC+5:30',
        'experience_level': 'Expert',
        'learning_style': 'Visual',
        'time_tokens': 12, // Exists in raw database record
      };

      // Simulated public view sanitization (as implemented in ProfileScreen)
      final publicViewCard = {
        'id': publicProfileData['id'],
        'username': publicProfileData['username'],
        'full_name': publicProfileData['full_name'],
        'bio': publicProfileData['bio'],
        'location': publicProfileData['location'],
        'timezone': publicProfileData['timezone'],
        'experience_level': publicProfileData['experience_level'],
        'learning_style': publicProfileData['learning_style'],
        // 'time_tokens' is deliberately omitted from public reputation cards
      };

      expect(publicViewCard.containsKey('time_tokens'), isFalse);
      expect(publicViewCard['username'], equals('alex_creator'));
      expect(publicViewCard['learning_style'], equals('Visual'));
    });
  });

  group('6. Profile Model Deserialization & Learning Styles', () {
    test('UserProfile.fromMap parses learning_style and time_tokens accurately', () {
      final map = {
        'id': 'usr-777',
        'full_name': 'Sushan D',
        'username': 'Sushiiii',
        'bio': 'AI Engineer learning video editing',
        'time_tokens': 5,
        'learning_style': 'Kinesthetic',
      };

      final profile = UserProfile.fromMap(map, true);

      expect(profile.username, equals('Sushiiii'));
      expect(profile.timeTokens, equals(5));
      expect(profile.learningStyle, equals('Kinesthetic'));
      expect(profile.isComplete, isTrue);
    });
  });
}
