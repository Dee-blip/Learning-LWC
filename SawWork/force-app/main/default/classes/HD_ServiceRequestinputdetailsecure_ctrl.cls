/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Service Request secure field

Purpose : an Implemetation showing encrypted field
          
Usage : Used as an implementation for the business logic , for Service request input details secure data
          
Test Class Asssociated : 

Controller (Boolean): true

Page Used/Asssociated (default -> NONE) : ServiceRequestinputdetailsecure.page

Trigger Associated : NONE
              
*/
public with sharing class HD_ServiceRequestinputdetailsecure_ctrl 
{
     
    private final BMCServiceDesk__incident__c inc;
    
    public List<BMCServiceDesk__SRM_RequestDetail__c> reqdet{get;set;}
    public List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqindet{get;set;}
    public User currentUser {get;set;}
    //Print service template capture code
    public HD_SRMPrintService__c SRMprintserv{get;set;}
    
    public HD_ServiceRequestinputdetailsecure_ctrl(ApexPages.StandardController stdcontroller) 
    {
    //getting the user Details
    currentUser = [Select Id,Name,Email,HD_View_Helpdesk_Confidential_Data__c from User where Id=:userinfo.getuserId() LIMIT 1];
    this.inc = (BMCServiceDesk__Incident__c)stdcontroller.getrecord();
    reqdet = new List<BMCServiceDesk__SRM_RequestDetail__c>();
    SRMprintserv = getSRMPrintTemplateObject(inc.BMCServiceDesk__FKRequestDefinition__c);
    reqdet = getrequestdetails(inc.Id,inc.BMCServiceDesk__FKRequestDefinition__c);
    if( reqdet.size() > 0 )
    {
     for(BMCServiceDesk__SRM_RequestDetail__c srmreqdet : reqdet )
     {
     reqindet = getrequestinputdetails( srmreqdet.id);
     }//for
    }//if

    }//
    
   private List<BMCServiceDesk__SRM_RequestDetail__c> getrequestdetails(String incId,String reqdefId)
   {
     List<BMCServiceDesk__SRM_RequestDetail__c> reqdettemp = [Select id,Name,BMCServiceDesk__FKClient__c,BMCServiceDesk__FKClient__r.Department,BMCServiceDesk__FKClient__r.Division,BMCServiceDesk__FKClient__r.EmployeeNumber,BMCServiceDesk__FKClient__r.Email,BMCServiceDesk__FKClient__r.Phone,BMCServiceDesk__DateExpected__c,BMCServiceDesk__DateRequired__c,BMCServiceDesk__Quantity__c,BMCServiceDesk__FKIncident__c,BMCServiceDesk__FKRequestDefinition__c,Owner.Name, BMCServiceDesk__TotalPrice__c,BMCServiceDesk__CustomerPrice__c    from BMCServiceDesk__SRM_RequestDetail__c where BMCServiceDesk__FKIncident__c =:incId AND BMCServiceDesk__FKRequestDefinition__c=:reqdefId LIMIT 1 ];
     return reqdettemp;
   }//
   

   private List<BMCServiceDesk__SRM_RequestDetailInputs__c> getrequestinputdetails( String reqdetId)
   {
   List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqDetinput = [select Id,Name,BMCServiceDesk__Input__c,BMCServiceDesk__Response__c,BMCServiceDesk__StoredValue__c,HD_Secure_Response__c,HD_Aes_Key__c ,BMCServiceDesk__FKFulfillmentInputs__r.HD_Secure_Field__c, HD_Ffi_Secure_Flag__c, HD_Ffi_Response_Type__c from BMCServiceDesk__SRM_RequestDetailInputs__c where BMCServiceDesk__FKRequestDetail__c =: reqdetId limit 100];
   for(BMCServiceDesk__SRM_RequestDetailInputs__c drmreqinp : reqDetinput)
   {
     if( drmreqinp.HD_Ffi_Response_Type__c == 'Text Area' && currentUser.HD_View_Helpdesk_Confidential_Data__c == true && drmreqinp.HD_Ffi_Secure_Flag__c == true && drmreqinp.HD_Aes_Key__c != null )
     {
      String resp = drmreqinp.BMCServiceDesk__Response__c;
      System.debug('Stored Value ----> '+drmreqinp.BMCServiceDesk__StoredValue__c);
      System.debug('Aes Key Value ----> '+drmreqinp.HD_Aes_Key__c);
      
      String Actualdata = decryptTextAreaData(drmreqinp.BMCServiceDesk__StoredValue__c,drmreqinp.HD_Aes_Key__c).toString();
      System.debug('--->' +Actualdata);
      drmreqinp.BMCServiceDesk__Response__c = Actualdata ;
     }//If
     else if( drmreqinp.HD_Ffi_Response_Type__c == 'Text Area' && currentUser.HD_View_Helpdesk_Confidential_Data__c == false && drmreqinp.HD_Ffi_Secure_Flag__c == true )
     {
          drmreqinp.BMCServiceDesk__Response__c = 'Data is encrypted' ;
     }//else if( drmreqinp.HD_Ffi_Response_Type__c == 'Text Area' && currentUser.HD_View_Helpdesk_Confidential_Data__c == true ) 
 
   }//for

   return reqDetinput;
   }//
   
   private blob decryptTextAreaData( String encryptedStringData,String AesStringKey)
   {
     blob decryptedblobResponse = null;
   try{
     blob decodedencryptedResponseblob = EncodingUtil.base64Decode(encryptedStringData);
     blob decodedAeskeyblob = EncodingUtil.base64Decode(AesStringKey);
    
    //decrypted blob
    decryptedblobResponse = Crypto.decryptWithManagedIV('AES128', decodedAeskeyblob, decodedencryptedResponseblob);
    }
    catch(exception e)
    {
    System.debug('[Exception]: '+e.getMessage());
    }
    
    return decryptedblobResponse;
   
   }//

   //This function is used to retrive SRM print template
   private HD_SRMPrintService__c getSRMPrintTemplateObject(id reqdetId)
   {
    List<HD_SRMPrintService__c> srmprinttempObj = new List<HD_SRMPrintService__c>();
    srmprinttempObj = [Select id,Name from HD_SRMPrintService__c where Request_Definition__c =:reqdetId LIMIT 1];
    if( srmprinttempObj.size() > 0 )
    {
      for( HD_SRMPrintService__c srmprinttemp : srmprinttempObj )
      {
         return srmprinttemp; 
      }
     
    }//if( srmprinttempObj.size > 0 )
    return null;

   }//
  

}//END OF CLASS