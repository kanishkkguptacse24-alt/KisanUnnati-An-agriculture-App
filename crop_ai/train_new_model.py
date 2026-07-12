import pandas as pd
from sklearn.ensemble import RandomForestClassifier
import pickle

# 1. Load the data
df = pd.read_csv('Crop_recommendation.csv')

# 2. Features and Target
X = df[['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']]
y = df['label']

# 3. Train
print("🚀 Training your custom AI... this will take 2 seconds.")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# 4. Save
with open('RandomForest_v3.pkl', 'wb') as f:
    pickle.dump(model, f)

print("✅ SUCCESS! Your modern 'RandomForest_v3.pkl' is ready.")