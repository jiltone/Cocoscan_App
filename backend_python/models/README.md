Place your trained Keras checkpoint here as either:

- `best_model_1.keras` (preferred), or
- `best_model.keras` (fallback)

The server auto-detects whether the backbone is ResNet50 or EfficientNetB4
from the layer names, so either checkpoint works without code changes
(see `model_utils.detect_architecture`).

Class order must match `backend_python/class_names.json`:
Bud_Root_Dropping, Bud_Rot, Gray_Leaf_Spot, Healthy_Leaves, Leaf_Rot,
Leaf_Yellowing, Stem_Bleeding — this must be the exact order the training
generator emitted the classes in, or every prediction will be silently
relabelled (see report Section 4.2.1).
