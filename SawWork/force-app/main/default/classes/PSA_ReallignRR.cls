global class PSA_ReallignRR implements Database.Batchable<sObject>,Database.Stateful
{
    private string query;
    global list<pse__region__c> Regions;
    list<pse__Resource_Request__c> RRList;
    /*global PSA_ReallignRR()
    {
       Regions = [select Id,Name from pse__region__c where Name LIKE '% (Territory)'];
    }
                */
  
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
       query='select Id,pse__region__c,pse__project__c,pse__project__r.pse__region__c from pse__Resource_Request__c where ( NOT pse__region__r.Name LIKE \'Corporate\') ';
       return Database.getQueryLocator(query);
    }
  
                global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
       list<pse__Resource_Request__c> RR2Update = new list<pse__Resource_Request__c>();
       RRList = scope;
       for(pse__Resource_Request__c p:RRList)
       {
           if(p.pse__region__c != p.pse__project__r.pse__region__c)
           {
               p.pse__region__c = p.pse__project__r.pse__region__c;
               RR2Update.add(p);
           }
                 
       }
    
        
       Database.update(RR2Update,False);
    }
  
    global void finish(Database.BatchableContext BC)
    {
       // send errored records as mail.
    }
}