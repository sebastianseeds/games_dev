from PIL import Image
import os

# Input and output folders
input_folder = "."
output_folder = "../cropped_temp"

# Create output folder if it doesn't exist
os.makedirs(output_folder, exist_ok=True)

# Set target size (same for all images)
TARGET_WIDTH = 842  # Adjust based on your standard frame width * number of columns
TARGET_HEIGHT = 1353  # Adjust based on your standard frame height * number of rows

# Process all PNG files in the input folder
for filename in os.listdir(input_folder):
    if filename.endswith(".png"):
        img_path = os.path.join(input_folder, filename)
        img = Image.open(img_path)

        # Crop from top-left corner to target size
        cropped_img = img.crop((0, 0, TARGET_WIDTH, TARGET_HEIGHT))

        # Save the cropped image
        output_path = os.path.join(output_folder, filename)
        cropped_img.save(output_path)

        print(f"Cropped and saved: {output_path}")

print("Batch cropping completed.")
