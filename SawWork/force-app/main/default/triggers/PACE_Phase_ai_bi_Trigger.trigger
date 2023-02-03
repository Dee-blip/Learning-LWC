trigger PACE_Phase_ai_bi_Trigger on PACE_Phase__c (after insert,after update,before update) {
    
    if(Trigger.isInsert && Trigger.isAfter){
        PACE_Phase.afterInsert(Trigger.New); 
    }  
   
    if(Trigger.isUpdate && Trigger.isAfter){
        PACE_Phase.updateTabName(Trigger.New); 
    }
    
       
    if(Trigger.isUpdate && Trigger.isBefore){
        PACE_Phase.updateTabName(Trigger.New); 
        List<PACE_Phase__c> pList = new List<PACE_Phase__c>();
        for(PACE_Phase__c item : Trigger.new)
        {
            if((Trigger.oldMap.get(item.Id).PRB_Review_Date__c  != item.PRB_Review_Date__c)&&(item.Moved_from_PRB_Review_Calendar__c ==null)) {
                item.Moved_from_PRB_Review_Calendar__c=Trigger.oldMap.get(item.Id).PRB_Review_Date__c;  
            }
            if((Trigger.oldMap.get(item.Id).Exception_Review_Date__c  != item.Exception_Review_Date__c)&&(item.Moved_from_Exception_Review_Calendar__c ==null)) {
                item.Moved_from_Exception_Review_Calendar__c=Trigger.oldMap.get(item.Id).Exception_Review_Date__c;   
            }
        }   
    }  
}