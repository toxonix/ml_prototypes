ArrayList cubes = new ArrayList();
String[] lines;
float minX=1000, minY= 1000, maxX=0, maxY=0;

void setup() {
  size(1400, 1400);
  noStroke();
  
  lines = loadStrings("chicago_readinggroup.csv");

  for (int i=1; i<lines.length; i++) {
    String[] pieces = split(lines[i], ':');
    float x = abs(float(pieces[14]));
    minX = min(x, minX);
    maxX = max(x, maxX);
    float y = abs(float(pieces[15]));
    minY = min(y, minY);
    maxY = max(y, maxY);
    cubes.add(new PVector(x,y));
  }
  float maxCoord = (width) + max(maxX, maxY);
  
  for(int i=0;i<cubes.size();i++){
    PVector v = (PVector)cubes.get(i);
    PVector scaled = new PVector((v.x-minX) * maxCoord, (v.y-minY) * maxCoord);
    println("scaled vector:"+scaled);
    cubes.set(i, scaled);
  }
  
  println("maxCoord "+maxCoord);
  println("minX,maxX: "+minX+", "+minY);
  println("maxX, maxY: "+maxX+", "+maxY);
}

float zoom = 1.0;
float xOffset = 0.0;
float yOffset = 0.0;

void draw(){
  background(0);
  stroke(100);
  scale(zoom);
  translate(xOffset, yOffset);
  for(int i=0;i<cubes.size();i++){
    fill(255);
    PVector p = (PVector)cubes.get(i);
    point (p.x , p.y);
  }
}

void keyPressed(){
  if(key == 'z'){ zoom+=0.10; }
  if(key == 'x'){ zoom-=0.10; }
  if(key == 'w') { yOffset += 10;}
  if(key == 's') { yOffset -= 10; }
  if(key == 'q') { xOffset += 10.0;}
  if(key == 'e') { xOffset -= 10.0;}
  if(key == 'r'){ 
    zoom = 1.0;
    xOffset = 0.0;
    yOffset = 0.0;
  }
  println("new zoom level:"+zoom);
  println("pan"+xOffset+", "+yOffset);
}
