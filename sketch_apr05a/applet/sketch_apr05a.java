import processing.core.*; 
import processing.xml.*; 

import shapes3d.utils.*; 
import shapes3d.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class sketch_apr05a extends PApplet {




String[] lines;

Ellipsoid earth;
ArrayList airports = new ArrayList();
int R = 160; //big R! the radius of the earth


public void setup(){
  size(800,600, P3D);
  // Create the earth
  colorMode(RGB, 1.0f);
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
    ap.lat = PApplet.parseFloat(pieces[5]);
    ap.lon = PApplet.parseFloat(pieces[6]);
    ap.elevation = PApplet.parseFloat(pieces[7]);
    AirportBox b = new AirportBox(this, ap, 1);
    PVector p = sphericalToCartesian(radians(ap.lat), radians(ap.lon),ap.elevation);
    b.moveTo(p.x, p.y, p.z);
    b.airport = ap;
    earth.addShape(b);
  }
  frameRate(35);
}

public PVector geoToCartesian(PVector geo){
  PVector geoToC = sphericalToCylindrical(geo);
  return cylindricalToCartesian(geoToC);
}

public PVector cylindricalToCartesian(PVector c){
  float x= c.x * cos(c.y);
  float y= c.x * sin(c.y);
  float z=c.z;
  return new PVector(c.x * cos(c.y), c.x*sin(c.y), c.z);
}

public PVector sphericalToCylindrical(PVector vec){
  float r = vec.x * sin(vec.y);
  float o = vec.z;
  float h = vec.x * cos(vec.y);
  return new PVector(r, o, h);
}

// NOTE: lat and lon are assumed to be radians
public PVector sphericalToCartesian(float lat, float lon, float elevation){
  float x= R * cos(lat) * cos(lon);
  float y= R * cos(lat) * sin(lon);
  float z= R * sin(-lat);
  return new PVector(x, y, z);
}

/*
   x = radius_of_world * cos(longitude) * sin(90 - latitude)
   y = radius_of_world * sin(longitude) * sin(90 - latitude)
   z = radius_of_world * cos(90 - latitude)
** */

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

public void draw(){
  // Change the rotations before drawing
  stroke(1, 0,0);
  line(0,0,0, 1000,0,0);
  stroke(0,1,0);
  line(0,0,0, 0,1000,0);
  stroke(0,0,1);
  line(0,0,0, 0,0,1000);

  if(mousePressed){
    earth.rotateBy(radians(0.5f * (pmouseY - mouseY)), radians( 0.5f * (mouseX - pmouseX)), 0);
  }

  background(0.02f);
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
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#DFDFDF", "sketch_apr05a" });
  }
}
