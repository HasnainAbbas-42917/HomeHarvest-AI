"""
HomeHarvest AI - Plant Disease Detection
Transfer Learning with EfficientNetB0
Run: python train_transfer_learning.py
"""

import os
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
import matplotlib.pyplot as plt

# ─── Paths ───────────────────────────────────────────────────────────────────
BASE_DIR  = r"C:\Users\AIC\Desktop\Datasets 2\New Plant Diseases Dataset(Augmented)\New Plant Diseases Dataset(Augmented)"
TRAIN_DIR = os.path.join(BASE_DIR, "train")
VALID_DIR = os.path.join(BASE_DIR, "valid")

# ─── Config ──────────────────────────────────────────────────────────────────
IMG_SIZE    = (224, 224)
BATCH_SIZE  = 16
EPOCHS_HEAD = 5
EPOCHS_FINE = 5

# ─── Data Generators ─────────────────────────────────────────────────────────
train_gen = ImageDataGenerator(
    horizontal_flip=True,
    rotation_range=20,
    zoom_range=0.2,
    shear_range=0.2,
    width_shift_range=0.1,
    height_shift_range=0.1,
    preprocessing_function=tf.keras.applications.efficientnet.preprocess_input,
)
valid_gen = ImageDataGenerator(
    preprocessing_function=tf.keras.applications.efficientnet.preprocess_input,
)

train_data = train_gen.flow_from_directory(TRAIN_DIR, target_size=IMG_SIZE, batch_size=BATCH_SIZE, class_mode="categorical")
valid_data = valid_gen.flow_from_directory(VALID_DIR, target_size=IMG_SIZE, batch_size=BATCH_SIZE, class_mode="categorical")

# Save class indices for Flutter inference
import json
NUM_CLASSES = len(train_data.class_indices)
print(f"Detected {NUM_CLASSES} classes")
with open("class_indices.json", "w") as f:
    json.dump({v: k for k, v in train_data.class_indices.items()}, f, indent=2)
print(f"Saved {NUM_CLASSES} class labels to class_indices.json")

# ─── Build Model ─────────────────────────────────────────────────────────────
base_model = EfficientNetB0(weights="imagenet", include_top=False, input_shape=(*IMG_SIZE, 3))
base_model.trainable = False  # Freeze base for head training

inputs = tf.keras.Input(shape=(*IMG_SIZE, 3))
x = base_model(inputs, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.BatchNormalization()(x)
x = layers.Dense(256, activation="relu")(x)
x = layers.Dropout(0.4)(x)
outputs = layers.Dense(NUM_CLASSES, activation="softmax")(x)

model = models.Model(inputs, outputs)
model.summary()

# ─── Phase 1: Train Head Only ─────────────────────────────────────────────────
print("\n=== Phase 1: Training classification head ===")
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

callbacks_phase1 = [
    EarlyStopping(patience=4, restore_best_weights=True, monitor="val_accuracy"),
    ReduceLROnPlateau(factor=0.5, patience=2, monitor="val_loss"),
    ModelCheckpoint("best_plant_disease_tl.keras", save_best_only=True, monitor="val_accuracy"),
]

history1 = model.fit(
    train_data,
    validation_data=valid_data,
    epochs=EPOCHS_HEAD,
    callbacks=callbacks_phase1,
)

# ─── Phase 2: Fine-tune Top Layers ───────────────────────────────────────────
print("\n=== Phase 2: Fine-tuning top layers ===")
base_model.trainable = True

# Freeze all layers except the last 30
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=5e-5),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

callbacks_phase2 = [
    EarlyStopping(patience=5, restore_best_weights=True, monitor="val_accuracy"),
    ReduceLROnPlateau(factor=0.5, patience=3, monitor="val_loss"),
    ModelCheckpoint("best_plant_disease_tl.keras", save_best_only=True, monitor="val_accuracy"),
]

history2 = model.fit(
    train_data,
    validation_data=valid_data,
    epochs=EPOCHS_FINE,
    callbacks=callbacks_phase2,
)

# ─── Evaluate ────────────────────────────────────────────────────────────────
val_loss, val_acc = model.evaluate(valid_data)
print(f"\nFinal Validation Accuracy: {val_acc*100:.2f}%")

# ─── Convert to TFLite (for Flutter) ─────────────────────────────────────────
print("\nConverting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
with open("plant_disease_model.tflite", "wb") as f:
    f.write(tflite_model)
print("TFLite model saved as 'plant_disease_model.tflite'")

# ─── Plot Results ─────────────────────────────────────────────────────────────
acc1  = history1.history["accuracy"]
acc2  = history2.history["accuracy"]
vacc1 = history1.history["val_accuracy"]
vacc2 = history2.history["val_accuracy"]
loss1  = history1.history["loss"]
loss2  = history2.history["loss"]
vloss1 = history1.history["val_loss"]
vloss2 = history2.history["val_loss"]

all_acc  = acc1  + acc2
all_vacc = vacc1 + vacc2
all_loss  = loss1  + loss2
all_vloss = vloss1 + vloss2

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

ax1.plot(all_acc,  label="Train Accuracy")
ax1.plot(all_vacc, label="Val Accuracy")
ax1.axvline(x=len(acc1)-1, color="gray", linestyle="--", label="Fine-tune start")
ax1.set_title("Accuracy")
ax1.set_xlabel("Epoch")
ax1.legend()

ax2.plot(all_loss,  label="Train Loss")
ax2.plot(all_vloss, label="Val Loss")
ax2.axvline(x=len(loss1)-1, color="gray", linestyle="--", label="Fine-tune start")
ax2.set_title("Loss")
ax2.set_xlabel("Epoch")
ax2.legend()

plt.suptitle("EfficientNetB0 Transfer Learning - Plant Disease Detection")
plt.tight_layout()
plt.savefig("transfer_learning_results.png")
plt.show()
print("\nDone! Files saved:")
print("  - best_plant_disease_tl.keras")
print("  - plant_disease_model.tflite")
print("  - class_indices.json")
print("  - transfer_learning_results.png")
