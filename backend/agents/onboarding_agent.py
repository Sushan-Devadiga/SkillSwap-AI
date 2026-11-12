from pydantic import BaseModel
from typing import List, Literal
from .base import AIAgent

class ExtractedSkill(BaseModel):
    skill_name: str
    type: Literal['TEACH', 'LEARN']
    proficiency_level: Literal['Beginner', 'Intermediate', 'Advanced', 'Expert'] = 'Beginner'
    confidence: float

class OnboardingRequest(BaseModel):
    description: str

class OnboardingResponse(BaseModel):
    skills: List[ExtractedSkill]

class OnboardingAgent(AIAgent[OnboardingRequest, OnboardingResponse]):
    def execute(self, request: OnboardingRequest) -> OnboardingResponse:
        system_instruction = """
You are the SkillSwap AI Onboarding Assistant.
A user has provided a free-text description of skills they can teach and skills they want to learn.
Your task is to extract these into a structured JSON list.

For each skill:
- `skill_name`: The name of the skill (e.g., "Python", "Graphic Design").
- `type`: "TEACH" if they are offering to teach it, "LEARN" if they want to learn it.
- `proficiency_level`: "Beginner", "Intermediate", "Advanced", or "Expert". Estimate this based on their description, default to "Beginner" if unknown.
- `confidence`: Your confidence score in this extraction (0.0 to 1.0).

Return ONLY valid JSON containing an array of objects matching this schema. Example:
{
    "skills": [
        {"skill_name": "React", "type": "TEACH", "proficiency_level": "Advanced", "confidence": 0.9}
    ]
}
"""
        prompt = f"System Instruction:\n{system_instruction}\n\nUser Description:\n{request.description}"
        
        try:
            raw_result = self.generate_json(prompt)
            return OnboardingResponse.model_validate(raw_result)
        except Exception as e:
            raise Exception(f"Failed to process onboarding: {e}")
