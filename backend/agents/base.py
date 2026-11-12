import os
import json
import google.generativeai as genai
from typing import Any, Dict, TypeVar, Generic
from pydantic import BaseModel
from abc import ABC, abstractmethod

TIn = TypeVar('TIn', bound=BaseModel)
TOut = TypeVar('TOut', bound=BaseModel)

class AIAgent(ABC, Generic[TIn, TOut]):
    def __init__(self, api_key: str = None):
        key = api_key or os.environ.get("GEMINI_API_KEY")
        if key:
            genai.configure(api_key=key)
            self.model = genai.GenerativeModel('gemini-2.5-flash', generation_config={"response_mime_type": "application/json"})
        else:
            self.model = None

    @abstractmethod
    def execute(self, request: TIn) -> TOut:
        """Execute the agent's primary task."""
        pass
        
    def generate_json(self, prompt: str) -> Dict[str, Any]:
        if not self.model:
            raise RuntimeError("GEMINI_API_KEY not set or invalid for agent execution.")
        try:
            response = self.model.generate_content(prompt)
            return json.loads(response.text)
        except Exception as e:
            raise Exception(f"AI generation failed: {e}")
