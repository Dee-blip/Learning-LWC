public  virtual class SI_ComponentControllerBase {

  public SI_PageControllerBase pageController { get; 
    set {
      if (value != null) {
    pageController = value;
    pageController.setComponentController(this);
      }
    }
  }
  
}