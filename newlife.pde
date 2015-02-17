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
float zoom = 3;
// vector field scale
float iscale = 0.03;
// outer scale
float oscale = 4;
// chain point amount of previous frame 
float tdelay = 0.8;
// how much each chain-element is moved to the middle
float shrink = 0.16;
// strength of vector field
float vstrength = 2;
// scale for the offset initialization
float offset_scale = 0.3;
// speed of change
float w_offset = 1;
// velocity
float phase_scale = 0.06;
// fix ball radius (the initial point thing)
float frad = 90;

// length of each chain element
int elem_len = 50;
// number of chains
int chains = 20;
// pint buffer
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

  size(int(displayWidth*0.5), int(displayHeight*0.5), OPENGL);
  frameRate(60);
  noiseDetail(3);
}



void draw() {
  background(0);
  translate(width/2, height/2);
  scale(zoom);
  beat.detect(in.mix);
  if (beat.isOnset()) {
    for (int i = 0; i < 9; i++) {
      phasew[i] = phasew[i]*0.5+random(-1, 1)*0.5*w_offset;
      ellipse(20, 20, 20, 20);
    }
  }


  for (int i = 0; i < 9; i++) {
    phases[i] = (phases[i]+phasew[i]*phase_scale)%TWO_PI;
    //line(width*0.5, i*15, i*15+phases[i]*width*0.1, i*15);
    //stroke(127);
  }
  float rad = -mouseX/8;
  for (int i = 0; i < chains; i++) {
    noFill();
    stroke(255, 255, 255, 127);
    beginShape();
    curveVertex(megabuf[i][0].x, megabuf[i][0].y, megabuf[i][0].z);
    megabuf[i][0].x = rad*cos(TWO_PI*i*2/chains)*sin(i*TWO_PI/chains);
    megabuf[i][0].y = rad*sin(TWO_PI*i*2/chains)*sin(i*TWO_PI/chains);
    megabuf[i][0].z = rad*cos(i*TWO_PI/chains);
    for (int j = 1; j < elem_len; j++) {
      float x1 =megabuf[i][j-1].x;
      float y1 =megabuf[i][j-1].y;
      float z1 =megabuf[i][j-1].z;
      megabuf[i][j].x = megabuf[i][j].x*tdelay + x1*shrink + sin( sin(z1*iscale + phases[0]) * sin(y1*iscale + phases[1])*oscale + phases[3])*vstrength;
      megabuf[i][j].y = megabuf[i][j].y*tdelay + y1*shrink + sin( sin(x1*iscale + phases[3]) * sin(z1*iscale + phases[4])*oscale + phases[5])*vstrength;
      megabuf[i][j].z = megabuf[i][j].z*tdelay + z1*shrink + sin( sin(y1*iscale + phases[6]) * sin(x1*iscale + phases[7])*oscale + phases[8])*vstrength;
      curveVertex(megabuf[i][j].x, megabuf[i][j].y, megabuf[i][j].z);
    }
    endShape();
  }
}

