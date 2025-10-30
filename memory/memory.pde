// memoryCanvas Fragile Memory w/ Revival and Morph
//  sketch allows you to draw strokes that gradually distort/morph over time.
// r to create revival and c to clear the canvas

ArrayList<MemoryStroke> strokes; // stores all drawn strokes
MemoryStroke currentStroke;      // stroke currently being drawn
PGraphics buffer;                // graphics buffer for smooth blending

void setup() {
  size(900, 700);
  strokes = new ArrayList<MemoryStroke>();
  buffer = createGraphics(width, height);
  colorMode(HSB, 360, 100, 100, 100);
  background(0);
}

void draw() {
  buffer.beginDraw();
  buffer.noStroke();
  buffer.fill(0, 0, 0, 8); // soft fade background to create cloudlike blending
  buffer.rect(0, 0, width, height);

  float currentTime = millis() / 1000.0; // time in seconds

  // Display all strokes
  for (MemoryStroke s : strokes) {
    s.display(buffer, currentTime);
  }

  buffer.endDraw();
  image(buffer, 0, 0); // draw buffer onto main canvas
}

// -----------------------
// Mouse interactions
// -----------------------
void mousePressed() {
  //  new stroke with random color and thickness
  currentStroke = new MemoryStroke(
    color(random(360), 80, 100),
    random(8, 18)
  );
  currentStroke.addPoint(mouseX, mouseY); // add first point
}

void mouseDragged() {
  // add points to the current stroke while dragging
  if (currentStroke != null) currentStroke.addPoint(mouseX, mouseY);
}

void mouseReleased() {
  
  if (currentStroke != null) {
    currentStroke.startTime = millis() / 1000.0;
    strokes.add(currentStroke);
    currentStroke = null;
  }
}

// -----------------------
// keyboard interactions
// -----------------------
void keyPressed() {
  if (key == 'r' || key == 'R') {
    // Softly revive all strokes when 'R' is pressed
    for (MemoryStroke s : strokes) {
      s.revive();
    }
  } else if (key == 'c' || key == 'C') {
    // strokes are cleared when you press c 
    strokes.clear();
    buffer.beginDraw();
    buffer.background(0);
    buffer.endDraw();
  }
}

// -----------------------
// memorystroke class
// -----------------------
class MemoryStroke {
  ArrayList<PVector> points;        
  ArrayList<PVector> originalPoints; // original positions at drawing
  color c;                           // stroke color
  float thickness;                   // stroke thickness
  float startTime;                   // stroke  time
  float lifeSpan;                    // how long until fade
  float driftX, driftY;              

  boolean revived = false;           
  float reviveFactor = 0;            

  MemoryStroke(color c, float thickness) {
    points = new ArrayList<PVector>();
    originalPoints = new ArrayList<PVector>();
    this.c = c;
    this.thickness = thickness;
    this.lifeSpan = 14; // alpha fades over ~14 seconds
    driftX = random(-0.3, 0.3); // small random drift
    driftY = random(-0.3, 0.3);
  }

  // add a new point to the stroke
  void addPoint(float x, float y) {
    PVector p = new PVector(x, y);
    points.add(p.copy());         // store current point
    originalPoints.add(p.copy()); // store original point for revival
  }

  // display stroke 
  void display(PGraphics pg, float currentTime) {
    float age = currentTime - startTime;
    float alpha = computeAlpha(age, lifeSpan);

    // soft revival gradually blend points toward original
    if (revived) {
      reviveFactor = lerp(reviveFactor, 0.6, 0.05); // 
      if (reviveFactor < 0.01) revived = false;    // 
    } else {
      reviveFactor *= 0.95; // 
    }

    pg.strokeWeight(thickness);

    // draw cloudlike movements
    for (int i = 1; i < points.size(); i++) {
      PVector p1 = warpPoint(points.get(i-1), originalPoints.get(i-1), age);
      PVector p2 = warpPoint(points.get(i), originalPoints.get(i), age);

      pg.stroke(hue(c), saturation(c), brightness(c), alpha*100);
      pg.line(p1.x, p1.y, p2.x, p2.y);

      // draw for soft morphing effect
      pg.noStroke();
      pg.fill(hue(c), saturation(c)*0.8, brightness(c), alpha*60);
      pg.ellipse(p1.x, p1.y, thickness*1.5, thickness*1.5);
      pg.ellipse(p2.x, p2.y, thickness*1.5, thickness*1.5);
    }
  }

  // Compute fading alpha based on age
  float computeAlpha(float age, float lifeSpan) {
    float t = constrain(age / lifeSpan, 0, 1);
    return 1 - pow(t, 1.3); // fades nonlinearly
  }

  // revival
  void revive() {
    revived = true; // smooth revival
  }

  // 
  PVector warpPoint(PVector p, PVector original, float age) {
    float t = constrain(age / lifeSpan, 0, 1);

    // add a drifttt
    p.x += driftX + random(-0.3, 0.3);
    p.y += driftY + random(-0.3, 0.3);

    //  distortion for morphing
    float ns = 0.01;
    float dx = map(noise(p.x*ns, p.y*ns, millis()*0.0005), 0, 1, -20, 20);
    float dy = map(noise(p.y*ns, p.x*ns, millis()*0.0005+100), 0, 1, -20, 20);

    PVector warped = new PVector(p.x + dx*t*2, p.y + dy*t*2);

    // blend toward original if revived innit
    if (reviveFactor > 0) {
      warped.x = lerp(warped.x, original.x, reviveFactor);
      warped.y = lerp(warped.y, original.y, reviveFactor);
    }

    return warped;
  }
}
