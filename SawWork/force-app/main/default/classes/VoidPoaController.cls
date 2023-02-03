/* Class to Void Poa Documents 
Taruni Sunder SFDC - 7900*/


public with sharing class VoidPoaController {

    @AuraEnabled
     public static List<string> voidPoaDocument(String poaId){
        List<String> allowedProfileIds = GsmUtilClass.getGSMSettingValue('POA_ProfilesWithVoidPermissions').split(',');
		//System.debug(allowedProfileIds);
         //List<Profiles_to_Void_Poa__mdt> allowedProfiles= [select Ids__c from Profiles_to_Void_Poa__mdt];
        Set<id> allowedProfileIdsSet = new set<id>();
        for (String allowedProfileId :allowedProfileIds){
            allowedProfileIdsSet.add(allowedProfileId);
        }
        system.debug(LoggingLevel.DEBUG ,'***** allowed profile ids ' + allowedProfileIdsSet );
        
        id pid = userinfo.getProfileId();
        System.debug(LoggingLevel.DEBUG ,'********profile id = '+ pid);
        String currUserProfileName=[Select Id,Name from Profile where Id=:pid].Name;
        
		System.debug(LoggingLevel.DEBUG , '***********ProfileName'+currUserProfileName);
       
        
            //system.debug('yes');
        
        
        //System.debug(LoggingLevel.ERROR, '*********************** in APEX class **********' + poaId);
        
        List<String> returnList = new List<String>();
        List<String> rl;
        String title ='';
        String message = '';
       if(!Schema.sObjectType.Partner_Order_Acceptance_Document__c.fields.id.isAccessible() || !Schema.sObjectType.Partner_Order_Acceptance_Document__c.fields.Order_Acceptance_Status__c.isAccessible()){ 
           return rl;
       }
        List<Partner_Order_Acceptance_Document__c> poa = [Select id,Order_Acceptance_Status__c from Partner_Order_Acceptance_Document__c where id =: poaId  limit 1];
        system.debug(LoggingLevel.DEBUG, 'Status. ---- ' + poa[0].Order_Acceptance_Status__c);
        if(allowedProfileIdsSet.contains(pid)) {
            try{
                    if (Schema.sObjectType.Partner_Order_Acceptance_Document__c.fields.validation_override__c.isUpdateable()) {
                        poa[0].validation_override__c = true;
                        poa[0].Order_Acceptance_Status__c = 'Voided';
                        update poa;
                        title = 'Success!';
                        message = 'Document successfully voided';
                    }
                
            }
            catch (Exception e){
                system.debug(LoggingLevel.DEBUG , 'EXCEPTION--- ' + string.valueOf(e));
                title = 'Error';
                message = string.valueOf(e);
                
            }
        
        }
    
       
       else {
            title = 'Error';
            message = 'Insufficient Access';
        }
        System.debug(LoggingLevel.DEBUG, returnList);
        returnList.add(title);
        returnList.add(message);
        return returnList;
        
    }

}