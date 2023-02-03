public  virtual class SI_PageControllerBase {
    
  public SI_ComponentControllerBase myComponentController;
    
  public virtual SI_ComponentControllerBase getMyComponentController() {
    return myComponentController;
  }

  public virtual void setComponentController(SI_ComponentControllerBase compController) {
    myComponentController = compController;
  }
    
  public SI_PageControllerBase getThis() {
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