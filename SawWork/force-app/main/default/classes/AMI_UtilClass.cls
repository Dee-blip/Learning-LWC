global without sharing class AMI_UtilClass {
    public static String getAMISettingValue(String developerName)
    {   //SFDC-2686
        List<AMI_Setting__mdt> mdtRecord = [select Id, Value__c from AMI_Setting__mdt where DeveloperName = :developerName];
        if(mdtRecord.size() > 0)
            return mdtRecord[0].Value__c;
        else
            return null;
    }

    public static AMI_Credential__c getAMICredentials(){
        List<AMI_Credential__c> creds = [Select Client_ID__c,Client_Secret__c,Resource_ID__c,Tenant_Id__c from AMI_Credential__c order by createddate desc limit 1];
        if (creds.size() != 0) {
            return creds[0];
        }
        return null;
    }
}