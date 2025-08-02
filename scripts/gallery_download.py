#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
import requests
import os
import re
import sys

WALLPAPER_FOLDER = os.path.expanduser(os.path.join("~", "Pictures", "Wallpapers"))


def download_reddit_gallery(gallery_url):
    """
    Downloads all full-resolution images from a Reddit gallery URL.
    """
    # Append .json to the URL to get the post data
    if not gallery_url.endswith(".json"):
        gallery_url += ".json"

    # Set a custom User-Agent to avoid potential blocking
    headers = {"User-Agent": "My Reddit Gallery Downloader v1.0"}

    try:
        # Fetch the JSON data for the post
        response = requests.get(gallery_url, headers=headers)
        response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)
        data = response.json()

        # Extract the post data, specifically the media metadata
        post_data = data[0]["data"]["children"][0]["data"]
        media_metadata = post_data.get("media_metadata")

        if not media_metadata:
            print("Error: This doesn't appear to be a gallery post or it's empty.")
            return

        # Sanitize the post title to create a valid folder name
        post_title = post_data["title"]
        # Remove invalid characters for a folder name
        safe_folder_name = re.sub(r'[\\/*?:"<>|]', "", post_title).strip()

        # Create a directory with the sanitized post title
        if not os.path.exists(safe_folder_name):
            os.makedirs(safe_folder_name)

        print(f"Downloading images to folder: '{safe_folder_name}'")

        # Loop through each image in the gallery's metadata
        image_count = 0
        for image_id, meta in media_metadata.items():
            image_count += 1
            # The highest resolution image URL is in the 's' dictionary with key 'u'
            # The URL might be HTML-encoded, but requests handles it
            # We replace 'preview.redd.it' with 'i.redd.it' for the direct file
            full_res_url = meta["s"]["u"].replace("preview.redd.it", "i.redd.it")

            # Get the file extension (e.g., .jpg)
            file_extension = meta["m"].split("/")[-1]  # mimetype e.g., "image/jpeg"
            file_name = f"{image_id}.{file_extension}"
            file_path = os.path.join(WALLPAPER_FOLDER, file_name)

            print(f"  Downloading image {image_count}: {file_name}...")

            # Download and save the image
            image_response = requests.get(full_res_url, headers=headers)
            image_response.raise_for_status()

            with open(file_path, "wb+") as f:
                f.write(image_response.content)

        print(f"\n✅ Success! Downloaded {image_count} images.")

    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
    except (KeyError, IndexError):
        print(
            "Error: Could not parse the JSON data. The URL might be incorrect or the post structure has changed."
        )


if __name__ == "__main__":
    # Check if a URL was provided as a command-line argument
    if len(sys.argv) < 2:
        print("Usage: python reddit_downloader.py <reddit_gallery_url>")
        sys.exit(1)  # Exit the script if no URL is given

    input_url = sys.argv[1]  # Get the URL from the first argument
    if "reddit.com" in input_url:
        download_reddit_gallery(input_url)
    else:
        print("Invalid URL. Please enter a valid Reddit gallery URL.")
