# Bash Text Editor

## Description

This Bash script provides a simple text editor with features like editing text, changing text size, choosing font, saving changes, showing change history, and performing search and replace operations.

## Features

- Edit text files.
- Change text size and font.
- Save changes in different formats (txt, html, pdf).
- Show change history and revert to previous versions.
- Perform search and replace operations.

## Usage

Run the script using Bash:

./text_editor.sh [-f <file>] [-s <size>] [-o <font>]
Options:

-f <file>: Specify the file to edit. <br>
-s <size>: Specify the initial text size. <br>
-o <font>: Specify the initial font (Monospace, Arial, Times New Roman, Courier New). <br>
If options are not provided, the script prompts the user to select a file, font, and size interactively. <br>

Example
Suppose you want to edit a file named example.txt with the initial text size of 14 and font Arial. You can run the script as follows:

./text_editor.sh -f example.txt -s 14 -o Arial
