import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.opengl.*;

// Audio recoreder
Minim minim;
AudioInput in;
BeatDetect beat;

int pos = 0;
float[] phases;
float[] phasew;

// vector field parameters
float[] wind;

float spx1 = 0;
float spy1 = 0;
float spz1 = 0;

float sphr = 150;


// zoom factor
float zoom = 1;
// vector field scale
float iscale = 0.01;
// outer scale
float oscale = 4;
// chain point amount of previous frame 
float tdelay = .7;
// how much each chain-element is moved to the middle
float shrink = 0.96;
// strength of vector field
float vstrength_init = 30;
// scale for the offset initialization
float offset_scale = 0.3;
// speed of change
float w_offset = 1;
// velocity
float phase_scale = 0.01;
// fix ball radius (the initial point thing)
float frad = 0;

// length of each chain element
int elem_len = 35;
// number of chains
int chains = 256;
// point buffer
Point[][] megabuf;

final int InitCIRCLE = 0;
final int InitSPHERE = 1;

class Point {
  public float x, y, z = 0;
  Point() {
    x = 0;
    y = 0;
    z = 0;
  }
};

void setup() {

  phases = new float[9];
  phasew = new float[9];
  wind =new float[3]; 
    wind[0] = 0;
    wind[1] = 0;
    wind[2] = 0;

  megabuf = new Point[chains][elem_len];
  for (int i = 0; i < chains; i++) {
    for (int j = 0; j < elem_len; j++) {
      megabuf[i][j] = new Point();
    }
  }
  for (int i = 0; i < 9; i++) {
    phasew[i] = random(-1, 1)*0.5*w_offset;
  }

  minim = new Minim(this);

  in = minim.getLineIn();

  beat = new BeatDetect();

  size(int(displayHeight*0.75), int(displayHeight*0.75), OPENGL);
  frameRate(60);
  noiseDetail(3);
}

float rx = 0;
float rx_w = 0;
float ry = 0;
float ry_w = 0;
float rz = 0;
float rz_w = 0;
float vstrength;
float rad;

int initVal;

void showDebug() {
  textSize(20);
  fill(127);
  text("rad: "+rad, 10, 25);
  text("vstrength: "+ vstrength, 10, 50);
  text("vstrength: "+ vstrength, 10, 50);
  noFill();
}

void draw() {
  
  if (keyPressed && key == 'i' ) {
    initVal = (initVal+1)%2;
    println(initVal);
  }
  
  vstrength = float(mouseY)/float(height)*vstrength_init;
  background(255);
  showDebug();
  translate(width/2, height/2, 0);
  scale(zoom);
  rx = rx+rx_w;
  ry = ry+ry_w;
  rz = rz+rz_w;
  rotateX(rx);
  rotateY(ry);
  rotateZ(rz);

  beat.detect(in.mix);
  if (beat.isOnset() || (keyPressed && key == 0x20)) {
    for (int i = 0; i < 9; i++) {
      // rotation selector
      float rotaccl = vstrength*0.005;
      int rotsel = round(random(1, 3));
      if (rotsel == 1) {
        rx_w = 1*rotaccl;
      } else {
        rx_w = 0;
      }
      if (rotsel == 2) {
        ry_w = 1*rotaccl;
      } else {
        ry_w = 0;
      }
      if (rotsel == 3) {
        rz_w = 1*rotaccl;
      } else {
        rz_w = 0;
      }
      phasew[i] = phasew[i]*0.5+random(-1, 1)*0.5*w_offset;
      ellipse(20, 20, 20, 20);

    }
  }
  //colorMode(HSB, 100);
  fill(0, 255, 230);
  noStroke();
  //ellipse(0, 0, 210, 210);
  sphere(210);
  noFill();
  //colorMode(RGB, 100);
  for (int i = 0; i < 9; i++) {
    phases[i] = (phases[i]+phasew[i]*phase_scale)%TWO_PI;
    //line(width*0.5, i*15, i*15+phases[i]*width*0.1, i*15);
    //stroke(127);
  }
  rad = float(mouseX)/float(width)*height;
  for (int i = 0; i < chains; i++) {
    noFill();
    stroke(0);
    beginShape();
    curveVertex(megabuf[i][0].x, megabuf[i][0].y, megabuf[i][0].z);

    // initial sphere
    switch (initVal){
      case InitCIRCLE: initCircle(i);
          break;
      case InitSPHERE: initSphere(i);
          break;
    }

    for (int j = 1; j < elem_len; j++) {
      //stroke(255,255,255, 255-(j*255/elem_len));
      if (!(keyPressed && key == 'p')) {
        sphereshaper(i, j);
        sinvortex(i, j);
        
      }
      curveVertex(megabuf[i][j-1].x, megabuf[i][j-1].y, megabuf[i][j-1].z);
    }
    endShape();
  }
}

void initSphere(int i) {
 megabuf[i][0].x = rad*cos(TWO_PI*i*11111/chains)*sin(i*TWO_PI/chains);
 megabuf[i][0].y = rad*sin(TWO_PI*i*11111/chains)*sin(i*TWO_PI/chains);
 megabuf[i][0].z = rad*cos(i*TWO_PI/chains);
}

void initCircle(int i) {
 megabuf[i][0].x = rad*cos(TWO_PI*i/(chains));  
 megabuf[i][0].y = rad*sin(TWO_PI*i/(chains));
 megabuf[i][0].z = 0;
}

void sinvortex(int i, int j) {
  float x1 =megabuf[i][j-1].x;
  float y1 =megabuf[i][j-1].y;
  float z1 =megabuf[i][j-1].z;
  megabuf[i][j].x = megabuf[i][j].x*tdelay + x1*(1-tdelay)*shrink + sin( sin(z1*iscale + phases[0]) * sin(y1*iscale + phases[1])*oscale + phases[3])*vstrength + wind[0];
  megabuf[i][j].y = megabuf[i][j].y*tdelay + y1*(1-tdelay)*shrink + sin( sin(x1*iscale + phases[3]) * sin(z1*iscale + phases[4])*oscale + phases[5])*vstrength + wind[1];
  megabuf[i][j].z = megabuf[i][j].z*tdelay + z1*(1-tdelay)*shrink + sin( sin(y1*iscale + phases[6]) * sin(x1*iscale + phases[7])*oscale + phases[8])*vstrength + wind[2];
}

void sphereshaper(int i, int j) {
  float x1 = megabuf[i][j].x;
  float y1 = megabuf[i][j].y;
  float z1 = megabuf[i][j].z;
  //float dist = sqrt(sq(x1-spx1) + sq(y1-spy1) + sq(z1-spz1)) - sphr;
  float dist = sqrt(sq(x1-spx1) + sq(y1-spy1) + sq(z1-spz1)) - rad;
  
  
  megabuf[i][j].x = x1 + (spx1 - x1)*dist/300;
  megabuf[i][j].y = y1 + (spy1 - y1)*dist/300;
  megabuf[i][j].z = z1 + (spz1 - z1)*dist/300;
}
