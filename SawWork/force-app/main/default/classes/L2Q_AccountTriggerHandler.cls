//Added as part of SFDC-2851
public class L2Q_AccountTriggerHandler extends ApexTriggerHandlerAbstractClass {
    public static Boolean fieldMappingFirstRunFlag = true;
    public static List<GSM_Settings_Verbose__mdt> fieldMapping = new List<GSM_Settings_Verbose__mdt>();

    public override void beforeInsertBeforeUpdateTrigger(){

        List<Account> accountsTriggerNew = (List<Account>)newList;
        List<Account> accountsTriggerOld = (List<Account>)oldList;
        Map<Id,Account> accountsTriggerNewMap = (Map<Id,Account>)newMap;
        Map<Id,Account> accountsTriggerOldMap = (Map<Id,Account>)oldMap;

        if(Trigger.isInsert){
            L2Q_AccountTriggerClass.beforeInsertUpdate(true, null, accountsTriggerNew, null, null);
        }

        if(Trigger.isUpdate){
            L2Q_AccountTriggerClass.beforeInsertUpdate(false, accountsTriggerOld, accountsTriggerNew, accountsTriggerOldMap, accountsTriggerNewMap);
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){
    }

    public override void afterInsertAfterUpdateTrigger(){

        List<Account> accountsTriggerNew = (List<Account>)newList;
        List<Account> accountsTriggerOld = (List<Account>)oldList;
        Map<Id,Account> accountsTriggerNewMap = (Map<Id,Account>)newMap;
        Map<Id,Account> accountsTriggerOldMap = (Map<Id,Account>)oldMap;
        Map<id,Account> VerticalAccountMap=new map<id,account>();
        list<account> VerticalSubverticalAcc=new list<account>();
        // Contract Share Update.
        //List<Account> updateAccOwnerCShareList = new List<Account>();

        if(fieldMappingFirstRunFlag){
            fieldMapping = [SELECT Value__c FROM GSM_Settings_Verbose__mdt WHERE DeveloperName = 'AccountPlanToAccountFieldMapping' LIMIT 1];
            fieldMappingFirstRunFlag = false;
        }

        Map<String, Object> accountPlanToAccountFieldMapping = (Map<String, Object>)JSON.deserializeUntyped(fieldMapping[0].Value__c);
        Map<String, Account> accountMapToUpdatePlan = new Map<String, Account>();

        if(Trigger.isInsert){
            if(!UserInfo.getName().equalsIgnoreCase('Connection User') && canRun(accountsTriggerNew, false)){
                L2Q_AccountTriggerClass.afterInsertUpdate(true, accountsTriggerOld, accountsTriggerNew, accountsTriggerOldMap, accountsTriggerNewMap);
            }
        }

        if(Trigger.isUpdate && !UserInfo.getName().equalsIgnoreCase('Connection User') && canRun(accountsTriggerNew, false)){
            L2Q_AccountTriggerClass.afterInsertUpdate(false, accountsTriggerOld, accountsTriggerNew, accountsTriggerOldMap, accountsTriggerNewMap);
        }

        if(Trigger.isUpdate && canRun(accountsTriggerNew, false)){
            L2Q_AccountTriggerClass.afterUpdate(accountsTriggerNew, accountsTriggerOldMap);
        }

        /* Start of SFDC-5433 */
        List<Id> childAccountIds = new List<Id>();
        List<Id> parentAccountIds = new List<Id>();
        List<Id> childAccountIdsToDeleteATM = new List<Id>();
        List<Id> oldCompanyIdsToFindOwner = new List<Id>();
        List<Id> companyIdsToFindChildAccounts = new List<Id>();
        List<Id> accountOwnerIdsToDeleteATM = new List<Id>();
        /* End of SFDC-5433 */

        for (Account acc: accountsTriggerNew)
        {
            Account accRecOld = null;
            if(Trigger.isUpdate)
                accRecOld=accountsTriggerOldMap.get(acc.Id);
            
            /*if(Trigger.isUpdate && Util.hasChanges('OwnerId' ,accRecOld, acc) && acc.OwnerID != null){
                updateAccOwnerCShareList.add(acc);
            }*/

            /* Start of SFDC-5433 */
            if((Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Company__c',accRecOld,acc))) && acc.Company__c != null)
            {
                childAccountIds.add(acc.Id);
            }
            //SFDC-5436
            system.debug('account status::'+acc.Division_Formula__c);
            system.debug('account status::'+acc.Account_Status__c);


             /*
            SFDC-6867
            if(Trigger.isUpdate && (!acc.Account_Status__c.contains('Active') || acc.Account_Status__c == 'Inactive') && acc.Division_Formula__c =='Web'){
                if(Util.hasChanges('Division_Formula__c',accRecOld,acc))
                    VerticalSubverticalAcc.add(acc);
                            system.debug('VerticalSubverticalAcc::'+VerticalSubverticalAcc);

            }
            */

            if(Trigger.isUpdate)
            {
                if(acc.IsGlobalAccount__c && (Util.hasChanges('IsGlobalAccount__c',accRecOld,acc) || Util.hasChanges('OwnerId',accRecOld,acc)))
                {
                    parentAccountIds.add(acc.Id);
                }

                if((Util.hasChanges('IsGlobalAccount__c',accRecOld,acc) && !acc.IsGlobalAccount__c) || (Util.hasChanges('OwnerId',accRecOld,acc) && acc.IsGlobalAccount__c))
                {
                    companyIdsToFindChildAccounts.add(acc.Id);
                    accountOwnerIdsToDeleteATM.add(accRecOld.OwnerId);
                }

                if(Util.hasChanges('Company__c',accRecOld,acc) && accRecOld.Company__c != null)
                {
                    oldCompanyIdsToFindOwner.add(accRecOld.Company__c);
                    childAccountIdsToDeleteATM.add(acc.Id);
                }
            }
            /* End of SFDC-5433 */

            for(Object accFieldObj : accountPlanToAccountFieldMapping.values()){
                if(Util.hasChanges(String.valueOf(accFieldObj),accRecOld,acc)){
                    accountMapToUpdatePlan.put(acc.Id, acc);
                }
            }

        }

        if(accountMapToUpdatePlan.size()>0){
            AccountPlanTriggerClass.syncToAccountPlan(accountMapToUpdatePlan, accountPlanToAccountFieldMapping);
        }

        if(!UserInfo.getName().equalsIgnoreCase('Connection User') && canRun(trigger.new, true)){
            GroupSharing.accountShareManagementTrigger(accountsTriggerNew, accountsTriggerOldMap);
        }

        /*if (updateAccOwnerCShareList.size()>0)// && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled')) 
                ContractSharing.updateAccountOwnerContractShare(updateAccOwnerCShareList, accountsTriggerOldMap);*/

        //SFDC-5433
        if(childAccountIds.size() > 0){
            L2Q_AccountTriggerClass.addGlobalAccountManager(childAccountIds,null);
        }

        //SFDC-5433
        if(parentAccountIds.size() > 0){
            L2Q_AccountTriggerClass.addGlobalAccountManager(null,parentAccountIds);
        }

        //SFDC-5433
        if(companyIdsToFindChildAccounts.size() > 0){
            L2Q_AccountTriggerClass.removeGlobalAccountManager(new List<Id>(), companyIdsToFindChildAccounts, accountOwnerIdsToDeleteATM, true);
        }

        //SFDC-5433
        if(oldCompanyIdsToFindOwner.size() > 0){
            L2Q_AccountTriggerClass.removeGlobalAccountManager(childAccountIdsToDeleteATM, oldCompanyIdsToFindOwner, new List<Id>(), false);
        }

        /*
        //SFDC-5436
        //SFDC-6867
        if(VerticalSubverticalAcc.size() >0){
            L2Q_AccountTriggerClass.UpdateVerticalSubVerticalStatus(VerticalSubverticalAcc,VerticalAccountMap,true);
        
        }
        */

    }

    public override void afterDeleteAfterUndeleteTrigger(){
        if(Trigger.isDelete){
            List<Account> accountsTriggerOld = (List<Account>)oldList;

            if(!UserInfo.getName().equalsIgnoreCase('Connection User') && canRun(accountsTriggerOld, false)){
                  System.Debug(LoggingLevel.Error, 'AGH_D entering triggers');
                  L2Q_AccountTriggerClass.afterDelete(accountsTriggerOld);
            }
        }
    }

   // Merged canRun from AccountTrigger and AccountShareManagement Trigger
   private Boolean canRun(List<Account> allAccounts, Boolean isAccGroupShare)
    {
        if(L2Q_AccountTriggerClass.wasTriggerAndWfOverrideSet && !isAccGroupShare)
            return false;

        if(!GroupSharing.accountShareManagementTriggerFirstRunFlag && isAccGroupShare)
            return false;

        for(Account acc : allAccounts)
        {
            if(acc.TriggerAndWF_Override__c)
            {
                if(!isAccGroupShare){
                    l2Q_AccountTriggerClass.wasTriggerAndWfOverrideSet=true;
                    return false;
                }else {
                    GroupSharing.accountShareManagementTriggerFirstRunFlag=false;
                    return false;
                }

            }
        }
        return true;
    }

}