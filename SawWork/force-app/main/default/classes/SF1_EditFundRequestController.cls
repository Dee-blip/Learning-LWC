/**
 @author: Shubham Richhariya
 MOB-154 : Controller for edit fund request
 * History:
 * =========================
 * Developer        Date        Description
    
   Shubham    21/June/17        Added this class for MOB-154
**/

global without sharing class SF1_EditFundRequestController {
    
    @AuraEnabled
    public static Boolean hasEditingRights(Id recordID)
    {   
        Boolean accessAllowed = SF1_FundRequestService.hasEditingRights(recordID);
        return accessAllowed;
    }
    
    @AuraEnabled
    public static SFDC_MDF__c getPageObject(Id recordID)
    {
        SFDC_MDF__c pageObject = SF1_FundRequestService.getPageObjectForEditFundRequest(recordID);
        return pageObject;
    }
    
    @AuraEnabled
    public static Boolean checkIfStatusSubmitted(Id recordID)
    {   
        SFDC_MDF__c pageObject = SF1_FundRequestService.getPageObject(recordID);
        String status = pageObject.Status__c;
        if(status.equals('Submitted'))
            return true;
        else
            return false;
        
    }
    
    @AuraEnabled
    public static String saveObj(SFDC_MDF__c pageObject)
    {   
        System.debug('pageObject :'+JSON.serialize(pageObject));
        try
        {   update pageObject;
        }
        catch(Exception e){
            return e.getMessage();

        }
        return 'success';
    }
    
    @AuraEnabled
    public static List<String> loadPickListValuesFromUtil(String sobjectName, String picklistFieldName)
    {
        List<String> options = GSMLite_UtilClass.populatePickList(sobjectName,picklistFieldName);
        return options;
    }

    
    
    
}