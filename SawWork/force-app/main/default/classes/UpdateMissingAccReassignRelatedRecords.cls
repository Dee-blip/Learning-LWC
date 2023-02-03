global class UpdateMissingAccReassignRelatedRecords implements Database.Batchable<Sobject>, Database.Stateful {
    global final string query;
    
    public UpdateMissingAccReassignRelatedRecords(){
        query='select Id,Is_Opportunity_Failed__c,Is_Contact_Failed__c,Account__c from Account_Reassignment__c where Reassign_Status__c=\'Accepted\' and (Is_Opportunity_Failed__c=true or Is_Contact_Failed__c=true) order by CreatedDate desc';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        list<string> contactFailureAccIds = new list<string>();
        list<string> opptyFailureAccIds = new list<string>();
        list<string> opportunityFailureAccIds = new list<string>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        map<string,Account_Reassignment__c> accIdToReassignment = new map<string,Account_Reassignment__c>();
        for(Account_Reassignment__c aR : (List<Account_Reassignment__c>)scope){
            if(!accIdToReassignment.containsKey(aR.Account__c)){
                if(aR.Is_Contact_Failed__c){
                    aR.Is_Contact_Failed__c=false;
                    contactFailureAccIds.add(aR.Account__c);
                }
                if(aR.Is_Opportunity_Failed__c){
                    aR.Is_Opportunity_Failed__c=false;
                    opptyFailureAccIds.add(aR.Account__c);
                }
                aR.Validation_Override__c=true;
                accIdToReassignment.put(aR.Account__c,aR);
            }
        }
        if(contactFailureAccIds.size()>0){
            list<Contact> conListToUpdate = new list<Contact>();
            boolean needUpdate=false;
            for(Contact con : [select Id, OwnerId, adg_Projected_Account_Owner__c, Projected_SDR__c, Account.OwnerId, Account.adg_Projected_Account_Owner__c, Account.Projected_SDR__c from Contact where AccountId IN : contactFailureAccIds]){
                if(con.OwnerId != con.Account.OwnerId){
                    con.OwnerId = con.Account.OwnerId;
                    needUpdate = true;
                }
                /* Start of Marketing Team Changes */
                if(con.adg_Projected_Account_Owner__c != con.Account.adg_Projected_Account_Owner__c){
                    con.adg_Projected_Account_Owner__c = con.Account.adg_Projected_Account_Owner__c;
                    needUpdate = true;
                }
                if(con.Projected_SDR__c != con.Account.Projected_SDR__c){
                    con.Projected_SDR__c = con.Account.Projected_SDR__c;
                    needUpdate = true;
                }
                /* End of Marketing Team Changes */
                if(needUpdate){
                    con.Validation_Override__c = true;
                    conListToUpdate.add(con);
                }
            }
            if(conListToUpdate.size()>0){
                Database.SaveResult[] saveRes = Database.Update(conListToUpdate, false);
                Integer count = 0;
                for(Database.SaveResult result : saveRes){
                    String errMessage = '';
                    if(!result.isSuccess()){
                        for(Database.Error err : result.getErrors())
                            errMessage += err.getMessage() + '\n';
                        Map<String, Object> fieldsToValue = conListToUpdate[count].getPopulatedFieldsAsMap();
                        String objectState = JSON.serialize(fieldsToValue);
                        Error_Log__c el = new Error_Log__c(Name='ContactUpdate', Class__c='UpdateMissingAccReassignRelatedRecords', Error_Message__c=errMessage , Object_State__c=objectState);
                        errorLogs.add(el);
                        Account_Reassignment__c aR = accIdToReassignment.get(String.valueOf(fieldsToValue.get('AccountId')));
                        aR.Is_Contact_Failed__c=true;
                        accIdToReassignment.put(String.valueOf(fieldsToValue.get('AccountId')),aR);
                    }
                    count += 1;
                }
            }
        }
        if(opptyFailureAccIds.size()>0){
            list<string> oppRecTypesToProcess = new list<string>();
            oppRecTypesToProcess.addAll(GsmUtilClass.getAccountReassignSettingValue('OppRecordTypeIdsToReassign').split(','));
            list<Opportunity> oppListToUpdate = new list<Opportunity>();
            for(Opportunity opp : [select Id, OwnerId, Account.OwnerId from Opportunity where AccountId IN : opptyFailureAccIds and RecordTypeId IN : oppRecTypesToProcess and (NOT StageName like 'Closed%')]){
                if(opp.OwnerId != opp.Account.OwnerId){
                    opp.OwnerId = opp.Account.OwnerId;
                    opp.Opportunity_Owner_Copy__c = opp.Account.OwnerId;
                    opp.Validation_Override__c = true;
                    oppListToUpdate.add(opp);
                }
            }
            if(oppListToUpdate.size()>0){
                Database.SaveResult[] saveRes1 = Database.Update(oppListToUpdate, false);
                Integer count1 = 0;
                for(Database.SaveResult result : saveRes1){
                    String errMessage1 = '';
                    if(!result.isSuccess()){
                        for(Database.Error err : result.getErrors())
                            errMessage1 += err.getMessage() + '\n';
                        Map<String, Object> fieldsToValue1 = oppListToUpdate[count1].getPopulatedFieldsAsMap();
                        String objectState1 = JSON.serialize(fieldsToValue1);
                        Error_Log__c el1 = new Error_Log__c(Name='OpportunityUpdate', Class__c='UpdateMissingAccReassignRelatedRecords', Error_Message__c=errMessage1 , Object_State__c=objectState1);
                        errorLogs.add(el1);
                        Account_Reassignment__c aR1 = accIdToReassignment.get(String.valueOf(fieldsToValue1.get('AccountId')));
                        aR1.Is_Opportunity_Failed__c=true;
                        accIdToReassignment.put(String.valueOf(fieldsToValue1.get('AccountId')),aR1);
                    }
                    count1 += 1;
                }
            }
        }
        if(accIdToReassignment.size()>0){
            ByPassAndLimitUtils.disable('AccountReassignmentTrigger');
            GsmUtilClass.doDatabaseUpdate(accIdToReassignment.values(),'UpdateMissingAccReassignRelatedRecords','AccountReassignmentUpdate');
        }
        if(errorLogs.size()>0){
            Database.insert(errorLogs,false);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        string results = 'Job Completed.';
        Util.updateCronRunWithResult('Update Missing Account Reassign Related Records', results);
    }
}