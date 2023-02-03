/* Author- Ruchika Sharma
Story: SFDC-1481
*/
trigger Partner_Client_Manager_bi_bu on Partner_Client_Manager__c (before insert, before update){
for(Partner_Client_Manager__c pcm : Trigger.new)
    {
        pcm.Partner_Client_Manager_Ext_Id__c = pcm.Indirect_Account__c+'#'+pcm.Partner_Account__c;
    }	
}