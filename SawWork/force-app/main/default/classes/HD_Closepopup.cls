public with sharing class HD_Closepopup {

   private final BMCServiceDesk__Incident__c incident;
   private static BMCServiceDesk__Status__c status;
   public boolean savebuttonFlag{get;set;}
   transient public boolean errorflag{get;set;}

    public HD_Closepopup(ApexPages.StandardController controller) {
    errorflag = false;
      //adding extra filed not in page  reference
      String[] ExtraFields = new String[]{'BMCServiceDesk__Status_ID__c'};
       if(!test.isRunningTest())
       {
      controller.addFields(ExtraFields);
        }
      this.incident = (BMCServiceDesk__Incident__c)controller.getRecord();
      status = [Select Id,Name from BMCServiceDesk__Status__c where Name ='CLOSED'limit 1];
      //checking weather the incident is already closed or wat
      if(this.incident.BMCServiceDesk__Status_ID__c == 'CLOSED')
      {
       savebuttonFlag = true;
      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Incident Is already Closed !'));
      }
      this.incident.BMCServiceDesk__FKStatus__c = status.id;
      this.incident.BMCServiceDesk__FKClosedBy__c = UserInfo.getuserId();
    }
    
    public pageReference ajaxSave()
    {
    try
    {

     Database.SaveResult sr = Database.update(incident, false);
   if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully Updated Incident ID : ' + sr.getId());
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Save Succesfull !' ));
    }//if
       else
    {
   // ApexPages.addMessages(sr.getErrors());

   for(Database.Error err : sr.getErrors() )
   {
      this.errorflag = true;
   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,''+err.getMessage() ));
   }//for(Database.Error err : sr.getErrors() )
   
    }//else
    }//try
    catch(Exception e)
    {

     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
    }
    return null;
    }

}//CLASS END