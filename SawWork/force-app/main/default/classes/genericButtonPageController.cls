/* OnClick JS is deprecated in Lightning. This is a generic controller called from buttons to do backend operations and show messages 
  similar to window alerts. 
  
 Author             Date                    
 Sonali Tandon      16th December 2016      Created class
 */

public class genericButtonPageController {
    //SFDC-5995-Start
    public class GuidanceToPeriodMapper {
        String Pmp_GuidanceFieldAPIName;
        List<String> listOfSupportedPMP_PicklistVals;

    }
    //SFDC-5995-End

    // record Id
    public Id recordId {get;set;}
    PageReference pageRef;
    //SFDC-4389
    //public String successMessage {get;set;}
    public String message {get;set;}
    //public String result {get;set;}
    public String fromButton {get;set;}
    
    public PageReference init()
    {
        // name of source button
        //String fromButton;
        fromButton   = ApexPages.currentPage().getParameters().get('fromButton');
        recordId     = ApexPages.currentPage().getParameters().get('recordId');

        if(!String.isBlank(fromButton))
        {
            //if(fromButton == 'DeauthorizeMPButton')
            //  deauthorizeMPContact();
            if(fromButton == 'DisqualifyDealDiscount')
                disqualifyDealDiscount();
            if(fromButton == 'CreateCreditCheckTask')
            {
                pageRef=createCreditCheckTask();
                return pageRef;
            }

            if(fromButton.containsIgnoreCase('SubmitPartner'))
            {
                return submitRecordForApproval();
            }
            if(fromButton.containsIgnoreCase('UnlockPartner')) //SFDC-4389
            {
                //Boolean partnerEligible = checkPartnerEligibleToSubmit();
                message = GsmUtilClass.getGSMSettingValue('partnerConfirmationMessage')+':1';
            }
            if(fromButton == 'UsePartnerForecasting') //ITREQ-3098
            {
                pageRef=copyPartnerForecasting();
                return pageRef;
            }
        }

        
        return null;
    }

    public List<String> updateToDraft(Id ppId)
    {
        List <String> idToErrorsResultList = new List<String>(); //SDFC 7223
        DMLResults dmlres= new DMLResults(true);
        //SFDC-4389
        Schema.sObjectType entityType = Id.valueof(recordId).getSObjectType();
        List<sObject> objToUpdate;
        if(entityType ==Partner_Profile__c.sObjectType){
        Id rtid = Schema.SObjectType.Partner_Profile__c
                    .getRecordTypeInfosByName()
                    .get('Partner Information Draft or Resubmit')
                    .getRecordTypeId();  
        objToUpdate=
            new List<Partner_Profile__c>{
                new Partner_Profile__c(Id=ppId
                        ,Approval_Status__c='Re-Opened' //SFDC-6778
                        ,Fast_Track__c = false //SFDC-6778
                        ,Validation_Override__c=true
                        ,RecordTypeId=rtid)};
            }
        else if(entityType ==Partner_Marketing_Plan__c.sObjectType){

        objToUpdate=
            new List<Partner_Marketing_Plan__c>{
                new Partner_Marketing_Plan__c(Id=ppId
                        ,Plan_Status__c='Draft'
                        ,Validation_Override__c=true
                        )};
            }
        dmlres.dmlUpdate(objToUpdate);
        Map<Id,List<String>> idToErrors = dmlres.fetchErrorLogs();
        if(idToErrors.containsKey(ppId)){
            idToErrorsResultList.addAll(idToErrors.get(ppId)); //SDFC 7223
        }
        return idToErrorsResultList; //SDFC 7223
    }

    //SFDC-4389
    public Boolean checkPartnerEligibleToSubmit(){
        Boolean flag = true;
       List<ProcessInstance> piList = [SELECT TargetObjectId, SubmittedBy.Profile.name, createddate FROM ProcessInstance WHERE TargetObjectId = :recordId order by createddate desc];
       if(UserInfo.getUserType().equals('PowerPartner') && !piList.isEmpty() && piList[0].SubmittedBy!=null && !piList[0].SubmittedBy.Profile.name.contains('Partner Community'))
            flag=false;
        return flag;
    }

    //SFDC-6889 change return type to handle redirection from Page
    public void unlockRecord()
    {   //SFDC-4389
        PageReference pageRef;
        List<String> errs = new List<String>();
        Schema.DescribeSObjectResult profileObj;
        Schema.sObjectType entityType = Id.valueof(recordId).getSObjectType();
        Set<String> partnerProfileNamesSet = new Set<String>();
        partnerProfileNamesSet.add('Partner Community User');
        partnerProfileNamesSet.add('Partner Community Admin');

        // SFDC-6609
        message = '';
        //SFDC-4389
        if(entityType ==Partner_Profile__c.sObjectType || entityType ==Partner_Marketing_Plan__c.sObjectType)
        {
            Boolean canUnlock = true;
            system.debug(LoggingLevel.ERROR,'Approval.isLocked(recordId):: '+Approval.isLocked(recordId));

            //Check if user has partner plan access and create sharing rule
            Id loggedInUserId = UserInfo.getUserId();
            Id profileId = UserInfo.getProfileId();
            User u = [Select id,AccountId__c,Has_PartnerPlans_Access__c From User where id=:loggedInUserId];
            String profileName = [Select name from profile where id=:profileId].Name;
            
            if (!u.Has_PartnerPlans_Access__c && entityType==Partner_Marketing_Plan__c.sObjectType && partnerProfileNamesSet.contains(profileName)) {
                canUnlock = false;
                String partnerPartnerAccessError = GsmUtilClass.getNAPSettingValue('PartnerAccess_PartnerPlanAccessError');
                errs.add(partnerPartnerAccessError);
            }
            
            if (canUnlock) {
                if(Approval.isLocked(recordId)){
                    errs = ApprovalsUtilClass.unlockRecord(recordId);
                }
                if(errs==null || errs.size()==0) {

                    List<String> errsForUpdate = updateToDraft(recordId);
                    if(errsForUpdate!=null && errsForUpdate.size()>0)
                        errs.addAll(errsForUpdate);
                }
            }
            
        }
        
       if(errs==null || errs.size()==0)
        {  
            
            pageRef = new PageReference('/'+recordId);
            pageRef.setRedirect(true);
        }
        else
        {
            for(String err : errs)
            {
                 // SFDC-6609
                if (Apexpages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));                
                }
                message += err+'\n';
            }
        }
    }

    public PageReference submitRecordForApproval()
    {
        PageReference pageRef;
        List<String> errs = new List<String>();
        Schema.DescribeSObjectResult profileObj;

        Schema.sObjectType entityType = Id.valueof(recordId).getSObjectType();
        Boolean isPermitted = false;
        // SFDC-6609
        message = '';
        if(entityType ==Partner_Profile__c.sObjectType)
        {
            isPermitted = Schema.sObjectType.Partner_Profile__c.isUpdateable();
            profileObj = Schema.sObjectType.Partner_Profile__c;
            if(profileObj.isUpdateable())
            {
                errs = ApprovalsUtilClass.submitForApproval(recordId);

            }
            else
            {
                errs.add('You do not have sufficient privileges to perform this action');
            }
        }
        else if(entityType==Partner_Marketing_Plan__c.sObjectType)
        {
            //SFDC-6322 Begins
            errs = submitForApprovalInvocable(new List<Id>{recordId});
            //SFDC-6322 Ends
        }
        if(errs==null || errs.size()==0)
        {
            pageRef = new PageReference('/'+recordId);
            pageRef.setRedirect(true);
        }
        else
        {
            for(String err : errs)
            {
                // SFDC-6609
                if (Apexpages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));                
                }
                message += err+'\n';
            }
        }
        return pageRef;
    }
//SFDC-6322 Begins
@InvocableMethod(label='Flow PMP/PMA creation' description='submits PMP after validations')
public static List<String> submitForApprovalInvocable(List<Id> recordId){
     //SFDC-4058
            //Partner_Marketing_Plan__c pmp = [select id,Active__c,Approval_required__c,Plan_Status__c,Cost_null_non_excluded__c from Partner_Marketing_Plan__c where id=:recordId];
            
            //SFDC-5995-Start
            String PMP_Period_To_PBP_PeriodMappingJSON = GSMSettings.getVerbose('PMP_Period_To_PBP_PeriodMappingJSON');
            String PartnerProfileIds = GsmUtilClass.getPRMSettingValue('PartnerProfileIds');
            String PartnerSubmiteerErrorMsg = GsmUtilClass.getPRMSettingValue('GBPC_Partner_submitter');
            List<GuidanceToPeriodMapper> listOfGuidanceToPeriodMapper = (List<GuidanceToPeriodMapper>) JSON.deserialize(PMP_Period_To_PBP_PeriodMappingJSON, List<GuidanceToPeriodMapper>.Class);
            String queryString = 'SELECT Id, Active__c, Approval_required__c, Plan_Status__c, Cost_null_non_excluded__c, Plan_Period__c, Plan_Funding_Approved_Roll_Up__c, Business_Plan__r.Period__c, Business_Plan__r.CurrencyIsoCode,Partner_Submitter__c';
            for(GuidanceToPeriodMapper eachGuidanceToPeriodMapper : listOfGuidanceToPeriodMapper) {
                if(eachGuidanceToPeriodMapper.Pmp_GuidanceFieldAPIName != null && eachGuidanceToPeriodMapper.Pmp_GuidanceFieldAPIName != '') {
                    queryString += ', Business_Plan__r.' + eachGuidanceToPeriodMapper.Pmp_GuidanceFieldAPIName + ' ';
                }
            }
            List<String> errs = new List<String>();
            Boolean isPermitted = false;
            queryString += ' FROM Partner_Marketing_Plan__c WHERE Id = \'' + recordId[0] + '\'' ;
            try {
                system.debug(LoggingLevel.ERROR,'queryString in submitForApproval PMP'+queryString+' '+recordId);
                Partner_Marketing_Plan__c pmp = Database.query(queryString);
                if(!pmp.Active__c)
                {
                    errs.add('This marketing plan is inactive.');
                }
                if(pmp.Approval_required__c<=0)
                {
                    errs.add('You need to add marketing activities with non-zero activity costs.');
                }
                //SFDC-4058
                if(pmp.Cost_null_non_excluded__c>0)
                {
                    String error = GsmUtilClass.getGSMSettingValue('PM_PartnerMarketingPMCostError');
                    errs.add(error);
                }
                // SFDC-7476
                if(!PartnerProfileIds.contains(UserInfo.getProfileId()) &&  String.ISBLANK(pmp.Partner_Submitter__c))
                {
                    errs.add(PartnerSubmiteerErrorMsg);
                }
                //SFDC-5995-Start
                if(pmp.Plan_Period__c != null && pmp.Plan_Period__c != '') {
                    
                    Decimal requiredBudgetGuidence = 0;
                    Boolean guidanceCheckRequired = true;
                    for(GuidanceToPeriodMapper eachGuidanceToPeriodMapper : listOfGuidanceToPeriodMapper) {
                        if(!guidanceCheckRequired || requiredBudgetGuidence != 0) {
                            break;
                        }
                        for(String eachSupportedPicklistVal : eachGuidanceToPeriodMapper.listOfSupportedPMP_PicklistVals) {
                            if(pmp.Plan_Period__c.contains(eachSupportedPicklistVal)) {
                                Object tempRequiredBudgetGuidence = pmp.Business_Plan__r.get(eachGuidanceToPeriodMapper.Pmp_GuidanceFieldAPIName);
                                if(tempRequiredBudgetGuidence == null) {
                                    guidanceCheckRequired = false;
                                } else {
                                    requiredBudgetGuidence = (Decimal) tempRequiredBudgetGuidence;
                                }
                                break;
                            }
                        }
                    }
                    //SFDC-6322
                    if(guidanceCheckRequired && pmp.Approval_required__c.setScale(0, RoundingMode.HALF_UP) > requiredBudgetGuidence.setScale(0, RoundingMode.HALF_UP)) {
                        errs.add(GsmUtilClass.getGSMSettingValue('MarketingBudgetOverflowMsg').replace('#CurrencyValueHere#', pmp.Business_Plan__r.CurrencyIsoCode + ' ' + String.valueOf(requiredBudgetGuidence)));
                    }
                }
                //SFDC-5995-End
                if(errs.size()==0)
                {
                    if(CurrentUser.isPartner)
                    {
                        String pSetID = NAPSettings.getValue('PartnerAccess_PartnerPlanAccess');
                        for(PermissionSetAssignment psa : [select id from PermissionSetAssignment where AssigneeId=:UserInfo.getUserId() and PermissionSetId=:pSetId])
                        {
                            isPermitted=true;
                        }
                    }
                    else
                    {
                        isPermitted = Schema.sObjectType.Partner_Marketing_Plan__c.isUpdateable();
                    }

                    if(isPermitted)
                    {   system.debug('Exception happened:: '+recordId);
                        //SFDC-7661
                        String fname = UserInfo.getFirstName() != ''? UserInfo.getFirstName() : '';
                        String lname = UserInfo.getLastName() != ''? UserInfo.getLastName(): '';
                     	pmp.Submitter_Full_Name__c = fname + ' ' +lname;
                     	pmp.Submission_Date__c = date.today();
                     	update pmp;
                        errs = ApprovalsUtilClass.submitForApproval(recordId.get(0));
                        //system.debug('Exception happened after submitForApproval:: '+errs);
                        //if(errs==null)
                        //    errs = new List<String>();
                        //errs.add(' : Successfully Passed ');
                        //system.debug('Exception happened after errs.add:: '+errs);                        
                    }
                    else
                    {
                        errs.add('You do not have sufficient privileges to perform this action');
                    }
                }
            }
            catch (Exception e) {
                system.debug('Exception happened:: '+e);
                errs.add(e.getMessage());
            }
                //SFDC-5995-End
                system.debug('errs:: '+errs);
                return errs;
}
//SFDC-6322 Ends

//commenting as not referenced anywhere
    public pageReference createCreditCheckTask(){

        PageReference pageRef;
        String accountID;
        accountID = ApexPages.currentPage().getParameters().get('accountId');


        String taskCreatedForCreditCheck = ApexPages.currentPage().getParameters().get('taskCreatedForCreditCheck');

        String CreditCheckStatus = ApexPages.currentPage().getParameters().get('creditCheckStatus');
        //acc.Validation_Override__c = true;
        System.debug('taskCreatedForCreditCheck: '+taskCreatedForCreditCheck);
        if(taskCreatedForCreditCheck.equals('0')){
            Task tempTask = new Task();
            tempTask.OwnerId = GSMSettings.getValue('CollectionsQueueId');
            tempTask.Subject = 'Credit Check Needed';
            tempTask.WhatId = accountID;
            tempTask.Description =  GsmUtilClass.getGSMSettingValue('CreditCheckDescription');
            Account accountList = [Select Id, Name ,taskCreatedForCreditCheck__c,Credit_Check_Status__c, Account_Status__c From Account where Id = :accountID];
            accountList.taskCreatedForCreditCheck__c=true;
            insert(tempTask);
            update accountList;
            //System.debug('temp id:'+ tempTask.Id);
            pageRef = new PageReference('/'+tempTask.Id);
            pageRef.setRedirect(true);
            return pageRef;
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This account already has a pending credit check task'));
            return null;
        }
    }

     private void disqualifyDealDiscount()
     {
        String discountStatus = ApexPages.currentPage().getParameters().get('discountStatus');
        Id opportunityId      = ApexPages.currentPage().getParameters().get('opportunityId');
        
        if(discountStatus.equals('Disqualified'))
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Deal registeration has already been disqualified.'));

        else 
        {
            Opportunity oppty = new Opportunity(Id = opportunityId, Discount_Status__c = 'Disqualified', Discount_Percentage__c=0);
            try
            {
                update oppty;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Deal Registeration discount sucessfully disqualified.'));
            }
            catch(Exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured while trying to update deal registeration : ' + e.getMessage()));  
            }
        }

     }

     //ITREQ-3098
     public pageReference copyPartnerForecasting(){

        PageReference pageRef;
        //acc.Validation_Override__c = true;

            Opportunity opp = [select Partner_Forecast_Category__c,Partner_Close_Date__c,Partner_Forecast_Comments__c,Partner_Projected_Monthly_Commit__c,Partner_Projected_Monthly_Usage__c from opportunity where id=:recordId];
            opp.Partner_Forecast__c = opp.Partner_Forecast_Category__c;
            opp.PAE_Close_Date__c = opp.Partner_Close_Date__c;
            //opp.PAE_Forecast_Comments__c = opp.Partner_Forecast_Comments__c;
            //opp.Partner_Forecast_Amount__c = opp.Partner_MRR__c;
            opp.Override_PAE_TCV__c= true;
            opp.PAE_Projected_Monthly_Commit__c = opp.Partner_Projected_Monthly_Commit__c;
            opp.PAE_Projected_Monthly_Usage__c = opp.Partner_Projected_Monthly_Usage__c;
            opp.validation_override__C = true;

            //System.debug('temp id:'+ tempTask.Id);
            try
            {
                update opp;
                pageRef = new PageReference('/'+recordId);
                pageRef.setRedirect(true);
                return pageRef;
            }
            catch(Exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured while trying to update PAE Forecasting : ' + e.getMessage()));  
            }
            return null;
        }

    //SFDC-6889
    @AuraEnabled
    public static Boolean getFastTrackDetailsBeforeSubmission(String partnerProfileId) {
        Partner_profile__c partnerProfileRec = [SELECT Id, Fast_Track__c, Approval_Status__c FROM Partner_Profile__c WHERE Id = :partnerProfileId LIMIT 1];
        if(partnerProfileRec != null && partnerProfileRec.Approval_Status__c == 'Draft' ) {
            return partnerProfileRec.Fast_Track__c;
        }
        return true;
    }

    //SFDC-6889 : Add confirmation for Fast Track, before submitting a partner profile for approval : used for internal users only
    @AuraEnabled
    public static string submitPartnerProfileForApproval(String partnerProfileId, Boolean fastTrack, Boolean hasFastTrackChanged) {
        String returnMessage = '';
        System.DEBUG(LoggingLevel.ERROR, 'hasFastTrackChanged : ' + hasFastTrackChanged + 'fastTrack : ' + fastTrack);
        if(hasFastTrackChanged) {
            System.DEBUG(LoggingLevel.ERROR, 'inside hasFastTrackChanged');
            Partner_Profile__c partnerProfileRec = new Partner_Profile__c();
            partnerProfileRec.Id = partnerProfileId;
            partnerProfileRec.Fast_Track__c = fastTrack;
            try  {
                update partnerProfileRec;
            }
            catch (Exception e) {
                returnMessage += e.getMessage();
                System.DEBUG(LoggingLevel.ERROR, 'returnMessage : ' + returnMessage);
                //Handle Exception
            }
        }
        genericButtonPageController gbpcObj = new genericButtonPageController();
        gbpcobj.recordId = partnerProfileId;
        gbpcObj.submitRecordForApproval();
        if(!String.isBlank(gbpcObj.message)){
            returnMessage += gbpcObj.message;
        }
        else {
            returnMessage += 'SUCCESS';
        }
        return returnMessage;
    }
}