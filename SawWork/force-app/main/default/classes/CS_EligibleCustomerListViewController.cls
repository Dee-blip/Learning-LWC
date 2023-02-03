/*
CR 1636447 CSAT: Q22012 Eligible Contact List Management Functionality
Created :April-2012
Created By: Sharath
Description: The users would like to see all the eligible contacts who could be surveyed for a particular account. They can remove contacts from the list using mass edit functionality.
      This is a custom controller, the edit,save and cancel buttons on the associated VF page are all custom implemented
Modified By: ssawhney on 29/08/2013 CR 2367219 Modified logic to exclude AT&T and IBM accounts
             ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
*/
public class CS_EligibleCustomerListViewController  {

    public String accountName { get; set; }
    public List<Account> accounts = new List<Account>();
    private static Account acct;
    public String acctId {get;set;}
    static string contactSOQL = '';
    Boolean renderMassEditSection = false;
    private String displayStyle ='display:none';
    private String displayMassStyle ='display:block';
     public List<CS_ContactWrapper> contactsList = new List<CS_ContactWrapper>();
     List<Contact> contactsToUpdate = new List<Contact>();
     Contact dummyContact;
     Contact contactForAccSearch;
     Integer no_Of_Contacts_per_Page = 0;
     public String sortField {get; set;}
     public String previousSortField {get; set;}
     public String groupMessage {get;set;}
     private Boolean validAccount = true;
     
     // the dummyContact variable is used to get the survey Opt Out and the survey Opt Out reason code selected on the VF page
     public Contact getDummyContact(){
         dummyContact = new Contact();
         return dummyContact;
     }
     
     // user tries to search contacts for a new account on VF page, so to pick an acccount from a look-up use a dummy contact
     public Contact getContactForAccSearch(){
         contactForAccSearch = new Contact();
         return contactForAccSearch;
     }
     
     //constructor
     public CS_EligibleCustomerListViewController () {
        CSAT_CustomSettings__c instanceValue1 = CSAT_CustomSettings__c.getInstance('EligibleContactsPerPage');
        no_Of_Contacts_per_Page =Integer.valueOf(instanceValue1.CSAT_Value__c);
        acctId = ApexPages.currentPage().getParameters().get('acct_id');
        checkAccountValidity();
    }
    
    // method for controlling pagination on the VF page    
    public ApexPages.StandardSetController objController
    {
        get{
            if(objController == null){
                try{
                    if(contactSOQL != ''){
                    objController = new ApexPages.StandardSetController(Database.getQueryLocator(contactSOQL));
                    objController.setPageSize(no_Of_Contacts_per_Page);
                    }
                }
                catch(Exception e){
                    ApexPages.Message myMsg;
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'No matching records were found ');
                    ApexPages.addMessage(myMsg);
                    throw e;
                }
            }
            return objController;
        }
        set;
    }

    public Boolean hasNext {
        get {
        // indicates whether there are more records after the current page set.
            if(objController != null){
                return objController.getHasNext();
            }
            else 
                return null;
        }
        set;
    }
 
 
    public Boolean hasPrevious {
        get {
           // indicates whether there are more records before the current page set.
           if(objController != null){
                return objController.getHasPrevious();
           }
           else
                return null;
        }
        set;
    }

    public void first() {
    // returns the first page of records
    if(objController != null){
        objController.first();
        }
    }
 
     public void last() {
        // returns the last page of records
     if(objController != null){
           objController.last();
     }
    }
 
    public void previous() {
        // returns the previous page of records
     if(objController != null){
           objController.previous();
        }
    }
 
    public void next() {
        // returns the next page of records
        if(objController != null){
            objController.next();
        }
    }
    
    // update the survey opt Out and Reason code fields for the records selected on the VF Page
    //Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
    public void save()
     {
         contactsToUpdate.clear();
        List<Contact> inlineUpdateList = new List<Contact>();
        for( CS_ContactWrapper contactRec : contactsList){
            if(contactRec.selected == true && ((dummyContact.CS_SurveyOptOutReason__c != '' && dummyContact.CS_SurveyOptOutReason__c != null) || dummyContact.Survey_Opt_Out__c == true)){
                contactRec.con.CS_SurveyOptOutReason__c = dummyContact.CS_SurveyOptOutReason__c;
                contactRec.con.No_Longer_with_Company__c = dummyContact.No_Longer_with_Company__c;
                //Modified by ssawhney on 29/08/2013 CR 2137582 to change the survey opt in flag
                contactRec.con.Survey_Opt_Out__c = !(dummyContact.Survey_Opt_Out__c);
                contactsToUpdate.add(contactRec.con);
            }
        }
        if(contactsToUpdate.size() > 0){
                try{
                database.update(contactsToUpdate);
                resetDataList();
                }
                catch(Exception e){
                //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
                //ApexPages.addMessage(myMsg);
            }
        }
     }
     
    // method to display contact records on the page
    public List<CS_ContactWrapper> getContactRecords(){
        contactsList.clear();
        if(objController!= null){
            for(Contact c :(List<Contact>)objController.getRecords()){
                contactsList.add(new CS_ContactWrapper(c));
            }
        }
        return contactsList;
     }
     
     // attribute deciding whether the dummyContact attributes( survey Opt out and reason code) should be shown on the screen or not
     public Boolean getRenderMassEdit(){
         return renderMassEditSection;
         }
         
    public void showMassEdit()
    {
        renderMassEditSection = true;
        displayStyle = 'display:block';
        displayMassStyle = 'display:none';
    }
    
    // re-render the contact SOQL after a save/ cancel operation
    public void resetDataList(){
        contactsList.clear();
        renderMassEditSection = false;
        objController = null;
        displayMassStyle = 'display:block';
        displayStyle = 'display:none';
        if(acctId!=null && validAccount == true ){
         //Modified the query to add logic for sales contact
         //Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
         //contactSOQL = 'select Id,Name,Akam_Contact_id__c,Email,Survey_Opt_Out__c,CS_SurveyOptOutReason__c,Title,Contact_Type__c from Contact  where Survey_Opt_Out__c = false and Network_contact__c = false and AccountId = \'' + acctId + '\' and Email != null and Email != \'\' order by Name asc ';
         contactSOQL = 'select Id,Name,Akam_Contact_id__c,Email,Survey_Opt_Out__c,CS_SurveyOptOutReason__c,Title,Contact_Type__c from Contact  where Survey_Opt_Out__c = true and (Network_contact__c = false OR (Network_contact__c = true AND Sales_Contact__c = true)) and AccountId = \'' + acctId + '\' and Email != null and Email != \'\' order by Name asc ';
        }
}
    
    public String getDisplayStyle(){
        return displayStyle;
    }
    
    public String getDisplayMassStyle(){
        return displayMassStyle;
    }
    
    public void cancel(){
      //checkAccountValidity();
        resetDataList();
    }
    
    // on clicking the contact name, user is redirected to the Contact screen using this method
    public String getRedirectToContact(){
        String redirectUrl= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
        return redirectUrl;
    }
    
    // when user selects a new Account, the new account's contacts should appear on the VF page. this metod does that operation
    public PageReference doNothing() {
        contactsList.clear();
        objController = null;
        if(contactForAccSearch != null){
            acctId = contactForAccSearch.AccountId;
        }
        PageReference pg = new PageReference('/apex/CS_VfpEligibleCustomerList?acct_id=' + acctId);
        pg.setRedirect(true);
        return pg;
    }
    
    // this method sets the Contact SOQL and the Page message at the top. This method gets called in constructor wnd while sorting
    //Modified by ssawhney on 29/08/2013 CR 2367219 Modified logic to exclude AT&T and IBM accounts
    void checkAccountValidity(){
        try{
            accountName = [select Name from Account where Id =:acctId].Name;
            //start of changes for CR 2367219 by ssawhney on 29/08/2013 Modified logic to exclude AT&T and IBM accounts
            //acct = [select Id,Name,Survey_Group__c from Account where Id = :acctId and Type IN ('Direct Customer - Active','Multiple w ISP - Active','Indirect Customer - Active','Multiple wo ISP - Active','VAR Customer - Active','Value Added Reseller - Active','Agency - Active','Brand - Active') AND Vertical__c != 'Akamai Internal' ];
            string accountSQL = 'select Id,Name,Survey_Group__c from Account where Id = :acctId AND Vertical__c != \'Akamai Internal\'';
                //Add the account types
            //Modified by ssawhney to incorporate code review comments by chandra 
            list<CS_Relationship_Account_Types__c> lstAccounTypes = CS_Relationship_Account_Types__c.getAll().values();
            if(lstAccounTypes.size() > 0)
            {
                accountSQL += ' AND Type IN (';
                for (CS_Relationship_Account_Types__c objAccountType : lstAccounTypes){
                   accountSQL += '\'' + objAccountType.Name + '\' ,';
                } 
                accountSQL = accountSQL.removeEnd(',') + ')';     
            }
            
            //check of any of the account names are present in excluded survey accounts
            list<CS_Excluded_Survey_Accounts__c> lstExcludedAccounts = CS_Excluded_Survey_Accounts__c.getAll().values();
            if(lstExcludedAccounts.size() > 0)
            {
                string contractSQL = 'select Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE AND (';
                for (CS_Excluded_Survey_Accounts__c objExcludedAccounts : lstExcludedAccounts ){
                   contractSQL += ' Parent_Account_Name__r.Name Like \'' + objExcludedAccounts.Name + '%\' OR';
                } 
                contractSQL = contractSQL.removeEnd('OR') + ')';            
                accountSQL += ' AND Id NOT IN (' + contractSQL + ')';
            }
            acct = Database.query(accountSQL);
            
            groupMessage = 'Please note: Contacts belonging to this account will be surveyed in the "' + acct.Survey_Group__c + '" cycle';
            //Modified the query to add logic for sales contact
            //Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
            //contactSOQL = 'select Id,Name,Akam_Contact_id__c,Email,Survey_Opt_Out__c,CS_SurveyOptOutReason__c,Title,Contact_Type__c from Contact where Survey_Opt_Out__c = false and Network_contact__c = false and AccountId = \'' + acct.Id + '\' and Email != null and Email != \'\' order by Name asc';
            contactSOQL = 'select Id,Name,Akam_Contact_id__c,Email,Survey_Opt_Out__c,CS_SurveyOptOutReason__c,Title,Contact_Type__c from Contact where Survey_Opt_Out__c = true and (Network_contact__c = false OR (Network_contact__c = true AND Sales_Contact__c = true)) and AccountId = \'' + acct.Id + '\' and Email != null and Email != \'\' order by Name asc';
            //end of changes for CR 2367219
            contactsList.clear();
        }
        catch(Exception e){
          validAccount = false;
            groupMessage = 'This account does not meet one or more criteria to be surveyed. Contact the Customer Experience team for details.';
        }
    }
    
    // method for sorting
    public PageReference doSort() {
        string sortOrder = 'desc';
        checkAccountValidity();
        if(previousSortField == sortField){
            sortOrder = 'desc';
           
            previousSortField = sortField;
        }
        else{
          sortOrder = 'asc';
            previousSortField = sortField;
        }
        
        contactSOQL = contactSOQL.split('order by')[0] + ' order by ' + sortField + ' ' + sortOrder ;
        objController = null;
        return null;
    }
}