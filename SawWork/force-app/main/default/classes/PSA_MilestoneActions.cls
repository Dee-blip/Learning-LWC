/***
    PSA_MilestoneActions
    @author Liz Ichihashi
    @Description : This Class contains methods called from PSA_Milestone_Trigger
                   before update and delete.  
                   
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.   
    Sonia                 21/05/2014    CR 2576469 - User Profile: Ability to add, modify & remove Project templates  
*/
public with sharing class PSA_MilestoneActions 
{
    static Boolean CheckUpdatable = Schema.sObjectType.pse__Proj__c.fields.pse__Is_Template__c.isUpdateable();

    /* if either conditions are true (if timecards exist or the milestone is a template milestone), do not allow delete */
    public static void checkForRelatedTimecardsOrIsFromTemplate(List<pse__Milestone__c> mileList) {
        //start of changes for  CR 2576469  
        Map<Id, pse__Milestone__c> mileMap = new Map<Id, pse__Milestone__c>([SELECT Id, From_Template__c, pse__Project__r.pse__Is_Template__c,
                   (SELECT Id FROM pse__Timecards__r)
                    FROM pse__Milestone__c 
                    WHERE Id in :mileList]);
       
        for (pse__Milestone__c mileRow : mileList) {  
            if (!mileMap.get(mileRow.Id).pse__Project__r.pse__Is_Template__c && mileRow.From_Template__c) {
                mileRow.addError('You may not delete the Milestone because it is a Template Milestone.');
            } 
            if (mileMap.get(mileRow.Id).pse__Timecards__r != null && mileMap.get(mileRow.Id).pse__Timecards__r.size() > 0) {
                mileRow.addError('You may not delete the Milestone because it has related Timecards.');
            }
            if (mileMap.get(mileRow.Id).pse__Project__r.pse__Is_Template__c && !CheckUpdatable) {
                mileRow.addError('You do not have permission to delete Template Milestones');
            }
            //end of changes for  CR 2576469 
        }
    }
    
    /* called from PSA_Milestone_Trigger on before update */
    /* this enforces the rule that milestones that originated from a template (Template_Milestone__c checkbox) */
    /* do not have their billable flag or milestone type fields updated */ 
    public static void checkForUpdatesToTemplateMilestones(List<pse__Milestone__c> oldList, List<pse__Milestone__c> newList) {
        Map<Id, pse__Milestone__c> oldMap = new Map<Id, pse__Milestone__c>(oldList);
        //start of changes for  CR 2576469  
        Map<Id, pse__Milestone__c> mileMap = new Map<Id, pse__Milestone__c>([SELECT Id, pse__Project__r.pse__Is_Template__c
                    FROM pse__Milestone__c WHERE Id in :newList]);
        
        for (pse__Milestone__c newRow : newList) {
            if (!mileMap.get(newRow.Id).pse__Project__r.pse__Is_Template__c && newRow.From_Template__c) {
                //end of changes for  CR 2576469  
                if (newRow.Billable__c != oldMap.get(newRow.Id).Billable__c) {
                    newRow.addError('You may not update the Milestone Billable flag because it is a Template Milestone.');
                }
                if (newRow.Milestone_Type_List__c != oldMap.get(newRow.Id).Milestone_Type_List__c) {
                    newRow.addError('You may not update the Milestone Type because it is a Template Milestone.');
                }
            }   
            if (mileMap.get(newRow.Id).pse__Project__r.pse__Is_Template__c && !CheckUpdatable) {
                newRow.addError('You do not have permission to update Template Milestones');
            }
        } 
    }

    //Added by ssawhney for CR 2576469 
    /* called from PSA_Milestone_Trigger on before insert*/
    /* this enforces the rule that users who do not have access to create templates should not be able to add new milestones */
    public static void checkTemplateMilestoneInsert(List<pse__Milestone__c> newList) {
        set<Id> projectIds = new set<Id>();
        
        for (pse__Milestone__c newRow : newList) {
            projectIds.add(newRow.pse__Project__c);
        }
        Map<Id, pse__proj__c> projMap = new Map<Id, pse__proj__c>([SELECT Id, pse__Is_Template__c, Account_Department__c, pse__Account__c 
                    FROM pse__proj__c WHERE Id in :projectIds]);
        
        for (pse__Milestone__c newRow : newList) {
            //added for ESESP-5590, By Bhavesh,prepopulating Account Department and Account_Name__c from parent project.
            if(projMap.get(newRow.pse__Project__c).Account_Department__c != NULL && newRow.Account_Department__c == NULL){
                newRow.Account_Department__c = projMap.get(newRow.pse__Project__c).Account_Department__c;
            }
            if( newRow.Account_Name__c == NULL ){
                newRow.Account_Name__c  = projMap.get(newRow.pse__Project__c).pse__Account__c;
            }
            if (projMap.get(newRow.pse__Project__c).pse__Is_Template__c && !CheckUpdatable) {
                newRow.addError('You do not have permission to insert Template Milestones');
            }
        }
    }
        public static void checkForValidClosedForTimeEntry(List<pse__Milestone__c> oldList, List<pse__Milestone__c> newList)
    {
        Map<Id, pse__Milestone__c> oldMap = new Map<Id, pse__Milestone__c>(oldList);
        list<pse__Milestone__c> milestone2check = new list<pse__Milestone__c>();
        for(pse__Milestone__c a1: newList)
        {
            if(oldMap.get(a1.Id).pse__Closed_for_Time_Entry__c != TRUE && a1.pse__Closed_for_Time_Entry__c == TRUE)
            {
                milestone2check.add(a1);
            }
        }
        if(milestone2check.size()>0)
          checkforSavedSubmittedTimecards(milestone2check); 
    }
    
    public static void checkforSavedSubmittedTimecards(List<pse__Milestone__c> a1)
    {
       list<pse__timecard_header__c> tclist = [select id,pse__Project__r.PSA_Ignore_Saved_Timecards__c,pse__Total_Hours__c,pse__Status__c, pse__Milestone__c from pse__timecard_header__c 
                                               where pse__Milestone__c in :a1 and pse__Status__c in ('Saved','Submitted','Approver Level 1','Rejected')];
       map<pse__Milestone__c,list<pse__timecard_header__c>> assgnTc = new map<pse__Milestone__c,list<pse__timecard_header__c>>();
       double numSubmittedHours,numSavedHours;
       for(pse__Milestone__c a2:a1)
       {
           for(pse__timecard_header__c tc:tclist)
           {
              if(tc.pse__Milestone__c == a2.Id)
              {
                  if(assgnTc.get(a2)!=NULL)
                  {
                     assgnTc.get(a2).add(tc); 
                  }
                  else
                  {
                     assgnTc.put(a2,new list<pse__timecard_header__c>());
                     assgnTc.get(a2).add(tc);  
                  }
                  
              }
           }
       }
           for(pse__Milestone__c a3:a1)
           {
              numSubmittedHours = 0;
              numSavedHours = 0;
              if(assgnTc.get(a3)!= NULL)
              {
                for(pse__timecard_header__c tc1:assgnTc.get(a3))
                {
                   if(tc1.pse__Status__c == 'Submitted' || tc1.pse__Status__c == 'Approver Level 1')
                   {
                      numSubmittedHours+= math.abs(tc1.pse__Total_Hours__c);
                   }
                    else if((tc1.pse__Status__c == 'Saved' || tc1.pse__Status__c =='Rejected') && tc1.pse__Project__r.PSA_Ignore_Saved_Timecards__c == FALSE)
                    {
                       numSavedHours+= math.abs(tc1.pse__Total_Hours__c);
                    }
                }
              }
               if(numSubmittedHours==0 && numSavedHours!= 0 && a3.PSA_Ignore_Saved_Timecards__c == FALSE )
                   a3.addError('Note that this Milestone has Saved/Rejected Hours = ' + numSavedHours +'. If you check "Closed for Time Entry" flag resources will not be able to Submit these hours. Check the "Ignore Saved Timecards" flag to lose saved hours and continue.');
               else if(numSubmittedHours!=0)
                   a3.addError('Please take action on the Pending Timecards before closing it for Time Entry. This Assignment has Submitted Hours = '+ numSubmittedHours + ' Hours');  
           } 
    }
}