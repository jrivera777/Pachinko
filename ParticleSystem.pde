//Default Particle System based on http://processing.org/examples/multipleparticlesystems.html 
class ParticleSystem 
{

  ArrayList<Particle> particles;    
  PVector origin;                   
  int count;
  float r, g, b;

  ParticleSystem(int num, PVector v) 
  {
    this(num, v, 255, 255, 255);
  }

  ParticleSystem(int num, PVector v, float rt, float gt, float bt) 
  {
    particles = new ArrayList<Particle>();
    origin = v.get();                     
    r = rt;
    g = gt;
    b = gt; 
    for (int i = 0; i < num; i++) 
    {
      particles.add(new Particle(origin, r, g, b));
    }
  }

  ParticleSystem(PVector v, ArrayList<Particle> parts, float rt, float gt, float bt) 
  {
    particles = new ArrayList<Particle>();
    origin = v.get();                     
    r = rt;
    g = gt;
    b = gt; 
    for (int i = 0; i < parts.size(); i++) 
    {
      particles.add(parts.get(i));
    }
  }
  
  ParticleSystem(PVector v, ArrayList<Particle> parts) 
  {
    this(v, parts, 255, 255, 255);
  }

  void run() 
  {
    for (int i = particles.size()-1; i >= 0; i--)
    {
      Particle p = particles.get(i);
      if (p.isDead()) 
        particles.remove(i);
      else
        p.run();
    }
  }

  void addParticle() 
  {
    Particle p;
    p = new Particle(origin, r, g, b);
    particles.add(p);
  }

  void addParticle(Particle p) 
  {
    particles.add(p);
  }

  boolean dead() 
  {
    return particles.isEmpty();
  }
}

