import os
from agents.base import AIAgent
from agents.matchmaking_agent import MatchmakingAgent
from agents.onboarding_agent import OnboardingAgent
from agents.session_planner_agent import SessionPlannerAgent

# We can provide simple getters for the agents to abstract API key injection
def get_matchmaking_agent() -> MatchmakingAgent:
    return MatchmakingAgent(api_key=os.environ.get("GEMINI_API_KEY"))

def get_onboarding_agent() -> OnboardingAgent:
    return OnboardingAgent(api_key=os.environ.get("GEMINI_API_KEY"))

def get_session_planner_agent() -> SessionPlannerAgent:
    return SessionPlannerAgent(api_key=os.environ.get("GEMINI_API_KEY"))
