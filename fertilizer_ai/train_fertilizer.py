import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
import pickle

# 1. Load the data
df = pd.read_csv('Fertilizer_recommendation.csv')

# 🛠️ THE FIX: Strip invisible spaces from all column names
df.columns = df.columns.str.strip()

# 2. Translate Words to Numbers (Encoding)
soil_encoder = LabelEncoder()
crop_encoder = LabelEncoder()

df['Soil Type'] = soil_encoder.fit_transform(df['Soil Type'])
df['Crop Type'] = crop_encoder.fit_transform(df['Crop Type'])

# 3. Separate Features (X) and Target (y)
# (Notice 'Temparature' is misspelled in the original CSV, we have to match it exactly!)
X = df[['Temparature', 'Humidity', 'Moisture', 'Soil Type', 'Crop Type', 'Nitrogen', 'Potassium', 'Phosphorous']]
y = df['Fertilizer Name']

# 4. Train the AI
print("🚀 Training Fertilizer AI...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# 5. Save the Model AND the Translators together!
with open('fertilizer_brain.pkl', 'wb') as f:
    pickle.dump({'model': model, 'soil_encoder': soil_encoder, 'crop_encoder': crop_encoder}, f)

print("✅ SUCCESS! Model and encoders saved as 'fertilizer_brain.pkl'")