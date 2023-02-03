/*Customer Community Component*/
global with sharing class communityLoginLinkController {
    @AuraEnabled
    public static string getNetworkURL(){
        id myNetworkId = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt limit 1].CommunityNetworkId__c;
        
        string networkURL = Network.getLoginUrl(myNetworkId);
        integer lastIdex = networkURL.indexOf('login');   
        networkURL = networkURL.substring(0,lastIdex);
        return networkURL;
        
    }
    
    
}