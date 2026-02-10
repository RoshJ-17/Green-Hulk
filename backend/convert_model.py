"""
TFLite to TFJS Converter Script
Converts a .tflite model to TensorFlow.js format (.json + .bin files)
"""
import tensorflow as tf
import numpy as np
import json
import os

def convert_tflite_to_saved_model(tflite_path, saved_model_dir):
    """Convert TFLite model to SavedModel format first"""
    # Load the TFLite model
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"Input shape: {input_details[0]['shape']}")
    print(f"Output shape: {output_details[0]['shape']}")
    
    # Create a concrete function
    @tf.function(input_signature=[tf.TensorSpec(shape=input_details[0]['shape'], dtype=tf.float32)])
    def model_fn(input_tensor):
        interpreter.set_tensor(input_details[0]['index'], input_tensor.numpy())
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        return tf.convert_to_tensor(output, dtype=tf.float32)
    
    # Save as SavedModel
    tf.saved_model.save(
        model_fn,
        saved_model_dir,
        signatures=model_fn.get_concrete_function()
    )
    print(f"SavedModel created at: {saved_model_dir}")

if __name__ == "__main__":
    tflite_model_path = "./models/model.tflite"
    saved_model_path = "./models/saved_model"
    
    if not os.path.exists(tflite_model_path):
        print(f"Error: {tflite_model_path} not found!")
        exit(1)
    
    try:
        convert_tflite_to_saved_model(tflite_model_path, saved_model_path)
        print("\n✅ Conversion successful!")
        print(f"Next step: Run tensorflowjs_converter on the SavedModel:")
        print(f"  tensorflowjs_converter --input_format=tf_saved_model --output_format=tfjs_graph_model {saved_model_path} ./models/tfjs_model")
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        import traceback
        traceback.print_exc()
