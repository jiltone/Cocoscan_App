"""
Model loading, architecture auto-detection and Grad-CAM/LIME helpers for the
CocoScan FastAPI inference service (see report Section 4.3 / 4.2.1).

Auto-detecting the base architecture (ResNet50 vs EfficientNetB4) lets the
same server code serve either candidate checkpoint without a code change,
because the two architectures need different preprocessing and a different
"last conv layer" name for Grad-CAM.
"""
import io
import json
import os

import numpy as np
import tensorflow as tf
from PIL import Image

MODEL_DIR = os.path.join(os.path.dirname(__file__), "models")
CANDIDATE_MODEL_NAMES = ["best_model_1.keras", "best_model.keras"]
IMAGE_SIZE = (224, 224)

def _load_class_names(path: str) -> list[str]:
    """Accepts either a plain JSON array of names, or the richer
    {"class_names": [...], "class_indices": {name: index, ...}} shape a
    training pipeline's train_generator.class_indices export commonly
    produces. When both keys are present, "class_names" is trusted as
    already being in index order."""
    with open(path) as f:
        raw = json.load(f)
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict):
        if isinstance(raw.get("class_names"), list):
            return raw["class_names"]
        if isinstance(raw.get("class_indices"), dict):
            indices = raw["class_indices"]
            ordered = [None] * len(indices)
            for name, idx in indices.items():
                ordered[idx] = name
            return ordered
    raise ValueError(f"Unrecognised class_names.json format: {path}")


CLASS_NAMES = _load_class_names(os.path.join(os.path.dirname(__file__), "class_names.json"))

CONFIRMED_THRESHOLD = 0.85
UNCERTAIN_THRESHOLD = 0.60


def find_model_path():
    for name in CANDIDATE_MODEL_NAMES:
        path = os.path.join(MODEL_DIR, name)
        if os.path.exists(path):
            return path
    return None


def detect_architecture(model: tf.keras.Model) -> str:
    """Inspect layer names to work out whether the base network is a
    ResNet50 or an EfficientNetB4 backbone."""
    names = " ".join(layer.name.lower() for layer in model.layers)
    if "efficientnet" in names:
        return "efficientnet"
    if "resnet" in names:
        return "resnet50"
    # Fall back on layer class names if the functional API flattened the
    # backbone into the top-level model instead of nesting it.
    for layer in model.layers:
        cls = layer.__class__.__name__.lower()
        if "efficientnet" in cls:
            return "efficientnet"
        if "resnet" in cls:
            return "resnet50"
    return "resnet50"


def find_last_conv_layer(model: tf.keras.Model) -> str:
    """Walk the model (including nested sub-models, since a Sequential head
    is usually stacked on top of a Functional backbone) and return the name
    of the last layer whose output is rank-4 (spatial feature map) — this is
    the layer Grad-CAM needs gradients through."""

    def search(m):
        for layer in reversed(m.layers):
            if isinstance(layer, tf.keras.Model):
                found = search(layer)
                if found:
                    return found
            try:
                shape = layer.output_shape
            except AttributeError:
                continue
            if isinstance(shape, tuple) and len(shape) == 4:
                return layer.name
        return None

    layer_name = search(model)
    if layer_name is None:
        raise ValueError("Could not locate a convolutional layer for Grad-CAM.")
    return layer_name


class LoadedModel:
    def __init__(self):
        self.model = None
        self.architecture = None
        self.last_conv_layer = None
        self.path = None

    def load(self):
        path = find_model_path()
        if path is None:
            self.model = None
            return False
        self.model = tf.keras.models.load_model(path)
        self.path = path
        self.architecture = detect_architecture(self.model)
        self.last_conv_layer = find_last_conv_layer(self.model)
        return True

    @property
    def is_ready(self):
        return self.model is not None

    def preprocess(self, pil_image: Image.Image) -> np.ndarray:
        img = pil_image.convert("RGB").resize(IMAGE_SIZE)
        arr = np.array(img).astype(np.float32)
        arr = np.expand_dims(arr, axis=0)
        if self.architecture == "efficientnet":
            return tf.keras.applications.efficientnet.preprocess_input(arr)
        return tf.keras.applications.resnet50.preprocess_input(arr)

    def predict(self, pil_image: Image.Image):
        tensor = self.preprocess(pil_image)
        probs = self.model.predict(tensor, verbose=0)[0]
        return probs

    def gradcam_heatmap(self, pil_image: Image.Image, class_index: int | None = None):
        """Grad-CAM via a manual eager forward pass rather than rebuilding a
        Model from a nested submodel's stored `.output` tensor. Keras 3 does
        not treat a nested backbone's `.output` as connected to the outer
        model's inputs when used to construct a new Functional Model (raises
        "Output with path ... is not connected to inputs"), so instead we
        replay self.model.layers one at a time in eager mode and
        tape.watch() the activation at last_conv_layer directly."""
        tensor = tf.constant(self.preprocess(pil_image))

        with tf.GradientTape() as tape:
            x = tensor
            conv_output = None
            for layer in self.model.layers:
                if isinstance(layer, tf.keras.layers.InputLayer):
                    continue
                x = layer(x, training=False)
                if layer.name == self.last_conv_layer:
                    conv_output = x
                    tape.watch(conv_output)
            if conv_output is None:
                raise ValueError(
                    f"Layer '{self.last_conv_layer}' was not found while replaying "
                    "self.model.layers — Grad-CAM only supports a last-conv layer "
                    "that sits at the top level of the model (e.g. a backbone "
                    "wrapped as a single nested layer)."
                )
            predictions = x
            if class_index is None:
                class_index = int(tf.argmax(predictions[0]))
            class_channel = predictions[:, class_index]

        grads = tape.gradient(class_channel, conv_output)
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
        conv_output = conv_output[0]
        heatmap = conv_output @ pooled_grads[..., tf.newaxis]
        heatmap = tf.squeeze(heatmap)
        heatmap = tf.maximum(heatmap, 0) / (tf.math.reduce_max(heatmap) + 1e-8)
        return heatmap.numpy(), class_index


def heatmap_to_overlay(heatmap: np.ndarray, original: Image.Image, alpha: float = 0.5) -> Image.Image:
    """Resize the Grad-CAM heatmap to the original image size, apply the
    jet colour map and alpha-blend it over the original leaf photo."""
    import matplotlib as mpl

    original = original.convert("RGB")
    heatmap_img = Image.fromarray(np.uint8(255 * heatmap)).resize(original.size, Image.BILINEAR)
    heatmap_arr = np.array(heatmap_img)
    jet = mpl.colormaps["jet"](heatmap_arr / 255.0)[:, :, :3]
    jet = Image.fromarray(np.uint8(jet * 255))
    return Image.blend(original, jet, alpha=alpha)


def image_to_base64_png(image: Image.Image) -> str:
    import base64

    buf = io.BytesIO()
    image.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("ascii")


def confidence_tier(confidence: float) -> str:
    if confidence >= CONFIRMED_THRESHOLD:
        return "Confirmed"
    if confidence >= UNCERTAIN_THRESHOLD:
        return "Uncertain"
    return "Low_Confidence"
