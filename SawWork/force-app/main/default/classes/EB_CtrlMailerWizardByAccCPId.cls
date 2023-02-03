public class EB_CtrlMailerWizardByAccCPId extends EB_CtrlMailerWizard{
    
   /* ========================================================================
     
   Author: Sharath
   Description: This contoller returns a list of accounts, allows user to select them and create mailers
                when provided with Account IDs or CP Codes as search inputs.
    9/9/2010 - CR 791832: Customer Notification Accounts Pagination & Selection Fix - Added new function getAdded(), modified getAccounts(),getSelected(),createMailer(),page2()
    9/14/2010- CR 794793: Implementing code review findings - this class now extends EB_CtrlMailerWizard and hence uses most of its functions without overriding it.
    9/26/2011 - CR 1302518 CNotify: 10/10 Filtering out Contacts which have Email Id as null - Adding Email !='' and Email !=null conditions in all Contact queries.
    7/12/2013 - CR 2286623 Sonia - CNotify: Filter Inactive Accounts - Adding Account_Status__c NOT LIKE '% - Inactive' condition in all Account queries.
    ======================================================================== */
String choice = ApexPages.currentPage().getParameters().get('choice');
 

    public String getDispvalue() {
   //function that returns the appropriate text value to UI based on Search criteria.
       String dispVal;
        if(ApexPages.currentPage().getParameters().get('basis')=='accId'){
            dispVal='Account IDs';
            return dispVal;
        }
        else{
            dispVal = 'CP Codes ';
            return dispVal;
        }
    }


    
    /* ========================================================================
    descripion: this function validates the Account search criteria.
     It is called on the click of a Validate Account or Next on the VisualForce Search Page 
     This function also forms the final SOQL query by parsing the list of input values(ID/CP CODES) appropriately
    created by:Sharath K
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
        2.Modified:07/12/2013, Sonia, CR 2286623 : Added filter on Account to remove all Inactive accounts
    code review:
    ======================================================================== */

    public override PageReference validateAccount()
    {
        Account a;
        ApexPages.Message myMsg;
        validateAccountFlag = 0;
        String tempStr='';
        String finalstr='';
        String validate='';
        Integer x=0;
        List<String> dispFields;
        //system.assertEquals(ResellerAccounts,NULL);
        try{ 
        String fields='';
        dispFields = new List<String>();
        for (EBCS_DisplayFields__c displayFields : EBCS_DisplayFields__c.getAll().values()){
            dispFields.add(displayFields.Name_API__c);
        }     
        for( x=0;x<( dispFields.size()-1);x++){
             fields= fields + dispFields.get(x) + ' , ';
        }
        fields= fields + dispFields.get(x) + ' ';        
        if(SQLWhere != null && SQLWhere != ''){
            if(ApexPages.currentPage().getParameters().get('basis')=='accId'){
                List<String> accIds =SQLWhere.split('\\n');
                for( String partId : accIds)
                tempStr = tempStr + ' \'' + partId.trim() + '\',';
                finalstr=tempStr.subString(0,tempStr.length()-1); 
                //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
                //finalSOQLAccount = 'select ' + fields + ' FROM Account where AKAM_Account_ID__c IN ( ' + finalstr + ' ) AND Account_Status__c != \'Lead\'';           
                finalSOQLAccount = 'select ' + fields + ' FROM Account where AKAM_Account_ID__c IN ( ' + finalstr + ' ) AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\'))';
            }
            else{
                List<String> CPIds =SQLWhere.split('\\n');
                for( String partId : CPIds)
                tempStr = tempStr + ' ' + partId.trim() + ',';
                finalstr=tempStr.subString(0,tempStr.length()-1);
                //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
                //finalSOQLAccount = 'select '+ fields + ' FROM Account where Id IN ( select EB_Account__c from EB_AccountCPCodeMap__c where EB_CPCode__c IN ( ' +finalstr + ' )) AND Account_Status__c != \'Lead\'';
                finalSOQLAccount = 'select '+ fields + ' FROM Account where Id IN ( select EB_Account__c from EB_AccountCPCodeMap__c where EB_CPCode__c IN ( ' +finalstr + ' )) AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\'))';
            }
            validate = finalSOQLAccount + ' limit 1';
            try{
                a = Database.query(validate);
                disableStatus = 'true';
            }
            catch(Exception e){
                validateAccountFlag = 1;
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()+' Error:Account '+finalSOQLAccount);       
                ApexPages.addMessage(myMsg);
            }
            }
        }
        catch(StringException s){
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,s.getMessage());
                    ApexPages.addMessage(myMsg);
                    }
        return null;
    }    
    

    
    public override PageReference page2() 
    {
    /* ========================================================================
    descripion:This is invoked when user clicks on "Next" button. In this method we frame the final SOQL queries that are supplied to getAccounts() through database.getQueryLoctor().
    
    created by: Sharath K
    test class & test method:   
    modifications: date, by, description
        1. 6/-/2010 :created
        2. 6/25/2010: removed filtering criteria from getAccounts(). the filtering now happens in page2() and EB_UniqAccConList class.
        3. 6/29/2010: Added logic to display error message if search criteria return no rows
        4.7/28/2010: Removed dependency on UniqAccConList
        5.9/9/2010 - CR 791832: Customer Notification Accounts Pagination & Selection Fix 
        
    code review:
    ======================================================================== */

        String debugFlag;
        ApexPages.Message myMsg;
        String listString;
        String userId= '%' + UserInfo.getUserId() + '%';
        String mail_type = ApexPages.currentPage().getParameters().get('type');
    //system.assertEquals(mail_type,null); 
                
        validateAccount();
        if(validateAccountFlag == 1 )
        {
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Error in search criteria');
            ApexPages.addMessage(myMsg);
            return null;
        }

        try
        {
        if(SQLWhere != null && SQLWhere != ''){
                if(choice == 'selectedContacts'){
                  //CR 851546 changes- Nov 3rd 2010 - Removing HasOptedOutOfEmail filter from where clause of the SOQL - only for Service Incidents 
                    final_query= finalSOQLAccount + ' AND (Id not in :ResellerAccounts)' + ' AND (Id IN' + '(SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')'  + ' AND (Email != null AND Email !=\'\')))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'  + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));            
                    soql=final_query;
                    strOriginalResellerSOQL=finalSOQLAccount + ' AND (Id in :ResellerAccounts)' + ' AND (Id IN' + '(SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')'  + ' AND (Email != null AND Email !=\'\')))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'  + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));  
                    
                    }
                else{
                    final_query= finalSOQLAccount +' AND (Id not in :ResellerAccounts)' + ' AND (Id IN' + '(SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != null AND Email !=\'\'))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL) ' + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                    soql= final_query ; 
                    strOriginalResellerSOQL=finalSOQLAccount +' AND (Id in :ResellerAccounts)' + ' AND (Id IN' + '(SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != null AND Email !=\'\'))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL) ' + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                    }
                setSOQL(soql,strOriginalResellerSOQL);
            }
        
        else{
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Please enter the search criteria');
            ApexPages.addMessage(myMsg);
            return null;
        }
        }
        catch(StringException s)
               {
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,s.getMessage());
                ApexPages.addMessage(myMsg);
                throw s;
                return null;
               }
          catch(Exception e)
               {
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
                ApexPages.addMessage(myMsg);
                throw e;
                return null;
               }
        objController = null;
        debugFlag=EB_UtilApplication.getProperty_DebugSQL();
        if(debugFlag=='TRUE'){
            debugFinalSQL=soql;
        }
        //9/9/2010 - CR 791832: Customer Notification Accounts Pagination & Selection Fix 
        // clear all the selected Accounts from the custom Object Selected Accounts
        /*
        List<EB_SelectedAccounts__c> deleteAll = [select Id from EB_SelectedAccounts__c where CreatedById = :userId ];
        database.delete(deleteAll);
        */
        if(((List<Account>)objController.getRecords()).size()==0){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Search did not return any result');
            ApexPages.addMessage(myMsg);
            return null;
         }
         else{
             //CR 819957: Making the Create Mailer Batchable - for single mails, call createMailer()
             if(mail_type=='single'){
              return Page.EB_VfpMailerWizardByAccCPId2;
             }
             else{
               //CR 819957: Making the Create Mailer Batchable - for mass mails, create mailers directly
               PageReference mailerPg=createMailerDirectly();
                  return mailerPg;
             }
         }
    }
    
        public override PageReference page1(){
        // function redirects to the VfpMailerWizard2 page from VfpMailerWizard3
        selectMore.clear();
        selectedAccounts.clear();
        accountList.clear();
        return Page.EB_VfpMailerWizardByAccCPId1;
    }    
 }