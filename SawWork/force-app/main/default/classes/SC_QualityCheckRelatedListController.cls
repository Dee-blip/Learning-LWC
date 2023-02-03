public class SC_QualityCheckRelatedListController {  
  
    @AuraEnabled( cacheable=true )  
    public static List < wrapperList > fetchRecords( String listValues )  {  
      
        system.debug( 'values are ' + listValues );  
        //List < String > strList = listValues.split( ',' );  
        //system.debug( 'values are ' + strList );  
          
      
          
            String recordId = listValues;  
            System.debug('rec id**'+recordId);
            /*String objectName = strList.get( 1 );  
            String parentFieldAPIName = strList.get( 2 );  
            String fieldName = strList.get( 3 );  
            String fieldValue = strList.get( 4 );  
            String filterType = strList.get( 5 );  
            String operator = strList.get( 6 );  */
            Knowledge__kav k = [Select Id,KnowledgeArticleId from Knowledge__kav where Id=:recordId]; 
              
            String strSOQL = 'SELECT Id,Name,Total_Score__c,	Cumulative_Score__c,CreatedBy.Name,CreatedDate FROM SC_KCS_Scorecard__c WHERE 	Knowledge__r.KnowledgeArticleId ' + ' = \'' + k.KnowledgeArticleId+'\'';  
            
        
            System.debug('query***'+strSOQL);    
            List<wrapperList> toBeReturnList = new List<wrapperList>(); 
            for(SC_KCS_Scorecard__c iteratedQuality : Database.query( strSOQL )){
                wrapperList sampleInstance= new wrapperList();
                sampleInstance.qualityCoachRec = iteratedQuality;
                sampleInstance.IdURL = '/'+iteratedQuality.Id;
                sampleInstance.cretedByURL='/'+iteratedQuality.CreatedById;
                toBeReturnList.add(sampleInstance);
            } 
            return toBeReturnList; 
         
          
    }  

    public class wrapperList{
        @AuraEnabled
        public SC_KCS_Scorecard__c qualityCoachRec{get;set;}
        @AuraEnabled
        public String IdURL{get;set;}
        @AuraEnabled
        public String cretedByURL{get;set;}

    }
          
}