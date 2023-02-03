/**
 * PRM search account controller 
 * This is a controller for Searching account for FCM.
 * This page is invoked by button click on opportunity object
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N   01/2011     Created Class
   Vinayendra T N   11/2011     CR 1428076 Escape Single Quotes in PRM search account page
  Rahul Gaira     02/2015     Changed the Rebate % and moved it inside the custom setting
  Sonali Tandon    22 Dec 2016 SFDC- 1337 : Changed rebate % calculation, added logic for discount % and status 

 **/
global class PRM_search_account_controller {

    public list<Account> Accs { get; set; }
    public String AccountCountry { get; set; }
    public String AccountDomain { get; set; }
    public string AccountName {get;set;}
    public String AccountStreet { get; set; }
    public String AccountState { get; set; }
    public string AccountZip {get;set;}
    public string AccountCity {get;set;}
    public Account newAccount {get; set;}
    private string OppId= '' ;
    private Opportunity Optty=null;
    private Boolean FirstTimeEntry=false;
    private PageReference pRef;
    public Boolean mode { get; set; }
    public Boolean allowDuplicate {get; set;}
    public Boolean showButton { get; set; }
    public Boolean DupcheckFlag {get;set;}
    public list<sobject> acctList1 {get; set;}
    public List<Account> DuplicateAcc {get; set;}


    //Update Opportunity share table.
    public Static OpportunityShare opptyUpdateShareTable(Id p_opp_id, Id p_user_Id,String p_access)
        {
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:p_opp_id and UserOrGroupId=:p_user_Id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel=p_access;
            return oppsh;
        }
    public PRM_search_account_controller()
        {
            init();
        }
    public void init()
        {
            DupcheckFlag =false;
            showButton = true;
            oppId = ApexPages.currentPage().getParameters().get('opptyid');
            if(oppId== '' || oppId == null ) // SFDC-5952 Added Null Condition
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity ID'));
            }
            else
            {
                oppId = String.escapeSingleQuotes(oppId.escapeHtml4());// SFDC-5952 Escaped
                AccountName='';
                AccountDomain ='';
                AccountCountry = '';
                AccountStreet = '';
                AccountCity = '';
                AccountState = '';
                AccountZip = '';
                mode=true;
                for(Opportunity opp:[select Id,Partner_Involved__r.No_Rebate_Required__c,AccountId,Customer_Company_Name__c,End_Customer_Website__c,End_Customer_Country__c,End_Customer_Zip_Code__c,End_Customer_Street_Address__c,End_Customer_State__c,End_Customer_City__c, Deal_Reg_Opportunity_Discount__c, Deal_Reg_Account_Discount__c,Rebate__c,Discount_Status__c,Discount_Percentage__c, Deal_Reg_Account_Status__c, Deal_Reg_Opportunity_Status__c from Opportunity where id = :OppId ])
                    Optty=opp;
                if(Optty==null)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Opportunity found with this ID'));
                else{
                    if(optty.Customer_Company_Name__c!=null)
                        AccountName=optty.Customer_Company_Name__c;
                    if(optty.End_Customer_Website__c!=null)
                        AccountDomain =optty.End_Customer_Website__c;
                    if(optty.End_Customer_Country__c!=null)
                        AccountCountry=optty.End_Customer_Country__c;
                    if(optty.End_Customer_Street_Address__c!=null)
                        AccountStreet=optty.End_Customer_Street_Address__c;
                    if(optty.End_Customer_City__c!=null)
                        AccountCity=optty.End_Customer_City__c;
                    if(optty.End_Customer_State__c!=null)
                        AccountState=optty.End_Customer_State__c;
                    if(optty.End_Customer_Zip_Code__c!=null)
                        AccountZip=optty.End_Customer_Zip_Code__c;
                    search();
                }
            }
            FirstTimeEntry=true;
        }
    public PageReference search() {
        mode=true;
        Accs = new list<Account>();

        if(Optty!=null)
        {
            // SFDC 1237 : Update Deal Reg Locate Acct Function to include State
            // replacing existing logic with soql builder to make this easily extensible.
            al.SoqlBuilder soql = new al.SoqlBuilder().selectx(new Set<Object>{'Id','Name','Website','BillingCountry','OwnerId','Owner.Name','Account_Status__c','BillingState'}).fromx('Account').limitx(100);
            al.NestableCondition  andCond = new al.AndCondition();
            al.NestableCondition orCond = new al.OrCondition();
            String query;
            // Don't query if there is no filter criteria
            Boolean flag = false;

            if(!String.isBlank(AccountName))
            {
                flag = true;
                orCond.add(new al.FieldCondition('Name').likex('%'+ AccountName + '%'));
            }
            if(!String.isBlank(AccountDomain))
            {
                flag = true;
                orCond.add(new al.FieldCondition('Website').likex('%'+ AccountDomain+ '%'));
            }
            if(!String.isBlank(AccountCountry))
            {
                flag = true;
                andCond.add(new al.FieldCondition('BillingCountry').likex('%'+ AccountCountry+ '%'));
            }
            if(!String.isBlank(AccountState))
            {
                flag = true;
                andCond.add(new al.FieldCondition('BillingState').likex('%'+ AccountState+ '%'));
            }

            andCond.add(orCond);
            query = soql.wherex(andCond).toSoql(new al.SoqlOptions().escapeSingleQuotes());

            System.debug('flag' + flag);

            if(!String.isBlank(query) && flag)
            {

                for(Account a : Database.query(query))
                    {

                        Accs.add(a);
                    }
                if(Accs.size()>90)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Too Many search results. Please narrow down your search.'));
                    return null;
                }
                if(Accs.size()<1)
                {
                    if(FirstTimeEntry==true)
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Matches Found.'));
                    return null;
                }
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Matches Found. Please enter some search criteria.'));
                return null;
            }

        }
        else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity ID'));
        return null;
    }
    public PageReference CreateMode()
        {
            String accessProfileIds = GSMSettings.getVerbose('AccountCreationProfileIds');
            String accessProfileId1 = GSMSettings.getVerbose('AccountCreationProfileId1');
            String accessProfileId2 = GSMSettings.getVerbose('AccountCreationProfileId2');
    // system.debug('swati:::'+flag);
        if(accessProfileIds.contains(userinfo.getProfileId()) || accessProfileId1.contains(userinfo.getProfileId()) || accessProfileId2.contains(userinfo.getProfileId()) ){
            newAccount = new Account();
            newAccount.Name=AccountName;
            newAccount.Website=AccountDomain;
            newAccount.BillingCountry=AccountCountry;
            newAccount.BillingStreet=AccountStreet;
            newAccount.BillingCity=AccountCity;
            newAccount.BillingState=AccountState;
            newAccount.BillingPostalCode=AccountZip;
            mode=false;
             showButton = true;
 
            return null;
            }
            else{
                system.debug('Inside else');
            String Prefix =  Schema.Sobjecttype.Account_Creation_Request__c.getKeyPrefix();
           PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?');
            returnURL.getParameters().put('nooverride', '1');
            returnURL.setRedirect(true); 
            return returnURL;
            }
        }
    public PageReference AddAccount() {
        ID pid = ApexPages.currentPage().getParameters().get('pid');
        pid = !String.isBlank(pid) ? ID.valueOf(String.escapeSingleQuotes( String.valueOf(pid).escapeHtml4())) : pid; // SFDC-5952 Added escapehtml4 and escaped single quotes
        Account selectedAccount = [select id, Customer_or_Account__c, No_Rebate_Required__c from Account where id=:pid];
        if(Optty!=null)
        {
            Optty.AccountId=pid;
            Optty.Validation_Override__c=true;
            Optty.Deal_Reg_Account_Status__c = selectedAccount.Customer_or_Account__c;
            System.Debug('check@@@ optty' + Optty);
            //SFDC-1469
            
            if(Optty.Deal_Reg_Opportunity_Status__c == 'New Opportunity')
            {
                if(selectedAccount.Customer_or_Account__c == 'Existing Customer')
                    populateRebateDiscountPercentageAndStatus(Optty,'ExistingCustomerNewOppty');


                if(selectedAccount.Customer_or_Account__c == 'Existing Account')
                    populateRebateDiscountPercentageAndStatus(Optty,'ExistingAccountNewOpportunity');

            }

            if(Optty.Deal_Reg_Opportunity_Status__c == 'Existing Opportunity')
            {
                if(selectedAccount.Customer_or_Account__c == 'Existing Customer')
                    populateRebateDiscountPercentageAndStatus(Optty,'ExistingCustomerExistingOppty');


                if(selectedAccount.Customer_or_Account__c == 'Existing Account')
                    populateRebateDiscountPercentageAndStatus(Optty,'ExistingAccountExistingOppty');


            }
            //SFDC-1469 ends

            try{
                update Optty;
            }
            catch(Exception e)
            {
                System.Debug('check@@@ Exception' + e);
                if(e.getMessage().contains('Owner Not Assigned') || e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') )
                    return null;
                else
                    pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
            }
            OpportunityTeamMember otm=null;
            OpportunityShare oppshare=null;
            for(OpportunityTeamMember otmmem:[select id,UserId from OpportunityTeamMember where OpportunityId=:Optty.id and TeamMemberRole='Partner'])
                otm=otmmem;
            if(otm!=null)
                oppshare=opptyUpdateShareTable(Optty.id,otm.UserId,'Edit');
            //accshare=opptyUpdateShareTable(newAccount.id,otm.UserId,'Edit');
            if(oppshare!=null)
            {
                try
                {
                    update oppshare;
                }
                catch(Exception e)
                {
                    pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                }
            }

            PageReference rPage = new PageReference('/'+OppId);
            rPage.setRedirect(true);
            return rPage;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity ID'));
            return null;
        }
    }
    public PageReference cancel() {
        PageReference rPage = new PageReference('/'+OppId );
        rPage.setRedirect(true);
        return rPage;
    }
    public PageReference CancelCreate() {
        mode=true;
         showButton = true;
 
        return null;
    }
    public PageReference DupAccountCheck(){
        showButton =false;
        string Accinfo ='Akam' ;
        list<account> acctList =new list<account>();
         acctList1 =new list<sobject>();
        
        //system.debug(sr);
        acctList.add(newAccount);
        try{
        //Find Duplicate Accounts
        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(acctList);
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        string Akamid='AKAM Account Id::'+ matchRecord.getRecord().get('AKAM_Account_ID__c');
                                if(!Accinfo.contains(Akamid)){
                                    Accinfo +='Account Name::'+matchRecord.getRecord().get('Name') + 'AKAM Account Id::'+ matchRecord.getRecord().get('AKAM_Account_ID__c')+'\n';
                                 
                        acctList1.add(matchRecord.getRecord());
                        system.debug('acctList1'+acctList1);
                    }
                    }
                }
            }
        } 
       }catch(Exception e){
        system.debug('Error::'+e.getMessage());
        ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
        return null; 
    } 
     DuplicateAcc = (List<Account>)acctList1;
    system.debug('swati>>'+DuplicateAcc);
   
           if(DuplicateAcc.isempty()){
                        DupcheckFlag = false;
                    return CreateAcc();
                 }else{
                    DupcheckFlag =true;
                    return null;
                 }
        
        }

    public PageReference CreateAcc() {
        if(Optty!=null)
        {            Account_Reassignment_Rule__c currentUserRule = null;
            for (Account_Reassignment_Rule__c  tempRule : [Select a.Associated_User__c, a.Associated_User_RSM__c From Account_Reassignment_Rule__c a where a.Associated_User__c = :UserInfo.getUserID()])
                currentUserRule = tempRule;

            if (CurrentUserRule==null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Account Reassignment Rule found for this user.'));
                return null;
            }
            try{
                 Database.DMLOptions dml = new Database.DMLOptions();
        
            dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(newAccount, dml);
            if (!sr.isSuccess()) { 
                
                for(Database.Error err : sr.getErrors()) {
                    
                    System.debug('The following error has occurred.');                   
                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage());
                            ApexPages.addMessage(errMsg);
                }
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
                //showButton =true;
                return null;
            }
            }
            catch(DMLException e)
            {
                for (Integer i = 0; i < e.getNumDml(); i++)
                    {
                        
                        pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                    }
                return null;
            }

            Optty.AccountId=newAccount.id;
            Optty.Validation_Override__c=true;
            Optty.Deal_Reg_Account_Status__c = 'New Account';
            Optty.Deal_Reg_Opportunity_Status__c = 'New Opportunity';
            Optty.Existing_Opportunity__c = null;
            //SFDC- 1469
            populateRebateDiscountPercentageAndStatus(Optty,'NewAccountNewOppty');

            try
            {
                update Optty;
            }
            catch(Exception e)
            {
                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
            }

            OpportunityTeamMember otm=null;
            OpportunityShare oppshare=null;
            for(OpportunityTeamMember otmmem:[select id,UserId from OpportunityTeamMember where OpportunityId=:Optty.id and TeamMemberRole='Partner'])
                otm=otmmem;
            if(otm!=null)
                oppshare=opptyUpdateShareTable(Optty.id,otm.UserId,'Edit');
            //accshare=opptyUpdateShareTable(newAccount.id,otm.UserId,'Edit');
            if(oppshare!=null)
            {
                try
                {
                    update oppshare;
                }
                catch(Exception e)
                {
                    pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                }
            }

            PageReference rPage = new PageReference('/'+OppId);
            rPage.setRedirect(true);
            return rPage;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity ID'));
            return null;
        }
    }
    //SFDC-1469
    public static void populateRebateDiscountPercentageAndStatus(Opportunity oppty,String metadataInfo)
        {
            /*
             * Shivam Verma - SFDC-6774
             * Skip Rebate percentage population logic is account No rebate required == true
             */
            if (!oppty.Partner_Involved__r.No_Rebate_Required__c) {
                oppty.Rebate__c =  GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Deal_Reg_Rebate_Percentage__c;
                oppty.Discount_Percentage__c =  Integer.valueOf(GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Discount__c);
                oppty.Discount_Status__c = GsmUtilClass.getDealRegRebateMatrixSettingValue(metadataInfo).Discount_Status__c;
            }
        }
}