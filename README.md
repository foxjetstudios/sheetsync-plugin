# SheetSync

SheetSync is a roblox studio plugin that let's you import data from Google sheets directly into studio.

### Official Plugin: [SheetSync - Roblox Creator Store](https://create.roblox.com/store/asset/71895649950262/SheetSync)

---

## Features

* Import data from Google sheets
* Generate:
  * ModuleScripts
  * Scripts
  * Folders with value objects
* Choose destination (serverstorage, replicatedstorage or workspace)
* Preview data before you import
* Output frame for debugging

---

## Usage

1. Open SheetSync from the plugins tab
2. Paste your google sheets url
3. Make sure the sheet is public
4. Choose:
   * Output type
   * Destination
   * Output name
5. Click Import
6. Your data is imported in the destination you selected

---

## How It Works

* Converts a Google sheets url into a CSV export url
* Fetches the data using Roblox httpservice
* Parses headers and rows safely
* Automatically detects value types
* Generates instances or luau source code
* Logs every step in the output frame

---

## Requirements

* You must allow the plugin to use httpservice.
* You must allow the plugin to inject scripts
* Your Google sheet needs to be publicly accessible:

<img width="553" height="462" alt="Image" src="https://github.com/user-attachments/assets/7f49eba9-46c0-4b21-8e5c-1eef54c570e8" />

---

## License
Code is released under the MIT License
Free to use, modify, and distribute.
Please see the 'LICENSE' file for more details

---

Happy building! :)