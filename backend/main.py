import os
import logging
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from pydantic import BaseModel
from typing import List
from supabase import create_client, Client
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL", "")
key: str = os.environ.get("SUPABASE_ANON_KEY", "")
if not url or not key:
    raise RuntimeError("SUPABASE_URL and SUPABASE_ANON_KEY must be set")
supabase: Client = create_client(url, key)

# Initialize AI Model for Embeddings (all-MiniLM-L6-v2 outputs 384 dimensions)
print("Loading sentence-transformers model...")
model = SentenceTransformer('all-MiniLM-L6-v2')
print("Model loaded successfully.")

from ai_service import get_ai_provider
ai_provider = get_ai_provider()

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="SkillSwap AI Backend")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000", "http://localhost:8000", "http://127.0.0.1:8000", "http://localhost:8080", "http://127.0.0.1:54992"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        user_resp = supabase.auth.get_user(token)
        if not user_resp or not user_resp.user:
            logger.warning("Authentication failed: Invalid JWT")
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        return user_resp.user
    except Exception as e:
        logger.warning(f"Authentication failed: {e}")
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

class MatchRequest(BaseModel):
    user_id: str
    limit: int = 10

class Skill(BaseModel):
    name: str

class GenerateEmbeddingRequest(BaseModel):
    skills: List[str]

@app.get("/")
def read_root():
    return {"status": "ok", "message": "SkillSwap AI Matching Engine is running"}

@app.post("/api/embeddings")
@limiter.limit("20/minute")
def generate_embeddings(request: Request, payload: GenerateEmbeddingRequest, user = Depends(get_current_user)):
    """
    Generate embeddings for a list of skills.
    Useful when a user adds a new skill.
    """
    try:
        embeddings = model.encode(payload.skills).tolist()
        return {"embeddings": embeddings}
    except Exception as e:
        logger.error(f"Error generating embeddings: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/match")
@limiter.limit("10/minute")
def match_users(request: Request, payload: MatchRequest, user = Depends(get_current_user)):
    """
    Find matching users for a given user_id based on their learning goals and teaching skills.
    """
    if payload.user_id != user.id:
        logger.warning(f"Impersonation attempt: User {user.id} attempted to request matches for {payload.user_id}")
        raise HTTPException(status_code=403, detail="Not authorized to access this resource")

    # 1. Fetch current user's skills
    user_skills_resp = supabase.table('user_skills').select('skill_id, type, skills(name)').eq('user_id', payload.user_id).execute()
    
    my_teaches = {item['skill_id']: item['skills']['name'] for item in user_skills_resp.data if item['type'] == 'TEACH'}
    my_learns = {item['skill_id']: item['skills']['name'] for item in user_skills_resp.data if item['type'] == 'LEARN'}
    
    if not my_teaches or not my_learns:
        return {"matches": []}

    # 2. Find potential matches: users who TEACH what I want to LEARN
    learn_skill_ids = list(my_learns.keys())
    potential_teachers_resp = supabase.table('user_skills').select('user_id, skill_id, proficiency_level, profiles(username, full_name, avatar_url)').in_('skill_id', learn_skill_ids).eq('type', 'TEACH').neq('user_id', payload.user_id).execute()
    
    if not potential_teachers_resp.data:
        return {"matches": []}
        
    potential_user_ids = list(set([item['user_id'] for item in potential_teachers_resp.data]))
    
    # 3. From these potential teachers, see if they want to LEARN what I TEACH
    teach_skill_ids = list(my_teaches.keys())
    potential_learners_resp = supabase.table('user_skills').select('user_id, skill_id').in_('skill_id', teach_skill_ids).eq('type', 'LEARN').in_('user_id', potential_user_ids).execute()
    
    # Map user_id to the skills they want to learn from me
    learners_map = {}
    for item in potential_learners_resp.data:
        uid = item['user_id']
        if uid not in learners_map:
            learners_map[uid] = []
        learners_map[uid].append(item['skill_id'])
        
    # 4. Score and format matches
    matches = []
    teachers_map = {}
    profile_info = {}
    
    for item in potential_teachers_resp.data:
        uid = item['user_id']
        if uid not in teachers_map:
            teachers_map[uid] = []
            prof = item.get('profiles')
            if isinstance(prof, dict):
                profile_info[uid] = prof
            elif isinstance(prof, list) and prof:
                profile_info[uid] = prof[0]
                
        teachers_map[uid].append(item['skill_id'])
        
    for uid in potential_user_ids:
        # A reciprocal match MUST want to learn at least one thing I teach
        if uid not in learners_map:
            continue
            
        skills_they_can_teach_me = teachers_map.get(uid, [])
        skills_they_want_from_me = learners_map.get(uid, [])
        
        if not skills_they_can_teach_me or not skills_they_want_from_me:
            continue
            
        # Base score is number of overlapping skills
        score = len(skills_they_can_teach_me) + len(skills_they_want_from_me)
        similarity = min(0.99, 0.70 + (score * 0.05))
        
        # Get names for explanation
        they_teach_names = [my_learns[sid] for sid in skills_they_can_teach_me]
        they_learn_names = [my_teaches[sid] for sid in skills_they_want_from_me]
        
        prof = profile_info.get(uid, {})
        full_name = prof.get('full_name', 'Someone')
        username = prof.get('username', '')
        avatar_url = prof.get('avatar_url', None)
        
        # Explanation
        teach_str = " and ".join(they_teach_names[:2])
        learn_str = " and ".join(they_learn_names[:2])
        explanation = f"{full_name} is a strong match because you can teach them {learn_str} while they can teach you {teach_str}."
        
        primary_skill = they_teach_names[0] if they_teach_names else "Skills"
        
        matches.append({
            "user_id": uid,
            "username": username,
            "full_name": full_name,
            "avatar_url": avatar_url,
            "skill_name": primary_skill,
            "similarity": similarity,
            "explanation": explanation,
            "score": score
        })
        
    # Sort by score descending
    matches.sort(key=lambda x: x['score'], reverse=True)
    matches = matches[:payload.limit]
    
    # 5. Enhance matches with AI
    # Fetch current user's profile for AI context
    user_prof_resp = supabase.table('profiles').select('full_name, bio, learning_goals').eq('id', payload.user_id).execute()
    user_profile = user_prof_resp.data[0] if user_prof_resp.data else {}
    
    enhanced_matches = ai_provider.enhance_matches(user_profile, matches)
    
    return {"matches": enhanced_matches}
