//Modified as part of SFDC-2851
// -------
public class AccountTriggerHandler extends ApexTriggerHandlerAbstractClass {

    public override void beforeInsertBeforeUpdateTrigger(){

        List<Account> accountsTriggerNew = (List<Account>)newList;
        List<Account> accountsTriggerOld = (List<Account>)oldList;
        Map<Id,Account> accountsTriggerNewMap = (Map<Id,Account>)newMap;
        Map<Id,Account> accountsTriggerOldMap = (Map<Id,Account>)oldMap;
        System.Debug('Mayank, call came to AccountTriggerHandler beforeInsertBeforeUpdateTrigger :' +accountsTriggerNew);
        
        if(!UserInfo.getName().equalsIgnoreCase('Connection User') && canRun(newList)){
            if(Trigger.isInsert)
                AccountTriggerClass.beforeInsertUpdate(true, null, accountsTriggerNew, null, null);

            if(Trigger.isUpdate)
                AccountTriggerClass.beforeInsertUpdate(false, accountsTriggerOld, accountsTriggerNew, accountsTriggerOldMap, accountsTriggerNewMap);
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){
        System.Debug('Mayank, call came to AccountTriggerHandler beforeDeleteBeforeUndeleteTrigger');
    }

    public override void afterInsertAfterUpdateTrigger(){
        List<Account> accountsTriggerNew = (List<Account>)newList;
        List<Account> accountsTriggerOld = (List<Account>)oldList;
        Map<Id,Account> accountsTriggerNewMap = (Map<Id,Account>)newMap;
        Map<Id,Account> accountsTriggerOldMap = (Map<Id,Account>)oldMap;
        System.Debug('Mayank, call came to AccountTriggerHandler afterInsertAfterUpdateTrigger :' +accountsTriggerNew);
        
        if(Trigger.isUpdate){
            if(canRun(accountsTriggerNew)) {
                AccountTriggerClass.afterUpdate(accountsTriggerNew, accountsTriggerOldMap);
            }
        }
        if(Trigger.isInsert){
            
            AccountTriggerClass.afterInsert(accountsTriggerNew);
            
        }

    }

    public override void afterDeleteAfterUndeleteTrigger(){
        System.Debug('Mayank, call came to AccountTriggerHandler afterDeleteAfterUndeleteTrigger');
    }   

    private Boolean canRun(List<Account> allAccounts)
    {
        if(L2Q_AccountTriggerClass.wasTriggerAndWfOverrideSet)
            return false;

        for(Account acc : allAccounts)
        {
            if(acc.TriggerAndWF_Override__c)
            {
                l2Q_AccountTriggerClass.wasTriggerAndWfOverrideSet=true;
                return false;
            }
        }

        return true;
    }

}