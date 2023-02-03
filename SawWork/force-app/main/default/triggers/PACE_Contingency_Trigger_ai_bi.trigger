trigger PACE_Contingency_Trigger_ai_bi on Contingency__c (after insert,before insert,before update,after update) {

    List<Contingency__c> conList = new List<Contingency__c>();
    /*Map<Id,Id> phasemap=new map<Id,Id>();
    map<Id,Id> contingencywithphase=new map<Id,Id>();
    map<Id,Id> conceptmap=new map<Id,Id>();
    map<Id,Id> contingencywithconcept=new map<Id,Id>();*/
    
    map<Id,Id> contingencyToPhaseMap = new map<Id,Id>();
    map<Id,Id> phaseToContingencyMap = new map<Id,Id>();
    //map<Id,Id> contingencyToConceptMap = new map<Id,Id>();
    //map<Id,Id> conceptToContingencyMap = new map<Id,Id>();
   
    PACECustomSettings__c error1 = PACECustomSettings__c.getValues('ContingencyErr#1');
    PACECustomSettings__c error2 = PACECustomSettings__c.getValues('ContingencyErr#2');
    PACECustomSettings__c error3 = PACECustomSettings__c.getValues('ContingencyErr#3');
    PACECustomSettings__c error4 = PACECustomSettings__c.getValues('ContingencyErr#4');
              
    List<Id> phases=new List<Id>();
    if(Trigger.isInsert && Trigger.isAfter){ 
    
    for(Contingency__c con:Trigger.New){
    
        if(con.Phase__c!=null){
      
            contingencyToPhaseMap.put(con.id,con.Phase__c);
            phaseToContingencyMap.put(con.Phase__c,con.Id);
        }
        /* else{
        
            contingencyToConceptMap.put(con.Id,con.Concept__c); 
            conceptToContingencyMap.put(con.Concept__c,con.Id);
       }*/
       
   }
   //phases=contingencyToPhaseMap.values();
    
   for(PACE_Phase__c phase:[Select Id,PACE_Program__r.Program_Manager__c From PACE_Phase__c where Id IN : contingencyToPhaseMap.values()]){
       Id ContingencyId = phaseToContingencyMap.get(phase.Id);
       Contingency__c cont = new Contingency__c(Id = ContingencyId,Assigned_To__c = phase.PACE_Program__r.Program_Manager__c);    
       conList.add(cont);
   }    
   
  /* for(PACE_Concept__c concept:[Select Id,Program_Manager__c From PACE_Concept__c where Id IN : contingencyToConceptMap.values()]){
       Id ContingencyId=conceptToContingencyMap.get(concept.Id);
       Contingency__c cont = new Contingency__c(Id = ContingencyId,Assigned_To__c = concept.Program_Manager__c);    
       conList.add(cont);
   }  */
   
   if(conList.size()>0){
          update conList;  
            return;
        }   
       
   }   
   
 
  /* if(Trigger.isInsert && Trigger.isBefore){
     
     for(Contingency__c con: Trigger.New){
         if(con.Concept__c!=null && con.Phase__c!=null){
             con.addError(error1.value__c);
         }
        if(con.Concept__c==null && con.Phase__c==null){
             con.addError(error2.value__c);
         }  
     }
   } */
     
   if(Trigger.isUpdate && Trigger.isBefore){
     
     for(Contingency__c con: Trigger.New){
        /* if(con.Concept__c!=null && con.Phase__c!=null){
             con.addError(error1.value__c);
         }
         if(con.Concept__c==null && con.Phase__c==null){
             con.addError(error2.value__c);
         } */
         //Make Program-Phase field of Contingency a required fied to avoid confusion anymore
         if(Trigger.oldMap.get(con.Id).Phase__c!= con.Phase__c)
         {
             con.addError(error3.value__c);
         }
       /*  if(Trigger.oldMap.get(con.Id).Concept__c!= con.Concept__c)
         {
             con.addError(error4.value__c);
         }*/
    
     }
    }
     
     
}