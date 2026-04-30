# 🥥 CocoScan — Flutter Mobile App

Coconut Disease Detection System using Deep Learning & Explainable AI  
**University of Ruhuna — Department of Electrical and Information Engineering**

---

## 📱 Screens Included

| Screen | File | Description |
|--------|------|-------------|
| Splash | `splash_screen.dart` | Animated app launch screen |
| Login | `login_screen.dart` | Role-based login (Farmer / Officer) |
| Home | `home_screen.dart` | Dashboard with stats, quick actions, recent scans |
| Camera | `camera_screen.dart` | Live camera capture with scan overlay |
| Result | `result_screen.dart` | Disease prediction with confidence breakdown |
| Grad-CAM | `result_screen.dart` | XAI heatmap visualization (GradCamScreen) |
| Treatment | `result_screen.dart` | Step-by-step treatment recommendations |
| Drone Report | `drone_report_screen.dart` | Upload drone images, plantation map, tree report |
| History | `drone_report_screen.dart` | Past scan history with filters |

---

## 🎨 Design System

- **Primary**: `#1565C0` (Deep Blue)
- **Secondary**: `#2E7D32` (Deep Green)
- **Accent**: `#00ACC1` (Teal)
- **Font**: Poppins (download from Google Fonts)
- **Confidence System**: ✅ >85% Confirmed | ⚠️ 60–85% Uncertain | ❌ <60% Inconclusive

---

## 🚀 Getting Started

### 1. Install Flutter
```bash
flutter --version   # Must be >= 3.10.0
```

### 2. Download Poppins Font
Go to https://fonts.google.com/specimen/Poppins  
Download all weights and place in `assets/fonts/`

### 3. Create asset folders
```bash
mkdir -p assets/fonts assets/images assets/models
```

### 4. Install dependencies
```bash
flutter pub get
```

### 5. Run the app
```bash
flutter run
```

---

## 🔌 Backend Integration

Replace the mock data in `result_screen.dart` with real API calls:

```dart
// In ResultScreen — replace mock with:
final response = await http.post(
  Uri.parse('http://YOUR_BACKEND_URL/predict'),
  body: {'image': base64Image},
);
final data = json.decode(response.body);
// data['disease'], data['confidence'], data['gradcam_path']
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `camera` | Live camera capture |
| `image_picker` | Gallery/drone image upload |
| `tflite_flutter` | On-device disease classification |
| `google_maps_flutter` | Plantation map view |
| `fl_chart` | Confidence bar charts |
| `flutter_animate` | Smooth animations |
| `http` / `dio` | Backend API calls |

---

## 👥 Team
- P.S. Dlshan (RU/EG/2020/3898)
- B.T.I. Sewwandi (RU/EG/2020/4210)
- P.K.T.S. Jayasundara (RU/EG/2021/4582)

**Supervisor:** Ms. Yugani Gamlath
