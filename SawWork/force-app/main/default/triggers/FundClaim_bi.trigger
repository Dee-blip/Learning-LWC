/***
    FundClaim_bi
    @author Vinayendra T N <Vinatara@akamai.com>
    @Description : This trigger is called on 'before insert '
 * History:
 * =========================
 * Developer    Date    Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N 21/01/11  CR 919522 Developments related to PRM
                If User is Partner User and its insert
                  1)Add FCM to to the Fund Claim from the corresponding Fund Request
 * Vinayendra T N 4/2011    CR 1052130 PRM: Insufficient Funds error when FC gets submitted.
                ~ Insufficent Error msg is even added when FC is submitted                    
 
*/   
trigger FundClaim_bi on SFDC_MDF_Claim__c (before insert,before update) {

  list<SFDC_MDF_Claim__c> addFcmList = new list<SFDC_MDF_Claim__c>();
  list<SFDC_MDF_Claim__c> ValidateCurrencyList=new list<SFDC_MDF_Claim__c>();
    for(SFDC_MDF_Claim__c fm : Trigger.new)
    {
        if(Trigger.isInsert)
        {
            if(fm.Fund_Request__c!=null && fm.Validation_Override__c==false)
                ValidateCurrencyList.add(fm);
        }

        if (Trigger.isUpdate && Trigger.oldMap.get(fm.id).Status__c != fm.Status__c && (fm.Fund_Claim_Activity_Spender__c == ''  || fm.Fund_Claim_Activity_Spender__c == null) && (fm.Status__c == 'Approved' || fm.Status__c=='Approved - Internal') && !fm.Validation_Override__c){
              fm.addError('"Fund Claim Activity spender" should have a value before Fund Claim is marked as approved.');
            }

        if(Trigger.isUpdate && Trigger.oldMap.get(fm.id).Contract_Reviewed_Date__c != fm.Contract_Reviewed_Date__c) {
            fm.Contract_Reviewed_By__c = UserInfo.getUserID();
        }

        //CR 1052130 PRM: Insufficient Funds error when FC gets submitted. Added logic to show error when Submitted also.
        if(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(fm.id).Status__c!='Submitted' && fm.Status__c=='Submitted'))
            addFcmList.add(fm);

        if(Trigger.isUpdate)
        {
            PRMTriggerClass.FCValidateFundClaimOnApprovalTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
            PRMTriggerClass.FundClaimTrigger(Trigger.new,Trigger.oldMap,Trigger.newMap);   
        }

        //Anand Hegde - CR 2461584. Workflow always sets status to approved internal.
        // Change it here based on Paid by
        if(Trigger.isUpdate)
        {
           //SFDC-5962 Replacing Paid By (Paid_By__c) with Fund_Claim_Activity_Spender__c
            if(fm.Status__c=='Approved - Internal' && fm.Fund_Claim_Activity_Spender__c=='Partner')
                fm.Status__c = 'Approved - Reimburse';
        }

        if(fm.FC_First_Submitted__c == null && fm.Status__c == 'Submitted'){
          fm.FC_First_Submitted__c = Date.today();
        }

    }   
    if(addFcmList.size()>0)
    {
        if(Trigger.isInsert)
            PRM_opportunity.addFCMdealcreation(addFcmList);
        PRM_opportunity.convertAndCheckFC(addFcmList);
    }
    if(ValidateCurrencyList.size()>0)
        PRM_opportunity.ValidateFundClaimCurrency(ValidateCurrencyList);
  //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
    for(SFDC_MDF_Claim__c claim : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (claim.AKAM_Created_By__c =='' || 
          claim.AKAM_Created_Date__c == null ||claim.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          claim.AKAM_Created_By__c = claim.AKAM_Alias__c ;
          claim.AKAM_Created_Date__c = system.now();
          claim.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (claim.AKAM_Modified_Date__c  == null|| 
        claim.AKAM_Modified_By__c == '' || claim.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        claim.AKAM_Modified_By__c = claim.AKAM_Alias__c;
        claim.AKAM_Modified_Date__c =  system.now();  
      }
    }
  } 
}