global without sharing class SF1_FundRequestAddPrivateNoteController {
 
    @AuraEnabled
    public static Boolean accessAllowedToCurrentUserProfile()
    {
        Boolean accessAllowed = SF1_FundRequestService.accessAllowedToCurrentUserProfile();
		return accessAllowed;
    }
    
    @AuraEnabled
    public static SFDC_MDF__c getPageObject(Id recordID)
    {
        SFDC_MDF__c pageObject = SF1_FundRequestService.getPageObject(recordID);
        return pageObject;
    }
    
    @AuraEnabled
    public static String saveNote(SFDC_MDF__c pageObject)
    {
        try
        {
            update pageObject;
        }
        catch(Exception e)
        {
            return e.getMessage();
        }
        return 'success';
    }
}