/***
    PSA_ProjectCreationPageController
    Author       :Kushal Khokale
    Description  :This Class is invoked from psaProProjectTemplateSelection and psaProjectCreate LWC components
                   This class is mainly used for Project creation
    JIRA         : FFPSA-1890             

*/
public with sharing class PSA_ProjectCreationPageController {
    public static List<pse__Proj__c> templateList;
    pse__Proj__c selectedTemplate;
    public static Opportunity opp;
    public static Account acct;
    public static list<pse__Resource_Request__c> oppResourceRequests;
    public static list<pse__Resource_Request__c> newResourceRequests;
    public static list<Project_Contract__c> projContHeader;

    public static String baseSQlString ='Select Id, Name, pse__Account__c, pse__Group__c, pse__Region__c, pse__Practice__c, '+
                                        'pse__Planned_Hours__c, pse__Project_Manager__c, pse__Project_Type__c, Project_Sub_Type__c, '+
                                        'CurrencyIsoCode, pse__Start_Date__c, pse__End_Date__c, pse__Is_Active__c, '+
                                        'pse__Is_Billable__c, pse__Time_Credited__c, pse__Time_Excluded__c, Contract_Closed__c, '+
                                        'Ongoing_Project_Recurring_Planned_Hour__c, Ongoing_Project_Recurring_Budget_Amt__c, RecordTypeId, ' +
                                        'pse__Account__r.Name, pse__Region__r.Name, pse__Practice__r.Name '+
                                        'from pse__Proj__c where pse__Is_Template__c = true ';

 
// Retrives project templates also can pass template name to filter. Returns list of Project templates for selection on LWC screen                                       
    @AuraEnabled(cacheable=true)
    public static list<pse__Proj__c> getProjectTemplates(string namesearch){
        list<pse__Proj__c> projreturnList = new list<pse__Proj__c>();
        string namefilter;
        if (namesearch != ''){
            namefilter = namesearch;     
        }

        if(namefilter != null && namefilter.length() >0){
            baseSQLString = baseSQLString + ' and Name LIKE \'%'+string.escapeSingleQuotes(namefilter)+'%\'';
        }
        projreturnList = queryForData(baseSQLString);
        system.debug('projreturnList ==>'+projreturnList);
        return projreturnList;
    }

// Used to query Project data 
    private static list<pse__Proj__c> queryForData(String queryString) {
        String newQueryString;
        Id profileId=userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        
        if (Test.isRunningTest()) {
            newQueryString = queryString + ' order by CreatedDate desc';
        } else {
            if(profileName == 'GSS Operations'){
            	newQueryString = queryString + ' order by Name';
            }
            else{
                newQueryString = queryString + ' and Name != \'Internal/Internal - Project Template\' AND Name != \'Internal/Pre-Sales - Project Template\' order by Name';
            }
        }       
        templateList = Database.query(newQueryString);
        if (templateList != null && templateList.size() > 0) {
            return templateList;
        } else {
            return null;
        }
    }

    // Get the region associated with the Area on the Account 
    public static String getRegion() {
        pse__Region__c reg;
        string regionId = '';
        system.debug('inside region acct =>'+acct.TERR_HIER_5__c);
        if (acct != null && acct.TERR_HIER_5__c != null && acct.TERR_HIER_5__c.length() > 0) {
            try {
                reg = [select Id, Name from pse__Region__c where Territory__c = :acct.TERR_HIER_5__c limit 1];
                system.debug('reg :'+reg);
            } catch (Exception e) {
                System.debug('no region found for acct.TERR_HIER_5__c ='+acct.TERR_HIER_5__c);
            }   
            if (reg != null) {
                regionId = reg.Id;
            }   
        }   
        return regionId;
    } 

    /*This method fetches projects with its related budget, milestones, tasks for a given template and returns the details via wrapper
      to LWC screen which preset values.
    */
    @AuraEnabled(cacheable=true)
    public static projectsWrapper getProjectinfo(id templateId, string parentrecId){
        projectsWrapper prowrapperecs = new projectsWrapper(); 
        pse__Proj__c newProject = new pse__Proj__c();
        Contact userContact;
        string acctId = '';
        string oppId = '';

        list<pse__Milestone__c> milestonelist = new list<pse__Milestone__c>();
        list<pse__Project_Task__c> tasklists = new list<pse__Project_Task__c>();
        oppResourceRequests = new list<pse__Resource_Request__c>();
        newResourceRequests = new list<pse__Resource_Request__c>();
        // Page can be called from either Account or Opportunity for Project creation
        if (parentrecId != null && parentrecId.length() > 0){
            if (parentrecId.startsWith('001')){
                acctId = parentrecId;
            }
            else if (parentrecId.startsWith('006')){
                oppId = parentrecId;
            }
        }

        if (oppId != null && oppId.length() > 0) {
            opp = [Select Id, Name, pse__Region__c, pse__Practice__c, AccountId from Opportunity where Id = :oppId];
        }
        
        if ((acctId == null || acctId.length() == 0) && opp != null) {
            acctId = opp.AccountId;
        }
        
        if (acctId != null && acctId.length() > 0) {
            acct = [Select Id, Name, TERR_HIER_5__c, Contract_Currency__c from Account where id = :acctId];
        } 
        System.debug('acct='+acct);

        try{
            userContact = [select Id from Contact where pse__Salesforce_User__c = :UserInfo.getUserId()];
        }
        catch (exception ex){
            // Do nothing
        }
        List<String> projTemplateAkamIds = new List<String>();
        // Tasks will be created for values stored in the customMetadata
        try{
            projTemplateAkamIds.addAll([select Value_Long__c from PSA_Common_Setting__mdt where DeveloperName = 'Project_template_for_Tasks'].Value_Long__c.split(','));

            //Get all project template data including related budgets, milestones, resource requests and project products. */
            if(templateId != null){
                pse__Proj__c templateProj = [Select Id, Name, pse__Opportunity__c, pse__Account__c, pse__Group__c, pse__Region__c, pse__Planned_Hours__c, Ongoing_Project_Recurring_Budget_Amt__c,      
                                            pse__Practice__c, pse__Project_Manager__c, pse__Project_Type__c, Project_Sub_Type__c, CurrencyIsoCode, Account_Department__c,pse__Billing_Type__c,Contract_Closed__c,
                                            pse__Start_Date__c, pse__End_Date__c, pse__Is_Active__c, pse__Is_Billable__c, pse__Time_Credited__c, pse__Time_Excluded__c,Ongoing_Project_Recurring_Planned_Hour__c,RecordTypeId,
                                    (Select Id, Name, pse__Status__c, pse__Type__c, pse__Effective_Date__c,pse__Description__c, pse__Amount__c from pse__Budgets__r),
                                    (Select Id, Name, RecordTypeId, pse__Target_Date__c, pse__Milestone_Amount__c, pse__Planned_Hours__c, pse__Actual_Date__c, Start_Date__c, Billable__c, Task_Milestone_Name__c, Milestone_Type_List__c, Internal_Time_Only__c from pse__Milestones__r),
                                    (Select Id, Name, Display_Name__c, pse__Request_Priority__c, pse__Notes__c, pse__SOW_Hours__c, pse__Status__c, pse__Resource__r.Name, pse__Staffer_Resource__r.Name, pse__Start_Date__c, pse__End_Date__c,Originating_Account__c, Resource_Request_Sub_Type__c from pse__Resource_Requests__r),
                                    (select Id, Name, Billable__c,pse__Milestone__c , pse__Milestone__r.Name , pse__Status__c , pse__Start_Date_Time__c , pse__End_Date_Time__c from pse__Project_Tasks__r where pse__Project__r.AKAM_Project_ID__c IN :projTemplateAkamIds)
                                    From pse__Proj__c where id =: templateId]; 

            // Clone Account template and set field values to be rendered on UI                        
            newProject = templateProj.clone(false, false, false, false);   
            newProject.Project_Template__c =  templateProj.Id;
            newProject.Name = '';
            newProject.pse__Daily_Timecard_Notes_Required__c = true;
            newProject.pse__Is_Template__c = false;     
            newProject.pse__Is_Active__c = true;
            newProject.pse__Region__c = getRegion();
            newProject.pse__Start_Date__c = System.today();
            if (userContact != null) {
                newProject.pse__Project_Manager__c = userContact.Id;
            } else {
                newProject.pse__Project_Manager__c = null;
            }
            newProject.pse__End_Date__c = null;
            if (opp != null) {
                newProject.pse__Account__c = opp.AccountId;
                newProject.pse__Opportunity__c = opp.Id;
            }    
            if (acct != null) {
                newProject.pse__Account__c = acct.Id;
            }
            // Clone related Budget record
            pse__Budget__c tempBudget;
            for (pse__Budget__c budgRow : templateProj.pse__Budgets__r) {
                tempBudget = budgRow.clone(false, false, false, false); 
                break;
            }
            if (tempBudget == null) {
                tempBudget = new pse__Budget__c();  
            }
            
            tempBudget.pse__Effective_Date__c = null;  
            tempBudget.pse__Status__c = 'Approved';
            tempBudget.pse__Type__c = 'Customer Purchase Order';
            tempBudget.pse__Invoice_Date__c = newProject.pse__Start_Date__c;

            // Clone Milestones
            for (pse__Milestone__c mile : templateProj.pse__Milestones__r) {
                pse__Milestone__c newMile = mile.clone(true, false, false, false);
                newMile.Start_Date__c = System.today();
                newMile.pse__Target_Date__c = System.today().addDays(90);
                milestonelist.add(newMile);
            }   
            system.debug('milestonelist =>'+milestonelist);

            // Clone tasks
            if (templateProj.pse__Project_Tasks__r != null && templateProj.pse__Project_Tasks__r.size()> 0 ) {
                for (pse__Project_Task__c projTask : templateProj.pse__Project_Tasks__r) {
                    //selectable = new PSA_SelectableObject();
                    pse__Project_Task__c prjTask = projTask.clone(true , false , false , false);
                    tasklists.add(prjTask);
                }   
            }
            system.debug('tasklists =>'+tasklists);
            if (templateProj.pse__Resource_Requests__r != null && templateProj.pse__Resource_Requests__r.size()> 0 ) {
                for (pse__Resource_Request__c req : templateProj.pse__Resource_Requests__r) {
                    req.Display_Name__c = req.Name;
                    pse__Resource_Request__c resreq = req.clone(true, false, false, false);
                    system.debug('resreq =>'+resreq);
                    newResourceRequests.add(resreq);
                } 
            }

            // Map results to wrapper which will be used to display values on UI
            prowrapperecs.prorec = newProject;
            prowrapperecs.budgetrec = tempBudget;
            prowrapperecs.milestonesrecs = milestonelist;
            prowrapperecs.taskrecs = tasklists;
            prowrapperecs.newResourceRequests = newResourceRequests;
            //prowrapperecs.oppResourceRequests = oppResourceRequests;
            system.debug('prowrapperecs ***:'+prowrapperecs);
            return prowrapperecs; 
            }
            else {
                system.debug('null values');
                return null;
            }
        }
        catch (exception e){
            system.debug('Exception inside getProjectinfo :'+e.getmessage()+ '-'+ e.getStackTraceString()+ '-' + e.getLineNumber());
            return null;
        }
    }

    // This method is invoked from Save button on UI. It creates Project, Budget, Milestones, tasks, project Contract and PCI 
    @AuraEnabled
    public static pse__Proj__c saveProject(string projstr, string budgetstr, string milestonestr, string taskstr, string cliId, string resreq){

        pse__proj__c projRecord = (pse__proj__c) JSON.deserialize(projstr, pse__proj__c.class);
        pse__Budget__c budgetRecord = (pse__Budget__c) JSON.deserialize(budgetstr, pse__Budget__c.class);
        List<pse__Milestone__c> milestoneInsertList = (List<pse__Milestone__c>) JSON.deserialize(milestonestr, List<pse__Milestone__c>.class);
        List<pse__Project_Task__c> taskList = (List<pse__Project_Task__c>) JSON.deserialize(taskstr, List<pse__Project_Task__c>.class)                                                                                                                                                                                                                                                                                                                                                                                                                                                      ;
        list<pse__Resource_Request__c> resreqList = (list<pse__Resource_Request__c>) JSON.deserialize(resreq,list<pse__Resource_Request__c>.class);

        system.debug('milestoneInsertList =>:'+milestoneInsertList);
        system.debug('taskList =>:'+taskList);
        system.debug('budgetRecord =>:'+budgetRecord);
        system.debug('projRecord =>:'+projRecord);
        system.debug('resreqList =>:'+resreqList);
        // Contract should be closed for non Internal Projects
        if (projRecord.pse__Project_Type__c != 'Internal' && (projRecord.Contract_Closed__c == null ||projRecord.Contract_Closed__c.length() == 0)) {
            throw new AuraHandledException('Contract Closed is required for non-internal projects.');
        }
        // CLI should be associated to the project when Contract Closed = YES
        if (projRecord.Contract_Closed__c == 'Yes' && (cliId == '' || cliId == null)){
            throw new AuraHandledException('Because Contract Closed = "Yes", you are required to select a Contract Detail Line to associate with your Project.');
        }

        projRecord.pse__Is_Active__c = true;
        projRecord.pse__Time_Credited__c = false;
        projRecord.pse__Time_Excluded__c = false;
        if (projRecord.pse__Project_Type__c == 'Internal') {    
            projRecord.pse__Is_Billable__c = false; 
        } else {
            projRecord.pse__Is_Billable__c = true;
        }
        insert projRecord;

        if (budgetRecord != null) {
            budgetRecord.pse__Project__c = projRecord.Id;
            budgetRecord.pse__Account__c = projRecord.pse__Account__c;         
            insert budgetRecord;
        } 
        list<pse__Milestone__c> mileInsetList = new list<pse__Milestone__c>();
        Map<String, Id> milestoneNametoIdMap = new Map<String, Id>();                

        if(!milestoneInsertList.isEmpty()){
            for(pse__Milestone__c mile : milestoneInsertList){
                mile.pse__Project__c = projRecord.Id;
                mile.From_Template__c = true;       
                if(projRecord.pse__Project_Type__c == 'Internal'){
                    mile.RecordTypeId = Schema.SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get('Task_Milestone_Internal').getRecordTypeId();
                } 
                system.debug('Milestone Name is =>'+mile.Name + mile.Task_Milestone_Name__c+ mile.RecordType.Name);
                mileInsetList.add(mile); 
            }
            if (mileInsetList.size() > 0){
                insert mileInsetList;
            } 
        }

        List<pse__Project_Task__c> taskInsertList = new List<pse__Project_Task__c>();

        if(!taskList.isEmpty()){
            for(pse__Project_Task__c eachtask : taskList){
                eachtask.pse__Milestone__c = milestoneNametoIdMap.get(eachtask.pse__Milestone__r.Name);
                eachtask.pse__Project__c = projRecord.Id;
                taskInsertList.add(eachtask);
            }
            insert taskInsertList;
        }

        List<pse__Resource_Request__c> selectedResourceRequests = new List<pse__Resource_Request__c>();
        if (resreqList!= null && resreqList.size()>0){
            for (pse__Resource_Request__c resRow : resreqList) {
                    resRow.pse__Project__c = projRecord.Id;
                    resRow.pse__Group__c = projRecord.pse__Group__c;
                    resRow.pse__Region__c = projRecord.pse__Region__c;
                    resRow.pse__Practice__c = projRecord.pse__Practice__c;                               
                    selectedResourceRequests.add(resRow);
            } 
        }

        if (selectedResourceRequests.size() > 0) {
            insert selectedResourceRequests;
        }   
            save(cliId,projRecord);
            return projRecord;
        }
            
        // This method inserts Project Contract and PCI for the Project
        public static void save(string conDetail, pse__proj__c proj) {

            List<Merge_Contract_Header__c> contractList = new List<Merge_Contract_Header__c>();
            if(conDetail != '' && conDetail != null)
            {
                system.debug('conDetail :'+conDetail);
                contractList = [SELECT Id, Name, Account_Name__c, Opportunity_Name__c, Effective_Start_Date__c, Effective_End_Date__c, 
                Original_Contract_Id__c, Active__c, Parent_Contract__c, Revision_Contract_Id__c, Revision_Effective_Start_Date__c, 
                (SELECT Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c, Product__c, 
                Unit_Price__c, Units_High__c, Units_Low__c, Record_Type__c, Unit_of_Measure__c, Product_Id__c 
                FROM Merge_Contract_Details__r WHERE ID = :conDetail ) FROM Merge_Contract_Header__c WHERE id IN (select Original_Contract_Id__c from Merge_Contract_Detail__c where ID = :conDetail ) ];
            }

            Project_Contract__c projContHeader = new Project_Contract__c();
            Project_Contract_Line_Item__c projContItem = new Project_Contract_Line_Item__c();
            if (contractList != null && contractList.size() >0){
                for (Merge_Contract_Header__c contRow : contractList) {
                    system.debug('org cont Id1:'+contRow.Id);
                    projContHeader.Account__c = proj.pse__Account__c;
                    projContHeader.Original_Contract_Id__c = contRow.Id;
                    projContHeader.Project__c = proj.Id;

                    for(Merge_Contract_Detail__c lineRow : contRow.Merge_Contract_Details__r){
                        system.debug('org cont Id2:'+contRow.Id);
                        projContItem.Contract_Detail__c = lineRow.Id;
                        projContItem.Original_Contract_Id__c = contRow.Id; 
                        projContItem.Project__c = proj.Id;
                        projContItem.Valid_Create__c = true;
                    }
                }  
            }            

            if (projContHeader.Project__c != null) {
                system.debug('projContHeader *'+projContHeader);
                insert projContHeader;
            }   
            
            if (projContItem.Project__c != null ) {
                projContItem.Project_Contract__c = projContHeader.Id;
                insert projContItem;
            }
        }                

    public class projectsWrapper{
        @AuraEnabled
        public pse__Proj__c prorec{get;set;}
        @AuraEnabled
        public pse__Budget__c budgetrec{get;set;}
        @AuraEnabled
        public list<pse__Milestone__c> milestonesrecs{get;set;}
        @AuraEnabled
        public list<pse__Project_Task__c> taskrecs{get;set;}
        // @AuraEnabled
        // public list<pse__Resource_Request__c> oppResourceRequests{get;set;}
        @AuraEnabled
        public list<pse__Resource_Request__c> newResourceRequests{get;set;}
    } 
}