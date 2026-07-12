import pickle
import pandas as pd # 1. ADD THIS IMPORT
from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np

app = Flask(__name__)
CORS(app)

# Load the brain
try:
    with open('RandomForest_v3.pkl', 'rb') as f:
        model = pickle.load(f) 
    print("✅ Crop AI Model Loaded Successfully!")
except Exception as e:
    print(f"❌ Error loading model: {e}")

@app.route('/predict_crop', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        
        # 2. CREATE A DATAFRAME WITH NAMES (This stops the warning)
        # The names MUST match the names in your CSV exactly
        feature_names = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        features = pd.DataFrame([[
            float(data['n']), float(data['p']), float(data['k']),
            float(data['temp']), float(data['humidity']),
            float(data['ph']), float(data['rainfall'])
        ]], columns=feature_names)
        
        # 3. Predict using the named DataFrame
        probabilities = model.predict_proba(features)[0]
        all_crops = model.classes_
        
        crop_probs = sorted(zip(all_crops, probabilities), key=lambda x: x[1], reverse=True)[:3]
        
        results = []
        for crop, prob in crop_probs:
            results.append({
                "crop": str(crop).capitalize(),
                "confidence": round(prob * 100, 2)
            })
            
        print(f"🎯 Top Prediction: {results[0]['crop']} ({results[0]['confidence']}%)")
        return jsonify(results) 
    
    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081, debug=True)