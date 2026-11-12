import pytest
from unittest.mock import patch, MagicMock
from agents.onboarding_agent import OnboardingAgent, OnboardingRequest
from agents.matchmaking_agent import MatchmakingAgent, MatchRequestData

@patch('agents.base.genai.GenerativeModel')
def test_onboarding_agent(mock_model):
    # Mock the Gemini response
    mock_instance = MagicMock()
    mock_response = MagicMock()
    mock_response.text = '{"skills": [{"skill_name": "Flutter", "type": "TEACH", "proficiency_level": "Advanced", "confidence": 0.95}]}'
    mock_instance.generate_content.return_value = mock_response
    mock_model.return_value = mock_instance

    agent = OnboardingAgent(api_key="fake-key")
    agent.model = mock_instance # Override manually if needed, but the init handles it

    request = OnboardingRequest(description="I can teach advanced Flutter.")
    response = agent.execute(request)

    assert len(response.skills) == 1
    assert response.skills[0].skill_name == "Flutter"
    assert response.skills[0].type == "TEACH"
    assert response.skills[0].proficiency_level == "Advanced"

@patch('agents.base.genai.GenerativeModel')
def test_matchmaking_agent(mock_model):
    # Mock the Gemini response
    mock_instance = MagicMock()
    mock_response = MagicMock()
    mock_response.text = '{"enhanced_matches": [{"user_id": "u123", "explanation": "Perfect match!", "suggestions": "Say hi!"}]}'
    mock_instance.generate_content.return_value = mock_response
    mock_model.return_value = mock_instance

    agent = MatchmakingAgent(api_key="fake-key")
    agent.model = mock_instance

    request = MatchRequestData(
        user_profile={"full_name": "Bob"},
        deterministic_matches=[{"user_id": "u123", "score": 2}]
    )
    response = agent.execute(request)

    assert len(response.enhanced_matches) == 1
    assert response.enhanced_matches[0].user_id == "u123"
    assert response.enhanced_matches[0].explanation == "Perfect match!"

@patch('agents.base.genai.GenerativeModel')
def test_session_planner_agent(mock_model):
    from agents.session_planner_agent import SessionPlannerAgent, SessionPlannerRequest, SkillContext
    
    # Mock the Gemini response
    mock_instance = MagicMock()
    mock_response = MagicMock()
    mock_response.text = '{"curriculum": [{"order": 1, "title": "Intro to DB", "description": "Learn basic queries"}]}'
    mock_instance.generate_content.return_value = mock_response
    mock_model.return_value = mock_instance

    agent = SessionPlannerAgent(api_key="fake-key")
    agent.model = mock_instance

    request = SessionPlannerRequest(
        user1_name="Alice",
        user2_name="Bob",
        skills=[
            SkillContext(user_id="1", skill_name="SQL", type="TEACH", proficiency_level="Expert")
        ]
    )
    response = agent.execute(request)

    assert len(response.curriculum) == 1
    assert response.curriculum[0].order == 1
    assert response.curriculum[0].title == "Intro to DB"
