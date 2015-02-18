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


// zoom factor
float zoom = 1;
// vector field scale
float iscale = 0.01;
// outer scale
float oscale = 4;
// chain point amount of previous frame 
float tdelay = 0.8;
// how much each chain-element is moved to the middle
float shrink = 0.16;
// strength of vector field
float vstrength_init = 30;
// scale for the offset initialization
float offset_scale = 0.3;
// speed of change
float w_offset = 1;
// velocity
float phase_scale = 0.06;
// fix ball radius (the initial point thing)
float frad = 0;

// length of each chain element
int elem_len = 50;
// number of chains
int chains = 15;
// point buffer
Point[][] megabuf;

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

  megabuf = new Point[chains][elem_len];
  for (int i = 0; i < chains; i++) {
    for (int j = 0; j < elem_len; j++) {
      megabuf[i][j] = new Point();
    }
    megabuf[i][0].x = frad*cos(TWO_PI*i*2/chains)*sin(i*TWO_PI/chains);
    megabuf[i][0].y = frad*sin(TWO_PI*i*2/chains)*sin(i*TWO_PI/chains);
    megabuf[i][0].z = frad*cos(i*TWO_PI/chains);
  }
  for (int i = 0; i < 9; i++) {
    phasew[i] = random(-1, 1)*0.5*w_offset;
  }

  minim = new Minim(this);

  in = minim.getLineIn();

  beat = new BeatDetect();

  size(int(displayHeight*0.5), int(displayHeight*0.5), OPENGL);
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

void showDebug() {
  textSize(20);
  fill(127);
  text("rad: "+rad, 10, 25);
  text("vstrength: "+ vstrength, 10, 50);
  text("vstrength: "+ vstrength, 10, 50);
  noFill();
}

void draw() {
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
    megabuf[i][0].x = rad*cos(TWO_PI*i*2/chains)*sin(i*TWO_PI/chains);
    megabuf[i][0].y = rad*sin(TWO_PI*i*2/chains)*sin(i*TWO_PI/chains);
    megabuf[i][0].z = rad*cos(i*TWO_PI/chains);

    for (int j = 1; j < elem_len; j++) {
      //stroke(255,255,255, 255-(j*255/elem_len));
      if (!(keyPressed && key == 'p')) {
        updateBuffer(i, j);
      }
      curveVertex(megabuf[i][j].x, megabuf[i][j].y, megabuf[i][j].z);
    }
    endShape();
  }
}

void updateBuffer(int i, int j) {
  float x1 =megabuf[i][j-1].x;
  float y1 =megabuf[i][j-1].y;
  float z1 =megabuf[i][j-1].z;
  megabuf[i][j].x = megabuf[i][j].x*tdelay + x1*shrink + sin( sin(z1*iscale + phases[0]) * sin(y1*iscale + phases[1])*oscale + phases[3])*vstrength;
  megabuf[i][j].y = megabuf[i][j].y*tdelay + y1*shrink + sin( sin(x1*iscale + phases[3]) * sin(z1*iscale + phases[4])*oscale + phases[5])*vstrength;
  megabuf[i][j].z = megabuf[i][j].z*tdelay + z1*shrink + sin( sin(y1*iscale + phases[6]) * sin(x1*iscale + phases[7])*oscale + phases[8])*vstrength;
}

