public without sharing class SF1_ManageProductsController {

    @AuraEnabled
        public static string getUserProfileName(){
            return [select Profile.Name from User where id =: UserInfo.getUserId()][0].Profile.Name;
        }

    @AuraEnabled
    public static Opportunity fetchOpportunity(Id oppId){
        Opportunity opp;
        try {
            opp = SF1_OpportunityService.getOpportunity(oppId);
        } catch (QueryException e){
            System.debug('No record was found for the Id provided. Returning null Opp');
        }
        return opp;
    }
    
    @AuraEnabled
    public static OpportunityLineItem saveProductObj(OpportunityLineItem pageObject)
    {   
        System.debug('pageObject :'+JSON.serialize(pageObject));
           
            //pageObject.UnitPrice = pageObject.Projected_Monthly_commit_fees__c - pageObject.Average_Renewal_Commit_MRR__c;
            //pageObject.Net_Non_Commit__c = pageObject.Projected_Avg_Rev_Non_Commit__c - pageObject.Average_Renewal_Usage_MRR__c;
            //pageObject.EMRI__c = pageObject.UnitPrice + pageObject.Net_Non_Commit__c;
            update pageObject;
        
        
        return fetchOpportunityLineItem(pageObject.Id);
    }
    
    @AuraEnabled
    public static OpportunityLineItem fetchOpportunityLineItem(Id oppLineItemObjId){
        OpportunityLineItem opp;
        try {
            opp = SF1_OpportunityService.getOpportunityLineItem(oppLineItemObjId);
        } catch (QueryException e){
            System.debug('No record was found for the Id provided. Returning null Opp');
        }
        return opp;
    }
    
    @AuraEnabled
    public static String deleteProductObj(OpportunityLineItem pageObject)
    {   
        System.debug('pageObject :'+JSON.serialize(pageObject));
        try
        {   
            delete pageObject;
        }
        catch(Exception e){
            return e.getMessage();

        }
        return 'success';
    }
    
    @AuraEnabled
    public static String cancelProductObj(OpportunityLineItem pageObject)
    {   
        System.debug('pageObject :'+JSON.serialize(pageObject));
        pageObject.Projected_Monthly_commit_fees__c = 0;
        pageObject.Projected_Avg_Rev_Non_Commit__c = 0;
        
        try
        {   update pageObject;
        }
        catch(Exception e){
            return e.getMessage();

        }
        return 'success';
    }

    @AuraEnabled
    public static Map<String,String> fetchProductNames(Opportunity oppRec)
    { 
        Map<String,String> ProductNamesMap = new Map<String,String>();
        for( Product2 prodObj : [Select Id, Name, Description, Family, UOM__c, 
                                 (select id from pricebookentries where CurrencyIsoCode=:oppRec.CurrencyIsoCode 
                                  and IsActive=true) From Product2 WHERE isActive=true and 
                                 RecordType.Name= 'Forecasting Products' ORDER BY Name]) {
            ProductNamesMap.put(prodObj.Name,prodObj.Id);                                
        }
        system.debug('ProductNamesMap = '+ProductNamesMap);
        return ProductNamesMap;
    }
    
        @AuraEnabled // SFDC-3714
        public static Map<String, String> getInitValues(Opportunity oppRec) {
                Map<String, String> returnValMap = new Map<String, String>();
                returnValMap.put('ProductNamesMap', JSON.serialize(fetchProductNames(oppRec)));
                returnValMap.put('SFC_PKL_Vals', GSMLite_UtilClass.populatePickListWithLabelAndValues('OpportunityLineItem', 'Specialist_Forecast_Category__c'));
                returnValMap.put('isSpecialistUser', String.valueOf(validateSpecialistUser(UserInfo.getProfileId())));
                return returnValMap;
        }

        @AuraEnabled // SFDC-3714
        public static Map<String, Object> fetchOpportunityLineItemWrapperFunction(Id oppLineItemObjId){
                Map<String, Object> returnMap = new Map<String, Object>();
                returnMap.put('OpportunityLineItem', fetchOpportunityLineItem(oppLineItemObjId));
                returnMap.put('SFC_PKL_Vals', GSMLite_UtilClass.populatePickListWithLabelAndValues('OpportunityLineItem', 'Specialist_Forecast_Category__c'));
                returnMap.put('isSpecialistUser', validateSpecialistUser(UserInfo.getProfileId()));
                return returnMap;
        }

        @AuraEnabled // SFDC-3714
        public static Boolean validateSpecialistUser(Id userId) {
                String specialistAllowedProfilesFieldEdit = EMRIProductSettings.getEmriProductWizardSettingValue('Specialist_field_edit_allowed_Profiles');
                return specialistAllowedProfilesFieldEdit.contains(userId);
        }

    
    @AuraEnabled
    public static List<String> fetchPicklistValues(String sobjectName, String picklistFieldName)
    {
        List<String> options = GSMLite_UtilClass.populatePickList(sobjectName,picklistFieldName);
        return options;
    }
    
    @AuraEnabled
    public static Map<String,List<String>> getDependentPicklist(String sobjectName, String parentfieldName, String childFieldName)
    {
        Map<String,List<String>> options = GSMLite_UtilClass.GetDependentOptions(sobjectName,parentfieldName,childFieldName);
        return options;
    }
    
    @AuraEnabled
    public static String insertProductObj(OpportunityLineItem pageObject) {
        insert pageObject;  
        return pageObject.Id;
    }
    
    @AuraEnabled
    public static String updateOpportunityObj(Opportunity pageObject) {
            try{
                System.debug('Try Block:'+pageObject);
                System.debug(LoggingLevel.Error,'Try Block:'+pageObject.Opportunity_Category__c);
                System.debug('Try Block:'+pageObject.Loss_Reason__c);
                update pageObject;
                System.debug('++++++++Saket Logs+++++++++++');
                System.debug('Try Block:'+pageObject);
                System.debug('Try Block:'+pageObject.Opportunity_Category__c);
                System.debug('Try Block:'+pageObject.Loss_Reason__c);
                return 'success';

            }
            catch(Exception Ex){
                System.assert(1 != 1,'Hello Saket::'+Ex.getMessage());
                System.debug('updateOpportunityObj Error:'+Ex.getMessage());
                System.debug(LoggingLevel.Error, 'Catch Block:'+Ex.getMessage());
                return 'failure';
            }
                
        }
    
    @AuraEnabled
    public static String fetchPricebookEntry(String productId,String currencyCode) {
        PricebookEntry priceBook = [Select Id,Product2Id, Name from pricebookentry where CurrencyIsoCode=:currencyCode
                                    and IsActive=true and Product2Id = :productId];
        system.debug('Price Book = '+priceBook.Id);
        return priceBook.Id;
    }

    @AuraEnabled
    public static Opportunity noContractChanges(String oppId) {
        List<OpportunityLineItem> updateOppLines = new List<OpportunityLineItem>();
        List<OpportunityLineItem> deleteOppLines = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppLineObj : [Select Id,Projected_Monthly_commit_fees__c,Average_Renewal_Commit_MRR__c,
                                              Projected_Avg_Rev_Non_Commit__c,Average_Renewal_Usage_MRR__c,Quantity__c 
                                              from OpportunityLineItem where OpportunityId = :oppId]) 
        {
            if(oppLineObj.Average_Renewal_Commit_MRR__c != null)
                oppLineObj.Projected_Monthly_commit_fees__c = oppLineObj.Average_Renewal_Commit_MRR__c;  
            else
                oppLineObj.Projected_Monthly_commit_fees__c = 0;

            if(oppLineObj.Average_Renewal_Usage_MRR__c != null)
                oppLineObj.Projected_Avg_Rev_Non_Commit__c = oppLineObj.Average_Renewal_Usage_MRR__c; 
            else
                oppLineObj.Projected_Avg_Rev_Non_Commit__c = 0;

            if(oppLineObj.Quantity__c == 0 || oppLineObj.Quantity__c == null) {
                oppLineObj.Quantity__c = 1;
            }

            if(oppLineObj.Average_Renewal_Commit_MRR__c == null && oppLineObj.Average_Renewal_Usage_MRR__c == null)
                deleteOppLines.add(oppLineObj);
            else
                updateOppLines.add(oppLineObj);
        }
        delete deleteOppLines;
        update updateOppLines;
        return SF1_OpportunityService.getOpportunity(oppId);
    }
    
    @AuraEnabled
    public static Opportunity performChurnCancelOnOppLines(Opportunity oppObject,Boolean contractValue) {
        List<OpportunityLineItem> updateOppLines = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppLineObj : [Select Id,Projected_Monthly_commit_fees__c,
                                              Projected_Avg_Rev_Non_Commit__c,
                                              Quantity__c
                                              from OpportunityLineItem where OpportunityId = :oppObject.Id]) {
            oppLineObj.Projected_Monthly_commit_fees__c = 0;
            oppLineObj.Projected_Avg_Rev_Non_Commit__c = 0;  
            if(oppLineObj.Quantity__c == 0 || oppLineObj.Quantity__c == null) {
                oppLineObj.Quantity__c = 1;
            }
            updateOppLines.add(oppLineObj);
        }
        
        /*for(OpportunityLineItem oppLine : oppObject.OpportunityLineItems) {
            oppLine.Projected_Monthly_commit_fees__c = 0;
            oppLine.Projected_Avg_Rev_Non_Commit__c = 0;                                     
            updateOppLines.add(oppLine);    
        }*/
        update updateOppLines;
        if(contractValue)
            oppObject.Churn_No_Paper__c = true;
        else
            oppObject.Churn_No_Paper__c = false;
        oppObject.Opportunity_Revenue_Impact__c = 0;
        for(OpportunityLineItem oppLineObj : [Select Id,EMRI__c from OpportunityLineItem 
                                              where OpportunityId = :oppObject.Id]) {
            oppObject.Opportunity_Revenue_Impact__c = oppObject.Opportunity_Revenue_Impact__c + oppLineObj.EMRI__c;
                                                
        }
        update oppObject;
        return SF1_OpportunityService.getOpportunity(oppObject.Id);
    }

    @AuraEnabled
    public static Boolean checkBaselineNegativeAmount(String oppId) {
        Boolean negativeValue = false;
        for(OpportunityLineItem oppLineObj : [Select Id,Projected_Monthly_commit_fees__c,UnitPrice
                                              from OpportunityLineItem where OpportunityId = :oppId]) {
            system.debug('Net MRR = '+oppLineObj.UnitPrice);                                      
            if(oppLineObj.UnitPrice < 1) {
                negativeValue = true;
                system.debug('In Negative');
            }                                          
        }
        return negativeValue;
    }
    
    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiThemeDisplayed();
        system.debug('theme == '+theme);
        return theme;
    }

    @AuraEnabled
    public static Order_Approval__c returnOrderApprovalDetails(String orderAppId) {
        Order_Approval__c orderAppObj = [Select Id,Account_Primary_Country__c,E_Sign_Admin_Override__c, 
                                         Order_Expires_Unless_Duly_Executed_By__c from Order_Approval__c
                                         where Id = :orderAppId];
        return orderAppObj;
    }
   
}