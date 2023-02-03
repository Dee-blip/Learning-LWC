/**
    History
        
    --Developer         --Date          --Description
    Lisha Murthy        06/11/2012      Created the class. 
                                        -> CR 1700275: EBC request - Add contacts related list 
        
*/
public class EBCInviteeNewController
{
    public static String EBCAccountName;
    public static String EBCId;

    public PageReference pageRedirect()
    {
        EBCAccountName = GsmUtilClass.getGSMSettingValue('EBCInvitee_EBCAccountName');
        EBCId = GsmUtilClass.getGSMSettingValue('EBCInvitee_EBCId');
        
        System.debug('EBC Account Name : '+EBCAccountName);
        
        EBC_Request__c relatedEBC=null;
        String Prefix =  Schema.Sobjecttype.EBC_Invitee__c.getKeyPrefix();
        PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?');
        
        // Get related Partner Account Id 
        Id relatedEBCId=ApexPages.currentPage().getParameters().get('id');
        
        if(relatedEBCId!=null)
            relatedEBC=[select Id,Name,Associated_Account__r.Name,Associated_Account__r.Id from EBC_Request__c where Id=:relatedEBCId][0];
            
        if(relatedEBC.Associated_Account__r.Name.contains('&'))
            relatedEBC.Associated_Account__r.Name.replace('&','%26');
        if(relatedEBC.Associated_Account__r.Name.contains(','))
            relatedEBC.Associated_Account__r.Name.replace('&','%2C');
        
        System.debug('RelatedEBCAccount=' + relatedEBC);
        if (relatedEBC!=null)
        {
            returnURL.getParameters().put('retURL', '/'+relatedEBCId);
            returnURL.getParameters().put(EBCId,relatedEBC.Name);
            returnURL.getParameters().put(EBCId+'_lkid',relatedEBC.Id);
            returnURL.getParameters().put(EBCAccountName,relatedEBC.Associated_Account__r.Name);
            returnURL.getParameters().put(EBCAccountName+'_lkid',relatedEBC.Associated_Account__r.Id);
        }
        else
            returnURL.getParameters().put('retURL', '/'+ Prefix+ '/o');
        returnURL.setRedirect(true);
        
        return returnURL;
    }
    
    //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //static testmethod void unitTest()
 //   {
 //       Account newAccount = utilTestClass.CreateAccount('_TEST_ Account 12');
 //       insert newAccount;
        
 //       EBC_Request__c newEBCRequest = new EBC_Request__c();
 //       newEBCRequest.Associated_Account__c = newAccount.Id;
 //       newEBCRequest.Location_of_visit__c = 'Zurich';
 //       newEBCRequest.Pre_Brief_Call__c = Date.today();
 //       insert newEBCRequest;
                               
 //       PageReference ebcInviteeNewPage = Page.EBCInviteeNew;
 //       Test.setCurrentPageReference(ebcInviteeNewPage);
 //       ebcInviteeNewPage.getParameters().put('id', String.valueOf(newEBCRequest.Id));
 //       EBCInviteeNewController controller = new EBCInviteeNewController();
 //       controller.pageRedirect();
 //   }

}