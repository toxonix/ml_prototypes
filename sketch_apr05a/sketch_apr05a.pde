import shapes3d.utils.*;
import shapes3d.*;

String[] lines;

Ellipsoid earth;
ArrayList airports = new ArrayList();
int R = 160; //big R! the radius of the earth


void setup(){
  size(800,600, P3D);
  // Create the earth
  colorMode(RGB, 1.0);
  earth = new Ellipsoid(this, 20 ,30);
  earth.setTexture("world_gmt2.png");
  earth.setRadius(R);
  earth.fill(0);
  earth.moveTo(new PVector(0,0,0));


  earth.drawMode(Shape3D.SOLID);
  
  lines = loadStrings("world_airports.csv");

  for(int i=0;i<lines.length; i++){
    float lat,lon;
    String[] pieces = split(lines[i], ",");
    Airport ap = new Airport();
    ap.iataCode = pieces[0];
    ap.name = pieces[1];
    ap.country = pieces[3];
    ap.countryCode = pieces[4];
    ap.lat = float(pieces[5]);
    ap.lon = float(pieces[6]);
    ap.elevation = float(pieces[7]);
    AirportBox b = new AirportBox(this, ap, 1);
    PVector p = sphericalToCartesian(radians(ap.lat), radians(ap.lon),ap.elevation);
    b.moveTo(p.x, p.y, p.z);
    b.airport = ap;
    earth.addShape(b);
  }
  frameRate(35);
}

PVector geoToCartesian(PVector geo){
  PVector geoToC = sphericalToCylindrical(geo);
  return cylindricalToCartesian(geoToC);
}

PVector cylindricalToCartesian(PVector c){
  float x= c.x * cos(c.y);
  float y= c.x * sin(c.y);
  float z=c.z;
  return new PVector(c.x * cos(c.y), c.x*sin(c.y), c.z);
}

PVector sphericalToCylindrical(PVector vec){
  float r = vec.x * sin(vec.y);
  float o = vec.z;
  float h = vec.x * cos(vec.y);
  return new PVector(r, o, h);
}

// NOTE: lat and lon are assumed to be radians
PVector sphericalToCartesian(float lat, float lon, float elevation){
  float x= R * cos(lat) * cos(lon);
  float y= R * cos(lat) * sin(lon);
  float z= R * sin(-lat);//processing is inside out
  return new PVector(x, y, z);
}

//a boxy airport.
class AirportBox extends Box{
  AirportBox(PApplet p, Airport a, int s){
    super(p,s);
    airport = a;
  }
  Airport airport;
}

class Airport {
  String name,country,countryCode,iataCode;
  float lat,lon,elevation;
}

void draw(){
  if(autoRotate){
    earth.rotateBy(0, radians(0.6), 0);
  }
  background(0.02);
  pushMatrix();
  camera(0, -190, 350, 0, 0, 0, 0, 1, 0);
  ambientLight(80,80,80);
  directionalLight(255, 255, 255, -150, 150, -80);
  
  earth.draw();

  // Reset the lights
  noLights();
  ambientLight(180,180,180);
  popMatrix();
}

void mouseDragged(){
    earth.rotateBy(radians(0.2 * (pmouseY - mouseY)), radians( 0.2 * (pmouseX - mouseX)), 0);
}

boolean autoRotate = true;
void keyPressed(){
  if(key == 'r'){
    autoRotate = !(autoRotate);
    println("rotate:"+autoRotate);
  }
}
