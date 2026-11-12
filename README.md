# SkillSwap AI 🚀
> **Intelligent Peer-to-Peer Reciprocal Skill Exchange Platform**

SkillSwap AI is a full-stack mobile application that replaces monetary barriers to learning with reciprocal skill exchanges powered by a **Time Token Economy**, **semantic vector matching**, and **multi-agent Generative AI**.

---

## 🌟 Core Features

- **Reciprocal AI Matchmaking:** Dual-layer matching engine combining 384-dimensional dense semantic vector embeddings (`all-MiniLM-L6-v2`) via PostgreSQL `pgvector` with a Gemini Generative AI Agent for contextual match explanations and icebreakers.
- **Time Token Economy:** 1 hour teaching = 1 Time Token earned; 1 hour learning = 1 Time Token spent. Solves the "double coincidence of wants" with a mathematical ledger derived from exchange history and a 3-token genesis grant.
- **Multi-Step Onboarding:** 7-step interactive wizard capturing teaching skills, learning goals, proficiency levels, and availability with an NLP bio-parser.
- **Realtime 1-on-1 Chat:** Supabase Realtime WebSocket messaging with REST pre-fetching, auto-reconnect polling fallback, optimistic delivery indicators, and Jitsi Meet room links.
- **Session Scheduling & AI Curriculum:** Calendar date/time booking with Gemini-generated 3-to-5 step milestone curricula customized for each pair.
- **Profile Customization:** Full profile editing including photo gallery upload via Supabase Storage, bio, location, experience levels, and searchable skill tag selection.
- **Production-Grade Security:** PostgreSQL Row-Level Security (RLS) across all 11 tables, JWT verification, anti-impersonation guards, and SlowAPI rate limiting.

---

## 🏗️ System Architecture

```
[ Flutter Mobile Client ] ───(HTTP / JWT)───► [ FastAPI AI Engine (Python 3.13) ]
        │                                                    │
   (Direct RLS)                                       (Admin SDK / Verify)
        ▼                                                    ▼
[ Supabase Cloud (PostgreSQL 15 + pgvector + Realtime + Storage) ]
        ▲
        └───── [ Google Gemini API Multi-Agent System ]
```

---

## 🛠️ Tech Stack

- **Frontend:** Flutter 3.x, Dart 3.x, Riverpod 3.x, GoRouter, Lucide Icons, Shadcn-inspired UI aesthetics.
- **Backend:** FastAPI, Python 3.13, Uvicorn, SlowAPI, Pydantic, HTTPBearer JWT auth.
- **AI & ML:** Google Gemini Generative AI, SentenceTransformers (`all-MiniLM-L6-v2`, 384-dim), NumPy.
- **Database:** Supabase Cloud (PostgreSQL 15+), `pgvector` extension, Row-Level Security (RLS).
- **Realtime & Storage:** Supabase Realtime (WebSocket WAL replication), Supabase Storage (`avatars` bucket).
- **Video Calling:** Dynamic Jitsi Meet integration (`https://meet.jit.si/SkillSwap-...`).

---

## 📂 Project Structure

```
stitch_skillswap_ai/
├── backend/
│   ├── agents/                   # Multi-agent AI engine (Onboarding, Matchmaking, Planner)
│   ├── ai_service.py             # Gemini API orchestrations
│   ├── main.py                   # FastAPI application & endpoints
│   ├── seed_db.py                # Database seeder script
│   ├── supabase_migration.sql    # DDL schema, pgvector, and RLS policies
│   └── test_agents.py            # Pytest test suite for AI agents
├── skillswap_ai/
│   ├── lib/
│   │   ├── constants/            # Popular & trending skill taxonomies
│   │   ├── providers/            # Riverpod state notifiers & profile providers
│   │   ├── screens/              # All app screens (Home, Chat, Profile, Edit, etc.)
│   │   ├── services/             # Auth, Chat, Session, Token, Storage, Stats services
│   │   ├── theme/                # Color palettes, typography, theme modes
│   │   └── widgets/              # Reusable UI widgets & Shadcn-inspired cards
│   └── pubspec.yaml              # Flutter dependencies
├── docs/                         # Detailed project audit & implementation reports
└── README.md
```

---

## 🚀 Getting Started

### Backend Setup
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Mobile App Setup
```bash
cd skillswap_ai
flutter pub get
flutter run
```

### Building Android APK
```bash
flutter build apk --debug
```

---

## 📄 License
This project is open-source under the MIT License.
