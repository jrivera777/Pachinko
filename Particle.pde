
class Particle {
  PVector location;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  float r, g, b;
  
  Particle(PVector l, float rt, float gt, float bt) 
  {
    acceleration = new PVector(0, 0.05);
    velocity = new PVector(random(-1, 1), random(-2, 0));
    location = l.get();
    lifespan = 250.0;
    r = rt;
    g = gt;
    b = bt;
  }
  Particle(PVector l) 
  {
   this(l, 255, 255, 255);
  }

  void run() 
  {
    update();
    display();
  }

  void update() 
  {
    velocity.add(acceleration);
    location.add(velocity);
    lifespan -= 2.0;
  }

  // Method to display
  void display() 
  {

    stroke(r, g, b, lifespan);
    fill(r, g, b, lifespan);
    ellipse(location.x, location.y, 8, 8);
  }

  // Is the particle still useful?
  boolean isDead() 
  {
    return (lifespan < 0.0);
  }
}

