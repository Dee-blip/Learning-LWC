public without sharing class OpportunityWarningsExtensionController{

   public Opportunity currentOppty {get;set;}
   public Boolean showWarnings {get;set;}
   public String fieldName{get;set;}
   public String ialtApprovalURL{get;set;}
   public Id opportunityId {get;set;}
   public Boolean PurchaseOrdershowWarnings {get;set;}
   public String PurchaseOrderWarnings {get;set;}
   public string gamblingWarning {get;set;}
   public String visualComplianceWarning {get;set;}

   public OpportunityWarningsExtensionController(ApexPages.StandardController stdController) 
   {    
       showWarnings = false;
       PurchaseOrdershowWarnings = false;
       ialtApprovalURL = '';
       this.currentOppty = (Opportunity)stdController.getRecord();
        opportunityId = currentOppty.Id;
       if(ApexPages.currentPage().getParameters().get('opptyId')!='' && ApexPages.currentPage().getParameters().get('opptyId')!=null)
           opportunityId = ApexPages.currentPage().getParameters().get('opptyId');
           
       //currentOppty = [select id, deal_type__c, Sales_Approval_Status__c, IALT_Received__c, IALT_Requested__c, Is_Restricted_Country__c, OwnerId,Is_Authorized_Partner_Sellable_Country__c, Account.BillingCountry, Partner_Involved__r.Partner_Sellable_Countries__c,Account.Name,isWon, isClosed,Account.PO_Required__c,Partner_Involved__r.PO_Required__c from Opportunity where id= :opportunityId];

       Map<String, Object> fieldToVaueMap = new Map<String, Object>();
       string gamblingWarningMsg='';
       for(GSM_Settings_Verbose__mdt verbose : [SELECT DeveloperName,Value__c FROM GSM_Settings_Verbose__mdt WHERE DeveloperName = 'OpptyWarning_Gambling' OR DeveloperName = 'OpptyWarning_GamblingWarningMsg']){
           if(verbose.DeveloperName == 'OpptyWarning_Gambling')
               fieldToVaueMap = (Map<String, Object>)JSON.deserializeUntyped(verbose.Value__c);
           else if(verbose.DeveloperName == 'OpptyWarning_GamblingWarningMsg')
               gamblingWarningMsg = verbose.Value__c;
       }

       string gamblingFields = '';
       for(string field : fieldToVaueMap.keySet()){
            gamblingFields += ','+field;
       }
       string opptyQueryStr = 'select id, deal_type__c, Sales_Approval_Status__c, IALT_Received__c, IALT_Requested__c, Is_Restricted_Country__c, OwnerId,Is_Authorized_Partner_Sellable_Country__c, Account.BillingCountry, Partner_Involved__r.Partner_Sellable_Countries__c,Account.Name,isWon, isClosed, Account.eCustoms_Legal_Approved__c, Account.RPS_Status__c, Account.ECUSTOMS__RPS_Status__c, Account.PO_Required__c,Partner_Involved__r.PO_Required__c' + gamblingFields + ' from Opportunity where id=:opportunityId';
       currentOppty = database.query(opptyQueryStr);

       //SFDC-2686
       String eps = null;
       String metadataName = currentOppty.Sales_Approval_Status__c;
       if(metadataName != null){
          if(metadataName.contains(' ')){
              metadataName = metadataName.replaceAll(' ', '_');
          }
          if(metadataName.isNumeric()){
              metadataName = 'X'+metadataName;
          }
         eps = GsmUtilClass.getErrorPageSettingValue(metadataName);  //Error_Page_Settings__c.getInstance(currentOppty.Sales_Approval_Status__c);
       }
       String partnerSellableCountriesError = GsmUtilClass.getErrorPageSettingValue('PartnerSellableCountriesError'); //Error_Page_Settings__c.getInstance('PartnerSellableCountriesError');

        // for strictly restricted country
       if(eps!=null && ((!currentOppty.IALT_Received__c && currentOppty.Sales_Approval_Status__c=='Both Restricted') || (currentOppty.Sales_Approval_Status__c=='Only Reselling Allowed' && currentOppty.Deal_Type__c=='Direct')))
       {
           showWarnings = true;
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, eps));
       }

       // show warning only on open indirect opportunities
       //SFDC-2686
       if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('Partner_Sellable_Country_Toggle') && partnerSellableCountriesError!=null && !currentOppty.Is_Authorized_Partner_Sellable_Country__c && currentOppty.Deal_Type__c == 'Indirect' && currentOppty.isWon ==false && currentOppty.isClosed == false)
        {
          showWarnings = true;
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, partnerSellableCountriesError));
        }

      //Saket More
        if(currentOppty.Account.eCustoms_Legal_Approved__c == false && currentOppty.Account.RPS_Status__c == GsmUtilClass.getGSMSettingValue('Account_RPS_Status_c_Red')) {
          showWarnings = true;
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, GsmUtilClass.getGSMSettingValue('eCustoms_warning')));
        }
        //SFDC-6330
        String vcStatusAlertValue = GsmUtilClass.getGSMSettingValue('VC_Status_Alert_Values');
        if(String.isnotBlank(currentOppty.Account.ECUSTOMS__RPS_Status__c) && vcStatusAlertValue.contains(currentOppty.Account.ECUSTOMS__RPS_Status__c)){
            visualComplianceWarning = GsmUtilClass.getGSMSettingValue('VC_Oppty_Warnings');
        }

        if((currentOppty.deal_type__c == 'Direct' && currentOppty.Account.PO_Required__c == 'Yes') || (currentOppty.deal_type__c == 'Indirect' && currentOppty.Partner_Involved__r.PO_Required__c == 'Yes')){
          PurchaseOrdershowWarnings = true;
          PurchaseOrderWarnings = GsmUtilClass.getGSMSettingValue('Purchase_Order_Warning');
          //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, GsmUtilClass.getGSMSettingValue('Purchase_Order_Warning')));
        }

        boolean showGamblingWarning = false;
        for(string field : fieldToVaueMap.keySet()){
            if(field.contains('.')){
                if(currentOppty.getSObject(field.split('\\.')[0]).get(field.split('\\.')[1]) == String.valueOf(fieldToVaueMap.get(field))){
                    showGamblingWarning=true;
                }
                else if(currentOppty.getSObject(field.split('\\.')[0]).get(field.split('\\.')[1]) == Boolean.valueOf(fieldToVaueMap.get(field))){
                    showGamblingWarning=true;
                }
                else{
                    showGamblingWarning=false;
                    break;
                }
            }
            else{
                if(currentOppty.get(field) == String.valueOf(fieldToVaueMap.get(field))){
                    showGamblingWarning=true;
                }
                else if(currentOppty.get(field) == Boolean.valueOf(fieldToVaueMap.get(field))){
                    showGamblingWarning=true;
                }
                else{
                    showGamblingWarning=false;
                    break;
                }
            }
        }

        if(showGamblingWarning){
            gamblingWarning = gamblingWarningMsg;
        }
     
   }

    public PageReference markFieldAsChecked() 
    {
        currentOppty.put(fieldName,true) ;
        currentOppty.Validation_Override__c = true;
        if(currentOppty.OwnerId!=UserInfo.getUserId() && !GSMSettings.getValue('ProfileIDsWithAccessToIALTButtons').contains(UserInfo.getProfileId().substring(0,15)))
        {   //SFDC-2686
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, GsmUtilClass.getErrorPageSettingValue('OpptyInsufficientPrivileges')));
            return null;
        }
        try
        {
            update currentOppty;
            showWarnings=true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, fieldName.replace('__c', ' ').replace('_', ' ') + ' has been checked.'));
            if(fieldName=='IALT_Requested__c')
            {
               ialtApprovalURL = Links__c.getInstance('IALTApproval').Value__c;
            }

        }
        catch(Exception e)
        {
             ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured while trying to save the record : ' + e.getMessage());
             ApexPages.addMessage(errMsg);  
        }
            return null;
    }   
  
}