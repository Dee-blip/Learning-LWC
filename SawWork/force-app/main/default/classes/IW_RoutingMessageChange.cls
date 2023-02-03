public without sharing class IW_RoutingMessageChange {
    @AuraEnabled
    public static String getRoutingMessageToggle(){

        System.debug(' has reached apps :'  );
        return JSON.serialize( [select Value__c from PSA_Common_Setting__mdt where developerName = 'IW_Routing_Message_Text'].Value__c ) ;

    }
}