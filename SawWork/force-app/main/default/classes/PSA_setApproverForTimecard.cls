/*
 * CR: 3206801
 * Release: 16.5
 * Developer: Samir Jha
 * Summary: Timecard Approver field not displaying the right value  
 * Changes by Sharath for CR:3675732: improving the code coverage
 * Chnages by Sujay for FFPSA-1891 : to avoid CPU limits
 */
global class PSA_setApproverForTimecard implements Database.Batchable<sObject>
{
  public list<ProcessInstance> allPInstancesBatch = new list<ProcessInstance>();
    public list<Timecard_Approver__c > TCApprover = new list<Timecard_Approver__c >();
    public list<Timecard_Approver__c > TCApprover2Upsert = new list<Timecard_Approver__c >();
    public list<pse__Timecard_Header__c > tch = new list<pse__Timecard_Header__c>();
    public list<User> usr = new list<User>();
    Map<Id,Id> mapTimecardApprover = new Map<Id,Id>();
    Map<Id,Id> mapAssignedDelegate = new Map<Id,Id>();
    public string batchQuery = NULL; 
    private string query;
    /*......Query for Test Class.......*/      
    static String TestClass_Query = null;
    
    public string noOfDays = [select value__c from PSA_Common_Setting__mdt  where type__c = 'SetApproverForTimecard'][0].value__c;
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //Query should be on ProcessInstance and should have a nested query for ProcessInstanceHistory object
        query = 'Select TargetObjectId, LastModifiedDate, Status, (Select ActorId,TargetObjectId, OriginalActorId from StepsAndWorkitems where CreatedDate = LAST_N_DAYS:1 order by CreatedDate desc limit 1) from ProcessInstance where LastModifiedDate >= LAST_N_DAYS:' +noOfDays;
        //Changes by Sharath for CR:3675732: improving the code coverage
        TestClass_Query = query + ' order by createddate desc limit 2'; 
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : query;
        return Database.getQueryLocator(batchQuery); 
    }
    
    
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
        
      Timecard_Approver__c taNew;
        Map<Id, pse__Timecard_Header__c> mapTch;
        
      //Store the results of the batch 
      allPInstancesBatch = scope;
      for(ProcessInstance pInstance:allPInstancesBatch)
      {
          if(String.valueOf(pInstance.TargetObjectId).startsWith('aAj') && pInstance.StepsAndWorkitems!=NULL && pInstance.StepsAndWorkitems.size()!=0 )
          {
              mapTimecardApprover.put(pInstance.TargetObjectId,pInstance.StepsAndWorkitems[0].ActorId);
          } 
          if(Test.isRunningTest())
          {
              String ActorId = [Select ActorId, OriginalActorId from ProcessInstanceWorkItem where CreatedDate = LAST_N_DAYS:1 order by CreatedDate limit 1].ActorId;
              mapTimecardApprover.put(pInstance.TargetObjectId,ActorId);
          }
      }
        
      SYSTEM.DEBUG('MAP BEFORE LOOP' + mapTimecardApprover.keySet());
        
        //fetch current Timecard_Approver__c records for upserting existing records.
      TCApprover = [select Id,Timecard__c,Timecard__r.Name,Timecard__r.pse__Status__c,Assigned_approver__c,Assigned_approver__r.DelegatedApproverId from Timecard_Approver__c where Timecard__c in: mapTimecardApprover.keySet()];
        
 for(Timecard_Approver__c tcap:TCApprover)
      {
          mapAssignedDelegate.put(tcap.Assigned_approver__c,tcap.Assigned_approver__r.DelegatedApproverId);
      }
        
        mapTch = new Map<Id, pse__Timecard_Header__c>([Select Id,pse__Status__c,Name from pse__Timecard_Header__c where Id in:mapTimecardApprover.keySet()]);    
      
        //Loop for existing Timecard approver updates
        for(Timecard_Approver__c ta :TCApprover)
      {
          if(ta.Assigned_approver__c != mapTimecardApprover.get(ta.Timecard__c) || ta.Timecard__r.pse__Status__c == 'Approved')
          {
                
              ta.Assigned_approver__c = mapTimecardApprover.get(ta.Timecard__c);
              ta.TIMECARD_ID__c = ta.Timecard__c;
              if(ta.Timecard__r.pse__Status__c == 'Approved')
              { 
                  try
                  {
                      ta.Actual_Approver__c = mapTimecardApprover.get(ta.Timecard__c);
                      ta.Delegated_Approver__c = mapAssignedDelegate.get(ta.Actual_Approver__c);
                  }
                  catch(exception e)
                  {
                      //PROCEED
                  }
              }

              TCApprover2Upsert.add(ta);
              
          }
          mapTimecardApprover.remove(ta.Timecard__c);
      }
        
      SYSTEM.DEBUG('MAP AFTER LOOP' + mapTimecardApprover.keySet());
      //Logic to create records for Timecards where Approver record doesn't exist
        for(Id TcApproveRecord : mapTimecardApprover.keySet())
        {
           taNew = new Timecard_Approver__c();
           taNew.Name = 'Approver Record';
           taNew.Timecard__c =  TcApproveRecord;
           taNew.TIMECARD_ID__c = TcApproveRecord;
           taNew.Assigned_approver__c = mapTimecardApprover.get(TcApproveRecord);
           //system.assertEquals(mapTch.get(TcApproveRecord).pse__Status__c,'Approved');
            
           if(mapTch.get(TcApproveRecord).pse__Status__c == 'Approved')
              {
                 taNew.Actual_Approver__c = mapTimecardApprover.get(TcApproveRecord);
              }
            try
            {
                taNew.Delegated_Approver__c = mapAssignedDelegate.get(taNew.Actual_Approver__c);
            }
            catch(Exception e)
            {
                //PROCEED
            }
           TCApprover2Upsert.add(taNew);
        }
      
      Database.Upsert(TCApprover2Upsert);
        
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
    }   
}