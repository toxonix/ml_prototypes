/**
 * visualization of hotel locations
 * 
 */

String[] lines;
ArrayList cubes = new ArrayList();
boolean connect = false;

float scaler = 1;
float explode = 1;

void setup() {
  size(640, 480, P3D);
  noStroke();
  lines = loadStrings("chicago_readinggroup.csv");
  println("lines:"+lines.length); 
  for (int i=1; i<lines.length; i++) {
    String[] pieces = split(lines[i], ':');
    float lat = norm(float(pieces[14]),40, 42) * 10;
    float lon = norm(float(pieces[15]), -80, -82) * 10;
    println("xy"+lat+", "+lon);
    cubes.add(new PVector(lat,0,lon));
  }
}



void draw() {
  background(200);
  lights();
 
  noStroke();
  
 
  for(int i=0;i<cubes.size(); i++){
   PVector p = (PVector)cubes.get(i);
   fill(0);
   // Draw cube
   pushMatrix();
   translate(p.x, p.x, p.z);
   
   box(4);
   popMatrix();
   if(connect){
     if(i<cubes.size()-1){
       //draw a line connecting the cubes
       PVector n = (PVector) cubes.get(i+1);
       fill(25);
       stroke(25);
       line(p.x, p.y, p.z, n.x, n.y, n.z);
     }
   }
 }
}





