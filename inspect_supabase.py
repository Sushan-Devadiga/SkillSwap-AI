import os
import requests
from dotenv import load_dotenv

load_dotenv('skillswap_ai/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY')

headers = {
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
}

tables_to_check = [
    'user_skills_teach',
    'user_skills_learn',
]

print("Supabase Table Introspection part 2:")
for table in tables_to_check:
    url = f"{SUPABASE_URL}/rest/v1/{table}?limit=1"
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        print(f"Table '{table}': EXISTS (Status 200)")
    elif response.status_code == 404:
        print(f"Table '{table}': DOES NOT EXIST (Status 404)")
    elif response.status_code == 406:
        print(f"Table '{table}': DOES NOT EXIST (Status 406)")
    else:
        print(f"Table '{table}': STATUS {response.status_code}")
