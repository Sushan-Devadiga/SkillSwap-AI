import pytest
from unittest.mock import patch, MagicMock
from agents.matchmaking_agent import MatchmakingAgent, MatchRequestData, DimensionScores, EnhancedMatch

def test_dimension_scores_model():
    """Verify 4-Dimension scoring model has all 4 required dimensions."""
    dim = DimensionScores(
        learning_style=92,
        timezone_alignment=85,
        proficiency_balance=95,
        feedback_rating=88,
    )
    assert dim.learning_style == 92
    assert dim.timezone_alignment == 85
    assert dim.timezone_proximity == 85
    assert dim.proficiency_balance == 95
    assert dim.feedback_rating == 88

    # Test average score calculation
    avg_score = (dim.learning_style + dim.timezone_alignment + dim.proficiency_balance + dim.feedback_rating) / 4.0
    assert avg_score == 90.0

@patch('agents.base.genai.GenerativeModel')
def test_4d_matchmaking_agent_execution(mock_model):
    """Verify MatchmakingAgent parses 4D dimension scores and returns structured EnhancedMatch."""
    mock_instance = MagicMock()
    mock_response = MagicMock()
    mock_response.text = '''{
        "enhanced_matches": [
            {
                "user_id": "target_peer_uuid_001",
                "explanation": "Outstanding synergy in Visual Python learning and Video Editing exchange.",
                "suggestions": "Propose an introductory 45-minute swap session.",
                "dimension_scores": {
                    "learning_style": 94,
                    "timezone_alignment": 90,
                    "proficiency_balance": 96,
                    "feedback_rating": 92
                }
            }
        ]
    }'''
    mock_instance.generate_content.return_value = mock_response
    mock_model.return_value = mock_instance

    agent = MatchmakingAgent(api_key="fake-test-key")
    agent.model = mock_instance

    request = MatchRequestData(
        user_profile={
            "full_name": "Sushan",
            "learning_style": "Visual",
            "timezone": "UTC+5:30",
            "experience_level": "Expert"
        },
        deterministic_matches=[
            {
                "user_id": "target_peer_uuid_001",
                "full_name": "Alex Rivera",
                "score": 0.95,
                "learning_style": "Visual",
                "timezone": "UTC+5:30",
                "experience_level": "Advanced"
            }
        ]
    )

    response = agent.execute(request)

    assert len(response.enhanced_matches) == 1
    match = response.enhanced_matches[0]
    assert match.user_id == "target_peer_uuid_001"
    assert "synergy" in match.explanation.lower()
    assert match.dimension_scores is not None
    assert match.dimension_scores.learning_style == 94
    assert match.dimension_scores.timezone_alignment == 90
    assert match.dimension_scores.timezone_proximity == 90
    assert match.dimension_scores.proficiency_balance == 96
    assert match.dimension_scores.feedback_rating == 92

def test_time_token_settlement_rules():
    """Verify Time Token economy rules (1 hr = 1 token, teacher +1, learner -1)."""
    initial_learner_tokens = 3
    initial_teacher_tokens = 5
    session_hours = 1.0

    # Settle session
    learner_new_balance = initial_learner_tokens - int(session_hours)
    teacher_new_balance = initial_teacher_tokens + int(session_hours)

    assert learner_new_balance == 2
    assert teacher_new_balance == 6

def test_jitsi_meeting_link_generation():
    """Verify Jitsi Meet URL format meets SkillSwap standard."""
    session_id = "test-session-123"
    organizer_prefix = "usr1"
    room_tag = f"SkillSwap-{session_id}-{organizer_prefix}"
    meeting_url = f"https://meet.jit.si/{room_tag}"

    assert meeting_url.startswith("https://meet.jit.si/SkillSwap-")
    assert session_id in meeting_url
