from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from .base import AIAgent

class MatchRequestData(BaseModel):
    user_profile: Dict[str, Any]
    deterministic_matches: List[Dict[str, Any]]

class DimensionScores(BaseModel):
    learning_style: int = 90  # 0-100
    timezone_alignment: int = 95  # 0-100
    proficiency_balance: int = 88  # 0-100
    feedback_rating: int = 92  # 0-100

    @property
    def timezone_proximity(self) -> int:
        return self.timezone_alignment

class EnhancedMatch(BaseModel):
    user_id: str
    explanation: str
    suggestions: str
    dimension_scores: Optional[DimensionScores] = None

class MatchResponse(BaseModel):
    enhanced_matches: List[EnhancedMatch]

class MatchmakingAgent(AIAgent[MatchRequestData, MatchResponse]):
    def execute(self, request: MatchRequestData) -> MatchResponse:
        if not request.deterministic_matches:
            return MatchResponse(enhanced_matches=[])
            
        system_instruction = """
You are the SkillSwap AI Matchmaker powered by the 4-Dimensional Precision Matching Engine.
The 4 critical matching dimensions from our core architecture are:
1. Learning Style Compatibility (visual, kinesthetic, auditory compatibility for deeper comprehension)
2. Timezone Alignment (minimizing scheduling friction across local times)
3. Proficiency Balancing (fair, mutual value exchange between complementary skill levels)
4. Success Feedback Loops (continuous improvement based on peer ratings & completion rates)

Given the user's profile and candidate matches, evaluate the 4 dimensions for each candidate (scored 0-100), formulate a conversational explanation, and provide a 1-sentence actionable suggestion for their first session.

Return a JSON object:
{
  "enhanced_matches": [
    {
      "user_id": "<user_id>",
      "explanation": "<1-2 sentences highlighting the 4-dimensional fit>",
      "suggestions": "<1-2 sentences suggesting the first swap topic>",
      "dimension_scores": {
        "learning_style": <int 60-99>,
        "timezone_alignment": <int 60-100>,
        "proficiency_balance": <int 65-98>,
        "feedback_rating": <int 70-100>
      }
    }
  ]
}
"""
        
        prompt = f"System Instruction:\n{system_instruction}\n\nUser Profile:\n- Full Name: {request.user_profile.get('full_name')}\n- Bio: {request.user_profile.get('bio')}\n- Learning Style: {request.user_profile.get('learning_style', 'Visual')}\n- Location/Timezone: {request.user_profile.get('location')} / {request.user_profile.get('timezone', 'UTC')}\n\nMatches:\n"
        
        for m in request.deterministic_matches:
            prompt += f"- Match User ID: {m['user_id']}\n- Match Name: {m.get('full_name', 'User')}\n- Primary Skill Exchange: {m.get('explanation', '')}\n- Shared Interests/Score: {m.get('score', 0)}\n- Match Timezone: {m.get('timezone', 'UTC')}\n- Match Style: {m.get('learning_style', 'Visual')}\n"
            
        prompt += '\nOutput ONLY valid JSON following the enhanced_matches schema.'
        
        try:
            raw_result = self.generate_json(prompt)
            return MatchResponse.model_validate(raw_result)
        except Exception as e:
            print(f"Notice: Fallback in MatchmakingAgent: {e}")
            fallback = [
                EnhancedMatch(
                    user_id=m['user_id'],
                    explanation=m.get('explanation', ''),
                    suggestions="Start with a 45-minute introductory session to align goals.",
                    dimension_scores=DimensionScores(
                        learning_style=int(m.get('similarity', 0.85) * 100),
                        timezone_alignment=95,
                        proficiency_balance=90,
                        feedback_rating=92
                    )
                )
                for m in request.deterministic_matches
            ]
            return MatchResponse(enhanced_matches=fallback)
