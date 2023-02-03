/****
3.42 Pramod for OC

****/

trigger OCCampaignBIBU on Campaign_AkamOnline__c (before insert, before update) {


for (Campaign_AkamOnline__c occ: Trigger.new){



if(occ.Campaign_Type__c=='Default')
{
occ.Is_Default_In_Package__c=occ.Campaign_Package__c+'-'+occ.Campaign_Type__c;
}
else
occ.Is_Default_In_Package__c=occ.id;
}



}