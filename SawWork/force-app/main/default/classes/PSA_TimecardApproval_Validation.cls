/* Modified by janantha on 18/03/2015 for introducing an intermediate approval status */
// Modified by  - Sujay 26th Mar 18  - Resaon : throw a validation on Approver approving his own Timecard. CR : FFPSA-480
// Sujay :  19.6 added a filter on picking the Milestones tagged to Investment Work Security projects                  
public class PSA_TimecardApproval_Validation
{
    public static boolean isRecursive = false;
    public static boolean timeHourRecur = false;

    //public void milestonePlannedHoursCheck (List<pse__Timecard_Header__c> triggerNew , Map<Id,pse__Timecard_Header__c> triggerOld, Boolean isInsert)
    //{
    //    List<Id> milestoneIds = new List<Id>();
    //    Map<Id, pse__Milestone__c> idToMilestone = new Map<Id, pse__Milestone__c>();
    //    Map<Id, Decimal> idToHours = new Map<Id, Decimal>();
    //    Map<Date, Decimal > dateToHours = new Map<Date, Decimal>();
    //    for(pse__Timecard_Header__c tc: triggerNew)
    //    {
    //        if((!isInsert && triggerOld.get(tc.Id).pse__Status__c == 'Saved' && tc.pse__Status__c == 'Submitted') || (isInsert && tc.pse__Status__c == 'Submitted'))
    //        {
    //            milestoneIds.add(tc.pse__Milestone__c);                
    //        }
    //    }
    //    if(!milestoneIds.isEmpty())
    //    {                        
    //        idToMilestone = new Map<Id, pse__Milestone__c>([select id,pse__Planned_Hours__c, Start_Date__c, pse__Target_Date__c from pse__Milestone__c where id in :milestoneIds and pse__Project__r.Project_Sub_Type__c = 'Investment Work' and pse__Project__r.pse__Project_Type__c = 'Internal' and Investment_Work__c != null]);
    //        if(idToMilestone != null && !idToMilestone.isEmpty())
    //        {
    //            for (AggregateResult timecards :[select pse__Milestone__c, sum(pse__Total_Hours__c) totalHours from pse__Timecard_Header__c where pse__Status__c in ('Approved', 'Submitted', 'Approver Level 1') and pse__Milestone__c in :milestoneIds and id not in : triggerOld.keySet() group by pse__Milestone__c])
    //            {
    //                if(timecards.get('totalHours') != null)
    //                {
    //                    idToHours.put((Id)timecards.get('pse__Milestone__c'),(Decimal)timecards.get('totalHours'));    
    //                } 
    //            }
    //            for(Id milestoneId: idToMilestone.keySet())
    //            {
    //                if(!idToHours.containsKey(milestoneId))
    //                {
    //                    idToHours.put(milestoneId,0.0);   
    //                }
    //            }
    //            if(!idToHours.isEmpty())
    //            {
    //                pse__Milestone__c milestoneRecord;
    //                for(pse__Timecard_Header__c tc: triggerNew)
    //                {                        
    //                    if(idToHours.containsKey(tc.pse__Milestone__c))
    //                    {
    //                        milestoneRecord = idToMilestone.get(tc.pse__Milestone__c);
    //                        dateToHours = new Map<Date, Decimal>();
    //                        for(Integer i = 0; i< 6; i++)
    //                        {
    //                            date currentDate = tc.pse__Start_Date__c.adddays(i);
    //                            String currentField = 'pse__' + ((datetime)currentDate).format('EEEE') + '_Hours__c';
    //                            decimal currentHours = (Decimal)tc.get(currentField);
    //                            if(currentHours != 0 && (currentDate > milestoneRecord.pse__Target_Date__c || currentDate < milestoneRecord.Start_Date__c))
    //                            {
    //                                tc.addError('Timecard cannot be Submitted as Hours are not within the Milestone dates');
    //                            }
    //                        }
                            
    //                        if((idToHours.get(tc.pse__Milestone__c) + tc.pse__Total_Hours__c) > milestoneRecord.pse__Planned_Hours__c)  
    //                        {
    //                            tc.addError('Timecard cannot be Submitted as Milestone Planned Hours have been met');
    //                        }
    //                    }
    //                }

    //            }

    //        }            
        

    //    }
    //}

    public void milestonePlannedHoursCheck (List<pse__Timecard_Header__c> triggerNew , Map<Id,pse__Timecard_Header__c> triggerOld, Boolean isInsert)
    {
        List<Id> milestoneIds = new List<Id>();
        Map<Id, pse__Milestone__c> idToMilestone = new Map<Id, pse__Milestone__c>();
        Map<Id, Decimal> idToHours = new Map<Id, Decimal>();
        //19.6 Sujay : To keep track of IW billable Milestone Billable Hours Submitted
        Map<Id, Decimal> idToHoursBillable = new Map<Id, Decimal>();
        Map<Date, Decimal > dateToHours = new Map<Date, Decimal>();
        List<Id> milestoneIdtoUpdate = new List<Id>();
        List<pse__Milestone__c> milestonestoUpdate = new List<pse__Milestone__c>();
        for(pse__Timecard_Header__c tc: triggerNew)
        {
            if((!isInsert && triggerOld.get(tc.Id).pse__Status__c == 'Saved' && tc.pse__Status__c == 'Submitted') || (isInsert && tc.pse__Status__c == 'Submitted'))
            {
                milestoneIds.add(tc.pse__Milestone__c);                
            }
        }
        if(!milestoneIds.isEmpty() && !timeHourRecur )
        {   //Sujay :  19.6 added a filter on picking the Milestones tagged to Investment Work Security projects 
            timeHourRecur = true;   // recurcive check for the method milestonePlannedHoursCheck()
            idToMilestone = new Map<Id, pse__Milestone__c>([select id,pse__Planned_Hours__c, Start_Date__c, pse__Target_Date__c,pse__Non_Billable_Hours_Submitted__c, RecordType.Name, pse__Billable_Hours_Submitted__c from pse__Milestone__c where id in :milestoneIds and ((pse__Project__r.Project_Sub_Type__c = 'Investment Work' and pse__Project__r.pse__Project_Type__c = 'Internal') OR RecordType.name = 'Investment Work Billable') and Investment_Work__c != null FOR UPDATE]);

            if(idToMilestone != null && !idToMilestone.isEmpty())
            {         
                System.debug('idToMilestone' + idToMilestone);
                for (Id milestoneID :idToMilestone.keySet())
                    
                {   System.debug('milestoneID' + milestoneID);
                    if(idToMilestone.get(milestoneID).RecordType.name == 'Investment Work Billable'){
                        idToHoursBillable.put(milestoneID,idToMilestone.get(milestoneID).pse__Billable_Hours_Submitted__c);
                    }
                    else{
                        idToHours.put(milestoneID,idToMilestone.get(milestoneID).pse__Non_Billable_Hours_Submitted__c);    
                    }
                    
                }
                if(!idToHours.isEmpty() || !idToHoursBillable.isEmpty())
                {
                    pse__Milestone__c milestoneRecord;
                    Decimal totalHoursSubmitted = 0.0;
                    for(pse__Timecard_Header__c tc: triggerNew)
                    {                
                        if(idToHours.containsKey(tc.pse__Milestone__c) || idToHoursBillable.containsKey(tc.pse__Milestone__c))
                        {
                            milestoneRecord = idToMilestone.get(tc.pse__Milestone__c);
                            dateToHours = new Map<Date, Decimal>();
                            for(Integer i = 0; i< 7; i++)
                            {
                                date currentDate = tc.pse__Start_Date__c.adddays(i);
                                String currentField = 'pse__' + ((datetime)currentDate).format('EEEE') + '_Hours__c';
                                decimal currentHours = (Decimal)tc.get(currentField);
                                if(currentHours != 0 && (currentDate > milestoneRecord.pse__Target_Date__c || currentDate < milestoneRecord.Start_Date__c))
                                {
                                    tc.addError('Timecard cannot be Submitted as Hours are not within the Milestone dates');
                                }
                            }
                            totalHoursSubmitted = idToMilestone.get(tc.pse__Milestone__c).RecordType.Name == 'Investment Work Billable' ? idToHoursBillable.get(tc.pse__Milestone__c) :  idToHours.get(tc.pse__Milestone__c) ;
                            if((totalHoursSubmitted + tc.pse__Total_Hours__c) > milestoneRecord.pse__Planned_Hours__c)  
                            {
                                tc.addError('Timecard cannot be Submitted as Milestone Planned Hours have been met');
                            }
                            else
                            {
                                if(idToMilestone.get(tc.pse__Milestone__c).Recordtype.Name == 'Investment Work Billable'){
                                    idToHoursBillable.put(tc.pse__Milestone__c, (totalHoursSubmitted + tc.pse__Total_Hours__c));
                                    // add timecard hours to Billable hours submitted field , since updating this field from FF package code in future call might be delayed and other transaction accessing this value will not get latest value.
                                    idToMilestone.get(tc.pse__Milestone__c).pse__Billable_Hours_Submitted__c = idToMilestone.get(tc.pse__Milestone__c).pse__Billable_Hours_Submitted__c + tc.pse__Total_Hours__c ;
                                    milestoneIdtoUpdate.add(tc.pse__Milestone__c);
                                }
                                else{
                                    idToHours.put(tc.pse__Milestone__c, (totalHoursSubmitted + tc.pse__Total_Hours__c));
                                    // add timecard hours to Non Billable hours submitted field , since updating this field from FF package code in future call might be delayed and other transaction accessing this value will not get latest value.
                                    idToMilestone.get(tc.pse__Milestone__c).pse__Non_Billable_Hours_Submitted__c = idToMilestone.get(tc.pse__Milestone__c).pse__Non_Billable_Hours_Submitted__c + tc.pse__Total_Hours__c ;
                                    milestoneIdtoUpdate.add(tc.pse__Milestone__c);
                                }
                            }
                        }
                    }

                    // after all the milestone field values are populated, check which milestone needs to be updated from all the queried milestone and update them
                    if( !milestoneIdtoUpdate.isEmpty() )
                    {
                        for (pse__Milestone__c mile : idToMilestone.values() ) {
                            if ( milestoneIdtoUpdate.contains(mile.Id) ) {
                                milestonestoUpdate.add(mile);
                            }
                        }
                        Database.update(milestonestoUpdate, false);
                        System.debug('mile to up :: ' + milestonestoUpdate );
                    }
                }

            }            
        

        }
    }
    /*public static Id getWorkItemId(Id targetObjectId)
    {
        Id retVal = null;

        for(ProcessInstanceWorkitem workItem  : [Select p.Id from ProcessInstanceWorkitem p
            where p.ProcessInstance.TargetObjectId =: targetObjectId])
        {
            retVal  =  workItem.Id;
        }

        return retVal;
    }
    
    @future
    public static void rejectTC(List<Id> idsToReject)
    {
        System.debug('IdsToreject from future '+idsToReject);
        isRecursive = true;
        if(idsToReject.size()>0)
        {
            
            List<pse__Timecard_Header__c> timecards = new List<pse__Timecard_Header__c>();
            timecards = [select Id from pse__Timecard_Header__c where Id in :idsToReject];
            for(pse__Timecard_Header__c tcHeader:timecards)
            {
                Approval.ProcessWorkitemRequest req1 = new Approval.ProcessWorkitemRequest();
                req1.setComments('Reject TC approved by resource.');
                Id workItemId = getWorkItemId(tcHeader.id);             
                req1.setWorkitemId(workItemId);      
                req1.setAction('Reject');
                Approval.ProcessResult result = Approval.process(req1);  
            }
        }
    }
    */

// FFPSA-1719 - Checks if the CLI is missing on the PCLI linked to timecard's project and throws validation error
    public void stoptimecardApproval (List<pse__Timecard_Header__c> triggerNew , Map<Id,pse__Timecard_Header__c> triggerOld){
        map<id,id> timecardsIdsMap = new map<id,id>();
        set<id> projIdset = new set<id>();
        
        for(pse__Timecard_Header__c  tc : triggerNew){
            if((triggerOld.get(tc.Id).pse__Approved__c == FALSE && tc.pse__Approved__c == TRUE) && triggerOld.get(tc.Id).pse__Status__c == 'Submitted'){
                if (tc.pse__Project__c != null){
                    timecardsIdsMap.put(tc.id,tc.pse__Project__c);
                }
            }
        }
       if (!timecardsIdsMap.isEmpty()){
        for(Project_Contract_Line_Item__c pcli : [select Id, Project__c, Project__r.pse__Billing_Type__c, contract_detail__c from Project_Contract_Line_Item__c where Project__c IN: timecardsIdsMap.values() AND (Project__r.pse__Billing_Type__c != 'One-Time: Fixed Price' AND Project__r.pse__Billing_Type__c != 'One-Time: Fixed Price - At Risk')]){
            if (pcli.contract_detail__c == null){
                projIdset.add(pcli.Project__c);
            }
        } 
       }

        for(pse__Timecard_Header__c  tc : triggerNew){
            if (projIdset.contains(timecardsIdsMap.get(tc.id))){
                tc.addError('This timecard cannot be approved due to missing CLI on its project');
            }

        }
    }

    public void validateApproval(List<pse__Timecard_Header__c> triggerNew , Map<Id,pse__Timecard_Header__c> triggerOld)
    {
        Id ownerId;
        Id approverId;
        List<Id> TCIdsToReject = new List<Id>();
                       
        for(pse__Timecard_Header__c tc: triggerNew)
        {
            if((triggerOld.get(tc.Id).pse__Approved__c == FALSE && tc.pse__Approved__c == TRUE) || (triggerOld.get(tc.Id).pse__Status__c == 'Submitted' && tc.pse__Status__c == 'Approver Level 1'))
            {
                ownerId = tc.ownerId;
                approverId = tc.PSA_Actual_Approver__c;
                
                if(ownerId==approverId)
                {
                    //Added chages as per CR : FFPSA-480
                    tc.addError('Timecards cannot be approved by the resource who submitted it.');                    
                }               
            }          
        }
    }   
}