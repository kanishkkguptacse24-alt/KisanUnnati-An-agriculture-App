import pickle
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load the brain and the translators
try:
    with open('fertilizer_brain.pkl', 'rb') as f:
        saved_data = pickle.load(f)
        model = saved_data['model']
        soil_encoder = saved_data['soil_encoder']
        crop_encoder = saved_data['crop_encoder']
    print("✅ Fertilizer AI Loaded Successfully!")
except Exception as e:
    print(f"❌ Error loading model: {e}")

@app.route('/predict_fertilizer', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        
        # Translate the text from Flutter into numbers using our saved encoders
        soil_id = soil_encoder.transform([data['soil_type']])[0]
        crop_id = crop_encoder.transform([data['crop_type']])[0]
        
        # Put it all into a DataFrame to prevent Scikit-Learn warnings
        feature_names = ['Temparature', 'Humidity', 'Moisture', 'Soil Type', 'Crop Type', 'Nitrogen', 'Potassium', 'Phosphorous']
        features = pd.DataFrame([[
            float(data['temperature']), float(data['humidity']), float(data['moisture']), 
            soil_id, crop_id, 
            float(data['nitrogen']), float(data['potassium']), float(data['phosphorous'])
        ]], columns=feature_names)
        
        # Predict
        prediction = model.predict(features)[0]
        
        print(f"🎯 Recommended Fertilizer: {prediction}")
        return jsonify({'fertilizer': str(prediction)})
    
    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    # Running on 8082!
    app.run(host='0.0.0.0', port=8082, debug=True)