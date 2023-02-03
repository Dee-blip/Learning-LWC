//Created by nagarajg as part of MARIT-215, 
//MARIT-525 Removed logic of finding PAO based on DGRAT values, going fwd PAO will be be updated for those Accs having PSO. 
//Confirmed with business and jira updated
public class MARIT_AccountTriggerClass {
    public static void populateProjectedAccountOwner (List<Account> accountsTriggerNew,List<Id> ownerIds){
        
        Map<Id,Account_Reassignment_Rule__c> OwnerToAccReassignMap = new Map<Id,Account_Reassignment_Rule__c>();
        List<Id> projectedSalesOwnerIdList = new List<Id>();
        
        if(accountsTriggerNew.size() > 0){
            LeadToContactConversionClass.populateProjectedSalesOwner(accountsTriggerNew);
        }

        for(Account acc : accountsTriggerNew){
            if(acc != null && acc.Projected_Sales_Owner__c != null){
                    projectedSalesOwnerIdList.add(acc.Projected_Sales_Owner__c);
            }
        }
        
        if(projectedSalesOwnerIdList.size() > 0){
            for(Account_Reassignment_Rule__c accReassign:[Select id,
                    AccountReassignmentRuleAutoID__c,
                    Associated_User__c from Account_Reassignment_Rule__c
                    where Associated_User__c in :projectedSalesOwnerIdList and (NOT Name like 'OLD_%')
                    order by AKAM_Modified_Date__c desc]){
                if(!OwnerToAccReassignMap.containsKey(accReassign.Associated_User__c))
                    OwnerToAccReassignMap.put(accReassign.Associated_User__c, accReassign);
            }
        }
        
        System.debug('No of Account reassignment = '+OwnerToAccReassignMap.size());
        if(OwnerToAccReassignMap.size() > 0){
            for(Account acc : accountsTriggerNew){
                if(acc != null && acc.Projected_Sales_Owner__c != null && OwnerToAccReassignMap.get(acc.Projected_Sales_Owner__c) != null){
                            acc.adg_Projected_Account_Owner__c = OwnerToAccReassignMap.get(acc.Projected_Sales_Owner__c).id;
                }
            }
        }
    }

    public static void createAccountReassignmentRequest(Map<Id, Id> accountToReassignmentRuleMap){
        List<Account_Reassignment__c> accReassignList = new List<Account_Reassignment__c>();
        for(Id accId: accountToReassignmentRuleMap.keySet()){
            if(accountToReassignmentRuleMap.get(accId) != null){
                Account_Reassignment__c accReassign=new Account_Reassignment__c();
                accReassign.Account__c=accId;
                accReassign.Assign_To__c=accountToReassignmentRuleMap.get(accId);
                //accReassign.CurrencyIsoCode = acc.CurrencyIsoCode;
                accReassign.Reassign__c=true;
                accReassign.Reason_Code__c='Fill Unused Hunter Capacity';
                accReassignList.add(accReassign);
            }
        }
        insert accReassignList;
    }
}