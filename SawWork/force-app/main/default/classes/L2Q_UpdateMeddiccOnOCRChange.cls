global class L2Q_UpdateMeddiccOnOCRChange implements Schedulable {
    global void execute(SchedulableContext ctx){
        Set<Id> oppIds = new Set<Id>();
        Integer lastNHours = Integer.valueOf(GsmUtilClass.getGSMSettingValue('MEDDICC_OpptyContactRoleUpdateLastNHours'));
        //collect opportunitycontactrole ids
        for(OpportunityContactRole ocr : [select Id, OpportunityId from OpportunityContactRole where OpportunityId != null and LastModifiedDate >=: Datetime.now().addHours(-(lastNHours)) ALL ROWS]){
            oppIds.add(ocr.OpportunityId);
        }
        string gsmSettingDeveloperNames = 'MEDDICC_Champion_Identified,MEDDICC_EB_Identified,MEDDICC_EconomicBuyerRole,MEDDICC_ChampionRole';
        Map<string,string> gsmMetadata = GsmUtilClass.getKeyValueMetadata('GSM_Settings__mdt','Value__c',gsmSettingDeveloperNames,false);
        
        List<String> ocrRoles = new List<String>{gsmMetadata.get('MEDDICC_EconomicBuyerRole'),gsmMetadata.get('MEDDICC_ChampionRole')};
            List<String> meddiccQuestions = new List<String>{gsmMetadata.get('MEDDICC_EB_Identified'),gsmMetadata.get('MEDDICC_Champion_Identified')};
                List<MEDDICC__c> meddicToUpdate = new List<MEDDICC__c>();
        //fetching opportunity with its meddicc and opportunitycontactroles
        List<Opportunity> oppList = [select Id, (select Id,Response__c,MEDDICC_Questionnaire__c,MEDDICC_Questionnaire__r.AKAM_MEDDICC_Questionnaire_ID__c from MEDDICC__r where MEDDICC_Questionnaire__r.AKAM_MEDDICC_Questionnaire_ID__c IN : meddiccQuestions), (select Id,Role from OpportunityContactRoles where Role IN : ocrRoles) from Opportunity where Id IN : oppIds];
        
        //derermining response based on opportunitycontactroles
        for(Opportunity op : oppList){
            boolean hasEB=false,hasChamp=false;
            for(OpportunityContactRole ocr : op.OpportunityContactRoles){
                if(ocr.Role==gsmMetadata.get('MEDDICC_EconomicBuyerRole')) hasEB=true;
                else if(ocr.Role==gsmMetadata.get('MEDDICC_ChampionRole')) hasChamp=true;
                if(hasEB && hasChamp) break;
            }
            for(MEDDICC__c m : op.MEDDICC__r){
                if(gsmMetadata.get('MEDDICC_EB_Identified').contains(m.MEDDICC_Questionnaire__r.AKAM_MEDDICC_Questionnaire_ID__c)){
                    m.Response__c = (hasEB && !m.Response__c)?true:false; meddicToUpdate.add(m);
                }
                else if(gsmMetadata.get('MEDDICC_Champion_Identified').contains(m.MEDDICC_Questionnaire__r.AKAM_MEDDICC_Questionnaire_ID__c)){
                    m.Response__c = (hasChamp && !m.Response__c)?true:false; meddicToUpdate.add(m);
                }
            }
        }
        try {
            if(!meddicToUpdate.isEmpty()) { ByPassAndLimitUtils.disable('OpportunityTriggerGeneric'); database.update(meddicToUpdate,false); }
        }
        catch(Exception ex) { Sawyer.saw(ex); }
    }
}