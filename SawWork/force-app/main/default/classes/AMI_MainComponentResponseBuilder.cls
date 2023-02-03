global without sharing class AMI_MainComponentResponseBuilder {
    public String getUIControllerObject(String status, String responseObj){
      AMI_MainComponentGenericObject uiResponse = new AMI_MainComponentGenericObject();
      uiResponse.status = status;
      uiResponse.responseObj = responseObj;
      return JSON.serialize(uiResponse);
  }

  public String generateGenericExceptionObject(Exception e){
      AMI_GenericErrorObject genericObject = new AMI_GenericErrorObject();
      genericObject.message = e.getMessage();
      return JSON.serialize(genericObject);
  }
}