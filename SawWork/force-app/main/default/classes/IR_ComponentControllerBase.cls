public  virtual class IR_ComponentControllerBase {



  public IR_PageControllerBase pageController { get; 
    set {
      if (value != null) {
    pageController = value;
    pageController.setComponentController(this);
      }
    }
  }
  
 
  
}