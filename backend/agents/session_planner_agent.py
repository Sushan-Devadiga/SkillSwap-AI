from typing import List
from pydantic import BaseModel
from .base import AIAgent

class SkillContext(BaseModel):
    user_id: str
    skill_name: str
    type: str # TEACH or LEARN
    proficiency_level: str

class SessionPlannerRequest(BaseModel):
    user1_name: str
    user2_name: str
    skills: List[SkillContext]

class SessionPlan(BaseModel):
    title: str
    description: str
    order: int

class SessionPlannerResponse(BaseModel):
    curriculum: List[SessionPlan]

class SessionPlannerAgent(AIAgent[SessionPlannerRequest, SessionPlannerResponse]):
    def execute(self, request: SessionPlannerRequest) -> SessionPlannerResponse:
        system_instruction = """
You are the SkillSwap AI Session Planner.
Two users have matched to exchange skills. You are given their names and the skills they are exchanging (with proficiency levels).
Your task is to design a structured multi-session curriculum (3 to 5 sessions) for their skill exchange.
Make it collaborative. Sessions can either focus on one user's skill, or blend both if they are complementary.
Each session should have a clear 'title', a short 'description' of what they will do, and an 'order' (1, 2, 3...).

Return ONLY valid JSON matching this schema:
{
    "curriculum": [
        {"order": 1, "title": "Introduction to X and Y", "description": "..."}
    ]
}
"""
        prompt = f"System Instruction:\n{system_instruction}\n\n"
        prompt += f"User 1: {request.user1_name}\nUser 2: {request.user2_name}\n\nSkills Context:\n"
        for s in request.skills:
            prompt += f"- User {s.user_id} wants to {s.type} {s.skill_name} (Level: {s.proficiency_level})\n"
            
        prompt += '\nOutput JSON format: {"curriculum": [{"order": 1, "title": "...", "description": "..."}]}'
        
        try:
            raw_result = self.generate_json(prompt)
            return SessionPlannerResponse.model_validate(raw_result)
        except Exception as e:
            raise Exception(f"Failed to generate session plan: {e}")
