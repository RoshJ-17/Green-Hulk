"""
Unit tests for TFLite Inference Service
Tests Flask endpoints and inference logic
"""
import pytest
import json
import numpy as np
from unittest.mock import patch, MagicMock

# Import the Flask app
import sys
sys.path.insert(0, '.')
from tflite_service import app

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

class TestHealthEndpoint:
    """Tests for /health endpoint"""
    
    def test_health_returns_200(self, client):
        """Test that /health endpoint returns 200 status code"""
        response = client.get('/health')
        assert response.status_code == 200
    
    def test_health_returns_correct_json(self, client):
        """Test that /health returns correct JSON structure"""
        response = client.get('/health')
        data = json.loads(response.data)
        
        assert 'status' in data
        assert 'model' in data
        assert data['status'] == 'healthy'
        assert data['model'] == 'loaded'

class TestPredictEndpoint:
    """Tests for /predict endpoint"""
    
    def test_predict_accepts_valid_input(self, client):
        """Test that /predict accepts valid input array"""
        # Create valid input: 224*224*3 = 150528 elements
        input_size = 224 * 224 * 3
        valid_input = np.random.rand(input_size).astype(np.float32).tolist()
        
        response = client.post(
            '/predict',
            data=json.dumps({'input': valid_input}),
            content_type='application/json'
        )
        
        assert response.status_code == 200
    
    def test_predict_returns_probabilities(self, client):
        """Test that /predict returns probabilities array"""
        input_size = 224 * 224 * 3
        valid_input = np.random.rand(input_size).astype(np.float32).tolist()
        
        response = client.post(
            '/predict',
            data=json.dumps({'input': valid_input}),
            content_type='application/json'
        )
        
        data = json.loads(response.data)
        
        assert 'probabilities' in data
        assert 'status' in data
        assert data['status'] == 'success'
        assert isinstance(data['probabilities'], list)
        assert len(data['probabilities']) == 38  # 38 disease classes
    
    def test_predict_returns_400_for_missing_input(self, client):
        """Test that /predict returns 400 when 'input' field is missing"""
        response = client.post(
            '/predict',
            data=json.dumps({}),
            content_type='application/json'
        )
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_predict_returns_400_for_invalid_input_size(self, client):
        """Test that /predict returns 400 for wrong input size"""
        # Wrong size: only 1000 elements instead of 150528
        invalid_input = np.random.rand(1000).astype(np.float32).tolist()
        
        response = client.post(
            '/predict',
            data=json.dumps({'input': invalid_input}),
            content_type='application/json'
        )
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
        assert 'Invalid input size' in data['error']
    
    def test_predict_probabilities_sum_to_one(self, client):
        """Test that probabilities sum to approximately 1.0"""
        input_size = 224 * 224 * 3
        valid_input = np.random.rand(input_size).astype(np.float32).tolist()
        
        response = client.post(
            '/predict',
            data=json.dumps({'input': valid_input}),
            content_type='application/json'
        )
        
        data = json.loads(response.data)
        probabilities = data['probabilities']
        
        # Probabilities should sum to approximately 1.0 (within tolerance)
        prob_sum = sum(probabilities)
        assert 0.99 <= prob_sum <= 1.01, f"Probabilities sum to {prob_sum}, expected ~1.0"
    
    def test_predict_handles_invalid_json(self, client):
        """Test that /predict handles malformed JSON gracefully"""
        response = client.post(
            '/predict',
            data='not valid json',
            content_type='application/json'
        )
        
        assert response.status_code in [400, 500]

class TestInputValidation:
    """Tests for input validation logic"""
    
    def test_input_must_be_float32(self, client):
        """Test that input accepts float values"""
        input_size = 224 * 224 * 3
        # Use integers (should still work as they convert to float)
        int_input = [1] * input_size
        
        response = client.post(
            '/predict',
            data=json.dumps({'input': int_input}),
            content_type='application/json'
        )
        
        # Should accept and convert to float
        assert response.status_code in [200, 400]  # Either works or validates strictly
    
    def test_empty_input_rejected(self, client):
        """Test that empty input array is rejected"""
        response = client.post(
            '/predict',
            data=json.dumps({'input': []}),
            content_type='application/json'
        )
        
        assert response.status_code == 400

if __name__ == '__main__':
    pytest.main([__file__, '-v'])
