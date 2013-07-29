import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;

//sound stuff
Maxim maxim;
AudioPlayer gameMusic;
AudioPlayer bump;
AudioPlayer ballNoise;
AudioPlayer scoreBarNoise;

//button stuff
Button again;
Button exit;

//image stuff
PImage ballImage;

//physics stuff
Physics physics; 
CollisionDetector detector; 
Body currentBall;
ArrayList<Body> barriers;
ArrayList<Body> movers;
ArrayList<Body> scoreBars;

//size and other info
float startHeight;
float ballRadius = 12;
float scoreAreas;
float scoreAreaHeight;
float scoreAreaWidth;
float extraSpace;

//score and game stuff
boolean paused = false;
boolean gameOver = false;
int simSpeed;
float points;
float ballsLeft;
boolean updateScore;

final int MAX_BALLS = 10;

void setup()
{
  size(500, 800);
  frameRate(60);

  //button setup
  again = new Button("Play Again!", (int)(width / 2 - 50), (int)(height/2 + 80), 
  (int) (textWidth("Play Again!")) + 15, 30);
  exit = new Button("Exit.", (int)(width / 2 + 50), (int)(height/2 + 80), 
  (int) (textWidth("Exit.")) + 15, 30);

  //body container setup
  barriers = new ArrayList<Body>();
  scoreBars = new ArrayList<Body>();
  movers = new ArrayList<Body>();

  //size setup
  scoreAreas = 13;
  scoreAreaHeight = height / 15  ;
  scoreAreaWidth = width / scoreAreas;
  extraSpace = 600;
  startHeight = ballRadius;

  // sound setup
  maxim = new Maxim(this);
  bump = maxim.loadFile("bump.wav");
  bump.setLooping(false);
  bump.volume(1);

  maxim = new Maxim(this);
  scoreBarNoise = maxim.loadFile("scoreBarNoise.wav");
  scoreBarNoise.setLooping(false);
  scoreBarNoise.volume(1);

  ballNoise = maxim.loadFile("ballNoise.wav");
  ballNoise.setLooping(false);
  ballNoise.volume(1);

  gameMusic = maxim.loadFile("Tranquility.wav");
  gameMusic.setAnalysing(true);
  gameMusic.setLooping(true);
  gameMusic.volume(.70);
  gameMusic.play();

  //image setup
  ballImage = loadImage("red circle.png");
  imageMode(CENTER);

  setupGame();
  println(physics.getRestitution());
}


//initialize basic game components, including the physics engine
void setupGame()
{
  currentBall = null;
  points = 0;
  ballsLeft = MAX_BALLS;

  //physics stuff
  physics = new Physics(this, width, height, 0, -9.8, width*2, height*2, width+11, height + 11, 100);
  simSpeed = physics.getSettings().hz;
  physics.setCustomRenderingMethod(this, "myCustomRenderer");
  detector = new CollisionDetector (physics, this);

  physics.setDensity(0); //make objects static
  for (int i = -1; i < scoreAreas; i++)
  {
    Body b = createScoreBar((i+1)*scoreAreaWidth);
    scoreBars.add(b);
  }
  physics.setDensity(1);


  //generate random barriers
  physics.setDensity(0);
  //generateBarriers();
  generateBlockers(); 
  physics.setDensity(1);
}

//generates wall-like barriers.
//CURRENTLY NOT USED...
void generateBarriers()
{
  float sections = 7;
  float currY = height / sections;

  float currX = 0;
  for (int i = 0; i < sections-1; i++)
  {
    float numberOfBarriers = random(3, 7);
    for (int j = 0; j < numberOfBarriers; j++)
    {
      float offsetY = random(-40, 40);
      float angle = random(-90, 90);
      float length = random(20, 40);
      float xLoc = currX + random(-50, 50);
      Body barrier = generateRectangleBarrier(xLoc, currY + offsetY, length, angle, false, 0, 0);
      barriers.add(barrier);
      currX += width / numberOfBarriers;
    }
    currX = 0;
    currY += height/sections;
    println(currY);
  }
}

//generates a bunch of circular bumpers
void generateBlockers()
{
  float sections = 7;
  float currY = height / sections;

  //create sections-1 rows
  for (int i = 0; i < sections-1; i++)
  {
    float xOffset = random(-50, 100);
    float currX = 20 + xOffset;
    float numberOfBarriers = random(3, 8);

    //create random number of bumbers in this row. Random offsets make things more...random
    for (int j = 0; j < numberOfBarriers; j++)
    {
      float offsetY = random(0, 0);
      float radSize = random(10, 18);
      physics.setRestitution(map(radSize, 10, 18, .3, .8));
      Body blocker = physics.createCircle(currX, currY+offsetY, radSize);
      physics.setRestitution(.1);
      UserData data = new UserData();
      data.pachinko_type = UserData.BLOCKER;
      blocker.setUserData(data);
      currX += width / numberOfBarriers + random(-10, 10);
    }
    currX = 20;
    currY += height/sections;
  }
}

void draw()
{
  //if ball gets stuck in a non score zone, apply some force to get it moving again
  if (currentBall != null && currentBall.isSleeping () && inScoreArea(currentBall) < 0)
    currentBall.applyImpulse(new Vec2(random(-.1, .1), .5), currentBall.getPosition());
  if (gameOver)
  {
    gameOverScreen();
  }
}

void mousePressed()
{
  //nothing going on here
}

void mouseReleased()
{
  if (gameOver)
  {
    if (again.mouseReleased()) //restart game
    {
      setupGame();
      gameOver = false;
    }
    else if (exit.mouseReleased()) //exit program
      System.exit(0);
  }
  else if (!paused)
  {
    //create new ball to be dropped, unless the previous ball is in play
    updateScore = true;
    //create new ball for next drop
    if (currentBall == null || (inScoreArea(currentBall) >= 0 && currentBall.isSleeping()))
    {
      if (currentBall != null)
        physics.removeBody(currentBall);

      currentBall = physics.createCircle(mouseX, startHeight, ballRadius);
      UserData ballData = new UserData();
      ballData.pachinko_type = UserData.PACHINKO_BALL;
      currentBall.setUserData(ballData);
    }
  }
}

//creates a rectangle barrier
//CURRENTLY NOT USED...
Body generateRectangleBarrier(float x, float y, float length, float angle, boolean isMoving, int ud, int lr)
{
  float barrier_h = 10;///random(10, 20);
  Body b = physics.createRect(x, y, x+length, y + barrier_h);
  b.setAngle(radians(angle));
  UserData data = new UserData();
  data.pachinko_type = UserData.BARRIER;
  data.loc = 0;
  data.moving = isMoving;
  data.udDir = ud;
  data.lrDir = lr;
  b.setUserData(data);
  return b;
}

//Moves barriers in a rhythmic way
//CURRENTLY NOT USED...
float scalar = 1;
void updateMover(Body mover)
{
  UserData data = (UserData)mover.getUserData();
  if (data.pachinko_type == UserData.BARRIER)
  {
    float x, y;
    //figure out the directions to move
    Vec2 pos = physics.getCMPosition(mover);
    if (data.udDir > 0)
      x = pos.x + (scalar * sin(radians(data.loc)));
    else
      x = pos.x + (scalar * sin(radians(data.loc) * -1));
    if (data.lrDir > 0)
      y = pos.y + (scalar * sin(radians(data.loc))*-1);
    else
      y = pos.y + (scalar * sin(radians(data.loc)));
    Vec2 newLoc = new Vec2(x, y);
    //move static object
    mover.setPosition(physics.screenToWorld(newLoc));
  }
  data.loc = (data.loc + 2) % 360;
  mover.setUserData(data);
}

//do most of the drawing. Called in customRenderer
void displayGame(World world)
{
  //pulse background based on music playing
  float[] spec = gameMusic.getPowerSpectrum();
  float red, green, blue;
  float power = 0;
  float scale = 10000;
  int p = 0;
  for ( ; p < spec.length / 3; p++);
  {
    power += scale * spec[p];
  }
  red = power / (spec.length / 3);
  power = 0;
  for ( ; p < spec.length* 2 / 3; p++);
  {
    power += scale * spec[p];
  }
  green = power / (spec.length / 3);
  power = 0;
  for ( ; p < spec.length - 1; p++);
  {
    power += scale * spec[p];
  }
  blue = power / (spec.length / 3);

  red = map(red, 0, 20, 0, 100);
  green = map(green, 0, 20, 0, 100);
  blue = map(blue, 0, 20, 0, 255);
  background(red, green, blue);
  
  drawScoreArea();

  if (currentBall != null)
  {
    //update score if necessary
    int scoreArea = inScoreArea(currentBall);
    if (scoreArea >= 0 && currentBall.isSleeping() && updateScore)
    {
      adjustScore(scoreArea);
      updateScore = false;
    }
  }

  //render the panchinko ball.
  if (currentBall != null)
  {
    CircleShape ballShape = (CircleShape)currentBall.getShapeList();

    Vec2 ballPos = physics.worldToScreen(currentBall.getWorldCenter());
    float ballAngle = physics.getAngle(currentBall);

    pushMatrix();
    translate(ballPos.x, ballPos.y);
    rotate(-radians(ballAngle));
    float rad = physics.worldToScreen(((CircleShape)currentBall.getShapeList()).getRadius());
    image(ballImage, 0, 0, rad*3 - 5, rad*3 - 5);
    popMatrix();
  }

  //render different items in game (mostly barriers)
  for (Body b = world.getBodyList(); b != null; b = b.getNext())
  {
    UserData data = (UserData)b.getUserData();
    for (Shape shape = b.getShapeList(); shape != null; shape = shape.getNext())
    {
      if (shape.getType() == ShapeType.POLYGON_SHAPE )
      {
        if (data != null && data.pachinko_type == UserData.SCOREBAR)
        {
          //draw scorebar polygons
          stroke(100);
          fill(10, 200, 10);
          beginShape(QUAD);
          PolygonShape poly = (PolygonShape) shape;
          int count = poly.getVertexCount();
          Vec2[] verts = poly.getVertices();
          for (int i = 0; i < count; i++) 
          {
            Vec2 vert = physics.worldToScreen(b.getWorldPoint(verts[i]));
            vertex(vert.x, vert.y);
          }
          Vec2 firstVert = physics.worldToScreen(b.getWorldPoint(verts[0]));
          vertex(firstVert.x, firstVert.y);
          endShape();
        }
        else if ( data != null && data.pachinko_type == UserData.BARRIER)
        {
          //draw barrier polygons NOT USED FOR NOW
          stroke(255);
          fill(50, 25, 25);
          beginShape(QUAD);
          PolygonShape poly = (PolygonShape) shape;
          int count = poly.getVertexCount();
          Vec2[] verts = poly.getVertices();
          for (int i = 0; i < count; i++) 
          {
            Vec2 vert = physics.worldToScreen(b.getWorldPoint(verts[i]));
            vertex(vert.x, vert.y);
          }
          Vec2 firstVert = physics.worldToScreen(b.getWorldPoint(verts[0]));
          vertex(firstVert.x, firstVert.y);
          endShape();
        }
      }
      else if (shape.getType() == ShapeType.CIRCLE_SHAPE)
      {
        //draw circular blockers
        if ( data != null && data.pachinko_type == UserData.BLOCKER)
        {
          CircleShape circle = (CircleShape) shape;
          Vec2 pos = physics.worldToScreen(b.getWorldPoint(circle.getLocalPosition()));
          float radius = physics.worldToScreen(circle.getRadius());
          //draw barrier polygons
          stroke(70, 66, 125);
          fill(163, 160, 206);
          ellipseMode(CENTER);
          ellipse(pos.x, pos.y, radius*2, radius*2);
        }
      }
    }
  }
}

//custom renderer. Handles (almost) all drawing.
void myCustomRenderer(World world) 
{
  if (gameOver)
  {
    //display game over info
    gameOverScreen();
    gameMusic.volume(1.0);
  }
  else if (paused)
  {
    gameMusic.volume(1.0);
    //Freeze physics simulation (Not sure if there is better way to do this...)
    physics.getSettings().hz = Integer.MAX_VALUE;
    displayMenu(world);
  }
  else
  {
    //game not paused. render game at normal speed
    gameMusic.volume(.70);
    //run game normally
    physics.getSettings().hz = simSpeed;
    for (int i = 0; i < movers.size(); i++)
    {
      updateMover(movers.get(i));
    }

    displayGame(world);
    drawMouseTarget();
  }
}

//draws pause menu (not really a menu)
void displayMenu(World world)
{
  displayGame(world);
  fill(0, 0, 0, 210);
  rect(0, 0, width, height);
  fill(255);
  String msg = "Current Score: " + (int)points;
  textSize(32);
  text(msg, width/2 - textWidth(msg)/ 2, height/2);
  String ballMsg = "Balls available: " + (int)ballsLeft;
  text(ballMsg, width/2 - textWidth(ballMsg)/ 2, height/2 + textAscent() + textDescent());
  textSize(12);
}

//draw nice gameover screen
void gameOverScreen()
{
  physics.destroy();
  background(0);
  textSize(32); 
  String msg = "Game Over!\nScore: " + (int)points;
  fill(255);
  text(msg, width / 2 - textWidth(msg)/ 2, height / 2);
  textSize(12);
  again.display();
  exit.display();
}

//return value of score area if ball is there. -1 otherwise
int inScoreArea(Body b)
{
  Vec2 bodyPos = physics.getCMPosition(b);
  for (int i = 0; i < scoreAreas; i++)
  {
    if (bodyPos.x > i*scoreAreaWidth && bodyPos.x < i*scoreAreaWidth + scoreAreaWidth
      && bodyPos.y < height && bodyPos.y > height - scoreAreaHeight)
      return i;
  }
  return -1;
}

//draw out the score area in grayscale
void drawScoreArea()
{
  float col = 0;
  for (int i = 0; i < scoreAreas; i++)
  {
    col = (i+1) * (255/scoreAreas);
    fill(col);
    noStroke();
    rect(i*scoreAreaWidth, height - scoreAreaHeight, scoreAreaWidth, scoreAreaHeight);
  }
  printScores();
}

//print given number vertically (for score areas)
void printVerticalNumber(float x, float y, int number)
{
  fill(230, 0, 0);
  String num = String.valueOf(number);
  float yLoc = y;
  float size = textAscent() + textDescent();
  for (int i = 0; i < num.length(); i++)
  {
    text(num.charAt(i), x, yLoc);
    yLoc += size;
  }
}

//print all the score area points 
void printScores()
{
  float size = textAscent() + textDescent() + 2;
  textSize(12);
  printVerticalNumber(0*scoreAreaWidth + 15, height - scoreAreaHeight + size, 50);
  printVerticalNumber(12*scoreAreaWidth + 15, height - scoreAreaHeight + size, 50);
  printVerticalNumber(1*scoreAreaWidth + 15, height - scoreAreaHeight + size, 100);
  printVerticalNumber(11*scoreAreaWidth + 15, height - scoreAreaHeight + size, 100);
  printVerticalNumber(2*scoreAreaWidth + 15, height - scoreAreaHeight + size, 100);
  printVerticalNumber(10*scoreAreaWidth + 15, height - scoreAreaHeight + size, 100);
  printVerticalNumber(3*scoreAreaWidth + 15, height - scoreAreaHeight + size, 150);
  printVerticalNumber(9*scoreAreaWidth + 15, height - scoreAreaHeight + size, 150);
  printVerticalNumber(4*scoreAreaWidth + 15, height - scoreAreaHeight + size, 250);
  printVerticalNumber(8*scoreAreaWidth + 15, height - scoreAreaHeight + size, 250);
  printVerticalNumber(5*scoreAreaWidth + 15, height - scoreAreaHeight + size, 500);
  printVerticalNumber(7*scoreAreaWidth + 15, height - scoreAreaHeight + size, 500);
  textSize(10);
  printVerticalNumber(6*scoreAreaWidth + 15, height - scoreAreaHeight + size, 1000);
  textSize(8);
}

//renders red or green marker for where ball will drop from.
void drawMouseTarget()
{
  ellipseMode(CENTER);
  noStroke();

  if (currentBall == null || (inScoreArea(currentBall) >= 0 && currentBall.isSleeping()))
  {
    fill(150, 0, 0, 30);
  }
  else
    fill(0, 150, 0, 30);
  ellipse(mouseX, startHeight, ballRadius*2, ballRadius*2);
}

//generate score bar to separate different score areas.
Body createScoreBar(float loc)
{
  Body b = physics.createRect(loc - 15 / 2, height - scoreAreaHeight, loc + 15 / 2, height);
  UserData data = new UserData();
  data.pachinko_type = UserData.SCOREBAR;
  b.setUserData(data);

  return b;
}

//update score based on where the ball landed, and adjust number of balls left over
void adjustScore(int scoreArea)
{
  switch(scoreArea)
  {
  case 0:
  case 12: 
    points += 50; 
    break;
  case 1:
  case 11: 
    points += 100; 
    break;
  case 2:
  case 10: 
    points += 150; 
    break;
  case 3:
  case 9: 
    points += 150; 
    break;
  case 4:
  case 8: 
    points += 250; 
    break;
  case 5:
  case 7: 
    points += 500; 
    break;
  case 6:  
    points += 1000; 
    ballsLeft++;
  }
  if (--ballsLeft <= 0)
    gameOver = true;
}

//collision stuff goes here
//Mostly sound playing right now.
void collision(Body b1, Body b2, float impulse)
{
  UserData b1Data = (UserData)b1.getUserData();
  UserData b2Data = (UserData)b2.getUserData();

  if ( b1Data != null && b2Data != null)
  {
    if (b1Data.pachinko_type == UserData.BARRIER || b2Data.pachinko_type == UserData.BARRIER)
    {
      bump.play();
    }
    if (b1Data.pachinko_type == UserData.BLOCKER || b2Data.pachinko_type == UserData.BLOCKER)
    {
      bump.play();
    }
    if (b1Data.pachinko_type == UserData.SCOREBAR || b2Data.pachinko_type == UserData.SCOREBAR)
    {
      scoreBarNoise.play();
    }
  }
}

//various key functionalities
void keyPressed()
{
  switch(key)
  {
  case 'p': 
    paused = !paused; 
    break;
  }
}

