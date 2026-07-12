<div align="center">
  <img src="https://github.com/user-attachments/assets/b8150434-326a-4f2b-b7ad-16d798d3825e" alt="KisaanUnnati Banner" width="100%" />
</div>

# 🌾 KisaanUnnati (किसान उन्नति)

> **Empowering Indian Farmers with an Intelligent, App-Based Sustainable Agriculture Ecosystem.**

🥉 **Winner:** 3rd Position at Think India Adhaya AI Hackathon  
👨‍💻 **Team:** The Novas

## 📖 About The Project

Agriculture is the backbone of the Indian economy, yet farmers face fragmented ecosystems, market inefficiencies, and vast knowledge gaps. **KisaanUnnati** is an end-to-end AgriTech platform designed to bridge the gap between rural farmers, active buyers, vendors, and government bodies. 

Built specifically to tackle the "Innovating App-Based Solutions for Sustainable Agriculture" problem statement, KisaanUnnati integrates smart farming, predictive analytics, and a digital marketplace into a single, user-friendly, and localized mobile ecosystem.

### 🎯 The Challenge We Solved
* **Fragmented Ecosystem:** Connecting weather, advisory, market, and government services into one hub.
* **Market Inefficiencies:** Eliminating exploitative middlemen through transparent price discovery.
* **Knowledge Gaps:** Replacing outdated methods with modern, AI-driven crop and fertilizer insights.

---

## ✨ Key Features

### 👥 A Unified, Multi-Profile Ecosystem
* **🧑‍🌾 Farmer Interface:** A localized dashboard for crop management, AI advisory, produce listing, and tracking earnings.
* **🛒 Buyer/Vendor Interface:** A dedicated E-commerce portal to browse available crops, track market trends, and sell agricultural inputs/equipment.
* **🏛️ Government & Services Interface:** A centralized hub to drive awareness for government schemes, subsidies, and quality grading standards.

### ⚖️ Dynamic E-Commerce & Bidding Engine
Farmers can list pre-harvest and post-harvest crops. Buyers place competitive bids in real-time, creating a transparent price-discovery mechanism that cuts out middlemen and maximizes farmer returns. Includes a **Rental Marketplace** for tractors and farming equipment.

### 🗣️ Localized & Inclusive
* **Sakha (KisanBot):** A voice-enabled Hindi chatbot bridging the digital literacy gap for rural communities.
* **Secure Onboarding:** Gmail authentication with optional Aadhar integration for verified, trusted profiles.

---

## 🧠 The AI-Powered Advisory Suite

We turned raw agricultural data into actionable insights by deeply integrating four specialized Machine Learning models:

1.  **🌱 Smart Crop AI (Random Forest):** Analyzes current soil nutrients (N, P, K), pH, temperature, and rainfall to suggest the most profitable and sustainable crops for the farmer's specific location.
2.  **📈 Price Teller (Predictive Insights):** Forecasts future market prices based on historical trends, seasonal patterns, and demand indicators to help farmers plan cultivation and sales.
3.  **🧪 Smart Fertilizer AI:** Calculates the optimal nutrient blend based on soil type, moisture level, and selected crop, saving costs and preventing soil degradation.
4.  **🔬 Plant Doctor (Computer Vision):** Allows farmers to upload a smartphone photo of a sick leaf. The ML algorithm processes the visual patterns to instantly diagnose plant diseases and suggest treatment plans.

---

## 🛠️ Tech Stack

* **Frontend Mobile Development:** Flutter (Dart)
* **Machine Learning / AI:** Python, Scikit-Learn, TensorFlow/Keras 
* **Backend / Database:** Firebase 
* **UI/UX Design:** Figma

---

## ⚠️ Important Repository Notes

To maintain security and adhere to GitHub file size limits, the following files are **not** included in this repository:

1. **Environment Variables (`.env`):** Our API keys and sensitive configuration files are omitted. To run this project locally, you will need to create your own `.env` file in the root directory.
   ```env
   # Example .env file
   YOUR_API_KEY_NAME=your_actual_api_key_here
   # Add other required API keys here
2.Model Weights (.keras / .h5 files): The pre-trained model file for the Plant Disease Detection API is too large to host here. You will need to train the model locally or place your own .keras file in the disease_api folder to test that specific module. Note: You can obtain the required model weights from the original source repository here.

## 🚀 Installation & Local Setup

Because our AI models run as separate microservices, you will need to start the Flutter frontend and the respective Python APIs in separate terminal windows.

### 1. Start the AI Microservices (Backend)
Ensure you have Python 3 installed. Open separate terminal instances for each API:

**Price Prediction API:**
```bash
cd price_ai
pip install -r requirements.txt
python app.py

Fertilizer Recommendation API:

cd fertilizer_ai
pip install -r requirements.txt
python fertilizer_api.py

Crop Recommendation API:

cd crop_ai
python crop_api.py

Plant Disease Detection API:
(Note: Ensure your .keras model file is placed in this directory before running)

cd disease_api
python disease_api.py

2. Start the Flutter App (Frontend)
Open a final terminal window for the mobile application:

Bash
# Clone the repository (if you haven't already)
git clone [https://github.com/yourusername/KisaanUnnati.git](https://github.com/yourusername/KisaanUnnati.git)

# Navigate into the root directory
cd KisaanUnnati

# Install Flutter dependencies
flutter pub get

# Run the app on your connected device or emulator
flutter run

🔮 Future Roadmap (Impact Vision)
While KisaanUnnati is already fully functional, our vision for a self-reliant agricultural ecosystem includes:

📡 IoT & Sensor Integration: Real-time farm monitoring connecting directly to hardware sensors for soil moisture, pH, and NPK levels.

💸 Financial Inclusion: In-app provisions for micro-loans, crop insurance, and direct government subsidy disbursements.

🚚 Supply Chain Optimization: Direct logistics integration and warehousing partnerships to minimize post-harvest losses.

🙏 Acknowledgments & Credits
Building an AI-driven ecosystem in a hackathon timeframe requires standing on the shoulders of the open-source community. We would like to express our deep gratitude to the original creators whose datasets and base ML models made our advisory suite possible:

Crop, Fertilizer, Price Models, & Plant Disease Detection: Base logic and datasets adapted from the open-source repository https://github.com/ravikant-diwakar/AgriSens/tree/master

Note: All base models were fine-tuned and integrated into our custom microservice architecture for the KisaanUnnati ecosystem.

👨‍💻 Meet "The Novas"
We are a passionate team dedicated to using technology to empower farmers and revolutionize the agricultural value chain.

Ayush Kumar Barnwal - Frontend Architecture & Development

Built the complete Flutter mobile application from scratch, crafted the complex UI, handled state management for the multi-profile system, and ensured a responsive, accessible experience.

Kanishk Kumar Gupta - AI/ML Engineering

Trained, optimized, and deployed all four highly accurate machine learning models that serve as the "brain" powering our smart farm advisory.

Shreyansh Kumar Gupta - UX/UI Product Design & Integration

Spearheaded the intuitive product design tailored for rural users and bridged the critical gap between the Flutter frontend code and the backend ML models.

If you like this project, please consider giving it a ⭐!
