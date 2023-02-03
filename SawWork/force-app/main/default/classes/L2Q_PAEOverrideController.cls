public without sharing class L2Q_PAEOverrideController {

	@AuraEnabled
    public static Partner_Marketing_Activity__c fetchPMA(Id pmaId){
        Partner_Marketing_Activity__c pma;
        try {
            pma = [Select PAE_Forecast_Override__c, PAE_Forecast_DR__c, PAE_Forecast_Monthly_Bookings__c, PAE_Forecast_Closed_Deals__c, PAE_Forecast_Total_Contract_Value__c, Forecast_DR__c, Forecast_Closed_Deals__c, Forecast_Monthly_Bookings__c, Forecast_Total_Contract_Value__c from Partner_Marketing_Activity__c where id=:pmaId];
        } catch (QueryException e){
            System.debug('No record was found for the Id provided. Returning null pma');
        }
        return pma;
    }

    @AuraEnabled
    public static List<String> fieldAPINameToLabel(List<String> fieldAPINames){
        Schema.DescribeSObjectResult r1 = Partner_Marketing_Activity__c.SObjectType.getDescribe();  
       Map<String , Schema.SObjectField> fieldNameMap = r1.fields.getMap(); 
        List<String> fieldLabels = new List<String>();
        for(String fieldAPIName: fieldAPINames){
            Schema.SObjectField F = fieldNameMap.get(fieldAPIName); //where fieldAPIName is API name of field
            Schema.DescribeFieldResult R = F.getDescribe();
            String fieldLabel=R.getLabel();
            fieldLabels.add(fieldLabel);
        }
        return fieldLabels;
    }

    @AuraEnabled
    public static string updateOpportunity(string pmaId, string opportunityId){
        Opportunity oppty = new Opportunity(Id=opportunityId);
        oppty.Partner_Marketing_Activity__c = pmaId;
        oppty.Validation_Override__c = true;
        try{
            update oppty;
            return 'success';
        }
        catch(DmlException e){
            Error_Log__c eL = new Error_Log__c(Name='editPMA_OnOppty', Class__c='L2Q_PAEOverrideController', Error_Message__c=e.getMessage());
            insert eL;
            return e.getMessage();
        }
    }

    @AuraEnabled
    public static Map<string,string> getInitialValues(){
        Map<string,string> config = new Map<string,string>();
        config.put('ActivityStatus',GsmUtilClass.getGSMSettingValue('EditPartMAOnOppty_ActivityStatus'));
        config.put('TimeoutVal',GsmUtilClass.getGSMSettingValue('EditPartMAOnOppty_SetTimeoutVal'));
        return config;
    }
}