/*
Author: Sharath K
CR 1639120 CSAT: Q22012 New CSAT Admin screen for Adding Survey Accounts & Survey Contacts
Description: This is the controller to create survey accounts and survey contacts from the CSAT Admin screen. This controller only forms the Contact query. It passes the query to a batch class which actually creates the records.
Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
*/

public class CS_CreateSurveyRecordsController{
    
    public String akamContactsList { get; set; }
    public Integer countOfSurveyAccounts {get;set;}
    public Integer countOfSurveyContacts {get;set;}
    public Integer totalRecordsCount {get;set;}
    
    public CS_CreateSurveyRecordsController()
    {
        options = new List<SelectOption>();
        countOfSurveyContacts = totalRecordsCount = countOfSurveyAccounts = 0;
        surveySelected = ApexPages.currentPage().getParameters().get('survey_id');
        ApexPages.Message myMsg;
        String surveyName = '';
        try{
        surveyName = [select Name from CS_Survey__c where Id= :surveySelected and CS_Status__c = 'Active'].Name;
        //System.assertEquals(surveyName,null);
        myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Please note: You are creating/deleting records under the survey : ' + surveyName);
        ApexPages.addMessage(myMsg);
        }
        catch(Exception e){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'No survey is in Active state. ');
            ApexPages.addMessage(myMsg);
        }
    }
    List<SelectOption> options; 

    public String surveySelected { get; set; }

    //Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
    public PageReference addContactsToSurvey() {
        String tempStr ='';
        String finalstr = '';
        String finalSOQLQuery='';
        
        
        Set<CS_SurveyAccount__c> insert_surveyAccounts_List = new Set<CS_SurveyAccount__c>();
        CS_SurveyAccount__c surveyAccount;
        Map<String,String> Created_Acc_SurveyAccMap = new Map<String,String>();
        Map<String,String> Created_Con_SurveyCon_Map = new Map<String,String>();
        Map<String,String> Existing_Acc_surveyAccMap = new Map<String,String>();
        List<CS_SurveyContacts__c> insert_SurveyContacts_List= new List<CS_SurveyContacts__c>();
        CS_SurveyContacts__c surveyContact;
        List<Account> accountsUpdate = new List<Account>();
        List<Contact> contactsUpdate = new List<Contact>();
        Set<String> Existing_surveyCon_Set = new Set<String>();
        List<Contact> contactsList = new List<Contact>();
        List<CS_SurveyAccount__c> updateSurveyAccountRecords = new List<CS_SurveyAccount__c>();
        Database.Saveresult [] surveyCon_InsertResults;
        Database.Saveresult [] surveyAcc_InsertResults;
        //create a set to contain only the newly created survey accounts.
        Set<String> insertedSurveyAccounts = new Set<String>();
        //create a set to contain only the newly created survey contacts.
        Set<String> insertedSurveyContacts = new Set<String>();
        Set<String> insertedIds = Created_Con_SurveyCon_Map.keySet();
        
        if(akamContactsList != null && akamContactsList != ''){
            List<String> contactIds =akamContactsList.split('\\n');
            totalRecordsCount = contactIds.size();
            if(totalRecordsCount != null && totalRecordsCount > 50){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Too many contacts being updated at once. ');
                ApexPages.addMessage(myMsg);
                return null;
            }
            for( String partId : contactIds)
                tempStr = tempStr + ' \'' + partId.trim() + '\',';
            finalstr=tempStr.subString(0,tempStr.length()-1);     
            // Query Modified for CR 2137582 by ssawhney on 29/08/2013 - Survey Opt Out functionality changed       
            finalSOQLQuery = 'select Account.Id,Account.Name,Id,CS_CurrentlySurveyed__c,CS_AssociatedSurveyContact__c,Validation_Override__c,Akam_Contact_Id__c FROM Contact where AKAM_Contact_Id__c IN ( ' + finalstr + ' ) and Survey_Opt_Out__c = true and  (Network_contact__c = false OR (Network_contact__c = true AND Sales_Contact__c = true)) order by Account.Id ';
            
            contactsList =database.query(finalSOQLQuery);
            
            
            
            /*###########################
            1. Create new survey accounts , if any
            
            ############################# */
            //get all the survey accounts for the existing survey and add it to a map
            for(CS_SurveyAccount__c surveyAcc : [select Id,CS_Account__c from CS_SurveyAccount__c where CS_Survey__c =:surveySelected AND CS_IsDeleted__c = false]){
                Existing_Acc_surveyAccMap.put(surveyAcc.CS_Account__c,surveyAcc.Id);
            }
            for( Contact contact: contactsList ){
                 // prevent duplicate mailer account from being created for the same account
                if(Existing_Acc_surveyAccMap.get(contact.Account.Id) == null){ 
                    //This is a new Mailer Account, create one
                    surveyAccount = new CS_SurveyAccount__c();
                    surveyAccount.CS_Account__c = contact.Account.Id;
                    surveyAccount.CS_Survey__c = surveySelected;
                    insert_surveyAccounts_List.add(surveyAccount);
                }
                
            }
            try{
                updateSurveyAccountRecords.addAll(insert_surveyAccounts_List);
                surveyAcc_InsertResults = database.insert(updateSurveyAccountRecords,true);
                
                for(Database.saveresult res: surveyAcc_InsertResults){
                    if(res.isSuccess()){
                        insertedSurveyAccounts.add(res.getId());
                        countOfSurveyAccounts++;
                    }
                }
            }
            catch (DmlException e) {
                //System.assertEquals(e.getMessage(),null);
            }
            /*###########################
            2. For every new survey account created, update the account with the new survey account
            
            ############################# */
            
            
            // create a map of account Id to surveyAccount Id
            for (CS_SurveyAccount__c surveyAccountRecord : insert_surveyAccounts_List){
                if(insertedSurveyAccounts.contains(surveyAccountRecord.Id)){
                    Created_Acc_SurveyAccMap.put(surveyAccountRecord.CS_Account__c, surveyAccountRecord.Id);
                }
            }
            Set<String> accountIds = Created_Acc_SurveyAccMap.keySet();
            for(Account acc : [select Id,CS_SurveyAccount__c,Validation_Override__c from Account where Id IN :accountIds])
            {
                acc.CS_SurveyAccount__c = Created_Acc_SurveyAccMap.get(acc.Id);
                acc.Validation_Override__c = true;
                accountsUpdate.add(acc);
            }
            if(accountsUpdate.size() > 0)
            {
                try{
                    database.update(accountsUpdate);
                }
                catch(Exception e){
                    CS_SurveyException__c excpRec = new CS_SurveyException__c();
                    excpRec.CS_ExceptionMessage__c = 'Account update failed in CS_CreateSurveyRecordsController class. Please investigate';
                    excpRec.CS_Survey__c = surveySelected;
                    excpRec.CS_ExceptionInObject__c = 'CS_CreateSurveyRecordsController';
                    database.insert(excpRec);
                }
                
            }
            
            /*###########################
            3. Create new survey contacts
            
            ############################# */
            //clear the map, because it would have few 'Dummy Value' as values,
            Existing_Acc_surveyAccMap.clear();
            //re-query all the survey accounts for the existing survey and add it to the map
            for(CS_SurveyAccount__c surveyAcc : [select Id,CS_Account__c from CS_SurveyAccount__c where CS_Survey__c =:surveySelected AND CS_IsDeleted__c = false]){
                Existing_Acc_surveyAccMap.put(surveyAcc.CS_Account__c,surveyAcc.Id);
            }
            //query all existing survey contacts and put into a Set
            for(CS_SurveyContacts__c surveyCon : [select Id,CS_Contact__c from CS_SurveyContacts__c where CS_SurveyAccount__r.CS_Survey__c =:surveySelected AND CS_IsDeleted__c = false]){
                Existing_surveyCon_Set.add(surveyCon.CS_Contact__c);
            }
            for( Contact contact: contactsList){
                // If survey contact for a contact doesn't already exist, only then create a survey contact
                if(!(Existing_surveyCon_Set.contains(contact.Id))){
                    surveyContact = new CS_SurveyContacts__c();
                    surveyContact.CS_Contact__c = contact.Id;
                    surveyContact.CS_Account__c = contact.Account.Id;
                    surveyContact.CS_SyncStatus__c = 'New';
                    surveyContact.CS_SurveyAccount__c = Existing_Acc_surveyAccMap.get(contact.Account.Id);
                    surveyContact.CS_Survey__c = surveySelected;
                    surveyContact.CS_Classification__c = 'None';
                    surveyContact.CS_Type__c = 'Survey Invite';
                    surveyContact.CS_IsDeleted__c=false;
                    insert_SurveyContacts_List.add(surveyContact);
                }
                else{
                    CS_SurveyException__c excpRec = new CS_SurveyException__c();
                    excpRec.CS_ExceptionMessage__c = 'There already exists a survey contact for ' + contact.Akam_Contact_Id__c;
                    excpRec.CS_ErrorRecordId__c =  contact.Akam_Contact_Id__c;
                    excpRec.CS_Survey__c = surveySelected;
                    excpRec.CS_ExceptionInObject__c = 'CS_CreateSurveyRecordsController';
                    database.insert(excpRec);
                }
            }
            try{
                surveyCon_InsertResults = database.insert(insert_SurveyContacts_List);
                for(Database.saveresult res: surveyCon_InsertResults){
                    if(res.isSuccess()){
                        insertedSurveyContacts.add(res.getId());
                        countOfSurveyContacts++;
                    }
                }
            }
            catch (DmlException e) {
                //System.assertEquals(e.getMessage(),null);
            }
            
            /*###########################
            4. For every new survey Contact created, update the contact with the new survey contact and mark it as "Currently Surveyed"
            
            ############################# */
            
            
            // create a map of contact Id to surveyContact Id
            for (CS_SurveyContacts__c surveyContactRecord : insert_SurveyContacts_List){
                // only if survey contact was created newly, put it to the map and update the contact
                if(insertedSurveyContacts.contains(surveyContactRecord.Id)){
                    Created_Con_SurveyCon_Map.put(surveyContactRecord.CS_Contact__c,surveyContactRecord.Id);
                }
            }
            
            for(Contact con : [select Id,CS_AssociatedSurveyContact__c,Validation_Override__c,CS_CurrentlySurveyed__c from Contact where Id IN :insertedIds])
            {
                con.CS_AssociatedSurveyContact__c = Created_Con_SurveyCon_Map.get(con.Id);
                con.Validation_Override__c = true;
                con.CS_CurrentlySurveyed__c = true;
                contactsUpdate.add(con);
            }
            if(contactsUpdate.size() > 0)
            {
                try{
                    database.update(contactsUpdate);
                }
                catch(Exception e){
                    CS_SurveyException__c excpRec = new CS_SurveyException__c();
                    excpRec.CS_ExceptionMessage__c = 'Contact update failed in CS_CreateSurveyRecordsController class. Please investigate';
                    excpRec.CS_Survey__c = surveySelected;
                    excpRec.CS_ExceptionInObject__c = 'CS_CreateSurveyRecordsController';
                    database.insert(excpRec);
                }
            }
        }
        return null;
        
    }
    
    /* Author: Jayalakshmi A
      Description: This function logically deletes Survey Contacts and Survey Accounts. CR 1639120
      Created Date: 06/04/2012 
      Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
    */
    
    public PageReference removeContactsFromSurvey() 
    { 
        
        String tempStr ='';
        String finalstr = '';
        String finalSOQLQuery='';       
        List<Contact> contactsList = new List<Contact>();
        List<CS_SurveyContacts__c> surveyContactsIsDeleted = new List<CS_SurveyContacts__c>();
        List<String> contactIds = new List<String>();
        Set<String> isDeletedSurveyContactIds = new Set<String>();
        String tempIdList = '';
        String finalIdList = '';
        List<CS_SurveyContacts__c> surveyContactIsDeletedUpdates = new List<CS_SurveyContacts__c>();
        List<Id> surveyContactsDelId = new List<Id>();
        Database.saveResult[] surveyContactUpdate;
        List<Contact> removeAssociationContact = new List<Contact>();
        String isDeletedSurveyContacts = '';
                     
        Set<Id> deletedSurveyAccounts = new Set<Id>();
        List<CS_SurveyAccount__c> surveyAccountsToBeDeleted = new List<CS_SurveyAccount__c>();
        Database.Saveresult[] removeAccountAssociation;
        List<Id> surveyAccDelIds = new List<Id>();
        List<Account> accountsToBeDeleted = new List<Account>(); 
        Database.SaveResult[] associationContactUpdate;  
        
        try
        {
            if(akamContactsList != null && akamContactsList != '')
            {
                contactIds =akamContactsList.split('\\n');
                totalRecordsCount = contactIds.size();
                
                if(totalRecordsCount != null && totalRecordsCount > 50)
                {
                  ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Too many contacts being updated at once. ');
                  ApexPages.addMessage(myMsg);
                  return null;
                }
                for( String partId : contactIds)
                    tempStr = tempStr + ' \'' + partId.trim() + '\',';
                    
                finalstr=tempStr.subString(0,tempStr.length()-1);                             
                //Query Modified by ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
                finalSOQLQuery = 'select CS_AssociatedSurveyContact__c FROM Contact where AKAM_Contact_Id__c IN ( ' + finalstr + ' ) and Survey_Opt_Out__c = true and  (Network_contact__c = false OR (Network_contact__c = true AND Sales_Contact__c = true))';               
                contactsList =database.query(finalSOQLQuery);              
                
                
                /*Set isdeleted = true at survey contacts.*/
                for(Contact contact:contactsList)
                {
                    isDeletedSurveyContactIds.add(contact.CS_AssociatedSurveyContact__c);
                }
                
                for( String tempId : isDeletedSurveyContactIds)
                    tempIdList = tempIdList + ' \'' + tempId.trim() + '\',';
                    
                finalIdList=tempIdList.subString(0,tempIdList.length()-1);
                
                isDeletedSurveyContacts = 'select Id, CS_IsDeleted__c from CS_SurveyContacts__c where Id in(' + finalIdList +') and CS_IsDeleted__c = false';
                
                surveyContactsIsDeleted = database.query(isDeletedSurveyContacts);
                
                for(CS_SurveyContacts__c surveyContacts:surveyContactsIsDeleted)
                {  
                    surveyContacts.CS_IsDeleted__c = true;
                    surveyContactIsDeletedUpdates.add(surveyContacts);  
                }
                
                if(surveyContactIsDeletedUpdates.size()>0)
                    surveyContactUpdate = database.update(surveyContactIsDeletedUpdates);
                    
                countOfSurveyContacts = 0;
                for(Database.SaveResult successId:surveyContactUpdate)
                {
                     surveyContactsDelId.add(successId.getId());
                     countOfSurveyContacts++;
                }
                
                for(Contact con:[select Id, CS_AssociatedSurveyContact__c, CS_CurrentlySurveyed__c from Contact where CS_AssociatedSurveyContact__c in :surveyContactsDelId])
                {
                    con.CS_AssociatedSurveyContact__c = null;
                    con.CS_CurrentlySurveyed__c = false;
                    removeAssociationContact.add(con);
                }
                
                if(removeAssociationContact.size()>0)
                { 
                    associationContactUpdate = database.update(removeAssociationContact);
                    //System.assertEquals(associationContactUpdate,null);
                }
              
              /*###########################
              1. delete survey accounts , if any
              
              ############################# */
                                      
              
              for(CS_SurveyContacts__c surveyCon:[select CS_SurveyAccount__c, CS_SurveyAccount__r.CS_InvitationsSent__c from CS_SurveyContacts__c where (CS_Survey__c = :surveySelected and CS_IsDeleted__c = true)])
              {
                    if(surveyCon.CS_SurveyAccount__r.CS_InvitationsSent__c == 0)
                        deletedSurveyAccounts.add(surveyCon.CS_SurveyAccount__c);
              }
              
              for(CS_SurveyAccount__c surveyAcc:[select Id,CS_IsDeleted__c from CS_SurveyAccount__c where Id in :deletedSurveyAccounts and CS_IsDeleted__c = false])
              {   
                    surveyAcc.CS_IsDeleted__c = true;
                    surveyAccountsToBeDeleted.add(surveyAcc);     
              }
              
              if(surveyAccountsToBeDeleted.size()>0)
                removeAccountAssociation = database.update(surveyAccountsToBeDeleted);
              countOfSurveyAccounts = 0;
              for(Database.Saveresult updateAccount:removeAccountAssociation)
              {
                    surveyAccDelIds.add(updateAccount.getId());
                    countOfSurveyAccounts++;
              }
              
              for(Account acc:[select Id,CS_SurveyAccount__c from Account where CS_SurveyAccount__c in :surveyAccDelIds])
              {
                    acc.CS_SurveyAccount__c = null;
                    accountsToBeDeleted.add(acc);
              }
              
              if(accountsToBeDeleted.size()>0)
                    database.update(accountsToBeDeleted);
            
            }
        }
        catch(Exception e)
        {
            CS_SurveyException__c surveyException = new CS_SurveyException__c();
            surveyException.CS_ExceptionMessage__c = e.getMessage();
            surveyException.CS_Survey__c = surveySelected;
            insert surveyException;
        }
        return null;
    }
}