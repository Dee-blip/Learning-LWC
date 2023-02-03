global class HD_Batchable_Resolved_State_To_Closed implements Database.Batchable<SObject>{

    global final String query;
    global final String closestateid;
    
    global HD_Batchable_Resolved_State_To_Closed(String q, String ClosedStateId){
        System.debug('In batchable constructor');
        query=q;
        closestateid = ClosedStateId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
      System.debug('In Batchable start');  
        System.debug('Query: '+query);
        
      return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<BMCServiceDesk__Incident__c> scope){
        System.debug('In execute');
        for(BMCServiceDesk__Incident__c inc:scope){
            inc.Force_Change_Status__c = true;
            inc.BMCServiceDesk__FKStatus__c = closestateid;
        }
        update scope;
    }
    
    global void finish( Database.BatchableContext BC )
    {
 		System.debug('In Batchable Finish');
    }
    
}