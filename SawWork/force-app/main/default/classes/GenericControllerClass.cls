global virtual class GenericControllerClass {
	
     protected GenericDataClass dataObject;
     
     public GenericControllerClass()
     {
     	
     }
     
     public GenericControllerClass(String className)
     {
     	dataObject=GenericDataClass.getDataClassObject(className);
     }
     
     public String getPLMCustomSettingValue(String customSettingName)
     {
     	String value=PLM_Custom_Settings__c.getInstance(customSettingName).value__c;
     	return value;
     }
     
     public Features_Toggle__c getFeatureToggleCustomSettings(String customSettingName)
     {
     	Features_Toggle__c featureEnable=Features_Toggle__c.getInstance(customSettingName);
     	return featureEnable;
     }
     
}