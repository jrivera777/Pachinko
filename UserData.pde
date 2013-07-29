class UserData
{
  //types to let us know what we are dealing with
  static final int SCOREBAR = 0;
  static final int BARRIER = 1;
  static final int BLOCKER = 2;
  static final int PACHINKO_BALL = 3;  

  int pachinko_type;
  boolean moving;
  int udDir; //directional stuff (NOT USED)
  int lrDir; //directional stuff (NOT USED)
  float loc;  
}

