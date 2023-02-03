trigger SupportTeamTrigger on TS_Support_Team__c (before insert, before update) {
    
    STM_Custom_Modal_Layout__mdt versionFlag = [SELECT Field__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = 'Metadata'];
    
    if(versionFlag.Field__c == 'Old'){
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            if (Trigger.isbefore) 
            {
                If (Trigger.isInsert) {
                    
                    AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
                    AkamFieldHandler.insertHandler(Trigger.new);
                    
                } else if (Trigger.isUpdate) {
                    
                    AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
                    AkamFieldHandler.updateHandler(Trigger.new);
                }
                
                
                /*Code By Knagal: 
				Code to check if any of the fields which are synced  to Siebel are updated by any user other than CrmIntegration
				*/  
                //SyncToSiebelFieldsClass.populateSyncToSiebelField('Account');
            }
            
            //if(Trigger.isBefore && Trigger.isUpdate)
            //AccountTriggerClass.updateFinancialRiskCreditCheck(Trigger.new,Trigger.oldMap);      
            
        }
    }        

}