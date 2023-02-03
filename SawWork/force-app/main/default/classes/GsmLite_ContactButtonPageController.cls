public class GsmLite_ContactButtonPageController
{
    PageReference pageRef;
    
    public static Id recordId;
    public static String firstname,lastname ;
    
    public PageReference init()
    {
        String fromButton;
        
        fromButton   = ApexPages.currentPage().getParameters().get('fromButton');
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        firstname = ApexPages.currentPage().getParameters().get('firstname');
        lastname = ApexPages.currentPage().getParameters().get('lastname');
        
        if(!String.isBlank(fromButton))
        {
            if(fromButton == 'ManageOperationsPortalAccess')
            {
                pageRef = manageOperationsPortalAccess();
            }

            if(fromButton == 'UpdateAccess')
            {
                pageRef = updateAccess();
            }
        }
        return pageRef;
    }
    
    public PageReference updateAccess()
    {
        if(NAPSettings.getValue('UpdatePartnerAccessAllowedProfiles').containsIgnoreCase(UserInfo.getProfileId()))
        {
            Contact partnerContact = [select id, Partner_User__c from Contact where id=:recordId];
            if(partnerContact!=null && partnerContact.Partner_User__c!=null)
            {
                pageRef = new PageReference(NAPUrlService.getUserTypeAwareUrl('/apex/DefinePartnerAccess?id='+recordId));
                pageRef.setRedirect(true);
            }
            else
            {
                //SFDC-7653 - @nadesai
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'This contact has not been provisioned with ' + NAPSettings.getValue('NAPRebrand_Type2') + ' Access yet.'));
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You are not authorized to this page'));
        }

        return pageRef;
    }

    public PageReference manageOperationsPortalAccess()
    {
        String result,message;
        
        firstname = firstname.replaceAll('\\s','');
        lastname = lastname.replaceAll('\\s','');
        
        Boolean fname  = Pattern.matches('\\w+',firstname);
        Boolean lname  = Pattern.matches('\\w+',lastname);
        
        System.debug('firstname - fname :'+firstname+'-'+fname);
        System.debug('lastname - lname :'+lastname+'-'+lname);
        
        if (!(fname && lname)){
            //SFDC-7653 - @nadesai
            message = 'Warning! – Users with access to ' + NAPSettings.getValue('NAPRebrand_Type2') + 'Portal or Luna cannot have special characters in the First or Last Name. Only simple characters a through z, A through Z, 0 through 9, including spaces are allowed. Please update the names before provisioning Portal access.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
        } 
        
        else { 
            // SFDC-5894
            //result = PartnerUserController.manageContactAccess(recordId+'','0');
            result = Util.createCommunityAwareURL('/apex/ManagePartnerUser?con=' + recordId + '&AU=0');
            pageRef = new PageReference(result);
            pageRef.setRedirect(true);
        }
		
        
        return pageRef;
    }
    
    
}