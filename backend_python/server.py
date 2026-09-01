"""
CocoScan FastAPI/TensorFlow inference service (report Section 4.3, Table 4.2).

Run with:
    uvicorn server:app --host 0.0.0.0 --port 8000 --reload

Drop a trained checkpoint into backend_python/models/ named either
"best_model_1.keras" or "best_model.keras" (the server prefers the former)
before starting the server — /api/classify, /api/gradcam and /api/lime all
respond 503 until a model is loaded.
"""
import io
import json
import os
import random
import uuid
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, File, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image

from disease_info import DISEASE_INFO
from model_utils import (
    CLASS_NAMES,
    LoadedModel,
    confidence_tier,
    heatmap_to_overlay,
    image_to_base64_png,
)

app = FastAPI(title="CocoScan Inference Service", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

loaded_model = LoadedModel()

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
DB_FILE = os.path.join(DATA_DIR, "db.json")
os.makedirs(DATA_DIR, exist_ok=True)


def load_db():
    if not os.path.exists(DB_FILE):
        with open(DB_FILE, "w") as f:
            json.dump({"users": [], "scans": []}, f)
    with open(DB_FILE) as f:
        return json.load(f)


def save_db(db):
    with open(DB_FILE, "w") as f:
        json.dump(db, f, indent=2)


@app.on_event("startup")
def startup():
    ok = loaded_model.load()
    if ok:
        print(f"Loaded {loaded_model.path} — architecture={loaded_model.architecture}, "
              f"last_conv_layer={loaded_model.last_conv_layer}")
    else:
        print("WARNING: no model found in backend_python/models/. "
              "Place best_model_1.keras or best_model.keras there and restart.")


def require_model():
    if not loaded_model.is_ready:
        raise HTTPException(status_code=503, detail="Model not loaded. See backend_python/models/README.")


def require_auth(x_auth_token: Optional[str] = Header(default=None)):
    if not x_auth_token:
        raise HTTPException(status_code=401, detail="Missing authentication token")
    db = load_db()
    user = next((u for u in db["users"] if u["token"] == x_auth_token), None)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    return user


async def read_image(file: UploadFile) -> Image.Image:
    content = await file.read()
    try:
        return Image.open(io.BytesIO(content))
    except Exception:
        raise HTTPException(status_code=400, detail="Uploaded file is not a valid image")


@app.get("/")
def root():
    return {
        "message": "CocoScan FastAPI inference service is running.",
        "model_loaded": loaded_model.is_ready,
        "architecture": loaded_model.architecture,
    }


@app.post("/api/classify")
async def classify(image: UploadFile = File(...)):
    require_model()
    pil_image = await read_image(image)
    probs = loaded_model.predict(pil_image)
    top_index = int(probs.argmax())
    top_class = CLASS_NAMES[top_index]
    confidence = float(probs[top_index])
    tier = confidence_tier(confidence)
    info = DISEASE_INFO.get(top_class, {})
    return {
        "prediction": top_class,
        "confidence": confidence,
        "tier": tier,
        "causal_agent": info.get("causal_agent"),
        "warning": info.get("warning"),
        "probabilities": {CLASS_NAMES[i]: float(probs[i]) for i in range(len(CLASS_NAMES))},
    }


@app.post("/api/gradcam")
async def gradcam(image: UploadFile = File(...)):
    require_model()
    pil_image = await read_image(image)
    heatmap, class_index = loaded_model.gradcam_heatmap(pil_image)
    overlay = heatmap_to_overlay(heatmap, pil_image, alpha=0.5)
    return {
        "prediction": CLASS_NAMES[class_index],
        "image_base64": image_to_base64_png(overlay),
        "encoding": "png_base64",
    }


@app.post("/api/lime")
async def lime_explain(image: UploadFile = File(...)):
    require_model()
    pil_image = await read_image(image)

    import numpy as np
    from lime import lime_image
    from skimage.segmentation import mark_boundaries

    resized = pil_image.convert("RGB").resize((224, 224))
    rgb_array = np.array(resized)

    def predict_fn(images: "np.ndarray"):
        batch = np.stack([loaded_model.preprocess(Image.fromarray(im))[0] for im in images])
        return loaded_model.model.predict(batch, verbose=0)

    explainer = lime_image.LimeImageExplainer()
    explanation = explainer.explain_instance(
        rgb_array, predict_fn, top_labels=1, hide_color=0, num_samples=200
    )
    top_label = explanation.top_labels[0]
    temp, mask = explanation.get_image_and_mask(
        top_label, positive_only=True, num_features=8, hide_rest=False
    )
    boundary_img = (mark_boundaries(temp / 255.0, mask) * 255).astype("uint8")
    result_image = Image.fromarray(boundary_img)

    return {
        "prediction": CLASS_NAMES[top_label],
        "image_base64": image_to_base64_png(result_image),
        "encoding": "png_base64",
    }


@app.post("/api/drone/analyse")
async def drone_analyse(image: UploadFile = File(...), lat: float = 0.0, lng: float = 0.0):
    """Per-tree canopy analysis with map coordinates. This is a placeholder
    detector (report Table 4.2) — it does not run real tree detection, it
    returns plausible synthetic per-tree results so the drone workflow can
    be exercised end to end without a trained detector."""
    await image.read()
    tree_count = random.randint(3, 9)
    trees = []
    for i in range(tree_count):
        disease = random.choice(CLASS_NAMES)
        trees.append({
            "tree_id": f"tree-{i + 1}",
            "lat": lat + random.uniform(-0.0005, 0.0005),
            "lng": lng + random.uniform(-0.0005, 0.0005),
            "prediction": disease,
            "confidence": round(random.uniform(0.6, 0.99), 3),
        })
    return {"tree_count": tree_count, "trees": trees}


@app.post("/api/drone/report/pdf")
async def drone_report_pdf():
    raise HTTPException(status_code=501, detail="PDF report export is not implemented.")


@app.post("/auth/register")
async def register(payload: dict):
    name = payload.get("name")
    email = payload.get("email")
    password = payload.get("password")
    role = payload.get("role")
    if not all([name, email, password, role]):
        raise HTTPException(status_code=400, detail="Name, email, password, and role are required.")
    db = load_db()
    if any(u["email"] == email for u in db["users"]):
        raise HTTPException(status_code=409, detail="Email already exists.")
    token = f"token-{uuid.uuid4()}"
    user = {
        "id": f"user-{uuid.uuid4()}",
        "name": name,
        "email": email,
        "password": password,
        "role": role,
        "plantation": payload.get("plantation", ""),
        "phone": payload.get("phone", ""),
        "token": token,
        "stats": {"totalScans": 0, "diseasesFound": 0, "healthyTrees": 0, "reportScore": 0},
    }
    db["users"].append(user)
    save_db(db)
    public_user = {k: v for k, v in user.items() if k != "password"}
    return JSONResponse(status_code=201, content={"token": token, "user": public_user})


@app.post("/auth/login")
async def login(payload: dict):
    email = payload.get("email")
    password = payload.get("password")
    role = payload.get("role")
    if not all([email, password, role]):
        raise HTTPException(status_code=400, detail="Email, password, and role are required.")
    db = load_db()
    user = next((u for u in db["users"] if u["email"] == email and u["password"] == password and u["role"] == role), None)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials.")
    public_user = {k: v for k, v in user.items() if k != "password"}
    return {"token": user["token"], "user": public_user}


@app.get("/users/me")
async def users_me(x_auth_token: Optional[str] = Header(default=None)):
    user = require_auth(x_auth_token)
    return {k: v for k, v in user.items() if k not in ("password", "token")}


@app.get("/scans")
async def scans(x_auth_token: Optional[str] = Header(default=None)):
    user = require_auth(x_auth_token)
    db = load_db()
    user_scans = [s for s in db["scans"] if s["userId"] == user["id"]]
    return {"scans": user_scans}


@app.post("/scans")
async def create_scan(payload: dict, x_auth_token: Optional[str] = Header(default=None)):
    user = require_auth(x_auth_token)
    db = load_db()
    scan = {
        "id": f"scan-{uuid.uuid4()}",
        "userId": user["id"],
        "disease": payload.get("disease"),
        "confidence": payload.get("confidence"),
        "tier": payload.get("tier"),
        "date": datetime.utcnow().isoformat(),
    }
    db["scans"].insert(0, scan)
    for u in db["users"]:
        if u["id"] == user["id"]:
            u["stats"]["totalScans"] += 1
            if payload.get("disease") == "Healthy_Leaves":
                u["stats"]["healthyTrees"] += 1
            else:
                u["stats"]["diseasesFound"] += 1
    save_db(db)
    return scan
