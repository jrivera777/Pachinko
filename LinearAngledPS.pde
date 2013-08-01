class LinearAngledPS extends ParticleSystem
{
  float angle;
  LinearAngledPS(int num, PVector v, float an)
  {
    super(0, v);
    angle = an;
    // add linear particles with angles ranging from
    // angle - 45 to angle + 45
    for (int i = 0; i < num; i++)
    {
      float currAngle = random(angle - 45, angle + 45);
      particles.add(new LinearParticle(origin, currAngle, 10, 5));
    }
    println();
  }
}

