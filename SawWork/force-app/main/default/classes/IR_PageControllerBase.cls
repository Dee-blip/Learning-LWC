public  virtual class IR_PageControllerBase {
    
  public IR_ComponentControllerBase myComponentController;
    
  public virtual IR_ComponentControllerBase getMyComponentController() {
    return myComponentController;
  }

  public virtual void setComponentController(IR_ComponentControllerBase compController) {
    myComponentController = compController;
  }
    
    
    //?
  public IR_PageControllerBase getThis() {
    return this;
  }
  public virtual void SetObjControllerNull()
  {
  }
  public virtual void PostProcessApplySearch()
  {
  }
  public virtual void clearSearch()
  {
  }
  
 
}