# Psycho-Connect Dialogue Editor

**Visual Dialogue Graph Editor for Narrative Games**

---

![Dialogue Graph Overview](Editor-overview.png)

---

## Overview

**Psycho-Connect Dialogue Editor** is a free and open-source, node-based dialogue editor built in **Processing**. It is designed for narrative-heavy games, visual novels, RPGs, and experimental interactive fiction where dialogue structure, player intent, NPC reaction, and presentation assets are treated as first-class data.

The editor allows authors to visually construct branching dialogue graphs composed of **Stations (nodes)** and **Routes (choices)**, enriched with metadata such as intent type, trust impact, NPC reactions, dialogue audio, and per-node visual assets.

This project is currently a **prototype**, but is fully functional, actively developed, and suitable for real production pipelines.

**Current version:** `v0.0.9b`

---

## Key Features

### Node-based dialogue graph
- Each node represents a dialogue *station*
- Directed edges represent player choices
- Visual graph connections with curved routing

### Rich station data
Each node can contain:
- NPC name
- Dialogue text
- Optional dialogue **audio file**
- Per-node **background** and **foreground** images
- Outbound routes (choices)

### Rich choice metadata
- Choice *type* (e.g., Nice, Rude, Intelligent, etc.)
- Player response text
- NPC reaction text
- Trust score modifier
- Explicit target node linking

### Asset Manager
- Global asset library for scene visuals
- Assignable per-node **background** and **foreground** images
- Visual asset selector directly in the node editor
- Scrollable asset management window

### Sequential dialogue authoring
- **"+ NEXT STEP"** button for fast linear dialogue creation
- New nodes inherit NPC name and visual assets from the parent

### Expanded text editor
- Modal large text editor for long dialogue or reactions
- Supports multi-line input
- Keeps the main UI uncluttered

### Live editing
- Changes propagate immediately to graph and data
- No separate "apply" step

### JSON import/export
- Human-readable format
- Backward-compatible with earlier schema versions
- Safe defaults for missing fields

### Autosave (Improved)
- Automatic versioned autosaves with timestamps
- Prevents accidental data loss
- Manual export still supported

### Modern UI / UX
- Consistent theme system
- Shadows, bevels, and accent colors
- Toast notifications for user feedback
- Improved button states and visual clarity

### Single-file architecture
- Entire editor contained in one `.pde` file
- Easy to audit, modify, or fork
- No external build system required

---

## Requirements

- **Processing 4.x**  
  Download from: https://processing.org/download

- Java is bundled with Processing (no separate install required)

**Tested on:**
- Linux
- Expected to work on Windows and macOS

---

## How to Run

### 1. Install Processing

Download and install Processing from:
https://processing.org/download

### 2. Clone the Repository

```bash
git clone https://github.com/Enrique-ZA/psycho-connect-dialogue-editor.git
cd psycho-connect-dialogue-editor
```

Or download the ZIP and extract it.

### 3. Open the Sketch

1. Launch Processing
2. Open the file: `PsychoConnectDialogueEditor.pde`

### 4. Run

Click Run (▶). The editor window will open immediately.

---

## Basic Usage

### Navigation

| Action | Description |
|--------|-------------|
| Left-click node | Open station editor |
| Drag empty space | Pan camera |
| Mouse wheel / J / K | Zoom |
| Re-Layout | Auto-arrange graph |

### Stations (Nodes)

Each station contains:

- NPC Name
- Dialogue text
- Optional audio file
- Background image
- Foreground image
- A list of outbound routes (choices)

> **Note:** The root station is created automatically and cannot be deleted.

### Routes (Choices)

Each route includes:

| Field | Description |
|-------|-------------|
| Type | High-level intent or tone (used as graph label) |
| Player Response | Text the player selects |
| NPC Reaction | Immediate NPC response |
| Trust | Integer modifier |
| Link ID | Target station ID |

> **Warning:** Deleting a route also deletes its target station and cleans all references.

### Expanded Text Editor

Clicking on most text fields opens a modal expanded editor, suitable for long dialogue or reactions.

- **OK** → Save changes
- **Cancel** → Discard changes
- Supports multi-line input and proper cursor/selection handling

### Asset Manager

The Asset Manager allows you to define and reuse visual assets across dialogue nodes.

- Global asset list (images)
- Assignable per node as:
  - Background image
  - Foreground image
- Visual selectors embedded in the node editor
- Scrollable asset management UI

---

## File Format (JSON)

Exported dialogue is stored as a single JSON file.

**Example (simplified):**

```json
{
  "assets": [
    "bg_room.png",
    "fg_guard.png"
  ],
  "nodes": [
    {
      "id": "stn_1A2B3C4D5E6F",
      "npcName": "Guard",
      "dialogue": "Halt! Who goes there?",
      "audio": "guard_halt.wav",
      "bgImage": "bg_room.png",
      "fgImage": "fg_guard.png",
      "choices": [
        {
          "type": "Polite",
          "response": "Just a traveler.",
          "reaction": "The guard relaxes slightly.",
          "trust": 1,
          "targetId": "stn_3F9C8A1B2D4E"
        }
      ]
    }
  ]
}
```

### Compatibility

- Older versions without assets, audio, bgImage, or fgImage fields load safely
- Missing fields are defaulted
- Legacy "text" choice fields are handled automatically

---

## Project Status

**Prototype**

This means:

- Core functionality is stable
- UI and workflow may continue to evolve
- Data format is mostly stable but may expand

### Not yet included:

- Undo / redo
- Search
- Graph validation for broken links
- Multiple root nodes
- Runtime dialogue simulation / preview

---

## Philosophy

This project prioritizes:

- **Author clarity** over engine lock-in
- **Explicit structure** over hidden logic
- **Readable data** over proprietary formats
- **Hackability** over abstraction

The editor is engine-agnostic and designed to integrate into custom pipelines.

---

## License

**MIT License**

You are free to:

- Use
- Modify
- Fork
- Redistribute
- Integrate into commercial or non-commercial projects

> Attribution is appreciated but not required.

---

## Contributions

Contributions are welcome.

**Suggested areas:**

- UX improvements
- Keyboard navigation
- Undo / redo
- Graph validation
- Schema extensions
- Documentation
- Exporters (Ink, Yarn, Ren'Py, Godot, Unity, etc.)

> Please keep changes consistent with the single-file Processing architecture unless discussed.

---

## Author

Created by Enrique Nelson
