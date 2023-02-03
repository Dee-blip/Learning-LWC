global class AccountReassignmentEscalationController 
{
    //public String initializeFlag { get; set; }
    public Boolean initializedFlag {get; set;}
    //public User accOwner {get; set;}
    //public Account account {get; set;}
    public Account_Reassignment__c accReassign {get; set;}
    public Account_Reassignment__c accReassignDummy {get; set;}
    //public Boolean isAccountActive {get; set;}
    //public Boolean isRevenueAccount {get; set;}
    //public Id pendingAccountReassignmentReqId {get; set;}
    public Boolean isAccountReassignmentReqIdPresent {get;set;}
    public Boolean isAdminProfile{get;set;}
    public Boolean isValidRequest{get;set;}

    // construct
    public AccountReassignmentEscalationController()
    {
        String id=ApexPages.currentPage().getParameters().get('id');
        if(id == null || (id !=null && id==''))
        {
            isAccountReassignmentReqIdPresent=false;
            showErrorAndDiscontinue('Account Reassignment Request Id is missing.');
        }
        else
        {
            isAccountReassignmentReqIdPresent=true;
            initialize();   
        }
    }
    
    public void initialize()
    {
        //Features_Toggle__c featureToggle = Features_Toggle__c.getInstance('AccountReassignment'); //SFDC-2304
        initializedFlag=true;
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AccountReassignment') == false) //SFDC-2304
        {
             showErrorAndDiscontinue(GsmUtilClass.featureToggleMsg('AccountReassignment')); //SFDC-2304                          
             initializedFlag=false;
        } 
        for(Account_Reassignment__c req : [ Select Id,Action__c,Account__c,Account_Status__c,Account_Owner__c,Reassign_Status__c,Rejected_On__c,Reassignment_Due_Date__c,Monthly_Revenue__c,Reason_for_Change__c,CreatedDate,
                Account_Move_Escalation__c,Requesting_User__c,Account_Owner_RSM__c,Assign_To_User__c,Assign_To_User_RSM__c,Name,Status_Message__c,isEscalated__c from Account_Reassignment__c where Id=: ApexPages.currentPage().getParameters().get('id')])
                accReassign = req;
        if(accReassign == null)
        {
            isAccountReassignmentReqIdPresent=false;
            showErrorAndDiscontinue('Account Reassignment Request Id is missing.');
            //return false;
            initializedFlag=false;
        }
        else
        {
            accReassignDummy = new Account_Reassignment__c();
            System.debug('accReassign Date=' + accReassign.CreatedDate);
            System.debug('Date Time Now 21 Days Older=' + DateTime.now().addDays(-1*Integer.valueOf('21')));
            
            if(accReassign.isEscalated__c==true && accReassign.Reassign_Status__c=='Rejected')
            {
                showErrorAndDiscontinue('Escalation on this Account Reassignment Request has already been declined.');
                initializedFlag=false;
            }
            
            //String daysToWaitBeforeEscalation = Account_Reassignment_Settings__c.getInstance('DaysToHoldBeforeEscalation').Value__c; //SFDC-2304
            String daysToWaitBeforeEscalation = GsmUtilClass.getAccountReassignSettingValue('DaysToHoldBeforeEscalation'); //SFDC-2304
            Integer daysToWaitBeforeEscalationVal = Math.round(Double.valueOf(daysToWaitBeforeEscalation));
            if (DateTime.now().addDays(-1*daysToWaitBeforeEscalationVal)<accReassign.CreatedDate && accReassign.Reassign_Status__c=='Approval Pending')
            {
                showErrorAndDiscontinue('This Account Reassignment Request does not qualify for Escalations, request should be older than 7 days to be escalated.');                                                                   
                initializedFlag=false;
            }
            
            //String daysUntillEscalationCanBeDone = Account_Reassignment_Settings__c.getInstance('DaysUntillEscalationCanBeDone').Value__c; //SFDC-2304
            String daysUntillEscalationCanBeDone = GsmUtilClass.getAccountReassignSettingValue('DaysUntillEscalationCanBeDone'); //SFDC-2304
            Integer daysUntillEscalationCanBeDoneVal = Math.round(Double.valueOf(daysUntillEscalationCanBeDone));
            if (((DateTime.now().addDays(-1*daysUntillEscalationCanBeDoneVal)<accReassign.CreatedDate) && accReassign.Reassign_Status__c == 'Approval Pending')
            || (accReassign.Rejected_On__c!=null && DateTime.now().addDays(-1*Integer.valueOf('14'))<accReassign.Rejected_On__c && accReassign.Reassign_Status__c == 'Rejected'))
                isValidRequest=true;
            else
                isValidRequest=false;
            
            if (!isValidRequest)
            {
                showErrorAndDiscontinue('This Account Reassignment Request does not qualify for Escalations.');                                                                     
                initializedFlag=false;
            }
                
            
            //@todo: check to ensure this is not an older request and also this should be for only rejected/pending review logic.
            DateTime esclationRequestGraceDaysFromStart = DateTime.now().addDays(Integer.valueOf('21'));
            DateTime esclationRequestGraceDaysFromRejection = DateTime.now().addDays(Integer.valueOf('14'));
            System.debug('esclationRequestGraceDaysFromStart=' + esclationRequestGraceDaysFromStart);
            System.debug('esclationRequestGraceDaysFromRejection=' + esclationRequestGraceDaysFromRejection);
            for (Account_Reassignment__c accReq : [Select Id from Account_Reassignment__c where Account__c =:accReassign.Account__c AND CreatedDate>=: DateTime.now().addDays(-1*Integer.valueOf('21')) Order By CreatedDate DESC LIMIT 1])
            {
                System.debug('accReq Id=' + accReq.Id); 
                if (accReq.Id!=accReassign.Id)
                {
                    showErrorAndDiscontinue('This is an old request, please pick the most recent Account Reassignment Request for Escalation.');                              
                    initializedFlag=false;
                    break;
                }  
            }
            /*
            isAccountIdPresent=true;
            pendingAccountReassignmentReqId = AccountReassignmentInterfaceClass.getPendingReassignmentRequestId(accReassign.Account__c);              
            if(pendingAccountReassignmentReqId!=null)
            {
                showErrorAndDiscontinue(AccountReassignmentDataClass.getCustomSettings('Error : Prevent Duplicates'));
                //return false;
                initializedFlag=false;        
            }
            */
            String salesOpsProfileId = AccountReassignmentDataClass.getCustomSettings('SalesOpsProfileId') + ',' + AccountReassignmentDataClass.getCustomSettings('Exception_Profile_Ids'); //SFDC-2304
            if(salesOpsProfileId.contains(UserInfo.getProfileId()))
                isAdminProfile=true;
            else
                isAdminProfile=false;
        } 
        if (initializedFlag)
        {
                            
        }
    }
    
    public PageReference cancel()    
    {
        return new PageReference('/'+accReassign.Id);       
    }
    public PageReference save()
    {
        try
        {
            accReassign.Reassign_Status__c='Escalated';
            accReassign.Status_Message__c='The Requested Account Move/Reassignment is Escalated. Please contact your Sales Operations Team.';
            accReassign.Account_Move_Escalation__c = accReassignDummy.Account_Move_Escalation__c;
            accReassign.isEscalated__c=true;
            update accReassign;
        }
        catch(DMLException e)
        {
             for (Integer i = 0; i < e.getNumDml(); i++)
             { 
                 if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION 
                    || e.getDmlType(i)==StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION
                    || e.getDmlType(i)==StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY)
                 {
                     String errMessage=e.getDmlMessage(i);
                     //String error=GSM_Custom_Settings__c.getInstance('AccountReassignment#ErrorToCompare').value__c; //SFDC-2304
                     String error=GsmUtilClass.getGSMSettingValue('AccountReassignment_ErrorToCompare'); //SFDC-2304
                     if(errMessage.contains(error))
                     {
                        //errMessage='.Error : '+GSM_Custom_Settings__c.getInstance('AccountReassignment#ErrorToShow').value__c; //SFDC-2304
                        errMessage='.Error : '+GsmUtilClass.getGSMSettingValue('AccountReassignment_ErrorToShow'); //SFDC-2304
                     }
                     ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errMessage);
                     ApexPages.addMessage(errMsg);
                 }
                 else
                     throw e;
             } 
             return null;
        }        
        return new PageReference('/'+accReassign.Id);        
    }
    
    // helper methods.
    public static void showErrorAndDiscontinue(String pErrorMessage)
    {
         ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage);
         ApexPages.addMessage(errMsg);      
    }
    
    
}