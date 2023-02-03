/***
    ContactTriggerClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class houses business logic to be implemented on Contact DML triggers.
            The following functionlatiy is achieved : 
            1. Only for Integration users : Use Account.Associated_Account_Id to populate Contact.AccountId
            2. Check for duplicates by making Contact.Name + Contact.Email unique.
    
    @History
  --Developer          --Date      --Change
  Karteek Kumar M      01/03/2010    Cretaed class.
  Karteek Kumar M      12/04/2010     Check duplicates.
  Karteek Kumar M      15/04/2010    Gave "Valdiation Override option" and "First Run logic" for CheckDuplicates()
  Karteek Kumar M      16/04/2010    Gave "Valdiation Override option" and "First Run logic" for AssociatedAccountIDMap() and SyncLeadContactAccount()
  Karteek Kumar M      09/08/2010    Getting rid of SyncLeadContactAccount() as it was inefficient.
                      The logic is convered in the changes made for CR 699202 Ability to Merge Contacts.
  Vinayendra T N      19/07/2012    CR 1700212 CRM: Error message when duplicate contact created
                                    Changed logic to check for duplicates only when same email is found but accross all accounts.
  ALI KM             06/Jul/2012    CR 1741378 Manage scores during Contact merge process
                      - 1. Added 2 new fields: 
                        a. Merged ContactID : holds the loosing Contact's AKAM Contact ID 
                        b. Scores Source ContactID: holds the AKAM Contact ID of Scores source contact.
                      2. Both are Text area fields can hold 500 chars
                      3. With the assumption that all scores (listed below) will come from the same
                        Contact, am considering below Scores before updating the field in 1b.
                        - Aqua ADS Activity Score
                        - Aqua DSA Activity Score
                        - Aqua Mobile Activity Score
                        - Kona Activity Score
                        - Sola Activity Score
                        - Terra Alta Activity Score
                        - Terra Steelhead Activity Score
                        - Cumulative Activity Score
                      4. What should happen if winning record is involved in another contact merge ? 
                        a. If its the winner, am appending the lost contact's ID to Merged ContactID field.
                        b. If its the loser then its Contact ID and any Contact IDs in MergedContactID
                        should be added to Winner.Merged_ContactID.
  Ruchika Sharma       26/02/2015       CR 2919927 Create Contact Accout Pick list limited to User Account and children
                      restrict the partner to create a contact on other account (for which partner should not have access to create account like customer account)
                           except the account associated with partner contact or children of that account
                           Added methods : restrictContactCreationByPartner and getContactsAccountHierarchy
  Shivam Verma      27/04/15    CR 2932653 - Partner Accounts ot reflecting the right number of Licenses
                      - Added the method updateCurrentLicencesOnAccount 
*/
public class ContactTriggerClass{

  public static Boolean checkDuplicatesFirstRunFlag = true;
  public static Boolean AssociatedAccountIDMapFirstRunFlag = true;
  public static Boolean prepareAccoutsForRecomputationFirstRun = true;
  //public static Boolean populateVerticalFieldsFromAccountFirstRunFlag = true;
  // @ali: Contact merge code
  public static Boolean updateMasterContactFirstRunFlag=true;
  public static Boolean isMergeTriggered=false;
  public static Boolean contactAfterDeleteFirstRunFlag=true;
  public static Boolean contactBeforeUpdateFirstRunFlag=true;
  public static Map<Id,List<Id>> masterToLostContactsMap= new Map<Id,List<Id>>();
  public static Map<Id,Contact> lostContactMap=new Map<Id,Contact>(); 
  public static Map<ID,Account> accHierarchyMap = new Map<ID,Account>();
  
  /**
   initializeContactMerge(Contact[] triggerOld)
     Entry Criteria: This method is called in After Delete trigger during Contact Merge for Loosing Contacts.
     - Capturing the Winner -> Loosing Contact Static Map
     - Capturing the Loosing Contact Details Static Map
     - Setting the isMergeTriggered if Contact Merge transaction.
  */
  public static void initializeContactMerge(Contact[] triggerOld)
  {
    if(!contactAfterDeleteFirstRunFlag)
      return;
    
    for (Contact con : triggerOld)
    {  
      if (con.MasterRecordId!=null)
      {  
        isMergeTriggered=true;
        lostContactMap.put(con.Id,con);
        if (masterToLostContactsMap.containsKey(con.MasterRecordId))
          masterToLostContactsMap.get(con.MasterRecordId).add(con.Id);
        else
          masterToLostContactsMap.put(con.MasterRecordId, new List<Id>{con.Id});
      }
    }
    /*
    // DEBUG
    System.Debug('###Merge Contact###');
    System.Debug('isMergeTriggered=' + isMergeTriggered);
    System.Debug('masterToLostContactsMap=' + masterToLostContactsMap);
    System.Debug('lostContactMap=' + lostContactMap);
    */
    updateMasterContactFirstRunFlag=false;
    //System.Debug('updateMasterContactFirstRunFlag=' + updateMasterContactFirstRunFlag);
    
  }

  
  /**
   updateContactMergeFields(Contact[] triggerNew)
     Entry Criteria: This method is called in After Update trigger during Contact Merge for Winning Contact.
     - Calculating and updating the Winner.Merged_ContactID__c & Winner.Scores_Source_ContactID__c fields.
  */
  public static void updateContactMergeFields(Contact[] triggerNew)
  {
    /*
    // DEBUG
    System.Debug('Inside updateContactMergeFields');
    System.Debug('isMergeTriggered=' + isMergeTriggered);
    System.Debug('contactBeforeUpdateFirstRunFlag=' + contactBeforeUpdateFirstRunFlag);
    System.Debug('masterToLostContactsMap.size()=' + masterToLostContactsMap.size());
    */
    
    // If the transaction is not from Merge Contacts, exit.
    if (!isMergeTriggered || !contactBeforeUpdateFirstRunFlag || masterToLostContactsMap.size()<1)
      return;
    
    for (Contact con : triggerNew)
      {
        Boolean foundScoreContactId = false;
        //System.Debug('Contact Record Before=' + con);
        if (!masterToLostContactsMap.containsKey(con.Id))
          continue;
        
        for (Id conId : masterToLostContactsMap.get(con.Id))
        {
          // update the winning contacts Merged ContactId field.
          if (con.Merged_ContactID__c==null || con.Merged_ContactID__c=='')
            con.Merged_ContactID__c= lostContactMap.get(conId).AKAM_Contact_ID__c;//conId;
          else
            con.Merged_ContactID__c += ',' + lostContactMap.get(conId).AKAM_Contact_ID__c;//conId;
          
          //System.Debug('lostContactMap.get(conId).Merged_ContactID__c=' + lostContactMap.get(conId).Merged_ContactID__c);
          if(lostContactMap.get(conId).Merged_ContactID__c!=null && lostContactMap.get(conId).Merged_ContactID__c!='')
              con.Merged_ContactID__c+= ',' + lostContactMap.get(conId).Merged_ContactID__c;
          
          //System.Debug('con.Merged_ContactID__c=' + con.Merged_ContactID__c);  
            
          if (foundScoreContactId)
            continue;      
            
          // compare and update the Scores Source ContactId
          if (lostContactMap.get(conId).Aqua_ADS_Activity_Score__c==con.Aqua_ADS_Activity_Score__c && lostContactMap.get(conId).Aqua_DSA_Activity_Score__c==con.Aqua_DSA_Activity_Score__c
            && lostContactMap.get(conId).Aqua_Mobile_Activity_Score__c==con.Aqua_Mobile_Activity_Score__c && lostContactMap.get(conId).Kona_Activity_Score__c==con.Kona_Activity_Score__c
            && lostContactMap.get(conId).Sola_Activity_Score__c==con.Sola_Activity_Score__c && lostContactMap.get(conId).Terra_Alta_Activity_Score__c==con.Terra_Alta_Activity_Score__c
            && lostContactMap.get(conId).Terra_Steelhead_Activity_Score__c==con.Terra_Steelhead_Activity_Score__c && lostContactMap.get(conId).Cumulative_Activity_Score__c==con.Cumulative_Activity_Score__c)
          {
            con.Scores_Source_ContactID__c = lostContactMap.get(conId).AKAM_Contact_ID__c;//conId;
            foundScoreContactId=true;
          }
          else
            con.Scores_Source_ContactID__c = con.AKAM_Contact_ID__c;//con.Id;
            
          //System.Debug('con.Scores_Source_ContactID__c=' + con.Scores_Source_ContactID__c);  
              
        }        
        
        //System.Debug('con.Merged_ContactID__c BEFORE CLEANUP=' + con.Merged_ContactID__c);
        
        // Clean up the Merged_ContactID field as it could have duplicates.
        con.Merged_ContactID__c = removeDupContactIds(con.Merged_ContactID__c, ',');
        
        //System.Debug('con.Merged_ContactID__c AFTER CLEANUP=' + con.Merged_ContactID__c);
        //System.Debug('Contact Record After=' + con);
      }
    //System.Debug('toUpdateMasterContacts=' + toUpdateMasterContacts);
    
    contactBeforeUpdateFirstRunFlag=false;
  }

  public static void associateContactToAccount(List<Contact> contactsList) {
        
        Map<String,List<String>> mapOfDomainAndAssociatedAccount = new Map<String,List<String>>();
        Map<Id,Account> accountIdAccMap = new Map<Id,Account>();
        List<Id> accountsIds = new List<Id>();
        List<String> domainsFromContacts = new List<String>();
        String emailValue = '';
        String domainValue = '';

        /* Creating list of domains from all contacts 
         * The list is used to query the related domain records from Domain__c object
         */
        for (Contact cont:contactsList) {
            emailValue = cont.email;
            if (emailValue != null && !String.isEmpty(emailValue)) {
                    integer index = emailValue.indexOf('@');
                    domainValue = emailValue.substring(index + 1,emailValue.length());
                    if (domainValue != null) {
                        domainsFromContacts.add(domainValue);
                    }
            }
        }
        

        List<Domain__c> domainsList = [Select id,name,Associated_Account__c
                                       From Domain__c where name in:domainsFromContacts];

        /* Creating mapping of domain name and associated accounts 
         * The list is used to query the related domain records from Domain__c object
         */
        if (domainsList != null && domainsList.size() > 0) {
            
            for (Domain__c dom:domainsList) {
                //add trim
                ////remove all occurances
                if (!mapOfDomainAndAssociatedAccount.containsKey(dom.name.trim()) && dom.Associated_Account__c != null) {
                    mapOfDomainAndAssociatedAccount.put(dom.name.trim(), new List<String>{dom.Associated_Account__c});
                    accountsIds.add(dom.Associated_Account__c);
                } else if (dom.Associated_Account__c != null){
                    mapOfDomainAndAssociatedAccount.get(dom.name.trim()).add(dom.Associated_Account__c);
                    accountsIds.add(dom.Associated_Account__c);
                }
            }

            System.debug('Map of domain and associated account :'+mapOfDomainAndAssociatedAccount);
            
            String associationCriteria = GSMUtilClass.getGSMSettingValue('ContactAssociation_Criteria');
            String[] criterias = associationCriteria.split(',');
            System.debug('Criterias :'+criterias);
            
            String accountQuery = 'Select id,';
            
            for (String crt:criterias) {
                String [] criteriasValues = crt.split('-');
                accountQuery += criteriasValues[0] + ',';             
            }
            
            accountQuery = accountQuery.substring(0,accountQuery.length()-1);
            //accountQuery += ' From Account where id IN ('+SOQL_IDs + ')';
            accountQuery += ' From Account where id in:accountsIds';
            System.debug('Account Query :'+accountQuery);
            
            List<sObject> accountsList;
            List<Account> accountsQueried = new List<Account>();
            if (accountsIds.size() > 0) {
                accountsList = Database.query(accountQuery);
            }
            
            for (sObject acc:accountsList) {
                Account account = (Account)acc;
                accountIdAccMap.put(account.id, account);
            }
            
            String domain = '';
            String email = '';
            
            for (Contact c:contactsList) {
                email = c.email;
                if (email != null && !String.isEmpty(email)) {
                    integer index = email.indexOf('@');
                    domain = email.substring(index + 1,email.length());
                    System.debug('Domain :'+domain);
                    List<String> associatedAccountIds = mapOfDomainAndAssociatedAccount.get(domain);
                    if (associatedAccountIds != null && associatedAccountIds.size() > 0) {
                        
                        /* Get Account records from IDs
                         * And check for the Criterias
                         */
                        List<Account> accountsListForDomian = new List<Account>();
                        List<Account> accountsListMatchingCriteria = new List<Account>();

                        for (String accId:associatedAccountIds) {
                            accountsListForDomian.add(accountIdAccMap.get(accId));
                        }
                        System.debug('Account list for domain :'+domain + ' :::: '+accountsListForDomian);

                        for (Account ac:accountsListForDomian) {

                            for (String crt:criterias) {
                                String [] criteriasValues = crt.split('-');
                                //sObject acc = (sObject)accountIdAccMap.get(associatedAccount);
                                sObject acc = (sObject)ac;
                                String accFieldCriteria = (String)acc.get(criteriasValues[0]);
                                sObject con = (sObject)c;
                                if (criteriasValues[1].equalsIgnoreCase('equals')) {
                                    if (accFieldCriteria.equalsIgnoreCase((String)con.get(criteriasValues[2]))) {
                                        //c.AccountId = associatedAccount;
                                        //c.Account_Associated_by_Domain__c = true;
                                        accountsListMatchingCriteria.add(ac);
                                    }
                                } else if (criteriasValues[1].equalsIgnoreCase('like')) {
                                    if (accFieldCriteria.contains((String)con.get(criteriasValues[2]))) {
                                        //c.AccountId = associatedAccount;
                                        //c.Account_Associated_by_Domain__c = true;
                                        accountsListMatchingCriteria.add(ac);
                                    }
                                }
                                
                            }
                        }
                        if (accountsListMatchingCriteria.size() == 1) {
                            c.AccountId = accountsListMatchingCriteria[0].id;
                            c.Account_Associated_by_Domain__c = true;
                        }
                    }
                }
            }
        }
        
    } 
  
  /**
   removeDupContactIds(String pCSVString, String pSeparator)
   Comments: This is a helper method that gets rid of duplicate values in a string separated by comma/colon/etc... also it restricts the length of string to 500 chars.
     @param1: pCSVString -> String that needs to be cleaned up.
     @param2: pSeparator -> Separator (comma,colon, semicolon) that will be used to split String in Param1. 
     @return: retString -> String separated by pSeparator sans duplicate entries.
  */
  public static String removeDupContactIds(String pCSVString, String pSeparator)
  {
    String retString = '';
    String[] tempStr = pCSVString.split(pSeparator);
    for (String str : tempStr)
    {
      if (retString == '')
        retString = str;
      else if (!retString.contains(str))
        retString += pSeparator + str;
    }
    
    System.debug('return retString BEFORE TRIM=' + retString);
    if (retString.length() > 500)
    {  
      String strtemp = retString;
      retString = strtemp.substring(0,500);
    }
    System.debug('return retString AFTER TRIM=' + retString);
    return retString;
  }
  
  /**
     CheckDuplicates(Contact[] triggerNew)
     CR 1700212 CRM: Error message when duplicate contact created
     1.    Need to remove the validation that checks for duplicate contacts tied to
        the same account.
     2.    Need to create a new validation that displays an error when the new contact
         has the same email as another contact in SFDC, not just on the account.
     3.    Only exception should be Dave Rossignol's user – he needs to be able to
      create duplicate contacts.  He will create duplicate contacts tied to a "dummy"
      account if his script detects duplicate contacts.  Marketing Ops will then
      merge all these duplicate contacts into one contact
     
  */
  public static void CheckDuplicates(Contact[] triggerNew)
  {
    if(!checkDuplicatesFirstRunFlag)
      return;
    Map<String, Contact> newConMap = new Map<String, Contact>();
    // Commenting out check for ERM_WEB_ as part of Internal House Cleaning: Clean up AWE references in Code & Configurations :CR 3046311

    //Boolean showError=true;
    //if(GSM_Custom_Settings__c.getInstance('ContactTriggerClass#ErrorException').Value__c.contains(Userinfo.getUserId()) || GSM_Custom_Settings__c.getInstance('ContactTriggerClass#ErrorException').Value__c.contains(Userinfo.getProfileId()))
    //showError=false;
    for(Contact con: triggerNew)
    {
      if(con.Validation_Override__c != true)
      {
        if(newConMap.get(con.Email)!=null)
        {
          //if(showError==true)
          con.Email.AddError('A contact with Email = '+con.email+' already exists in the same list.');
        }
        else
        {
          newConMap.put(con.email,con);
        }
      }
    }
    if(newConMap.size() > 0)
    {
      for(Contact existingCon: [select id,Email from Contact where Email IN :newConMap.keySet() and Id NOT IN :triggerNew])
      {
        Contact tempNewCon = null;
        if(newConMap.get(existingCon.Email)!=null)
        tempNewCon = newConMap.get(existingCon.Email);
        if(tempNewCon != null)
        {
          //if(showError==true)
                    //{
                        String errorMessage = 'A contact with Contact Email = '+existingCon.Email+' already exists in the system.';
                        if(UserInfo.getProfileId().containsIgnoreCase(GsmUtilClass.getPRMSettingValue('Partner_Admin_Id'))) // SFDC-2391 
                            errorMessage += ' Please contact partnersupport@akamai.com for assistance.';
                        tempNewCon.Email.addError(errorMessage);
                    //}
        }
      }
    }
    
    checkDuplicatesFirstRunFlag = false;
  }  
  /**
     AssociatedAccountIDMap(Contact[] contacts)
     The function is called only for Integration users.
     This function uses Contact.Associated_AKAM_AccountId to query for an Account and populate Contact.AccountId
     1. An error is thrown if Contact.Associated_AKAM_AccountId = null
     2. An error is thrown if Contact.Associated_AKAM_AccountId does not map to a valid Account.
     3. Else, Contact.AccountId is populated with the queried Account.Id
  */
  public static void AssociatedAccountIDMap(Contact[] contacts, String marketoIntegrationProfileId)
  {
    if(!AssociatedAccountIDMapFirstRunFlag)
      return;
    Map<String,Id> Associated_AKAM_AccountIdMap = new Map<String,Id>();
    Set<String> Associated_AKAM_AccountId_Set = new Set<String>();
    for(Contact con:contacts)    
    {
      //An error is thrown if Contact.Associated_AKAM_AccountId = null
      if((con.Associated_AKAM_Account_Id__c == null || con.Associated_AKAM_Account_Id__c == '') && !marketoIntegrationProfileId.contains(UserInfo.getProfileId()))
        con.Associated_AKAM_Account_Id__c.addError('Associated_AKAM_Account_Id__c is mandatory for Integration.');

      if(!String.isBlank(con.Associated_AKAM_Account_ID__c))
          Associated_AKAM_AccountId_Set.add(con.Associated_AKAM_Account_Id__c);
    }
    for(Account acc:[select Id,AKAM_Account_Id__c from Account where AKAM_Account_Id__c IN :Associated_AKAM_AccountId_Set])
      Associated_AKAM_AccountIdMap.put(acc.AKAM_Account_Id__c,acc.Id);
    Id tempAccountId;
    for(Contact con:contacts)
    {
      if(con.Associated_AKAM_Account_Id__c == null || con.Associated_AKAM_Account_Id__c == '')
        continue;
      else
      {
        tempAccountId = Associated_AKAM_AccountIdMap.get(con.Associated_AKAM_Account_Id__c);
        if(tempAccountId == null)
          con.Associated_AKAM_Account_Id__c.addError('Account with AKAM_Account_Id : '+con.Associated_AKAM_Account_ID__c+' does not exist' );
        else
          con.AccountId = tempAccountId;
      }
    }  
    AssociatedAccountIDMapFirstRunFlag = false;
  }

  //CR 2919927 : restrict the partner to create a contact on other account (for which partner should not have access to create account like customer account) except the account associated with partner contact or children of that account
  public static void restrictContactCreationByPartner(String userId){
    User usr = [select AccountId__c from user where id = :userId];
            if(usr!=null && Usr.AccountId__c!=null){
                Id userAccId = Usr.AccountId__c;
                getContactsAccountHierarchy(userAccId);
                System.debug('Account Hierarchy for acount: '+userAccId+' is: '+ContactTriggerClass.accHierarchyMap);
               }
  }

  public static void getContactsAccountHierarchy(Id userAccId){
    if(userAccId!=null){
    //Query all the children of User acc id, which can only be valid accounts to create contact by partner.
                Map<ID,Account> childAccs = new Map<ID,Account>([select id,parent.parent.parent.parent.parentId from Account where id = :userAccId or parentId = :userAccId or parent.ParentId = :userAccId 
                                        or parent.parent.parentId =  :userAccId
                                        or parent.parent.parent.parentId =  :userAccId
                                        or parent.parent.parent.parent.parentId =  :userAccId]);
                
                accHierarchyMap.putAll(childAccs);
                //Account fifthParentAvailable = [select id from Account where parent.parent.parent.parent.parentId = :userAccId];
                Account fifthParentAvailable;
                for(Account acc : childAccs.values()){
                  if(acc.parent.parent.parent.parent.parentId == userAccId)
                  fifthParentAvailable = acc;
                }
                if(fifthParentAvailable!=null){
                  getContactsAccountHierarchy(fifthParentAvailable.id);
                }
            }
  }

  //Sonali Tandon - -- CR 3094031 -- Copy account vertical, subvertical onto contact.
  // MARIT-1597
  /*
  public static void populateVerticalFieldsFromAccountForContact(Contact[] triggerNew)
  {
     if(!populateVerticalFieldsFromAccountFirstRunFlag)
            return;

    List<Id> listOfContactIds = new List<Id>();
    List<Contact> listOfContactsToUpdate = new List<Contact>();
    
    for(Contact contact : triggerNew)
    {
      listOfContactIds.add(contact.Id);
    }
    System.debug('List of contact ids' + listOfContactIds);

    // Exlcude accounts : WWW Lead Gen (DO NOT DELETE!),WWW Pending Lead Gen (Do Not Delete!),WWW Bad Data (Do Not Delete)
    String exclusionAccounts = GsmUtilClass.getGSMSettingValue('AccTriggerCls_ExclusionAccountList'); //SFDC-2391
                Set<String> exclusionList= new Set<String>();
                if(exclusionAccounts!= null ){
                        exclusionList.addAll(exclusionAccounts.split(','));
                }
        System.debug('List of accounts to be excluded' + exclusionList);
     
        List<Contact> listOfContacts = [Select Validation_Override__c,Account.Name,Akamai_Vertical__c,Sub_Vertical__c, Account.Vertical__c, Account.Sub_Vertical__c from Contact where Id in : listOfContactIds and Contact.Account.Name NOT in :exclusionList];
        if(listOfContacts.size()>0)
        {
          for(Contact contact : listOfContacts)
          {

              if(contact.Account.Vertical__c!='' && contact.Account.Vertical__c!=null && contact.Account.Vertical__c!='Akamai Internal')
              {
                contact.Akamai_Vertical__c = contact.Account.Vertical__c;
                contact.Sub_Vertical__c = contact.Account.Sub_Vertical__c;  
                contact.Validation_Override__c = true;
                listOfContactsToUpdate.add(contact);
              }
              
          }
        }
         if(listOfContactsToUpdate.size()>0)
          update listOfContactsToUpdate;
        populateVerticalFieldsFromAccountFirstRunFlag = false;
       
  }*/

  public static void checkDoubleBytesValues(List<Contact> conList) {
        
        List<Id> accountIds = new List<Id>();
        //Map<Id,String> accountIdNameMap = new Map<Id,String>();
        for (Contact c:conList) {
            accountIds.add(c.AccountId);
        }
        
        /*List<Account> accList = [Select id,name from Account where id IN:accountIds];
        for (Account a:accList) {
            accountIdNameMap.put(a.id, a.name);
        }*/

        Set<String> asciiCheckFields = new Set<String>{'FirstName','LastName'}; //MARIT-872, if first and last name is non ascii on update, revert back to old values
        String restrictedProfiles = MarketingUtilClass.getMarketingSettingsValue('RestrictedProfilesForNameUpdates');
        Boolean isMarketoUpdate = Trigger.isUpdate && restrictedProfiles.contains(UserInfo.getProfileId());
        System.debug('isMarketoUpdate='+isMarketoUpdate);
        for (Contact c:conList) {
            if(isMarketoUpdate && c.Active_Portal_Login__c){
              Contact oldCon = (Contact)Trigger.oldMap.get(c.Id);
              if(Util.hasChanges(asciiCheckFields,oldCon,c)){
                String contactName = c.FirstName+' '+c.LastName;
                if(!contactName.isAsciiPrintable()){
                    c.FirstName = oldCon.FirstName;
                    c.LastName = oldCon.LastName;
                    System.debug('Contact Name Not Ascii Printable='+c.Id+' '+contactName);
                }
              }
            }
            if (checkDoubleByte(c.FirstName) || checkDoubleByte(c.LastName) || checkDoubleByte(c.Company__c)
                || checkDoubleByte(c.Title) ) {
                    c.Double_Byte__c = true;
                } else {
                    c.Double_Byte__c = false;
                }
        }

    }
    
    private static Boolean checkDoubleByte(String text) {
        if (text != null) {
          //Replaceing all the space and no break sspace
          text = text.trim().replaceAll(' ','');
          //.replaceAll(' ','');
          //System.debug('Text :'+text + '   :::: Text length :'+text.length() + '   ::::::  blob length :'+Blob.valueof(text).size());
            if (text.length() != Blob.valueof(text).size()){
                System.debug('Text : '+text + ' is double byte');
                return true;
            } else {
                System.debug('Text :'+text + ' is single byte');
                return false;
            }
        } else {
            return false;
        }
        
    }

    //Added as part of SFDC-2250
    public static Contact updateRebateField(Contact con, Account acc) {
        
        DateTime acceptedDate=acc.Rebate_TC_Accepted_At__c;
        DateTime rejectedDate=acc.Rebate_TC_Rejected_At__c;
        // Anand Hegde - remove Validation_Override__c CR 2639298
        //con.Validation_Override__c=true;
        if((acc.Rebate_TC_Status__c=='' ||acc.Rebate_TC_Status__c==null))
        {
            con.isRebateTCToShow__c=true;
            con.Rebate_TC_Status__c='';
        }
        else if((acc.Rebate_TC_Status__c=='Accepted' && (acceptedDate!=null && acceptedDate.year()<DateTime.now().year())) 
                || (acc.Rebate_TC_Status__c=='Rejected' && (rejectedDate!=null && rejectedDate.year()<DateTime.now().year() )))
        {
            con.isRebateTCToShow__c=true;
            con.Rebate_TC_Status__c=acc.Rebate_TC_Status__c;
        }
        else
        {
            con.isRebateTCToShow__c=false;
            con.Rebate_TC_Status__c=acc.Rebate_TC_Status__c;
        }
        return con;

    }

    //Added as part of SFDC-2250
    public static List<Contact> updateMailingField(List<Contact> contactsTriggerNew, Map<Id,Contact> contactsTriggerOldMap) {
        
             String specialChars = GSMUtilClass.getGSMSettingValue('AddressDoctor_SpecialCharactersPhone'); //SFDC-2391
             for (Contact c: contactsTriggerNew) {
                String newEmail = c.Email;
                String newPhone = c.phone;

                if (contactsTriggerOldMap.get(c.id).Email != newEmail) {
                    c.Email_Hygiene__c = null;
                    c.Email_NetProtected__c = false;
                    c.Email_Net_Protected_By__c = null;
                    c.Email_Reason_Code__c = null;
                    c.Email_Reason_Description__c = null;
                    c.Email_Status_Description__c = null;
                    c.Email_Status_Number__c = null;
                    c.Email_Verified_by_StrikeIron__c = false;
                    c.Email_Verified_Date__c = null;
                }

                
                String oldPhone = contactsTriggerOldMap.get(c.id).Phone;
                
                //String specialChars = ' !@#$%^&*()-_=+";:{}<>,.?/';
                for(integer i=0; i<specialChars.split('|').size(); i++) {
                    if (oldPhone != null && oldPhone != '') {
                        oldPhone = oldPhone.replace(specialChars.split('|')[i], '');
                    }
                    if (newPhone != null && newPhone != '') {
                        newPhone = newPhone.replace(specialChars.split('|')[i], '');
                    }
                }
                
                if (oldPhone != newPhone) {
                    c.Phone_Status_Code__c = null;
                    c.Phone_Status_Description__c = null;
                    c.Phone_Verification_Date__c = null;
                    c.Phone_Verified_By_StrikeIron__c = false;
                }
            }
           return contactsTriggerNew;
    }

  //Added as part of SFDC-2250
    public static List<Contact> checkForAssociateContactToAccount(List<Contact> contactsTriggerNew, Map<Id,Contact> contactsTriggerOldMap) {
        
             List<Contact> contactListforAccAutomation = new List<Contact>();
             String wwwLeadGenAccountId = GSMUtilClass.getGSMSettingValue('ContactAssociation_WWWLeadGenAccountId');
             String isAccountAssociationEnabled = GSMUtilClass.getGSMSettingValue('ContactAssociation_Enabled');
        for (Contact con: contactsTriggerNew) {
            if (wwwLeadGenAccountId !=  null && isAccountAssociationEnabled.equalsIgnoreCase('true')) {
                if (con.AccountId != Null && wwwLeadGenAccountId.contains(con.AccountId) &&
                    (Trigger.isInsert || (Trigger.isUpdate && ((con.email != null && con.email != contactsTriggerOldMap.get(con.Id).email) || (con.MailingCountry != null && con.MailingCountry != contactsTriggerOldMap.get(con.Id).MailingCountry)))))
                    contactListforAccAutomation.add(con);
            }
        }
        if (contactListforAccAutomation.size() > 0)
            associateContactToAccount(contactListforAccAutomation);

           return contactsTriggerNew;
    }

    /* CR 2841150 Detect Language for the combination of FirstName and LastName
     */
    public static void detectLanguageOnContact(List<Contact> contactsList, Map<Id,Contact> contactsTriggerOldMap, Boolean isUpdate) {

      if (contactsList != null && contactsList.size() > 0) {
        for (Contact c: contactsList) {
                String lastName = c.LastName;
                String firstName = c.FirstName;

                if (!isUpdate || (isUpdate && (contactsTriggerOldMap.get(c.id).LastName != lastName) || (contactsTriggerOldMap.get(c.id).FirstName != firstName))) {
                  String language = LanguageDetectionClass.detectLanguageForCombination(firstName, lastName);
                  c.UserInputLanguage__c = language;
                }
            }
      }
    }

    public static void preProcessBeforeInsertUpdate(List<Contact> contactsTriggerNew, Map<Id,Contact> contactsTriggerOldMap) {
      
        List<Contact> checkDuplicateList = new List<Contact>();

        for(Contact con: contactsTriggerNew)
        {
            // If new Contact or Contact.Name/ Email is changing, then check for duplicates
            Contact oldContact;

            if(!Trigger.isInsert)
            {
                oldContact = contactsTriggerOldMap.get(con.Id);
            }
            if(con.email!=null && (Trigger.isInsert || (!Trigger.isInsert && con.Email != oldContact.Email)))
                checkDuplicateList.add(con);

            /* CR 2962001 Country Conversion for Data.com */
            if (con.MailingCountry == 'United States' || con.MailingCountry == 'United States of America') 
                con.MailingCountry = 'USA';

            if (con.OtherCountry == 'United States' || con.OtherCountry == 'United States of America') 
                con.OtherCountry = 'USA';
            /* End of Country Conversion for Data.com */
        
        }

        if(checkDuplicateList.size()>0)
            ContactTriggerClass.CheckDuplicates(checkDuplicateList);

    }

      //SFDC-9168 - Rajul Vishwakarma 
      public static void prepareAccoutsForRecomputation(Boolean isInsert,Boolean isUpdate,Map<Id,SObject> oldContactsMap,List<Contact> newContacts,List<Contact> oldContacts){
        if(!prepareAccoutsForRecomputationFirstRun){
          return;
        }
        Set<Id> uniqueAccountIds = new Set<Id>();
        if(isInsert){
            for(Contact c:newContacts){
                uniqueAccountIds.add(c.AccountId);
            }
        }
        else if(isUpdate){
            for(Contact newContact:newContacts){
                Contact oldContact = (Contact)oldContactsMap.get(newContact.Id);
                  if(newContact.AccountId != oldContact.AccountId){
                      uniqueAccountIds.add(oldContact.AccountId);
                      uniqueAccountIds.add(newContact.AccountId);
                  }
            }
        }
        else {
            for(Contact c:oldContacts){
                uniqueAccountIds.add(c.AccountId);
            }
        }
        if(uniqueAccountIds.size()>0){
          L2Q_AccountTriggerClass.updateAndInsertAccountHelperObjects(uniqueAccountIds);
        }
        prepareAccoutsForRecomputationFirstRun = false;
    }
}