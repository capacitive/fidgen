/**
 * FidGen - a general purpose fiducial marker generator
 * for reacTIVision based projects
 * 
 * Copyright (c) 2008 Karsten Schmidt
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import processing.video.*;
import processing.opengl.*;

import toxi.geom.*;
import toxi.physics.*;

import controlP5.*;

VerletPhysics physics;
FiducialNode fid;
FiducialStore store;

PImage logoBlack,logoWhite;
PFont txtFont,fidFont;

boolean combinationsExhausted=false;

void setup() {
  size(1024,1024,OPENGL);
  hint( ENABLE_OPENGL_4X_SMOOTH );
  physics=new VerletPhysics();
  store=new FiducialStore();
  initUI();
}

void draw() {
  if (newFid && isSaved) {
    String id=null;
    boolean isUnique=true;
    int numIterations=0;
    do {
      physics=new VerletPhysics();
      fid=new FiducialNode(null,NUM_NODES, new Vec3D(), new Vec3D());
      id=fid.toString();
      isUnique=store.isNewUnique(id);
      if (!isUnique) println("duplicate, retry...");
      if (id.length()>MAX_DEPTHSEQ_LENGTH) println("sequence too long, retry...");
    }
    while(!isUnique && numIterations++<100);
    combinationsExhausted=(numIterations>=MAX_ITERATIONS);
    if (forceMinimumDistance) {
      for(int i=0; i<300; i++) physics.update();
      fid.update();
      float dist=fid.avgBlack.distanceTo(fid.avgAll);
      if (dist>MIN_ORIENT_LEN*SCALE) {
        newFid=false;
        isSaved=false;
        println("distance: "+dist);
        store.push(fid);
      } 
      else {
        println("too short... regenerating once more.");
        newFid=true;
        isSaved=true;
      }
    } 
    else {
      newFid=false;
      isSaved=false;
      store.push(fid);
    }
  }
  if (combinationsExhausted) {
    background(255,0,0);
  } 
  else {
    background(isInverted ? 0: 255);
  }
  ellipseMode(CENTER);
  noStroke();
  pushMatrix();
  pushMatrix();
  physics.update();
  fid.update();
  AABB bounds=fid.getBounds();
  Vec3D centroid=new Vec3D(width/2,height/2,0).subSelf(bounds.scale(DRAW_SCALE));
  translate(centroid.x,centroid.y);
  scale(DRAW_SCALE);
  fid.draw();
  popMatrix();
  if (showDepthSequence) {
    pushMatrix();
    translate(20,height-20);
    rotate(-HALF_PI);
    image(isInverted ? logoWhite : logoBlack,0,0);
    fill(isInverted ? 255 : 0);
    textFont(txtFont);
    textAlign(LEFT);
    text("current tree: "+fid.toString(),180,18);
    text("unique trees generated: "+store.sessionSize()+" ("+store.totalSize()+")",180,34);
    popMatrix();
  }
  if (showFiducialID) {
    pushMatrix();
    translate(width/2,height-40);
    textAlign(CENTER);
    textFont(fidFont);
    fill(isInverted ? 255 : 0);
    text(nf(store.sessionSize()-1,4),0,0);
    popMatrix();
  }
  if (newFid && !isSaved) {
    if (!combinationsExhausted) {
      String fn=SAVE_NAME+"/fid-"+nf(store.totalSize()-1,4)+".png";
      saveFrame(fn);
      println(fn+" saved");
    }
    isSaved=true;
  }
  translate(centroid.x,centroid.y);  
  scale(DRAW_SCALE);
  if (showPhysics) drawPhysics();
  if (showDebug) {
    showOrientation();
  }
  popMatrix();
  checkSave();
}

void drawPhysics() {
  stroke(0x60ff4400);
  beginShape(LINES);
  Iterator is=physics.springs.iterator();
  while(is.hasNext()) {
    VerletSpring s=(VerletSpring)is.next();
    line(s.a.x,s.a.y,s.b.x,s.b.y);
  }
  endShape();
}

void showOrientation() {
  fill(0,255,0);
  ellipse(fid.avgBlack.x,fid.avgBlack.y,10,10);
  fill(0,255,255);
  ellipse(fid.avgAll.x,fid.avgAll.y,10,10);
  Vec3D dir=fid.avgBlack.sub(fid.avgAll).normalize();
  Vec3D a=fid.avgAll.add(dir.scale(10));
  Vec3D b=fid.avgBlack.sub(dir.scale(10));
  Vec3D norm=new Vec3D(dir);
  float t=-norm.y;
  norm.y=norm.x;
  norm.x=t;
  norm.scaleSelf(10);
  beginShape(TRIANGLES);
  vertex(a.x-norm.x,a.y-norm.y);
  vertex(a.x+norm.x,a.y+norm.y);
  fill(0,255,0);
  vertex(b.x,b.y);
  endShape();
  stroke(0,0,255);
  noFill();
  AABB bounds=fid.getBounds(null,null);
  rectMode(RADIUS);
  rect(bounds.x,bounds.y,bounds.getExtent().x,bounds.getExtent().y);
}


void acceptMarker() {
  newFid=true;
}

void discardMarker() {
  if(store.pop()) println("removed current fiducial");
  else println("not found");
  newFid=isSaved=true;
}

String newSessionID() {
  return "fiducials-"+year()+nf(month(),2)+nf(day(),2)+"_"+nf(hour(),2)+nf(minute(),2)+nf(second(),2);
}

void newSession() {
  store.clear();
  newFid=isSaved=true;
  combinationsExhausted=false;
  SAVE_NAME = newSessionID();
}
