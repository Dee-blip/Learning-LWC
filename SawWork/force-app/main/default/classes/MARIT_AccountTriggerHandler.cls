//Created by nagarajg as part of MARIT-215
public class MARIT_AccountTriggerHandler extends ApexTriggerHandlerAbstractClass{
    public override void beforeInsertBeforeUpdateTrigger(){
        List<Account> accountsToProcess = new List<Account>();
        List<Id> AccOwnerIds = new List<Id>();
        List<String> PAODependentFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('PAODependentFieldsInAccount');
        PAODependentFields = String.join(PAODependentFields,',').split('\\s*,\\s*');
        Set<String> PAODependentFieldsInAccountSet = new Set<String>(PAODependentFields);
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsTriggerNew = (List<Account>)newList;
        String ONALIst = GsmUtilClass.getGSMSettingValue('ONAPoolOpsIdList'); //MARIT-359
        List<String> akamAccIdsWithSOQLError = new List<String>();//MARIT-318
        if(MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException') != null){
            akamAccIdsWithSOQLError = MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException').replaceAll(' ', '').split(',');
        }
        List<String> AccountFormulaFieldsForCDP = MarketingUtilClass.getMarketingSettingValuePartialMatch('AccountFormulaFieldsForCDP');
        AccountFormulaFieldsForCDP = String.join(AccountFormulaFieldsForCDP,',').split('\\s*,\\s*');
        Set<String> ChangesInAccountFormulaFieldsForCDP = new Set<String>(AccountFormulaFieldsForCDP);

        for(Account acc: accountsTriggerNew){
            Account newAccount = (Account)acc;
            Account oldAcc;
            if(Trigger.isInsert){
            
                if(!ONALIst.contains(newAccount.OwnerId)){ //MARIT-359
                    newAccount.Projected_Sales_Owner__c = newAccount.OwnerId;
                } else {
                    newAccount.Projected_Sales_Owner__c = null;//MARIT-676
                }
                //add new accounts to populate PAO in bulk
                accountsToProcess.add(newAccount);
                AccOwnerIds.add(newAccount.ownerId);
            }
            //calculate PAO when there is any update on PAODependentFields and akam account id not in AccountsHavingSOQLLimitException
            //PAODependentFields: Vertical__c,Sub_Vertical__c,OwnerId,BillingCountry,BillingState
            //AccountsHavingSOQLLimitException: 1-40V5,1-599K,F-AC-1906560,AANA-OQUT1
            if(Trigger.isUpdate && Trigger.isBefore){
                Account oldAccount = (Account)oldMap.get(newAccount.Id);
                if(Util.hasChanges(ChangesInAccountFormulaFieldsForCDP,oldAccount,newAccount)){
                    newAccount.Updated_Date_For_CDP__c=System.now();
                }
                if(Util.hasChanges(PAODependentFieldsInAccountSet,oldAccount,newAccount) && !akamAccIdsWithSOQLError.contains(newAccount.AKAM_Account_ID__c)){
                    // In populateProjectedAccountOwner, line 15 there is check for PSO value to be null, only then PSO is calculated. Hence making PSO null so that new value will be calculated
                    //MARIT-676
                    if(!ONALIst.contains(newAccount.OwnerId)){
                        newAccount.Projected_Sales_Owner__c = newAccount.OwnerId;
                    } else {
                        newAccount.Projected_Sales_Owner__c = null;
                    }
                    newAccount.adg_Projected_Account_Owner__c = null;
                    accountsToProcess.add(newAccount);
                    AccOwnerIds.add(newAccount.ownerId);
                    System.debug('Account id for which PSO needs to be updated. Id = ' +newAccount.Id);
                }
            }
        }
        if(accountsToProcess.size() > 0){
            System.debug('No of records to populate/update PSO = '+accountsToProcess.size());
            MARIT_AccountTriggerClass.populateProjectedAccountOwner(accountsToProcess,AccOwnerIds);
            accountsToProcess.clear(); 
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }

    public override void afterInsertAfterUpdateTrigger(){
        List<Account> accountsTriggerNew = (List<Account>)newList;
        Set<Id> accountIds = new Set<Id>();
        List<String> PAODependentFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('PAODependentFieldsInAccount');
        PAODependentFields = String.join(PAODependentFields,',').split('\\s*,\\s*');
        Set<String> PAODependentFieldsInAccountSet = new Set<String>(PAODependentFields);
        Set<String> PAODependentFieldsInAccountWithoutOwnerSet = new Set<String>(MarketingUtilClass.getMarketingSettingsValue('PAODependentFieldsInAccountWithoutOwner').split(',')); //MARIT-452
        List<String> akamAccIdsWithSOQLError = new List<String>();//MARIT-318
        Account newAccount;
        Account oldAccount;
        if(MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException') != null){
            akamAccIdsWithSOQLError = MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException').replaceAll(' ', '').split(',');
        }
        if(Trigger.isUpdate && Trigger.isAfter){
            for(Account acc: accountsTriggerNew){
                newAccount = (Account)acc;
                oldAccount = (Account)oldMap.get(acc.Id);
                /*if PAODependentFields is changed in account, PAO and PSDR are updated(sync) in account,these updates(async) are also cascaded to its 
                associated leads and contacts*/
                //added projected account owner changes condition for marit-1264
                if((Util.hasChanges('adg_Projected_Account_Owner__c',oldAccount,newAccount) || Util.hasChanges(PAODependentFieldsInAccountSet,oldAccount,newAccount)) && !akamAccIdsWithSOQLError.contains(newAccount.AKAM_Account_ID__c)){
                    if((Util.hasChanges('adg_Projected_Account_Owner__c',oldAccount,newAccount) || Util.hasChanges(PAODependentFieldsInAccountWithoutOwnerSet,oldAccount,newAccount)) && !Util.hasChanges('OwnerId',oldAccount,newAccount)) //MARIT-452
                        accountIds.add(newAccount.Id);
                }
            }
        }
        System.debug('Leads/Contacts for which Projected fields needs to be updated. Id = ' +accountIds);
        if(accountIds.size() > 0){
            System.debug('Updating PSO for associated leads and contacts in async mode');
            MARIT_AsyncLeadUpdateOnAccountUpdate updateLeadsAsync = new MARIT_AsyncLeadUpdateOnAccountUpdate(newMap,accountIds);
            ID jobIDLeads = System.enqueueJob(updateLeadsAsync);
            System.debug('Leads Queueable Apex Job Id = '+ jobIDLeads);
            MARIT_AsyncContactUpdateOnAccountUpdate updateContactsAsync = new MARIT_AsyncContactUpdateOnAccountUpdate(newMap,accountIds);
            ID jobIDContacts = System.enqueueJob(updateContactsAsync);
            System.debug('Contacts Queueable Apex Job Id = '+ jobIDContacts);
        }
    }

    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
}