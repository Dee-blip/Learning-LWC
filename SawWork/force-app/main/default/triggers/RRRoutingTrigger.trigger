/*
Author : Samir Jha
This trigger facilitates the Routing of Resource Requests. This uses the conditions stored in RR PS Original Mapping object.
*/
trigger RRRoutingTrigger on pse__Resource_Request__c (before insert,before update,after update) 
{
    string ConcatenatedResourceRoutingFields;//Stores the Concatenated Geo+Region+Territory+Type+Subtype+Product+Role of the New RR
    list<RR_PS_Original_Mapping__c> ListRRRoutinglogic = new List<RR_PS_Original_Mapping__c>(); //Stores the RR Logic conditions stored in RR PS Original Mapping
    Map<Id,pse__Resource_Request__c> RROldMap = new Map<Id,pse__Resource_Request__c>();
    list<pse__Resource_Request__c> RROlaList = new list<pse__Resource_Request__c>();
    list<pse__Resource_Request__c> RROlaList2Stop = new list<pse__Resource_Request__c>();
    if(Trigger.isBefore)
        {
            //try
            //{
                if(Trigger.isUpdate)
                {
                  for(pse__Resource_Request__c rr1: trigger.new)
                  {
                      if(rr1.pse__Status__c == 'Ready to Staff' && trigger.oldMap.get(rr1.Id).pse__Status__c != 'Ready to Staff')
                      {
                          RROlaList.add(rr1);
                      }
                      else if(rr1.pse__Status__c != 'Ready to Staff' && trigger.oldMap.get(rr1.Id).pse__Status__c == 'Ready to Staff')
                      {
                          RROlaList2Stop.add(rr1);
                      }
                  }
                    if(RROlaList.size()!=0)
                    {
                        PSA_RR_Actions.StartTimer(RROlaList);
                    }
                    if(RROlaList2Stop.size()!=0)
                    {
                    PSA_RR_Actions.StopTimer(RROlaList2Stop);
                    }
                }
                else if(Trigger.isInsert)
                {
                  PSA_RR_Actions.StartTimer(trigger.new);   
                }
                
            //}
            //catch(exception e)
            //{
                
            //}
            try
            {
                if(Trigger.isUpdate)
                {
                 RROldMap  = Trigger.oldMap;
                }
                ListRRRoutinglogic = [Select Concatenated_Condition__c,Criteria_Order__c,Receiving_PS_Group__c from RR_PS_Original_Mapping__c order by Criteria_Order__c];
               
            
               for (pse__Resource_Request__c RRNew : Trigger.New)
                {
                  
                    ConcatenatedResourceRoutingFields = RRNew.Account_Geography__c + ',' +RRNew.Account_Division__c + ',' + RRNew.Account_Territory__c + ',' +  RRNew.pse__Request_Priority__c + ',' + RRNew.Resource_Request_Sub_Type__c + ',' + RRNew.Product__c + ',' + RRNew.pse__Resource_Role__c;
                    String newRecordRRConditionString = ConcatenatedResourceRoutingFields.replaceAll('NULL','*');
                    //MapConcatenatedResourceRoutingFields.put(RRNew,ConcatenatedResourceRoutingFields);              
                  
                    // String newRecordRRConditionString = MapConcatenatedResourceRoutingFields.get(RRNew);
                    //This is to specify the conditions in which Routing should trigger
                        if(Trigger.isInsert || (Trigger.isUpdate && RRNew.pse__Status__c == 'Ready to Staff' && (((RRNew.pse__Status__c == 'Ready to Staff') && (RROldMap.get(RRNew.Id).pse__Status__c != 'Ready to Staff')) || (RROldMap.get(RRNew.Id).pse__Request_Priority__c != RRNew.pse__Request_Priority__c) || (RROldMap.get(RRNew.Id).Resource_Request_Sub_Type__c != RRNew.Resource_Request_Sub_Type__c) || (RROldMap.get(RRNew.Id).Product__c != RRNew.Product__c) || (RROldMap.get(RRNew.Id).pse__Resource_Role__c != RRNew.pse__Resource_Role__c))))
                    {
                        //This is to specify the conditions in which Routing should trigger
                        for(RR_PS_Original_Mapping__c RRMappingMatrix :ListRRRoutinglogic )
                        {  
                              Integer i=0;
                              Boolean Match = True;
                              List<String> FieldstobecheckedGetField= newRecordRRConditionString.split(',',0); // Separate all the fields from new RR 
                              List<String> FieldsInRRMapping = RRMappingMatrix.Concatenated_Condition__c.split(',',0); // Separate all the fields from the RR PS Original Mapping Condition
                              while(i<FieldsInRRMapping.Size() && Match == True)
                              {                       
                                 if(FieldsInRRMapping[i].containsIgnoreCase(FieldstobecheckedGetField[i]) || FieldsInRRMapping[i] == '*')
                                {
                                  Match = True;
                                  i++;
                                  
                                }
                                else
                                {
                                  Match = False;
                                }
                              }
                              if(Match) // Route the RR to corresponding PS Group
                              {
                                 RRNew.Receiving_PS_Group__c = RRMappingMatrix.Receiving_PS_Group__c;
                                 break;
                              }
                              
                              
                              
                              
                        }
                        
                    }  //else no need to route to any group 
                }
                
                
            }
            catch(exception e)
            {
            //do nothing and allow creation of RR without routing
            }
        
        }
        //Changes by Sharath for FFPSA-607: Removing the insert statements from the for loop
        if(trigger.isBefore)
        {
            if(trigger.isUpdate)
            {                
                pse__Schedule__c schd;
                pse__Assignment__c Ass1;
                pse__Schedule__c scheduleLookUp;
                pse__Assignment__c assignmentLookUp;
                List<pse__Schedule__c> schedulesToInsert = new List<pse__Schedule__c>();
                List<pse__Assignment__c> assignmentsToInsert = new List<pse__Assignment__c>();
                Set<Id> resourceRequestIds = new Set<Id> ();

               for(pse__Resource_Request__c RRNew1 : Trigger.New)
               {
                   if(Trigger.oldMap.get(RRNew1.Id).pse__Status__c != 'Assigned' && RRNew1.pse__Status__c == 'Assigned' && RRNew1.pse__Staffer_Resource__c!= NULL && RRNew1.pse__Assignment__c == NULL)
                   {
                       schd = new pse__Schedule__c();
                       schd.pse__End_Date__c = RRNew1.pse__End_Date__c;
                       schd.pse__Scheduled_Hours__c = RRNew1.pse__SOW_Hours__c;
                       schd.pse__Start_Date__c = RRNew1.pse__Start_Date__c;
                       //insert schd;

                       schd.External_Look__c = String.valueOf(RRNew1.Id) + String.valueOf(RRNew1.pse__Project__c) + String.valueOf(RRNew1.pse__Staffer_Resource__c) + String.valueOf(system.now());
                       schedulesToInsert.add(schd);

                        //Create another schedule record and set the external id of this record to the external id of the above created record.
                        scheduleLookUp = new pse__Schedule__c();
                        scheduleLookUp.External_Look__c = schd.External_Look__c;
                       
                       Ass1 = new pse__Assignment__c();
                       Ass1.pse__Project__c = RRNew1.pse__Project__c;
                       //Ass1.pse__Schedule__c = schd.Id;
                       Ass1.pse__Schedule__r = scheduleLookUp;
                       //Ass1.pse__End_Date__c = RRNew1.pse__End_Date__c;
                       //Ass1.pse__Start_Date__c = RRNew1.pse__Start_Date__c;
                       Ass1.pse__Resource__c = RRNew1.pse__Staffer_Resource__c;
                       Ass1.pse__Bill_Rate__c = 1;
                       
                       String externalIdString = String.valueOf(RRNew1.Id) + String.valueOf(RRNew1.pse__Project__c) + String.valueOf(RRNew1.pse__Staffer_Resource__c) + String.valueOf(system.now());
                       externalIdString = externalIdString.length() > 80 ? externalIdString.substring(0,80) : externalIdString;
                       Ass1.External_Id__c = externalIdString;
                       assignmentsToInsert.add(Ass1);
                       //insert Ass1;
                       
                      assignmentLookUp = new pse__Assignment__c();
                      assignmentLookUp.External_Id__c = Ass1.External_Id__c;

                      resourceRequestIds.add(RRNew1.id);
                      //RRNew1.pse__Assignment__r = assignmentLookUp;
                  }
              }
              if(schedulesToInsert != null && !schedulesToInsert.isEmpty())
              {
                  insert schedulesToInsert;
                  insert assignmentsToInsert;
              }
               for(Integer i = 0; i < Trigger.new.size();i++)
               {
                   pse__Resource_Request__c newRR =  Trigger.new.get(i);
                   if(resourceRequestIds.contains(newRR.id))
                   {
                      newRR.pse__Assignment__c = assignmentsToInsert.get(i).id;
                   }
               }   

          }    
    
      }
    
}