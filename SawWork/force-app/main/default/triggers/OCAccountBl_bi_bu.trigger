/**
    OCAccountBl_bi_bu
    
    @Author: Ruchika Sharma <rsharma@akamai.com>
    
    @Description: Trigger on Online_Channel_Account_Blacklist__c object
                  --> CR 2835876 : Added code to prevent duplication of blacklisted account
 */
trigger OCAccountBl_bi_bu on Online_Channel_Account_Blacklist__c (before insert, before update) {
    for(Online_Channel_Account_Blacklist__c OCAccBl : Trigger.new){
        //Check if account to be blacklisted is not empty 
        if( OCAccBl.Account__c!=null ){
            if(Trigger.isInsert){
                 OCAccBl.Unique_Blacklisted_Account__c = OCAccBl.Account__c+''+OCAccBl.Online_Channel_Package__c;   
            }
            //On update Check if account to be blacklisted is changed from previous value
            else if(Trigger.oldMap.get(OCAccBl.id).Account__c!=null && OCAccBl.Account__c!=Trigger.oldMap.get(OCAccBl.id).Account__c){
                 OCAccBl.Unique_Blacklisted_Account__c = OCAccBl.Account__c+''+OCAccBl.Online_Channel_Package__c;
            }
        }
    }
}