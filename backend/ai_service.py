import os
import json
import google.generativeai as genai
from typing import List, Dict, Any
from abc import ABC, abstractmethod

class AIProvider(ABC):
    @abstractmethod
    def enhance_matches(self, user_profile: Dict[str, Any], deterministic_matches: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        pass

class FallbackProvider(AIProvider):
    def enhance_matches(self, user_profile: Dict[str, Any], deterministic_matches: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        # Just return the original matches, perhaps adding an empty suggestions string
        for match in deterministic_matches:
            match['suggestions'] = ""
        return deterministic_matches

class GeminiProvider(AIProvider):
    def __init__(self, api_key: str):
        genai.configure(api_key=api_key)
        # Use a model that supports JSON generation well
        self.model = genai.GenerativeModel('gemini-2.5-flash', generation_config={"response_mime_type": "application/json"})

    def enhance_matches(self, user_profile: Dict[str, Any], deterministic_matches: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        if not deterministic_matches:
            return []

        # Prepare the prompt
        system_instruction = """
You are the SkillSwap AI Matchmaker. 
You are given a user's profile and a list of deterministically calculated candidate matches (who teach what the user wants to learn, and want to learn what the user teaches).
Your job is to provide a highly personalized, conversational explanation of WHY they are a good match, and a short, actionable suggestion for their first skill-exchange session.

Rules:
1. Do NOT hallucinate skills or users. Only use the provided data.
2. Return a JSON array where each object has 'user_id' (matching the input user_id), 'explanation' (1-2 sentences), and 'suggestions' (1-2 sentences).
3. Do not modify the original 'score' or 'similarity'. 
4. Output ONLY valid JSON containing an array of match enhancement objects.
"""
        
        prompt = f"""
System Instruction:
{system_instruction}

User Profile:
- Full Name: {user_profile.get('full_name')}
- Bio: {user_profile.get('bio')}
- Learning Goals: {user_profile.get('learning_goals', [])}

Matches:
"""
        for m in deterministic_matches:
            prompt += f"""
- Match User ID: {m['user_id']}
- Match Name: {m['full_name']}
- Primary Skill Exchange: {m['explanation']}
- Shared Interests/Score: {m['score']}
"""
            
        prompt += "\nOutput JSON format: [{\"user_id\": \"...\", \"explanation\": \"...\", \"suggestions\": \"...\"}]"

        try:
            response = self.model.generate_content(prompt)
            ai_data = json.loads(response.text)
            
            # Merge back into deterministic_matches
            ai_map = {item['user_id']: item for item in ai_data if 'user_id' in item}
            
            for match in deterministic_matches:
                uid = match['user_id']
                if uid in ai_map:
                    match['explanation'] = ai_map[uid].get('explanation', match['explanation'])
                    match['suggestions'] = ai_map[uid].get('suggestions', "")
                else:
                    match['suggestions'] = ""
                    
            return deterministic_matches
        except Exception as e:
            print(f"Error in GeminiProvider: {e}")
            # Fallback to deterministic
            for match in deterministic_matches:
                match['suggestions'] = ""
            return deterministic_matches

def get_ai_provider() -> AIProvider:
    api_key = os.environ.get("GEMINI_API_KEY")
    if api_key:
        print("Initializing Gemini AI Provider")
        return GeminiProvider(api_key)
    print("Initializing Fallback AI Provider")
    return FallbackProvider()
