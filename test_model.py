import os, requests

valid_dir = r"C:\Users\waliq\OneDrive\Desktop\Datasets 2\Datasets 2\New Plant Diseases Dataset(Augmented)\New Plant Diseases Dataset(Augmented)\valid"

correct = 0
total = 0

for folder in sorted(os.listdir(valid_dir)):
    folder_path = os.path.join(valid_dir, folder)
    if not os.path.isdir(folder_path):
        continue
    images = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    if not images:
        continue
    img_path = os.path.join(folder_path, images[0])
    with open(img_path, 'rb') as f:
        r = requests.post('http://localhost:5000/predict-disease', files={'image': f})
    if r.status_code == 200:
        data = r.json()
        predicted = data.get('label', '')
        expected  = folder
        match = 'OK' if predicted == expected else 'XX'
        total += 1
        if predicted == expected:
            correct += 1
        print(f"{match} Expected: {expected[:40]:<40} | Got: {predicted}")
    else:
        print(f"❌ Error for {folder}: {r.text}")

print(f"\nAccuracy: {correct}/{total} = {correct/total*100:.1f}%")
