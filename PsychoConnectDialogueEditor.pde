// ==========================================
// PSYCHO-CONNECT DIALOGUE EDITOR (PROTOTYPE v0.0.8)
// Single File Processing Application
// ==========================================

import processing.data.JSONArray;
import processing.data.JSONObject;
import java.util.*;
import java.awt.datatransfer.*;
import java.awt.Toolkit; 

// --- GLOBAL SETTINGS ---
PFont appFont;
float camX = 0, camY = 0;
float camZoom = 1.0;
boolean isDraggingMap = false;
float lastMouseX, lastMouseY;

// --- DATA ---
ArrayList<Node> nodes = new ArrayList<Node>();
Node selectedNode = null;
int autoSaveTimer = 0;
final int AUTOSAVE_INTERVAL = 30000; // 30 seconds

// --- LAYOUT ENGINE ---
float layoutYCursor = 0;
// --- UI STATE ---
boolean showEditor = false;
TextField activeTextField = null;
// --- BIG EDITOR STATE ---
boolean showBigEditor = false;
TextField bigEditorField;
TextField sourceTextField;
// Remembers which small field triggered the big editor
Button btnBigOk, btnBigCancel;

// --- BUTTONS ---
Button btnSave, btnLoad, btnReset, btnLayout;
Button btnCloseEditor, btnAddChoice, btnDeleteNode;
TextField tfNpcName, tfDialogue;
ArrayList<ChoiceRow> choiceRows = new ArrayList<ChoiceRow>();
// ==========================================
// SETUP
// ==========================================
void setup() {
  size(1280, 720);
  surface.setResizable(true);
  surface.setTitle("Psycho-Connect Dialogue Editor - v0.0.8");
  appFont = createFont("Monospaced", 14);
  textFont(appFont);
// Toolbar
  btnSave = new Button(10, 10, 80, 30, "EXPORT");
  btnLoad = new Button(100, 10, 80, 30, "IMPORT");
  btnReset = new Button(190, 10, 80, 30, "NEW");
  btnLayout = new Button(280, 10, 100, 30, "RE-LAYOUT");
// Editor UI
  btnCloseEditor = new Button(0,0, 30, 30, "X");
  btnAddChoice = new Button(0,0, 120, 30, "+ ADD ROUTE");
  btnDeleteNode = new Button(0,0, 120, 30, "DELETE STN");
  
  tfNpcName = new TextField(0,0, 200, 30, "NPC Name");
  tfDialogue = new TextField(0,0, 400, 80, "Dialogue Text...");
  
  // --- BIG EDITOR UI SETUP ---
  // Centered large text field
  bigEditorField = new TextField(0, 0, 600, 300, "Type here...");
  btnBigOk = new Button(0, 0, 100, 40, "OK (Save)");
  btnBigCancel = new Button(0, 0, 100, 40, "Cancel");
// CENTER CAMERA
  camX = width/2;
  camY = height/2;

  // AUTO-LOAD DEFAULT.JSON
  File f = new File(sketchPath("default.json"));
  if (f.exists()) {
    println("Found default.json, loading...");
    loadData(f.getAbsolutePath());
  } else {
    createRootNode();
  }
}

void createRootNode() {
  nodes.clear();
  Node root = new Node(getUniqueId());
  root.npcName = "System";
  root.dialogue = "Start of the line.";
  root.nodeColor = color(0, 255, 200); // Cyan start
  nodes.add(root);
  applyAutoLayout();
}

String getUniqueId() {
  return "stn_" + hex((int)random(0xFFFF), 4);
}

// ==========================================
// AUTO-LAYOUT ENGINE
// ==========================================

void applyAutoLayout() {
  if (nodes.isEmpty()) return;
  layoutYCursor = 0;
  HashSet<String> visited = new HashSet<String>();
// Start from node 0 (Root)
  calculateNodePosition(nodes.get(0), 0, visited);
}

float calculateNodePosition(Node n, int depth, HashSet<String> visited) {
  if (visited.contains(n.id)) return n.y;
  visited.add(n.id);
  
  n.x = depth * 350;
// Increased horizontal spacing
  
  ArrayList<Node> validChildren = new ArrayList<Node>();
  for (Choice c : n.choices) {
    Node child = getNodeById(c.targetNodeId);
    if (child != null && !visited.contains(child.id)) {
      validChildren.add(child);
    }
  }
  
  if (validChildren.isEmpty()) {
    n.y = layoutYCursor * 120;
// Vertical spacing
    layoutYCursor++;
    return n.y;
  } else {
    float sumY = 0;
    for (Node child : validChildren) {
      sumY += calculateNodePosition(child, depth + 1, visited);
    }
    n.y = sumY / validChildren.size();
    return n.y;
  }
}

// ==========================================
// DRAW LOOP
// ==========================================
void draw() {
  background(25, 25, 30);
// Darker background
  
  // Autosave
  if (millis() - autoSaveTimer > AUTOSAVE_INTERVAL) {
    saveData("autosave.json");
    autoSaveTimer = millis();
  }

  // --- DRAW GRAPH ---
  pushMatrix();
  translate(camX, camY);
  scale(camZoom);
// 1. Draw Connections & Labels
  strokeWeight(3);
  
  for (Node n : nodes) {
    for (int i = 0; i < n.choices.size(); i++) {
      Choice c = n.choices.get(i);
      Node target = getNodeById(c.targetNodeId);
      if (target != null) {
        // Line
        stroke(200, 100);
// Subtle line
        line(n.x, n.y, target.x, target.y);
// Midpoint Label
        float midX = (n.x + target.x) / 2;
        float midY = (n.y + target.y) / 2;
        
        // Label Box (Draws the Choice TYPE)
        noStroke();
        fill(40, 40, 50, 255);
        float tw = textWidth(c.type) + 10;
        rectMode(CENTER);
        rect(midX, midY, tw, 20, 5);
        rectMode(CORNER);
        fill(0, 180);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(c.type, midX+2, midY + 2); // shadow
        // Label Text
        fill(pickColor(i));
// Match text color to choice index
        text(c.type, midX, midY);
// Direction Arrow
        float angle = atan2(target.y - n.y, target.x - n.x);
        float dist = dist(n.x, n.y, target.x, target.y);
        if (dist > 60) {
           float ax = target.x - cos(angle) * 35;
           float ay = target.y - sin(angle) * 35;
           fill(255, 150); 
           ellipse(ax, ay, 6, 6);
        }
      }
    }
  }
  
  // 2. Draw Nodes
  for (Node n : nodes) {
    n.draw();
  }
  
  popMatrix();
  
  // --- DRAW UI ---
  drawToolbar();
  if (showEditor && selectedNode != null) {
    drawEditorWindow();
  }
  
  // --- DRAW BIG EDITOR OVERLAY ---
  if (showBigEditor) {
    drawBigEditorWindow();
  }
}

int pickColor(int i) {
  // Returns a consistent color for choice index
  int[] cols = { #FFD700, #00BFFF, #FF6347, #32CD32, #DA70D6, #F0E68C };
  return cols[i % cols.length];
}

// ==========================================
// BIG EDITOR WINDOW (MODAL)
// ==========================================
void openBigEditor(TextField source) {
  sourceTextField = source;
  bigEditorField.text = source.text;
  showBigEditor = true;
  activeTextField = bigEditorField; // Focus immediately
}

void closeBigEditor(boolean save) {
  if (save && sourceTextField != null) {
    // AI-TODO 
    sourceTextField.text = bigEditorField.text;
    activeTextField = sourceTextField; 
    saveNodeFromEditor();
  } else {
    activeTextField = null;
  }
  showBigEditor = false;
}

void drawBigEditorWindow() {
  // Dimmer background
  fill(0, 0, 0, 200);
  noStroke();
  rect(0, 0, width, height);
  float w = 700;
  float h = 450;
  float x = (width - w) / 2;
  float y = (height - h) / 2;
  
  // Modal Window
  fill(50, 50, 60);
  stroke(100); strokeWeight(2);
  rect(x, y, w, h, 10);
  
  fill(255); textAlign(CENTER, TOP); textSize(20);
  text("EXPANDED TEXT EDITOR", x + w/2, y + 20);
// Text Field
  bigEditorField.x = x + 50;
  bigEditorField.y = y + 60;
  bigEditorField.w = w - 100;
  bigEditorField.h = h - 140;
  bigEditorField.draw();
  
  // Buttons
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
// WIDER to fit the new column
  float h = 600;
  float x = (width - w) / 2;
  float y = (height - h) / 2;
  
  // Shadow & Bg
  fill(0, 150); noStroke();
  rect(x+15, y+15, w, h, 12);
  fill(45, 45, 55); stroke(100); strokeWeight(1);
  rect(x, y, w, h, 10);
  
  // Header
  fill(255);
  textAlign(LEFT, TOP); textSize(20);
  text("STATION INSPECTOR", x + 25, y + 25);
  textSize(12); fill(150);
  text("ID: " + selectedNode.id, x + 25, y + 50);
  
  // Close
  btnCloseEditor.x = x + w - 40;
  btnCloseEditor.y = y + 10;
  btnCloseEditor.draw();
  
  // Main Inputs
  fill(200); textSize(12); text("NPC NAME", x+55, y+80);
// why is this one specifically off center????
  tfNpcName.x = x+25;
  tfNpcName.y = y+95;
  tfNpcName.draw();
  
  text("DIALOGUE", x+25, y+135);
  tfDialogue.x = x+25; tfDialogue.y = y+150;
  tfDialogue.draw();
  
  // Choices Headers
  text("OUTBOUND ROUTES", x+25, y+250);
  fill(150); textSize(10);
// Adjusted Header Positions
  text("TYPE", x+25, y+265);
  text("PLAYER RESPONSE", x+110, y+265);
  text("NPC REACTION", x+275, y+265); // Shifted
  text("TRUST", x+460, y+265);
  text("LINK TO ID", x+505, y+265); // NEW HEADER
  
  float startY = y + 280;
  for(int i=0; i<choiceRows.size(); i++) {
    ChoiceRow row = choiceRows.get(i);
    row.y = startY + (i * 40);
    row.x = x + 25;
    row.draw();
  }
  
  // Add Choice Button
  btnAddChoice.x = x + 25;
  btnAddChoice.y = startY + (choiceRows.size() * 40) + 10;
  btnAddChoice.draw();
// Delete Node
  if(nodes.indexOf(selectedNode) != 0) {
    btnDeleteNode.x = x + w - 140;
    btnDeleteNode.y = y + h - 45;
    btnDeleteNode.draw();
  }
}

void updateEditorFromNode() {
  if (selectedNode == null) return;
  tfNpcName.text = selectedNode.npcName;
  tfDialogue.text = selectedNode.dialogue;
  
  choiceRows.clear();
  for (Choice c : selectedNode.choices) {
    choiceRows.add(new ChoiceRow(c));
  }
}

void saveNodeFromEditor() {
  if (selectedNode == null) return;
  selectedNode.npcName = tfNpcName.text;
  selectedNode.dialogue = tfDialogue.text;
// Choices sync automatically via reference in ChoiceRow logic
}

void drawToolbar() {
  noStroke(); fill(30, 30, 40, 240);
  rect(0, 0, width, 50);
  stroke(255, 50);
  line(0, 50, width, 50);
  
  btnSave.draw();
  btnLoad.draw();
  btnReset.draw();
  btnLayout.draw();
  
  fill(150); textAlign(RIGHT, CENTER); textSize(12);
  text("Drag: Mouse | Zoom: J/K or Wheel | Edit: Click Node | Paste: Ctrl+V", width - 20, 25);
}

// ==========================================
// INTERACTION
// ==========================================

void mousePressed() {

  
  // 0. BIG EDITOR INTERACTION (Highest Priority)
  if (showBigEditor) {
    if (btnBigOk.isHover()) {
      closeBigEditor(true);
      return;
    }
    if (btnBigCancel.isHover()) {
      closeBigEditor(false);
      return;
    }
    // Check if clicked inside the big text field
    if (bigEditorField.contains(mouseX, mouseY)) {
      activeTextField = bigEditorField;
    } else {
      // Clicked outside? maybe activeTextField null?
    }
    return;
// Block all other clicks
  }
  
  // 1. UI Overlay
  if (showEditor) {
    if (btnCloseEditor.isHover()) { showEditor = false;
    activeTextField = null; return; }
    
    // Global Editor Fields -> NOW OPEN BIG EDITOR
    if (tfNpcName.contains(mouseX, mouseY)) { 
      openBigEditor(tfNpcName);
      return; 
    }
    if (tfDialogue.contains(mouseX, mouseY)) { 
      openBigEditor(tfDialogue); 
      return;
    }
    
    // Dynamic Rows (Route Fields)
    for (ChoiceRow r : choiceRows) {
      // Choice Type -> BIG EDITOR
      if (r.tfType.contains(mouseX, mouseY)) { 
        openBigEditor(r.tfType);
        return; 
      }
      // Choice Response -> BIG EDITOR
      if (r.tfResponse.contains(mouseX, mouseY)) { 
        openBigEditor(r.tfResponse);
        return; 
      }
      // NPC Reaction -> BIG EDITOR
      if (r.tfReaction.contains(mouseX, mouseY)) {
        openBigEditor(r.tfReaction);
        return;
      }
      // Trust Score -> NORMAL SMALL EDIT
      if (r.tfTrust.contains(mouseX, mouseY)) { 
        activeTextField = r.tfTrust;
        return; 
      }
      // Target ID -> BIG EDITOR (Updated)
      if (r.tfTargetId.contains(mouseX, mouseY)) {
        openBigEditor(r.tfTargetId);
        return;
      }
      
      // --- DELETE BUTTON LOGIC ---
      if (r.btnDel.isHover()) {
        // 1. Store ID of target node
        String targetId = r.refChoice.targetNodeId;
        
        // 2. Remove choice from the current node
        selectedNode.choices.remove(r.refChoice);
        
        // 3. Find and Delete the connected target node (and clean its links)
        Node targetNode = getNodeById(targetId);
        if (targetNode != null) {
          deleteNode(targetNode);
        }
        
        // 4. Update UI
        updateEditorFromNode(); 
        applyAutoLayout();
        return; 
      }
    }
    
    // Unfocus if clicked elsewhere in editor
    activeTextField = null;
    if (btnAddChoice.isHover()) {
      Node newNode = new Node(getUniqueId());
      nodes.add(newNode);
// Initialize new Choice with defaults, including Reaction
      Choice c = new Choice("Option", "Player says...", "NPC reacts...", 0, newNode.id);
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
    return;
  }
  
  // 2. Toolbar
  if (btnSave.isHover()) { selectOutput("Export JSON", "fileSelectedSave"); return;
  }
  if (btnLoad.isHover()) { selectInput("Import JSON", "fileSelectedLoad"); return; }
  if (btnReset.isHover()) { createRootNode(); return;
  }
  if (btnLayout.isHover()) { applyAutoLayout(); return; }

  // 3. World Interaction
  float mx = (mouseX - camX) / camZoom;
  float my = (mouseY - camY) / camZoom;
  
  // Node Clicking
  for (int i = nodes.size()-1; i >= 0; i--) {
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
  
  // Panning
  if (!showEditor) {
    isDraggingMap = true;
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseDragged() {
  if (showEditor || showBigEditor) return;
  if (isDraggingMap) {
    camX += (mouseX - lastMouseX);
    camY += (mouseY - lastMouseY);
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  } 
}

void mouseReleased() { isDraggingMap = false; }

void mouseWheel(MouseEvent event) {
  if (showEditor || showBigEditor) return;
  float e = event.getCount();
  if (e < 0) camZoom *= 1.1; else camZoom *= 0.9;
  camZoom = constrain(camZoom, 0.1, 5.0);
}

void keyPressed() {
  // Input Typing
  if (activeTextField != null && (showEditor || showBigEditor)) {
    activeTextField.handleKey(key, keyCode);
// If we are NOT in big editor, save immediately.
// If we ARE in big editor, we wait for "OK" button.
    if (!showBigEditor) {
      saveNodeFromEditor();
    }
    return;
  }
  
  // Camera Hotkeys
  if ((!showEditor && !showBigEditor) || activeTextField == null) {
    if (key == 'k' || key == 'K') camZoom = constrain(camZoom * 1.1, 0.1, 5.0);
    if (key == 'j' || key == 'J') camZoom = constrain(camZoom * 0.9, 0.1, 5.0);
  }
}

// ==========================================
// DATA LOGIC
// ==========================================

void deleteNode(Node n) {
    for(Node other : nodes) {
        for(int i = other.choices.size() - 1; i >= 0; i--) {
            if(other.choices.get(i).targetNodeId.equals(n.id)) other.choices.remove(i);
        }
    }
    nodes.remove(n);
}

Node getNodeById(String id) {
  for(Node n : nodes) if (n.id.equals(id)) return n;
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
  JSONArray nodesArr = new JSONArray();
  for (int i = 0; i < nodes.size(); i++) nodesArr.setJSONObject(i, nodes.get(i).toJSON());
  json.setJSONArray("nodes", nodesArr);
  saveJSONObject(json, path);
  println("Saved to " + path);
}

void loadData(String path) {
  try {
    JSONObject json = loadJSONObject(path);
    JSONArray nodesArr = json.getJSONArray("nodes");
    nodes.clear();
    for (int i = 0; i < nodesArr.size(); i++) {
      JSONObject nObj = nodesArr.getJSONObject(i);
      Node n = new Node(nObj.getString("id"));
      n.npcName = nObj.getString("npcName");
      n.dialogue = nObj.getString("dialogue");
      if (nObj.hasKey("color")) n.nodeColor = nObj.getInt("color");
      
      JSONArray choicesArr = nObj.getJSONArray("choices");
      for (int j = 0; j < choicesArr.size(); j++) {
        JSONObject cObj = choicesArr.getJSONObject(j);
// Handle New "type" vs Old "text" field
        String cType = "Option";
        if (cObj.hasKey("type")) cType = cObj.getString("type");
        else if (cObj.hasKey("text")) cType = cObj.getString("text");
// Handle Response Text
        String cResponse = "";
        if (cObj.hasKey("response")) cResponse = cObj.getString("response");
// Handle NPC Reaction (NEW)
        String cReaction = "";
        if (cObj.hasKey("reaction")) cReaction = cObj.getString("reaction");
        
        Choice c = new Choice(cType, cResponse, cReaction, cObj.getInt("trust"), cObj.getString("targetId"));
        n.choices.add(c);
      }
      nodes.add(n);
    }
    applyAutoLayout();
    camX = width/2; camY = height/2;
// Center view on load
  } catch (Exception e) {
    println("Error loading: " + e.getMessage());
  }
}

// ==========================================
// CLASSES
// ==========================================

class Node {
  String id;
  float x = 0, y = 0;
  float r = 25;
  String npcName = "NPC";
  String dialogue = "";
  int nodeColor;
  ArrayList<Choice> choices = new ArrayList<Choice>();
  Node(String id) {
    this.id = id;
  int[] cols = { #FFD700, #00BFFF, #FF6347, #32CD32, #DA70D6, #F0E68C };
  this.nodeColor = color(cols[(int)(Math.floor(random(cols.length)))]);

    colorMode(RGB, 255);
  }
  
  void draw() {
    strokeWeight(4);
    stroke(255);
    fill(nodeColor);
    ellipse(x, y, r*2, r*2);
    
    // Label
    fill(255); textAlign(CENTER, BOTTOM); textSize(14);
    fill(0, 180);
    text(npcName, x+2, y - r - 8); // shadow
    fill(255); text(npcName, x, y - r - 10);
// Snippet
    String snippet = dialogue.length() > 15 ? dialogue.substring(0, 15)+"..." : dialogue;
    textSize(10); 
    fill(0,180);
    text(snippet, x+2, y + r + 15+2); // shadow
    fill(200);
    text(snippet, x, y + r + 15);
  }
  
  JSONObject toJSON() {
    JSONObject obj = new JSONObject();
    obj.setString("id", id);
    obj.setFloat("x", x);
    obj.setFloat("y", y);
    obj.setString("npcName", npcName);
    obj.setString("dialogue", dialogue);
    obj.setInt("color", nodeColor);
    
    JSONArray cArr = new JSONArray();
    for(int i=0; i<choices.size(); i++) {
      JSONObject cObj = new JSONObject();
      Choice c = choices.get(i);
      cObj.setString("type", c.type); 
      cObj.setString("response", c.responseText);
      cObj.setString("reaction", c.npcReaction); // SAVE REACTION
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
// The label shown on the graph connection
  String responseText; // The actual player text
  String npcReaction;
// NEW: The NPC's immediate reaction text
  int trustScore;
  String targetNodeId;
  Choice(String type, String responseText, String reaction, int trust, String id) { 
    this.type = type;
    this.responseText = responseText;
    this.npcReaction = reaction;
    this.trustScore = trust; 
    this.targetNodeId = id;
  }
}

// --- UI COMPONENTS ---

class Button {
  float x, y, w, h;
  String label;
  Button(float x, float y, float w, float h, String label) { this.x=x; this.y=y; this.w=w; this.h=h; this.label=label;
  }
  void draw() {
    boolean hover = isHover();
    fill(hover ? color(80, 140, 220) : color(60));
    stroke(0);
    strokeWeight(1);
    rect(x, y, w, h, 5);
    fill(255); textAlign(CENTER, CENTER); textSize(12);
    text(label, x + w/2, y + h/2);
  }
  boolean isHover() { return mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h;
  }
}

class TextField {
  float x, y, w, h;
  String text = "";
  String placeholder;
  TextField(float x, float y, float w, float h, String placeholder) {
    this.x=x; this.y=y; this.w=w; this.h=h;
    this.placeholder = placeholder;
  }
  
  void draw() {
    boolean active = (activeTextField == this);
    fill(30);
    if(active) stroke(0, 200, 255); else stroke(80);
    strokeWeight(active ? 2 : 1);
    rect(x, y, w, h, 4);
    
    fill(255); textAlign(LEFT, TOP); textSize(14);
    if (text.length() == 0 && !active) {
      fill(100);
      text(placeholder, x + 5, y + 5, w-10, h-10);
    } else {
      fill(255);
// Blinking cursor
      String display = text + (active && frameCount % 60 < 30 ? "|" : "");
      text(display, x + 5, y + 5, w-10, h-10);
    }
  }
  
  boolean contains(float mx, float my) { return mx >= x && mx <= x+w && my >= y && my <= y+h;
  }
  
  void handleKey(char k, int code) {
    if (k == BACKSPACE) {
      if (text.length() > 0) text = text.substring(0, text.length()-1);
    } 
    else if (code == 86 && (key == 22 || isCtrlDown())) { 
      // PASTE (Ctrl+V)
      pasteFromClipboard();
    }
    else if (k >= ' ' && k <= '~') {
      text += k;
    }
  }
  
  boolean isCtrlDown() {
    // Cross-platform control check
    return (keyPressed && (key == CODED || key == 22));
  }

  void pasteFromClipboard() {
    try {
      Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      Transferable content = clipboard.getContents(null);
      if (content != null && content.isDataFlavorSupported(DataFlavor.stringFlavor)) {
        String str = (String) content.getTransferData(DataFlavor.stringFlavor);
        text += str;
      }
    } catch (Exception e) {
      println("Paste failed: " + e);
    }
  }
}

class ChoiceRow {
  Choice refChoice;
  TextField tfType;
  TextField tfResponse;
  TextField tfReaction; 
  TextField tfTrust;
  TextField tfTargetId; // NEW
  Button btnDel;
  float x, y;
  ChoiceRow(Choice c) {
    this.refChoice = c;
// 1. Type (Short)
    tfType = new TextField(0,0, 80, 30, "Type");
    tfType.text = c.type;
// 2. Response (Medium) 
    tfResponse = new TextField(0,0, 160, 30, "Response");
    tfResponse.text = c.responseText;

    // 3. Reaction (Medium) 
    tfReaction = new TextField(0,0, 180, 30, "NPC Reaction");
    tfReaction.text = c.npcReaction;

    // 4. Trust (Tiny)
    tfTrust = new TextField(0,0, 40, 30, "0");
    tfTrust.text = str(c.trustScore);
    
    // 5. Target ID (Small) - NEW
    tfTargetId = new TextField(0,0, 80, 30, "LinkID");
    tfTargetId.text = c.targetNodeId;
    
    btnDel = new Button(0,0, 30, 30, "X");
  }
  
  void draw() {
    // Layout
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
    
// Logic: Sync UI <-> Data
    
    // Type Field
    if (activeTextField != tfType) tfType.text = refChoice.type;
    else refChoice.type = tfType.text; 
    tfType.draw();
    
    // Response Field
    if (activeTextField != tfResponse) tfResponse.text = refChoice.responseText;
    else refChoice.responseText = tfResponse.text;
    tfResponse.draw();
    
    // Reaction Field 
    if (activeTextField != tfReaction) tfReaction.text = refChoice.npcReaction;
    else refChoice.npcReaction = tfReaction.text;
    tfReaction.draw();
    
    // Trust Field
    if (activeTextField != tfTrust) tfTrust.text = str(refChoice.trustScore);
    else {
      try { refChoice.trustScore = Integer.parseInt(tfTrust.text.trim());
      } catch(Exception e){}
    }
    tfTrust.draw();
    
    // Target ID Field (NEW)
    if (activeTextField != tfTargetId) tfTargetId.text = refChoice.targetNodeId;
    else refChoice.targetNodeId = tfTargetId.text;
    tfTargetId.draw();
    
    btnDel.draw();
  }
}
