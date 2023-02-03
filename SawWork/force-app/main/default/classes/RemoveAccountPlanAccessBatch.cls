//SFDC-6112 : Remove Account Plan Access
global class RemoveAccountPlanAccessBatch implements Database.Batchable<Sobject>, Database.Stateful {
    global final string query;
    global integer totalAccessRemoved;
    
    global RemoveAccountPlanAccessBatch(){
        totalAccessRemoved=0;
        query='select Id,Account__c,Account_Team_Member_s_Email__c,Quip_New_Document_URL__c,Account__r.Removed_Account_Team_Emails__c from Account_Plan__c where Quip_New_Document_URL__c != null and Account__r.Removed_Account_Team_Emails__c != null';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        map<Id,Account> accListToUpdate = new map<Id,Account>();
        list<Account_Plan__c> accPlanList = (List<Account_Plan__c>)scope;
        boolean needUpdate=false;
        for(Account_Plan__c plan : accPlanList){
            plan.Account_Team_Member_s_Email__c = plan.Account__r.Removed_Account_Team_Emails__c;
            if(!accListToUpdate.containsKey(plan.Account__c))
                accListToUpdate.put(plan.Account__c,new Account(Id=plan.Account__c,Removed_Account_Team_Emails__c=null,Validation_Override__c=true));
        }
        if(accPlanList.size()>0){
            Flow.Interview flow = new Flow.Interview.Remove_Account_Plan_Access(new map<String, Object>{'AccountPlans'=>accPlanList});
            try{
                flow.start();
                if(accListToUpdate.size()>0){
                    totalAccessRemoved=totalAccessRemoved+accPlanList.size();
                    ByPassAndLimitUtils.disable('AccountTriggerGeneric');
                    GsmUtilClass.doDatabaseUpdate(accListToUpdate.values(),'RemoveAccountPlanAccessBatch','Removed_Account_Team_Emails_Update');
                }
            }
            catch(Exception e){
                Error_Log__c eL = new Error_Log__c(Name='Not Authorized',Class__c='RemoveAccountPlanAccessBatch',Error_Message__c=e.getMessage());
                Database.insert(new List<Error_Log__c>{eL},false);
            }
        }        
    }
    global void finish(Database.BatchableContext BC) {
        string results = 'Job Completed. Access Removed: '+totalAccessRemoved;
        Util.updateCronRunWithResult('Remove Account Plan Access', results);
    }
}