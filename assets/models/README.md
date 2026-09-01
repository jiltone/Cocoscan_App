Place the on-device inference assets here:

- `coconut_disease_model.tflite` — TFLite export of the trained classifier
  (post-training DEFAULT quantisation, see report Section 4.2.1)
- `class_names.txt` — one class name per line, **in the exact order the
  training generator emitted them**. Must match
  `backend_python/class_names.json`:

```
Bud_Root_Dropping
Bud_Rot
Gray_Leaf_Spot
Healthy_Leaves
Leaf_Rot
Leaf_Yellowing
Stem_Bleeding
```

`lib/services/tflite_service.dart` loads these two files. Until they're
present, on-device inference falls back to calling the FastAPI
`/api/classify` endpoint instead (see `BackendService`).
