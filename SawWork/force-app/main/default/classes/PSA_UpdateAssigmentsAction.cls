global class PSA_UpdateAssigmentsAction 
{
// 

@AuraEnabled
public static String callUpdateMethod(String projId)
{
    return updateAssignmentEndDates((Id)projId);    
}

webservice static string updateAssignmentEndDates(Id projId)
    {
        List<pse__Assignment__c> assgn = new List<pse__Assignment__c>();
        list<pse__proj__c> project2Update = [Select Id, Name, pse__End_Date__c, (Select Id, pse__Schedule__c, pse__Project__c from pse__Assignments__r) from pse__proj__c where Id = :projId];
        pse__proj__c projectRecord2Update = new pse__proj__c();
        pse__Schedule__c scheduleToUpdate = new pse__Schedule__c();
        list<pse__Schedule__c> tempscheduleToUpdate = new list<pse__Schedule__c>();
        list<pse__Schedule__c> schedulesToUpdate = new list<pse__Schedule__c>();
        if(project2Update == NULL || project2Update.size()==0)
        {
            return 'Found no Project to process';
        }
        else if(project2Update.size()==1)
        {
           projectRecord2Update = project2Update[0];
           //Assgn = [Select Id,pse__Schedule__c,pse__Project__c from pse__Assignment__c where pse__Project__c = :projectRecord2Update.Id];
           list<Id> scheduleIdList = new list<Id>();
           for(pse__Assignment__c a : projectRecord2Update.pse__Assignments__r)
           {
             scheduleIdList.add(a.pse__Schedule__c); 
           }
          
           tempscheduleToUpdate = [select Id,pse__End_Date__c from pse__Schedule__c where Id in :scheduleIdList and pse__End_Date__c!=:projectRecord2Update.pse__End_Date__c];
           //System.assertEquals(projectRecord2Update.pse__End_Date__c,NULL);
           if(TempscheduleToUpdate!= NULL && TempscheduleToUpdate.size()!=0)
           {
               for(pse__Schedule__c sched2Update : TempscheduleToUpdate)
               {
                   sched2Update.pse__End_Date__c = projectRecord2Update.pse__End_Date__c;
                   schedulesToUpdate.add(sched2Update);
               }
               
               try
               {
                  Database.update(schedulesToUpdate); 
               }
               catch(Exception e)
               {


                  return 'Exception: ' + e.getMessage()+ ' ' + e.getTypeName();
               }

           }
           else 
           {
              return 'All assignment end dates are equal to the Project End Date';
           } 
            
         }
  
        return schedulesToUpdate.size() + ' assignments updated';
     }

}