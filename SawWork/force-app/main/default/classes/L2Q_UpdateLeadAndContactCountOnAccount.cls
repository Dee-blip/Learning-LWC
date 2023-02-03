/*Created By: Vivek Baidya
* Created Date: 12-Nov-2020
* JIRA: SFDC-7475
* Description: Update Lead And Contact Count On Account.
* Last Chnages Done By Rajul Vishwakarma
* JIRA Story : SFDC-9138
*/
public class L2Q_UpdateLeadAndContactCountOnAccount implements Queueable {
    
    public void execute(QueueableContext context) {

        // Collecting the account ids from helperObect
        Integer batchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('UpdateLeadAndContactCountBatchSize'));
        Map<Id,Count_Leads_And_Contacts_On_Acc_Helper__c> mapAccIdwithAccHelperObjs = new Map<Id,Count_Leads_And_Contacts_On_Acc_Helper__c>();
        List<Count_Leads_And_Contacts_On_Acc_Helper__c> accHelperObjs = [Select Id,Account_Id__c,Error_Message__c,isProcessed__c from Count_Leads_And_Contacts_On_Acc_Helper__c where isProcessed__c = FALSE LIMIT :batchSize];
        if(accHelperObjs == null){
            return;
        }
        for(Count_Leads_And_Contacts_On_Acc_Helper__c aho:accHelperObjs){
            mapAccIdwithAccHelperObjs.put(aho.Account_Id__c,aho);
        }
        Set<Id> accountIdsToProcess = mapAccIdwithAccHelperObjs.keySet();
        //List<Account> accountsToUpdate = new List<Account>();
        Map<Id,Count_Leads_And_Contacts_On_Acc_Helper__c> accHelperListToUpdate = new Map<Id,Count_Leads_And_Contacts_On_Acc_Helper__c>();
        List<Account> accListToUpdate = new List<Account>();
        try{
            //get the count of lead & contact for each account and set the latest count
            Map<Id,Account> accMapToProcess = new Map<Id,Account>([SELECT Id,Number_of_Associated_Contacts__c,Number_of_Associated_Leads__c FROM Account WHERE (NOT Name LIKE '%DO NOT DELETE%') AND Id = :accountIdsToProcess]);
            Map<Id,Integer> accIdMapWithContacts = new Map<Id,Integer>();
            Map<Id,Integer> accIdMapWithLeads = new Map<Id,Integer>();
            for (AggregateResult aggContacts:[SELECT Count(ID) cntContacts, AccountId FROM Contact WHERE AccountId IN :accountIdsToProcess GROUP BY AccountId]) {
                accIdMapWithContacts.put((Id) aggContacts.get('AccountId'),(Integer) aggContacts.get('cntContacts'));
            }
            for (AggregateResult aggLeads:[SELECT Count(ID) cntLeads, Associated_Account__c FROM Lead WHERE IsConverted=false AND Associated_Account__c IN :accountIdsToProcess GROUP BY Associated_Account__c]) {
                accIdMapWithLeads.put((String) aggLeads.get('Associated_Account__c'),(Integer) aggLeads.get('cntLeads'));
            }
            for(Id accId:accountIdsToProcess){
                Account ac = new Account(Id = accId);
                ac.Number_of_Associated_Contacts__c = accIdMapWithContacts.containsKey(accId)? accIdMapWithContacts.get(accId) : 0;
                ac.Number_of_Associated_Leads__c = accIdMapWithLeads.containsKey(accId)? accIdMapWithLeads.get(accId) : 0;
                if(accMapToProcess.containsKey(accId)){
                    if(accMapToProcess.get(accId).Number_of_Associated_Contacts__c != ac.Number_of_Associated_Contacts__c || accMapToProcess.get(accId).Number_of_Associated_Leads__c != ac.Number_of_Associated_Leads__c){
                        Count_Leads_And_Contacts_On_Acc_Helper__c ah = mapAccIdwithAccHelperObjs.get(accId);
                        ah.isProcessed__c = true;
                        ah.Error_Message__c = '';
                        accHelperListToUpdate.put(accId,ah);
                        accListToUpdate.add(ac);
                    }
                    else{
                        Count_Leads_And_Contacts_On_Acc_Helper__c ah = mapAccIdwithAccHelperObjs.get(accId);
                        ah.isProcessed__c = true;
                        ah.Error_Message__c = '';
                        accHelperListToUpdate.put(accId,ah);
                    }
                }
                else{
                    Count_Leads_And_Contacts_On_Acc_Helper__c ah = mapAccIdwithAccHelperObjs.get(accId);
                    ah.isProcessed__c = true;
                    ah.Error_Message__c = '';
                    accHelperListToUpdate.put(accId,ah);
                }
            }
        }
        catch(Exception ex){
            Sawyer.saw(ex);
        }
        
        //update accounts with the latest lead & contact count
        if(!accListToUpdate.isEmpty()){
            ByPassAndLimitUtils.disable('AccountTriggerGeneric');
            Database.SaveResult[] saveRes = Database.Update(accListToUpdate, false);
            for(Database.SaveResult sr:saveRes){
                if(!sr.isSuccess() && accHelperListToUpdate.containsKey(sr.getId())){
                    Count_Leads_And_Contacts_On_Acc_Helper__c ah = accHelperListToUpdate.get(sr.getId());
                    ah.isProcessed__c = false;
                    ah.Error_Message__c = sr.getErrors().isEmpty()? '' : String.join(sr.getErrors(),',');
                    accHelperListToUpdate.put(sr.getId(),ah);
                }
            }
            Database.update(accHelperListToUpdate.values(),false);
        }

        //enqueue the class for remaining account ids
        if(accHelperObjs.size() == batchSize){
            System.enqueueJob(new L2Q_UpdateLeadAndContactCountOnAccount());
        }
        
    }
}