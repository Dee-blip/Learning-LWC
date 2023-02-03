public class AccountUtilClass
{

    public static Id getUserRSM(Account_Reassignment_Rule__c assignToRule)
    {
        if(assignToRule.Associated_User_RSM__c != null 
                && assignToRule.Associated_User_RSM__r.IsActive )
            return assignToRule.Associated_User_RSM__c;
        else if(assignToRule.Associated_User__r.ManagerId != null 
                && assignToRule.Associated_User__r.Manager.IsActive)
            return assignToRule.Associated_User__r.ManagerId;
        else
            return null;
    }

}