public class PSA_RealignRegions 
{
   public void updateOldRegions()
    {
    try
    {
        list<pse__Region__c> regOld = [select Id,Name,Region_Unique_Id__c,psa_Old__c from pse__Region__c where psa_Old__c=TRUE and (Not Name  Like '%_OLD') and (Not Name  Like '%_OLD (%')];
        system.debug(regOld);
        set<pse__Region__c> Region2UpdateSet = new set<pse__Region__c>();
        list<pse__Region__c> Region2Update = new list<pse__Region__c>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        for(pse__Region__c r:regOld)
        {
            r.Name+='_OLD';
            r.Region_Unique_Id__c+='_OLD';
            Region2UpdateSet.add(r);
        }
        Region2Update.AddAll(Region2UpdateSet);
        System.debug('Set Values -----> '+Region2UpdateSet);
        System.debug('Set Values -----> '+Region2Update);
        //Update(Region2Update);
        saveResultRecords = Database.Update(Region2Update,false);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords,Region2Update);
        
        }
        catch(Exception e)
        {
        System.assertEquals(('Exception[]:---> '+e.getMessage()),NULL);
        }
        
    }
    
    public void deleteOldRegions()
    {
        list<pse__Region__c> regOld2Delete = [select Id,Name,psa_Old__c from pse__Region__c where psa_Old__c=TRUE and Name LIKE '%Old'];
        Database.delete(regOld2Delete,True);
    }
    
}