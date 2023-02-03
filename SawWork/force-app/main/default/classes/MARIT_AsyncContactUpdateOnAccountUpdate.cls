/*
As part of MARIT-502
This class updates fields like Projected Account Owner(PAO) and Projected SDR(PSDR) in Contacts when account's PAO or PSDR
is updated. The update happens in async using queueable apex and this job is called from MARIT_AccountTriggerClass 
*/
public class MARIT_AsyncContactUpdateOnAccountUpdate implements Queueable {
    private Map<Id,SObject> accounts;
    Set<Id> accountIds;
    List<Contact> contactsToUpdate;
    boolean toUpdate;
    public MARIT_AsyncContactUpdateOnAccountUpdate(Map<Id,SObject> accounts,Set<Id> accountIds){
        this.accounts = accounts;
        this.accountIds = accountIds;
        this.contactsToUpdate = new List<Contact>();
        toUpdate = false;
    }
    public void execute(QueueableContext context){
        //updating projected fields in contacts
        //Values of projeted fields are copied from account to contacts
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for(Contact c : [SELECT Id,AccountId,adg_Projected_Account_Owner__c,Projected_SDR__c,Validation_Override__c FROM contact WHERE AccountId IN :accountIds]){
            if(c != null && c.AccountId != null){
                Account acc = (Account)accounts.get(c.AccountId);
                if(acc != null){
                    //MARIT-215 to populate Projected Account Owner from Account to all it's associated contacts
                    if(c.adg_Projected_Account_Owner__c != acc.adg_Projected_Account_Owner__c){
                        c.adg_Projected_Account_Owner__c = acc.adg_Projected_Account_Owner__c;
                        toUpdate = true;
                    }
                    //MARIT-270 to populate Projected SDR from Account to all it's associated contacts
                    if(c.Projected_SDR__c != acc.Projected_SDR__c){
                        c.Projected_SDR__c = acc.Projected_SDR__c;
                        toUpdate = true;
                    }
                    //add to update list if contact is updated
                    if(toUpdate){
                        c.Validation_Override__c = true;
                        contactsToUpdate.add(c);
                        toUpdate = false;
                        System.debug('Contact Id = '+c.Id);
                    }
                }
            }
        }
        if(contactsToUpdate.size() > 0){
            try{
                update contactsToUpdate;
            }
            catch(Exception e)
            {
                Error_Log__c el = new Error_Log__c(Name='populateAccountContactSyncFields', Class__c='MARIT_AsyncContactUpdateOnAccountUpdate', Error_Message__c=e.getMessage());
                errorLogs.add(el);
            }
            if(errorLogs.size() > 0)
                Database.insert(errorLogs, false);
            System.debug('Successfully populated/updated PSO for contacts:'+contactsToUpdate.size());
        }
    }
}