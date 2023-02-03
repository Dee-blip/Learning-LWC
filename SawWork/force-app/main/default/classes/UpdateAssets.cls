public class UpdateAssets implements Schedulable{

    public void execute(SchedulableContext sc){
         Date start=Date.Today().addDays(-1);
         String assets='Select Akamai_Asset_Status__c,Apttus_Config2__AssetStatus__c,Apttus_Config2__BundleAssetId__c, Apttus_Config2__IsInactive__c,Apttus_Config2__EndDate__c,Termination_date__c,Subscription_ID__c,Apttus_Config2__ProductId__c,Apttus_Config2__OptionId__c,Apttus_Config2__LineType__c,Apttus_Config2__StartDate__c,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__PriceType__c,Apttus_Config2__ChargeType__c,Expired_Charges__c,Asset_Attribute_Value__c from Apttus_Config2__AssetLineItem__c';
         Id batchInstanceId = Database.executeBatch(new ProcessAssets(assets,start)); 


}
}