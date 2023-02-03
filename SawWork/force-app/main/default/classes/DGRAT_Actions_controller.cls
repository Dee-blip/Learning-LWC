public with sharing class DGRAT_Actions_controller {
    
    @auraEnabled
    public static boolean isDeleted(Id tsaId){
        Territory_Security_Assignment__c tsaObj = new Territory_Security_Assignment__c();
        tsaObj = [ select id,Is_Deleted__c from Territory_Security_Assignment__c where Id=: tsaId ];
        system.debug('tsaObj'+tsaObj);
        if(tsaObj.Is_Deleted__c){
            return true;
        }      
        return false;
    }//
    
    @auraEnabled
    public static Territory_Security_Assignment__c toggle_soft_delete(Id tsaId){
        Territory_Security_Assignment__c tsaObj = new Territory_Security_Assignment__c();
        tsaObj = [ select id,Is_Deleted__c from Territory_Security_Assignment__c where Id=: tsaId ];
        if(tsaObj.Is_Deleted__c){
            tsaObj.Is_Deleted__c = false;
        }
        else{
            tsaObj.Is_Deleted__c = true;
        }
        //update tsaObj; 
        List<Territory_Security_Assignment__c> tsaObjList = new List<Territory_Security_Assignment__c>();
        tsaObjList.add(tsaObj);
        Database.SaveResult[] srList = Database.update(tsaObjList,false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Territory Security Assignment. Territory Security Assignment ID: ' + sr.getId());
                return tsaObj;
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Territory Security Assignment fields that affected this error: ' + err.getFields());
                    throw new AuraHandledException(err.getMessage());
                }
            }
        }  
        
      return null;  
    }//
    
}//END