global class FCM_page_controller 
{
    public static list<Channel_Mapping__c> channelMapping = new list<Channel_Mapping__c>();
    public List<Channel_Mapping__c> fcmIds  {get;set;}
    public String fcm_selected {get;set;}
    public Id AccountId;
    private map<id,id> fcm_Manager_map = new map<id,id>();
    private string opptyId=null;
    private string FundRequestId=null;
    private Opportunity oppty=null;
    private SFDC_MDF__c frId=null;
    private integer mode= null;
    private PageReference pRef;
    private Channel_Mapping__c RcmChannelMapping = null;

    public Opportunity getOppty()
    {
        return oppty;
    }

    public static void initilizeChannelMappingdata()
    {   
        for (Channel_Mapping__c cm :[SELECT Id, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c,Partner_Name__r.Name,PAE_ID__r.Name,PAE_ID__r.ManagerId,MDF_Approver__c,Global_Account_Manager6__c, Global_Account_Manager6__r.isActive FROM Channel_Mapping__c WHERE VAR_Manager_Status__c = 'Active' AND Active__c=true AND Temp_PAE__c=null AND PAE_ID__c !=null AND (Global_Account_Manager6__c = null OR (Global_Account_Manager6__c != null AND Global_Account_Manager6__r.isActive = true))])
        {
            channelMapping.add(cm);
        }
    }
    //Get the Master channel mapping record for that particualer account 
    public Channel_Mapping__c getMasterChannelMapping()
    {
        Channel_Mapping__c MasterChannelMapping=null;
        RcmChannelMapping = null;
        for(Channel_Mapping__c cm :[SELECT Id, Name, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c, Partner_Name__r.Name, PAE_ID__r.Name, Comp_Owner1__r.IsActive,
                                    PAE_ID__r.ManagerId, MDF_Approver__c, Comp_Owner1__c, Temp_PAE__c, Master_Channel_Mapping__c, PAE_ID__r.IsActive
                                    FROM Channel_Mapping__c 
                                    WHERE (
                                        Active__c = true
                                        AND Partner_Name__c =: AccountId
                                        AND (PAE_ID__c !=null OR Comp_Owner1__c != null)
                                        AND (PAE_ID__r.IsActive = true OR Comp_Owner1__r.IsActive = true)
                                    ) ORDER BY LastModifiedDate DESC])
        {
            if(cm.Master_Channel_Mapping__c && cm.PAE_ID__c != null && cm.PAE_ID__r.IsActive && cm.Temp_PAE__c == null){
                MasterChannelMapping=cm;
                break;
            }
            else if(RcmChannelMapping == null){
                if(!cm.Master_Channel_Mapping__c && cm.Comp_Owner1__c != null && cm.Comp_Owner1__r.IsActive){
                    RcmChannelMapping=cm;
                }
            }
        }
        return MasterChannelMapping;
    }
    
/** Hitesh Chawda - CR 3317151 - MDF -- Fund Req -- Remove PAE Choice on Submission 
    WebService call from Submit For Approval Button at Fund Request Object**/

    WebService  static String assignMasterChannelMapping(Id frId)
    {
//Get the Fund Request Record 
         SFDC_MDF__c fundreqId = [select id,FCM__c,Partner_Account_Owner__c,Fund_Request_Approver__c,Account__c from SFDC_MDF__c where id=:frId];
         Channel_Mapping__c MasterChannelMapping=null;
         //Get the associated Master Channel Mapping
         for (Channel_Mapping__c cm :[SELECT Id, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c,Partner_Name__r.Name,PAE_ID__r.Name,PAE_ID__r.ManagerId,MDF_Approver__c FROM Channel_Mapping__c WHERE (VAR_Manager_Status__c = 'Active' AND Active__c=true AND Temp_PAE__c=null AND Partner_Name__c=:fundreqId.Account__c AND Master_Channel_Mapping__c=true AND PAE_ID__c !=null AND MDF_Approver__r.IsActive=true) ORDER BY LastModifiedDate DESC])
            {
                MasterChannelMapping=cm;
            }
                if(MasterChannelMapping!=null)
                    {
                       //if Chennel mapping not null then assign FR Approver and FCM from the channel mapping record else assign Partner Account Owner as the Approver and FCM
                        if(MasterChannelMapping.MDF_Approver__c!=null)
                        {
                            fundreqId.Fund_Request_Approver__c=MasterChannelMapping.MDF_Approver__c;
                            fundreqId.FCM__c = MasterChannelMapping.PAE_ID__c;
                        }

                        else 
                            {
                            fundreqId.Fund_Request_Approver__c = fundreqId.Partner_Account_Owner__c;
                            fundreqId.FCM__c = MasterChannelMapping.PAE_ID__c;
                        }

                    }
                else
                        {
                            fundreqId.Fund_Request_Approver__c = fundreqId.Partner_Account_Owner__c;
                            fundreqId.FCM__c = fundreqId.Partner_Account_Owner__c;
                        }   
                        try
                            {
                                update fundreqId;
                                return 'Succesfully Assigned Channel Manager';

                            }
                        catch(Exception e)
                              {
                                String errMessage=e.getMessage();
                                if(errMessage.contains(GsmUtilClass.getGSMSettingValue('OpportunityTrg_RebateTCError')))
                                    return GsmUtilClass.getGSMSettingValue('OpportunityTrg_RebateTCError');
                                if(errMessage.contains('MANAGER_NOT_DEFINED'))
                                    return 'Fund Request Approver on the Channel Mapping is an invalid user.';
                                else
                                    return errMessage;
                              }

                    }

                    

                    

    
    


    public static string submitForApproval(Id p_OppId, Boolean isOppty)
    {
        PageReference pRef;
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted for approval. Please approve.');
        req.setObjectId(p_OppId);
        String customSettingsExceptionCheck = GsmUtilClass.getGSMSettingValue('DealRegSubmit_ProfileException');
        String userProfileId = userinfo.getProfileId();
        Opportunity oppty;
        if(isOppty)
        {
            oppty = [Select CloseDate from Opportunity where Id=:p_OppId][0];
        }
        if(!isOppty || customSettingsExceptionCheck.contains(userProfileId) || (isOppty && oppty.CloseDate!=null && oppty.CloseDate>=Date.today()))
        {
            // submit the approval request for processing
            try
            {
                Approval.ProcessResult result = Approval.process(req);
            }
            catch(DmlException e)
            {
                for (Integer i = 0; i < e.getNumDml(); i++)
                { 
                    if(e.getDmlType(i) == Statuscode.ALREADY_IN_PROCESS)
                    {
                        return Util.createCommunityAwareURL('/apex/ErrorPage?ErrorType=3&retURL=/'+p_OppId);
                    }
                    else if(e.getMessage().containsIgnoreCase('MANAGER_NOT_DEFINED'))
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error : Fund Request Approver is inactive'));
                        pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(), e);
                        return Util.createCommunityAwareURL('/apex/ErrorPage?ErrorType=8&retURL=/'+p_OppId);
                    }
                    else
                        throw e;
                }
            }
            catch(Exception e)
            {
                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
            }
            return null;
        }
        else
        {   
            return Util.createCommunityAwareURL('/apex/ErrorPage?ErrorType=7&retURL=/'+p_OppId);
        }
    }
    public PageReference checksubmit(){
        if(opptyId!=null && opptyId!='')
        { 
            oppty = [select id,FCM__c,isRebateTCToShow__c,Partner_Owner__r.AccountId from Opportunity where id=:opptyId];
            if(oppty!=null)
            {
                if(fcm_selected!='NONE')
                {
                    oppty.FCM__c=fcm_selected;
                }
                else
                {
                    // i dont know is selected, assign PAE of master channel mapping
                    Channel_Mapping__c masterChannelMapping=getMasterChannelMapping();
                    if(masterChannelMapping!=null)
                    {
                        oppty.FCM__c = masterChannelMapping.PAE_ID__c;
                    }
                    /* Start - Added by Vivek as part of SFDC-2590 */
                    else if(RcmChannelMapping!=null)
                    {
                        oppty.FCM__c = RcmChannelMapping.Comp_Owner1__c;
                    }
                    /* End - Added by Vivek as part of SFDC-2590 */
                }
                oppty.Validation_Override__c=true;
                try
                {
                    update oppty;
                }
                catch(Exception e)
                {
                    pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                }
                try
                {
                    string returnstring = submitForApproval(oppty.id, true);
                    if(returnstring != null && returnstring.startsWith('/')) {
                    	returnstring = returnstring.replaceFirst('/', '');
                	}
                    if(returnstring != null)
                        return new PageReference('/' + returnstring);
                    PageReference rPage = new PageReference('/'+opptyId);
                    rPage.setRedirect(true);
                    return rPage;
                }
                catch(DMLException e)
                {
                    if(e.getDmlType(0)==StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION && e.getDMLMessage(0).contains(GsmUtilClass.getGSMSettingValue('OpportunityTrg_RebateTCError')))
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getDmlMessage(0)));
                }
                catch(Exception e)
                {
                    pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                }
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Invalid Opportunity Id'));
            }
            return null;
        }
        else if(FundRequestId!=null && FundRequestId!='')
        {
            SFDC_MDF__c frId = [select id,FCM__c from SFDC_MDF__c where id=:FundRequestId];
            if(frId!=null)
            {
                if(fcm_selected!='NONE')
                {
                    frId.FCM__c=fcm_selected;
                    if(fcm_Manager_map.get(fcm_selected)!=null)
                        frId.Fund_Request_Approver__c=fcm_Manager_map.get(fcm_selected);
                    try
                    {
                        update frId;
                    }
                    catch(Exception e)
                    {
                        pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                    }

                }
                else//if i dont know is selected try to get master channel mapping
                {
                    Channel_Mapping__c MasterCm=getMasterChannelMapping();
                    if(MasterCm!=null)
                    {
                        if(MasterCm.MDF_Approver__c!=null)
                        {// assign the Fr approver as Fund request approver of Master Channel Mapping
                            frId.Fund_Request_Approver__c=MasterCm.MDF_Approver__c;
                            try
                            {
                                update frId;
                            }
                            catch(Exception e)
                            {
                                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                            }

                        }
                    }
                }
                string returnstring = submitForApproval(frId.id, false);
                if(returnstring != null && returnstring.startsWith('/')) {
                    returnstring = returnstring.replaceFirst('/', '');
                }
                if(returnstring!=null)
                    return new PageReference('/' + returnstring);
                PageReference rPage = new PageReference('/'+FundRequestId);
                rPage.setRedirect(true);
                return rPage;
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Invalid Fund Request Id'));
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Invalid Id'));
        }
        return null;
    }

    public FCM_page_controller()
    {
        init();
    }

    public void init()
    {

        initilizeChannelMappingdata();    
        fcm_selected=null;
        opptyId = ApexPages.currentPage().getParameters().get('oppty');
        FundRequestId = ApexPages.currentPage().getParameters().get('fr');
        
        if(opptyId!=null && opptyId!='') 
        {
            opptyId = String.escapeSingleQuotes(opptyId.escapeHtml4());
            mode=0;
            AccountId=([select Partner_Involved__c from Opportunity where id=:opptyId]).Partner_Involved__c;
        }
        else if(FundRequestId!=null && FundRequestId!='')
        {
            FundRequestId = String.escapeSingleQuotes(FundRequestId.escapeHtml4());
            mode=1;
            AccountId=([select Account__c from SFDC_MDF__c where id=:FundRequestId]).Account__c;
        }
        else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Invalid Id'));

        fcmIds = new List<Channel_Mapping__c>();
        for (Channel_Mapping__c cm : channelMapping)
        {
            if (cm.Partner_Name__c == AccountId)//partnerUser.contact.AccountId)      
            {       
                fcmIds.add(cm);
                if(cm.MDF_Approver__c!=null)
                    fcm_Manager_map.put(cm.PAE_ID__c,cm.MDF_Approver__c);
            }
        }
        if(fcmIds.size()==0)
        {
            this.fcm_selected='NONE';
        }
        if(fcmIds.size()==1)
        {
            this.fcm_selected=fcmIds[0].PAE_ID__c;
        }

    }

    public PageReference updateoppty() 
    {
        if(fcm_selected!=null)
        {
            return checksubmit();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Please select one of the options'));
            return null;
        }
    }

    public List<SelectOption> getItems() 
    {
        List<SelectOption> options = new List<SelectOption>();
        for (Channel_Mapping__c fcm : fcmIds)
        {       
            if (fcm.PAE_ID__r.Name!=null)
                options.add(new SelectOption(fcm.PAE_ID__c,fcm.PAE_ID__r.Name));
        } 
        if(mode!=null)
            options.add(new SelectOption('NONE','I don`t know')); 
        return options; 
    }

    public String getCountry() 
    {
        return fcm_selected;
    }

    public void setCountry(String fcm_selected) 
    { 
        this.fcm_selected = fcm_selected; 
    }

    public PageReference checkForNoFCM() 
    {
        if(fcm_selected!=null)
            return checksubmit();
        return null;
    }

    public PageReference cancel() 
    {
        PageReference rPage; 
        if(opptyId!=null && opptyId!='')
            rPage = new PageReference('/'+opptyId );
        else if(FundRequestId!=null && FundRequestId!='')
            rPage = new PageReference('/'+FundRequestId );
        else
            return null;
        rPage.setRedirect(true);
        return rPage;
    }
}