# SheetSync 📊

**By Fox Jet Studios**

Sync data from **Google Sheets** directly into **Roblox Studio** in seconds. SheetSync turns spreadsheets into **ModuleScripts, Lua tables, or structured folders**, powered by a fast and reliable import pipeline.

Perfect for **configs, balancing values, item data, NPC stats, leaderboards, and live iteration** without touching code every time.

### Official Plugin: [Event Tracker - Roblox Creator Store](https://create.roblox.com/store/asset/71895649950262/SheetSync)

---

## Features ✨

* ✅ Import data straight from **Google Sheets**
* ✅ Automatic CSV parsing with smart type detection
* ✅ Generate:

  * **ModuleScripts**
  * **Lua tables**
  * **Folders with Value objects**
* ✅ Choose output **destination** (ServerStorage, ReplicatedStorage, Workspace)
* ✅ Live **data preview** before importing
* ✅ Clean, modern, and intuitive UI
* ✅ Built-in logging with success, warning, and error states
* ✅ Safe name sanitization for Roblox instances

---

## Installation 🛠️

1. Download the plugin `.rbxm` or `.rbxmx` file  
2. Open Roblox Studio  
3. Go to **Explorer → Plugin → Save as local plugin**  
4. Load the plugin in your game

*Or install it directly from the [Roblox Creator Store](https://create.roblox.com/store/asset/71895649950262/SheetSync) (recommended so you get auto-updates).*
<img width="1440" height="724" alt="Screenshot" src="https://github.com/user-attachments/assets/fcf481e3-b440-498a-9176-8807d9248839" />

---

## Usage 🚀

1. Open **SheetSync** from the **Plugins** tab
2. Paste your **Google Sheets URL**
3. Make sure the sheet is **public**:

   * Share → Anyone with the link → Viewer
4. Choose:

   * **Output Type** (ModuleScript, Folder + Values, Lua Table)
   * **Destination**
   * **Output Name**
5. Click **Import**
6. Your data is instantly generated in the selected location

Use **Preview** to inspect parsed data before importing.

---

## Output Types Explained 🧠

### 📦 ModuleScript

Creates a `ModuleScript` returning a Lua table:

```lua
local data = {
	{
		["Name"] = "Sword",
		["Damage"] = 25,
		["Rare"] = true
	}
}

return data
```

### 📁 Folder + Values

Creates a folder where:

* Each row becomes a folder
* Each column becomes a `StringValue`, `NumberValue`, or `BoolValue`

Great for designers who prefer visual data.

### 📜 Lua Table

Creates a `Script` that returns a raw Lua table, ideal for quick requires or legacy setups.

---

## How It Works ⚡

SheetSync uses a multi-step import pipeline:

* Converts a Google Sheets URL into a CSV export
* Fetches data using Roblox HTTP services
* Parses headers and rows safely
* Detects value types automatically
* Generates Roblox instances or Lua source code
* Logs every step in real time

No external dependencies. No runtime overhead.

**Demonstration video:**

https://github.com/user-attachments/assets/db526111-c7a5-4efe-a403-138ef096c0fa

---

## Requirements ⚠️

* **You must allow the plugin to use HTTP Service and script injection**
* Google Sheet must be **publicly accessible** with the permissions below:
<img width="553" height="462" alt="Screenshot" src="https://github.com/user-attachments/assets/7f49eba9-46c0-4b21-8e5c-1eef54c570e8" />

---

## License 📜

Code is released under the **MIT License**
Free to **use, modify, and distribute**.
See the LICENSE file for full details.

---

## Support & Feedback 💌

* Found a bug or want a feature? Reach out via **Fox Jet Studios**
* Follow us for updates and new tools
* Your feedback directly shapes future releases
