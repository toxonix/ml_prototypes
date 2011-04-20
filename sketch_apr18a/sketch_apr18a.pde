import processing.opengl.PGraphicsOpenGL;
import javax.media.opengl.GL;
import javax.media.opengl.glu.GLU;
import javax.media.opengl.glu.GLUquadric;
import com.sun.opengl.util.texture.Texture;
import com.sun.opengl.util.texture.TextureIO;
import peasy.PeasyCam;  //magic hidden camera controls
import java.io.*;

PGraphicsOpenGL pgl;
GL gl;
GLU glu;
GLUquadric mysphere;
Texture earth;
PeasyCam cam;
float r = 2048/PI; 
float rotateearth = 0;
int frameCounter = 0;
PFont courierNews;
Timer clock = new Timer(100);
int currentHour = -1;
File data;


void setup() {
  size(800, 600, OPENGL );
  pgl = (PGraphicsOpenGL) g;  
  gl = pgl.gl;  
  glu = pgl.glu;

  PFont font = loadFont("Courier10PitchBT-Roman-9.vlw");
  textFont(font);

  mysphere = glu.gluNewQuadric();
  glu.gluQuadricDrawStyle(mysphere, glu.GLU_FILL);
  glu.gluQuadricNormals(mysphere, glu.GLU_NONE);
  glu.gluQuadricTexture(mysphere, true);
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*32.0);
  cam = new PeasyCam(this, width);
  cam.setResetOnDoubleClick(false);
  cam.setMinimumDistance(width/14);
  cam.setMaximumDistance(width*10);
  cam.rotateZ(radians(-90));
  cam.rotateX(radians(105));

  try {    
    earth = TextureIO.newTexture(new File(dataPath("srtm_ramp2.world.5400x2700.jpg")), true);
  }  
  catch (IOException e) {        
    javax.swing.JOptionPane.showMessageDialog(this, e);
  }
  frameRate(1000);
}

class Info{
  PVector p;
  int m,h,s;//time
}

String [] lines;
java.util.LinkedList displayList = new java.util.LinkedList();

class LogWorker implements Runnable{
  String file;
  Timer time;
  LogWorker(String file, Timer t){
    this.time=t;
    this.file=file;
  }

  void run(){
    String[] lines;
    lines = loadStrings(file);
    java.util.LinkedList ll = new java.util.LinkedList();
    for(int i=0;i<lines.length;i++){
      String [] line = split(lines[i]," ");
      Info info = new Info();
      String[] time = split(line[0],":");
      info.h=int(time[0]);
      info.m=int(time[1]);
      info.s=int(time[2]);
      info.p = sphericalToCartesian(float(line[2]),float(line[1]), 0);
      ll.add(info);
    }

    
    Info info;
    while((info = (Info)ll.peek()) != null){
      if(time.h >= info.h &&time.m >= info.m && time.s >= info.s){
        displayList.add(info);
        ll.poll();
      }else{
        delay(100);
      }
    }

    //pray for speedy garbage collection
    ll=null;
    lines=null;
  }
}

String zeroPad(int i){
  if (i < 10){
    return "0"+i;
  }
  return String.valueOf(i);
}

java.util.LinkedList locations = new java.util.LinkedList();

void draw() {
  background(0);
  if(clock.getHours() > currentHour){
    currentHour++;
    //load log segment
    new Thread(new LogWorker("hour"+zeroPad(currentHour)+".dat", clock)).start();
  }

  if(!displayList.isEmpty()){
    locations.add(displayList.poll());
  }

  stroke(100);
  Iterator iter = locations.iterator();
  while(iter.hasNext()){
    Info i = (Info) iter.next();
    point(i.p.x, i.p.y, i.p.z);
  }
  
  pgl.beginGL();
  gl.glPushMatrix();
  gl.glRotatef(degrees(rotateearth),0.0,0.0,1.0);
  gl.glColor3f(1,1,1);
  earth.enable();
  earth.bind();
 
  glu.gluSphere(mysphere, r, 40, 40);
  earth.disable();
  gl.glPopMatrix();
  pgl.endGL();
  if (autorotate) {
    if(rotateearth < 360){
      rotateearth = rotateearth + .005;
    }else{
      rotateearth = 0;
    }
  }
  hud();
}

class Timer {
  Timer(int scale) { this.timeScale = scale; }
  int h=0,m=0,s=0;
  int timeScale = 10000; 
  int frameCounter;
  
  void faster(){ timeScale+=100; }
  void slower() { timeScale-=100; }

  int getSeconds(){ return s; }
  int getMinutes(){ return m; }
  int getHours(){ return h; }

  void updateTime(float currentFrameRate){
    if(frameCounter < currentFrameRate/timeScale){
      frameCounter++;
    }else{
      frameCounter = 0;
      if(s < 59){
        s++;
      } else {
        s=0;
        if(m < 59){
          m++;
        } else {
          m=0;
          if(h < 24){
            h++;
          } 
        }
      }
    }
  }

  public String toString(){
    return zeroPad(h) + ":" + zeroPad(m) + ":" + zeroPad(s);
  }
}

PVector sphericalToCartesian(float lat, float lon, float elevation){
  float x= r * cos(lat) * cos(lon);
  float y= r * cos(lat) * sin(lon);
  float z= r * sin(lat);
  return new PVector(x, y, z);
}

float [] offsets = new float[3];
double distance = 0.0f;

//HUD
void hud(){
  clock.updateTime(frameRate);
  offsets = cam.getLookAt();
  PMatrix3D cameraMatrix = (PMatrix3D)pgl.getMatrix();
  camera();
  text(clock.toString(), 10,10,0); 
  pgl.setMatrix(cameraMatrix);
  cam.lookAt(offsets[0],offsets[1],offsets[2]);
}

boolean autorotate = false;
void keyPressed(){
  if(key == 'r'){
    autorotate=!autorotate;
  } 
}
