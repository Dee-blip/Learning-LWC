/*
 Developer                        Date                        JIRA                            Changes
 Kushal Khokale              17th NOV 2020                   FFPSA-1075                      Created class for Customer review cases  

*/
public with sharing class PSA_mPulseCustomerReviewCasesBatch implements Database.Batchable<sObject>{
    public PSA_mPulseCustomerReviewCasesBatch() {

    }

    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        string batchquery = 'select Id, Contract_Detail__c, Project__r.pse__Account__r.Name, Original_Contract_Id__c, Project__r.pse__Project_Manager__r.pse__Salesforce_User__c, Project__r.Id, Project__r.pse__Practice__r.Name, Project__r.Project_Sub_Type__c, Project__r.pse__Is_Active__c, Project__r.pse__Start_Date__c, Project__r.pse__End_Date__c from Project_Contract_Line_Item__c where Project__r.pse__Practice__r.Name = \'Professional Services\' AND Project__r.Project_Sub_Type__c = \'mPulse Service\' AND Contract_Detail__r.Product_Id__c = \'M-LC-166357\' AND Contract_Detail__r.Unit_of_Measure__c = \'Per Month\' AND Contract_Detail__r.Record_Type__c = \'Committed\' AND Project__r.pse__Is_Active__c = TRUE AND Project__r.pse__Stage__c != \'Closed\' AND Project__r.pse__Start_Date__c <= TODAY AND Project__r.pse__End_Date__c >= TODAY';
        system.debug('batchquery ***'+batchquery);
        return Database.getQueryLocator(batchquery);
    }

    public void execute(Database.BatchableContext batchContext, List<sObject> scope) {
        list<Project_Contract_Line_Item__c> pcliList = new list<Project_Contract_Line_Item__c>();
        list<Case> caseInsertlist = new list<Case>();
        list<Project_Case_Association__c> pcaList= new list<Project_Case_Association__c>();
        set<Id> caseIdsSet = new set<Id>();
        set<Id> projIds = new set<Id>();
        Map<Id,Project_Contract_Line_Item__c> propcliMap = new Map<Id,Project_Contract_Line_Item__c>();
        Map<Id,Project_Case_Association__c> projPcaMap = new Map<Id,Project_Case_Association__c>();
        string batchfreq = 'MONTHLY';

        pcliList = scope;
        system.debug('Scope ***'+ pcliList);
        
        // Value__c should be MONTHLY
        PSA_Common_Setting__mdt freq = [select Id, MasterLabel, Value__c from PSA_Common_Setting__mdt where MasterLabel= 'mPulseCustomerReviewCase' limit 1];
        if (freq.Value__c != '' && freq.Value__c != null){
            batchfreq = freq.Value__c;
            system.debug('batchfreq ***:'+batchfreq);
        }

        // fetching project Ids from the scope 
        for(Project_Contract_Line_Item__c pcliRec : pcliList){
            projIds.add(pcliRec.Project__r.Id);
        }
        system.debug('projIds ***'+ projIds);

        // query pca's by filtering by project Ids used in scope to determine if any pca record was created in same month for that project
        if(!projIds.isEmpty()){
            for (Project_Case_Association__c pcaRec : [select Id,Project__c,createdDate from Project_Case_Association__c where Project__c IN: projIds AND Name = 'mPulse Customer Review Cases' AND Automated_Project_Type__c = 'Automated mPulse Service Cases' limit 50000]){
                if (batchfreq == 'DAILY' && pcaRec.createdDate.Date() == Date.Today()){
                    system.debug('Created date *** :'+ pcaRec.createdDate.Date() + '-' + Date.Today());
                    projPcaMap.put(pcaRec.Project__c, pcaRec);   
                }
                else if(batchfreq == 'MONTHLY' && pcaRec.createdDate.Month() == Date.Today().Month() && pcaRec.createdDate.Year() == Date.Today().Year()){     
                    system.debug('Created month *** :'+ pcaRec.createdDate.Month() + '-' + Date.Today().Month());              
                    projPcaMap.put(pcaRec.Project__c, pcaRec);   
                }                                  
            }
        }
        system.debug('projPcaMap ***'+ projPcaMap);  
        
        //Filtering out the projects that have a pca created same month
        for(Project_Contract_Line_Item__c pcliRec : pcliList){
            if(!projPcaMap.containsKey(pcliRec.Project__c)){ 
                propcliMap.put(pcliRec.Project__r.Id,pcliRec);
            }                
        }
        system.debug('propcliMap ***:'+propcliMap);
        // If Project is active and difference between SD and ED is > 1, create case and PCA for that project
        try{
            for (Project_Contract_Line_Item__c pcliRec : propcliMap.values()){
                date endDate = pcliRec.project__r.pse__End_Date__c; 
                date startDate = pcliRec.project__r.pse__Start_Date__c; // check if sd is in the beginning of the month           

                if (startDate <= Date.Today().tostartofMonth() && endDate >= date.Today().addMonths(1).toStartOfMonth().addDays(-1)){
                    string acctName = '';
                    if(pcliRec.Project__r.pse__Account__r.Name != null){
                        acctName = pcliRec.Project__r.pse__Account__r.Name;
                    }
                    Case ca = new Case();
                    string projectURL = URL.getSalesforceBaseUrl().toExternalForm() +'/' + pcliRec.Project__c;
                    ca.Description = acctName + ' has mPulse Service Tuning Report due this month. \n\n' + projectURL + '\n\n Please prepare the report, reach out to the customer and update this case as closed, once customer acknowledges report delivery.';
                    //ca.Status = 'Unassigned';
                    ca.Request_Type__c = 'Other'; 
                    ca.Subject = acctName +'-'+ System.Today().Month()+' '+ System.Today().year() +' mPulse Service Tuning Report';        
                    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
                    ca.pse_Project__c = pcliRec.project__c;
                    ca.RecordTypeId = recordTypeId;
                    ca.AccountId = pcliRec.Project__r.pse__Account__c;
                    ca.OwnerId = pcliRec.Project__r.pse__Project_Manager__r.pse__Salesforce_User__c;
                    ca.Origin = 'Autogen';
                    ca.Request_Type__c = 'Other';
                    ca.Severity__c = '3';
                    ca.Do_Not_Show_In_Portal__c = True;
                    ca.Service__c = 'mPulse Service';
                    caseInsertlist.add(ca);
                }   
            }
            system.debug('caseInsertlist ***:'+caseInsertlist);   
            if (!caseInsertlist.isEmpty()){
                database.saveResult [] caseResults = database.insert(caseInsertlist,false);
                for(database.saveResult saveRes : caseResults){
                    if(!saveRes.isSuccess()){
                        for(Database.Error err : saveRes.getErrors()) {
                            system.debug(err.getMessage());
                        }
                    }
                    else if(saveRes.isSuccess()){                      
                        caseIdsSet.add(saveRes.getId());
                    } 
                }
            }

            for (Case ca : [select Id, pse_Project__c from Case where Id IN: caseIdsSet]){
                Project_Case_Association__c pca = new Project_Case_Association__c();  
                pca.Project__c = ca.pse_Project__c;
                pca.Contract__c = propcliMap.get(pca.Project__c).Original_Contract_Id__c;
                pca.Name = 'mPulse Customer Review Cases';               
                pca.Autogen_Project__c = false;
                pca.Automated_Project_Type__c = 'Automated mPulse Service Cases';
                pca.Contract_Detail__c = propcliMap.get(pca.Project__c).Contract_Detail__c;
                pca.Case__c = ca.Id;
                pcaList.add(pca);
            }

            if(!pcaList.isEmpty()){
                database.insert (pcaList,false);
            }
        }
        catch(Exception e){
            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
            PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at mPusle customer review Cases batch: ',error);
        }
        
    }  
    public void finish(Database.BatchableContext batchContext) {
       
    } 
}