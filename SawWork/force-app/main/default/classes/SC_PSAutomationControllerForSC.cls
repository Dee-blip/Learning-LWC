/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomationControllerForSC
    Test Class          :   
    Author              :   Vishnu Sharma
    Created             :   22-Jan-2022
    JIRA                :   ESESP-5612
    Purpose             :   Send Email to customers on Child Customer Mailer
             
    Last Modified         Developer                           Purpose            
    ============= ========================         			  ==========
    22-Jan-2022     Vishnu Sharma                             Initial Version
	Test Class : SC_PS_AutomationTest
* --------------------------------------------------------------------------------*/
public class SC_PSAutomationControllerForSC {
    
    //Method 1 : Method to pre-populated mail details on component.
    @AuraEnabled
    public static String getExternalMailInitDetail(String recId){
       externalEmailWrapperClass externalEmailWrapperClassInstance = new externalEmailWrapperClass();
        List<PS_Customer_Mailers__c> rec = new List<PS_Customer_Mailers__c> ();
    
       rec = [Select Id,Account__c,Email_forwarded_to_Contacts_On__c,Parent_PS_Customer_Mailer__c,Parent_PS_Customer_Mailer__r.Instructions__c,Parent_PS_Customer_Mailer__r.Subject__c,Parent_PS_Customer_Mailer__r.Content__c from PS_Customer_Mailers__c where Id=: recId limit 1]; 
       externalEmailWrapperClassInstance.masterMailerRec = rec[0];

   
       return JSON.serialize(externalEmailWrapperClassInstance);

    }

    //Method 2 : Method to validate if current user is authorized to forward emails to customers.
    @AuraEnabled
    public static Boolean validateUser(String recId){
      Boolean isValidUser = false;
      Set<String> atmIds = new Set<String> ();
      Set<String> atmManagersIds = new Set<String> ();  
      PS_Customer_Mailers__c rec = [Select Id,Account__c,Disabled_On__c from PS_Customer_Mailers__c where Id=:recId limit 1];
      User currUser = [Select Id,ManagerId from User where Id=:UserInfo.getUserId()];
      List<AccountTeamMember> atmList = [Select Id,UserId,User.ManagerId from AccountTeamMember where AccountId =: rec.Account__c AND TeamMemberRole='Security Services - Primary'];
      for(AccountTeamMember iteratedATM : atmList){
        atmIds.add(iteratedATM.UserId);
        atmManagersIds.add(iteratedATM.User.ManagerId);
      }
      if((atmIds.contains(UserInfo.getUserId()) || atmManagersIds.contains(UserInfo.getUserId()) || atmManagersIds.contains(currUser.ManagerId)) && rec.Disabled_On__c == null){
        isValidUser = true;
      }

      
      return isValidUser;
    }

   
    // Wrapper class for method - getExternalMailInitDetail
    class externalEmailWrapperClass{
      
      
        public PS_Customer_Mailers__c masterMailerRec;
      
    }

    // Method to send email to customers
    @AuraEnabled
      public static void sendEmailControllerForSC(String subject,String body,String whatId,List<String> attachNames){
     
          
          
          messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
          List<id> ContentDocumentids = new List<id>();
          List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
          List<String> toAddresses = new List<String>();
          List<String> toAddressesForMailing = new List<String>();
          //Fetching child mailer's Account
          PS_Customer_Mailers__c childMailerRec= [Select Id,Account__c from PS_Customer_Mailers__c where Id=:whatId limit 1];
          PS_Automation_Admin_DL__c dlRec = [Select Id,DL_Email_Address__c from PS_Automation_Admin_DL__c where recordType.Name = 'External' AND Account__c =:childMailerRec.Account__c limit 1];
          if(dlRec != null && dlRec.DL_Email_Address__c != ''){
            toAddresses = dlRec.DL_Email_Address__c.split(',');
            for(String itrEmail : toAddresses){
              toAddressesForMailing.add(itrEmail.trim());
            }
          }
        
        //  List<PS_Customer_Mailers__c> rec = [Select Id,Parent_PS_Customer_Mailer__c from PS_Customer_Mailers__c where Id=: whatId limit 1];
        for(contentDocumentLink CDLink : [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid=:whatId])
			  {
			   ContentDocumentids.add(CDLink.ContentDocumentid);  
        } 
        for ( ContentVersion cversion : [SELECT title, 
													PathOnClient, FileType,
													versiondata 
											  FROM contentversion 
											  WHERE ContentDocumentId IN :ContentDocumentids  
											   ])
			 {
			 
			  
			  Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
			  efa.setFileName(cversion.title);
			  efa.setBody(cversion.versiondata);
			  fileAttachments.add(efa); 
       }
       if(fileAttachments.size() > 0){
        mail.setFileAttachments(fileAttachments);
       }
       
          
          mail.setToAddresses(toAddressesForMailing);
          
         // mail.setSenderDisplayName('Fathima Tehzeeb <frs@akamai.com>');
          mail.setSenderDisplayName(UserInfo.getFirstName()+' '+UserInfo.getLastName());
          mail.setSubject(subject);
          mail.setHtmlBody(body);
          if(whatId != '' && whatId != null){
          mail.setWhatId(whatId);   
          mail.setSaveAsActivity(true);
          
          
          }
          Messaging.sendEmailResult[] sendEmailResults =  Messaging.sendEmail(new List<messaging.SingleEmailMessage>{mail});
          for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
            
                if(sendEmailResult.isSuccess()){
                    PS_Customer_Mailers__c recToUpdate = new PS_Customer_Mailers__c(Id=whatId);
                    recToUpdate.Email_forwarded_to_Contacts_On__c = Datetime.now();
                    update recToUpdate;
                 }
            }
      }
  
      // Email Wrapper
      Class EmailWrapper {
          
          public String subject;
          public String body;
          
      }
}