# StepTwoPrinter

Script that takes data exports from [StepTwo](https://steptwo.app) (app for TOTP based MFA for macOS and iOS) and make paper backup easier. It takes exports from the app that are in RTF format and converts to printable HTML with table and QR encoded data.

The HTML produced contains:

- Compact table with human-readable data:
  - account and username
  - TOTP params
  - secret key string separated every 4 characters for easier reading
- QR codes containing text form of above data
  - Number of codes is determined by QR code capacity with specified error correction level (default - `L`); if you want to change that or another parameter of `qrencode` you must tweak `$QRENCODE_MAX_CHARS_TOTAL` in the script (there's tester script in comment next to var definition)
  - It is always made even, so data is better balanced - both in terms of capacity and visuals
  - QR code contains the following data:
     - header with date of source RTF file modification (same as in HTML export) and part number
     - CSV (semicolon separated) data with header (same as in HTML export)

Requirements:

- `qrencode`
- `unrtf`
- GNU `coreutils`
- Google Chrome - unfortunately `@media print` especially in multi-paged mode does not work with my hacks on Safari like expected

## Usage

1. Open StepTwo on macOS
2. Open preferences (`⌘+,`), navigate to *iCloud* tab and click *Download iCloud Data...* button
3. Save file somewhere on the disk where the `StepTwoPrinter.sh` script is located (can be symlinked). 
	- You'll obviously want to use encrypted location (like FileVault). 
	- You can store with default name or use any naming convention - script will locate newest RTF file in current directory.
4. Run `./StepTwoPrinter.sh` and when browser opens, print the document (`⌘+P`).

## Demo

On the left source RFT file, on the right PDF printout from HTML output.

![screenshot](demo.jpg)
