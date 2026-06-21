from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
from PIL import Image
import io
import base64
import tensorflow as tf

app = Flask(__name__)
CORS(app, origins="*")

model_path = r"C:\Users\DELL\oral_cancer_app\assets\oral_cancer_model.tflite"
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Model loaded OK!")
print("Input shape:", input_details[0]['shape'])
print("Output shape:", output_details[0]['shape'])

def process_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    shape = input_details[0]['shape']
    h, w = shape[1], shape[2]
    img = img.resize((w, h))
    img = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(img, axis=0)

@app.route('/')
def home():
    return jsonify({'status': 'API Running!'})

@app.route('/predict', methods=['POST', 'OPTIONS'])
def predict():
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'})
    data = request.get_json()
    image_bytes = base64.b64decode(data['image'])
    img_array = process_image(image_bytes)
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    
    if output.shape[-1] == 1:
        cancer_prob = float(output[0][0])
        if cancer_prob > 0.5:
            prediction = 'Suspicious (Cancer)'
            confidence = cancer_prob
        else:
            prediction = 'Normal'
            confidence = 1 - cancer_prob
    else:
        cancer_prob = float(output[0][0])
        normal_prob = float(output[0][1])
        if cancer_prob > normal_prob:
            prediction = 'Suspicious (Cancer)'
            confidence = cancer_prob
        else:
            prediction = 'Normal'
            confidence = normal_prob

    return jsonify({'prediction': prediction, 'confidence': confidence})

if __name__ == '__main__':
    print("API Starting on port 5000...")
    app.run(debug=True, port=5000, host='0.0.0.0')