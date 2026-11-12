import os
import sys
import uuid
import time
from pathlib import Path
from supabase import create_client, Client
from dotenv import load_dotenv

# Resolve .env path relative to this file or working directories
possible_env_paths = [
    Path(__file__).resolve().parent / ".env",
    Path.cwd() / "stitch_skillswap_ai" / "backend" / ".env",
    Path.cwd() / "backend" / ".env",
    Path.cwd() / ".env",
]
for p in possible_env_paths:
    if p.exists():
        load_dotenv(dotenv_path=p)
        break
else:
    load_dotenv()

url = os.environ.get("SUPABASE_URL") or "https://lfznzlsziqdepglhmycc.supabase.co"
key = os.environ.get("SUPABASE_ANON_KEY") or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxmem56bHN6aXFkZXBnbGhteWNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0NDg3MDEsImV4cCI6MjEwMjAyNDcwMX0.V8sC97-tp0Kax-mXzsBN5cdDazewE6PHyCp-QUcfHZs"

if not url or not key:
    print("Error: SUPABASE_URL and SUPABASE_ANON_KEY must be provided.")
    sys.exit(1)

supabase: Client = create_client(url, key)

print("Starting to seed database...")

def get_or_create_skill(client: Client, name: str, category: str = "General") -> str:
    try:
        resp = client.table("skills").select("id").ilike("name", name.strip()).execute()
        if resp.data and len(resp.data) > 0:
            return resp.data[0]["id"]
        ins = client.table("skills").insert({"name": name.strip(), "category": category}).execute()
        if ins.data and len(ins.data) > 0:
            return ins.data[0]["id"]
    except Exception as e:
        print(f"Notice resolving skill '{name}': {e}")
    
    # fallback to first skill if available
    try:
        fallback = client.table("skills").select("id").limit(1).execute()
        return fallback.data[0]["id"] if fallback.data else str(uuid.uuid4())
    except Exception:
        return str(uuid.uuid4())

mock_users = [
    {
        "email": f"alex_{uuid.uuid4().hex[:8]}@example.com",
        "password": "password123",
        "profile": {
            "full_name": "Alex Rivera",
            "username": f"alex_design_{uuid.uuid4().hex[:4]}",
            "bio": "Senior video editor & creator looking to learn backend Python automation.",
            "location": "Bangalore",
            "experience_level": "Expert",
            "learning_style": "Visual",
            "time_tokens": 5,
        },
        "teaches": ["Video Editing", "Design"],
        "learns": ["Python", "PostgreSQL"],
    },
    {
        "email": f"maria_{uuid.uuid4().hex[:8]}@example.com",
        "password": "password123",
        "profile": {
            "full_name": "Maria Chen",
            "username": f"maria_creates_{uuid.uuid4().hex[:4]}",
            "bio": "Motion designer & video creator eager to learn AI and Python.",
            "location": "Mumbai",
            "experience_level": "Intermediate",
            "learning_style": "Kinesthetic",
            "time_tokens": 4,
        },
        "teaches": ["Video Editing", "Content Creation"],
        "learns": ["Python", "AI Engineering"],
    },
    {
        "email": f"bob_{uuid.uuid4().hex[:8]}@example.com",
        "password": "password123",
        "profile": {
            "full_name": "Bob Harrison",
            "username": f"bob_video_{uuid.uuid4().hex[:4]}",
            "bio": "Video editor & YouTube creator looking for PostgreSQL & Python mentorship.",
            "location": "Delhi",
            "experience_level": "Advanced",
            "learning_style": "Reading/Writing",
            "time_tokens": 3,
        },
        "teaches": ["Video Editing"],
        "learns": ["Python", "PostgreSQL"],
    },
]

for user_data in mock_users:
    print(f"\nProcessing user {user_data['email']}...")
    try:
        # Create a dedicated client instance for this user session
        user_client: Client = create_client(url, key)
        auth_resp = user_client.auth.sign_up({
            "email": user_data['email'], 
            "password": user_data['password'],
            "options": {
                "data": {
                    "full_name": user_data["profile"]["full_name"],
                    "username": user_data["profile"]["username"]
                }
            }
        })
        
        user_id = auth_resp.user.id if auth_resp.user else None
        
        if not user_id:
            print(f"Failed to create user (no user returned). Email confirmations might be required.")
            continue
            
        print(f"User created with ID: {user_id}")
        user_data["profile"]["id"] = user_id
        
        # Authenticate client with session token so RLS policies (auth.uid() = id) are satisfied
        active_client = user_client
        if auth_resp.session and hasattr(auth_resp.session, 'access_token') and auth_resp.session.access_token:
            active_client.postgrest.auth(auth_resp.session.access_token)
        else:
            try:
                sign_in = user_client.auth.sign_in_with_password({
                    "email": user_data['email'],
                    "password": user_data['password']
                })
                if sign_in.session and hasattr(sign_in.session, 'access_token') and sign_in.session.access_token:
                    active_client.postgrest.auth(sign_in.session.access_token)
            except Exception as sign_in_err:
                print(f"Note: User session setup ({sign_in_err})")

        time.sleep(0.5)
        
        # Upsert profile with authenticated client
        try:
            prof_resp = active_client.table("profiles").upsert(user_data["profile"]).execute()
            print(f"Profile updated successfully for @{user_data['profile']['username']}")
        except Exception as prof_err:
            print(f"Profile upsert notice: {prof_err}")
            
        # Insert skills
        skills_to_insert = []
        for skill_name in user_data["teaches"]:
            skill_id = get_or_create_skill(active_client, skill_name, "Design")
            skills_to_insert.append({
                "user_id": user_id,
                "skill_id": skill_id,
                "type": "TEACH",
                "proficiency_level": user_data["profile"]["experience_level"]
            })
        for skill_name in user_data["learns"]:
            skill_id = get_or_create_skill(active_client, skill_name, "Development")
            skills_to_insert.append({
                "user_id": user_id,
                "skill_id": skill_id,
                "type": "LEARN"
            })
            
        if skills_to_insert:
            try:
                skills_resp = active_client.table("user_skills").insert(skills_to_insert).execute()
                print(f"Linked {len(skills_to_insert)} skills to user.")
            except Exception as skill_err:
                print(f"Skill link notice: {skill_err}")
                
    except Exception as e:
        print(f"Error processing user {user_data['email']}: {e}")

print("\nSeeding complete!")
