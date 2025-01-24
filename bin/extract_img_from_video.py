import os
import cv2
from datetime import datetime, timedelta
import ffmpeg  # Requires ffmpeg-python (install with `pip install ffmpeg-python`)
import piexif  # Requires piexif library (install with `pip install piexif`)
from concurrent.futures import ThreadPoolExecutor
from avi_r import AVIReader

def extract_images_from_video_with_exif(video_path, output_folder, video_file_name, target_duration=10, num_images=10):
    """
    Extract images from a video file, save them to the output folder, 
    and update the EXIF timestamp to match the video's frame time.
    """
    os.makedirs(output_folder, exist_ok=True)

    # Handle .AVI files
    if video_path.endswith(".AVI"):
        new_video_path = video_path[:-4] + ".avi"
        os.rename(video_path, new_video_path)
        video_path = new_video_path

    # Extract video creation timestamp using ffmpeg
    try:
        video_metadata = ffmpeg.probe(video_path)
        creation_time_str = next(
            stream['tags']['creation_time']
            for stream in video_metadata['streams']
            if 'tags' in stream and 'creation_time' in stream['tags']
        )
        # Convert to a datetime object
        video_creation_time = datetime.fromisoformat(creation_time_str.replace("Z", "+00:00"))
    except Exception as e:
        print(f"Warning: Could not extract creation time: {e}. Frames will be extracted without adding creation time metadata")
    
    # Determine if the video is an AVI file and use avi_r if necessary
    if video_path.endswith(".avi"):
        try:
            video = AVIReader(video_path)
            fps = video.frame_rate
            total_frames = int(video.num_frames)
        except Exception as e:
            print(f"Error reading AVI file with avi_r: {e}")
            return        
    else:
        video = cv2.VideoCapture(video_path)
        fps = video.get(cv2.CAP_PROP_FPS)
        total_frames = int(video.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Open video 
    video = cv2.VideoCapture(video_path)
    frames_to_capture = min(int(target_duration * fps), total_frames)
    interval = max(1, frames_to_capture // num_images)

    frame_count = 0
    captured_count = 0
    frame_duration = 1 / fps  # Duration of each frame in seconds

    while True:
        ret, frame = video.read()
        if not ret or captured_count >= num_images:
            break

        if frame_count % interval == 0:
            # Calculate timestamp for the current frame
            try:
                frame_timestamp = video_creation_time + timedelta(seconds=frame_count * frame_duration)
                exif_timestamp = frame_timestamp.strftime("%Y:%m:%d %H:%M:%S")  # EXIF-compliant format
            except:
                print(f'Warning: Error adding creation time, no video_creation_time detected')

            # Save the frame as an image
            image_filename = f"{video_file_name}_image{captured_count + 1:03d}.jpg"
            image_path = os.path.join(output_folder, image_filename)
            cv2.imwrite(image_path, frame)

            # Add EXIF timestamp metadata
            try:
                exif_dict = {"Exif": {piexif.ExifIFD.DateTimeOriginal: exif_timestamp.encode("utf-8")}}
                exif_bytes = piexif.dump(exif_dict)
                piexif.insert(exif_bytes, image_path)
                print(f"Captured: {image_path} with EXIF timestamp {exif_timestamp}")
            except Exception as e:
                print(f"Warning: Error adding EXIF data to {image_filename}: {e}")

            captured_count += 1

        frame_count += 1

    video.release()
    print(f"Extraction complete. {captured_count} images saved to {output_folder}.")

def process_directory(input_dir, output_root):
    """
    Process all videos in a given directory, saving extracted frames to a new folder.
    """
    video_extensions = {".mp4", ".avi", ".mov", ".mkv"}  # Add more extensions as needed
    species_name = os.path.basename(input_dir)
    output_folder = os.path.join(output_root, f"{species_name}_extracted")

    for file_name in os.listdir(input_dir):
        file_path = os.path.join(input_dir, file_name)
        if os.path.isfile(file_path) and os.path.splitext(file_name)[1].lower() in video_extensions:
            video_file_name = os.path.splitext(file_name)[0]
            extract_images_from_video_with_exif(file_path, output_folder, video_file_name)

def main(input_root, output_root, max_workers=4):
    """
    Main function to process all subdirectories in parallel.
    """
    os.makedirs(output_root, exist_ok=True)
    subdirs = [os.path.join(input_root, d) for d in os.listdir(input_root) if os.path.isdir(os.path.join(input_root, d))]

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(process_directory, subdir, output_root) for subdir in subdirs]
        for future in futures:
            future.result()  # Wait for all tasks to complete

if __name__ == "__main__":
   input_root = "/mnt/STORAGE/csar/pipo_images"  # Replace with the path to your main directory
   output_root = "../data/images_from_videos"  # Replace with the path to save extracted frames
   main(input_root, output_root, max_workers=20)

