#  Smart Recipe Detection: An AI/Deep Learning-Based Dish Recognition and Nutritional Analysis System

A cross-platform mobile application that uses a custom-trained deep learning model (CNN based on MobileNetV2, trained via transfer learning in TensorFlow) to identify a dish from a photo, and then returns its ingredients, nutritional information, and recipe.

---
## 📖 Overview

Smart Recipe Detection is a Flutter-based mobile app that integrates a custom-trained AI image classification model. Users take or upload a photo of a dish, and the app:

1. Analyzes the image using an on-device deep learning model.
2. Predicts the dish along with a confidence score.
3. Fetches the corresponding **ingredients**, **nutritional information**, and **recipe** from a cloud backend.
4. Lets users save results to their history and provide feedback on the prediction.

The goal is to make it easier for cooking enthusiasts and food lovers to identify dishes visually and instantly access relevant recipe and nutrition data, instead of manually searching for a matching recipe.

---

##  Problem Statement

There is currently a lack of accessible, visual identification systems that can recognize a dish from an image **and** simultaneously provide its ingredients and nutritional breakdown. Most existing recipe apps rely on manual search or text-based queries rather than image-based recognition, making the process slower and less intuitive for users.

---

##  Key Features

-  **Image-based dish detection** — capture a photo via camera or select one from the gallery.
-  **On-device inference** using a custom-trained deep learning model (TensorFlow Lite).
-  **Ingredient & nutrient lookup** for the recognized dish.
-  **Step-by-step recipe** for the identified dish.
-  **Related video link** for the recipe.
-  **History tracking** — previously analyzed dishes are saved per user.
-  **User feedback** on prediction accuracy.
-  **Authentication** (Sign up / Login) with per-user data isolation.

---

##  AI / Deep Learning Approach

This project's core focus is the **image classification model** used for dish recognition:

- **Architecture:** Convolutional Neural Network (CNN), built on top of **MobileNetV2** using **transfer learning**, chosen for its strong accuracy-to-size trade-off and suitability for on-device mobile inference.
- **Framework:** TensorFlow / TensorFlow Lite (model trained in Google Colab and converted to `.tflite` for on-device deployment).
- **Input:** RGB images resized to `224 × 224 × 3`, normalized to `[0, 1]`.
- **Output:** Softmax probability distribution over 10 dish classes.
- **Classes (10 dishes):**
  `Bhindi`, `Chicken Biryani`, `Chicken Karahi`, `Chicken Tikka Leg Piece`, `Gajar Halva`, `Gulab Jamun`, `Haleem`, `Saagh`, `Sabat Masar`, `Kheer`
- **Confidence thresholding:** predictions below a set confidence threshold are rejected and the user is asked to try again, to reduce false positives.
- **Dataset:** ~1,200 images used for training, 39 for validation, and 58 for testing, curated and stored via Google Drive.
- **Results:** ~96% training accuracy and ~75% testing accuracy on the MobileNetV2-based model.
- **Model delivery:** the trained model is hosted and served via **Firebase ML Model Downloader**, allowing it to be fetched and run locally on the device using `tflite_flutter`.

---

##  Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart), GetX (state & navigation) |
| AI Model Training | Python, TensorFlow, Google Colab |
| On-device Inference | TensorFlow Lite (`tflite_flutter`) |
| Backend / Database | Firebase (Firestore, Authentication, Storage, ML Model Downloader) |
| Dataset Storage | Google Drive |
| Image Handling | `image_picker`, `image` (Dart) |

---

##  System Architecture

```
 ┌────────────┐      ┌───────────────────┐      ┌────────────────────┐
 │   User     │─────▶│  Flutter Mobile   │─────▶│  TFLite Interpreter │
 │ (Camera /  │      │      App          │      │  (MobileNetV2 CNN)  │
 │  Gallery)  │      └───────────────────┘      └──────────┬─────────┘
 └────────────┘                                             │
                                                             ▼
                                                  Predicted Dish + Confidence
                                                             │
                                                             ▼
                                              ┌──────────────────────────┐
                                              │   Firebase Firestore     │
                                              │ (Ingredients, Nutrients, │
                                              │  Recipe, Video Link)     │
                                              └──────────────┬───────────┘
                                                              │
                                                              ▼
                                              ┌──────────────────────────┐
                                              │  Result Displayed +      │
                                              │  Saved to User History   │
                                              └──────────────────────────┘
```
---

##  How It Works

1. **Capture / Upload** _ the user selects an image via the camera or gallery.
2. **Preprocessing** _ the image is decoded and resized to `224×224`, and pixel values are normalized.
3. **Inference** _ the preprocessed tensor is passed into the TFLite interpreter, which outputs class probabilities.
4. **Prediction**_ the highest-probability class is selected; results below the confidence threshold are treated as "no confident match."
5. **Data Retrieval**  for a confident prediction, the app queries Firestore for that dish's ingredients, nutrients, recipe steps, and a related video link.
6. **History & Feedback**  the result and uploaded image are saved to the user's history in Firestore/Storage, and the user can optionally submit feedback on the prediction.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](>= 3.4.0)
- A configured Firebase project (Firestore, Authentication, Storage, ML Model Downloader enabled)
- Android Studio / Xcode for platform builds

### Installation
```bash
# 1. Clone the repository
git clone <your-repo-url>
cd dish_detection

# 2. Install dependencies
flutter pub get

# 3. Add your own Firebase configuration
#    - Replace android/app/google-services.json with your project's file
#    - Replace lib/firebase_options.dart (generated via `flutterfire configure`)

# 4. Run the app
flutter run
```

### Firebase Setup Notes
- Create a Firestore collection named `dishes`, with one document per dish class, each containing `ingredients`, `nutrients`, `recipe`, and `link` fields.
- Register the trained `.tflite` model as **`Model89`** in Firebase ML Model Downloader (or bundle it locally via `assets/model.tflite`).
- Enable **Email/Password Authentication** in Firebase Authentication.
- Enable **Firebase Storage** for saving uploaded dish images to user history.

---

## 📊 Model Performance

| Metric | Value |
|---|---|
| Training Accuracy | ~96% |
| Testing Accuracy | ~75% |
| Input Size | 224 × 224 × 3 |
| Classes | 10 |
| Training Images | ~1,200 |
| Validation Images | 39 |
| Testing Images | 58 |

---

## 🔭 Future Improvements

- Expand the dataset and number of dish classes for broader coverage.
- Improve generalization to reduce the gap between training and testing accuracy.
- Add multi-dish detection within a single image.
- Explore lightweight LLM-based recipe generation/personalization on top of the recognized dish and nutrient data.
- Add offline-first support for the recipe/nutrition database.

---

## 📚 References

- Yan, K. (2023). *Building a Custom AI-Powered Recipe Recommender with TensorFlow.* Medium.
- Roboflow (2020). *Training a TensorFlow MobileNet Object Detection Model with a Custom Dataset.*
- Towards AI (2023). *Train and Deploy Custom Object Detection Models Without a Single Line of Code.*
- Moreira, L. P., Lima, R. M. F., & de Sousa, V. P. (2021). *An Intelligent System for Recipe Recommendation Using Deep Learning.* IEEE Transactions on Emerging Topics in Computational Intelligence, 5(1), 82–92.
- Gupta, S., Agarwal, A., & Kumar, P. (2020). *Nutritional Analysis of Food Items Using Image Processing Techniques.* IEEE Access, 8, 168131–168141.
- Smith, A. B., & Doe, J. (2020). *Machine Learning-Based Food Recognition System for Dietary Monitoring.* IEEE Journal of Biomedical and Health Informatics, 24(7), 1902–1910.

---

## 👥 Team

Developed as a semester project for the BS Computer Science program.

- **Sikandar Abbas**
- **Ali Hamza**
- **Muhammad Ashir**
---
**My Contribution**

As Sikandar Abbas, I served as the lead contributor on the AI/Deep Learning component of Smart Recipe Detection. My core responsibility was designing and training the custom CNN-based image classification model using MobileNetV2 with transfer learning in TensorFlow (Google Colab) — covering dataset preparation, preprocessing, and model tuning across 10 dish classes to reach ~96% training and ~75% testing accuracy. I also handled converting the trained model to TensorFlow Lite and integrating it into the Flutter application, including building the on-device inference pipeline (image preprocessing, running predictions through the TFLite interpreter, and confidence-based result filtering) and connecting it with Firebase (Firestore, Storage, and ML Model Downloader) to fetch and display ingredients, nutritional information, and recipes for each recognized dish. My teammates, Ali Hamza and Muhammad Aashir, contributed to the Flutter front-end screens (authentication, home, history, and profile UI) and supported dataset collection, testing, and Firebase backend configuration, rounding out the end-to-end mobile application.

## 📄 License

This project was developed for academic purposes. Feel free to explore the code; please credit the original authors if reused.
