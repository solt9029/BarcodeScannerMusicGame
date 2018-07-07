import processing.serial.*;
import ddf.minim.*;
import ddf.minim.effects.*;

Minim minim;
AudioPlayer music;
AudioSample scan;

String scannedBarcode = "";
String [] patterns = {"9784802611145\n", "9784844339458\n"};
boolean isStarted = false;
final int BPM = 190;
final int OFFSET = 50;
final int NPM = BPM * 4; // 1分間に流れるノーツの数
final float MPN = 60000.0 / (float)NPM; // ノート1個が流れるのに要する時間（ミリ秒）
int [] notes = {
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 
};
int [] hits; // 1がGreat・2がGood・3がBad
String [] judges = {"", ""};
int [] judgeTimes = {0, 0};

PImage [] imgs;

void setup() {
  size(1000, 1200);
  background(255);
  minim = new Minim(this);
  music = minim.loadFile("music.mp3");
  music.setGain(-15);
  scan = minim.loadSample("scan.mp3");
  hits = new int [notes.length];
  
  imgs = new PImage [2];
  imgs[0] = loadImage("pattern1.png");
  imgs[1] = loadImage("pattern2.png");
  
  textSize(100);
}

void draw() {
  if (!isStarted) {
     return;
  }
  
  background(255);
  
  line(0, 1000, width, 1000);
  
  int notePosition = getNotePosition();
  for (int i = notePosition - 10; i < notes.length; i++) {
    if (i >= 0 && notes[i] > 0 && hits[i] == 0) {
      image(imgs[notes[i] - 1], (notes[i] - 1) * 400 + 200, 1000 - 80 - (i - notePosition) * 20);
    }
  }
  
  if (judgeTimes[0] < 10) {
    if (judges[0].equals("Bad")) {
      fill(0,0,255);
    } else {
      fill(255,0,0);
    }
    text(judges[0], 200, 1000);
    judgeTimes[0]++;
  } else {
    judges[0] = "";
  }
  
  if (judgeTimes[1] < 10) {
    if (judges[1].equals("Bad")) {
      fill(0,0,255);
    } else {
      fill(255,0,0);
    }
    text(judges[1], 600, 1000);
    judgeTimes[1]++;
  } else {
    judges[1] = "";
  }
  
  
  
  // 2個前でまだヒットされていなかったらBadとする
  //int notePosition = getNotePosition();
  if (notePosition - 2 >= 0) {
    if (notes[notePosition - 2] > 0 && hits[notePosition - 2] == 0) {
      hits[notePosition - 2] = 3;
      judges[notes[notePosition - 2] - 1] = "Bad";
      judgeTimes[notes[notePosition - 2] - 1] = 0;
      //fill(0, 0, 255);
      //textMode(CENTER);
      //text("Bad", 200 + (notes[notePosition - 2] - 1) * 400, 1000);
    }
  }
}

int getNotePosition() {
  int notePosition = 0;
  if (int((music.position() - OFFSET) / MPN - 0.5) >= 0) {
    notePosition = int((music.position() - OFFSET) / MPN - 0.5);
  }
  return notePosition;
}

void keyPressed() {
  // バーコードのスキャン処理
  scannedBarcode = scannedBarcode + str(key);
  for (int patternIndex = 0; patternIndex < patterns.length; patternIndex++) {
    if (scannedBarcode.equals(patterns[patternIndex])) {
      scannedBarcode = "";
      scan.trigger();
      
      int notePosition = getNotePosition();
      for (int rangeIndex = -1; rangeIndex <= 1; rangeIndex++) {
        if (notePosition + rangeIndex >= 0 && notePosition + rangeIndex < notes.length) {
          if (notes[notePosition + rangeIndex] == patternIndex + 1 && hits[notePosition + rangeIndex] == 0) {
            hits[notePosition + rangeIndex] = 1 + abs(rangeIndex);
            if (1 + abs(rangeIndex) == 1) {
              judges[notes[notePosition + rangeIndex] - 1] = "Great!";
              judgeTimes[notes[notePosition + rangeIndex] - 1] = 0;
              //fill(255, 0, 0);
              //textMode(CENTER);
              //text("Great!", 200 + (notes[notePosition + rangeIndex] - 1) * 400, 1000);
            } else if (1 + abs(rangeIndex) == 2) {
              judges[notes[notePosition + rangeIndex] - 1] = "Good!";
              judgeTimes[notes[notePosition + rangeIndex] - 1] = 0;
              //fill(255, 0, 0);
              //textMode(CENTER);
              //text("Good!", 200 + (notes[notePosition + rangeIndex] - 1) * 400, 1000);
            }
            break;
          }
        }
      }
    }
  }
  
  // プレイ開始
  if (keyCode == 9) {
    if (!isStarted) {
      music.play();
      isStarted = true;
    }
    scannedBarcode = "";
  }
}

void stop() {
  music.close();
  scan.close();
  minim.stop();
  super.stop();
}