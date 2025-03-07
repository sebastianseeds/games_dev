import sys
import re

if len(sys.argv) != 3:
    print("Usage: python apply_frame_map.py <std_frame_map.tres> <character_map_to_be_modified.tres>")
    sys.exit(1)

std_frame_map_path = sys.argv[1]
character_tres_path = sys.argv[2]

# Read character .tres file
with open(character_tres_path, 'r') as char_file:
    char_lines = char_file.readlines()

# Debug: Show the first few lines
print(f"DEBUG: First 5 lines of {character_tres_path}:")
for i, line in enumerate(char_lines[:5]):
    print(f"{i + 1}: {line.strip()}")

# Corrected: Line 3 is actually index [2]
line_with_id = char_lines[2].strip()

print(f"DEBUG: Line with ID: {line_with_id}")

# Extract the ' id="..."' part (space before id)
texture_id_match = re.search(r' id="([^"]+)"', line_with_id)
if not texture_id_match:
    raise ValueError(f"Could not extract texture ID from expected line. Line content:\n{line_with_id}")

character_texture_id = texture_id_match.group(1)
print(f"DEBUG: Extracted Texture ID: {character_texture_id}")

# Read the standard frame map file
with open(std_frame_map_path, 'r') as std_map_file:
    std_map_lines = std_map_file.readlines()

# Replace '1_jud8h' with the extracted texture ID
std_map_modified = [line.replace("1_jud8h", character_texture_id) for line in std_map_lines]

# Merge: Keep the first 4 lines from the character file, append the rest from the standard map
merged_content = "".join(char_lines[:4]) + "".join(std_map_modified[4:])

# Write back to the character’s .tres file
with open(character_tres_path, 'w') as char_file:
    char_file.write(merged_content)

print(f"✅ Successfully updated {character_tres_path} using {std_frame_map_path} (Texture ID: {character_texture_id}).")
