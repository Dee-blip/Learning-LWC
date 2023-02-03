public  class PSA_TimeEntryController
{
    public PSA_TimeEntryController() 
    {
        
    }
    public PSA_TimeEntryController(ApexPages.StandardController sc) 
    {
        
    }

    public class RecordIdtoTimecard
    {
        String recordId;
        pse__Timecard_Header__c timecardRecord;

    }
  
  @RemoteAction 
  public static String getAccess()
  {
    PSA_Mobile_Pages__mdt mDRecord = [select Entry_Page_Batch__c,Error_Message_Timeout__c,Tooltip_Timeout__c from PSA_Mobile_Pages__mdt limit 1];

    PSA_Mobile_Access__c mobileAccess = PSA_Mobile_Access__c.getInstance(UserInfo.getUserId());
    Boolean access;
    if(mobileAccess == null)
    {
      mobileAccess = PSA_Mobile_Access__c.getInstance(UserInfo.getProfileId());      
    }    
    
    if(mobileAccess == null)
    {
      mobileAccess = PSA_Mobile_Access__c.getOrgDefaults();
    }
    access = mobileAccess == null ? false: mobileAccess.Has_Access__c;

    JSONGenerator gen = JSON.createGenerator(true);
            
        gen.writeStartObject();        
            gen.writeObjectField('access', access);        
            gen.writeObjectField('metadata', mDRecord);        
        gen.writeEndObject();

    return encodeBase64(gen.getAsString());
  }

  @RemoteAction
    public static  String getAssignmentsTimecards(String dateValue)
     {  
        String queryString;
        Set<id> projectIds= new Set<id>();

        Map<Id,pse__Proj__c> globalIdToProj = new Map<Id,pse__Proj__c>();
        Map<Id,List<pse__Assignment__c>> projectToAssignments = new Map<Id,List<pse__Assignment__c>>();
        Map<Id,Map<String,String>> projectToMilestones = new Map<Id,Map<String,String>>();
        Map<Id,Map<String,String>> projectToProducts = new Map<Id,Map<String,String>>();

        Map<Id,Integer> projectValidation = new Map<Id,Integer>();


        List<String> dateList = dateValue.split('-');       
        date startDate = Date.newInstance(Integer.valueOf(dateList[0]), Integer.valueOf(dateList[1]), Integer.valueOf(dateList[2])).addDays(-6);
        date endDate = startDate.addDays(6); 
        
        List <Contact> contacts =[select Id from Contact where pse__is_resource__c = true and pse__is_resource_active__c = true and pse__salesforce_user__c = :UserInfo.getUserId() and recordtype.name = 'PSA Resource'];
        if(contacts == null || contacts.size() < 1 )
        {
            return 'Current user has no PSA Contact record';
        }

        for(pse__Assignment__c assignment: [select id, name, pse__Resource__c, pse__project__r.pse__Project_Manager__c,pse__project__r.pse__Daily_Timecard_Notes_Required__c, pse__project__c,pse__project__r.pse__Is_Billable__c,pse__project__r.name,pse__milestone__c,pse__Closed_for_Time_Entry__c,pse__project__r.pse__Project_Manager__r.pse__Salesforce_User__c,pse__Start_Date__c,pse__End_Date__c from pse__Assignment__c 
                       where pse__resource__r.pse__salesforce_user__c = :UserInfo.getUserId() and 
                       pse__Closed_for_Time_Entry__c = false and pse__project__r.pse__Allow_Timecards_Without_Assignment__c = false and pse__project__r.pse__Closed_for_Time_Entry__c = false and pse__Start_Date__c <= :startDate and pse__End_Date__c >= :endDate order by name])
        {
            if(!projectToAssignments.containsKey(assignment.pse__project__c))
            {
                projectToAssignments.put(assignment.pse__project__c,new List<pse__Assignment__c>());    
            }
            projectToAssignments.get(assignment.pse__project__c).add(assignment);
        }

        for (pse__Proj__c project: [select id, name,pse__Start_Date__c,pse__End_Date__c, pse__Daily_Timecard_Notes_Required__c from pse__Proj__c where pse__Allow_Timecards_Without_Assignment__c = true and pse__Closed_for_Time_Entry__c = false and pse__Project_Type__c  = 'Internal' and pse__Start_Date__c <= :startDate and pse__End_Date__c >= :endDate and (pse__Practice__r.Name = 'Corporate' or pse__Region__r.Name = 'Corporate') order by name])
        {
            globalIdToProj.put(project.Id,project);
        }

        for(pse__milestone__c milestone: [select id, name, pse__Closed_for_Time_Entry__c,Billable__c,pse__project__c from  pse__milestone__c
                       where (pse__project__c in :projectToAssignments.keySet() or pse__project__c in :globalIdToProj.keySet()) and 
                       pse__Closed_for_Time_Entry__c = false and pse__project__r.pse__Closed_for_Time_Entry__c = false order by name])
        {
            if(!projectToMilestones.containsKey(milestone.Id))
            {
                projectToMilestones.put(milestone.Id,new Map<String,String>()); 
            }
            projectToMilestones.get(milestone.Id).put('Name',milestone.Name);
            projectToMilestones.get(milestone.Id).put('Project',milestone.pse__project__c);
            projectToMilestones.get(milestone.Id).put('Billable',''+milestone.Billable__c);

            if(!projectValidation.containsKey(milestone.pse__project__c))
            {
                projectValidation.put(milestone.pse__project__c,1); 
            }
        }

        for(pse__Project_Methodology__c methodology: [select id, name,pse__project__c from pse__Project_Methodology__c 
                       where (pse__project__c in :projectToAssignments.keySet() or pse__project__c in :globalIdToProj.keySet()) and 
                       pse__project__r.pse__Closed_for_Time_Entry__c = false order by name])
        {
            if(!projectToProducts.containsKey(methodology.Id))
            {
                projectToProducts.put(methodology.Id,new Map<String,String>()); 
            }
            projectToProducts.get(methodology.Id).put('Name',methodology.name);
            projectToProducts.get(methodology.Id).put('Project',methodology.pse__project__c);

            if(!projectValidation.containsKey(methodology.pse__project__c))
            {
                projectValidation.put(methodology.pse__project__c,1);   
            }
            else
            {
                projectValidation.put(methodology.pse__project__c,2);       
            }

        }


        List<pse__Timecard_Header__c> timecards = new  List<pse__Timecard_Header__c>();
        timecards = [select id,Name,pse__Project_Methodology_Object__c,pse__Project__c,pse__Milestone__c,pse__Approver__c,pse__Status__c,pse__Assignment__c,pse__Billable__c,pse__Timecard_Notes__c,pse__Resource__c,pse__Project__r.pse__Project_manager__c,pse__Project__r.pse__Daily_Timecard_Notes_Required__c,pse__Monday_Hours__c ,pse__Monday_Notes__c,pse__Tuesday_Hours__c, pse__Tuesday_Notes__c,pse__Wednesday_Hours__c,pse__Wednesday_Notes__c,pse__Thursday_Hours__c,pse__Thursday_Notes__c,pse__Friday_Hours__c, pse__Friday_Notes__c,pse__Saturday_Hours__c,pse__Saturday_Notes__c,pse__Sunday_Hours__c, pse__Sunday_Notes__c,pse__Total_Hours__c,pse__Project_Methodology_Object__r.Name,pse__Assignment__r.Name,pse__Milestone__r.Name,pse__Project__r.pse__Allow_Timecards_Without_Assignment__c from pse__Timecard_Header__c where pse__resource__r.pse__salesforce_user__c = :UserInfo.getUserId() and pse__Start_Date__c = :startDate and pse__project__r.pse__Closed_for_Time_Entry__c = false and pse__Milestone__r.pse__Closed_for_Time_Entry__c = false and ((pse__Assignment__c = null and pse__Project__r.pse__Start_Date__c <= :startDate and pse__Project__r.pse__End_Date__c >= :endDate) or (pse__Assignment__c != null and pse__Assignment__r.pse__Closed_for_Time_Entry__c = false and pse__Assignment__r.pse__End_Date__c >= :endDate and pse__Assignment__r.pse__Start_Date__c <= :startDate) ) order by createddate];


                
        
        if(projectToAssignments != null && projectToAssignments.size() > 0 && projectToProducts != null && projectToProducts.size() > 0 && projectToMilestones!= null && projectToMilestones.size() > 0)
        {
                List<pse__Assignment__c> assignmentList  = new List<pse__Assignment__c>();
                for(id projId: projectToAssignments.keySet()) 
                {
                    if(projectValidation.containsKey(projId) && projectValidation.get(projId) == 2)
                    {
                        assignmentList.addAll(projectToAssignments.get(projId));    
                    } 

                }
                for(id projId: globalIdToProj.keySet())
                {
                    if(!(projectValidation.containsKey(projId) && projectValidation.get(projId) == 2))
                    {
                        globalIdToProj.remove(projId);
                    }                   
                }

                JSONGenerator gen = JSON.createGenerator(true);

                    gen.writeStartObject(); 
                        
                        gen.writeFieldName('Objects');
                        
                            gen.writeStartArray();        
                        
                                gen.writeStartObject();        
                                    gen.writeObjectField('assignments', assignmentList);        
                                gen.writeEndObject();                               

                                gen.writeStartObject();        
                                    gen.writeObjectField('milestones', projectToMilestones);        
                                gen.writeEndObject();

                                gen.writeStartObject();        
                                    gen.writeObjectField('products', projectToProducts);        
                                gen.writeEndObject();

                                gen.writeStartObject();        
                                    gen.writeObjectField('timecards', timecards);        
                                gen.writeEndObject();

                                gen.writeStartObject();        
                                    gen.writeObjectField('global', globalIdToProj);        
                                gen.writeEndObject();

                                gen.writeStartObject();        
                                    gen.writeObjectField('contact', contacts[0]);        
                                gen.writeEndObject();

                            gen.writeEndArray();
                        
                    gen.writeEndObject();
                     

                return encodeBase64(gen.getAsString());
                 
                 

        }
            
        //system.assertEquals(1,2);
        return 'No Records';
            
    }

    public static String encodeBase64(String inputString)
    {
        Blob b = blob.valueof(inputString);
        return EncodingUtil.base64Encode(b);

    }
    
    public static String decodeBase64(String inputString)
    {
        Blob b = EncodingUtil.base64Decode(inputString);
        return b.toString();

    }

    @RemoteAction
    public static  String saveSubmitTimecards(String inputJSON,String action,Integer limits,String dateValue)
    {

        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();

        List<RecordIdtoTimecard> records = new List<RecordIdtoTimecard>();
        RecordIdtoTimecard record;
        Map<String, Object> mapJSON = (Map<String, Object>)JSON.deserializeUntyped(decodeBase64(inputJSON));
        Map<String,pse__Timecard_Header__c> timecardsMap = new Map<String,pse__Timecard_Header__c>();
        Map<String,String> idToErrors = new Map<String,String>();
        pse__Timecard_Header__c newTimecard;
        Map<String,Object> mapTimecard;
        List<String> dateList = dateValue.split('-');       
        date startDate = Date.newInstance(Integer.valueOf(dateList[0]), Integer.valueOf(dateList[1]), Integer.valueOf(dateList[2])).addDays(-6);

        Integer currentIndex = 0;
        if(mapJSON != null && mapJSON.size() > 0)
        {
            for(String rowId: mapJSON.keySet())
            {
                currentIndex++;
                if(currentIndex == limits)
                {
                    break;
                }
                newTimecard = new pse__Timecard_Header__c();
                mapTimecard= (Map<String,Object>)mapJSON.get(rowId);
                for(String key : mapTimecard.keySet())
                {
                    newTimecard.put(key,mapTimecard.get(key));
                }

                timecardsMap.put(rowId,newTimecard);
            }   
            
            Map<String,Map<String,String>> rowToRecord = new Map<String,Map<String,String>>();
        
            for(String rowID : timecardsMap.keySet())
            {
                pse__Timecard_Header__c tc = timecardsMap.get(rowID);
                record = new RecordIdtoTimecard();
                record.recordId = rowID;
                if(tc.pse__Status__c != 'Saved')
                {                   

                    tc.id= null;
                    tc.pse__Start_Date__c = startDate;
                    tc.pse__End_Date__c = startDate.addDays(6);
                }
                if(action == 'Save' && tc.pse__Status__c != 'Unsaved' && tc.pse__Status__c != 'Saved' && tc.pse__Status__c != 'Rejected')
                {                   
                    tc.pse__Status__c = 'Saved';
                }
                else if(action == 'Submit')
                {
                    if(!((tc.pse__Monday_Hours__c == 0 || tc.pse__Monday_Hours__c == null) && (tc.pse__Tuesday_Hours__c == 0 || tc.pse__Tuesday_Hours__c == NULL) && (tc.pse__Wednesday_Hours__c == 0 || tc.pse__Wednesday_Hours__c == NULL) && (tc.pse__Thursday_Hours__c == 0 || tc.pse__Thursday_Hours__c == NULL) && (tc.pse__Friday_Hours__c == 0 || tc.pse__Friday_Hours__c == NULL) && (tc.pse__Saturday_Hours__c == 0 || tc.pse__Saturday_Hours__c == NULL) && (tc.pse__Sunday_Hours__c == 0 || tc.pse__Sunday_Hours__c == NULL)))  
                    {
                        
                        tc.pse__Status__c = 'Submitted';
                        //tc.pse__Submitted__c = true;
                    }
                    else
                    {
                        tc.pse__Status__c = 'Saved';
                    }
                }               
                record.timecardRecord = tc;
                records.add(record);        

            }
                        
            List<pse__Timecard_Header__c> tcs = new List<pse__Timecard_Header__c>();
            for (RecordIdtoTimecard r: records)
            {
                tcs.add(r.timecardRecord);
            }

            if(tcs != null && tcs.size() > 0)
            {
                upsertResultRecords = Database.upsert(tcs,false);   
                String errors = '';
                List<Id> successTimecards = new List<Id>();
                for(Integer i =0; i < upsertResultRecords.size() ; i++)
                {
                    Database.UpsertResult sr = upsertResultRecords.get(i);
                    if (!sr.isSuccess()) 
                    {               
                        for(Database.Error err : sr.getErrors()) 
                        {             
                            idToErrors.put(records[i].recordId,err.getStatusCode() + ': ' + err.getMessage());      
                            //errors += err.getStatusCode() + ': ' + err.getMessage() + ' Timecard ID: ' + tcs.get(i).Id ;
                        }
                    }
                    else
                    {
                        successTimecards.add(tcs.get(i).Id);
                    }

                }

                Map<id,pse__Timecard_Header__c> successTimecardsMap = new Map<id,pse__Timecard_Header__c>([Select id, pse__status__c from pse__Timecard_Header__c where id in :successTimecards]);

                for (RecordIdtoTimecard r: records)
                {           
                    if(r.timecardRecord.Id != null && !idToErrors.containsKey(r.recordId))
                    {
                        rowToRecord.put(r.recordId,new Map<String,String>());
                        rowToRecord.get(r.recordId).put('Id',r.timecardRecord.Id);                      
                        rowToRecord.get(r.recordId).put('Status',successTimecardsMap.get(r.timecardRecord.Id).pse__Status__c);

                    }
                }

                
                JSONGenerator gen = JSON.createGenerator(true);
                        
                        gen.writeStartObject();        
                            gen.writeObjectField('timecards', rowToRecord);        
                            gen.writeObjectField('errors', idToErrors);        
                        gen.writeEndObject();
                        
                if(successTimecardsMap != null && !successTimecardsMap.isEmpty())
                {
                    List<Id> tcsIdsHistory = new List<Id>();
                    tcsIdsHistory.addAll(successTimecardsMap.keySet());
                    insertHistoryRecords(tcsIdsHistory,action); 
                }

                return encodeBase64(gen.getAsString());

            }

        }
        

        //system.assertEquals(mapJSON,null);
        return 'error';
        
        
    }   
   
    @RemoteAction
    public static  String recallTimecards(String inputJSON,String comments,Integer limits,String dateValue)
    {

        Map<String, Object> mapJSON = (Map<String, Object>)JSON.deserializeUntyped(decodeBase64(inputJSON));
        List<String> tcIds = new List<String>();
        String errors = '';     
        Map<String,String> recordToRowIds = new Map<String,String>();
        Map<String,String> idToErrors = new Map<String,String>();
        List<Approval.ProcessWorkitemRequest> listReq = new List<Approval.ProcessWorkitemRequest>();
        List<Approval.ProcessResult> result2 = new List<Approval.ProcessResult>();

        List<Id> rejectIds = new List<Id>();
        Integer currentIndex = 0;
        if(mapJSON != null && mapJSON.size() > 0)
        {       
                for(String rowId: mapJSON.keySet())
                {
                    currentIndex++;
                    if(currentIndex == limits)
                    {
                        break;
                    }
                    recordToRowIds.put((String)mapJSON.get(rowId),rowId);
                }   
                
                List<ProcessInstanceWorkitem>  workitems = new List<ProcessInstanceWorkitem>([select Id,ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.Status = 'Pending' and ProcessInstance.TargetObjectId = :recordToRowIds.keySet() limit :limits]);
               Approval.ProcessWorkitemRequest req2;
                
                for(ProcessInstanceWorkitem piw1:workitems)
                {
                    req2 = new Approval.ProcessWorkitemRequest();
                    if (comments != null )
                    {
                        req2.setComments(comments);                
                    }
                    req2.setAction('Removed');
                    req2.setWorkitemId(piw1.Id);
                    listReq.add(req2);
                
                }
                try
                {
                       //approving or rejecting the TCs. the results are stored in result2   
                      result2 =  Approval.process(listReq,False);
                }
                catch (Exception e)
                {
                    return e.getMessage();

                }
                if(result2!=NULL)
                {
                    //Iterating over the result list, for every failure, create a table row in the ErrorMessages variable
                    for (Integer index = 0;index < result2.size(); index++)
                    {
                        Approval.ProcessResult result1 = result2.get(index);
                        if(!result1.isSuccess())
                        {
                            idToErrors.put(recordToRowIds.get(workitems[index].ProcessInstance.TargetObjectId),result1.getErrors()[0].getMessage() );
                            //errors += 'Error: '+ result1.getErrors()[0].getMessage() ;
                        }
                        if(result1.isSuccess())
                        {
                            tcIds.add(recordToRowIds.get(workitems[index].ProcessInstance.TargetObjectId));
                            rejectIds.add(workitems[index].ProcessInstance.TargetObjectId);
                        }
                    }
                }           
                JSONGenerator gen = JSON.createGenerator(true);
                    
                    gen.writeStartObject();        
                        gen.writeObjectField('timecards', tcIds);        
                        gen.writeObjectField('errors', idToErrors);        
                    gen.writeEndObject();
                            
                    
                    if(rejectIds != null && !rejectIds.isEmpty())
                    {
                        insertHistoryRecords(rejectIds,'Recall');       
                    }                   
                    return encodeBase64(gen.getAsString());


        }



        return 'error';
        
        
    }   
    @RemoteAction
    public static  String deleteTimecards(String inputJSON,String action,Integer limits,String dateValue)
    {

        Map<String, Object> mapJSON = (Map<String, Object>)JSON.deserializeUntyped(decodeBase64(inputJSON));
        Map<String,pse__Timecard_Header__c> timecardsMap = new Map<String,pse__Timecard_Header__c>();       
        List<String> tcIds = new List<String>();
        Map<String,String> idToErrors = new Map<String,String>();
        String errors = '';     
        Map<String,String> recordToRowIds = new Map<String,String>();
        List<Id> deleteIds = new List<Id>();

        Integer currentIndex = 0;
        if(mapJSON != null && mapJSON.size() > 0)
        {
            for(String rowId: mapJSON.keySet())
            {
                currentIndex++;
                if(currentIndex == limits)
                {
                    break;
                }
                //tcIds.add(mapJSON.get(rowId));
                recordToRowIds.put((String)mapJSON.get(rowId),rowId);
            }   
            

            List<pse__Timecard_Header__c> deleteTCs = [select id from pse__Timecard_Header__c where id in :recordToRowIds.keySet() limit :limits];
            Database.DeleteResult[] drList = Database.delete(deleteTCs, false);

            Database.DeleteResult dr;
            for(Integer index = 0; index < drList.size(); index++) 
            {
                    dr = drList[index];
                    if (dr.isSuccess()) 
                    {
                        tcIds.add(recordToRowIds.get(dr.getId()));
                        deleteIds.add(dr.getId());
                    }
                    else
                    {                           
                            errors = '';
                            for(Database.Error err : dr.getErrors()) 
                            {
                                errors += err.getStatusCode() + ': ' + err.getMessage();
                            }
                            idToErrors.put(deleteTCs[index].id,errors);
                    }               
            }
            JSONGenerator gen = JSON.createGenerator(true);
                
                gen.writeStartObject();        
                    gen.writeObjectField('timecards', tcIds);        
                    gen.writeObjectField('errors', idToErrors);        
                gen.writeEndObject();
                        
                
                if(deleteIds != null && !deleteIds.isEmpty())
                {
                    insertHistoryRecords(deleteIds,'Delete');       
                }                   

                return encodeBase64(gen.getAsString());


        }
        

        return 'error';
        
        
    }


  @RemoteAction
    public static  String getTimecardsPreviousWeek(String dateValue,Boolean milestone, Boolean product, Boolean hours, Boolean notes)
     {  

        List<String> dateList = dateValue.split('-');  
        Date today =  Date.newInstance(Integer.valueOf(dateList[0]), Integer.valueOf(dateList[1]), Integer.valueOf(dateList[2])).addDays(-6);   
        Date previousWeek = today.addDays(-7);
        Date endDate = previousWeek.addDays(6);

        //system.assertEquals(1,2);
        List<pse__Timecard_Header__c> timecards = new  List<pse__Timecard_Header__c>();
        String query = 'select id,Name,pse__Project__c,pse__Approver__c,pse__Status__c,pse__Assignment__c,pse__Billable__c,pse__Resource__c,pse__Project__r.pse__Project_manager__c,pse__Project__r.pse__Daily_Timecard_Notes_Required__c';

        String userid = UserInfo.getUserId();
        if(milestone)
        {
            query += ',pse__Milestone__c';
        }
        if(product)
        {
            query += ',pse__Project_Methodology_Object__c'; 
        }
        if(hours)
        {
            query += ',pse__Monday_Hours__c,pse__Tuesday_Hours__c,pse__Wednesday_Hours__c,pse__Thursday_Hours__c,pse__Friday_Hours__c,pse__Saturday_Hours__c,pse__Sunday_Hours__c';     
        }
        if(notes)
        {
            query += ',pse__Timecard_Notes__c,pse__Monday_Notes__c, pse__Tuesday_Notes__c,pse__Wednesday_Notes__c,pse__Thursday_Notes__c, pse__Friday_Notes__c,pse__Saturday_Notes__c, pse__Sunday_Notes__c';
        }

        query += ' from pse__Timecard_Header__c where pse__resource__r.pse__salesforce_user__c = :userid and pse__Start_Date__c = :previousWeek and pse__project__r.pse__Closed_for_Time_Entry__c = false and pse__Milestone__r.pse__Closed_for_Time_Entry__c = false and ((pse__Assignment__c = null and  pse__Project__r.pse__End_Date__c >= :endDate and pse__Project__r.pse__Start_date__c <= :previousWeek) or (pse__Assignment__c != null and pse__Assignment__r.pse__Closed_for_Time_Entry__c = false and pse__Assignment__r.pse__End_Date__c >= :endDate and pse__Assignment__r.pse__Start_date__c <= :previousWeek) ) order by createddate';
        
        timecards = Database.query(query);

                
        
        if(timecards != null && timecards.size() > 0)
        {               
                JSONGenerator gen = JSON.createGenerator(true);

                    gen.writeStartObject(); 
                        
                        gen.writeFieldName('Objects');
                        
                            gen.writeStartArray();        
                        
                                gen.writeStartObject();        
                                    gen.writeObjectField('timecards', timecards);        
                                gen.writeEndObject();

                            gen.writeEndArray();
                        
                    gen.writeEndObject();
                
                return encodeBase64(gen.getAsString());

        }
            
        //system.assertEquals(1,2);
        return 'No Records';
            
    }

    @future
    public static void insertHistoryRecords(List<Id> timecardIds,String action)
    {
        List<Mobile_Timecard_History__c> mobileHistories = new List<Mobile_Timecard_History__c>();
        Mobile_Timecard_History__c mobileHistory;

        if(timecardIds != null && !timecardIds.isEmpty())
        {
            if(action != 'Delete')
            {
              for(Id timecardId: timecardIds)
              {
                mobileHistory = new Mobile_Timecard_History__c();
                mobileHistory.Timecard__c = timecardId;
                mobileHistory.Action__c = action;
                mobileHistories.add(mobileHistory);
              } 

            }
            else
            {
                mobileHistory = new Mobile_Timecard_History__c();
                
                mobileHistory.Action__c = 'Deleted ' + timecardIds.size() + ' Records';
                mobileHistories.add(mobileHistory);

            }

            if(mobileHistories != null && !mobileHistories.isEmpty())
            {
                insert mobileHistories;
            }

        }
    }


}