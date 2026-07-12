from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
import numpy as np
from PIL import Image
import io

app = Flask(__name__)
CORS(app)

# 1. Load the new Keras Brain
try:
    model = tf.keras.models.load_model('trained_plant_disease_model.keras')
    print("✅ Deep Learning Disease Model Loaded Successfully!")
except Exception as e:
    print(f"❌ Error loading model: {e}")

# 2. The exact list of 38 classes
CLASS_NAMES = [
    'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy',
    'Blueberry___healthy', 'Cherry_(including_sour)___Powdery_mildew', 
    'Cherry_(including_sour)___healthy', 'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 
    'Corn_(maize)___Common_rust_', 'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy', 
    'Grape___Black_rot', 'Grape___Esca_(Black_Measles)', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 
    'Grape___healthy', 'Orange___Haunglongbing_(Citrus_greening)', 'Peach___Bacterial_spot',
    'Peach___healthy', 'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 
    'Potato___Early_blight', 'Potato___Late_blight', 'Potato___healthy', 
    'Raspberry___healthy', 'Soybean___healthy', 'Squash___Powdery_mildew', 
    'Strawberry___Leaf_scorch', 'Strawberry___healthy', 'Tomato___Bacterial_spot', 
    'Tomato___Early_blight', 'Tomato___Late_blight', 'Tomato___Leaf_Mold', 
    'Tomato___Septoria_leaf_spot', 'Tomato___Spider_mites Two-spotted_spider_mite', 
    'Tomato___Target_Spot', 'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy'
]

# 3. The Details Dictionary
DISEASE_INFO = {
    'Apple___Apple_scab': 'A fungal disease caused by *Venturia inaequalis*, leading to dark, scabby lesions on leaves and fruit, affecting fruit quality and yield.',
    'Apple___Black_rot': 'Caused by the fungus *Botryosphaeria obtusa*, it results in black, rotten spots on apples and can also infect leaves and bark.',
    'Apple___Cedar_apple_rust': 'A fungal disease caused by *Gymnosporangium juniperi-virginianae*, leading to yellow-orange spots on apple leaves and fruit, requiring both apple and cedar hosts to complete its life cycle.',
    'Apple___healthy': 'No diseases detected; the apple plant appears healthy.',
    'Blueberry___healthy': 'No diseases detected; the blueberry plant appears healthy.',
    'Cherry_(including_sour)___Powdery_mildew': 'A fungal disease caused by *Podosphaera clandestina*, leading to white, powdery fungal growth on leaves, shoots, and fruit, affecting fruit development.',
    'Cherry_(including_sour)___healthy': 'No diseases detected; the cherry plant appears healthy.',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': 'Caused by the fungus *Cercospora zeae-maydis*, leading to rectangular gray lesions on maize leaves, reducing photosynthetic area and yield.',
    'Corn_(maize)___Common_rust_': 'A fungal disease caused by *Puccinia sorghi*, resulting in reddish-brown pustules on both leaf surfaces, potentially reducing yield if severe.',
    'Corn_(maize)___Northern_Leaf_Blight': 'Caused by the fungus *Setosphaeria turcica*, leading to cigar-shaped gray-green lesions on leaves, which can coalesce and cause significant yield loss.',
    'Corn_(maize)___healthy': 'No diseases detected; the corn plant appears healthy.',
    'Grape___Black_rot': 'A fungal disease caused by *Guignardia bidwellii*, leading to black spots on leaves and fruit, causing fruit to shrivel and turn into mummies.',
    'Grape___Esca_(Black_Measles)': 'A complex disease involving multiple fungi, leading to dark streaks on the wood and black spots on leaves and berries, potentially causing vine decline.',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': 'Caused by the fungus *Pseudocercospora vitis*, leading to irregular, necrotic spots on leaves, which can merge and cause significant leaf area loss.',
    'Grape___healthy': 'No diseases detected; the grapevine appears healthy.',
    'Orange___Haunglongbing_(Citrus_greening)': 'A bacterial disease caused by *Candidatus Liberibacter* species, leading to yellowing of shoots, asymmetrical fruit, and eventual tree death.',
    'Peach___Bacterial_spot': 'Caused by the bacterium *Xanthomonas campestris pv. pruni*, leading to small, water-soaked spots on leaves and fruit, which can coalesce and cause significant damage.',
    'Peach___healthy': 'No diseases detected; the peach tree appears healthy.',
    'Pepper,_bell___Bacterial_spot': 'Caused by the bacterium *Xanthomonas campestris pv. vesicatoria*, leading to dark, water-soaked spots on leaves and fruit, reducing yield and marketability.',
    'Pepper,_bell___healthy': 'No diseases detected; the bell pepper plant appears healthy.',
    'Potato___Early_blight': 'A fungal disease caused by *Alternaria solani*, leading to concentric ring lesions on leaves and tubers, reducing yield and tuber quality.',
    'Potato___Late_blight': 'Caused by the oomycete *Phytophthora infestans*, leading to water-soaked lesions on leaves and tubers, which can rapidly expand and cause total crop loss.',
    'Potato___healthy': 'No diseases detected; the potato plant appears healthy.',
    'Raspberry___healthy': 'No diseases detected; the raspberry plant appears healthy.',
    'Soybean___healthy': 'No diseases detected; the soybean plant appears healthy.',
    'Squash___Powdery_mildew': 'A fungal disease caused by *Podosphaera xanthii* or *Erysiphe cichoracearum*, leading to white, powdery fungal growth on leaves and stems, reducing photosynthesis and yield.',
    'Strawberry___Leaf_scorch': 'Caused by the fungus *Diplocarpon earlianum*, leading to irregular, dark purple spots on leaves, which can coalesce and cause leaf death.',
    'Strawberry___healthy': 'No diseases detected; the strawberry plant appears healthy.',
    'Tomato___Bacterial_spot': 'Caused by the bacterium *Xanthomonas campestris pv. vesicatoria*, leading to small, water-soaked spots on leaves and fruit, reducing yield and fruit quality.',
    'Tomato___Early_blight': 'A fungal disease caused by *Alternaria solani*, leading to concentric ring lesions on leaves, stems, and fruit, causing defoliation and yield loss.',
    'Tomato___Late_blight': 'Caused by the oomycete *Phytophthora infestans*, leading to large, water-soaked lesions on leaves and fruit, causing rapid plant decline and fruit rot.',
    'Tomato___Leaf_Mold': 'A fungal disease caused by *Passalora fulva*, leading to yellow spots on upper leaf surfaces and olive-green to gray mold on the undersides, causing defoliation.',
    'Tomato___Septoria_leaf_spot': 'Caused by the fungus *Septoria lycopersici*, leading to small, circular spots with gray centers and dark borders on leaves, causing premature defoliation.',
    'Tomato___Spider_mites Two-spotted_spider_mite': 'Infestation by *Tetranychus urticae*, leading to stippling and bronzing of leaves, which can cause defoliation and reduced yield.',
    'Tomato___Target_Spot': 'Caused by the fungus *Corynespora cassiicola*, leading to dark, concentric lesions on leaves, stems, and fruit, causing defoliation and fruit rot.',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus': 'A viral disease transmitted by whiteflies, leading to yellowing and curling of leaves, stunted growth, and reduced yield.',
    'Tomato___Tomato_mosaic_virus': 'A viral disease causing mottling, yellowing, and distortion of leaves, leading to reduced fruit size and yield.',
    'Tomato___healthy': 'No diseases detected; the tomato plant appears healthy.'
}

@app.route('/predict_disease', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    
    file = request.files['file']
    
    try:
        # Read the image the Flutter app sends
        img_bytes = file.read()
        img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
        
        # 🔥 CRITICAL FIX: Resize to 128x128 as required by this specific Keras model
        img = img.resize((128, 128)) 
        
        # Convert image to math arrays
        img_array = tf.keras.preprocessing.image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        
        # Predict!
        predictions = model.predict(img_array)
        predicted_index = np.argmax(predictions[0])
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = round(100 * float(np.max(predictions[0])), 2)
        
        # Get the description
        description = DISEASE_INFO.get(predicted_class, "No additional information available.")
        
        print(f"🎯 Detected: {predicted_class} ({confidence}%)")
        
        # Send everything back to Flutter!
        return jsonify({
            'disease': predicted_class.replace('___', ' - ').replace('_', ' '), # Clean up the name a bit
            'confidence': confidence,
            'description': description
        })
        
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Running on Port 8080 
    app.run(host='0.0.0.0', port=8080, debug=True)