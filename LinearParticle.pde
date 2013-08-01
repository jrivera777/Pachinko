class LinearParticle extends Particle
{
  float length;
  float thickness;
  float angle;
  LinearParticle(PVector l, float an, float len, float thck)
  {
    super(l);
    length = len;
    thickness = thck;
    angle = radians(an);
    float xAcc = cos(-angle)/4;
    float yAcc = sin(-angle)/4;
    velocity = new PVector(.05, .05);
    acceleration = new PVector(xAcc, yAcc);
    
    lifespan = 100;
  }
  LinearParticle(PVector l, float an, float len)
  {
    this(l, an, len, -1);
  }
  void display()
  {
    stroke(r, g, b, lifespan);
    if (thickness > 0)
      strokeWeight(thickness);
    line(location.x, location.y, location.x + length*cos(-angle), location.y + length*sin(-angle));
  }
}

