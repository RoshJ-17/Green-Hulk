# Model Conversion Guide

## Converting TFLite to TensorFlow.js

Your `model.tflite` file needs to be converted to TensorFlow.js format for use with Node.js.

### Prerequisites

```bash
pip install tensorflowjs tensorflow
```

### Method 1: From SavedModel (Recommended)

If you have the original SavedModel:

```bash
tensorflowjs_converter \
  --input_format=tf_saved_model \
  --output_format=tfjs_graph_model \
  --signature_name=serving_default \
  --saved_model_tags=serve \
  /path/to/saved_model \
  ./backend/assets/model
```

### Method 2: Convert TFLite to SavedModel First

If you only have the TFLite file:

```python
import tensorflow as tf

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

# Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Create a concrete function
@tf.function(input_signature=[tf.TensorSpec(shape=[1, 224, 224, 3], dtype=tf.float32)])
def model_fn(input_tensor):
    interpreter.set_tensor(input_details[0]['index'], input_tensor.numpy())
    interpreter.invoke()
    return interpreter.get_tensor(output_details[0]['index'])

# Save as SavedModel
tf.saved_model.save(
    model_fn,
    './saved_model',
    signatures={'serving_default': model_fn}
)
```

Then convert to TensorFlow.js:

```bash
tensorflowjs_converter \
  --input_format=tf_saved_model \
  --output_format=tfjs_graph_model \
  ./saved_model \
  ./backend/assets/model
```

### Verify Conversion

The output directory should contain:
- `model.json` - Model architecture
- `group1-shard1of1.bin` (or similar) - Model weights

### Update .env

```env
MODEL_PATH=./assets/model/model.json
```

### Test Loading

```bash
cd backend
npm install
npm run start:dev
```

Check logs for: "Model loaded successfully"
