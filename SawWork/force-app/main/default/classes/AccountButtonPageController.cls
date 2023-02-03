//SFDC-1556
public class AccountButtonPageController
{
    PageReference pageRef;

    public static Id recordId;
    public static String fromButton, function,isPartnerCustom, accName, profileName, reportId;
    public Boolean disableAsPartnerFunctionality {get; set;}
    public Boolean enableAsPartnerFunctionality {get; set;}
    public Boolean partnerFunctionalityConfirmed {get; set;}
    public Boolean partnerFunctionalityConfirmedEnabled {get; set;}
    public Boolean errorFunction {get; set;}
    public String disableConfirmationMsg {get; set;}
    public String enableConfirmationMsg {get; set;}

    public PageReference init()
    {
        fromButton = ApexPages.currentPage().getParameters().get('fromButton');
        recordId   = ApexPages.currentPage().getParameters().get('recordId');
        function   = ApexPages.currentPage().getParameters().get('function');
        isPartnerCustom = ApexPages.currentPage().getParameters().get('isPartnerCustom');
        accName = ApexPages.currentPage().getParameters().get('accName');
        profileName = ApexPages.currentPage().getParameters().get('profileName');
        disableAsPartnerFunctionality = false;
        enableAsPartnerFunctionality = false;
        partnerFunctionalityConfirmed = false;
        partnerFunctionalityConfirmedEnabled = false;
        errorFunction = false;
        reportId = ApexPages.currentPage().getParameters().get('reportId'); //SFDC-5507

        if(!String.isBlank(fromButton) && !String.isBlank(function))
        {
            if(function == 'UpdateCreditCheckStatus')
            {
                pageRef = updateCreditCheckStatus();
                return pageRef;
            }

            if(fromButton == 'DisableAsPartner') {
                if(profileName == 'System Administrator' || profileName == 'Partner Support') {
                    if(isPartnerCustom == '1') {
                        disableAsPartnerFunctionality = true;
                        disableConfirmationMsg = 'Are you sure you want to disable this Account as Partner Account? Doing so will disable all partner users associated to this account.';    
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Account ' + accName + ' is not enabled as a Partner Account.'));        
                        errorFunction = true;
                    }
                    
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have privileges to Perform this operation'));    
                    errorFunction = true;
                }
            }

            //SFDC-8783
            if(fromButton == 'EnableAsPartner') {
                if(profileName == 'System Administrator' || profileName == 'Partner Support') {
                    if(isPartnerCustom == '1') {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Account ' + accName + ' is Already Enabled as a Partner Account'));        
                        errorFunction = true;  
                    } else {
                        enableAsPartnerFunctionality = true;
                        enableConfirmationMsg = 'Are you sure you want to enable this Account as Partner Account?';  
                       
                    }
                    
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have privileges to Perform this operation'));    
                    errorFunction = true;
                }
            }

            //SFDC-5507
            if(function == 'RedirectUrl') {

                String redirectURL = '', accountId = '';
                if(((string)recordId).length() > 15)
                    accountId = ((string)recordId).substring(0,15);
                else
                    accountId = (string)recordId;

                if(fromButton == 'OutstandingInvoices') {
                    if(UserInfo.getUiThemeDisplayed() == 'Theme4d'){
                        redirectURL = '/lightning/r/Report/'+reportId+'/view?fv0='+accountId;
                    }else{
                        redirectURL = '/'+reportId+'?pv0='+accountId;
                    }
                }

                return new PageReference(redirectURL);
            }
        }

        return null;
    }

    public PageReference updateCreditCheckStatus()
    {
        String userWithAccessAliases = GsmUtilClass.getGSMSettingValue('UserWithAccesssAliases');
        Id profileId = UserInfo.getProfileId();
        Id userId = UserInfo.getUserId();
        String systemAdminId = GsmUtilClass.getGSMSettingValue('SystemAdminProfileId');
        User userAlias = [select Id,Alias from User where Id = :userId limit 1];
        String errMsg = 'You do not have sufficient privileges to perform this action.';
        Boolean isAdmin = false;
        String result = '0:Error';

        if(profileId == systemAdminId)
        {
            isAdmin = true;
        }

        if(!userWithAccessAliases.contains(userAlias.Alias.toLowerCase()) && isAdmin == false)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
            return null;
        }

        else
        {
            result = GsmUtilClass.CreditCheckButtonInvoke(fromButton,recordId);
            String resultFlag = result.substring(0, result.indexOf(':'));
            String resultMessage = result.substring(result.indexOf(':') + 1, result.length());

            if(resultFlag == '1')
            {
                pageRef = new PageReference('/' + resultMessage);
                pageRef.setRedirect(true);
                return pageRef;
            }

            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, resultMessage));
                return null;
            }
        }
    }

    public PageReference disableAsPartner() {
        recordId   = ApexPages.currentPage().getParameters().get('recordId');
        //String result = PRM_opportunity.DisablePartnerAccount(recordId);
        string returnmsg='';
        try {
            list<User> DisableUserList=new list<User>();
            //for(User u:[select id from User where AccountId=:recordId and Isactive=true]) {
            for(User u:[Select id, Has_MDF_Access__c,Has_DealRegistration_Access__c,
            Can_Accept_POA__c,Has_view_content_in_portals__c,Has_PartnerPlans_Access__c,Has_PartnerCertification_Access__c,
            View_Pricing_Details__c,Has_Partner_Concierge_Access__c ,Has_Start_Trial_Access__c,Has_View_Trial_Access__c 
            from User where AccountId=:recordId and isActive = true]) {
                u.IsActive=false; u.Has_MDF_Access__c = false; u.Has_DealRegistration_Access__c = false;u.Can_Accept_POA__c =false;
                u.Has_view_content_in_portals__c = false;u.Has_PartnerCertification_Access__c = false;u.View_Pricing_Details__c = false;u.Has_Partner_Concierge_Access__c = false;u.Has_Start_Trial_Access__c = false;u.Has_View_Trial_Access__c = false;
                DisableUserList.add(u);
            }
            if(DisableUserList.size()>0)
                update DisableUserList;
            
        } catch(DMLException e) {
            Sawyer.saw(e);
            for (Integer i = 0; i < e.getNumDml(); i++)
             { 
                 returnmsg+=e.getDmlMessage(i)+'<br/>';
             }
             if(returnmsg == '')
                returnmsg=e.getMessage();
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, returnmsg));
        }
        
        if(returnmsg == '') {
            disableConfirmationMsg = '';
            disableAsPartnerFunctionality = false;
            partnerFunctionalityConfirmed = true;
            disableConfirmationMsg = 'Succesfully disabled as Partner Account!';
            PRM_opportunity.DeactivateParterAccount(recordId);
        }

        return null;
        
    }

    //SFDC-8783
    public PageReference enableAsPartner() {

        
        recordId   = ApexPages.currentPage().getParameters().get('recordId');
        //String result = PRM_opportunity.DisablePartnerAccount(recordId);
        string returnmsg='';
        try {
            list<User> EnableUserList=new list<User>();
            for(User u:[select id from User where AccountId=:recordId and Isactive=true]) {
                u.IsActive=false;
                EnableUserList.add(u);
            }
            if(EnableUserList.size()>0)
                update EnableUserList;
            
        } catch(Exception e) {
            for (Integer i = 0; i < e.getNumDml(); i++)
             { 
                 returnmsg+=e.getDmlMessage(i)+'<br/>';
             }
             if(returnmsg == '')
                returnmsg=e.getMessage();
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, returnmsg));
             return null;
        }
        
        if(returnmsg == '') {
            enableConfirmationMsg = '';
            enableAsPartnerFunctionality = false;
            partnerFunctionalityConfirmedEnabled = true;
            enableConfirmationMsg = 'Succesfully enabled as Partner Account!';
            PRM_opportunity.makePartnerAccount(recordId);
            
        }

        return null;
        
    }

    public PageReference backToAccount() {
        recordId   = ApexPages.currentPage().getParameters().get('recordId');
        pageRef = new PageReference('/'+(Id)recordId);
        pageRef.setRedirect(true);
        return pageRef;    
    }
}
//End Of SFDC-1556