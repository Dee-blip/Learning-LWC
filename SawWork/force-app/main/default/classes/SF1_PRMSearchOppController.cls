/**
 @author: Shubham Richhariya
 MOB-71 : Controller For Locate Opportunity functionalities in Salesforce1

 * History:
 * =========================
 * Developer        Date        Description
    
   Shubham    27/March/17       Added this class for MOB-71.
   Shubham    05/April/17       updated getOpportunity to introduce pagination in SF1 app
   Shubham    08/April/17       updated return types of getAddOppty and getCreate to capture Error messages thrown.
**/

global without sharing class SF1_PRMSearchOppController {
    
    @AuraEnabled
    public static String getCurrentOpportunityAccountId(Id opptyId) {
        Opportunity currentOppty = SF1_OpportunityService.getOpportunity(opptyId);
        return currentOppty.AccountId+' ';
    }
    
    @AuraEnabled
    public static List<Opportunity> getOpportunity(Id opptyId,Integer pagesize , Integer offset, String orderBy) {
        Opportunity currentOppty = SF1_OpportunityService.getOpportunity(opptyId);
        List<Opportunity> opps =   SF1_OpportunityService.getExistingOpportunityList(currentOppty,pagesize,offset,orderBy);
        return opps;
    }

    @AuraEnabled
    public static String getAddOppty(Id opptyId,Id pid) 
    {
        Opportunity currentOppty = SF1_OpportunityService.getOpportunity(opptyId);
        String message = SF1_LocateAccAndExistingOppService.updateOpportunityAfterLinkedToDR(currentOppty,pid);
        return message;
    }
    
    @AuraEnabled
    public static String getCreate(Id oppId) 
    {
        Opportunity currentOppty = SF1_OpportunityService.getOpportunity(oppId);
        String message=SF1_LocateAccAndExistingOppService.updateOpportunityAfterAcceptAsNew(currentOppty);
        return message;
    }

}