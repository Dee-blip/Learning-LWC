trigger OCpkgpricingBIBU on Online_Channel_Package_Pricing__c (before insert, before update) {

for (Online_Channel_Package_Pricing__c ocp: Trigger.new){
ocp.Uniqueness_Constraint__c=ocp.Online_Channel_Package_Product__c +'-'+ocp.CurrencyIsoCode;
}

}