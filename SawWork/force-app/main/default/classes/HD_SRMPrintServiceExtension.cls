public with sharing class HD_SRMPrintServiceExtension {

//defining the global variable
private final HD_SRMPrintService__c srmprsrv;

//page parameters 
private id ReqDefID{get;set;}
private id IncId{get;set;}

public User currentUser {get;set;}

public String Finaltemplate{get;set;}


//getting template details for the request definition
public List<BMCServiceDesk__SRM_RequestDetail__c> reqdet{get;set;}
public List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqindet{get;set;}


//Controller Extension Constructor
    public HD_SRMPrintServiceExtension(ApexPages.StandardController stdcontroller) {
    
    try{

    currentUser = [Select Id,Name,Email,HD_View_Helpdesk_Confidential_Data__c from User where Id=:userinfo.getuserId() LIMIT 1];
    List<String>  fields= new List<String>();
    fields.add('Template_formate__c');
     if (!Test.isRunningTest()) {  
    stdcontroller.addFields(fields);
     }
    this.srmprsrv =  (HD_SRMPrintService__c) stdcontroller.getRecord();

    
    //lets get the parameter here
    ReqDefID = ApexPages.currentPage().getParameters().get('reqdefid');
    IncId = ApexPages.currentPage().getParameters().get('incid');
    
    reqdet = new List<BMCServiceDesk__SRM_RequestDetail__c>();      
   // if( (IncId != '' || IncId != null) && (ReqDefID != '' || ReqDefID != null) )
   // { 
    reqdet = getrequestdetails(IncId,ReqDefID);  
   // }//    if(ReqDefID != '' || ReqDefID != null )
    Finaltemplate = String.valueof(srmprsrv.Template_formate__c)+' ';
    system.debug('Finaltemplate--->'+Finaltemplate);
    System.debug('Request details : ----> '+ reqdet);
    if( reqdet.size() > 0 )
    {
      for ( BMCServiceDesk__SRM_RequestDetail__c srmreqdet : reqdet)
      {

      Finaltemplate = String.valueof(Finaltemplate).replace('[Request For]',srmreqdet.BMCServiceDesk__FKClient__r.Name);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Request By]',srmreqdet.BMCServiceDesk__FKClient__r.Name);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Employee Number]',srmreqdet.BMCServiceDesk__FKClient__r.EmployeeNumber);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Phone]',srmreqdet.BMCServiceDesk__FKClient__r.Phone);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Email]',srmreqdet.BMCServiceDesk__FKClient__r.Email);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Department]',srmreqdet.BMCServiceDesk__FKClient__r.Department);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Division]',srmreqdet.BMCServiceDesk__FKClient__r.Division);
      Finaltemplate = String.valueof(Finaltemplate).replace('[Date Expected]',String.valueOf(srmreqdet.BMCServiceDesk__DateExpected__c));
      //lets get the service request details inputs
      reqindet = getrequestinputdetails( srmreqdet.id);
      
      }//for ( BMCServiceDesk__SRM_RequestDetail__c srmreqdet : reqdet)
      
      //now lets get the service request details input
      for(BMCServiceDesk__SRM_RequestDetailInputs__c srmreqdetinput : reqindet)
      {
      //logic to avoid null values 
      System.debug('Final Temaplate : ---> '+Finaltemplate);
      System.debug('Request details Inputs :----> '+srmreqdetinput.BMCServiceDesk__Input__c+' -----> '+srmreqdetinput.BMCServiceDesk__Response__c);
        if( srmreqdetinput.BMCServiceDesk__Response__c == null )
        { 
        Finaltemplate = String.valueof(Finaltemplate).replace('['+srmreqdetinput.BMCServiceDesk__Input__c+']',''); 
        }//if( srmreqdetinput.BMCServiceDesk__Response__c != null )
        else if( srmreqdetinput.BMCServiceDesk__Input__c != null && srmreqdetinput.BMCServiceDesk__Response__c != null )
        {
          Finaltemplate = String.valueof(Finaltemplate).replace('['+srmreqdetinput.BMCServiceDesk__Input__c+']',srmreqdetinput.BMCServiceDesk__Response__c);
        }//else if( srmreqdetinput.BMCServiceDesk__Input__c != null && srmreqdetinput.BMCServiceDesk__Response__c != null )
         

          
      }//for(BMCServiceDesk__SRM_RequestDetailInputs__c srmreqinputs : reqindet)      

      System.debug('Final Temaplate : ---> '+Finaltemplate);
    }//if( reqdet.size() > 0 )
    
    
    }//try
    catch(Exception e)
    {
        System.debug('[Exception]: '+e.getMessage());
        System.debug('[Exception]: '+e.getStackTraceString());
    }//catch
    
    }//
    
    
//getting Request Details   
private List<BMCServiceDesk__SRM_RequestDetail__c> getrequestdetails(String incId,String reqdefId)
   {
     List<BMCServiceDesk__SRM_RequestDetail__c> reqdettemp = [Select id,Name,BMCServiceDesk__FKClient__c,BMCServiceDesk__FKClient__r.Name,BMCServiceDesk__FKClient__r.Email,BMCServiceDesk__FKClient__r.Phone,BMCServiceDesk__FKClient__r.EmployeeNumber,BMCServiceDesk__FKClient__r.Department,BMCServiceDesk__FKClient__r.Division,BMCServiceDesk__DateExpected__c,BMCServiceDesk__DateRequired__c,BMCServiceDesk__Quantity__c,BMCServiceDesk__FKIncident__c,BMCServiceDesk__FKRequestDefinition__c,Owner.Name, BMCServiceDesk__TotalPrice__c,BMCServiceDesk__CustomerPrice__c    from BMCServiceDesk__SRM_RequestDetail__c where BMCServiceDesk__FKIncident__c =:incId AND BMCServiceDesk__FKRequestDefinition__c=:reqdefId LIMIT 1 ];
     return reqdettemp;
   }//    
    
//getting the requestInput details    
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
    

}//END OF CLASS