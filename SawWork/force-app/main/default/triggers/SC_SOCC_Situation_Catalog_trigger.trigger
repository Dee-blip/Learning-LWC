trigger SC_SOCC_Situation_Catalog_trigger on SC_SOCC_Situation_Catalog__c (before insert, before update, after insert, after update, before delete, after delete)
{
     if(Trigger.isBefore){
          //Check if User is Shift Manager
          Boolean isShiftManager = SC_SOCC_Instruction_Manager.checkIfShiftManager();
          if(!isShiftManager){
               if(Trigger.isInsert || Trigger.isUpdate)
                    Trigger.new[0].addError('Only a shift manager can create/edit a situtaion catalog!');
               if(Trigger.isDelete)
                    Trigger.old[0].addError('Only a shift manager can delete a situtaion catalog!');
          }



          if(Trigger.isInsert)
          {
               //Call for Deduplication
               SC_SOCC_situationCatalogTriggerHandler.preventDupliactes(Trigger.New);
               
               //Call to Populate Handler Type Lookup
               SC_SOCC_situationCatalogTriggerHandler.populateHandlerTypeLookup(Trigger.New);
               
          }
          
          
          if(Trigger.isUpdate)
          {
               List<SC_SOCC_Situation_Catalog__c> situationCatalogList = new List<SC_SOCC_Situation_Catalog__c>();
               for(SC_SOCC_Situation_Catalog__c sc:Trigger.New)
               {
                         if(Trigger.oldMap.get(sc.id).Handler_Type_picklist__c!=Trigger.NewMap.get(sc.id).Handler_Type_picklist__c)
                         {
                              situationCatalogList.add(sc);
                         
                         }
               }
               
               if(situationCatalogList.size()>0)
               {
                    SC_SOCC_situationCatalogTriggerHandler.populateHandlerTypeLookup(situationCatalogList);
               }
                    
          }
     }
}