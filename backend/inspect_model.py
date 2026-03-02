"""
Simple TFLite Model Information Extractor
Extracts model metadata to help with manual conversion or direct usage
"""
import tensorflow as tf
import json

def inspect_tflite_model(model_path):
    """Inspect TFLite model and print details"""
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("=" * 60)
    print("TFLite Model Information")
    print("=" * 60)
    
    print("\nINPUT DETAILS:")
    for i, inp in enumerate(input_details):
        print(f"  Input {i}:")
        print(f"    Name: {inp['name']}")
        print(f"    Shape: {inp['shape']}")
        print(f"    Type: {inp['dtype']}")
        print(f"    Index: {inp['index']}")
    
    print("\nOUTPUT DETAILS:")
    for i, out in enumerate(output_details):
        print(f"  Output {i}:")
        print(f"    Name: {out['name']}")
        print(f"    Shape: {out['shape']}")
        print(f"    Type: {out['dtype']}")
        print(f"    Index: {out['index']}")
    
    print("\n" + "=" * 60)
    print("RECOMMENDATION:")
    print("=" * 60)
    print("For Node.js backend, you have 3 options:")
    print("1. Use '@tensorflow/tfjs-node' with pre-converted GraphModel")
    print("2. Create a Python microservice to run TFLite inference")
    print("3. Run TFLite inference on Flutter frontend (original design)")
    print("\nThe .tflite format is optimized for mobile/edge devices.")
    print("Backend TF.js works best with GraphModel (.json + .bin) format.")
    
    return {
        "input_shape": input_details[0]['shape'].tolist(),
        "output_shape": output_details[0]['shape'].tolist(),
        "input_dtype": str(input_details[0]['dtype']),
        "output_dtype": str(output_details[0]['dtype'])
    }

if __name__ == "__main__":
    model_info = inspect_tflite_model("./models/model.tflite")
    
    # Save model info as JSON for reference
    with open("./models/model_info.json", "w") as f:
        json.dump(model_info, f, indent=2)
    
    print(f"\n✅ Model info saved to: ./models/model_info.json")
