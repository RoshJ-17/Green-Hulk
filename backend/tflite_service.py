"""
TFLite Inference Microservice
A lightweight Flask service that runs TFLite inference
Called by the Node.js backend for model predictions
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
import numpy as np
import json
import os

app = Flask(__name__)
CORS(app)

# Load configuration
with open('tflite_service_config.json', 'r') as f:
    config = json.load(f)

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=config['modelPath'])
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("=" * 60)
print("TFLite Inference Service Started")
print("=" * 60)
print(f"Model: {config['modelPath']}")
print(f"Input shape: {input_details[0]['shape']}")
print(f"Output shape: {output_details[0]['shape']}")
print(f"Listening on port: {config['port']}")
print("=" * 60)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "model": "loaded"})

@app.route('/predict', methods=['POST'])
def predict():
    """
    Run inference on preprocessed image data
    Expects JSON: { "input": [<flattened float32 array of 224*224*3=150528 elements>] }
    Returns: { "probabilities": [<38 floats>] }
    """
    try:
        data = request.get_json()
        
        if 'input' not in data:
            return jsonify({"error": "Missing 'input' field"}), 400
        
        # Convert input to numpy array and reshape
        input_data = np.array(data['input'], dtype=np.float32)
        
        # Validate input shape
        expected_size = 1 * 224 * 224 * 3
        if input_data.size != expected_size:
            return jsonify({
                "error": f"Invalid input size. Expected {expected_size}, got {input_data.size}"
            }), 400
        
        # Reshape to model input shape
        input_tensor = input_data.reshape(config['inputShape'])
        
        # Run inference
        interpreter.set_tensor(input_details[0]['index'], input_tensor)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        # Convert to list for JSON serialization
        probabilities = output_data[0].tolist()
        
        return jsonify({
            "probabilities": probabilities,
            "status": "success"
        })
        
    except Exception as e:
        import traceback
        return jsonify({
            "error": str(e),
            "traceback": traceback.format_exc()
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=config['port'], debug=True)
