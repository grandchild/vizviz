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

// vector field scale
float scale = 5;
// chain point amount of previous frame 
float tdelay = 0;
// how much each chain-element is moved to the middle
float shrink = 0.8;
// strength of vector field
float vstrength = 0.5;

// length of each chain element
int elem_len = 10;
// number of chains
int chains = 10;
// pint buffer
Point[][] megabuf;

class Point {
  public float x, y, z = 0;
  Point() {
    x = 0;
    y = 0;
    z = 0;
  }
}


void setup() {

  float xcenter = width*0.5;
  float ycenter = height*0.5;
  float zcenter = ycenter;

  phases = new float[9];
  phasew = new float[9];

  megabuf = new Point[chains][elem_len];
  for (int i = 0; i < chains; i++) { 
    for (int j = 0; j < elem_len; j++) {
      megabuf[i][j] = new Point();
      megabuf[i][j].x = xcenter * random(0.7, 1.3);
      megabuf[i][j].y = ycenter * random(0.7, 1.3);
      megabuf[i][j].z = zcenter * random(0.7, 1.3);
    }
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
  beat.detect(in.mix);
  if (beat.isOnset()) {
    for (int i = 0; i < 9; i++) {
      phasew[i] = phasew[i]*0.5+random(-1, 1)*0.5;
    }
  }


  for (int i = 0; i < 9; i++) {
    phases[i] = (phases[i]+phasew[i])%TWO_PI;
    //line(width*0.5, i*15, i*15+phases[i]*width*0.1, i*15);
    //stroke(127);
  }
  for (int i = 0; i < chains; i++) {
    noFill();
    stroke(255);
    beginShape();
    curveVertex(megabuf[i][0].x, megabuf[i][0].y, megabuf[i][0].z);
    for (int j = 1; j < elem_len; j++) {
      float x1 =megabuf[i][j-1].x;
      float y1 =megabuf[i][j-1].y;
      float z1 =megabuf[i][j-1].z;
      megabuf[i][j].x = megabuf[i][j].x*tdelay + x1*shrink + sin( sin(z1*scale + phases[0]) * sin(y1*scale + phases[1]) + phases[3])*vstrength;
      megabuf[i][j].y = megabuf[i][j].y*tdelay + y1*shrink + sin( sin(x1*scale + phases[3]) * sin(z1*scale + phases[4]) + phases[5])*vstrength;
      megabuf[i][j].z = megabuf[i][j].z*tdelay + z1*shrink + sin( sin(y1*scale + phases[6]) * sin(x1*scale + phases[7]) + phases[8])*vstrength;
      curveVertex(megabuf[i][j].x, megabuf[i][j].y, megabuf[i][j].z);
    }
    endShape();
  }
}

