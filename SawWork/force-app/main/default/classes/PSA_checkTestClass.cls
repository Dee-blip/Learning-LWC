public class PSA_checkTestClass {

    @AuraEnabled
    public static String checkValidity(Id recordId)
    {
        List <pse__Proj__c> projects = new List <pse__Proj__c>();
        List <pse__Milestone__c> milestones = new List <pse__Milestone__c>();
        List <pse__Project_Methodology__c> products = new List <pse__Project_Methodology__c>();
        String url; 
        if(String.valueOf(recordId).startsWith('aAE'))
        {
            projects= [SELECT Name from pse__Proj__c where Id = :recordId];
            if(!projects.isEmpty())
            {
                products = [SELECT Name from pse__Project_Methodology__c where pse__Project__c = :recordId and Name = 'CloudTest on Demand'];
                if(!products.isEmpty())
                {
               		 url = null;      
                     return url;
                }
            }
        }
        else
        {
         	milestones =  [SELECT pse__Project__r.Id,pse__Project__r.Name from pse__Milestone__c where Id = :recordId];  
            if(!milestones.isEmpty())
            {	
                Id projectId = milestones.get(0).pse__Project__r.Id;
                products = [SELECT Name from pse__Project_Methodology__c where pse__Project__c = :projectId and Name = 'CloudTest on Demand'];
                if(!products.isEmpty())
                {
               		 url = projectId;      
                     return url;
                }
            }
        }
        url = 'Test records can only be associated to CloudTest on Demand Product!';
        return url;
    }

}