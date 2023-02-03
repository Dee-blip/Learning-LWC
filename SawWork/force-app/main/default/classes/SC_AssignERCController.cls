/*****************************************************************************
 * Developer    : Sharath Prasanna
 * Enhancement  : Assign ERC value to an Account. This will be associated to a lightning action.
 * Date         : 16th March 2020
 * Jira         : ESESP-3539
 ---------------------------------------------------
 */ 
public class SC_AssignERCController 
{
    public class ResponseWrapper
    {
        Boolean isValid;
        String accountNames;
        public ResponseWrapper()
        {
            isValid = true;
            accountNames = '';
        }
    }
    @AuraEnabled
    public static String getERCWrapper(String accountId, String currentERC )
    {
        ResponseWrapper responseWrapperObject = new ResponseWrapper();
        if(!String.isBlank(currentERC))
        {
            String numericERC = SupportTeamMgmt_Utility.getERCNumeric(currentERC);
            Set<Id> accountIds = new Set<Id>();
            String accountNames = '<b>';        
            Set<Id> supportTeamIds = new Set<Id>();
            for (Account accountRec: [Select Id, Name from Account where ERC_Numeric__c = :numericERC])
            {
                accountIds.add(accountRec.Id);
                accountNames += accountRec.Name + ',';
            }
            if(accountIds.size() > 0)
            {
                accountNames = accountNames.substring(0,accountNames.length() - 1);
                accountNames += '</b>';
                accountIds.add(accountId);
                for(TS_TeamAccount__c teamAccount : [Select TS_Support_Team__c, Team_Account__c from TS_TeamAccount__c 
                                                     where Team_Account__c in :accountIds order by createddate desc])
                {
                    supportTeamIds.add(teamAccount.TS_Support_Team__c);
                    if(supportTeamIds.size() > 1)
                    {
                        responseWrapperObject.isValid = false;
                        break;
                    }
                }
                if(accountNames.length() > 0)
                {
                    responseWrapperObject.accountNames = accountNames;
                }
            }
            
        }
                    
        return JSON.serializePretty(responseWrapperObject);
   }
}