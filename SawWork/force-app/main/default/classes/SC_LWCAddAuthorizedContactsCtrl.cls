/*
	Author              :   Tejaswini 
    Created             :   23-April-2021
    Purpose             :   Controller to Associate and Remove authorised contacts from PD
    Test Class          :   SC_LWCAddAuthorizedContactsCtrl_Test

	Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
	23 Apr 2021          Tejaswini      			ESESP-4953		SOCC CAR 2 - RunBooks 2
------------------------------------------------------------------------------------------------------------------
*/
public with sharing class SC_LWCAddAuthorizedContactsCtrl {
    
    public class ContactWrapper
    {
        @AuraEnabled public String contactName;
        @AuraEnabled public String akamContactId;
        @AuraEnabled public String title;
        @AuraEnabled public String email;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id Id;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String contactUrl;
        @AuraEnabled public String accountUrl;
    
    }
    
    public class ServiceAccountContactWrapper
    {
        @AuraEnabled public List<Id> listServiceAccountRecords;
        @AuraEnabled public List<Contact> contactList;
    }

    public class StatusWrapper{
        
        @AuraEnabled public String errorMsg;
        @AuraEnabled public Integer successCount;
        @AuraEnabled public String errorId;
          
    }
    
    @AuraEnabled 
    public static ServiceAccountContactWrapper getServiceAccountContacts(Id pdId){
        
        List<Service_Account_PD_Mapping__c> serviceAccountPDList = new List<Service_Account_PD_Mapping__c>();
        List<Id> serviceAccountIDList = new List<Id>();
        
        Set<Id> setServiceAccountRecords; 

        Policy_Domain__c policyDomainObject = [SELECT Id, Account_Name__c, Service_Account__c FROM Policy_Domain__c WHERE Id =: pdId LIMIT 1];
            
            //ESESP-4953 - Multiple Service Account
            serviceAccountPDList = [Select id, Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: pdId];
            for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
                serviceAccountIDList.add(SAPDMap.Service_Account__c);
            }
            
            //Get the List of Contacts which are not part of Policy domain
            List<Contact> contactList = [SELECT Id,Name, Title, Akam_contact_id__c, Email, Account.Name,AccountId FROM Contact 
                                         WHERE  (AccountId =: policyDomainObject.Account_Name__c OR
                                                 AccountId =: serviceAccountIDList) AND
                                                //AccountId =: policyDomainObject.Service_Account__c) AND //commented for ESESP-4953
                                                AccountId != NULL AND
                                                Id NOT In (SELECT Contact_Name__c FROM Authorized_Contact__c WHERE Policy_Domain__c  =:pdId) ORDER BY Name ASC];
            
             //List of Contacts which are part of Service Account
            setServiceAccountRecords = new Set<Id>();
            
            for(contact eachContact : contactList){
                for(id serviceAccountId : serviceAccountIDList){
                    if(eachContact.AccountId == serviceAccountId)
                        setServiceAccountRecords.add(eachContact.Id);
                }
            }
        
        List<Id> listServiceAccountRecords = new List<Id>();
        listServiceAccountRecords.addAll(setServiceAccountRecords);
        
        ServiceAccountContactWrapper recWrap= new ServiceAccountContactWrapper();
        recWrap.listServiceAccountRecords = listServiceAccountRecords;
        recWrap.contactList = contactList;
        
        return recWrap;
        
    }
    
    @AuraEnabled
    public static List<ContactWrapper> getAllContactRecs(Id pdId)
    {
       /* List<Service_Account_PD_Mapping__c> serviceAccountPDList = new List<Service_Account_PD_Mapping__c>();
        List<Id> serviceAccountIDList = new List<Id>();
        
        Set<Id> serviceAccountRecords; 

        Policy_Domain__c policyDomainObject = [SELECT Id, Account_Name__c, Service_Account__c FROM Policy_Domain__c WHERE Id =: pdId LIMIT 1];
            
            //ESESP-4953 - Multiple Service Account
            serviceAccountPDList = [Select id, Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: pdId];
            for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
                serviceAccountIDList.add(SAPDMap.Service_Account__c);
            }
            
            //Get the List of Contacts which are not part of Policy domain
            List<Contact> contactList = [SELECT Id,Name, Title, Akam_contact_id__c, Email,Alternative_Email__c, Account.Name,AccountId FROM Contact 
                                         WHERE  (AccountId =: policyDomainObject.Account_Name__c OR
                                                 AccountId =: serviceAccountIDList) AND
                                                //AccountId =: policyDomainObject.Service_Account__c) AND //commented for ESESP-4953
                                                AccountId != NULL AND
                                                Id NOT In (SELECT Contact_Name__c FROM Authorized_Contact__c WHERE Policy_Domain__c  =:pdId) ORDER BY Name ASC LIMIT 9000];
            
             //List of Contacts which are part of Service Account
            serviceAccountRecords = new Set<Id>();
            
            for(contact eachContact : contactList){
                for(id serviceAccountId : serviceAccountIDList){
                    if(eachContact.AccountId == serviceAccountId)
                        serviceAccountRecords.add(eachContact.Id);
                }
            }
        */
           ServiceAccountContactWrapper recordWrapper=getServiceAccountContacts(pdId);
        
        	
            List<ContactWrapper> listContactWrapper=new List<ContactWrapper>();

            for(Contact conObj:recordWrapper.contactList){

                ContactWrapper contactWrapperRec=new ContactWrapper();
                
                contactWrapperRec.contactName=conObj.Name;
                contactWrapperRec.akamContactId=conObj.Akam_contact_id__c;
                contactWrapperRec.title= conObj.Title;
                contactWrapperRec.email=conObj.Email;
                contactWrapperRec.accountName=conObj.Account.Name;
				contactWrapperRec.Id=conObj.Id;
                contactWrapperRec.accountId=conObj.AccountId;

                contactWrapperRec.contactUrl='/lightning/r/Contact/'+conObj.Id+'/view';
                contactWrapperRec.accountUrl='/lightning/r/Account/'+conObj.AccountId+'/view';
                

                listContactWrapper.add(contactWrapperRec);
            }

            return listContactWrapper;
            
    }

    @AuraEnabled
    public static StatusWrapper addContactRecs(Id pdId, Id[] arrContact){
		//System.debug('Add contact method entry ');
        
        System.debug('the contact array is'+arrContact);
        
        ServiceAccountContactWrapper recordWrapper=getServiceAccountContacts(pdId);
        
        Set<Id> serviceAccountRecords = new Set<Id>(recordWrapper.listServiceAccountRecords);
        
        //List<String> selectedRecordIdList = selectedRecords.split(',');
        List<String> selectedRecordIdList;
        //List to insert Authorized Contacts
        List<Authorized_Contact__c> authorizedContactsList = new List<Authorized_Contact__c>();
        
        //Temp Authorized Contact Record
        Authorized_Contact__c authorizedContactObject;
        
        List<Contact> conList = [Select Id,Akam_contact_id__c from Contact where Id in :arrContact];
        Map<Id,String> contactAkamContact = new Map<Id,String>();
        for(Contact c:conList)
        {
            String akamId=c.Akam_contact_id__c;
            contactAkamContact.put(c.Id,akamId);
        }
        //Add Contacts
        
            //If Service Account is empty
            if(serviceAccountRecords.size() == 0){
                
                for(Id eachId : arrContact){
                    authorizedContactObject = new Authorized_Contact__c();
                    authorizedContactObject.Contact_Name__c = eachId ;
                    authorizedContactObject.Policy_Domain__c = pdId;
                    authorizedContactObject.Product_Interests__c = 'All';
                    authorizedContactsList.add(authorizedContactObject);
                }
            }
            else{
                
                for(Id eachId : arrContact){
                    authorizedContactObject = new Authorized_Contact__c();
                    authorizedContactObject.Contact_Name__c = eachId ;
                    authorizedContactObject.Policy_Domain__c = pdId;
                    authorizedContactObject.Product_Interests__c = 'All';
                    
                    //If the Contact/Policy Domain belongs to service account
                    if(serviceAccountRecords.contains(eachId))
                        authorizedContactObject.Service__c = True;
                    authorizedContactsList.add(authorizedContactObject);
                }
            }
        
            /*if(authorizedContactsList.size() > 0){
                try{
                    //System.debug('insert block ');
                    Insert authorizedContactsList;
                    //Setting the success message
                    //successMessageText = ' Contact(s) added to the Policy Domain' ;
                }
                catch(Exception e){
                    System.debug('the error message is '+e.getMessage());
                    
                    //String msg= e.getMessage().contains('You need to be SOCC or S/SP to have access.') ?
                    //    'You need to be SOCC or S/SP to have access.' : e.getMessage();
                    
                    throw new AuraHandledException('Something went wrong:'+e.getMessage());
                    
                }
            }*/

            // String successMsg='Successfully inserted authorized contacts';
            // String errorMsg='The following error has occurred.';
            
            String errorMsg='';
            Integer successCount=0;
            Integer failureCount=0;
			String errorId='';
        	
            Database.SaveResult[] srList = Database.insert(authorizedContactsList, false);
            for(Integer i = 0;  i < srList.size(); i++)
        	{
          		Database.SaveResult sr = srList.get(i);
            	if (sr.isSuccess()) {
                    successCount++;
                }
            
            	if (!sr.isSuccess()) 
            	{
                	for(Database.Error err : sr.getErrors()) 
                	{
                    	failureCount++;
                    	if(failureCount<=5){
                        	errorId = errorId+ contactAkamContact.get(authorizedContactsList.get(i).Contact_Name__c)+',';
                    	}
                                      
                        if(!errorMsg.contains(err.getMessage())){
                        	errorMsg=errorMsg + err.getMessage() + ', ' ;
                    	}
                	}
            	}
			}
        
          StatusWrapper rec = new StatusWrapper();
          rec.successCount= successCount;
          rec.errorMsg= errorMsg;
          if(failureCount>5)
          {
              Integer count=failureCount-5;
              errorId=errorId+'...and '+ count +' other records failed';
              rec.errorId=errorId;
          }
          else
          {
              rec.errorId=errorId;
          }
          
          return rec;
    }

    @AuraEnabled
    public static List<ContactWrapper> getAllAuthContactRecs(Id pdId){

        List<Authorized_Contact__c> authorizedContactList = [SELECT Id, Contact_Name__r.Name, Contact_Name__r.AKAM_Contact_ID__c, Contact_Name__r.Title, 
                                                                 Contact_Name__r.Email,Contact_Name__r.Account.Name,Contact_Name__r.Account.Id FROM  authorized_contact__c 
                                                                 WHERE Policy_Domain__c  = :pdId];

        List<ContactWrapper> listAuthContactWrapper=new List<ContactWrapper>();                                                                                                            
        for(Authorized_Contact__c rec:authorizedContactList){

            ContactWrapper authContactWrapperRec=new ContactWrapper();

            authContactWrapperRec.Id=rec.Id;
            authContactWrapperRec.contactName=rec.Contact_Name__r.Name;
            authContactWrapperRec.akamContactId=rec.Contact_Name__r.AKAM_Contact_ID__c;
            authContactWrapperRec.title=rec.Contact_Name__r.Title;
            authContactWrapperRec.email=rec.Contact_Name__r.Email;
            authContactWrapperRec.accountName=rec.Contact_Name__r.Account.Name;

            authContactWrapperRec.contactUrl='/lightning/r/Authorized_Contact__c/'+rec.Id+'/view';
            authContactWrapperRec.accountUrl='/lightning/r/Account/'+rec.Contact_Name__r.Account.Id+'/view';
            
            listAuthContactWrapper.add(authContactWrapperRec);
        }

        return listAuthContactWrapper;
    }
    
    @AuraEnabled
    public static StatusWrapper deleteAuthContact(Id[] arrAuthContact){
		//System.debug('Delete method entry ');
        Authorized_Contact__c authorizedContactObject;

        List<Authorized_Contact__c> authorizedContactsList = new List<Authorized_Contact__c>();
        
        Map<Id,String> mAuthIdAkamContactId = new Map<Id,String>();
        
        List<Authorized_Contact__c> lAuthContact = [Select Id, Contact_Name__r.AKAM_Contact_ID__c from Authorized_Contact__c where Id IN :arrAuthContact];
		for(Authorized_Contact__c auCon:lAuthContact)
        {
            String akamId=auCon.Contact_Name__r.AKAM_Contact_ID__c;
            mAuthIdAkamContactId.put(auCon.Id,akamId);
        }
        
        for(Id recId:arrAuthContact){
            	System.debug('Delete Record form block ');
                authorizedContactObject = new Authorized_Contact__c(Id = recId);
                authorizedContactsList.add(authorizedContactObject);
        }

        /*if(authorizedContactsList.size() > 0){
            try{
                System.debug('Delete block ');
                Delete authorizedContactsList;
                           
            }
            catch(Exception e){
                System.debug('the error message is '+e.getMessage());
                throw new AuraHandledException('Something went wrong:'+e.getMessage());
                
            }
        }*/
        
        	String errorMsg='';
            Integer successCount=0;
            Integer failureCount=0;
			String errorId='';
        	
            Database.DeleteResult[] srList = Database.delete(authorizedContactsList, false);
            for(Integer i = 0;  i < srList.size(); i++)
        	{
          		Database.DeleteResult sr = srList.get(i);
            	if (sr.isSuccess()) {
                    successCount++;
                }
            
            	if (!sr.isSuccess()) 
            	{
                	for(Database.Error err : sr.getErrors()) 
                	{
                    	failureCount++;
                    	if(failureCount<=5){
                        	errorId = errorId+ mAuthIdAkamContactId.get(authorizedContactsList.get(i).Id)+',';
                    	}
                                      
                        if(!errorMsg.contains(err.getMessage())){
                        	errorMsg=errorMsg + err.getMessage() + ', ' ;
                    	}
                	}
            	}
			}
        
          StatusWrapper rec = new StatusWrapper();
          rec.successCount= successCount;
          rec.errorMsg= errorMsg;
          if(failureCount>5)
          {
              Integer count=failureCount-5;
              errorId=errorId+'...and '+ count +' other records failed';
              rec.errorId=errorId;
          }
          else
          {
              rec.errorId=errorId;
          }
          
          return rec;

    }
}