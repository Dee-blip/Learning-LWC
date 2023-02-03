/**
 * Extension controller for OpportunityLineItemsEdit2;  
 *
 * Ali KM                       02/Apr/2012      CR 1477954 Forecasting: Need to update QA env for Feb 6 kickoff. Will perform a live demo
 
 * Lisha Murthy                 30/07/2012      CR 1797448 Customer Save Program - Renewal Opportunities and Oppty-Products
                                                -> Added new fields called "Average Renewal Commit MRR" and "Average Renewal Usage MRR" on Page which are visible only for renewal Opportunities.

 * Lisha Murthy                 02/09/2013      CR 2345466 - Update to Churn/Lost Customer Process-Master Change Request
 
 * Lisha Murthy                 28/06/2014      CR 2652978 - Added two new validation rules for CFL functionality
 
 * Rahul Gaira                  06/08/2014       CR 2711073 - Added a  Check For the  fillCompetitor  and Updated oppty First  before oli updation

**/ 
global class OpportunityLineItemsExtension
{   
    public boolean firstLoaded {get;set;} //page first loaded flag
    public OpportunityLineItem oli {get;set;}
    public Opportunity opp {get; set;}
//    public Boolean showCancellationReason{get;set;}
//    public Boolean showCancellationReasonRequiredError{get;set;}
//    public String cancellationReasonError{get;set;}
    public Boolean missingSalesforId {get; set;}
    public Boolean isEligibleToEditProduct{get;set;} 
    public String partnerManageProductsErrorMessage{get;set;}
    public Boolean isRenewalOppty {get;set;}
    public Boolean isZeroMrrError{get;set;}
    public Boolean showOpptyCategory{get;set;}
    public Boolean showOpptyCategoryRequiredError{get;set;}    
    public string opptyCategoryError{get;set;}
    public Boolean fillMissingProductFeature{get;set;}
    public string missingProductFeatureError{get;set;}
    public Boolean fillCompetitor{get;set;}
    public string competitorError{get;set;}
    public Boolean fillConsolidationAccount{get;set;}
    public Boolean fillAggregationPartner{get;set;}
    public Boolean fillInitialOutClauseDesc{get;set;}
    public Boolean fillUnacceptableTnC{get;set;}
    public Boolean showErrorMessages{get;set;}

    public Profile currentUserProfile{get;set;}
    public RecordType currentRecordType{get;set;}
    public string validationProfileList{get;set;}
    public Boolean validProfile{get;set;}    
    
    //Use the constructor to build a list of related line items
    public OpportunityLineItemsExtension(ApexPages.StandardController stdController) 
    {   
        //otherProdAddDropLogicToggle = Features_Toggle__c.getInstance('Oppty Products-Other Drop & Add');
        //productGroupingToggle = Features_Toggle__c.getInstance('Product Wizard - Product Grouping');
        this.missingSalesforId = false;
        this.oli = (OpportunityLineItem)stdController.getRecord();
        //this.opp = [Select Id, Name, Cancellation_Reason__c from Opportunity where Id = :this.oli.OpportunityId];//[0]
        firstLoaded=true;
        isRenewalOppty = false;
        isZeroMrrError=false;
        fillCompetitor=false;
        fillConsolidationAccount=false;
        fillMissingProductFeature=false;
        fillAggregationPartner=false;
        fillInitialOutClauseDesc=false;
        fillUnacceptableTnC=false;
        partnerManageProductsErrorMessage=GSM_Custom_Settings__c.getInstance('OpptyLineItems#ManageProductsError').value__c;
        init();
    }
    
    /**
        GetCustomSettingValue(String pPropertyName)
        - Generic function to return Custom Setting values for the single Custom Setting Object model
    */
    private static String GetCustomSettingValue(String pPropertyName)
    {
        return GSM_Custom_Settings__c.getInstance('Contract_Extension#'+pPropertyName).Value__c;
    }
   
    /*public void setCancellationReason() 
    {              
        if (oli.UnitPrice!=null && oli.UnitPrice<0 && oli.LMRR_Type__c=='Customer')
            showCancellationReason=true;
        else
            showCancellationReason=false;
        if(showCancellationReasonRequiredError)
        {
                showCancellationReasonRequiredError=false;
        }
        //System.debug('showCancellationReasonRequiredError: '+showCancellationReasonRequiredError);
        //System.debug('showCancellationReason: '+showCancellationReason);
    }*/
    
    /*
    public String familyType{get;set;}
    public List<SelectOption> getFamilyTypes(){
        return getObjPicklistValues(Product2.Family.getDescribe());
    }
    public String lmrrType{get;set;}
    public List<SelectOption> getlmrrTypeVals(){
        return getObjPicklistValues(OpportunityLineItem.LMRR_Type__c.getDescribe());
    }*/
    
    public void init(){
        if (firstLoaded)
            { // on first page load, initialize the lists
                firstLoaded = false;
                Id id = ApexPages.currentPage().getParameters().get('id');
                if (id==null)
                {   
                    this.missingSalesforId = true;
                    ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, GetCustomSettingValue('Error-MissingType'));
                    ApexPages.addMessage(errMsg); 
                    return;
                }
                else
                {
                    this.oli = [SELECT UnitPrice, NRR__c, LMRR__c, LMRR_Type__c, ServiceDate, Quantity,PricebookEntryId,
                        ListPrice, Product_Family__c, TotalPrice, Forecast_Group__c, Forecast_MRR__c,
                        PricebookEntry.Name, PricebookEntry.ProductCode, Product_Name__c,
                        PricebookEntry.Product2.UOM__c, of_Months__c, Recurring__c, Total_Revenue_Months__c, Reseller_Retail_Price__c,
                        Quantity__c, Revenue_Impact2__c, G_L__c, MRR__c, Forecast_MRR_Realtime__c,
                        OpportunityId, Id, CurrencyIsoCode, Opportunity.Cancellation_Reason__c,
                        Comments__c, Description, Validation_Override__c, AKAM_Opportunity_Product_ID__c, AKAM_System__c, 
                        AKAM_Modified_Date__c, AKAM_Modified_By__c, AKAM_Created_Date__c, AKAM_Created_By__c,
                        Average_Renewal_Commit_MRR__c, Average_Renewal_Usage_MRR__c
                        FROM OpportunityLineItem WHERE id= :oli.id];
                 this.opp = [Select Id, Name, Cancellation_Reason__c,zero_Mrr_amount__c,Account.OwnerIDAlt__r.Profile.Name, 
                             Opportunity_Type__c, Opportunity_Category__c, Opportunity_Sub_Category__c, Loss_Reason__c,
                             Missing_Product_Feature__c, Competitor__c, Aggregation_Partner__c, Consolidation_Account__c, RecordType.Name, Initial_Out_Clause_Description__c, Unacceptable_Terms_and_Conditions__c
                             from Opportunity where Id = :oli.OpportunityId];
                 String userTypeString=Userinfo.getUserType();
                 if(userTypeString!='' && userTypeString.contains('Partner') && opp.Account.OwnerIDAlt__r.Profile.Name !='Sales - Partner Account Executive')
                 {
                    isEligibleToEditProduct=false;
                 }
                 else
                 {
                    isEligibleToEditProduct=true;
                 }
                 
                 if(this.opp.Opportunity_Type__c != null && this.opp.Opportunity_Type__c != '' && this.opp.Opportunity_Type__c.contains('Renewal'))
                    isRenewalOppty = true;
                 
                 //CR 2345466
                 //missingProductFeatureError=GSM_Custom_Settings__c.getInstance('AddOpptyLineItem#missProdError').value__c;
                 fillMissingProductFeature=false;
                 
                 //competitorError=GSM_Custom_Settings__c.getInstance('AddOpptyLineItem#competitorError').value__c;
                 fillCompetitor=false;

                 opptyCategoryError=GSM_Custom_Settings__c.getInstance('AddOpptyLineItem#OppCatError').value__c;
                 showOpptyCategoryRequiredError=false;
                 
                 fillConsolidationAccount=false;
                 fillAggregationPartner=false;
                 validProfile=false;
                 
                 validationProfileList=GSM_Custom_Settings__c.getInstance('AddOpptyLineItem#profileName').value__c;

                 currentRecordType = [SELECT Name FROM RecordType WHERE Id= :this.opp.RecordTypeId][0];
                               
                 currentUserProfile=[SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()][0];
                 String userProfileName = currentUserProfile.Name;
                 if(validationProfileList.indexOf(',') != -1)
                 {
                     for(string pName: validationProfileList.split(','))
                     {
                         System.debug('++userProfileName '+userProfileName);
                         System.debug('++profileName '+pName);
                         if(userProfileName.contains(pName))
                             validProfile=true;
                         System.debug('++validProfile '+validProfile);
                     }
                 }

                 else if(userProfileName.contains(validationProfileList))
                     validProfile=true;                 
                 System.debug('++validProfile outside '+validProfile);
                 
                 //End of CR 2345466
                }
            }
    }

    public PageReference save() {
        fillMissingProductFeature=false;
        //fillCompetitor=false;// Commented for CR 2711073
        showOpptyCategoryRequiredError=false;
        fillConsolidationAccount=false;
        fillAggregationPartner=false;
        
        //check that list can be added, and then refresh page
        if (saveSuccess())
        {
            // reload refreshed Page
            String rUrl = '/apex/OpportunityLineItemsView?id=';
            rUrl += ApexPages.currentPage().getParameters().get('id');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            return rPage;
        }
       else 
            return null;
    }
    public PageReference cancel() 
    {       
        String rUrl = '/apex/OpportunityLineItemsView?id=' + ApexPages.currentPage().getParameters().get('id');
        PageReference rPage = new PageReference(rUrl);
        rPage.setRedirect(true);
        return rPage;
    }
    

   private boolean saveSuccess()
   {
//        setCancellationReason();
//        Boolean isCancellationReasonRequired=false;
        Boolean didSaveSuccessful = true;
//        Boolean missingLossTypeError = false;
        Boolean isOpptyCategoryRequired=false;
      //  fillCompetitor=false; //Commented for CR 2711073
        fillMissingProductFeature=false;
        fillConsolidationAccount=false;
        fillAggregationPartner=false;
        showOpptyCategoryRequiredError=false;

//        if(oli.UnitPrice<0 && (oli.LMRR_Type__c=='' || oli.LMRR_Type__c==null))
//            missingLossTypeError=true;
//        if(oli.LMRR_Type__c=='Customer')
//            isCancellationReasonRequired=true; 

        //CR 2345466
        if(oli.UnitPrice<0
            && (this.opp.Opportunity_Category__c==null || this.opp.Opportunity_Category__c =='' 
            || this.opp.Opportunity_Sub_Category__c==null || this.opp.Opportunity_Sub_Category__c==''
             || this.opp.Loss_Reason__c==null || this.opp.Loss_Reason__c=='')
              && validProfile==true
               && currentRecordType.Name=='Akamai Opportunity')
           isOpptyCategoryRequired=true;
        //End of CR 2345466
        
        try
        {
//            if(true == missingLossTypeError) //) && !oli.Validation_Override__c)
//                throw (new CustomException('Loss Type cannot be empty, please select a value from the drop down.'));
            
            //CR 2345466: Commenting out Cancellation reason logic
/*            if(isCancellationReasonRequired && !checkOpptyCancellationReason())
            {   
                showCancellationReasonRequiredError=true;
                return false;
            }
            else
            {*/
             //Start: Added below logic for CR 2317619  
             if(isZeroMrrError && this.opp.Zero_MRR_AMOUNT__c !='')
             {
             update this.opp;
             isZeroMrrError=false;
             } 
             System.debug('++inside saveSuccess++ ');
             //End: Added below logic for CR 2317619
              
              //Start Code  CR 2711073
              if(fillCompetitor  && this.opp.Competitor__c !='')
             {
             update this.opp;
             fillCompetitor=false;
             } 
             // End Code CR 2711073
             
             //CR 2345466
             if(!checkOpptyCategory() && isOpptyCategoryRequired)
             {
                 showOpptyCategoryRequiredError=true;
                 return false;
             }
             //End of CR 2345466
             
             update oli;
             System.debug('oli after update:' + oli);
//            System.debug('isCancellationReasonRequired after update:' + isCancellationReasonRequired);
//            System.debug('checkOpptyCancellationReason() after update:' + checkOpptyCancellationReason());
            //}   
        }
        //CR 2345466: Added DMLException block
        catch (DMLException e)
        {
            String errMessage='Error: ';
            showErrorMessages=true;
            for (Integer i = 0; i < e.getNumDml(); i++)
             {                 
                 System.debug('++Error++ '+e.getNumDml());
                 
                 List<string> fieldNameList = new List<string>();
                 fieldNameList=e.getDmlFieldNames(i);
                 
                 if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
                 {
                     errMessage=e.getDmlMessage(i);
                     System.debug('+++Error Message+++ '+errMessage);
                     if(errMessage.contains('Opportunity Category, Sub-Category, Cancellation/Loss Reason is required'))
                     {
                         errMessage = 'Error : '+errMessage;
                         showOpptyCategory = true;
                     }
                     
                     if(errMessage.contains('Competitor is mandatory'))
                     {
                         errMessage = 'Error : '+errMessage;
                         fillCompetitor=true;
                         showOpptyCategory = true;
                     }
                     
                     if(errMessage.contains('Missing Product Feature is mandatory'))
                     {
                         errMessage = 'Error : '+errMessage;
                         fillMissingProductFeature=true;
                         showOpptyCategory = true;
                     }
                     
                     if(errMessage.contains('Consolidation Account is required'))
                     {
                         errMessage = 'Error : '+errMessage;
                         fillConsolidationAccount=true;
                         showOpptyCategory = true;
                     }
                     
                     if(errMessage.contains('Aggregation Partner is mandatory'))
                     {
                         errMessage = 'Error : '+errMessage;
                         fillAggregationPartner=true;
                         showOpptyCategory = true;
                     }
                     
                     if(errMessage.contains('Initial Out Clause Description is mandatory'))
                     {
                         errMessage = 'Error : '+errMessage;
                         fillInitialOutClauseDesc=true;
                         showOpptyCategory = true;
                     }
                     
                     if(errMessage.contains('Unacceptable Terms and Conditions is mandatory'))
                     {
                         errMessage = 'Error : '+errMessage;
                         fillUnacceptableTnC=true;
                         showOpptyCategory = true;
                     }
                     
                     if(e.getMessage().contains('Zero MRR Amount is required when sales stage is 4 or above and MRR = 0'))
                     {
                        errMessage = 'Error : '+errMessage;
                        isZeroMrrError=true;
                     }
                 }
             }
             ApexPages.addMessages(e);
             //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMessage));
             didSaveSuccessful = false;
        }        
        catch (exception ex)
        {
            //Start: Added below logic for CR 2317619
            // Below logic checks for validation errors for Opportunity which comes when OpportunityLineitems is saved.
            // It shows appropriate Opportunity Fields in OpptyEdit Page.
            
            //CR 2345466: Commenting Cancellation reason logic and moving Zero MRR Amount validation catch to DML Exception block.
/*            if(ex.getMessage().contains('Cancellation reason is required for Zero MRR Amounts where the value equals Zero MRR Churn'))
            {
                showCancellationReason=true;
            }*/
            ApexPages.addMessages(ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please correct the above errors and click on "Save" button to continue.'));
            didSaveSuccessful = false;
        }
        return didSaveSuccessful;
   }
   
   //CR 2345466: Commenting Cancellation reason logic
/*   private Boolean checkOpptyCancellationReason()
   {
        System.Debug('Inside checkOpptyCancellationReason');
        Boolean isOpptyCancellationReasonExists=false;
        if(this.opp.Cancellation_Reason__c!=null && this.opp.Cancellation_Reason__c !='')
        {
                isOpptyCancellationReasonExists=true;
                update this.opp;
                return isOpptyCancellationReasonExists;
        }
        System.Debug('isOpptyCancellationReasonExists: '+isOpptyCancellationReasonExists);      
        return isOpptyCancellationReasonExists;
   }*/

   /*CR 2345466: Added function checkOpptyCategory()
    Input Parameters: None
   Return value: Boolean - if Oppty fields are present or not.
   Functionality: Check if the Oppty Category, Sub-Category and Cancellation/Lost reason is filled, and Oppty update is successful,
                 then return true
                 else return false
   */ 
   private Boolean checkOpptyCategory()
   {
        System.Debug('Inside checkOpptyCategory');
        Boolean isOpptyCategoryExists=false;

        fillCompetitor=false;
        fillMissingProductFeature=false;
        fillConsolidationAccount=false;
        fillAggregationPartner=false;
        showOpptyCategoryRequiredError=false;

        if(this.opp.Opportunity_Category__c!=null && this.opp.Opportunity_Category__c !='' 
            && this.opp.Opportunity_Sub_Category__c!=null && this.opp.Opportunity_Sub_Category__c!=''
             && this.opp.Loss_Reason__c!=null && this.opp.Loss_Reason__c!=''
              && validProfile==true
               && currentRecordType.Name=='Akamai Opportunity')
            {
                System.debug('++oppty++ '+this.opp.Opportunity_category__c+', '+this.opp.Opportunity_Sub_Category__c+', '+this.opp.Loss_Reason__c);
                isOpptyCategoryExists=true;
                OpportunityLineItemTriggerClass.fromOpptyProdWizard=true;
                update this.opp;
                return isOpptyCategoryExists;
            }
        System.Debug('isOpptyCategoryExists: '+isOpptyCategoryExists);      
        return isOpptyCategoryExists;
   }
     
}