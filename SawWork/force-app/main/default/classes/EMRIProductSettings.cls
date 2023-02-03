public class EMRIProductSettings {

    public static List<EMRI_Product_Wizard_Settings__mdt>  getAll()
    {
        List<EMRI_Product_Wizard_Settings__mdt> listOfEMRIProductWizardSettings = new List<EMRI_Product_Wizard_Settings__mdt>();
        listOfEMRIProductWizardSettings = [Select Id,DeveloperName,MasterLabel,Editable__c,Help_Text_or_Error_Message__c,value__c from EMRI_Product_Wizard_Settings__mdt limit 50000];
        return listOfEMRIProductWizardSettings;
    }

    //rsharma - get the value of metadatatype field provided
    public static Map<String,String> getFieldToValue(String fieldToCheck){
    	List<EMRI_Product_Wizard_Settings__mdt> listOfEMRIProductWizardSettings = new List<EMRI_Product_Wizard_Settings__mdt>();
    	listOfEMRIProductWizardSettings = getAll();
    	Map<String,String> mapOfFieldToValue = new Map<String,String>();

    	if(listOfEMRIProductWizardSettings.size()>0)
    	{
    		for(EMRI_Product_Wizard_Settings__mdt settingInstance : listOfEMRIProductWizardSettings)
    		{
             	String fieldToCheckValue= String.valueOf(settingInstance.get(fieldToCheck));
    			if(!String.isBlank(fieldToCheckValue))
    				mapOfFieldToValue.put(settingInstance.DeveloperName,fieldToCheckValue);
    			

    		}	

    	}

    	return mapOfFieldToValue;
    }

    //rsharma - get all fields value for record with given developer name
    public static String getEmriProductWizardSettingValue(String developerName)
    {
        EMRI_Product_Wizard_Settings__mdt mdtRecord = [select Id,Editable__c, Help_Text_or_Error_Message__c, value__c from EMRI_Product_Wizard_Settings__mdt where DeveloperName = :developerName];
        return mdtRecord.Value__c;
    }
}