/***
    FundRequest_bi
    @author Vinayendra T N <Vinatara@akamai.com>
    @Description : This trigger is called on 'before insert'
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N   21/01/11    CR 919522 Developments related to PRM
                                If User is Partner User and its insert
                                    1)Add FCM to to the Fund Request if only 1 FCM is present for the User
 * Lisha Murthy     20/10/12    CR 1900756 - PRM: remove Has MDF checkbox for all contacts if partner doesnt have MDF
                                - Added the check for FB availability on insertion or submission of FR.
*/
trigger FundRequest_bi on SFDC_MDF__c (before insert,before update) {

    //Anand Hegde - CR 2505504 - Moved from updateFundRequestPartnerAccount trigger to here as we need the partner account to be populated before we check for available budgets
        PRMTriggerClass.FRUpdateFundRequestPartnerAccountTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);

        list<SFDC_MDF__c> FundRequestlist = new List<SFDC_MDF__c>();
        list<SFDC_MDF__c> FundRequestAsPAE = new List<SFDC_MDF__c>();
        list<SFDC_MDF__c> ValidateCurrencyList=new list<SFDC_MDF__c>();
        list<SFDC_MDF__c> fundRequestPopulateFields=new list<SFDC_MDF__c>();
        list<SFDC_MDF__c> fundRequestUpdateCampaign=new list<SFDC_MDF__c>();
        Integer frActivityEndBufferTime = Integer.valueOf(NAPSettings.getValue('MDF_FRActivityEndBufferDays'));
        for(SFDC_MDF__c fm : Trigger.new)
        {
            if(Trigger.isInsert)
            {
                if(fm.Account__c!=null && fm.Validation_Override__c==false)
                    ValidateCurrencyList.add(fm);
                
                if(fm.Account__c!=null)
                    FundRequestAsPAE.add(fm);
            }

          //SFDC-8953
           /* if (Trigger.isUpdate && Trigger.oldMap.get(fm.id).Status__c != fm.Status__c && fm.Spender_Confirmed__c == false && fm.Status__c == 'Approved' && !fm.Validation_Override__c)  {
              fm.addError('Spender Confirmed should be marked before approving the Fund Request');
            }*/
            
            //SFDC-3089
            if(fm.Fund_Request_Campaign__c!=null && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Fund_Request_Campaign__c',Trigger.oldMap.get(fm.id),fm))))
                fundRequestPopulateFields.add(fm);
           
            if(fm.Partner_Marketing_Activity__c!=null && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Partner_Marketing_Activity__c',Trigger.oldMap.get(fm.id),fm))))
              fundRequestUpdateCampaign.add(fm);


           }
           

        //SFDC-3089
        if(!fundRequestPopulateFields.isEmpty())
            PRM_opportunity.populateFieldsFromPMA(fundRequestPopulateFields);

        if (!fundRequestUpdateCampaign.isEmpty())
            PRM_opportunity.updateCampaignOnFundRequest(fundRequestUpdateCampaign);

        if(ValidateCurrencyList.size()>0)
            PRM_opportunity.ValidateFundRequestCurrency(ValidateCurrencyList);
        
           for(SFDC_MDF__c fm : Trigger.new)
        {     
            if(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(fm.id).Status__c!='Submitted' && fm.Status__c=='Submitted'))
                FundRequestlist.add(fm);
                

            // AGH
            // Fund Claim Deadline = activity end date + 60
            if(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(fm.id).Program_End_Date__c!=fm.Program_End_Date__c))
            {
                fm.Earliest_FC_Deadline__c = fm.Program_End_Date__c.addDays(frActivityEndBufferTime);
            }
            
        }
        
        
        if(FundRequestList.size() > 0)
            PRM_opportunity.convertAndCheckFR(FundRequestList);
         
   //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(SFDC_MDF__c fr : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (fr.AKAM_Created_By__c =='' || 
          fr.AKAM_Created_Date__c == null ||fr.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          fr.AKAM_Created_By__c = fr.AKAM_Alias__c ;
          fr.AKAM_Created_Date__c = system.now();
          fr.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (fr.AKAM_Modified_Date__c  == null|| 
        fr.AKAM_Modified_By__c == '' || fr.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        fr.AKAM_Modified_By__c = fr.AKAM_Alias__c;
        fr.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}