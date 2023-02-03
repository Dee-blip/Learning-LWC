/***
Author: Jaya
Created Date: 07/09/2015
Description: This class marks the Timedate records that are eligible for billing.
These records are then sent for the Automated billing process. 
Modified by                 Date                        Reason
Sharath                    18 Feb 2016              Modifying the timecard submit validation
sharath                    29 June 2016             Conditional validation on recall
suhas                      03 Aug  2018             Changes for FFPSA-545
Sujay					   01 October 2020 			20.10.2 changes by Sujay to resolve a known bug on net negative scenarios!
*/

public class PSA_TimecardActions {

    public static Boolean isFirstTime = true;
    public PSA_TimecardActions() 
    {
        
    }

    public void stampTDEligibleForBilling(List<pse__Timecard_Header__c> editedTCRecords,Map<Id,pse__Timecard_Header__c> oldTCRecords, Boolean isUpdate)
    {
        List<String> lstEligibleTCIds = new List<String>();
        List<pse__Time_Date__c> lstEligibleTDs = new List<pse__Time_Date__c>();
        //Map<String,pse__Time_Date__c> keyTimeDate = new Map<String,pse__Time_Date__c>();
        //20.10.2 Sujay : to store all TDs who have negative hours logged while timecard is travelling from one stage to another
        Map<String,List<pse__Time_Date__c>> keyToTimeDates = new Map<String,List<pse__Time_Date__c>>();
        //Changes by sharath: Changing from list to set so that the items can be removed
        //List<String> lstNegativeTDIds = new List<String>();
        Set<String> lstNegativeTDIds = new Set<String>();
        //End of changes by sharath
        List<String> lstApprovedTCIds = new List<String>();
        List<pse__Time_Date__c> lstApprovedTDs = new List<pse__Time_Date__c>();
        List<pse__Time_Date__c> lstApprovedTimeDateUpdates = new List<pse__Time_Date__c>();
        List<pse__Time_Date__c> lstNetNegativeTimeDates = new List<pse__Time_Date__c>();
        List<AggregateResult> positiveTimeDates1 = new List<AggregateResult>();
        List<AggregateResult> netNegativeApprovals = new List<AggregateResult>();
        
        /* For handling the case where recalled Timecards result in a Net Negative hours being in the system */
        List<String> lstRecalledTCIds = new List<String>();
        List<pse__Time_Date__c> lstRecalledTimeDates = new List<pse__Time_Date__c>();
        Map<String,pse__Time_Date__c> recalledKeyTimeDate = new Map<String,pse__Time_Date__c>();
        List<String> recalledPositiveHours = new List<String>();
        List<pse__Time_Date__c> lstRecalledNetNegativeTimeDates = new List<pse__Time_Date__c>();
        
        /* For handling the case where rejected Timecards result in a Net Negative hours being in the system. */
        List<String> lstRejectedTCIds = new List<String>();
        List<pse__Time_Date__c> lstRejectedTimeDates = new List<pse__Time_Date__c>();
        Map<String,pse__Time_Date__c> rejectedKeyTimeDate = new Map<String,pse__Time_Date__c>();
        List<String> rejectedPositiveHours = new List<String>();
        List<pse__Time_Date__c> lstRejectedNetNegativeTimeDates = new List<pse__Time_Date__c>();

        List<pse__Time_Date__c> lstApprovedTimeDates = new List<pse__Time_Date__c>();
        //20.10.2 Sujay : to store all TDs who have negative hours logged while timecard is Approved from submitted stage
        Map<String,List<pse__Time_Date__c>> approvedKeyTimeDates = new Map<String,List<pse__Time_Date__c>>();
        //Map<String,pse__Time_Date__c> approvedKeyTimeDate = new Map<String,pse__Time_Date__c>();
        Set<String> approvedNegativeHours = new Set<String>();
        List<pse__Time_Date__c> lstApprovedNetNegativeTimeDates = new List<pse__Time_Date__c>();
        List<Id> lstApprovedNetNegIds = new List<Id>();
        List<String> lstKeys = new List<String>();
        Set<ID> setTimecardIds = new Set<ID>();
        
        //Changes by Sharath for the v15 upgrade: conditional validation on recall
       // PSA_Settings__c validateOnRecallSetting = PSA_Settings__c.getInstance('Validation On Timecard Recall Active');
        //String validateOnRecall = validateOnRecallSetting.Value__c.trim();
        List<PSA_Common_Setting__mdt> validateOnRecallSetting = new List<PSA_Common_Setting__mdt>([select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'Validation On Timecard Recall Active']);     
        String validateOnRecall = validateOnRecallSetting.get(0).Value_Long__c.trim();
        System.debug('validateOnRecall : '+ validateOnRecall);
        //End of changes by Sharath

        /* Creates a list of all eligible Timecard record id's that are eligible for billing */
        for(pse__Timecard_Header__c TCHeader:editedTCRecords)
        {
            //System.debug('***Old Status of the TC during update: '+oldTCRecords.get(TCHeader.Id).pse__Status__c);
            //System.debug('***New Status of the TC during update: '+TCHeader.pse__Status__c);
            
            /* If the trigger is fired due to an update operation */
            /* Recall Action - the status goes from Submitted to Saved. 
               Reject Action - the status goes from Submitted to Rejected.
               Save Action - If a Timecard is Saved for the first time, the status goes from null to Saved.
               Submit Action - If a Timecard is Saved first and then submitted, the status goes from Saved to Submitted.
               Approve Action - If a Timecard is Approved then the status goes from Submitted to Approved.
               Directly Submit a Timecard and then Recall - Status goes from Submitted to Saved.
               Save with Net Negative hour and then Submit the Timecard which results in a error - the status goes remains Saved.
               Diectly Submit a Net Negative Timecard without Saving - the record is not saved in the DB at all so the record itself does not exist.
               
            */
            if(isUpdate == true)
            {
                /* Include in financials is not true for Submitted Time cards. It gets set only for Approved TC's. 
                Hence that check is removed from the below if condn. */
                
                if(TCHeader.pse__Billable__c == true && TCHeader.pse__Status__c == 'Submitted' && oldTCRecords.get(TCHeader.Id).pse__Status__c != 'Submitted')
                {
                    lstEligibleTCIds.add(TCHeader.Id);
                    System.debug('Edited TCs where status is submitted: '+lstEligibleTCIds);
                }
                
                /*If the update operation was triggered due to the TC getting Approved.*/
                if(TCHeader.pse__Billable__c == true && TCHeader.pse__Include_In_Financials__c == true && TCHeader.pse__Approved__c == true && oldTCRecords.get(TCHeader.Id).pse__Approved__c == false)
                {
                    lstApprovedTCIds.add(TCHeader.Id);
                    System.debug('Approved TCs: '+lstApprovedTCIds);
                }
                
                /*Recalled*/
                if(TCHeader.pse__Billable__c == true && TCHeader.pse__Status__c == 'Saved' && oldTCRecords.get(TCHeader.Id).pse__Status__c == 'Submitted')
                {
                    lstRecalledTCIds.add(TCHeader.Id);
                    System.debug('Recalled TCs: '+lstRecalledTCIds);
                }
                
                /*Rejected*/
                if(TCHeader.pse__Billable__c == true && TCHeader.pse__Status__c == 'Rejected' && oldTCRecords.get(TCHeader.Id).pse__Status__c == 'Submitted')
                {
                    lstRejectedTCIds.add(TCHeader.Id);
                    System.debug('Rejected TCs: '+lstRejectedTCIds);
                }
            }
            /* Else the trigger is fired due to an insert operation */
            else
            {
                if(TCHeader.pse__Billable__c == true && TCHeader.pse__Status__c == 'Submitted')
                {
                    lstEligibleTCIds.add(TCHeader.Id);
                    System.debug('lstEligibleTCIds from else block '+lstEligibleTCIds);
                }               
            }
        }
        
        System.debug('Eligible TC IDS: '+lstEligibleTCIds);
        
        /* Set the eligible for billing flag for the approved Time cards */
        if(lstApprovedTCIds.size() > 0)
        {
            lstApprovedTimeDates = [select Id, pse__Hours__c, Key__c, pse__Timecard__c, pse__Timecard__r.Name,pse__Timecard__r.Id, Eligible_For_Billing__c from pse__Time_Date__c where pse__Timecard__c in :lstApprovedTCIds and pse__Hours__c != 0 and pse__Timecard__r.pse__Milestone__r.Billable__c = true and Sent_For_Billing__c = false];

            for(pse__Time_Date__c approvedTimeDate:lstApprovedTimeDates)
            {
                if(approvedTimeDate.pse__Hours__c < 0)
                {
                    //approvedKeyTimeDate.put(approvedTimeDate.Key__c,approvedTimeDate); 
                    //approvedNegativeHours.add(approvedTimeDate.Id);
                    if(!approvedKeyTimeDates.containsKey(approvedTimeDate.Key__c))
                    {
                        approvedKeyTimeDates.put(approvedTimeDate.Key__c,new List<pse__Time_Date__c>());
                        approvedKeyTimeDates.get(approvedTimeDate.Key__c).add(approvedTimeDate);
                    }
                    else
                    {
                        approvedKeyTimeDates.get(approvedTimeDate.Key__c).add(approvedTimeDate);
                    }
                    approvedNegativeHours.add(approvedTimeDate.Id);
                }                           
            }
            //System.debug('approvedKeyTimeDate...'+approvedKeyTimeDate);
            System.debug('approvedKeyTimeDates...'+approvedKeyTimeDates);
            System.debug('approvedNegativeHours...'+approvedNegativeHours);

            for(AggregateResult approvedTimeDates:[select Key__c, sum(pse__Hours__c) totalHrs from pse__Time_Date__c where Key__c in :approvedKeyTimeDates.keyset() and Id not in :approvedNegativeHours and pse__Timecard__r.pse__Billable__c = true and pse__Timecard__r.pse__Milestone__r.Billable__c = true and FF_Rejected__c = false and pse__Timecard__r.pse__Status__c = 'Approved' group by Key__c])
            {
                System.debug('approvedTimeDates :: '+ approvedTimeDates);
                //pse__Time_Date__c timeDate = keyTimeDate.get((String)positiveTimeDates.get('Key__c'));
                //to store each key and its negative time Dates
                List<pse__Time_Date__c> timeDates = approvedKeyTimeDates.get((String)approvedTimeDates.get('Key__c'));
                Decimal totalNegtiveHoursLogged = 0.0;
                Boolean flag = false;
                List<String> tDatesProcessed = new List<String>();
                
                //pse__Time_Date__c approvedTimeDate = approvedKeyTimeDate.get((String)approvedTimeDates.get('Key__c'));
                
                //20.10.2 iterage over each store negative sum for each key
                for(pse__Time_Date__c eachTdfromKey : timeDates)
                {
                    totalNegtiveHoursLogged += eachTdfromKey.pse__Hours__c;
                    tDatesProcessed.add(eachTdfromKey.Id);
                }
                
                if((Decimal)(approvedTimeDates.get('totalHrs')) + totalNegtiveHoursLogged < 0)
                {
                    //20.10.2 iterage over each and set the Net Negative flag for each one of them
                    flag = true;
                    for(pse__Time_Date__c approvedTimeDate : timeDates)
                    {
                        approvedTimeDate.Net_Negative__c = true;   
                        //lstApprovedNetNegIds no need to store this timedate Ids as its already considered in approvedNegativeHours
                        //lstApprovedNetNegIds.add(approvedTimeDate.Id);          
                        lstApprovedNetNegativeTimeDates.add(approvedTimeDate);
                    } 
                } 
                
                System.debug('before removal lstNegativeTDIds...' + approvedNegativeHours);
                if(!flag)
                {
                    approvedNegativeHours.removeAll(tDatesProcessed);   
                }
                System.debug('after removal lstNegativeTDIds...' + approvedNegativeHours);
            }
            System.debug('lstApprovedNetNegativeTimeDates...'+lstApprovedNetNegativeTimeDates);
            System.debug('***lstKeys'+lstKeys);
            
        }

        System.debug('approvedNegativeHours after removal'+approvedNegativeHours);

        if(approvedNegativeHours != null && approvedNegativeHours.size() > 0)
        {
            //netNegativeApprovals = [select Key__c, sum(pse__Hours__c) totalHrs from pse__Time_Date__c where Key__c in :approvedKeyTimeDate.keyset() and Key__c not in :lstKeys and Id not in :approvedNegativeHours and pse__Timecard__r.pse__Billable__c = true and pse__Timecard__r.pse__Milestone__r.Billable__c = true and FF_Rejected__c = false and pse__Timecard__r.pse__Status__c = 'Approved' group by Key__c];
            //System.debug('netNegativeApprovals...'+netNegativeApprovals);
            //if(netNegativeApprovals == null || netNegativeApprovals.size() == 0)
            //{
                for(pse__Time_Date__c timeDate:[select Id, Net_Negative__c,pse__Timecard__c from pse__Time_Date__c where Id in :approvedNegativeHours])
                {
                    timeDate.Net_Negative__c = true;
                    lstApprovedNetNegIds.add(timeDate.Id);
                    lstApprovedNetNegativeTimeDates.add(timeDate);
                }
            //}
        }
        System.debug('lstApprovedNetNegativeTimeDates*'+lstApprovedNetNegativeTimeDates);
        lstApprovedTDs = [select Id, Eligible_For_Billing__c from pse__Time_Date__c where pse__Timecard__c in :lstApprovedTCIds and Id not in :lstApprovedNetNegIds and pse__Hours__c != 0 and pse__Timecard__r.pse__Milestone__r.Billable__c = true and Sent_For_Billing__c = false and FF_Rejected__c = false];

        List<Id> overageTimeDateIds = new List<Id>();
        for(pse__Time_Date__c approvedTimeDate:lstApprovedTDs)
        {            
            approvedTimeDate.Eligible_For_Billing__c = true;
            lstApprovedTimeDateUpdates.add(approvedTimeDate);
            overageTimeDateIds.add(approvedTimeDate.Id);
        }

        if(lstApprovedTimeDateUpdates.size() > 0)
        {
            update lstApprovedTimeDateUpdates;
            //This is the Trigger POint
            //system.assertEquals(1,2);
            if(!PSA_OverageController.checkRecursion)
            {
                PSA_OverageController.checkRecursion =  true;
    
                PSA_OverageController.checkOverage(overageTimeDateIds);
				                
            }
        }
        
        /* Handle Recalled */
        if(lstRecalledTCIds.size() > 0)
        {
            lstRecalledTimeDates = [select Id, pse__Hours__c, Key__c, pse__Timecard__c, pse__Timecard__r.Name, Eligible_For_Billing__c from pse__Time_Date__c where pse__Timecard__c in :lstRecalledTCIds and pse__Hours__c != 0 and pse__Timecard__r.pse__Milestone__r.Billable__c = true and Sent_For_Billing__c = false];
            System.debug('lstRecalledTimeDates '+lstRecalledTimeDates);
            for(pse__Time_Date__c recalledTimeDate:lstRecalledTimeDates)
            {
                if(recalledTimeDate.pse__Hours__c > 0)
                {
                    recalledKeyTimeDate.put(recalledTimeDate.Key__c,recalledTimeDate); 
                    recalledPositiveHours.add(recalledTimeDate.Id);
                }
                                  
            }
            System.debug('lstRecalledTDIds...'+recalledKeyTimeDate);
            
            for(AggregateResult positiveTimeDates:[select Key__c, sum(pse__Hours__c) totalHrs from pse__Time_Date__c where Key__c in :recalledKeyTimeDate.keyset() and Id not in :recalledPositiveHours and pse__Timecard__r.pse__Billable__c = true and pse__Timecard__r.pse__Milestone__r.Billable__c = true and FF_Rejected__c = false and pse__Timecard__r.pse__Status__c != 'Saved' and pse__Timecard__r.pse__Status__c != 'Rejected' group by Key__c])
            {
                pse__Time_Date__c recalledTimeDate = recalledKeyTimeDate.get((String)positiveTimeDates.get('Key__c'));
                
                if((Decimal)(positiveTimeDates.get('totalHrs')) < 0)
                {
                    recalledTimeDate.Net_Negative__c = true;                    
                    lstRecalledNetNegativeTimeDates.add(recalledTimeDate);
                } 
            }
        }
        
        /*Handle Rejected */
        if(lstRejectedTCIds.size() > 0)
        {
            lstRejectedTimeDates = [select Id, pse__Hours__c, Key__c, pse__Timecard__c, pse__Timecard__r.Name, pse__Timecard__r.Id from pse__Time_Date__c where pse__Timecard__c in :lstRejectedTCIds and pse__Hours__c != 0 and pse__Timecard__r.pse__Milestone__r.Billable__c = true and Sent_For_Billing__c = false];
            System.debug('lstRejectedTimeDates '+lstRejectedTimeDates);
            for(pse__Time_Date__c rejectedTimeDate:lstRejectedTimeDates)
            {
                if(rejectedTimeDate.pse__Hours__c > 0)
                {
                    rejectedKeyTimeDate.put(rejectedTimeDate.key__c,rejectedTimeDate);
                    rejectedPositiveHours.add(rejectedTimeDate.Id);
                }
            }
            
            System.debug('lstRejectedTDIds...'+rejectedPositiveHours);
            
            for(AggregateResult positiveTimeDates:[select Key__c, sum(pse__Hours__c) totalHrs from pse__Time_Date__c where Key__c in :rejectedKeyTimeDate.keyset() and Id not in :rejectedPositiveHours and pse__Timecard__r.pse__Billable__c = true and pse__Timecard__r.pse__Milestone__r.Billable__c = true and FF_Rejected__c = false and pse__Timecard__r.pse__Status__c != 'Saved' and pse__Timecard__r.pse__Status__c != 'Rejected' group by Key__c])
            {
                pse__Time_Date__c rejectedTimeDate = rejectedKeyTimeDate.get((String)positiveTimeDates.get('Key__c'));
                //System.assertEquals((Decimal)(positiveTimeDates.get('totalHrs')),100);
                if((Decimal)(positiveTimeDates.get('totalHrs')) < 0)
                {
                    rejectedTimeDate.Net_Negative__c = true;                    
                    lstRejectedNetNegativeTimeDates.add(rejectedTimeDate);
                } 
            }
        }
        
        if(lstEligibleTCIds.size() > 0)
        {
            lstEligibleTDs = [select Id, pse__Hours__c, Key__c, pse__Timecard__c, pse__Timecard__r.Name from pse__Time_Date__c where pse__Timecard__c in :lstEligibleTCIds and pse__Hours__c != 0 and pse__Timecard__r.pse__Milestone__r.Billable__c = true and Sent_For_Billing__c = false];
            System.debug('lstEligibleTDs: '+lstEligibleTDs);
            //20.10.2 iterage over each store a Key to a set negative timecards logged in
            for(pse__Time_Date__c eligibleTimeDate:lstEligibleTDs)
            {
                /* If the hours is less than zero set the net negative flag to true. */
                if(eligibleTimeDate.pse__Hours__c < 0)
                {
                    System.debug('eligibleTimeDate :: ' + eligibleTimeDate);
                    //keyTimeDate.put(eligibleTimeDate.Key__c,eligibleTimeDate);
                    if(!keyToTimeDates.containsKey(eligibleTimeDate.Key__c))
                    {
                        keyToTimeDates.put(eligibleTimeDate.Key__c,new List<pse__Time_Date__c>());
                        keyToTimeDates.get(eligibleTimeDate.Key__c).add(eligibleTimeDate);
                    }
                    else
                    {
                        keyToTimeDates.get(eligibleTimeDate.Key__c).add(eligibleTimeDate);
                    }
                    lstNegativeTDIds.add(eligibleTimeDate.Id);
                }
            }
            System.debug('lstNegativeTDIds...'+lstNegativeTDIds);
            //System.debug('keyTimeDate...'+keyTimeDate);
            System.debug('keyToTimeDates...'+keyToTimeDates);
            
            
            /* Query for all the Time Dates which have the same key a the ones with negative hours and check if the total results in a Net Positive. If yes then set the Net Negative flag as false. */
            
            for(AggregateResult positiveTimeDates:[select Key__c, sum(pse__Hours__c) totalHrs from pse__Time_Date__c where Key__c in :keyToTimeDates.keyset() and Id not in :lstNegativeTDIds and pse__Timecard__r.pse__Billable__c = true and pse__Timecard__r.pse__Milestone__r.Billable__c = true and FF_Rejected__c = false and pse__Timecard__r.pse__Status__c != 'Rejected' and pse__Timecard__r.pse__Status__c != 'Saved' group by Key__c])
            {
                System.debug('positiveTimeDates :: '+ positiveTimeDates);
                //pse__Time_Date__c timeDate = keyTimeDate.get((String)positiveTimeDates.get('Key__c'));
                List<pse__Time_Date__c> timeDates = keyToTimeDates.get((String)positiveTimeDates.get('Key__c'));
                Decimal totalNegtiveHoursLogged = 0.0;
                Boolean flag = false;
                List<String> tDatesProcessed = new List<String>();
                
                //20.10.2 iterage over each store negative sum for each key
                for(pse__Time_Date__c eachTdfromKey : timeDates)
                {
					totalNegtiveHoursLogged += eachTdfromKey.pse__Hours__c;
                    tDatesProcessed.add(eachTdfromKey.Id);
                }
                
                if((Decimal)(positiveTimeDates.get('totalHrs')) + totalNegtiveHoursLogged < 0)
                {
                    //20.10.2 iterage over each and set the Net Negative flag for each one of them
                    flag = true;
                    for(pse__Time_Date__c timeDate : timeDates)
                    {
                        System.debug('timeDate inside checking the net negative flag :: ' + timeDate);
                    	timeDate.Net_Negative__c = true;                    
                    	lstNetNegativeTimeDates.add(timeDate);
                    } 
                } 
                //Changes by sharath: removing the id of the timedate which has already been processed.
                //20.10.2 changes by Sujay to remove all the TDs which are processed without resulting in Net Negative 
                System.debug('before removal lstNegativeTDIds...' + lstNegativeTDIds);
                if(!flag)
                {
					lstNegativeTDIds.removeAll(tDatesProcessed);   
                }
                System.debug('after removal lstNegativeTDIds...' + lstNegativeTDIds);
                //End of changes by sharath
            }
            System.debug('lstNetNegativeTimeDates...'+lstNetNegativeTimeDates);
            System.debug('lstNegativeTDIds...' + lstNegativeTDIds);
            /* This if condition handles the case when a single negative hour is entered and there are no hours present for that key. */
            if(lstNegativeTDIds != null && lstNegativeTDIds.size() > 0)
            {
                //Changes by sharath: Commenting out the query to check if a single negative hour is entered as only those timedates are left in the set
                //positiveTimeDates1 = [select Key__c, sum(pse__Hours__c) totalHrs from pse__Time_Date__c where Key__c in :keyTimeDate.keyset() and Id not in :lstNegativeTDIds and pse__Timecard__r.pse__Billable__c = true and pse__Timecard__r.pse__Milestone__r.Billable__c = true and FF_Rejected__c = false  and pse__Timecard__r.pse__Status__c != 'Rejected' and pse__Timecard__r.pse__Status__c != 'Saved' group by Key__c];
                //System.debug('positiveTimeDates1...'+positiveTimeDates1);
                //if(positiveTimeDates1 == null || positiveTimeDates1.size() == 0)
                //{
                    for(pse__Time_Date__c timeDate:[select Id, Net_Negative__c,pse__Timecard__c from pse__Time_Date__c where Id in :lstNegativeTDIds])
                    {
                        timeDate.Net_Negative__c = true;
                        lstNetNegativeTimeDates.add(timeDate);
                    }
                //}
                //End of changes by sharath
            }
        }
        System.debug('lstNetNegativeTimeDates final: '+ lstNetNegativeTimeDates);

        if(lstApprovedNetNegativeTimeDates.size() > 0)
        {
            System.debug('list net negative TDs before update.. '+lstApprovedNetNegativeTimeDates);
            //Start of changes by sharath: initialising setTimecardIds 
            setTimecardIds = new Set<ID>();
            //20.10.2 - changes by Sujay : removing and loading the duplicate records and updating them to show the net negative error.
            Map<Id, pse__Time_Date__c> removeDupTimeDateRecs = new Map<Id, pse__Time_Date__c>();
            removeDupTimeDateRecs.putAll(lstApprovedNetNegativeTimeDates);
            
            //Adding timecardID of the timedates that result in net-negative to setTimecardIds
            for (pse__Time_Date__c timeDate: lstApprovedNetNegativeTimeDates)
            {
                setTimecardIds.add(timeDate.pse__Timecard__c);
            }
            System.debug('***setTimecardIds'+setTimecardIds);
            try
            {
                //update lstApprovedNetNegativeTimeDates;
                update removeDupTimeDateRecs.values();
            }
            catch(Exception e)
            {
                for(pse__Timecard_Header__c tcError:editedTCRecords)
                {    
                    //Changes by sharath: check if id of the timecard is in setTimecardIds. If so, add the error.
                    if(setTimecardIds.contains(tcError.id))
                    {
                        System.debug(e.getMessage());
                        if(e.getMessage().contains('The hours entered are not valid as'))
                            tcError.addError('You are trying to approve a Timecard which would result in a Net Negative hour for this day/month, resource and project due to negative hours entered previously. Please review and reject the previous negative data and try again.');
                    }
                }   
            }
        }
       
        if(lstNetNegativeTimeDates.size() > 0)
        {
            //Start of changes by sharath: initialising setTimecardIds             
            setTimecardIds = new Set<ID>();
            //20.10.2 - changes by Sujay : removing and loading the duplicate records and updating them to show the net negative error.
            Map<Id, pse__Time_Date__c> removeDupTimeDateRecs = new Map<Id, pse__Time_Date__c>();
            removeDupTimeDateRecs.putAll(lstNetNegativeTimeDates);
            //Adding timecardID of the timedates that result in net-negative to setTimecardIds
            for (pse__Time_Date__c timeDate: lstNetNegativeTimeDates)
            {
                setTimecardIds.add(timeDate.pse__Timecard__c);
            }
            System.debug('list net negative TDs before update.. '+lstNetNegativeTimeDates);
            
            try
            {
                //update lstNetNegativeTimeDates;
                update removeDupTimeDateRecs.values();
            }
            catch(Exception e)
            {
                System.debug('Size of editedTCRecords... '+editedTCRecords.size());
                for(pse__Timecard_Header__c tcError:editedTCRecords)
                {
                    //Changes by sharath: check if id of the timecard is in setTimecardIds. If so, add the error.
                    if(setTimecardIds.contains(tcError.id))
                    {
                        tcError.addError(e.getMessage());
                    }
                }
                System.debug('**** In the catch block...'+e.getMessage());
            }
        }
        
        //Changes by Sharath: Checking if the custom setting Validation On Timecard Recall Active has the value 'yes'. If so add the error on recall
        if(lstRecalledNetNegativeTimeDates.size() > 0 && validateOnRecall == 'yes')
        {
            //Start of changes by sharath: initialising setTimecardIds             
            setTimecardIds = new Set<ID>();
            //Adding timecardID of the timedates that result in net-negative to setTimecardIds
            for (pse__Time_Date__c timeDate: lstRecalledNetNegativeTimeDates)
            {
                setTimecardIds.add(timeDate.pse__Timecard__c);
            }

            try
            {
                update lstRecalledNetNegativeTimeDates;
            }
            catch(Exception e)
            {
                for(pse__Timecard_Header__c tcError:editedTCRecords)
                {
                    //Changes by sharath: check if id of the timecard is in setTimecardIds. If so, add the error.
                    if(setTimecardIds.contains(tcError.id))
                    {
                        System.debug(e.getMessage());
                        if(e.getMessage().contains('The hours entered are not valid as'))
                            tcError.addError('You are trying to recall a Timecard which would result in a Net Negative hour for this day/month, resource and project due to negative hours entered previously. Please review and correct the previous negative data and try again.');
                    }    
                }
            }
        }
        
        if(lstRejectedNetNegativeTimeDates.size() > 0)
        {
            //Start of changes by sharath: initialising setTimecardIds             
            setTimecardIds = new Set<ID>();
            //Adding timecardID of the timedates that result in net-negative to setTimecardIds
            for (pse__Time_Date__c timeDate: lstRejectedNetNegativeTimeDates)
            {
                setTimecardIds.add(timeDate.pse__Timecard__c);
            }
            
            try
            {
                update lstRejectedNetNegativeTimeDates;
            }
            catch(Exception e)
            {
                for(pse__Timecard_Header__c tcError:editedTCRecords)
                {
                    //Changes by sharath: check if id of the timecard is in setTimecardIds. If so, add the error.
                    if (setTimecardIds.contains(tcError.ID))
                    {
                        System.debug(e.getMessage());
                        if(e.getMessage().contains('The hours entered are not valid as'))
                            tcError.addError('You are trying to reject a Timecard which would result in a Net Negative hour for this day/month, resource and project due to negative hours entered previously. Please review and reject the previous negative data and try again.');
    
                    }
                    
                }
            }
        }
    } 

    // changes by suhas for FFPSA-545
    public static void psHoursUtilization(List<pse__Timecard_Header__c> newTimecardList, Map<Id, pse__Timecard_Header__c> oldTimecardListMap )
    {
        System.debug('check is first time : ' + isFirstTime );
        if(isFirstTime)
        {
            isFirstTime = false ;
            Set<Id> prjIdswithStatus = new Set<Id>();
            Set<Id> prjIdswithOldQuarterValue = new Set<Id>();
            List<Id> projAccounts = new List<Id>();
            List<Id> prjIdswithOldQuarterValueAccounts = new List<Id>();
            Map<Id , List<pse__Timecard_Header__c> > tcList = new Map<Id , List<pse__Timecard_Header__c> >();

            List<PSA_Common_Setting__mdt> products = new List<PSA_Common_Setting__mdt>([Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'GSS Protect and Perform Products']);

            Set<String> productList = new Set<String>();

            Map<Id, pse__proj__c> projects = new Map<Id, pse__proj__c>();

            for(PSA_Common_Setting__mdt product : products)
            {
                for(String str :product.Value_Long__c.split(',') )
                {
                    productList.add(str.trim());
                }
            }
            System.debug('displaying list of products : ' + productList);

            // should be visible in test class
            if(productList == null || productList.size() == 0 )
            {
                return;
            }

            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress'); // move it to custom meta data
            String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';


            String orgWideEmailId;
            
            try
            {
                orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id; // do not querry but put in custom meta data directly
            }
            catch(Exception e)
            {
                orgWideEmailId = null; 
            }
            
            Set<Id> tcIds = new Set<Id>();
            System.debug('before for loop'+prjIdswithStatus);

            System.debug('new list :' + newTimecardList + ' old map : ' + oldTimecardListMap);

            for(pse__Timecard_Header__c timecard: newTimecardList)
            {
                System.debug('check for values in test : ' + ' Billable__c : ' + timecard.pse__Billable__c + ' timecard.pse__Status__c :' + timecard.pse__Status__c + 'oldTimecardListMap.get(timecard.Id).pse__Status__c : ' + oldTimecardListMap.get(timecard.Id).pse__Status__c );
                System.debug('checkk : ' + ( timecard.pse__Billable__c && ( (timecard.pse__Status__c == 'Approved' && oldTimecardListMap.get(timecard.Id).pse__Status__c != 'Approved') || (timecard.pse__Approved__c && !oldTimecardListMap.get(timecard.Id).pse__Approved__c ) ) )  );
                if( timecard.pse__Billable__c && ( (timecard.pse__Status__c == 'Approved' && oldTimecardListMap.get(timecard.Id).pse__Status__c != 'Approved') || (timecard.pse__Approved__c && !oldTimecardListMap.get(timecard.Id).pse__Approved__c ) ) )
                {
                    prjIdswithStatus.add(timecard.pse__Project__c);

                    System.debug('In for loop'+prjIdswithStatus);

                    // save the map of project to timecards with right status 
                    if(!tcList.containsKey(timecard.pse__Project__c))
                    {
                        tcList.put(timecard.pse__Project__c, new List<pse__Timecard_Header__c>());
                    }
                    tcList.get(timecard.pse__Project__c).add(timecard);
                    
                }
            }
            System.debug('After for loop'+ prjIdswithStatus);

            // Get all the CLIs of timecard's projects to check for timecards associated to right product
            if(prjIdswithStatus.size() > 0)
            {
                System.debug('check before loop1 :' + prjIdswithStatus);
                System.debug('tc lict values : ' + tcList.values() );
                System.debug('tc lict values of 0 : ' + tcList.values().get(0) );

                List<Id> tcsList = new List<Id>();
                System.debug('tcsList  : ' + tcsList );

                for(pse__proj__c proj: [Select Id, Current_Quarter__c, pse__Account__c,Total_Billable_Hours_Q4__c, Total_Billable_Hours_Q3__c, Total_Billable_Hours_Q2__c, Total_Billable_Hours_Q1__c, pse__Project_Manager__c, pse__Account__r.Name, AKAM_Project_ID__c,
                                                (select Id, Units_Low__c, Units_High__c, Effective_Start_Date__c, Contract_Detail__r.Billing_Duration__c, Product__c, Product_Id__c , Unit_of_Measure__c from Project_Contract_Line_Items__r order by createdDate DESC limit 1 )
                                                from pse__proj__c where Id IN :prjIdswithStatus ] )
                {
                    //System.debug('product condition : ' + ( (!productList.contains(proj.Project_Contract_Line_Items__r.get(0).Product_Id__c)) || (proj.Project_Contract_Line_Items__r.get(0).Unit_of_Measure__c != 'Hour') ||  (proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c != 'Quarterly' && proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c != 'Annual')|| (proj.Project_Contract_Line_Items__r.get(0).Units_Low__c == 0 || proj.Project_Contract_Line_Items__r.get(0).Units_Low__c == null ) || (proj.Project_Contract_Line_Items__r.get(0).Units_High__c == 0 || proj.Project_Contract_Line_Items__r.get(0).Units_High__c == null) ) );

                    if( (proj.Project_Contract_Line_Items__r !=null && proj.Project_Contract_Line_Items__r.size() > 0 ) &&  ( (!productList.contains(proj.Project_Contract_Line_Items__r.get(0).Product_Id__c)) || (proj.Project_Contract_Line_Items__r.get(0).Unit_of_Measure__c != 'Hour') ||  (proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c != 'Quarterly' && proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c != 'Annual')|| (proj.Project_Contract_Line_Items__r.get(0).Units_Low__c == 0 || proj.Project_Contract_Line_Items__r.get(0).Units_Low__c == null ) || (proj.Project_Contract_Line_Items__r.get(0).Units_High__c == 0 || proj.Project_Contract_Line_Items__r.get(0).Units_High__c == null) ) )
                    {
                        tcList.remove(proj.Id);
                    }
                    // if the project does not contain the required product, remove it from the set in the above condition 
                    //else save the project in the below map
                    else 
                    {
                        projects.put(proj.Id, proj);
                        projAccounts.add(proj.pse__Account__c);
                    }

                }

            }

            List<String> accountTeamRoles = new List<String>();

            for(PSA_Common_Setting__mdt psaCommSetting :[Select Value__C from PSA_Common_Setting__mdt where Name__c Like 'Account Team Member Roles%'] )
            {
                for(String str :psaCommSetting.Value__C.split(',') )
                {
                    accountTeamRoles.add(str.trim());
                }
            }


            Map<Id, Account> accTeam = new Map<Id, Account>([select Id,(select Id,UserId from AccountTeamMembers where TeamMemberRole IN :accountTeamRoles AND User.IsActive = TRUE  ) from Account where Id IN :projAccounts ]);

            List<pse__proj__c> projToUpdate = new List<pse__proj__c>();

            if(projects.size() > 0)
            {
                System.debug('inside projects.size ');
                for(pse__proj__c proj: projects.values())
                {
                    if(proj.Project_Contract_Line_Items__r !=null && proj.Project_Contract_Line_Items__r.size() > 0 )
                    {
                        Double days = 0.00;
                        Integer quarterEndDays = 0 ;
                        Double currentQuarterHours = 0.00 ;
                        if(proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c == 'Quarterly')
                        {
                            days = 90.0;
                            quarterEndDays = 14;
                        }
                        else if(proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c == 'Annual')
                        {
                            days = 365.0;
                            quarterEndDays = 30 ;
                        }
                        if(proj.Total_Billable_Hours_Q1__c == null) {proj.Total_Billable_Hours_Q1__c = 0;}
                        if(proj.Total_Billable_Hours_Q2__c == null) {proj.Total_Billable_Hours_Q2__c = 0;}
                        if(proj.Total_Billable_Hours_Q3__c == null) {proj.Total_Billable_Hours_Q3__c = 0;}
                        if(proj.Total_Billable_Hours_Q4__c == null) {proj.Total_Billable_Hours_Q4__c = 0;}
                        Integer projCurrentQ = findQuarter(date.today(), proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c, proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c ) ;
                        System.debug('proj cur Q ' + proj.Current_Quarter__c);
                        Date quarterEndDate = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) (projCurrentQ * days));
                        Date quarterStartDate = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) ((projCurrentQ - 1) * days) );
                        if( projCurrentQ == proj.Current_Quarter__c )
                        {
                            System.debug('check quarter conditionnn : ' + projCurrentQ + ' proj.Current_Quarter__c :  ' + proj.Current_Quarter__c );
                            Double currentQTotHrs = 0.00;
                            Double prevQTotHrs = 0.00;
                            double unitsLow = proj.Project_Contract_Line_Items__r.get(0).Units_Low__c;
                            for(pse__Timecard_Header__c timecard : tcList.get(proj.Id) )
                            {
                                if(timecard.pse__Total_Hours__c != null && timecard.pse__Total_Hours__c != 0 )
                                {
                                    System.debug('for the timecard( tot hr not null and not 0 ) Id: ' +  timecard.Id);
                                    Integer tcQuarter = findQuarter(timecard.pse__Start_Date__c, proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c, proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c );
                                    Integer daysAheadofQuarter = 0;
                                    if( tcQuarter !=0 )
                                    {
                                        if( timecard.pse__End_Date__c >= quarterEndDate )
                                        {
                                            daysAheadofQuarter = quarterEndDate.daysBetween(timecard.pse__End_Date__c);
                                            currentQTotHrs = currentQTotHrs + postQuarterHoursSplit(daysAheadofQuarter, timecard, quarterEndDate ).get(1);
                                        }
                                        else { currentQTotHrs = currentQTotHrs + timecard.pse__Total_Hours__c; }
                                        
                                    }
                                    // Below condition for timecards with start date in previous quarter and end date in current quarter
                                    else if( timecard.pse__End_Date__c >= quarterStartDate && timecard.pse__Start_Date__c <  quarterStartDate )
                                    {
                                        System.debug('has not enter here' );
                                        daysAheadofQuarter = quarterStartDate.daysBetween(timecard.pse__End_Date__c);
                                        currentQTotHrs = currentQTotHrs + postQuarterHoursSplit(daysAheadofQuarter, timecard, quarterEndDate ).get(2);
                                        prevQTotHrs = prevQTotHrs + postQuarterHoursSplit(daysAheadofQuarter, timecard, quarterEndDate ).get(1);
                                    }
                                    // below condition for timecards with end date in the previous Quarter
                                    else if( timecard.pse__End_Date__c < quarterStartDate && timecard.pse__End_Date__c >= quarterStartDate.addDays( (Integer) (-days) ) )
                                    {
                                        if(timecard.pse__Start_Date__c < quarterStartDate.addDays( (Integer)(0 - days) ) )
                                        {
                                            daysAheadofQuarter = timecard.pse__Start_Date__c.daysBetween(quarterStartDate.addDays( (Integer)(0 - days) ));
                                            prevQTotHrs = prevQTotHrs + postQuarterHoursSplit(daysAheadofQuarter, timecard, quarterEndDate ).get(2);
                                        }
                                        else {System.debug('but  here ' ); prevQTotHrs = prevQTotHrs + timecard.pse__Total_Hours__c; }
                                    }
                                }
                                System.debug('checking toto hrs : ' + currentQTotHrs );
                            }

                            Integer quarterNum = projCurrentQ <= 4 ? projCurrentQ :4;
                            Integer prevQuarterNum = quarterNum - 1;
                            
                            currentQuarterHours = (Double)(proj.get('Total_Billable_Hours_Q'+quarterNum+'__c')) + currentQTotHrs;
                            proj.put('Total_Billable_Hours_Q'+quarterNum+'__c',  currentQuarterHours);
                            if(prevQuarterNum > 0)
                            {
                                Double prevhoursValue = (Double)proj.get('Total_Billable_Hours_Q'+prevQuarterNum +'__c') + prevQTotHrs ;
                                proj.put('Total_Billable_Hours_Q'+prevQuarterNum+'__c', prevhoursValue);    
                            }
                            
                            if( ( (currentQuarterHours >= (unitsLow * 70)/100) ) && (currentQuarterHours - currentQTotHrs < ((unitsLow * 70)/100) ) )
                            {
                                if( ( Date.valueOf(Date.today()) < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( ( days * projCurrentQ) - quarterEndDays ) )  ))
                                {
                                    notifyForPSHoursUtilization(accTeam.get(proj.pse__Account__c), proj, mailsToBeSent, orgWideEmailId, proj.pse__Project_Manager__c, proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c  );
                                } 
                            }

                        }
                        
                        projToUpdate.add(proj);

                        if(projCurrentQ != proj.Current_Quarter__c)
                        {
                            for(pse__Timecard_Header__c tc :tcList.get(proj.Id) )
                            {
                                tcIds.add(tc.Id); // add this to set instead of list
                            }
                            //tcIds.addAll(projects.get(proj.Id).pse__Timecards__r.Id);
                            prjIdswithOldQuarterValue.add(proj.Id);
                            prjIdswithOldQuarterValueAccounts.add(proj.pse__Account__c);
                        }
                    }
                    
                }
                
                update projToUpdate;

                Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
                for(Messaging.SendEmailResult result : mailSendResult)
                {
                    System.debug('Email result in method 1' + result.IsSuccess());
                    System.debug('Individ rsl in method 1:' + result);
                }
            }
            
            if(tcIds != null)
            {
                System.debug('calling func tcIds ' + tcIds);
                psHoursUtilizationFuture(tcIds, prjIdswithOldQuarterValue, prjIdswithOldQuarterValueAccounts);
            }
        }
    }

    @future
    public static void psHoursUtilizationFuture(Set<Id> tcids, Set<Id> projIds,List<Id> projAccounts )
    {
        List<pse__Timecard_Header__c> tcs = new List<pse__Timecard_Header__c>();
        Map<Id, List<Id>> projToTcs = new Map<Id, List<Id>>();
        List<pse__proj__c> projToUpdate = new List<pse__proj__c>();
        
        List<String> accountTeamRoles = new List<String>();

        for(PSA_Common_Setting__mdt psaCommSetting :[Select Value__C from PSA_Common_Setting__mdt where Name__c Like 'Account Team Member Roles%'] )
        {
            for(String str :psaCommSetting.Value__C.split(',') )
            {
                accountTeamRoles.add(str.trim());
            }
        }

        System.debug('check projAccnts :' + projAccounts);

        Map<Id, Account> accTeam = new Map<Id, Account>([select Id,(select Id,UserId from AccountTeamMembers where TeamMemberRole IN :accountTeamRoles AND User.IsActive = TRUE  ) from Account where Id IN:projAccounts ]);
        
        List<pse__proj__c> prjs = new List<pse__proj__c>([select id,pse__Account__r.Name,AKAM_Project_ID__c,pse__Project_Manager__c,Total_Billable_Hours_Q1__c,Total_Billable_Hours_Q2__c,Total_Billable_Hours_Q3__c,Total_Billable_Hours_Q4__c,pse__Account__c ,Current_Quarter__c,
                                                                 (select id,pse__Total_Hours__c,pse__Start_Date__c, pse__End_Date__c ,Approved_Date__c, pse__Monday_Hours__c, pse__Tuesday_Hours__c , pse__Wednesday_Hours__c, pse__Thursday_Hours__c, pse__Friday_Hours__c, pse__Saturday_Hours__c , pse__Sunday_Hours__c from pse__Timecards__r where pse__Status__c = 'Approved' AND pse__Billable__c = true AND ((pse__Start_Date__c = LAST_N_DAYS:100 OR pse__Start_Date__c = NEXT_N_DAYS:90) OR Id IN :tcIds ) ), 
                                                                 (select Id, Units_Low__c, Effective_Start_Date__c, Contract_Detail__r.Billing_Duration__c from Project_Contract_Line_Items__r order by createdDate DESC limit 1 )
                                                                 from pse__proj__c where Id IN :projIds ]);
        
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress');
        String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';


        String orgWideEmailId;
        
        try
        {
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id;
        }
        catch(Exception e)
        {
            orgWideEmailId = null; 
        }
        System.debug('just before prjs :' + prjs );
        for(pse__proj__c proj: prjs)
        {
            Double hoursTobeAdded = 0.00 ;
            Integer quarter;
            Double prevQ1Hrs = 0.00;
            Double prevQ2Hrs = 0.00;
            Double prevQ3Hrs = 0.00;
            Double lastQHrs = 0.00;
            //Double prevQ4Hrs = 0;
            Double currentQuarterTCTotalHrs = 0.00;
            Integer days = 0;

            if(proj.Total_Billable_Hours_Q1__c == null) {proj.Total_Billable_Hours_Q1__c = 0;}
            if(proj.Total_Billable_Hours_Q2__c == null) {proj.Total_Billable_Hours_Q2__c = 0;}
            if(proj.Total_Billable_Hours_Q3__c == null) {proj.Total_Billable_Hours_Q3__c = 0;}
            if(proj.Total_Billable_Hours_Q4__c == null) {proj.Total_Billable_Hours_Q4__c = 0;}

            String billingDuration = proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c ;
            Integer projPresentQuarter = findQuarter(Date.today(), proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c, billingDuration  ) ;

            if(billingDuration == 'Quarterly')
            {
                days = 90;
            }
            else if( billingDuration == 'Annual' )
            {
                days = 365;
            }

            Date projQuarterEndDate = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( projPresentQuarter * days) )  ;

            Double totalHrstoExclude = 0.00;

            System.debug('timecards : ' + proj.pse__Timecards__r);

            for(pse__Timecard_Header__c timeCard: proj.pse__Timecards__r)
            {

                if(timeCard.pse__Total_Hours__c != null )
                {
                    System.debug('for the timecard( tot hr not null ) Id:  ' +  timeCard.Id);
                    Integer timecardQuarter;

                    Integer timecardDaysDiff = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.daysBetween(timeCard.pse__Start_Date__c);

                    if(billingDuration == 'Quarterly') { timecardQuarter =(Integer) Math.ceil(timecardDaysDiff/90.0); }

                    if(billingDuration == 'Annual') { timecardQuarter =(Integer) Math.ceil(timecardDaysDiff/365.0); }
                    System.debug('disp TC Start date : ' + timeCard.pse__Start_Date__c);

                    Integer daysAheadofQuarter = 0;

                    quarter = findQuarter(timeCard.pse__Start_Date__c, proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c, billingDuration  ) ;

                    if(timeCard.pse__End_Date__c >= projQuarterEndDate)
                    {
                        // check what happens when both dates are equal
                        daysAheadofQuarter = projQuarterEndDate.daysBetween(timeCard.pse__End_Date__c);
                        //if(daysAheadofQuarter == 0) {daysAheadofQuarter = 1;}
                    }
                    
                    System.debug('time card quarter correct ? :' + (tcids.contains(timecard.Id) &&  quarter != 0) + 'timecard id :' + timeCard.Id );
                    // Go through all the timecard that has entered the trigger and which are in current quarter and sum-up all timecards total hours
                    //if( tcids.contains(timecard.Id) &&  quarter != 0 ) // Old Code
                    if( quarter != 0 )
                    {
                        System.debug('check if old timecard is coming : ' + timeCard.Id);
                        if(timeCard.pse__End_Date__c >= projQuarterEndDate)
                        {
                            System.debug('daysAheadofQuarter : ' +  daysAheadofQuarter  + 'projQuarterEndDate : ' +  projQuarterEndDate + ' timecards first part : ' + postQuarterHoursSplit(daysAheadofQuarter, timeCard, projQuarterEndDate).get(1));
                            hoursTobeAdded = hoursTobeAdded + postQuarterHoursSplit(daysAheadofQuarter, timeCard, projQuarterEndDate).get(1);
                        }
                        else 
                        {
                            hoursTobeAdded += timeCard.pse__Total_Hours__c; 
                        }
                    }
                    // Below else if Condition for timecards which was approved now but was for previous Quarter
                    else if( quarter == 0 && tcids.contains(timecard.Id)  )
                    {

                        if(  timecardQuarter == (projPresentQuarter - 1)  )
                        {
                            Double prevQHourstoDeduct = 0.00;
                            if(timeCard.pse__End_Date__c >= proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays(timecardQuarter * days ) )
                            {
                                daysAheadofQuarter = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays(timecardQuarter * days ).daysBetween(timeCard.pse__End_Date__c);
                                prevQHourstoDeduct = postQuarterHoursSplit(daysAheadofQuarter, timeCard, proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays(timecardQuarter * days )).get(2);
                                hoursTobeAdded +=   prevQHourstoDeduct;
                                lastQHrs +=  timeCard.pse__Total_Hours__c - prevQHourstoDeduct ;
                            }
                            else { lastQHrs += timeCard.pse__Total_Hours__c ; }
                        }
                        else if( timecardQuarter == (projPresentQuarter - 2) && timeCard.pse__End_Date__c >= (proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (timecardQuarter -1) * days) ))
                        {
                            System.debug('inside for prev timecards');
                            daysAheadofQuarter = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (timecardQuarter-1) * days ).daysBetween(timeCard.pse__End_Date__c);
                            lastQHrs = lastQHrs + postQuarterHoursSplit(daysAheadofQuarter, timeCard, proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (timecardQuarter-1) * days )).get(2);

                        }
                    }
                    // below else if condition for timecards which were already there but only end date is in present quarter
                    else if( quarter == 0 && !(tcids.contains(timecard.Id)) && timeCard.pse__End_Date__c>= (proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (projPresentQuarter -1) * days) )  )
                    {
                        System.debug(' containss : ' + tcids.contains(timecard.Id) );
                        System.debug('already present timecards but not in this quarter id : ' + timecard.Id);
                        daysAheadofQuarter = proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays(timecardQuarter * days ).daysBetween(timeCard.pse__End_Date__c);
                        hoursTobeAdded += postQuarterHoursSplit(daysAheadofQuarter, timeCard, proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays(timecardQuarter * days )).get(2);
                    }
                    System.debug('timecard end date quarter : ' + findQuarter(timeCard.pse__End_Date__c, proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c,billingDuration) );

                }
                
            }

            proj.Current_Quarter__c = projPresentQuarter ;

            if(projPresentQuarter > 4 )
            {
                proj.Total_Billable_Hours_Q1__c = proj.Total_Billable_Hours_Q2__c;
                proj.Total_Billable_Hours_Q2__c = proj.Total_Billable_Hours_Q3__c;
                proj.Total_Billable_Hours_Q3__c = proj.Total_Billable_Hours_Q4__c;
                proj.Total_Billable_Hours_Q4__c = 0;
            }

            double currentQuarterHours = 0 ;

            double unitsLow = proj.Project_Contract_Line_Items__r.get(0).Units_Low__c;


            Integer quarterNum = projPresentQuarter <= 4 ? projPresentQuarter :4;
            Integer prevQuarterNum = quarterNum - 1;

            
            currentQuarterHours = (Double)(proj.get('Total_Billable_Hours_Q'+quarterNum+'__c')) + hoursTobeAdded;
            proj.put('Total_Billable_Hours_Q'+quarterNum+'__c',  currentQuarterHours);
            if(prevQuarterNum > 0)
            {
                Double prevhoursValue = ((Double)proj.get('Total_Billable_Hours_Q'+prevQuarterNum +'__c') ) + lastQHrs ;
                proj.put('Total_Billable_Hours_Q'+prevQuarterNum+'__c', prevhoursValue);    
            }

            System.debug('check for conditiion :' + (( (currentQuarterHours < (unitsLow * 70)/100) ) && (currentQuarterHours + hoursTobeAdded >= (unitsLow * 70)/100) ) );

            if( ( (currentQuarterHours >= (unitsLow * 70)/100) ) && ( (currentQuarterHours - hoursTobeAdded) < (unitsLow * 70)/100) )
            {
                System.debug('he :' + ( Date.valueOf(Date.today()) < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c) );
                System.debug('check for date condtn :' + ( Date.valueOf(Date.today()) < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( (90 * quarter) - 14 ) )  ) );
                if( 
                    (billingDuration == 'Quarterly' && ( Date.valueOf(Date.today()) < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( (90 * quarter) - 14 ) )  )  ) 

                    || 

                    ( billingDuration == 'Annual' && ( Date.valueOf(Date.today()) < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( (365 * quarter) - 30 ) )  ) )  )
                {
                    System.debug('call email func ');
                    notifyForPSHoursUtilization(accTeam.get(proj.pse__Account__c), proj, mailsToBeSent, orgWideEmailId, proj.pse__Project_Manager__c, billingDuration  );
                }
                
            }

            projToUpdate.add(proj);
        }
        if(mailsToBeSent.size() > 0)
        {
            System.debug('send email obj ? :' + mailsToBeSent);
            Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
            for(Messaging.SendEmailResult result : mailSendResult)
            {
                System.debug('Email result ' + result.IsSuccess());
                System.debug('Individ rsl :' + result);
            }

        }
        if(projToUpdate.size() > 0)
        {
            update projToUpdate;
        }
        
    }

    public static Map<Integer, Double> postQuarterHoursSplit(Integer daysAheadofQuarter, pse__Timecard_Header__c timeCard, Date projQuarterEndDate )
    {
        Map<Integer, Double> timeSplit = new Map<Integer, Double>();
        timeSplit.put(1, 0.00 );
        timeSplit.put(2, 0.00 );
        Double hourstoExclude = 0.00;
        for(Integer i = daysAheadofQuarter; i >= 0 ; i-- )
        {
            Datetime dateAhead = DateTime.newInstance(projQuarterEndDate.addDays(i), Time.newInstance(0, 0, 0, 0) );
            String timecardDay = dateAhead.format('EEEE');
            System.debug('timecard day hours : ' + timeCard.get('pse__'+timecardDay+'_Hours__c') + ' day : ' + timecardDay + ' timecards : ' + timeCard.Id );
            System.debug('debug this : ' + timeCard.get('pse__'+timecardDay+'_Hours__c'));
            hourstoExclude = hourstoExclude + (Double) timeCard.get('pse__'+timecardDay+'_Hours__c') ;
        }
        timeSplit.put(1, (timeCard.pse__Total_Hours__c - hourstoExclude) );
        timeSplit.put(2, hourstoExclude);
        return timeSplit;
        
    }

    public static Integer findQuarter(date timecardStartDate, date cliStartDate, String billingDuration)
    {
        
        System.debug('timecard start date : ' +timecardStartDate + ' cliStartDate : ' + cliStartDate);
        Integer tcDaysDifference = cliStartDate.daysBetween(timecardStartDate); 
        if( tcDaysDifference == 0 )
        {
            tcDaysDifference = 1;
        }

        System.debug('diff bw tc start date and cli start date : ' + tcDaysDifference);
        Integer currentDaysDifference = cliStartDate.daysBetween(date.today());

        if( currentDaysDifference == 0  )
        {
            currentDaysDifference = 1;
        }

        System.debug(' diff cli and date.today() :' + cliStartDate.daysBetween(date.today()) );


        Integer tcQuarter;
        Integer currentQuarter;


        if(billingDuration == 'Quarterly')
        {
            tcQuarter =(Integer) Math.ceil(tcDaysDifference/90.0);

            currentQuarter =(Integer) Math.ceil(currentDaysDifference/90.0);

        }

        if(billingDuration == 'Annual')
        {
            tcQuarter =(Integer) Math.ceil(tcDaysDifference/365.0);

            currentQuarter =(Integer) Math.ceil(currentDaysDifference/365.0);
        }

        if(tcQuarter == currentQuarter)
        {
            return currentQuarter;
        }
        else return 0;


    }


    public static void notifyForPSHoursUtilization(Account acc, pse__proj__c proj, Messaging.SingleEmailMessage[] mailsToBeSent, String orgWideEmailId, Id targetObjectId, String billingDuration)
    {

        String billDuration;

        Double q1=0.00,q2=0.00,q3=0.00,q4=0.00;

        String q1current='',q2current='',q3current='',q4current='';

        Integer quarterIterator = (Integer) proj.Current_Quarter__c;
        Integer lastQuarter = ((Integer) proj.Current_Quarter__c > 4)?  4 : ((Integer) proj.Current_Quarter__c) ;

        for(Integer i = ((Integer) proj.Current_Quarter__c) ;  i > ( ((Integer)proj.Current_Quarter__c) - 4 ) && i > 0  ; i-- )
        {
            Integer switchNum = quarterIterator > 4 ? Math.mod(quarterIterator, 4) : quarterIterator ;
            switch on switchNum
            {
                when 1 { q1 = (Double)(proj.get('Total_Billable_Hours_Q'+lastQuarter+'__c')) ; q1current = (quarterIterator == proj.Current_Quarter__c)? q1current = ' (Current Quarter)' : q1current ; }
                when 2 { q2 = (Double)(proj.get('Total_Billable_Hours_Q'+lastQuarter+'__c')) ; q2current = (quarterIterator == proj.Current_Quarter__c)? q2current = ' (Current Quarter)' : q1current ; }
                when 3 { q3 = (Double)(proj.get('Total_Billable_Hours_Q'+lastQuarter+'__c')) ; q3current = (quarterIterator == proj.Current_Quarter__c)? q3current = ' (Current Quarter)' : q1current ; }
                when 4 { q4 = (Double)(proj.get('Total_Billable_Hours_Q'+lastQuarter+'__c')) ; q4current = (quarterIterator == proj.Current_Quarter__c)? q4current = ' (Current Quarter)' : q1current ; }
                when 0 { q4 = (Double)(proj.get('Total_Billable_Hours_Q'+lastQuarter+'__c')) ; q4current = (quarterIterator == proj.Current_Quarter__c)? q4current = ' (Current Quarter)' : q1current ; }
            }
            quarterIterator -- ;
            lastQuarter -- ;
        }

        if(billingDuration == 'Annual')
        {
           billDuration  = 'year';
        } else if (billingDuration == 'Quarterly'){ billDuration = 'quarter'; }

        String htmlBody = '<html><body><p>Hello,</p>' ;

        htmlBody = htmlBody + '<p>You are receiving this e-mail because your customer, <span style="font-weight:bold">' + proj.pse__Account__r.Name ;
        htmlBody = htmlBody + '</span>, has reached 70% utilization against the PS hours available to them as part of their Protect and Perform service contract ';
        htmlBody = htmlBody + proj.AKAM_Project_ID__c ;
        htmlBody = htmlBody + ' for this ' + billDuration +' ('+ billDuration + ' is calculated based on the effective start date of the contract). </p> ';
        htmlBody = htmlBody + '<p> Please review ' + proj.pse__Account__r.Name ;
        htmlBody = htmlBody + '’s usage and work with the Customer and the IAT to adjust any planned work if you wish to avoid overage charges for this ' +billDuration ;
        htmlBody = htmlBody + '. You may also add additional hours if desired.</p> ' ;

        if(billingDuration == 'Quarterly')
        {
            htmlBody = htmlBody + proj.pse__Account__r.Name + ' historical consumption is included below. </br>' ;
            htmlBody = htmlBody + '<table  align="center" border="1" style="height: 20%;" width="80%"><tbody><tr><td align=center style="width: 25%;">Q1' + q1current +'</td>' ;
            htmlBody = htmlBody + '<td align=center style="width: 25%;">Q2' + q2current + '</td><td align=center style="width: 25%;">Q3' + q3current + '</td><td align=center style="width: 25%;">Q4' + q4current + '</td>' ;
            htmlBody = htmlBody + '</tr><tr><td align=center style="width: 25%;">' + q1 + ' of ' + proj.Project_Contract_Line_Items__r.get(0).Units_Low__c + '</td><td align=center style="width: 25%;">' + q2 + ' of ' + proj.Project_Contract_Line_Items__r.get(0).Units_Low__c ;
            htmlBody = htmlBody + '</td><td align=center style="width: 25%;">' + q3 + ' of ' + proj.Project_Contract_Line_Items__r.get(0).Units_Low__c + '</td><td align=center style="width: 25%;">' + q4 + ' of ' + proj.Project_Contract_Line_Items__r.get(0).Units_Low__c ;
            htmlBody = htmlBody + '</td></tr></tbody></table>';
        }


        htmlBody = htmlBody + '<p> Thanks & Regards,</br> PSA Automated Notifications </p></body></html>';
        
        System.debug('Inside email func');
        Messaging.SingleEmailMessage objEmail = new Messaging.Singleemailmessage();
        List<Id> accTeamMemIds = new List<Id>();
        System.debug('acc :' +  acc );

        for(AccountTeamMember member: acc.AccountTeamMembers)
        {
            System.debug('let check :' + member.UserId );
            accTeamMemIds.add(member.UserId);
        }

        System.debug('after test ');

        objEmail.setToAddresses(accTeamMemIds);

        objEmail.setSubject(proj.pse__Account__r.Name + '- PS hours utilization has exceeded 70% for Project ID - ' + proj.AKAM_Project_ID__c);
        
        objEmail.setReplyTo('noreply@akamai.com');

        objEmail.setHtmlBody(htmlBody);
        

        if (orgWideEmailId != null)
        {
          objEmail.setOrgWideEmailAddressId(orgWideEmailId);
        }
        
        objEmail.saveAsActivity = false ;
        mailsToBeSent.add(objEmail);
        System.debug('at the last email ? :' + mailsToBeSent);

    }

    @future
    public static void reCalculateHoursFuture(List<Id> projIdList)
    {
        System.debug('reCalculateHoursFuture');
        List<pse__proj__c> projList = new List<pse__proj__c>([select Id,Total_Billable_Hours_Q1__c,Total_Billable_Hours_Q2__c,Total_Billable_Hours_Q3__c,Total_Billable_Hours_Q4__c ,pse__Project_Manager__c,pse__Account__c,pse__Account__r.Name,AKAM_Project_ID__c, Current_Quarter__c,
                                                                    (select id,pse__Total_Hours__c,pse__Start_Date__c,Approved_Date__c, pse__End_Date__c,pse__Monday_Hours__c, pse__Tuesday_Hours__c , pse__Wednesday_Hours__c, pse__Thursday_Hours__c, pse__Friday_Hours__c, pse__Saturday_Hours__c , pse__Sunday_Hours__c  from pse__Timecards__r where pse__Status__c = 'Approved' AND pse__Billable__c = true AND (pse__Start_Date__c = LAST_N_DAYS:375 OR pse__Start_Date__c = NEXT_N_DAYS:90) ), 
                                                                    (select Id, Units_Low__c, Effective_Start_Date__c, Contract_Detail__r.Billing_Duration__c from Project_Contract_Line_Items__r limit 1 )  
                                                                    from pse__proj__c 
                                                                    where Id IN :projIdList AND pse__Is_Active__c = true  ]);
        List<Id> projAccounts = new List<Id>();
        for(pse__proj__c proj: projList)
        {
            projAccounts.add(proj.pse__Account__c);
        }

        List<String> accountTeamRoles = new List<String>();

        for(PSA_Common_Setting__mdt psaCommSetting :[Select Value__C from PSA_Common_Setting__mdt where Name__c Like 'Account Team Member Roles%'] )
        {
            for(String str :psaCommSetting.Value__C.split(',') )
            {
                accountTeamRoles.add(str.trim());
            }
        }

        Map<Id, Account> accTeam = new Map<Id, Account>([select Id,(select Id,UserId from AccountTeamMembers where TeamMemberRole IN :accountTeamRoles AND User.IsActive = TRUE  ) from Account where Id IN:projAccounts ]);

        List<pse__proj__c> projToUpdate = new List<pse__proj__c>();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress');
        String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';
        String orgWideEmailId;
        
        try
        {
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id;
        }
        catch(Exception e)
        {
            orgWideEmailId = null; 
        }

        for(pse__proj__c proj: projList)
        {
            System.debug('check line item : ' + proj.Project_Contract_Line_Items__r );
            String billingDuration = proj.Project_Contract_Line_Items__r.get(0).Contract_Detail__r.Billing_Duration__c ;

            Integer projCurrentQuarter = findQuarter(date.today() , proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c, billingDuration);
             
            calculateForEachProject(billingDuration, projCurrentQuarter, proj, mailsToBeSent, orgWideEmailId, accTeam );

            projToUpdate.add(proj);

        }

        if(projToUpdate.size() > 0)
        {
            update projToUpdate;
        }
        Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
        for(Messaging.SendEmailResult result : mailSendResult)
        {
            System.debug('Email result ' + result.IsSuccess());
            System.debug('Individ rsl :' + result);
        }

    }

    public static void calculateForEachProject(String billingDuration, Integer quarter, pse__proj__c proj, Messaging.SingleEmailMessage[] mailsToBeSent, String orgWideEmailId,Map<Id, Account> accTeam)
    {
        Double days;
        Boolean mailforProjectCurrentQuarter = false ;
        if(billingDuration == 'Quarterly')
        {
            days = 90;
        }
        else if( billingDuration == 'Annual' )
        {
            days = 365;
        }

        proj.Total_Billable_Hours_Q1__c = 0;
        proj.Total_Billable_Hours_Q2__c = 0;
        proj.Total_Billable_Hours_Q3__c = 0;
        proj.Total_Billable_Hours_Q4__c = 0;

        System.debug('before for each inside func ' + quarter);

        proj.Current_Quarter__c = quarter;
        Integer j = 4 ;
        for( Integer i = quarter; (i > quarter - 4 && i > 0) && (j > 0 ) ; i--  )
        {

            System.debug('(Integer) Math.ceil( i-1 * days) : ' + (Integer) Math.ceil( (i-1) * days) );
            System.debug('Effctive start date : ' + proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c + ' Add dasys :  ' + proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( (i-1) * days) ) );

            Date quarterEndDate = Date.newInstance(proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( i * days) ).year(), 
                                                   proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( i * days) ).month(), 
                                                   proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( i * days) ).day() ) ;

            Date quarterStartDate = Date.newInstance( proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( (i-1) * days) ).year(),
                                                      proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( (i-1) * days) ).month(),
                                                      proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays( (Integer) Math.ceil( (i-1) * days) ).day() );
            Double tcApprovedHours = 0 ;

            System.debug('For Quarter : ' + i + ' || Quarter Start Date : ' + quarterStartDate + ' || Quarter end date : ' + quarterEndDate);

            for(pse__Timecard_Header__c timecard: proj.pse__Timecards__r )
            {
                if(timecard.pse__Total_Hours__c != null)
                {
                    System.debug('for the timecard( tot hr not null) inside date chnage and line item insert  Id: ' +  timeCard.Id);
                    // check the below if condition for dates ( = or < or > )
                    System.debug('timecard dates : Start Date : ' +  timecard.pse__Start_Date__c + '|| Timecard End Date : ' + timecard.pse__Start_Date__c + ' timecard : ' + timecard.Id + ' Timecard Dates condition :  ' + (timecard.pse__Start_Date__c < quarterEndDate && timecard.pse__Start_Date__c > quarterStartDate) );
                    if(timecard.pse__Start_Date__c < quarterEndDate && timecard.pse__Start_Date__c >= quarterStartDate)
                    {
                        System.debug('calculaten for timecard : ' + timecard.Id );
                        if( timeCard.pse__End_Date__c >= quarterEndDate )
                        {
                            Integer daysAheadofQuarter = quarterEndDate.daysBetween(timeCard.pse__End_Date__c);
                            tcApprovedHours = tcApprovedHours + postQuarterHoursSplit(daysAheadofQuarter, timecard, quarterEndDate).get(1);
                        }
                        else { tcApprovedHours = tcApprovedHours + timecard.pse__Total_Hours__c ; }
                    }
                    if(timecard.pse__End_Date__c >= quarterStartDate && timecard.pse__Start_Date__c < quarterStartDate)
                    {
                        Integer daysAheadofQuarter = quarterStartDate.daysBetween(timeCard.pse__End_Date__c);
                        tcApprovedHours = tcApprovedHours + postQuarterHoursSplit(daysAheadofQuarter, timecard, quarterStartDate).get(2);
                    }
                    System.debug('cumilative hours after above time card is considered : ' + tcApprovedHours );

                }
            }

            System.debug('Quarters Approved Hrs :' + tcApprovedHours);

            Integer quarterNum;

            if( quarter < 5 )
            {
                quarterNum = i ;
            }
            else { quarterNum = j ; }
            
            proj.put('Total_Billable_Hours_Q'+quarterNum+'__c', tcApprovedHours);

            if(i == quarter && tcApprovedHours >= (proj.Project_Contract_Line_Items__r.get(0).Units_Low__c * 70)/100 )
            {
                System.debug('condition ? ' + ( (billingDuration == 'Quarterly') && (date.today() < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( (90 * quarter) - 14 ) )  )) );
                if( billingDuration == 'Quarterly' && ( Date.today() < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( (90 * quarter) - 14 ) )  ))
                {
                    mailforProjectCurrentQuarter = true ;
                    System.debug('hereee ?? ' + proj.Id);
                }
                else if( billingDuration == 'Annual' && ( Date.today() < proj.Project_Contract_Line_Items__r.get(0).Effective_Start_Date__c.addDays((Integer) Math.ceil( (365 * quarter) - 30 ) )  ))
                {
                    mailforProjectCurrentQuarter = true ;
                }
            }

            j -- ;

        }

        if(mailforProjectCurrentQuarter)
        {
            notifyForPSHoursUtilization(accTeam.get(proj.pse__Account__c), proj, mailsToBeSent, orgWideEmailId, proj.pse__Project_Manager__c, billingDuration  );
        }

    }
    // End of changes by suhas for FFPSA-545

    public static void updateTaskTimeMilestone( Map<Id,pse__Timecard_Header__c> oldTimecardMap, Map<Id,pse__Timecard_Header__c> newTimecardMap  )
    {
        System.debug('timecard trig');
        List<pse__Timecard_Header__c> filteredTimecards = new List<pse__Timecard_Header__c>();
        List<pse__Task_Time__c> taskTimeList = new List<pse__Task_Time__c>();
        List<Id> timecardIdList = new List<Id>();

        for (pse__Timecard_Header__c tc : newTimecardMap.values() ) {
            System.debug('check mile for each timecard');
            if (tc.pse__Milestone__c != oldTimecardMap.get(tc.Id).pse__Milestone__c ) {
                System.debug('cndtn was true');
                filteredTimecards.add(tc);
                timecardIdList.add(tc.Id);
            }
        }

        if (timecardIdList != null && timecardIdList.size()>0 ) {
            taskTimeList = [select id, pse__Timecard__c , pse__Project_Task__c	 from pse__Task_Time__c where pse__Timecard__c	in :timecardIdList ];
        }

        if(taskTimeList != null && taskTimeList.size()>0  )
        {
            //Triggering Update event on Task Time which causes the Task Time Before update trigger to fire to check the milestone match of Timecard and Project Task
            Database.update(taskTimeList);
        }
    }

}