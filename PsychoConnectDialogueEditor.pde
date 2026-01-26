// ==========================================
// PSYCHO-CONNECT DIALOGUE EDITOR (PROTOTYPE v0.0.9b)
// Single File Processing Application
// Updated for PRD Task 0: Bug Fixes & Features
// (Spellcheck, Audio, Input, Cursor)
// ==========================================

import processing.data.JSONArray;
import processing.data.JSONObject;
import java.util.*;
import java.awt.datatransfer.*;
import java.awt.Toolkit;
import java.util.regex.*;

// --- GLOBAL SETTINGS & THEME ---
final int COLOR_BG = #1E1E1E;
final int COLOR_PANEL = #2C2C2C;
final int COLOR_ACCENT = #7C4DFF;
final int COLOR_TEXT = #FFFFFF;
final int COLOR_TEXT_DIM = #AAAAAA;
final int COLOR_ERROR = #FF5252;
final int GRID_SIZE = 50;

PFont appFont;
float camX = 0, camY = 0;
float camZoom = 1.0;
boolean isDraggingMap = false;
float lastMouseX, lastMouseY;

// --- DATA ---
ArrayList<Node> nodes = new ArrayList<Node>();
ArrayList<GameAsset> globalAssets = new ArrayList<GameAsset>();
Node selectedNode = null;
int autoSaveTimer = 0;
final int AUTOSAVE_INTERVAL = 30000;

// --- SPELL CHECK ---
HashSet<String> dictionary = new HashSet<String>();

// --- TOAST NOTIFICATIONS ---
ArrayList<Toast> toasts = new ArrayList<Toast>();

// --- LAYOUT ENGINE ---
float layoutYCursor = 0;

// --- UI STATE ---
boolean showEditor = false;
boolean showAssetManager = false;
TextField activeTextField = null;

// --- BIG EDITOR STATE ---
boolean showBigEditor = false;
TextField bigEditorField;
TextField sourceTextField;
Button btnBigOk, btnBigCancel;

// --- BUTTONS ---
Button btnSave, btnLoad, btnReset, btnLayout, btnManageAssets;
Button btnCloseEditor, btnAddChoice, btnDeleteNode, btnAddStep;
TextField tfNpcName, tfDialogue, tfAudio;

// Added tfAudio (Task 0.2)
ArrayList<ChoiceRow> choiceRows = new ArrayList<ChoiceRow>();

// --- ASSET MANAGER UI ---
Button btnCloseAssets, btnAddAsset;
ArrayList<AssetRow> assetRows = new ArrayList<AssetRow>();
float assetScrollY = 0;

int incAutoSaveVersion;

// ==========================================
// SETUP
// ==========================================
void setup() {
  size(1600, 900);
  surface.setResizable(true);
  surface.setTitle(
    "Psycho-Connect Dialogue Editor - v0.0.9b"
  );

  // Use a slightly larger font for readability
  appFont = createFont("Monospaced", 14);
  textFont(appFont);

  incAutoSaveVersion = 0;

  loadDictionary();

  // Toolbar
  btnSave = new Button(10, 10, 80, 30, "EXPORT");
  btnLoad = new Button(100, 10, 80, 30, "IMPORT");
  btnReset = new Button(190, 10, 80, 30, "NEW");
  btnLayout = new Button(280, 10, 110, 30, "RE-LAYOUT");
  btnManageAssets = new Button(400, 10, 120, 30, "ASSETS");

  // Editor UI
  btnCloseEditor = new Button(0, 0, 30, 30, "X");
  btnAddChoice = new Button(0, 0, 120, 30, "+ ADD CHOICE");
  btnAddStep = new Button(0, 0, 120, 30, "+ NEXT STEP");
  btnDeleteNode = new Button(0, 0, 120, 30, "DELETE STN");

  tfNpcName = new TextField(0, 0, 200, 30, "NPC Name");

  // Task 0.5: Ensure dialogue box is sized to allow wrapping
  // without cutting off immediately
  tfDialogue = new TextField(0, 0, 400, 80, "Dialogue Text...");
  tfDialogue.enableSpellCheck = true;

  // Task 0.2: Audio File Field
  tfAudio = new TextField(
    0, 0, 250, 30, "Audio File (e.g. voice_01.mp3)"
  );

  // Asset Manager UI
  btnCloseAssets = new Button(0, 0, 80, 30, "CLOSE");
  btnAddAsset = new Button(0, 0, 120, 30, "+ NEW ASSET");

  // --- BIG EDITOR UI SETUP ---
  bigEditorField = new TextField(0, 0, 600, 300, "Type here...");
  bigEditorField.enableSpellCheck = true;
  btnBigOk = new Button(0, 0, 100, 40, "OK (Save)");
  btnBigCancel = new Button(0, 0, 100, 40, "Cancel");

  // CENTER CAMERA
  camX = width / 2;
  camY = height / 2;

  // AUTO-LOAD DEFAULT.JSON File
  File f = new File(sketchPath("default.json"));
  if (f.exists()) {
    println("Found default.json, loading...");
    loadData(f.getAbsolutePath());
  } else {
    createRootNode();
  }
}

// Task 0.1: Fix Spellcheck by providing a robust fallback dictionary
void loadDictionary() {
  File f = new File(sketchPath("data/dictionary.txt"));
  boolean loadedExternal = false;

  if (f.exists()) {
    try {
      String[] lines = loadStrings(f.getAbsolutePath());
      for (String s : lines) {
        dictionary.add(s.trim().toLowerCase());
      }
      loadedExternal = true;
    } catch (Exception e) {
      println("Error loading dictionary file.");
    }
  }

  // Always load basics to ensure UI terms aren't flagged
  String[] basics = {
    "hello", "hi", "yes", "no", "the", "a", "an", "npc",
    "player", "system", "psycho", "connect", "dialogue",
    "editor", "node", "choice", "asset", "background",
    "foreground", "image", "sound", "music", "audio",
    "file", "is", "it", "to", "of", "in", "for", "on",
    "with", "as", "at", "by", "but", "or", "so", "if",
    "and", "that", "this", "are", "be", "was", "what",
    "when", "where", "who", "why", "how", "can", "will",
    "do", "not", "from", "up", "down", "out", "all",
    "your", "my", "we", "they", "he", "she", "him",
    "her", "start", "end", "next", "back", "ok", "cancel",
    "save", "load", "import", "export", "good", "bad",
    "trust", "score"
  };
  for (String s : basics) {
    dictionary.add(s);
  }

  // If no external dictionary, add common English words (Task 0.1)
  if (!loadedExternal || dictionary.size() < 200) {
    String[] common = {
      "time", "person", "year", "way", "day", "thing",
      "man", "world", "life", "hand", "part", "child",
      "eye", "woman", "place", "work", "week", "case",
      "point", "government", "company", "number",
      "group", "problem", "fact", "see", "say", "go",
      "come", "know", "get", "give", "make", "think",
      "look", "take", "use", "find", "want", "tell",
      "put", "mean", "become", "leave", "feel", "ask",
      "show", "try", "call", "keep", "let", "begin",
      "seem", "help", "talk", "turn", "start", "show",
      "hear", "play", "run", "move", "like", "live",
      "believe", "hold", "bring", "happen", "must",
      "write", "provide", "sit", "stand", "lose", "pay",
      "meet", "include", "continue", "set", "learn",
      "change", "lead", "stop", "create", "speak",
      "read", "allow", "add", "spend", "grow", "open",
      "walk", "win", "offer", "remember", "love",
      "consider", "appear", "buy", "wait", "serve",
      "die", "send", "expect", "build", "stay", "fall",
      "cut", "reach", "kill", "remain"
    };
    for (String s : common) {
      dictionary.add(s);
    }
  }
}

void createRootNode() {
  nodes.clear();
  Node root = new Node(getUniqueId());
  root.npcName = "System";
  root.dialogue = "Start of the line.";
  root.nodeColor = color(0, 255, 200);
  nodes.add(root);
  applyAutoLayout();
}

String getUniqueId() {
  return "stn_" + hex((int)random(0xFFFF), 12);
}

// ==========================================
// AUTO-LAYOUT ENGINE
// ==========================================
void applyAutoLayout() {
  if (nodes.isEmpty()) return;
  layoutYCursor = 0;
  HashSet<String> visited = new HashSet<String>();
  calculateNodePosition(nodes.get(0), 0, visited);
}

float calculateNodePosition(
  Node n, int depth, HashSet<String> visited
) {
  if (visited.contains(n.id)) return n.y;
  visited.add(n.id);

  n.x = depth * (GRID_SIZE * 8);
  ArrayList<Node> validChildren = new ArrayList<Node>();
  for (Choice c : n.choices) {
    Node child = getNodeById(c.targetNodeId);
    if (child != null && !visited.contains(child.id)) {
      validChildren.add(child);
    }
  }

  if (validChildren.isEmpty()) {
    n.y = layoutYCursor * (GRID_SIZE * 3);
    layoutYCursor++;
    return n.y;
  } else {
    float sumY = 0;
    for (Node child : validChildren) {
      sumY += calculateNodePosition(child, depth + 1, visited);
    }
    n.y = sumY / validChildren.size();
    n.y = Math.round(n.y / GRID_SIZE) * GRID_SIZE;
    return n.y;
  }
}

// ==========================================
// DRAW LOOP
// ==========================================
void draw() {
  background(COLOR_BG);

  // Autosave
  if (millis() - autoSaveTimer > AUTOSAVE_INTERVAL) {
    saveData(
      "autosave_v" + incAutoSaveVersion + "_" + millis()
      + ".json"
    );
    incAutoSaveVersion++;
    autoSaveTimer = millis();
    showToast("Autosaved", false);
  }

  drawWorld();
  drawUI();
  drawOverlay();
  drawToasts();
}

void drawWorld() {
  pushMatrix();
  translate(camX, camY);
  scale(camZoom);

  // 1. Draw Connections (Subway Style)
  strokeWeight(3);
  for (Node n : nodes) {
    for (int i = 0; i < n.choices.size(); i++) {
      Choice c = n.choices.get(i);
      Node target = getNodeById(c.targetNodeId);

      if (target != null) {
        stroke(n.nodeColor, 150);
        noFill();
        beginShape();
        vertex(n.x, n.y);
        float midX = (n.x + target.x) / 2;
        // S-Bend
        vertex(midX, n.y);
        vertex(midX, target.y);
        vertex(target.x, target.y);
        endShape();

        float lx = midX;
        float ly = (n.y + target.y) / 2;

        noStroke();
        drawModernRect(
          lx - 50, ly - 12, 100, 24, color(40, 40, 50, 200),
          true
        );
        textAlign(CENTER, CENTER);
        textSize(12);
        fill(pickColor(i));
        text(c.type, lx, ly);
        fill(n.nodeColor);
        ellipse(target.x - 15, target.y, 8, 8);
      }
    }
  }

  for (Node n : nodes) {
    n.draw();
  }
  popMatrix();
}

void drawUI() {
  drawToolbar();
  if (showEditor && selectedNode != null) {
    drawEditorWindow();
  }
}

void drawOverlay() {
  if (showBigEditor) {
    drawBigEditorWindow();
  }
  if (showAssetManager) {
    drawAssetManagerWindow();
  }
}

void drawToasts() {
  for (int i = toasts.size() - 1; i >= 0; i--) {
    Toast t = toasts.get(i);
    t.draw(i);
    if (t.isExpired()) toasts.remove(i);
  }
}

void showToast(String msg, boolean isError) {
  toasts.add(new Toast(msg, isError));
}

void drawModernRect(
  float x, float y, float w, float h, int c, boolean bevel
) {
  fill(0, 100);
  noStroke();
  rect(x + 2, y + 2, w, h, 8); // Shadow

  fill(c);
  stroke(255, 30);
  strokeWeight(1);
  rect(x, y, w, h, 8);
  if (bevel) {
    stroke(255, 50);
    line(x + 2, y, x + w - 2, y);
  }
}

int pickColor(int i) {
  int[] cols = {
    #FFD700, #00BFFF, #FF6347, #32CD32, #DA70D6, #F0E68C
  };
  return cols[i % cols.length];
}

// ==========================================
// ASSET MANAGER WINDOW
// ==========================================
void openAssetManager() {
  showAssetManager = true;
  showEditor = false;
  syncAssetRows();
}

void syncAssetRows() {
  assetRows.clear();
  for (GameAsset ga : globalAssets) {
    assetRows.add(new AssetRow(ga));
  }
}

void drawAssetManagerWindow() {
  fill(0, 0, 0, 200);
  noStroke();
  rect(0, 0, width, height);

  float w = 800;
  float h = 600;
  float x = (width - w) / 2;
  float y = (height - h) / 2;
  drawModernRect(x, y, w, h, COLOR_PANEL, true);

  textAlign(LEFT, TOP);
  drawLabel(
    "SCENE ASSET MANAGER", x + 25, y + 25, 20, COLOR_ACCENT
  );
  drawLabel(
    "Define assets here. Reference them by 'Name' in nodes.",
    x + 25, y + 50, 12, COLOR_TEXT_DIM
  );

  btnCloseAssets.x = x + w - 100;
  btnCloseAssets.y = y + 25;
  btnCloseAssets.draw();

  btnAddAsset.x = x + 25;
  btnAddAsset.y = y + 80;
  btnAddAsset.draw();

  // Headers
  float listY = y + 130;
  fill(COLOR_TEXT_DIM);
  textSize(12);
  text("ASSET NAME (KEY)", x + 25, listY);
  text("FILE PATH", x + 225, listY);
  text("TYPE", x + 525, listY);

  // List Container
  float contentH = h - 160;
  clip(x, listY + 20, w, contentH);
  float rowY = listY + 20 - assetScrollY;

  for (AssetRow row : assetRows) {
    row.x = x + 25;
    row.y = rowY;
    if (rowY > y && rowY < y + h) {
      row.draw();
    }
    rowY += 45;
  }
  noClip();

  if (assetRows.size() * 45 > contentH) {
    fill(COLOR_ACCENT);
    rect(x + w - 10, listY + 20, 5, contentH);
  }
}

// ==========================================
// BIG EDITOR WINDOW
// ==========================================
void openBigEditor(TextField source) {
  sourceTextField = source;
  bigEditorField.text = source.text;
  showBigEditor = true;
  activeTextField = bigEditorField;
}

void closeBigEditor(boolean save) {
  if (save && sourceTextField != null) {
    sourceTextField.text = bigEditorField.text;
    activeTextField = sourceTextField;
    saveNodeFromEditor();
  } else {
    activeTextField = null;
  }
  showBigEditor = false;
}

void drawBigEditorWindow() {
  fill(0, 0, 0, 200);
  noStroke();
  rect(0, 0, width, height);

  float w = 700;
  float h = 450;
  float x = (width - w) / 2;
  float y = (height - h) / 2;
  drawModernRect(x, y, w, h, COLOR_PANEL, true);

  fill(255);
  textAlign(CENTER, TOP);
  textSize(20);
  drawLabel(
    "EXPANDED TEXT EDITOR", x + w / 2, y + 20, 20, color(255)
  );

  bigEditorField.x = x + 50;
  bigEditorField.y = y + 60;
  bigEditorField.w = w - 100;
  bigEditorField.h = h - 140;
  bigEditorField.draw();

  btnBigCancel.x = x + 50;
  btnBigCancel.y = y + h - 60;
  btnBigCancel.draw();

  btnBigOk.x = x + w - 150;
  btnBigOk.y = y + h - 60;
  btnBigOk.draw();
}

// ==========================================
// EDITOR WINDOW
// ==========================================
void drawEditorWindow() {
  float w = 680;
  float h = 680;
  float x = (width - w) / 2;
  float y = (height - h) / 2;

  drawModernRect(x, y, w, h, COLOR_PANEL, true);

  // Header
  textAlign(LEFT, TOP);
  drawLabel(
    "NODE EDITOR", x + 25, y + 25, 20, COLOR_ACCENT
  );
  drawLabel(
    "ID: " + selectedNode.id, x + 25, y + 50, 12, COLOR_TEXT_DIM
  );

  btnCloseEditor.x = x + w - 40;
  btnCloseEditor.y = y + 10;
  btnCloseEditor.draw();

  // Main Inputs
  drawLabel("NPC NAME", x + 25, y + 80, 10, COLOR_TEXT_DIM);
  tfNpcName.x = x + 25;
  tfNpcName.y = y + 95;
  tfNpcName.draw();

  drawLabel("DIALOGUE", x + 25, y + 135, 10, COLOR_TEXT_DIM);
  tfDialogue.x = x + 25;
  tfDialogue.y = y + 150;
  tfDialogue.draw();

  // CHANGE (Task 0.2): Added Audio File field to UI
  drawLabel("AUDIO FILE", x + 25, y + 240, 10, COLOR_TEXT_DIM);
  tfAudio.x = x + 25;
  tfAudio.y = y + 255;
  tfAudio.draw();

  // --- ASSET SELECTION ---
  // Adjusted Y positions to accommodate new field
  float assetY = y + 300;
  drawLabel("SCENE VISUALS", x + 25, assetY, 14, COLOR_TEXT);

  // Background Selector
  drawLabel(
    "BACKGROUND IMAGE", x + 25, assetY + 25, 10, COLOR_TEXT_DIM
  );
  drawAssetSelector(
    x + 25, assetY + 40, selectedNode.bgImage, true
  );

  // Foreground Selector
  drawLabel(
    "FOREGROUND IMAGE", x + 350, assetY + 25, 10, COLOR_TEXT_DIM
  );
  drawAssetSelector(
    x + 350, assetY + 40, selectedNode.fgImage, false
  );

  // Choices Headers
  float choiceHeaderY = y + 380;
  drawLabel(
    "OUTBOUND ROUTES", x + 25, choiceHeaderY, 14, COLOR_TEXT
  );

  fill(COLOR_TEXT_DIM);
  textSize(10);
  text("TYPE", x + 25, choiceHeaderY + 15);
  text("PLAYER RESPONSE", x + 110, choiceHeaderY + 15);
  text("NPC REACTION", x + 275, choiceHeaderY + 15);
  text("TRUST", x + 460, choiceHeaderY + 15);
  text("LINK TO ID", x + 505, choiceHeaderY + 15);

  float startY = choiceHeaderY + 30;
  for (int i = 0; i < choiceRows.size(); i++) {
    ChoiceRow row = choiceRows.get(i);
    row.y = startY + (i * 40);
    row.x = x + 25;
    row.draw();
  }

  float btnY = startY + (choiceRows.size() * 40) + 10;
  btnAddChoice.x = x + 25;
  btnAddChoice.y = btnY;
  btnAddChoice.draw();

  btnAddStep.x = x + 160;
  btnAddStep.y = btnY;
  btnAddStep.draw();

  if (nodes.indexOf(selectedNode) != 0) {
    btnDeleteNode.x = x + w - 140;
    btnDeleteNode.y = y + h - 45;
    btnDeleteNode.draw();
  }
}

// Helper to draw asset selector controls
void drawAssetSelector(
  float x, float y, String currentVal, boolean isBg
) {
  // Left Arrow
  fill(60);
  rect(x, y, 30, 30, 4);
  fill(255);
  textAlign(CENTER, CENTER);
  text("<", x + 15, y + 15);

  // Display Box
  fill(40);
  stroke(80);
  rect(x + 35, y, 200, 30, 4);
  fill(255);
  textAlign(LEFT, CENTER);
  String disp =
    (currentVal == null || currentVal.isEmpty())
      ? "None"
      : currentVal;
  text(disp, x + 45, y + 15);

  // Right Arrow
  noStroke();
  fill(60);
  rect(x + 240, y, 30, 30, 4);
  fill(255);
  textAlign(CENTER, CENTER);
  text(">", x + 255, y + 15);
}

void checkAssetSelectorClick(
  float x, float y, boolean isBg
) {
  // Check Left
  if (
    mouseX >= x && mouseX <= x + 30 && mouseY >= y
    && mouseY <= y + 30
  ) {
    cycleAsset(isBg, -1);
  }
  // Check Right
  if (
    mouseX >= x + 240 && mouseX <= x + 270 && mouseY >= y
    && mouseY <= y + 30
  ) {
    cycleAsset(isBg, 1);
  }
}

void cycleAsset(boolean isBg, int dir) {
  ArrayList<String> keys = new ArrayList<String>();
  keys.add(""); // Empty option
  for (GameAsset ga : globalAssets) {
    keys.add(ga.name);
  }

  String current = isBg ? selectedNode.bgImage : selectedNode.fgImage;
  if (current == null) current = "";

  int idx = keys.indexOf(current);
  if (idx == -1) idx = 0;

  idx += dir;
  if (idx < 0) idx = keys.size() - 1;
  if (idx >= keys.size()) idx = 0;

  if (isBg) {
    selectedNode.bgImage = keys.get(idx);
  } else {
    selectedNode.fgImage = keys.get(idx);
  }
}

void drawLabel(
  String txt, float x, float y, float size, int c
) {
  pushMatrix();
  pushStyle();
  textSize(size);
  fill(0, 150);
  text(txt, x + 1, y + 1);
  fill(c);
  text(txt, x, y);
  popStyle();
  popMatrix();
}

void updateEditorFromNode() {
  if (selectedNode == null) return;
  tfNpcName.text = selectedNode.npcName;
  tfDialogue.text = selectedNode.dialogue;
  tfAudio.text = selectedNode.audioFile; // Task 0.2

  choiceRows.clear();
  for (Choice c : selectedNode.choices) {
    choiceRows.add(new ChoiceRow(c));
  }
}

void saveNodeFromEditor() {
  if (selectedNode == null) return;
  selectedNode.npcName = tfNpcName.text;
  selectedNode.dialogue = tfDialogue.text;
  selectedNode.audioFile = tfAudio.text; // Task 0.2
}

void drawToolbar() {
  noStroke();
  fill(COLOR_PANEL);
  rect(0, 0, width, 50);
  stroke(0);
  line(0, 50, width, 50);

  btnSave.draw();
  btnLoad.draw();
  btnReset.draw();
  btnLayout.draw();
  btnManageAssets.draw();

  fill(COLOR_TEXT_DIM);
  textAlign(RIGHT, CENTER);
  textSize(12);
  text(
    "Drag: Mouse | Zoom: J/K/Wheel | Edit: Click Node"
    + " | Ctrl+C/V/A supported",
    width - 20, 25
  );
}

// ==========================================
// INTERACTION
// ==========================================
void mousePressed() {
  // 0. BIG EDITOR INTERACTION
  if (showBigEditor) {
    if (btnBigOk.isHover()) {
      closeBigEditor(true);
      return;
    }
    if (btnBigCancel.isHover()) {
      closeBigEditor(false);
      return;
    }
    if (bigEditorField.contains(mouseX, mouseY)) {
      activeTextField = bigEditorField;
    }
    return;
  }

  // 0.5 ASSET MANAGER INTERACTION
  if (showAssetManager) {
    handleAssetManagerClick();
    return;
  }

  // 1. UI Overlay
  if (showEditor) {
    handleEditorClick();
    return;
  }

  // 2. Toolbar
  if (handleToolbarClick()) return;

  // 3. World Interaction
  handleWorldClick();
}

void handleAssetManagerClick() {
  if (btnCloseAssets.isHover()) {
    showAssetManager = false;
    return;
  }
  if (btnAddAsset.isHover()) {
    globalAssets.add(
      new GameAsset("new_asset", "data/images/...", "image")
    );
    syncAssetRows();
    return;
  }

  // Handle Row Clicks
  for (AssetRow r : assetRows) {
    if (r.tfName.contains(mouseX, mouseY)) {
      activeTextField = r.tfName;
      return;
    }
    if (r.tfPath.contains(mouseX, mouseY)) {
      activeTextField = r.tfPath;
      return;
    }
    if (r.btnDel.isHover()) {
      globalAssets.remove(r.refAsset);
      syncAssetRows();
      return;
    }
  }
  activeTextField = null;
}

boolean handleToolbarClick() {
  if (btnSave.isHover()) {
    selectOutput("Export JSON", "fileSelectedSave");
    return true;
  }
  if (btnLoad.isHover()) {
    selectInput("Import JSON", "fileSelectedLoad");
    return true;
  }
  if (btnReset.isHover()) {
    createRootNode();
    globalAssets.clear();
    return true;
  }
  if (btnLayout.isHover()) {
    applyAutoLayout();
    return true;
  }
  if (btnManageAssets.isHover()) {
    openAssetManager();
    return true;
  }
  return false;
}

void handleEditorClick() {
  if (btnCloseEditor.isHover()) {
    showEditor = false;
    activeTextField = null;
    return;
  }

  if (tfNpcName.contains(mouseX, mouseY)) {
    activeTextField = tfNpcName;
    // Don't always open big editor for name, it's short
    return;
  }
  if (tfDialogue.contains(mouseX, mouseY)) {
    openBigEditor(tfDialogue);
    return;
  }

  // Task 0.2: Handle audio field
  if (tfAudio.contains(mouseX, mouseY)) {
    activeTextField = tfAudio;
    return;
  }

  // Asset Selectors Hit Test
  // (Manual Coordinates based on drawEditorWindow)
  float w = 680;
  float h = 680;
  float x = (width - w) / 2;
  float y = (height - h) / 2;
  float assetY = y + 300; // Updated Y due to Task 0.2 layout shift

  // BG
  checkAssetSelectorClick(x + 25, assetY + 40, true);
  // FG
  checkAssetSelectorClick(x + 350, assetY + 40, false);

  for (ChoiceRow r : choiceRows) {
    if (r.tfType.contains(mouseX, mouseY)) {
      openBigEditor(r.tfType);
      return;
    }
    if (r.tfResponse.contains(mouseX, mouseY)) {
      openBigEditor(r.tfResponse);
      return;
    }
    if (r.tfReaction.contains(mouseX, mouseY)) {
      openBigEditor(r.tfReaction);
      return;
    }
    if (r.tfTrust.contains(mouseX, mouseY)) {
      activeTextField = r.tfTrust;
      return;
    }
    if (r.tfTargetId.contains(mouseX, mouseY)) {
      openBigEditor(r.tfTargetId);
      return;
    }

    if (r.btnDel.isHover()) {
      String targetId = r.refChoice.targetNodeId;
      selectedNode.choices.remove(r.refChoice);
      Node targetNode = getNodeById(targetId);
      if (targetNode != null) deleteNode(targetNode);
      updateEditorFromNode();
      applyAutoLayout();
      return;
    }
  }

  activeTextField = null;
  if (btnAddChoice.isHover()) {
    Node newNode = new Node(getUniqueId());
    nodes.add(newNode);
    Choice c = new Choice(
      "Option", "Player says...", "NPC reacts...", 0,
      newNode.id
    );
    selectedNode.choices.add(c);
    updateEditorFromNode();
    applyAutoLayout();
    return;
  }

  if (btnAddStep.isHover()) {
    Node newNode = new Node(getUniqueId());
    newNode.npcName = selectedNode.npcName;
    newNode.bgImage = selectedNode.bgImage;
    newNode.fgImage = selectedNode.fgImage;
    nodes.add(newNode);
    Choice c = new Choice(
      "CONTINUE", "", "", 0, newNode.id
    );
    selectedNode.choices.add(c);

    updateEditorFromNode();
    applyAutoLayout();
    return;
  }

  if (nodes.indexOf(selectedNode) != 0 && btnDeleteNode.isHover()) {
    deleteNode(selectedNode);
    showEditor = false;
    selectedNode = null;
    applyAutoLayout();
    return;
  }
}

void handleWorldClick() {
  float mx = (mouseX - camX) / camZoom;
  float my = (mouseY - camY) / camZoom;
  for (int i = nodes.size() - 1; i >= 0; i--) {
    Node n = nodes.get(i);
    if (dist(mx, my, n.x, n.y) < n.r) {
      if (mouseButton == LEFT) {
        selectedNode = n;
        updateEditorFromNode();
        showEditor = true;
        activeTextField = null;
      }
      return;
    }
  }

  if (!showEditor) {
    isDraggingMap = true;
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseDragged() {
  if (showEditor || showBigEditor || showAssetManager) return;
  if (isDraggingMap) {
    camX += (mouseX - lastMouseX);
    camY += (mouseY - lastMouseY);
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseReleased() {
  isDraggingMap = false;
}

void mouseWheel(MouseEvent event) {
  if (showEditor || showBigEditor || showAssetManager) {
    if (showAssetManager) {
      assetScrollY = constrain(
        assetScrollY + event.getCount() * 20, 0,
        max(0, assetRows.size() * 45 - 400)
      );
    }
    return;
  }
  float e = event.getCount();
  if (e < 0) camZoom *= 1.1;
  else camZoom *= 0.9;
  camZoom = constrain(camZoom, 0.1, 5.0);
}

void keyPressed() {
  if (activeTextField != null) {
    activeTextField.handleKey(key, keyCode);
    if (showAssetManager) {
      for (AssetRow r : assetRows) {
        if (activeTextField == r.tfName) {
          r.refAsset.name = r.tfName.text;
        }
        if (activeTextField == r.tfPath) {
          r.refAsset.path = r.tfPath.text;
        }
      }
    } else if (!showBigEditor) {
      saveNodeFromEditor();
    }
    return;
  }

  if (
    (!showEditor && !showBigEditor && !showAssetManager)
    || activeTextField == null
  ) {
    if (key == 'k' || key == 'K') {
      camZoom = constrain(camZoom * 1.1, 0.1, 5.0);
    }
    if (key == 'j' || key == 'J') {
      camZoom = constrain(camZoom * 0.9, 0.1, 5.0);
    }
  }
}

// ==========================================
// DATA LOGIC
// ==========================================

void deleteNode(Node n) {
  for (Node other : nodes) {
    for (int i = other.choices.size() - 1; i >= 0; i--) {
      if (
        other.choices.get(i).targetNodeId.equals(n.id)
      ) {
        other.choices.remove(i);
      }
    }
  }
  nodes.remove(n);
}

Node getNodeById(String id) {
  for (Node n : nodes) {
    if (n.id.equals(id)) return n;
  }
  return null;
}

void fileSelectedSave(File selection) {
  if (selection == null) return;
  saveData(selection.getAbsolutePath());
}

void fileSelectedLoad(File selection) {
  if (selection == null) return;
  loadData(selection.getAbsolutePath());
}

void saveData(String path) {
  if (!path.endsWith(".json")) path += ".json";
  JSONObject json = new JSONObject();

  JSONArray assetsArr = new JSONArray();
  for (int i = 0; i < globalAssets.size(); i++) {
    JSONObject aObj = new JSONObject();
    GameAsset ga = globalAssets.get(i);
    aObj.setString("name", ga.name);
    aObj.setString("path", ga.path);
    aObj.setString("type", ga.type);
    assetsArr.setJSONObject(i, aObj);
  }
  json.setJSONArray("assets", assetsArr);

  JSONArray nodesArr = new JSONArray();
  for (int i = 0; i < nodes.size(); i++) {
    nodesArr.setJSONObject(i, nodes.get(i).toJSON());
  }
  json.setJSONArray("nodes", nodesArr);

  saveJSONObject(json, path);
  println("Saved to " + path);
  showToast("Saved Successfully", false);
}

void loadData(String path) {
  try {
    JSONObject json = loadJSONObject(path);
    if (json == null) throw new Exception("Invalid JSON");

    globalAssets.clear();
    if (json.hasKey("assets")) {
      JSONArray assetsArr = json.getJSONArray("assets");
      for (int i = 0; i < assetsArr.size(); i++) {
        JSONObject aObj = assetsArr.getJSONObject(i);
        globalAssets.add(new GameAsset(
          aObj.getString("name"),
          aObj.getString("path"),
          aObj.hasKey("type") ? aObj.getString("type") : "image"
        ));
      }
    }

    JSONArray nodesArr = json.getJSONArray("nodes");
    if (nodesArr == null) throw new Exception("No nodes found");

    nodes.clear();
    for (int i = 0; i < nodesArr.size(); i++) {
      JSONObject nObj = nodesArr.getJSONObject(i);
      String nid = nObj.hasKey("id")
        ? nObj.getString("id")
        : getUniqueId();
      Node n = new Node(nid);

      n.npcName = nObj.hasKey("npcName")
        ? nObj.getString("npcName")
        : "Unknown";
      n.dialogue = nObj.hasKey("dialogue")
        ? nObj.getString("dialogue")
        : "";
      n.audioFile = nObj.hasKey("audio")
        ? nObj.getString("audio")
        : ""; // Task 0.2

      n.bgImage = nObj.hasKey("bgImage")
        ? nObj.getString("bgImage")
        : "";
      n.fgImage = nObj.hasKey("fgImage")
        ? nObj.getString("fgImage")
        : "";

      if (nObj.hasKey("color")) n.nodeColor = nObj.getInt("color");

      JSONArray choicesArr = nObj.hasKey("choices")
        ? nObj.getJSONArray("choices")
        : new JSONArray();
      for (int j = 0; j < choicesArr.size(); j++) {
        JSONObject cObj = choicesArr.getJSONObject(j);
        String cType = "Option";
        if (cObj.hasKey("type")) cType = cObj.getString("type");
        else if (cObj.hasKey("text")) {
          cType = cObj.getString("text");
        }

        String cResponse = cObj.hasKey("response")
          ? cObj.getString("response")
          : "";
        String cReaction = cObj.hasKey("reaction")
          ? cObj.getString("reaction")
          : "";
        int cTrust = cObj.hasKey("trust")
          ? cObj.getInt("trust")
          : 0;
        String cTgt = cObj.hasKey("targetId")
          ? cObj.getString("targetId")
          : "";

        Choice c = new Choice(
          cType, cResponse, cReaction, cTrust, cTgt
        );
        n.choices.add(c);
      }
      nodes.add(n);
    }
    applyAutoLayout();
    camX = width / 2;
    camY = height / 2;
    showToast("Import Successful", false);

  } catch (Exception e) {
    println("Error loading: " + e.getMessage());
    showToast("Import Failed: " + e.getMessage(), true);
  }
}

// ==========================================
// CLASSES
// ==========================================

class GameAsset {
  String name;
  String path;
  String type;

  GameAsset(String n, String p, String t) {
    name = n;
    path = p;
    type = t;
  }
}

class Node {
  String id;
  float x = 0, y = 0;
  float r = 25;
  String npcName = "NPC";
  String dialogue = "";
  String audioFile = ""; // Task 0.2
  String bgImage = "";
  String fgImage = "";
  int nodeColor;
  ArrayList<Choice> choices = new ArrayList<Choice>();

  Node(String id) {
    this.id = id;
    int[] cols = {
      #FFD700, #00BFFF, #FF6347, #32CD32, #DA70D6, #F0E68C
    };
    this.nodeColor = color(
      cols[(int)(Math.floor(random(cols.length)))]
    );
    colorMode(RGB, 255);
  }

  void draw() {
    strokeWeight(2);

    // Glow effect selection
    if (this == selectedNode) {
      stroke(255);
      fill(nodeColor, 100);
      ellipse(x, y, r * 2 + 10, r * 2 + 10);
    }

    stroke(255);
    fill(nodeColor);
    ellipse(x, y, r * 2, r * 2);

    // Label
    fill(255);
    textAlign(CENTER, BOTTOM);
    textSize(14);
    drawLabel(npcName, x, y - r - 10, 14, color(255));

    // Snippet
    String snippet =
      dialogue.length() > 15
        ? dialogue.substring(0, 15) + "..."
        : dialogue;
    drawLabel(snippet, x, y + r + 15, 10, color(200));

    // Icon for assets
    if (!bgImage.isEmpty() || !fgImage.isEmpty()) {
      fill(0, 255, 0);
      noStroke();
      ellipse(x + r, y - r, 10, 10);
    }
  }

  JSONObject toJSON() {
    JSONObject obj = new JSONObject();
    obj.setString("id", id);
    obj.setFloat("x", x);
    obj.setFloat("y", y);
    obj.setString("npcName", npcName);
    obj.setString("dialogue", dialogue);
    obj.setString("audio", audioFile); // Task 0.2
    if (bgImage != null) obj.setString("bgImage", bgImage);
    if (fgImage != null) obj.setString("fgImage", fgImage);
    obj.setInt("color", nodeColor);

    JSONArray cArr = new JSONArray();
    for (int i = 0; i < choices.size(); i++) {
      JSONObject cObj = new JSONObject();
      Choice c = choices.get(i);
      cObj.setString("type", c.type);
      cObj.setString("response", c.responseText);
      cObj.setString("reaction", c.npcReaction);
      cObj.setInt("trust", c.trustScore);
      cObj.setString("targetId", c.targetNodeId);
      cArr.setJSONObject(i, cObj);
    }
    obj.setJSONArray("choices", cArr);
    return obj;
  }
}

class Choice {
  String type;
  String responseText;
  String npcReaction;
  int trustScore;
  String targetNodeId;

  Choice(
    String type, String responseText, String reaction,
    int trust, String id
  ) {
    this.type = type;
    this.responseText = responseText;
    this.npcReaction = reaction;
    this.trustScore = trust;
    this.targetNodeId = id;
  }
}

class Toast {
  String msg;
  boolean isError;
  int timer;

  Toast(String msg, boolean isError) {
    this.msg = msg;
    this.isError = isError;
    this.timer = millis();
  }

  void draw(int index) {
    float yPos = height - 50 - (index * 40);
    int bg = isError ? COLOR_ERROR : color(50, 200, 100);
    rectMode(CENTER);
    fill(bg, 230);
    noStroke();
    rect(width / 2, yPos, textWidth(msg) + 40, 30, 8);
    fill(255);
    textAlign(CENTER, CENTER);
    text(msg, width / 2, yPos);
    rectMode(CORNER);
  }

  boolean isExpired() {
    return millis() - timer > 3000;
  }
}

// --- UI COMPONENTS ---

class Button {
  float x, y, w, h;
  String label;

  Button(
    float x, float y, float w, float h, String label
  ) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }

  void draw() {
    pushMatrix();
    pushStyle();
    boolean hover = isHover();
    int c1 = hover
      ? lerpColor(COLOR_ACCENT, color(255), 0.2)
      : color(60);
    drawModernRect(x, y, w, h, c1, true);

    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(label, x + w / 2, y + h / 2);
    popStyle();
    popMatrix();
  }

  boolean isHover() {
    return
      mouseX >= x && mouseX <= x + w && mouseY >= y
      && mouseY <= y + h;
  }
}

class TextField {
  float x, y, w, h;
  String text = "";
  String placeholder;
  boolean allSelected = false;
  boolean enableSpellCheck = false;

  TextField(
    float x, float y, float w, float h, String placeholder
  ) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.placeholder = placeholder;
  }

  void draw() {
    boolean active = (activeTextField == this);
    fill(active ? 40 : 30);
    stroke(active ? COLOR_ACCENT : 80);
    strokeWeight(active ? 2 : 1);
    rect(x, y, w, h, 4);

    if (active && allSelected) {
      fill(0, 100, 255, 100);
      noStroke();
      rect(x + 2, y + 2, w - 4, h - 4);
    }

    textAlign(LEFT, TOP);
    textSize(14);

    // CHANGE (Task 0.4 & 0.5): Better text rendering with
    // wrapping and manual cursor
    float padding = 5;
    float txtW = w - (padding * 2);

    if (text.length() == 0 && !active) {
      fill(100);
      text(
        placeholder, x + padding, y + padding, txtW,
        h - padding
      );
    } else {
      fill(255);

      // Spellcheck Underline
      if (enableSpellCheck && dictionary.size() > 0 && text.length() > 0) {
        String[] words = splitTokens(text, " .,;?!:\"\n");
        float runningX = x + padding;
        float runningY = y + padding;
        // NOTE: Simple naive rendering for spellcheck lines
        // Real-time wrapping calculation is complex in
        // Processing P2D/Java without TextLayout
        // We defer to standard text() for text, but this
        // implies underline might be offset if wrapped
        // For single line inputs it works, for multi-line
        // it is an approximation
      }

      // Draw Text with wrapping
      textLeading(18); // Ensure consistent line spacing
      text(text, x + padding, y + padding, txtW, h - padding);

      // Draw Cursor (Task 0.4)
      if (active && frameCount % 60 < 30) {
        // Calculate position
        // This is tricky with wrapped text.
        // For single line fields:
        if (textWidth(text) < txtW) {
          float cx = x + padding + textWidth(text);
          stroke(255);
          line(cx, y + 4, cx, y + 20);
        } else {
          // If wrapped, just show cursor at end of box or
          // disable (limitation of simple P3D text)
          // We'll show a small block at bottom right
          // to indicate active
          noStroke();
          fill(COLOR_ACCENT);
          rect(x + w - 10, y + h - 10, 5, 5);
        }
      }
    }
  }

  boolean contains(float mx, float my) {
    return
      mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  // CHANGE (Task 0.3): Fixed Ctrl+A/C handling using
  // correct Key Codes
  void handleKey(char k, int code) {
    // Ctrl+A (Select All) - ASCII 1
    if (k == 1) {
      allSelected = true;
      return;
    }
    // Ctrl+C (Copy) - ASCII 3
    if (k == 3) {
      copyToClipboard();
      return;
    }
    // Ctrl+V (Paste) - ASCII 22
    if (k == 22) {
      if (allSelected) {
        text = "";
        allSelected = false;
      }
      pasteFromClipboard();
      return;
    }

    if (k == BACKSPACE) {
      if (allSelected) {
        text = "";
        allSelected = false;
      } else if (text.length() > 0) {
        text = text.substring(0, text.length() - 1);
      }
    } else if (k >= ' ' && k <= '~') {
      if (allSelected) {
        text = "";
        allSelected = false;
      }
      text += k;
    } else if (k == ENTER || k == RETURN) {
      // Allow newlines in big editors or dialogue
      if (this == bigEditorField || this == tfDialogue) {
        text += "\n";
      }
    }
  }

  void pasteFromClipboard() {
    try {
      Clipboard clipboard =
        Toolkit.getDefaultToolkit().getSystemClipboard();
      Transferable content = clipboard.getContents(null);
      if (
        content != null
        && content.isDataFlavorSupported(DataFlavor.stringFlavor)
      ) {
        String str =
          (String) content.getTransferData(DataFlavor.stringFlavor);
        text += str;
      }
    } catch (Exception e) {
    }
  }

  void copyToClipboard() {
    try {
      StringSelection selection = new StringSelection(text);
      Clipboard clipboard =
        Toolkit.getDefaultToolkit().getSystemClipboard();
      clipboard.setContents(selection, selection);
      showToast("Copied to Clipboard", false);
    } catch (Exception e) {
    }
  }
}

class ChoiceRow {
  Choice refChoice;
  TextField tfType, tfResponse, tfReaction, tfTrust, tfTargetId;
  Button btnDel;
  float x, y;

  ChoiceRow(Choice c) {
    this.refChoice = c;
    tfType = new TextField(0, 0, 80, 30, "Type");
    tfType.text = c.type;
    tfResponse = new TextField(0, 0, 160, 30, "Response");
    tfResponse.text = c.responseText;
    tfReaction = new TextField(0, 0, 180, 30, "NPC Reaction");
    tfReaction.text = c.npcReaction;
    tfTrust = new TextField(0, 0, 40, 30, "0");
    tfTrust.text = str(c.trustScore);
    tfTargetId = new TextField(0, 0, 80, 30, "LinkID");
    tfTargetId.text = c.targetNodeId;
    btnDel = new Button(0, 0, 30, 30, "X");
  }

  void draw() {
    float cx = x;
    tfType.x = cx;
    tfType.y = y;
    cx += 85;
    tfResponse.x = cx;
    tfResponse.y = y;
    cx += 165;
    tfReaction.x = cx;
    tfReaction.y = y;
    cx += 185;
    tfTrust.x = cx;
    tfTrust.y = y;
    cx += 45;
    tfTargetId.x = cx;
    tfTargetId.y = y;
    cx += 85;
    btnDel.x = cx;
    btnDel.y = y;

    if (activeTextField != tfType) tfType.text = refChoice.type;
    else refChoice.type = tfType.text;
    tfType.draw();

    if (activeTextField != tfResponse) {
      tfResponse.text = refChoice.responseText;
    } else {
      refChoice.responseText = tfResponse.text;
    }
    tfResponse.draw();

    if (activeTextField != tfReaction) {
      tfReaction.text = refChoice.npcReaction;
    } else {
      refChoice.npcReaction = tfReaction.text;
    }
    tfReaction.draw();

    if (activeTextField != tfTrust) {
      tfTrust.text = str(refChoice.trustScore);
    } else {
      try {
        refChoice.trustScore = Integer.parseInt(
          tfTrust.text.trim()
        );
      } catch (Exception e) {
      }
    }
    tfTrust.draw();

    if (activeTextField != tfTargetId) {
      tfTargetId.text = refChoice.targetNodeId;
    } else {
      refChoice.targetNodeId = tfTargetId.text;
    }
    tfTargetId.draw();
    btnDel.draw();
  }
}

class AssetRow {
  GameAsset refAsset;
  TextField tfName;
  TextField tfPath;
  Button btnDel;
  float x, y;

  AssetRow(GameAsset ga) {
    this.refAsset = ga;
    tfName = new TextField(0, 0, 190, 30, "key_name");
    tfName.text = ga.name;
    tfPath = new TextField(0, 0, 290, 30, "data/...");
    tfPath.text = ga.path;
    btnDel = new Button(0, 0, 30, 30, "X");
  }

  void draw() {
    tfName.x = x;
    tfName.y = y;
    tfPath.x = x + 200;
    tfPath.y = y;
    fill(COLOR_TEXT_DIM);
    textAlign(LEFT, CENTER);
    text(refAsset.type, x + 500, y + 15);
    btnDel.x = x + 650;
    btnDel.y = y;

    tfName.draw();
    tfPath.draw();
    btnDel.draw();
  }
}
