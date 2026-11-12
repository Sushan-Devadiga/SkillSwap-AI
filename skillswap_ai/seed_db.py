"""
SkillSwap AI - Database Seeder Runner
Delegates execution to stitch_skillswap_ai/backend/seed_db.py
"""
import sys
import subprocess
from pathlib import Path

backend_seed = Path(__file__).resolve().parent.parent / "backend" / "seed_db.py"

if not backend_seed.exists():
    print(f"Error: Could not locate backend seed script at {backend_seed}")
    sys.exit(1)

# Execute the backend seed script using current python interpreter
result = subprocess.run([sys.executable, str(backend_seed)] + sys.argv[1:])
sys.exit(result.returncode)

