/**

**/
public class ChimeTriggerHandler extends ApexTriggerHandlerAbstractClass {
    public override void beforeInsertBeforeUpdateTrigger(){
        Set<String> setScopeCreeps = new Set<String>();
        List<GSM_Settings_Verbose__mdt> scopeCreepList = [SELECT Id,MasterLabel,Value__c from GSM_Settings_Verbose__mdt where MasterLabel = 'CHIME Scope Creeps' limit 1];
        
        for(GSM_Settings_Verbose__mdt mdt: scopeCreepList){
            setScopeCreeps.addAll(mdt.Value__c.split(';'));
            break;
        }
        List<CHIME__c> chimeTriggerNew = (List<CHIME__c>)newList;
        Map<Id,CHIME__c> chimeTriggerOldMap = (Map<Id,CHIME__c>)oldMap;
        for(CHIME__c chime : chimeTriggerNew) {
            
            if(chimeTriggerOldMap != null && (chimeTriggerOldMap.get(chime.Id).Status__c != chime.Status__c ) && chime.Stage__c  == 'Integration' && chime.Status__c  == 'Reopened'){
                for(String str: chime.Reopen_Reason__c.split(';')){
                    if(setScopeCreeps.contains(str)){
                        if(chime.Scope_Creep_Count__c == null || chime.Scope_Creep_Count__c == 0)
                            chime.Scope_Creep_Count__c=1;
                        else
                            chime.Scope_Creep_Count__c +=1;
                        
                        break;
                    }
                }
            }
            if(chimeTriggerOldMap != null && (chimeTriggerOldMap.get(chime.Id).Status__c != chime.Status__c ) && chime.Stage__c  == 'Integration' && chime.Status__c  == 'Reopened'){
                if(chime.Reopen_Count__c == null || chime.Reopen_Count__c == 0)
                    chime.Reopen_Count__c=1;
                else
                    chime.Reopen_Count__c +=1;
            }
            
        }
    }
    
    public override void afterInsertAfterUpdateTrigger() {
        List<CHIME__c> chimeTriggerNew = (List<CHIME__c>)newList;
        Map<Id,CHIME__c> chimePlanTriggerOldMap = (Map<Id,CHIME__c>)oldMap;
        ChimeTriggerHandler.processAuditTrails(chimeTriggerNew,chimePlanTriggerOldMap);

        List<Id> chimeIdList = new List<Id>();

        for(CHIME__c chime : chimeTriggerNew){
            if(Trigger.isUpdate && Util.hasChanges('Stage__c', chimePlanTriggerOldMap.get(chime.Id), chime) && chime.Stage__c == 'Closed'){
                chimeIdList.add(chime.id);
            }
        }

        if(chimeIdList.size() > 0){
            ChimeTriggerClass.checkChimeContactAccess(chimeIdList, 'Chime');
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
    
    private static Map<String,String> getFieldsForAudit (){
        Map<String,String> pickListValuesList= new Map<String,String>();
		Schema.DescribeFieldResult fieldResult = CHIME_Audit_Trail__c.Field__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.put( pickListVal.getValue(),pickListVal.getLabel());
		}     
		return pickListValuesList;

    }
    
    public static void processAuditTrails(List<CHIME__c> chimeTriggerNew, Map<Id,CHIME__c> chimeTriggerOldMap){
        //List<CHIME__c> allChime = new List<CHIME__c>();
        Set<String> setScopeCreeps = new Set<String>();
        List<GSM_Settings_Verbose__mdt> scopeCreepList = [SELECT Id,MasterLabel,Value__c from GSM_Settings_Verbose__mdt where MasterLabel = 'CHIME Scope Creeps' limit 1];
        
        for(GSM_Settings_Verbose__mdt mdt: scopeCreepList){
            setScopeCreeps.addAll(mdt.Value__c.split(';'));
            break;
        }
        List<CHIME_Audit_Trail__c> allTrails = new List<CHIME_Audit_Trail__c>();
        Map<String,String> mapAuditFields= getFieldsForAudit();
        Set<String> objectFields = Schema.SObjectType.CHIME__c.fields.getMap().keySet();

        for(CHIME__c chime : chimeTriggerNew) {
            
            //if(chimeTriggerOldMap != null && (chimeTriggerOldMap.get(chime.Id).Status__c != chime.Status__c ) && chime.Stage__c  == 'Integration' && chime.Status__c  == 'Reopened'){
             
            for(String field : mapAuditFields.keySet()){
                if( field != 'Total_LoE__c'&& objectFields.contains(field.toLowerCase()) && chime?.get(field)!=chimeTriggerOldMap?.get(chime.Id)?.get(field)){
                    CHIME_Audit_Trail__c eachTrail = new CHIME_Audit_Trail__c();
                    eachTrail.PreviousValue__c = (chimeTriggerOldMap?.get(chime.Id)?.get(field)==null) ?'': chimeTriggerOldMap?.get(chime.Id)?.get(field)+'';
                    eachTrail.CurrentValue__c = (chime?.get(field)==null)? '': chime.get(field)+'';
                    eachTrail.Source__c ='CHIME Form';
                    eachTrail.CHIME__c = chime.Id;
                    eachTrail.Field__c = mapAuditFields.get(field);
                    allTrails.add(eachTrail);
                }
            }
        }
        
        if(allTrails.size() > 0) {
            try {
                insert allTrails;
            }
            catch(Exception e) {
                Sawyer.saw(e);
            }
        
            //ChimeResponseTriggerClass.createAuditTrails(allResponses, chimeResponseTriggerOldMap);
        }
    }
}