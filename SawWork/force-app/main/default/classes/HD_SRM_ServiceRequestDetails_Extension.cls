/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for SRM Console

Purpose : an implementation for SRM detail page  Controller
          
Usage : used as an implementation for the business logic , for SRM record details display
          
Test Class Asssociated : 

Controller (Boolean): true

Page Used/Asssociated (default -> NONE) : ServiceRequestdetail?id=xxxxxxxxxxxxxxxx

Class Associated : NONE
              
*/
public with sharing class HD_SRM_ServiceRequestDetails_Extension {

        public BMCServiceDesk__Incident__c mysObject{get;set;}
        public boolean Save_Flag{get;set;}
        //public String SRM_Number{get;set;}
        public boolean Record_Lock_flag{get;set;}
        
        public String ClientId{get;set;}
        public String reqdefId{get;set;}
        public String SRMId{get;set;}
        private List<String> fieldnames;


    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public HD_SRM_ServiceRequestDetails_Extension(ApexPages.StandardController stdController) {
    
    try{
        //adding field which are not part of the simple field set beta query
        fieldnames = new List<String>();
        fieldnames.add('BMCServiceDesk__FKClient__c');
        if(!Test.isRunningTest()){
        stdController.addFields(fieldnames);
        }
        
        
        this.mysObject = (BMCServiceDesk__Incident__c)stdController.getRecord();
        this.Save_Flag =false;
        this.Record_Lock_flag = recordStatus((Id)mysObject.get('Id'));
        if ( mysObject.ownerID == null )
        {        this.mysObject.ownerID = UserInfo.getUserId(); }
        }//
        catch(Exception e){ system.debug('First Exception---> '+e.getMessage());}
        
    }//custructor
    
        //the method is used to check the weather the record is locked or not while approval
        public static boolean recordStatus(Id TargetRecordID)
        { 
        List<ProcessInstance> ProcessInstanceList = new  List<ProcessInstance>();
        ProcessInstanceList = [ SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =: TargetRecordID and STATUS = 'Pending' LIMIT 1]; 
        if(ProcessInstanceList.size() > 0)
        {
        return true;
        }
        return false;
        }//public static boolean recordStatus(Id TargetRecordID)
    
  // Overriding update functionality 
    public pagereference AjaxSave()
    {
   try 
   { 
                    
         //logic for SRM priority setting
         System.debug('SRM PRIORITY -----> '+this.mysObject.SR_Priority__c);
         if(this.mysObject.SR_Priority__c == 'High')
         {
         System.debug('------> The Priority is high');
         this.mysObject.HD_Ticket_Priority__c = '3';
         }
         else if(this.mysObject.SR_Priority__c == 'Standard')
         {
           this.mysObject.HD_Ticket_Priority__c = '4';
         }//else
          
        
   Database.SaveResult sr = Database.update(mysObject, false);
   if (sr.isSuccess()) {
         Save_Flag = true;
         //getting latest record details
         mysObject = this.mysObject;
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully Updated Incident ID : ' + sr.getId());
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Save Succesfull !' ));
    }//if
       else
    {
   // ApexPages.addMessages(sr.getErrors());
   for(Database.Error err : sr.getErrors() )
   {
      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,''+err.getMessage() ));
   }//for(Database.Error err : sr.getErrors() )
   
    }//else

   }//try
   catch(DmlException ex){
        ApexPages.addMessages(ex);
       }
   catch (Exception e)
   {
   System.debug('[]Exception Occurred : '+e.getMessage());
   ApexPages.addMessages(e);
   }//catch
   return null;
   }//AjaxSave()
   
    //Overriding save functionality 
    public pagereference AjSave()
    {
    pagereference pr = ApexPages.currentPage();
   try 
   {
         //logic for SRM priority setting
         System.debug('SRM PRIORITY -----> '+this.mysObject.SR_Priority__c);
         if(this.mysObject.SR_Priority__c == 'High')
         {
         System.debug('------> The Priority is high');
         this.mysObject.HD_Ticket_Priority__c = '3';
         }
         else if(this.mysObject.SR_Priority__c == 'Standard')
         {
           this.mysObject.HD_Ticket_Priority__c = '4';
         }//else
         
         
   Database.SaveResult sr = Database.insert(mysObject, false);
   if (sr.isSuccess()) {
         Save_Flag = true;
         
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully Saved  Service Request. ID: ' + sr.getId());
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Save Succesfull !' ));
        pr = new pagereference('/apex/ServiceRequestcreate?id='+sr.getId());
        this.mysObject = getIncidentrecord(sr.getId());
        SRMId = this.mysObject.Id;
        reqdefId = this.mysObject.BMCServiceDesk__FKRequestDefinition__c;
        ClientId = this.mysObject.BMCServiceDesk__FKClient__c;
    }
    else
    {
   // ApexPages.addMessages(sr.getErrors());
   for(Database.Error err : sr.getErrors() )
   {
       System.debug('Error: '+err.getMessage());
   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,''+err.getMessage() ));
   }//for(Database.Error err : sr.getErrors() )
   
    }//else

   }//try
   catch (DmlException ex)
   {
   ApexPages.addMessages(ex);
   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,''+ex.getMessage() ));
   }//catch (DmlException ex)
   catch (Exception e)
   {
   System.debug('[]Exception Occurred : '+e.getMessage());
   ApexPages.addMessages(e);
   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,''+e.getMessage() ));
   system.debug('----> Exception[]:'+e);
   }//catch
   return null;
   }//AjaxSave()
   
   
   
  //getting fieldset value
  public List<Schema.FieldSetMember> getHD_SRM_Client_Details() {
        return SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_SRM_Client_Details.getFields();
    }
    
    //getting fieldset value
  public List<Schema.FieldSetMember> getHD_SRM_Service_Details() {
        return SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_SRM_Service_Details.getFields();
    }
    
   
            //getting fieldset value
  public List<Schema.FieldSetMember> getHD_SRM_Status_and_details() {
        return SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_SRM_Status_and_details.getFields();
    }
    
            //getting fieldset value
  public List<Schema.FieldSetMember> getHD_SRM_Date_Time() {
        return SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_SRM_Date_Time.getFields();
    }
    
            //getting fieldset value
  public List<Schema.FieldSetMember> getHD_SRM_Assignment_detail() {
        return SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_SRM_Assignment_detail.getFields();
    }
    
    
    
    
    
    
    public BMCServiceDesk__Incident__c getIncidentrecord(String incid) {
        String query = 'SELECT ';
        //getting HD_SRM_Client_Details
        for(Schema.FieldSetMember f : this.getHD_SRM_Client_Details()) {
            query += f.getFieldPath() + ', ';
        }
        
        //getting HD_SRM_Client_Details
        for(Schema.FieldSetMember f : this.getHD_SRM_Service_Details()) {
            query += f.getFieldPath() + ', ';
        }
        
         //getting HD_SRM_Client_Details
        for(Schema.FieldSetMember f : this.getHD_SRM_Status_and_details()) {
            query += f.getFieldPath() + ', ';
        }
        
                 //getting HD_SRM_Client_Details
        for(Schema.FieldSetMember f : this.getHD_SRM_Date_Time()) {
            query += f.getFieldPath() + ', ';
        }
        
                         //getting HD_SRM_Client_Details
        for(Schema.FieldSetMember f : this.getHD_SRM_Assignment_detail()) {
            query += f.getFieldPath() + ', ';
        }
        
        query += 'Id,BMCServiceDesk__FKClient__c FROM BMCServiceDesk__Incident__c where id = \''+incid+'\' LIMIT 1';
        System.debug(' ---> '+query);
        return Database.query(query);
    }//

    
    public pagereference refreshRecord()
    {
      PageReference pr = new PageReference('/apex/ServiceRequestdetail?id='+(Id)mysObject.get('Id')); 
      try{
        pr.setRedirect(true); 
       }
       catch(Exception e)
       {
    System.debug('[]Exception Occurred : '+e.getMessage());
   ApexPages.addMessages(e);
   ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,''+e.getMessage() ));
   system.debug('----> Exception[]:'+e);

        }//catch
    
          //this.mysObject = getIncidentrecord(SRMId);
    
    return pr;
    
    }//
   
   
}//END OF CLASS