/*
As part of MARIT-502
This class updates fields like Projected Account Owner(PAO) and Projected SDR(PSDR) in leads when account's PAO or PSDR
is updated. The update happens in async using queueable apex and this job is called from MARIT_AccountTriggerClass 
*/
public class MARIT_AsyncLeadUpdateOnAccountUpdate implements Queueable{
    Map<Id,SObject> accounts;
    Set<Id> accountIds;
    List<Lead> leadsToUpdate;
    boolean toUpdate;
    public MARIT_AsyncLeadUpdateOnAccountUpdate(Map<Id,SObject> accounts,Set<Id> accountIds){
        this.accounts = accounts;
        this.accountIds = accountIds;
        this.leadsToUpdate = new List<Lead>();
        this.toUpdate = false;
    }
    //updating projected fields in leads. Values of projeted fields are copied from account to leads
    public void execute(QueueableContext context){
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        Map<String,Id> recordTypeNameIdMap = new Map<String,Id>();
        Map<String,Schema.RecordTypeInfo> recordTypeInfo = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName();
        //<lead record type, record id> mapping
        for(String recordName: recordTypeInfo.keySet()){
            Schema.RecordTypeInfo recInfo = recordTypeInfo.get(recordName);
            if(recInfo.isAvailable()){
                recordTypeNameIdMap.put(recordName,recInfo.getRecordTypeId());
            }
        }
        for(Lead l : [SELECT Id,Associated_Account__c,adg_Projected_Account_Owner__c,Projected_SDR__c,Validation_Override__c,Website,RecordTypeId FROM Lead WHERE Associated_Account__c IN :accountIds AND (RecordTypeId = :recordTypeNameIdMap.get('Marketo Lead') OR RecordTypeId = :recordTypeNameIdMap.get('Akamai Lead')) AND (Status = 'New' OR Status = 'In Process')]){
            if(l != null && l.Associated_Account__c != null){
                Account acc = (Account)accounts.get(l.Associated_Account__c);
                if(acc != null){
                    //MARIT-215 to populate Projected Account Owner from Account to all it's associated leads
                    if(l.adg_Projected_Account_Owner__c != acc.adg_Projected_Account_Owner__c){
                        l.adg_Projected_Account_Owner__c = acc.adg_Projected_Account_Owner__c;
                        toUpdate = true;
                    }
                    //MARIT-270 to populate Projected SDR from Account to all it's associated marketo leads
                    if(l.Projected_SDR__c != acc.Projected_SDR__c && l.RecordTypeId==recordTypeNameIdMap.get('Marketo Lead')){
                        l.Projected_SDR__c = acc.Projected_SDR__c;
                        toUpdate = true;
                    }
                    //Moving from L2A account trigger class. Website sync
                    if(l.RecordTypeId != recordTypeNameIdMap.get('Marketo Lead') && l.Website != acc.Website) {
                        l.Website = acc.Website;
                        toUpdate = true;
                    }
                    //add to update list if lead is updated
                    if(toUpdate){
                        l.Validation_Override__c = true;
                        leadsToUpdate.add(l);
                        toUpdate = false;
                        System.debug('Lead updated = '+l.Id);
                    }
                }
            }
        }
        if(leadsToUpdate.size() > 0){
            try{
                update leadsToUpdate;
            }
            catch(Exception e)
            {
                Error_Log__c el = new Error_Log__c(Name='populateAccountLeadSyncFields', Class__c='MARIT_AsyncLeadUpdateOnAccountUpdate', Error_Message__c=e.getMessage());
                errorLogs.add(el);
            }
            if(errorLogs.size() > 0)
                Database.insert(errorLogs, false);
            System.debug('Successfully populated/updated Projected fields for leads:'+leadsToUpdate.size());
        }
    }
}