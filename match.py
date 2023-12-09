import re
import sys

# Check for the correct number of command-line arguments
if len(sys.argv) != 2:
    print("Usage: python script.py input_file")
    sys.exit(1)

# Get the input file name from the command-line argument
file_name = sys.argv[1]
outstr = ""
# Read the file line by line while ignoring invalid characters
with open(file_name, 'rb') as file:
    for line_bytes in file:
        try:
            # Decode the line with 'utf-8' codec, ignoring errors
            line = line_bytes.decode('ascii', errors='ignore')
            line = ''.join(re.findall(r'[a-zA-Z0-9 ]+', line)).rstrip()
            outstr = outstr + line
            # Use regular expression to find all "user" followed by digits, then characters, and then one or more 'a' characters
        except UnicodeDecodeError:
            pass

matches = re.findall(r'user\d+[a-zA-Z0-9 ]{30}a{10}', outstr)
# Print the matches
for match in matches:
    print(re.findall(r'user\d+' , match)[0])