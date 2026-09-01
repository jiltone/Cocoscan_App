# CocoScan FastAPI/TensorFlow inference service

The production inference backend described in report Section 4.3 — serves
the trained Keras model, generates Grad-CAM/LIME explanations, and exposes a
lightweight file-backed auth/scan-history API for local development.

## Setup

```
cd backend_python
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt
```

Drop your trained model into `models/` (see `models/README.md`), then run:

```
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

## Endpoints (report Table 4.2)

| Endpoint | Function |
|---|---|
| `POST /api/classify` | Seven-class disease prediction with confidence tier |
| `POST /api/gradcam` | Grad-CAM heatmap overlay (PNG, base64) |
| `POST /api/lime` | LIME superpixel explanation (PNG, base64) |
| `POST /api/drone/analyse` | Per-tree drone/canopy analysis (placeholder detector) |
| `POST /api/drone/report/pdf` | Not implemented — returns HTTP 501 |
| `POST /auth/login` / `POST /auth/register` | Lightweight file-backed auth |
| `GET /users/me` | Current user details |
| `GET /scans` / `POST /scans` | Scan history |

Until a model file is placed in `models/`, `/api/classify`, `/api/gradcam`
and `/api/lime` respond `503`.
