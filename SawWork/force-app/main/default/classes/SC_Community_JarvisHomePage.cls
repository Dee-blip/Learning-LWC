/* 
Author          : Vishnu/ Sumukh SS/Sharath P
Description     : Controller for JARVIS Case Dashboard

WARNING : THIS IS A CUSTOMER FACING APEX CLASS, PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION

Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
25 Jan 2021				Authors				 	    					  Initial Development
06 Oct 2021             Vishnu                    ESESP-6208              Include Customer Name on landing page
19 Jan 2021             Harshil                   ESESP-6569              Added Partner Support Cases to home page
------------------------------------------------------------------------------------------------------------------
*/

public with sharing class SC_Community_JarvisHomePage {

    static final List<String> recordTypeList = new List<String>{'Technical', 'Emerging Products Engineering', 'Managed Security', 'Professional Services', 'AMG', 'Billing'};

    static final List<String> ptsSubTypeList = [Select Value__c from SC_CommunityUtility__mdt where DeveloperName = 'Partner_Technical_Support_Sub_Type'].Value__c.split(',');

    //ESESP-6569: Added condition to query partner support cases
    static final string dashBaseQuery ='select id, akam_case_id__c,account.name,subject,severity__c,owner.name,owner.type,recordtype.name,Sub_Type__c,Contact.Name,' 
                                        + 'Policy_Domain__r.Name, status,createddate,lastmodifieddate, description, CaseTypeFormula__c, Last_Case_Update__c '
                                        + ' from case where do_not_show_in_portal__c=false and (recordtype.name IN :recordTypeList or (recordtype.name = \'Partner Technical Support\' and Sub_Type__c IN :ptsSubTypeList))';
    
    static final map<String, String> dashDynamicQueryMap = new Map<String, String> {
        'myActiveCases' => ' and accountid IN :entitledSelectedAccIds and contactid=:contactid and isclosed=false',
        'myClosedCases' => ' and accountid IN :entitledSelectedAccIds and contactid=:contactid and isclosed=true',
        'allActiveCases' => ' and accountid IN :entitledSelectedAccIds and isclosed=false',
        'allClosedCases' => ' and accountid IN :entitledSelectedAccIds and isclosed=true'
    };

    //ESESP-6569: Added condition to query partner support cases
    static final Map<String, String> countQueryMap = new Map<String, String> {
        'myOpenCasesCount' => 'Select Count() from case where isclosed=false and do_not_show_in_portal__c=false and accountid IN :entitledSelectedAccIds and contactid=:contactid and (recordtype.name IN :recordTypeList or (recordtype.name = \'Partner Technical Support\' and Sub_Type__c IN :ptsSubTypeList))',
        'myClosedCasesCount' => 'Select Count() from case where isclosed=true and do_not_show_in_portal__c=false and accountid IN :entitledSelectedAccIds and contactid=:contactid and (recordtype.name IN :recordTypeList or (recordtype.name = \'Partner Technical Support\' and Sub_Type__c IN :ptsSubTypeList))',
        'allOpenCasesCount' => 'Select Count() from case where isclosed=false and do_not_show_in_portal__c=false and accountid IN :entitledSelectedAccIds and (recordtype.name IN :recordTypeList or (recordtype.name = \'Partner Technical Support\' and Sub_Type__c IN :ptsSubTypeList))',
        'allClosedCasesCount' => 'Select Count() from case where isclosed=true and do_not_show_in_portal__c=false and accountid IN :entitledSelectedAccIds and (recordtype.name IN :recordTypeList or (recordtype.name = \'Partner Technical Support\' and Sub_Type__c IN :ptsSubTypeList))' // 
    };
    //ESESP-6569: End of changes
    
    public class DashboardWrapper{
        
        @AuraEnabled public Integer techCasesCount=0; 
        @AuraEnabled public Integer soccCasesCount=0;
        @AuraEnabled public Integer billingCasesCount=0;
        @AuraEnabled public Integer psCasesCount=0;
        @AuraEnabled public Integer amgCasesCount=0;

        @AuraEnabled public Integer myOpenCasesCount=0;
        @AuraEnabled public Integer myClosedCasesCount=0;
        @AuraEnabled public Integer allOpenCasesCount=0;
        @AuraEnabled public Integer allClosedCasesCount=0;
        @AuraEnabled public Integer allCasesCount=0;

        @AuraEnabled public Boolean hasCaseCreateAccess;

        @AuraEnabled public list<Account> entitledAccounts;
        @AuraEnabled public List<Id> selectedAccountIds;
        @AuraEnabled public list<CaseWrapper> caseList = new list<CaseWrapper>();
        @AuraEnabled public List<String> entitledRecordtypes = new List<String>();
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public String queryType;

        public void addCase(Case cs) {
            this.caseList.add(new CaseWrapper(cs));

            //ESESP-6569: Added condition in count partner support cases
            if(cs.recordtype.name=='Technical' || cs.recordtype.name == 'Emerging Products Engineering' || (cs.recordtype.name == 'Partner Technical Support' && cs.Sub_Type__c == 'Technical Support')) {
                this.techCasesCount++;
            }
            else if(cs.recordtype.name=='Managed Security' || (cs.recordtype.name == 'Partner Technical Support' && cs.Sub_Type__c == 'Security Event')) {
                this.soccCasesCount++;
            }    
            else if(cs.recordtype.name=='Billing' || (cs.recordtype.name == 'Partner Technical Support' && cs.Sub_Type__c == 'Billing Support')) {
                this.billingCasesCount++;
            }
            else if(cs.recordtype.name=='AMG' || (cs.recordtype.name == 'Partner Technical Support' && cs.Sub_Type__c == 'Business Support')) {
                this.amgCasesCount++;
            }
            else if(cs.recordtype.name=='Professional Services' || (cs.recordtype.name == 'Partner Technical Support' && cs.Sub_Type__c == 'Professional-Services Support')) {
                this.psCasesCount++;
            }
            //ESESP-6569: End of changes
        }
    }    
    
    public class CaseWrapper{

        final Map<String, String> rtDisplayNames = new Map<String, String> {
                                                        'AMG' => 'Client Services Manager/ Business Support Issue',
                                                        'Billing' => 'Billing Support Issue or Question',
                                                        'Technical' => 'Technical Support Issue',
                                                        'Emerging Products Engineering' => 'Technical Support Issue',
                                                        'Professional Services' => 'Professional Services Request (billable)',
                                                        'Managed Security' => 'Managed Security Support'
                                                    };

        public caseWrapper(Case cs) {
            this.accountName = cs.Account.Name;
            this.pdName = cs.Policy_Domain__r?.Name;
            this.akamCaseID = cs.Akam_Case_Id__c;
            this.caseUrl = '/customers/s/case/'+cs.Id;
            this.subject = cs.subject;
            this.severity = SC_Jarvis_utility.getSeverityValuesCorrespondingToCase(cs.RecordType.Name, cs.Sub_Type__c, cs.AccountId, cs.Severity__c); 
            this.status = cs.status;
            this.caseowner = cs.owner.type=='Queue' ? 'In Queue' : cs.owner.name;

            //ESESP-6569: Added condition to include partner cases in RT tabs
            if(cs.recordtype.name == 'Partner Technical Support'){
                this.recordtype = SC_Jarvis_utility.getAkamaiRecordType('Partner Technical Support',cs.sub_type__c);
            } else if(cs.recordtype.name == 'Emerging Products Engineering'){
                this.recordtype = 'Technical';
            } else {
                this.recordtype = cs.recordtype.name;
            }
            //ESESP-6569 - changed rt reference to wrapper record type for PTS
            this.caseType = rtDisplayNames.get(this.recordtype);
            //ESESP-6569: End of changes
            this.description = cs.description;
            this.createddate = cs.CreatedDate;
            this.updateddate = cs.Last_Case_Update__c != null? cs.Last_Case_Update__c: cs.CreatedDate;//LastModifiedDate;
            this.createddatestr = this.createddate.format();
            this.updateddatestr = this.updateddate.format();
            //ESESP-6208 Enhancement : Include Customer Name on landing page
            this.caseContact = cs.contact?.name;

        }
        
        @AuraEnabled public string accountName {get;set;}
        @AuraEnabled public string pdName {get;set;}
        @AuraEnabled public string caseUrl {get;set;}
        @AuraEnabled public string akamCaseID {get;set;}
        @AuraEnabled public string caseType {get;set;}
        @AuraEnabled public string recordtype {get;set;}
        @AuraEnabled public string subject {get;set;}
        @AuraEnabled public string severity {get;set;}
        @AuraEnabled public string status {get;set;}
        @AuraEnabled public string description {get;set;}
        @AuraEnabled public string caseowner {get;set;}
        @AuraEnabled public DateTime createddate {get;set;}
        @AuraEnabled public String createddatestr {get;set;}
        @AuraEnabled public DateTime updateddate {get;set;}
        @AuraEnabled public String updateddatestr {get;set;}
        //ESESP-6208 Enhancement : Include Customer Name on landing page
        @AuraEnabled public String caseContact {get;set;}
    }
    
    //Gets Cases in Queue Records
    @AuraEnabled
    public static DashboardWrapper getCasesinQueue(string queryType, List<Id> selectedAccountIds) {
        DashboardWrapper dashWrp = new DashboardWrapper();
        
        // Getting list of accounts the logged in user has access        
        String contactid = SC_Jarvis_Create_Case_Controller.contactId;
        String currUserAccountId = SC_Jarvis_Create_Case_Controller.contactAccountId;

        if(String.isBlank(contactid) || String.isBlank(currUserAccountId)) {
            return dashWrp;
        }

        List<Account> entitledAccounts = SC_Jarvis_utility.getAccountRecords(contactid, 'ReadMode');
        Map<String, Object> savedCustz = SC_Jarvis_utility.getExistingUserCustz(UserInfo.getUserId());

        // If selected accounts is empty, get default or first account value
        if(selectedAccountIds == null || selectedAccountIds.isEmpty()) {
            if(savedCustz.containsKey('accounts')) {
                selectedAccountIds = new List<Id>();
                for(Object accId: (List<Object>)savedCustz.get('accounts')) {
                    selectedAccountIds.add((id) accId);
                }
            }
            else{
                Id defaultAccount = SC_Jarvis_Create_Case_Controller.contactAccountId; /* Review Default Acc condition with Sharath*/
                selectedAccountIds = new List<Id>{defaultAccount};
            }
        }

        if(String.isBlank(queryType) && savedCustz != null &&  savedCustz.containsKey('sessionInfo')) {
            Map<String,Object> sessionInfo = (Map<String,Object>)savedCustz.get('sessionInfo');

            Integer sessionIdHash = SC_Jarvis_utility.getSessionIdHash();

            if(sessionIdHash == (Integer)sessionInfo.get('sessionIdHash')) {
                queryType = (String)sessionInfo.get('queryType');
            }
        }

        dashWrp.hasCaseCreateAccess = SC_Jarvis_utility.hasCreateAccess(contactId);
        
        Set<Id> entitledSelectedAccIds = new Set<Id>();
        // validate if selected accounts are entitled accounts
        for(Account acc: entitledAccounts) {
            if(selectedAccountIds.contains(acc.Id)) {
                entitledSelectedAccIds.add(acc.Id);
            }
        }
        
        dashWrp.entitledAccounts = entitledAccounts;  //accsForHomePage;
        dashWrp.selectedAccountIds = new List<Id>(entitledSelectedAccIds);
        dashWrp.pageSize = (Integer) savedCustz.get('pageSize');
        dashWrp.entitledRecordtypes.addAll(SC_Jarvis_utility.getCategoriesAccounts(contactid, dashWrp.selectedAccountIds));

        if(String.isBlank(queryType)) {
            queryType = 'myActiveCases';
        }
        
        // Build Query
        String queryStr = dashBaseQuery + dashDynamicQueryMap.get(queryType) + ' order by createddate desc limit 20000';
        // Execute Query, add case to DashboardWrapper
        for(case eachcaseRec : database.query(queryStr)) {
            dashWrp.addCase(eachcaseRec);
        }

        // Count of cases for each view
        dashWrp.myOpenCasesCount = Database.Countquery(countQueryMap.get('myOpenCasesCount'));
        dashWrp.myClosedCasesCount = Database.Countquery(countQueryMap.get('myClosedCasesCount'));
        dashWrp.allOpenCasesCount = Database.Countquery(countQueryMap.get('allOpenCasesCount'));
        dashWrp.allClosedCasesCount = Database.Countquery(countQueryMap.get('allClosedCasesCount'));
        dashWrp.allCasesCount = dashWrp.allOpenCasesCount + dashWrp.allClosedCasesCount;
        dashWrp.queryType = queryType;

        return dashWrp;
    }

    @AuraEnabled
    public static void saveUserCustomizations(List<Id> accountIds, Integer pageSize, String queryType) {
        SC_Jarvis_utility.saveUserCustomizations(accountIds, pageSize, queryType);
    }
    
    @AuraEnabled(cacheable=true)
    public static list<case> getCasedetails(string caseid) {
        return ([select akam_case_id__c,subject, status, severity__c, description,owner.name,recordtype.name,Account.Name from case where id = :caseid]);
    }

    
    @AuraEnabled
    public static Boolean mitigateCase(string caseId) {
        Case cs = [select id, recordtype.name from Case where Id = :caseId];
        if(cs.recordtype.name == 'Technical') {
            cs.status = 'Mitigated / Solution Provided';
            cs.validation_override__c = true;
            update cs;
            SC_CommunityCommentController.insertnewComment((String)cs.Id, 'JARVIS', 'Case', 'Issue Mitigated', 'Public');   
        }
        return true;
    }

    @AuraEnabled
    public static List<CaseWrapper> fetchAllCases(List<String> selectedAccountIds) {
        // Getting list of accounts the logged in user has access        
        String contactid = SC_Jarvis_Create_Case_Controller.contactId;
        Id currUserAccountId = SC_Jarvis_Create_Case_Controller.contactAccountId;
        List<Account> entitledAccounts = SC_Jarvis_utility.getAccountRecords(contactid, 'ReadMode');
        Set<Id> selectedEntitledAccountIds = new Set<Id>();
        
        for(Account acc: entitledAccounts) {
            if(selectedAccountIds.contains(acc.id)) {
                selectedEntitledAccountIds.add(acc.Id);
            }
        }
        String queryStr = dashBaseQuery  + ' and accountid in :selectedEntitledAccountIds';
        List<CaseWrapper> caseList= new List<CaseWrapper>();
        for(Case cs: (List<Case>)Database.query(queryStr)) {
            caseList.add(new CaseWrapper(cs));
        }
        return  caseList;
    }
}