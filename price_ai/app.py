# -*- coding: utf-8 -*-
from flask import Flask, render_template, request, jsonify # 🔥 Added request & jsonify
from flask_cors import CORS, cross_origin
import numpy as np
import pandas as pd
from datetime import datetime
import crops
import random

app = Flask(__name__)
app.config['CORS_HEADERS'] = 'Content-Type'
# 🔥 CORS(app) allows your phone/browser to talk to this laptop
CORS(app) 

commodity_dict = {
    "arhar": "static/Arhar.csv",
    "bajra": "static/Bajra.csv",
    "barley": "static/Barley.csv",
    "copra": "static/Copra.csv",
    "cotton": "static/Cotton.csv",
    "sesamum": "static/Sesamum.csv",
    "gram": "static/Gram.csv",
    "groundnut": "static/Groundnut.csv",
    "jowar": "static/Jowar.csv",
    "maize": "static/Maize.csv",
    "masoor": "static/Masoor.csv",
    "moong": "static/Moong.csv",
    "niger": "static/Niger.csv",
    "paddy": "static/Paddy.csv",
    "ragi": "static/Ragi.csv",
    "rape": "static/Rape.csv",
    "jute": "static/Jute.csv",
    "safflower": "static/Safflower.csv",
    "soyabean": "static/Soyabean.csv",
    "sugarcane": "static/Sugarcane.csv",
    "sunflower": "static/Sunflower.csv",
    "urad": "static/Urad.csv",
    "wheat": "static/Wheat.csv"
}

annual_rainfall = [29, 21, 37.5, 30.7, 52.6, 150, 299, 251.7, 179.2, 70.5, 39.8, 10.9]

base = {
    "Paddy": 1245.5, "Arhar": 3200, "Bajra": 1175, "Barley": 980,
    "Copra": 5100, "Cotton": 3600, "Sesamum": 4200, "Gram": 2800,
    "Groundnut": 3700, "Jowar": 1520, "Maize": 1175, "Masoor": 2800,
    "Moong": 3500, "Niger": 3500, "Ragi": 1500, "Rape": 2500,
    "Jute": 1675, "Safflower": 2500, "Soyabean": 2200, "Sugarcane": 2250,
    "Sunflower": 3700, "Urad": 4300, "Wheat": 1350
}

commodity_list = []

# --- YOUR ORIGINAL ML LOGIC ---
class Commodity:
    def __init__(self, csv_name):
        self.name = csv_name
        dataset = pd.read_csv(csv_name)
        self.X = dataset.iloc[:, :-1].values
        self.Y = dataset.iloc[:, 3].values
        from sklearn.tree import DecisionTreeRegressor
        depth = random.randrange(7,18)
        self.regressor = DecisionTreeRegressor(max_depth=depth)
        self.regressor.fit(self.X, self.Y)

    def getPredictedValue(self, value):
        if value[1]>=2019:
            fsa = np.array(value).reshape(1, 3)
            return self.regressor.predict(fsa)[0]
        else:
            # Fallback logic for older years
            c=self.X[:,0:2]
            x=[]
            for i in c: x.append(i.tolist())
            fsa = [value[0], value[1]]
            ind = 0
            for i in range(0,len(x)):
                if x[i]==fsa:
                    ind=i
                    break
            return self.Y[ind]

    def getCropName(self):
        # Splits 'static/Wheat.csv' to get 'Wheat'
        return self.name.split('/')[1].split('.')[0]

@app.route('/predict', methods=['POST'], strict_slashes=False)
@cross_origin()
def predict_logic():
    try:
        data = request.get_json()
        # Clean the input to match your 'base' dictionary keys
        crop_input = data.get('crop', '').strip().capitalize()
        user_rainfall = float(data.get('rainfall', 0))
        
        # ML Logic
        curr_month = float(datetime.now().month)
        curr_year = float(datetime.now().year)

        selected_commodity = None
        for i in commodity_list:
            # Match the trained model name
            if crop_input == i.getCropName().capitalize():
                selected_commodity = i
                break
        
        if selected_commodity:
            wpi = selected_commodity.getPredictedValue([curr_month, curr_year, user_rainfall])
            # Price = (Base * WPI) / 100
            final_price = (base[crop_input] * wpi) / 100
            return jsonify({"predicted_price": round(final_price, 2)})
        else:
            return jsonify({"error": f"Crop '{crop_input}' not found"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔥 ADD THIS FOR YOUR HOME SCREEN LEADERBOARD
@app.route('/get_top_rated', methods=['GET'])
@cross_origin()
def get_top_rated():
    try:
        curr_month = float(datetime.now().month)
        curr_year = 2013 # Use a year present in your CSV fallback if needed
        avg_rainfall = 45.0
        leaderboard = []

        for i in commodity_list:
            name = i.getCropName().capitalize()
            wpi = i.getPredictedValue([curr_month, curr_year, avg_rainfall])
            price = (base[name] * wpi) / 100
            leaderboard.append({"name": name, "price": round(price, 2)})

        leaderboard.sort(key=lambda x: x['price'], reverse=True)
        return jsonify(leaderboard[:5])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- KEEP YOUR ORIGINAL ROUTES FOR THE WEB VIEW ---
@app.route('/')
def index():
    # (Keep your existing index logic)
    return "Server is running!"

# --- STARTUP LOGIC ---
if __name__ == "__main__":
    print("Training Models... Please wait.")
    for key in commodity_dict:
        commodity_list.append(Commodity(commodity_dict[key]))
    
    print("All models trained! Server starting on Port 8084...")
    # 🔥 host='0.0.0.0' is mandatory for phone connection
    app.run(host='0.0.0.0', port=8084, debug=True)