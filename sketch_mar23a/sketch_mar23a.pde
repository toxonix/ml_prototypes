/**
 * visualization of hotel locations
 * 
 */

String[] lines;
int index = 0;
ArrayList hotels;


void setup() {
  size(640, 360, P3D);
  noStroke();
  lines = loadStrings("chicago_readinggroup.csv");
  
  if (index < lines.length) {
    String[] pieces = split(lines[index], ':');
    float lat = abs(float(pieces[14]));
    float lon = abs(float(pieces[15]));
    hotels.add(new Hotel(new PVector(lat, lon)));
    // Go to the next line for the next run through draw()
    index = index + 1;
  }
}

void draw() {
  background(50);
  lights();
  
  // Center
  translate(width/2, height/2, -130);
  
 for(int i=0;i<hotels.size(); i++){
   pushMatrix();
   noStroke();
    hotels.get(i).create();
    popMatrix();
 }
}
