global class PSA_ReallignProjects implements Database.Batchable<sObject>,Database.Stateful
{
    private string query;
    global list<pse__region__c> Regions;
    list<pse__proj__c> projList;
   
    global PSA_ReallignProjects()
    {
       Regions = [select Id,Name from pse__region__c where Name LIKE '% (Territory)' and psa_Old__c = FALSE];
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
       PSA_RealignRegions ex1 = new PSA_RealignRegions();
       ex1.updateOldRegions();
       
       query='select Id,pse__region__c,pse__account__c,pse__account__r.TERR_HIER_5__c,pse__Allow_Timecards_Without_Assignment__c from pse__proj__c where pse__Allow_Timecards_Without_Assignment__c != TRUE';
       return Database.getQueryLocator(query); 
    }
   
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
       list<pse__proj__c> proj2Update = new list<pse__proj__c>();
       projList = scope;
       for(pse__proj__c p:projList)
       {
           for(pse__region__c r:Regions)
           {
              if(p.pse__account__r.TERR_HIER_5__c + ' (Territory)' == r.Name)
              {
                 if(p.pse__region__c != r.Id)
                 {
                     p.pse__region__c = r.Id;
                     proj2Update.add(p);
                 }
                 break;
              }
           }
       }
       
       Database.update(proj2Update,False);
    }
   
    global void finish(Database.BatchableContext BC)
    {
        PSA_ReallignRR reallignRR= new PSA_ReallignRR();
        database.executebatch(reallignRR);
    }
}