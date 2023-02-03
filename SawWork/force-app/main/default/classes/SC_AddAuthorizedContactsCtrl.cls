/*---------------------------------------------------------------------------------
 * Page Name            : SC_AddAuthorizedContacts
 * Controller           : SC_AddAuthorizedContactsCtrl
 * Developer Name       : Vamsee Surya
 * Date                 : 25th Oct,2017
 * JIRA                 : ESESP-767 (SOCC)
 * Test Class           : SC_PolicyDomain_Test
 ---------------------------------------------------------------------------------
    Last Modified   |   Developer   |   Purpose
    21st Nov 2017   |   Vamsee S    |   Delete Authorized Contacts functionality (ESESP-768)
    22nd Jan 2018   |   Vikas R     |   Changed the error message (ESESP-928)
    25th Jul 2018   |   Vamsee S    |   Associate Policy domain to the contact (ESESP-1498)
    03rd Mar 2019	|	Pinkesh R	|	ESESP2061 - Encrypt the passphrase coming from APIs(Mulesoft Integration Profile).
	05th Apr 2021	|	Vikas R		|	ESESP-4953 - Link multiple Service Accounts to a single PD
 ---------------------------------------------------------------------------------*/ 
public class SC_AddAuthorizedContactsCtrl {
    
    //Policy Domain Object
    public Policy_Domain__c policyDomainObject;
    
    //Id of the Policy Domain
    public Id policyDomainId{get;set;}
    
    //Id of the Contact
    public Id contactId{get;set;}
    
    //List of Contacts
    public transient String recordListjson{get;set;} 
    
    //List of selected contacts
    public string selectedRecords{get;set;}
    
    //Exception Message
    public string errorMessageText{get;set;}
    
    //Success Message
    public string successMessageText{get;set;}
    
    //Set of contact Ids which are part of Service Account
    Set<Id> serviceAccountRecords;
    
    //This flag will tell whether its Add or Delete
    public boolean isDelete{get;set;}
    
    //This flag will tell whether souce is Policy Domain or Contact
    public boolean fromPD {get;set;}
    
    //Title of the Page
    public string title{get;set;}
        
    //Constructor
    public SC_AddAuthorizedContactsCtrl(ApexPages.StandardController stdController){
        policyDomainId = ApexPages.currentPage().getParameters().get('policyDomainId');
        contactId = ApexPages.currentPage().getParameters().get('contactId');
        
        //Add Authorized Contacts from PD
        if(ApexPages.currentPage().getParameters().get('fromPD') == 'True' && ApexPages.currentPage().getParameters().get('isDelete') == 'False'){
            title = 'Add Authorized Contact(s)';
            isDelete = False;
            fromPD = True;
        }
        
        //Add Authorized Contacts from Contact
        else if(ApexPages.currentPage().getParameters().get('fromPD') == 'False' && ApexPages.currentPage().getParameters().get('isDelete') == 'False'){
            title = 'Associate Policy Domain(s)';
            isDelete = False;
            fromPD = False;
        }
        
        //Delete Authorized Contacts from PD
        else if(ApexPages.currentPage().getParameters().get('fromPD') == 'False' && ApexPages.currentPage().getParameters().get('isDelete') == 'True'){
            title = 'Remove Policy Domain(s) Association';
            isDelete = True;
            fromPD = False;
        }
        
        //Delete Authorized Contacts from Contact
        else{
            title = 'Delete Authorized Contact(s)';
            isDelete = True;
            fromPD = True;
        }        
            
    }
    
    //This method returns the list of contacts in JSON format
    public void getContactList(){
        recordListjson = '';
        
        //ESESP-4953 - Multiple Service Account
        List<Service_Account_PD_Mapping__c> serviceAccountPDList = new List<Service_Account_PD_Mapping__c>();
        List<Id> serviceAccountIDList = new List<Id>();
        
        //Add Contacts
        if(isDelete == False){
            //Get the Account details from Policy Domain record
            policyDomainObject = [SELECT Id, Account_Name__c, Service_Account__c FROM Policy_Domain__c WHERE Id =: policyDomainId LIMIT 1];
            
            //ESESP-4953 - Multiple Service Account
            serviceAccountPDList = [Select id, Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: policyDomainId];
            for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
                serviceAccountIDList.add(SAPDMap.Service_Account__c);
            }
            
            //Get the List of Contacts which are not part of Policy domain
            List<Contact> contactList = [SELECT Id,Name, Title, Akam_contact_id__c, Email, Account.Name,AccountId FROM Contact 
                                         WHERE  (AccountId =: policyDomainObject.Account_Name__c OR
                                                 AccountId =: serviceAccountIDList) AND
                                                //AccountId =: policyDomainObject.Service_Account__c) AND //commented for ESESP-4953
                                                AccountId != NULL AND
                                                Id NOT In (SELECT Contact_Name__c FROM Authorized_Contact__c WHERE Policy_Domain__c  =:policyDomainId) LIMIT 9000];
            
            //List of Contacts which are part of Service Account
            serviceAccountRecords = new Set<Id>();
            
            //Commented for ESESP-4953
            /*if(policyDomainObject.Service_Account__c != null){
                for(contact eachContact : contactList){
                    if(eachContact.AccountId == policyDomainObject.Service_Account__c)
                        serviceAccountRecords.add(eachContact.Id);
                }
            }*/
            
            //ESESP-4953 - Multiple Service Account
            for(contact eachContact : contactList){
                for(id serviceAccountId : serviceAccountIDList){
                    if(eachContact.AccountId == serviceAccountId)
                        serviceAccountRecords.add(eachContact.Id);
                }
            }
        
            //Convert Contact List to JSON
            recordListjson = JSON.serialize(contactList);
            contactList.clear();
        }
        //Delete Contacts
        else{
            //Get the list of existing Authorized Contacts
            List<Authorized_Contact__c> authorizedContactList = [SELECT Id, Contact_Name__r.Name, Contact_Name__r.AKAM_Contact_ID__c, Contact_Name__r.Title, 
                                                                 Contact_Name__r.Email, Contact_Name__r.Account.Name FROM  authorized_contact__c 
                                                                 WHERE Policy_Domain__c  = :policyDomainId];
            recordListjson = JSON.serialize(authorizedContactList);
            authorizedContactList.clear();
        }
        
    }
    
    //This method returns the list of Policy Domains in JSON format
    public void getPolicyDomainList(){
        recordListjson = '';
        //Get the AccountID of the Contact 
        Id AccountId = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1].AccountId;
        List<Policy_Domain__c> policyDomainList;
        
        //ESESP-4953 - Multiple Service Account
        List<Service_Account_PD_Mapping__c> serviceAccountPDList = new List<Service_Account_PD_Mapping__c>();
        List<Id> serviceAccountIDList = new List<Id>();
        List<Id> PDIDList = new List<Id>();
        
        //Associate Policy Domain
        if(isDelete == False){
            
            //ESESP-4953 - Multiple Service Account
            serviceAccountPDList = [Select id, Service_Account__c,Policy_Domain__c from Service_Account_PD_Mapping__c where Service_Account__c =: AccountId];
            for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
                serviceAccountIDList.add(SAPDMap.Service_Account__c);
                PDIDList.add(SAPDMap.Policy_Domain__c);
            }
            
            //Get the List of Policy Domain which are not associated with Contact
            policyDomainList = [SELECT Id, Name, Policy_Domain_State__c, Account_Name__r.Name, Service_Account__r.Name FROM Policy_Domain__c
                                WHERE Policy_Domain_State__c IN ('Active','Provisioned') AND (Account_Name__c = :AccountId OR Id IN: (PDIDList)/*Service_Account__c = :AccountId //commented for ESESP-4953*/) AND Id Not In
                                (SELECT Policy_Domain__c FROM Authorized_Contact__c WHERE Contact_Name__c = :ContactId)];
            
            //For Service Account
            serviceAccountRecords = new Set<Id>();
            for(Policy_Domain__c eachPolicyDomain :  policyDomainList){
                //commented for ESESP-4953
                /*if(eachPolicyDomain.Service_Account__c == AccountId){
                    serviceAccountRecords.add(eachPolicyDomain.Id);
                }*/
                
                //ESESP-4953 - Multiple Service Account
                if(serviceAccountIDList.contains(AccountId)){
                    serviceAccountRecords.add(eachPolicyDomain.Id);
                }
            }
        }
        //Remove Association
        else{
            policyDomainList = [SELECT Id, Name, Policy_Domain_State__c, Account_Name__r.Name, Service_Account__r.Name, Service_Account__c FROM Policy_Domain__c
                                WHERE Id IN(SELECT Policy_Domain__c FROM Authorized_Contact__c WHERE Contact_Name__c = :contactId)];
        }
        recordListjson = JSON.serialize(policyDomainList);
        policyDomainList.clear();
    }
    
     
    //This method inserts the selected contacts into authorized contacts
    public void processSelectedRecords(){
        //List of selected contacts
        List<String> selectedRecordIdList = selectedRecords.split(',');
        
        //List to insert Authorized Contacts
        List<Authorized_Contact__c> authorizedContactsList = new List<Authorized_Contact__c>();
        
        //Temp Authorized Contact Record
        Authorized_Contact__c authorizedContactObject;
        
        //Add Contacts
        if(isDelete == False){
            //If Service Account is empty
            if(serviceAccountRecords.size() == 0){
                for(String eachId : selectedRecordIdList){
                    authorizedContactObject = new Authorized_Contact__c();
                    authorizedContactObject.Contact_Name__c = fromPD == True ? eachId : contactId;
                    authorizedContactObject.Policy_Domain__c = fromPD == True ? policyDomainId :  eachId;
                    authorizedContactObject.Product_Interests__c = 'All';
                    authorizedContactsList.add(authorizedContactObject);
                }
            }
            else{
                for(String eachId : selectedRecordIdList){
                    authorizedContactObject = new Authorized_Contact__c();
                    authorizedContactObject.Contact_Name__c  = fromPD == True ? eachId : contactId;
                    authorizedContactObject.Policy_Domain__c = fromPD == True ? policyDomainId :  eachId;
                    authorizedContactObject.Product_Interests__c = 'All';
                    
                    //If the Contact/Policy Domain belongs to service account
                    if(serviceAccountRecords.contains(eachId))
                        authorizedContactObject.Service__c = True;
                    authorizedContactsList.add(authorizedContactObject);
                }
            }
        
            if(authorizedContactsList.size() > 0){
                try{
                    Insert authorizedContactsList;
                    //Setting the success message
                    successMessageText = fromPD == True ? authorizedContactsList.size() + ' Contact(s) added to the Policy Domain' : authorizedContactsList.size() + ' Policy Domain(s) associated to the Contact';
                }
                Catch(Exception ex){
                    system.debug('--exception--'+ex.getMessage());
                    errorMessageText = ex.getMessage().contains('You need to be SOCC or S/SP to have access.') ?
                        'You need to be SOCC or S/SP to have access.' : ex.getMessage();
                }
            }
        }
        //Delete Contacts
        else{
            //Delete Authorized Contacts
            if(fromPD == True){
                for(String eachId : selectedRecordIdList){
                    authorizedContactObject = new Authorized_Contact__c(Id = eachId);
                    authorizedContactsList.add(authorizedContactObject);
                }
            }
            //Remove Association
            else{
                authorizedContactsList = [SELECT Id FROM Authorized_Contact__c WHERE Policy_Domain__c IN :selectedRecordIdList AND Contact_Name__c = :contactId];
            }
            if(authorizedContactsList.size() > 0){
                try{
                    Delete authorizedContactsList;
                    //Setting the success message
                    successMessageText = fromPD == True ? authorizedContactsList.size() + ' Authorized Contact(s) deleted from the Policy Domain' : authorizedContactsList.size() + ' Policy Domain(s) disassociated from the Contact';
                }
                Catch(Exception ex){
                    system.debug('--exception--'+ex.getMessage());
                    errorMessageText = ex.getMessage().contains('You need to be SOCC or S/SP to have access.') ?
                        'You need to be SOCC or S/SP to have access.' : ex.getMessage();
                }
            }
        }
    }

    /*  This method will be called from Contact Trigger. This method will delete the authorized contacts when account 
        on the contact is changed */
    public static void deleteAuthorizedContacts(List<Id> contactIdList){
        List<Authorized_Contact__c> authorizedContactsToDeleteList = new List<Authorized_Contact__c>();
        authorizedContactsToDeleteList = [SELECT Id FROM Authorized_Contact__c WHERE Contact_Name__c IN :contactIdList];
        if(authorizedContactsToDeleteList.size() > 0){
            Try{
                Delete authorizedContactsToDeleteList;
            }
            Catch(Exception ex){
                System.debug('---Exception---'+ex.getMessage());
            }
        }
            
    }
    
    //ESESP-2061: To encrypt PassPhrase when data is coming from Mulesoft. This method will be called from Contact Trigger(ContactTrigger_bi_bu.apxt).
    public static void encryptPassPhrase(List<Contact> lNewContact, Map<Id, Contact> mIdOldContact){
        //Fetching Integration profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt 
        SC_SOC_Passphrase_Access__mdt passPhraseAccess = [Select id, Profile_ID_Text__c from SC_SOC_Passphrase_Access__mdt where DeveloperName =: 'Passphrase_Access_For_Mulesoft' limit 1];
        if(Test.isRunningTest() || passPhraseAccess.Profile_ID_Text__c.contains(String.valueOf(Userinfo.getProfileId()).substring(0, 15))){
            for(Contact con : lNewContact){
                
                if(String.isNotBlank(con.Passphrase__c) && con.Passphrase__c.length() <= 100 && ((String.isNotBlank(mIdOldContact.get(con.Id).Passphrase__c) && con.Passphrase__c != mIdOldContact.get(con.Id).Passphrase__c) || String.isBlank(mIdOldContact.get(con.Id).Passphrase__c))){
                    String newPassphrase = con.Passphrase__c;
                    
                    //creating Initialization Vector
                    Schema.DescribeSObjectResult res = Contact.sObjectType.getDescribe();
        			String keyPrefix = res.getKeyPrefix();
        			Blob IV = Blob.valueOf((keyPrefix + con.AKAM_Contact_ID__c.leftPad(13,'_')).substring(0,16));
                    
                    //generating and encrypting the encryption key
                    Blob key = Crypto.generateAesKey(256);
                    con.encryption_key__c = EncodingUtil.base64Encode(key);
                    
                    //Encrypting the passphrase
                    Blob data = Blob.valueOf(newPassphrase);
                    Blob encrypted = Crypto.encrypt('AES256', key, IV, data);
        
                    con.Passphrase__c  = EncodingUtil.base64Encode(encrypted);
                    //updating Passphrase_Last_Updated_Date__c
                    con.Passphrase_Last_Updated_Date__c = System.now();
                }
                else if(String.isNotBlank(con.Passphrase__c) && con.Passphrase__c.length() > 100 && String.isNotBlank(mIdOldContact.get(con.Id).Passphrase__c) && con.Passphrase__c != mIdOldContact.get(con.Id).Passphrase__c)
                    con.addError('Maximum length of Passphrase is 100 Characters');
                else if(String.isBlank(con.Passphrase__c) && String.isNotBlank(mIdOldContact.get(con.Id).Passphrase__c)){
                    con.Passphrase__c = mIdOldContact.get(con.Id).Passphrase__c;
                }
            }
        }
        
    }
    
}