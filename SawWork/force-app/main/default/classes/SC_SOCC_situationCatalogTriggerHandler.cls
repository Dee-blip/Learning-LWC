public class SC_SOCC_situationCatalogTriggerHandler
{

    public static void populateHandlerTypeLookup(List<SC_SOCC_Situation_Catalog__c> situationCatalogList)
    {
     
            system.debug('In Class');
            //Create a Map of Handler Type picklist name with related Handler Type Lookup Records
            Map<String,Handler_Type__c> picklistHandlerTypeLookup = new Map<String,Handler_Type__c>();
            for(Handler_Type__c handlerType:[Select Id,Name from Handler_Type__c])
            {
              
               picklistHandlerTypeLookup.put(handlerType.Name,handlerType);
                 
            }
            
            System.debug('picklistHandlerTypeLookup '+picklistHandlerTypeLookup);
            
            //add Handler Type Lookup
            for(SC_SOCC_Situation_Catalog__c varSC:situationCatalogList)
            {
            
                 varSC.Handler_Type__c = picklistHandlerTypeLookup.get(varSC.Handler_Type_picklist__c).Id;
            
            }
    
    }
    
    
    //To Prevent Duplicate Combination for SItuation Catalog
    public static void preventDupliactes(List<SC_SOCC_Situation_Catalog__c> situationCatalogList)
    {
         //get recordTypeID
         Id relRecordTypeId = Schema.SObjectType.SC_SOCC_Situation_Catalog__c.getRecordTypeInfosByName().get('Product Related Situations').getRecordTypeId();
         
         //Query All Situation Catalog 
         List<SC_SOCC_Situation_Catalog__c> allSituationCatalog  = [Select Product__c,Situation_Class__c,Event_Name__c from SC_SOCC_Situation_Catalog__c];
         
         if(allSituationCatalog.size()>0)
         {
             //Create a List of Key - Product+Situation Class+Event Name
             List<String> KeyList = new List<String>();
             for(SC_SOCC_Situation_Catalog__c varSC:allSituationCatalog)
             {
                 String Key = varSC.Product__c+varSC.Situation_Class__c+varSC.Event_Name__c;
                 KeyList.add(Key);
             }
             
             //Check for Incoming Situation Catalog list and collect records for which error is to be thrown
             
             for(SC_SOCC_Situation_Catalog__c varSC:situationCatalogList)
             {
             
               system.debug(varSC.RecordType.Name);
             
                if(varSC.RecordTypeId==relRecordTypeId)
               {
                 String Key = varSC.Product__c+varSC.Situation_Class__c+varSC.Event_Name__c;
                 if(KeyList.contains(Key))
                 {
                     varSC.addError('There is already a Situation Catalog Entry with Given Product ,Situation Class, Event Name');
                 }
               }
             
             }
         
         }
    
    
    }



}