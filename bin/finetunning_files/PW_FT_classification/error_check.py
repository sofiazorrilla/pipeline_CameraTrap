import os
import pandas as pd
from collections import Counter

# File paths
csv_file = "data/imgs/annotation_example.csv"
image_folder = "data/imgs"

# Step 1: Read the CSV file and extract .jpg or .JPG filenames from the first column
def read_csv_filenames(csv_file):
    try:
        df = pd.read_csv(csv_file, header=None)  # Assuming no header in the CSV
        filenames = df[0].tolist()  # Extract filenames from the first column
        # Filter for .jpg or .JPG files and normalize filenames
        filenames = [f.strip().lower() for f in filenames if f.lower().endswith(('.jpg', '.jpeg'))]
        return filenames
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return []

# Step 2: List all .jpg or .JPG files in the folder
def list_folder_files(folder):
    try:
        # Filter for .jpg or .JPG files and normalize filenames
        return [f.strip().lower() for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f)) and f.lower().endswith(('.jpg', '.jpeg'))]
    except Exception as e:
        print(f"Error reading folder: {e}")
        return []

# Step 3: Compare filenames between CSV and folder
def compare_filenames(csv_filenames, folder_filenames):
    # Print the number of .jpg or .JPG files in the CSV and folder (before extracting unique files)
    print(f"Number of .jpg/.JPG files in CSV (before extracting unique files): {len(csv_filenames)}")
    print(f"Number of .jpg/.JPG files in folder (before extracting unique files): {len(folder_filenames)}")

    # Convert both lists to sets for efficient comparison
    csv_set = set(csv_filenames)
    folder_set = set(folder_filenames)

    # Check for duplicates in CSV
    duplicate_csv_files = [file for file, count in Counter(csv_filenames).items() if count > 1]
    if duplicate_csv_files:
        print("Duplicate files in CSV:")
        for file in duplicate_csv_files:
            print(file)
    else:
        print("All files in CSV are unique.")

    # Check for duplicates in folder
    duplicate_folder_files = [file for file, count in Counter(folder_filenames).items() if count > 1]
    if duplicate_folder_files:
        print("Duplicate files in folder:")
        for file in duplicate_folder_files:
            print(file)
    else:
        print("All files in folder are unique.")

    # Count unique files
    unique_csv_count = len(csv_set)
    unique_folder_count = len(folder_set)

    print(f"Number of unique .jpg/.JPG files in CSV: {unique_csv_count}")
    print(f"Number of unique .jpg/.JPG files in folder: {unique_folder_count}")

    # Compare if the number of unique files is the same
    if unique_csv_count == unique_folder_count:
        print("The number of unique files in CSV and folder match.")
    else:
        print("The number of unique files in CSV and folder do not match.")

    # Check for missing files in the folder
    missing_in_folder = csv_set - folder_set
    if missing_in_folder:
        print("Files in CSV missing in folder:")
        for file in missing_in_folder:
            print(file)
    else:
        print("All files in CSV are present in the folder.")

    # Check for missing files in the CSV
    missing_in_csv = folder_set - csv_set
    if missing_in_csv:
        print("Files in folder missing in CSV:")
        for file in missing_in_csv:
            print(file)
    else:
        print("All files in folder are mentioned in the CSV.")

# Main function
def main():
    # Read filenames from CSV
    csv_filenames = read_csv_filenames(csv_file)
    if not csv_filenames:
        return

    # List files in folder
    folder_filenames = list_folder_files(image_folder)
    if not folder_filenames:
        return

    # Compare filenames
    compare_filenames(csv_filenames, folder_filenames)

# Run the script
if __name__ == "__main__":
    main()