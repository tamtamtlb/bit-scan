Button selectImage;
Button startScan;
PFont mono;

color black = color(0, 0, 0);
color white = color(256, 256, 256);

PImage img;
int imgSize = 400;
float imgRotation = 0;

int state = 0;

int startFrame;
int waitSeconds = 2;

int framerate = 60;
float speed = 0.8;
int laserWidth = 15;
int scannerPos = -laserWidth;

ArrayList<int[]> frames = new ArrayList<int[]>();

int[] result;

void setup() {
  size(420, 594); // a4 size, similar to scanner
  frameRate(framerate);
  background(black);
  mono = createFont("Monospaced", 24);
  textFont(mono);
  selectImage = new Button("select image", 24, mono, 50, 100, width - 100, 50, black, white, white, white, black, white, true);
  startScan = new Button("start scan", 24, mono, 50, 100 + 50 + 25, width - 100, 50, black, white, white, white, black, white, false);
}

void restart(){
  result = null;
  frames = new ArrayList<int[]>();
  scannerPos = -laserWidth; // <-- Add this to reset the laser!
  state = 0;
  selectImage.clickable = true;
}

void draw(){
  switch (state){
    case 0:
      drawStart();
      break;
    case 1: 
      drawWaiting();
      break;
    case 2:
      drawScan();
      break;
    case 3:
      drawResult(frames);
      break;
    default:
      state = 0;
  }
}

void drawImg(PImage img){
  drawImg(img, 0, 1);
}

void drawImg(PImage img, float transparency, int size){
  tint(255, 255 * (1 - transparency));
  float ratio = (float) img.height / img.width;
  
  float drawWidth = size;
  float drawHeight = size * ratio;

  pushMatrix();
  translate(mouseX, mouseY);
  rotate(PI * imgRotation);
  image(img, -drawWidth / 2, -drawHeight / 2, drawWidth, drawHeight);
  popMatrix();
}

void drawStart(){
  background(0, 0, 0);
  selectImage.draw();
  fill(white);
  if (img == null){
    startScan.clickable = false;
    return;
  }
  startScan.clickable = true;
  startScan.draw();
  drawImg(img, 0.5, imgSize);
  fill(white);
  text("press '.' or ',' to resize image \n press 'A' or 'S' to rotate", 50, 200, width - 100, height - 100);
}

void drawWaiting(){
  background(black);
  text("press SPACE to start scanning", 50, 200, width - 100, height - 100);
  drawImg(img, 0, imgSize);
  
}

void drawScan(){
  if (scannerPos > height){
    state = 3;
    drawResult(frames);
    return;
  }
  background(black);
  drawImg(img, 0, imgSize);
  loadPixels();
  frames.add(pixels.clone());
  scannerPos += (height / (float)framerate) * speed * 0.35;
  drawScannerLight(0, scannerPos, width, laserWidth);
  noStroke();
  
}

void drawResult(final ArrayList<int[]> frames){
  if (result != null){
    loadPixels();
    arrayCopy(result, 0, pixels, 0, pixels.length); 
    updatePixels();
    fill(black);
    rect(50, 400, width - 100, 150);
    fill(white);
    textSize(20);
    text("press ENTER to save image and restart scan. \n press DELETE or BACKSPACE to restart without saving", 50, 400, width - 100, 150);
    return;
  }
  int n = frames.size();
  if (n == 0) return;
  int size = frames.get(0).length;
  result = new int[size];
  int _part = size / n;
  int buf = size % n;
  int pos = 0;
  
  for (int i = 0; i < n; i++) {
    int part = _part;
    if (buf > 0) {
      buf--;
      part++;
    }
    arrayCopy(frames.get(i), pos, result, pos, part); 
    pos += part;
  }
  
  loadPixels();
  arrayCopy(result, 0, pixels, 0, pixels.length); 
  updatePixels();
}

void saveResult() {
  // Syntax: selectOutput(Prompt Message, Callback Function Name);
  selectOutput("Choose where to save your scan:", "fileSaved");
}

// This callback function runs automatically after the user clicks "Save" or "Cancel"
void fileSaved(File selection) {
  if (selection == null) {
    println("Save canceled by the user.");
  } else {
    String savePath = selection.getAbsolutePath();

    String pathLower = savePath.toLowerCase();
    if (!pathLower.endsWith(".tif") && !pathLower.endsWith(".png") && !pathLower.endsWith(".jpg")) {
      savePath += ".tif"; 
    }
    loadPixels();
    arrayCopy(result, 0, pixels, 0, pixels.length); 
    updatePixels();
    
    // Save to the exact path the user chose
    save(savePath);
    println("Saved successfully to: " + savePath);
    restart();
  }
}

void mousePressed(){
  if (selectImage.hover()){
    selectInput("Select an image to process:", "fileSelected");
  } if (startScan.hover()){
    selectImage.clickable = false;
    startScan.clickable = false;
    state = 1;
  }
}

void keyPressed(){
  if (key == 'a'){
    imgRotation += 0.025;
    println("rotate");
  }
  if (key == 's'){
    imgRotation -= 0.025;
  }
  if (state == 0){
    if (key == ','){
      imgSize+=5;
    } else if (key == '.'){
      imgSize-=5;
    }
  }
  else if (state == 1){
    if (key == ' '){
      state = 2;
    }
  } else if (state == 3){
    if (key == ENTER || key == RETURN){
      saveResult(); // Open the dialog exactly ONCE here!
    } 
    if (key == DELETE || key == BACKSPACE){
      restart();
    }
  }
}

class Button{
  String text;
  PFont font;
  int textSize, x, y, w, h;
  color textColor, fillColor, strokeColor, 
        hoverTextColor, hoverFillColor, hoverStrokeColor;
  boolean clickable = true;
  
  public Button(String text, int textSize, PFont font, 
                int x, int y, int w, int h, 
                color textColor, color fillColor, color strokeColor,
                color hTextColor, color hFillColor, color hStrokeColor,
                boolean clickable){
    this.text = text;
    this.textSize = textSize;
    this.font = font;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.textColor = textColor;
    this.fillColor = fillColor;
    this.strokeColor = strokeColor;
    this.hoverTextColor = hTextColor;
    this.hoverFillColor = hFillColor;
    this.hoverStrokeColor = hStrokeColor;
    this.clickable = clickable;
  }
  
  void draw(){
    if (!clickable) return;
    color fc, sc, tc;
    if (!hover()){
      fc = fillColor;
      sc = strokeColor;
      tc = textColor;
    } else {
      fc = hoverFillColor;
      sc = hoverStrokeColor; 
      tc = hoverTextColor;
    }
    fill(fc);
    stroke(sc);
    rect(x, y, w, h);
    
    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(textSize);
    fill(tc);
    text(text, x, y, w, h);
  }
  
  boolean hover(){
    if (mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h && clickable) return true;
    return false;
  }
}

// This function runs automatically after the user picks a file
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    
    // 1. Load the image into a TEMPORARY variable first
    PImage tempImg = loadImage(selection.getAbsolutePath());
    
    // 2. Check to make sure the user actually picked a valid image file
    // (If they picked a .txt file, loadImage returns null)
    if (tempImg != null) {
      
      // 3. Do your resizing on the temporary image
      tempImg.resize(imgSize, 0);
      
      // 4. Finally, hand it over to the main draw loop all at once
      img = tempImg; 
      
    } else {
      println("Error: The selected file is not a valid image.");
    }
  }
}

// --- Custom Function for the Gradient Light ---
void drawScannerLight(float x, float y, float w, float h) {
  // Define our colors (R, G, B, Alpha/Transparency)
  color edgeColor = color(0, 255, 150, 0);      // Transparent green
  color centerColor = color(200, 255, 220, 255); // Bright, solid greenish-white center
  
  float middleY = y + (h / 2);
  
  // Top half of the laser (fades from transparent to bright center)
  beginShape(QUADS);
  fill(edgeColor);
  vertex(x, y);                 // Top-left
  vertex(x + w, y);             // Top-right
  
  fill(centerColor);
  vertex(x + w, middleY);       // Bottom-right
  vertex(x, middleY);           // Bottom-left
  endShape();
  
  // Bottom half of the laser (fades from bright center back to transparent)
  beginShape(QUADS);
  fill(centerColor);
  vertex(x, middleY);           // Top-left
  vertex(x + w, middleY);       // Top-right
  
  fill(edgeColor);
  vertex(x + w, y + h);         // Bottom-right
  vertex(x, y + h);             // Bottom-left
  endShape();
}
