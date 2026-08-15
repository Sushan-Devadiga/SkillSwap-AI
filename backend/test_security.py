import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

# Set env vars before importing main
import os
os.environ["SUPABASE_URL"] = "http://fake.supabase.co"
os.environ["SUPABASE_ANON_KEY"] = "fake-key"
os.environ["GEMINI_API_KEY"] = "fake-key"

from main import app

client = TestClient(app)

def test_missing_jwt():
    response = client.post("/api/match", json={"user_id": "user123"})
    assert response.status_code == 403 # FastAPI HTTPBearer without token returns 403 Forbidden

@patch("main.supabase.auth.get_user")
def test_invalid_jwt(mock_get_user):
    mock_get_user.side_effect = Exception("Invalid token")
    
    response = client.post(
        "/api/match", 
        json={"user_id": "user123"},
        headers={"Authorization": "Bearer fake_invalid_token"}
    )
    assert response.status_code == 401

@patch("main.supabase.auth.get_user")
def test_impersonation_attempt(mock_get_user):
    # Mock token belongs to user A
    mock_user_resp = MagicMock()
    mock_user_resp.user.id = "user_A_id"
    mock_get_user.return_value = mock_user_resp
    
    # But payload requests user B
    response = client.post(
        "/api/match", 
        json={"user_id": "user_B_id"},
        headers={"Authorization": "Bearer valid_token_for_A"}
    )
    # Should reject impersonation
    assert response.status_code == 403
    assert "Not authorized" in response.json()["detail"]

@patch("main.supabase.auth.get_user")
@patch("main.supabase.table")
def test_valid_request(mock_table, mock_get_user):
    # Setup auth mock
    mock_user_resp = MagicMock()
    mock_user_resp.user.id = "user_A_id"
    mock_get_user.return_value = mock_user_resp
    
    # Setup db mocks to return empty so it exits early successfully
    mock_execute = MagicMock()
    mock_execute.execute.return_value = MagicMock(data=[])
    mock_table.return_value.select.return_value.eq.return_value = mock_execute
    
    response = client.post(
        "/api/match", 
        json={"user_id": "user_A_id"},
        headers={"Authorization": "Bearer valid_token_for_A"}
    )
    
    # Should be 200 OK
    assert response.status_code == 200

def test_rate_limiting():
    # Attempt 30 requests to /api/embeddings which allows 20/min
    # We will mock the auth so it passes that layer
    with patch("main.supabase.auth.get_user") as mock_get_user:
        mock_user_resp = MagicMock()
        mock_user_resp.user.id = "test_user"
        mock_get_user.return_value = mock_user_resp
        
        status_codes = set()
        
        for _ in range(25):
            response = client.post(
                "/api/embeddings", 
                json={"skills": ["Python"]},
                headers={"Authorization": "Bearer token"}
            )
            status_codes.add(response.status_code)
            
        assert 429 in status_codes
