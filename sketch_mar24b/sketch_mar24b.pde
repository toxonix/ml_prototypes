import damkjer.ocd.*; //obsessive camera library
ArrayList cubes = new ArrayList();

String[] lines;
float minX=1000, minY= 1000, maxX=0, maxY=0; //used for scaling
//default view parameters
float zoom = 1.0;
float rotationY = 0.0;
float rotationX = 0.0;
float xOffset = 0.0;
float yOffset = 0.0;
PFont courierNews;
SingleLinkageHierarchical clusterer = null;
Camera camera;
int weightIndex=0;
int tabIndex = 0;
//determines the maximum distance from the center of a cluster to find other clusters
float maxDistance = 0.05;
//determines how much to increment/decrement above by based on user input
float distanceIncrement = 0.01;

void setup() {
  size(800, 800, P3D);
  camera = new Camera(this);
  frameRate(35);
  lights();
  noStroke();
  colorMode (RGB, 1.0);
  PFont font = loadFont("Courier10PitchBT-Roman-9.vlw");
  textFont(font);
  textMode(SCREEN); 
  lines = loadStrings("chicago_readinggroup.csv");

  for (int i=1; i<lines.length; i++) {
    Cube c = new Cube();
    String[] pieces = split(lines[i], ':');
    c.latitude = float(pieces[14]);
    c.longitude = float(pieces[15]);
    c.weights = getWeights(pieces);
    c.name = pieces[12];
    c.id = int(pieces[0]);

    minX = min(c.latitude, minX);
    maxX = max(c.latitude, maxX);
    minY = min(c.longitude, minY);
    maxY = max(c.longitude, maxY);
    
    cubes.add(c);
  }

  findClusters();
}

/**
** finds any new clusters.
*/
void findClusters(){
  clusterer = 
    new SingleLinkageHierarchical(maxDistance);
  clusterer.init(cubes);
  clusterer.run();
}

void adjustTabIndex(){
  int end = clusterer.getClusters().size()-1;
  if(tabIndex > end){
    tabIndex = end;
  }
}

void draw(){
  //sleep draw loop if focus lost
  if(!focused) { 
    delay(100); 
    return;
  }

  background(0);
  //origin lines
  stroke(1,0,0);
  line(0,0,0, 100,0,0);
  stroke(0,1,0);
  line(0,0,0, 0, 100,0);
  stroke(0,0,1);
  line(0,0,0, 0, 0,100);
  fill(1,1,1);
  text(labels[weightIndex], 10, 10); 
  if(!keyEvents.isEmpty()){ 
    KeyEvent e = (KeyEvent)keyEvents.poll(); 
    if(keyEvents.size() > 5) { keyEvents.clear(); } 
    if(key == 'e') { xOffset += 5;} 
    if(key == 'q') { xOffset -= 5;} 
    if(key == 'n') { 
      if(weightIndex < labels.length-1){ 
        weightIndex++; 
      }else{ 
        weightIndex  = 0; 
      } 
    } 
    if(key == TAB) {
      if(tabIndex < clusterer.getClusters().size()-1){ 
        tabIndex++; 
      }else{ 
        tabIndex = 0; 
      } 
    } 
    if(key== 'k'){ 
      maxDistance+=distanceIncrement; 
      findClusters(); 
      adjustTabIndex(); 
    }
    if(key == 'j'){
      maxDistance-=distanceIncrement;
      findClusters();
      adjustTabIndex();
    }
  }

  Cube centroid = null;
  if(clusterer.getClusters().size() > 0){
    Cluster cluster = (Cluster)clusterer.getClusters().get(tabIndex);
    centroid = centroid(cluster); //get center of selected cluster
    
    for(int i=0;i<cluster.cubes.size();i++){
      Cube c = (Cube)cluster.cubes.get(i);
      float colorNormal = norm(((Double)(c.weights[weightIndex])).floatValue(), 0, 5);
      fill(colorNormal, 0.5, 1-colorNormal, 1);
      text(c.toString(), 10, (i+2)*10);
    }
  }

  camera.jump(xOffset, yOffset, 0);

  for(int i=0;i<cubes.size();i++){
    Cube c = (Cube)cubes.get(i);
    pushMatrix();
    //subtract min coords first to normalize, 
    //then multiply by the fov
    float xPos = (c.latitude-minX) * width/2;
    float yPos = (c.longitude-minY) * height/2;
    float zPos = ((Double)c.weights[weightIndex]).floatValue() * 25;
    float boxSize = 2;

    float colorNormal = norm(((Double)(c.weights[weightIndex])).floatValue(), 0, 5);
    float alpha = 0.2;
    if(clusterer.getClusters().size() > 0 && 
        c.cluster!=null && c.cluster.equals(clusterer.getClusters().get(tabIndex))){
      boxSize = 3;
      alpha = 1;
      if(centroid !=null && c.equals(centroid)){
        //aim at the center of the cluster
        camera.aim(xPos,yPos,zPos);
        boxSize=10;
        alpha=0.5;
        colorNormal = 1;
      }
    }
    fill(colorNormal, 0.1, 1-colorNormal, alpha);
    translate(xPos, yPos, zPos);
    noStroke();
    box(boxSize);
    popMatrix();
    
    stroke(colorNormal, 0.1, 1-colorNormal,alpha);
    line(xPos,yPos,zPos, xPos,yPos,0);
  }
  camera.feed();
  
}

java.util.LinkedList keyEvents = new java.util.LinkedList();
class KeyEvent {
  char key;
  KeyEvent(char key){
    this.key = key;
  }
} void keyPressed(){
  keyEvents.add(new KeyEvent(key));
}

//moves current offset
void mouseDragged(){
  if(mouseButton==LEFT){
    camera.zoom(radians(mouseY - pmouseY)/2.0);
  }
}

double[] getWeights(String[] line){
  int len = labels.length;
  double[] weights = new double[len];
  for (int i=1; i<len;i++){
    if(line[i]==null || "".equals(line[i])){
      weights[i-1] = 0;
    }else{
      weights[i-1]=Double.parseDouble(line[i]);
    }
  }
  return weights;
}

 //finds the cube closest to the center of a cluster
 //by the simplest method C = X1+...+Xk / k
Cube centroid(Cluster cluster){
  Cube center = (Cube) cluster.cubes.get(0);
  if(cluster.cubes.size()  > 1){
    PVector centerVector = approximateCenter(cluster.cubes);
   
   //println("cluster "+cluster+" approx center: "+centerX+", "+centerY);
    float minDistance = MAX_FLOAT; 
    for(int i=0;i<cluster.cubes.size();i++){
      Cube c =  (Cube)cluster.cubes.get(i); 
      float distance = distance(c.latitude, c.longitude, centerVector.x, centerVector.y);
      if(distance < minDistance) {
        center = c;
      }
    }
  }
  //println("Cube nearest centroid: "+center);
  return center;
}

PVector approximateCenter(ArrayList cubes){
    float sumX =0, sumY=0;
    for(int i=0;i<cubes.size();i++){
      Cube c =  (Cube)cubes.get(i); 
      sumX+=c.latitude;
      sumY+=c.longitude;
    }
    float centerX = sumX / cubes.size();
    float centerY = sumY / cubes.size();
    return new PVector(centerX, centerY, 0);
}

//calculates Euler distance
float distance(float x1, float y1, float x2, float y2){
  return sqrt(pow(x1 - x2,2) + pow(y1 - y2,2));
}

//finds the distance between two clusters
float distanceBetweenRandom(Cluster c1, Cluster c2){
  Cube center1 = (Cube)c1.cubes.get(0);
  Cube center2 = (Cube)c2.cubes.get(0);
  return distance(center1.latitude, center1.longitude, center2.latitude, center2.longitude);
}

float distanceBetweenCenters(Cluster c1, Cluster c2){
  Cube centroid1 = centroid(c1);
  Cube centroid2 = centroid(c2);
  return distance(centroid1.latitude, centroid1.longitude, centroid2.latitude, centroid2.longitude);
}

static String [] labels = new String[]{
    "gr_overall",
    "gr_amenity",
    "gr_checkin",
    "gr_cleanliness",
    "gr_comfort",
    "gr_dining",
    "gr_location",
    "gr_maintenance",
    "gr_staff",
    "gr_value"
};

class Cluster{
  ArrayList cubes;
  int id = 0;
  public Cluster(Cube center, int id){ 
    this.cubes = new ArrayList();
    this.id = id;
    this.cubes.add(center);
  }
  void merge(Cluster c){
    println("merged: "+c+" into "+this);
    cubes.addAll(c.cubes);
    for(int i=0;i<c.cubes.size();i++){
      Cube aCube = (Cube)c.cubes.get(i);
      aCube.cluster = this;
    }
  }

  public String toString(){
    return "Cluster("+id+")";
  }
}

class Cube{
  public Cube(){}
  Cluster cluster;
  float latitude, longitude;
  double[] weights;
  String name;
  int id;
  String toString() { return weights[weightIndex]+" "+name; }
}

interface ClusteringAlgorithm extends Runnable{
  /**
  ** Provide the data to cluster.
  */
  void init(ArrayList cubes);
  /**
  ** returns the list of clusters.
  */
  ArrayList getClusters();
}

class GaussianMixture implements ClusteringAlgorithm{
  ArrayList clusters = new ArrayList();
  void init(ArrayList cubes){
  }
  ArrayList getClusters( ) { return clusters; }
  void run() {}
}

//implementation of Fuzzy C-Means clustering
class FuzzyCMeans implements ClusteringAlgorithm{
  ArrayList centroids = new ArrayList();
  ArrayList clusters = new ArrayList();
  int initialCentroids = 25;
  void init(ArrayList cubes){
    //pick a few cubes to make initial centroids
    for(int i=0;i<initialCentroids;i++){
      //centroids.add(c);
    }
  }
  ArrayList getClusters( ) { return clusters; }
  void run() {
  } 
}

/**
** This is a nice distance clustering method. 
** It starts out with N clusters (one for each item), 
** merging them until a stable number of clusters has been found. 
** If left to its own devices it will reduce the N clusters into one 
** giant cluster. Providing it with a maximum distance and
** stability factor, it becomes very handy.
** In this form it takes at least O(n2) time to complete,
** so be wary of the size of the input set.
** This aglorithm is a good candidate for CUDA processing.
** */
class SingleLinkageHierarchical implements ClusteringAlgorithm{
  ArrayList clusters = new ArrayList();

  //a larger max distance finds large clusters
  //smaller distane finds many more compact clusters
  float maxDistance = 0.01; 

  SingleLinkageHierarchical (float maxDistance){
    this.maxDistance = maxDistance;
  }

  ArrayList getClusters() { 
    return clusters;
  }

  void init(ArrayList cubes){
    for(int i=0;i<cubes.size();i++){
      clusters.add(new Cluster((Cube)cubes.get(i), i));
    }
  }
  
  public void run(){
    //stability is kind of fuzzy. If you increase maxStability, you may find more clusters
    //decreasing it will find a smaller number of larger, less stable clustes.
    //at some point you find the maximum stabiliy for the maxDistance
    
    //the current stability
    int stability = 0;

    //Between 2 and 5. 
    //Anything less makes for too many unstable clusters. 
    //Anything more is a waste of cycles.
    final int maxStability = 3; 
    //holds the cluster size at the end of the last scan
    int lastClusterSize = 0; 

    //loop counter
    int i = 0;
    //** at least O(n2) time!! **//
    //** simple but Destructive **//
     for(;;){
      Cluster c1 = (Cluster)clusters.get(i);
      float leastDistance = MAX_FLOAT;
      Cluster nearest = null;
      for(int j=0;j<clusters.size();j++){
        Cluster c2 = (Cluster)clusters.get(j);
        if(c2.equals(c1)) { continue; } //skip this one, distance is zero
        float distance = distanceBetweenRandom(c1,c2);
        //brutus finds the nearest cluster
        if(distance < maxDistance) {
          if(distance < leastDistance){
            leastDistance = distance;
            nearest = c2;
          }
        }
      }
      //merge the nearest cluster with the selected one
      if(nearest!=null){
        clusters.remove(nearest);
        c1.merge(nearest);
        stability = 0;
        println("merged "+nearest+" into "+c1);
      }
      int currentSize = clusters.size();

      if(i < currentSize - 1){
        i++;
      }else{
        //if no new merges happen for a few cycles, stop scanning
        if(stability == maxStability){
          break;
        }
        if(clusters.size() == lastClusterSize) { 
          stability++;
          println("stability: "+stability);
        }
        i = 0; //scan again from cluster zero
      }
      lastClusterSize = currentSize;
    }//finished scanning
    println("found "+clusters.size()+" stable clusters");
  }

}


