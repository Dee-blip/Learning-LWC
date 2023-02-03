/***
    PSA_AssignmentActions
    @author Liz Ichihashi
    @Description : This Class contains a method called from PSA_Assignment_Trigger on before insert.
                   When an assignment is created, look for the project's project contract line item
                   and relate it to the assignment. 
                 
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         9/12/2013     Created the class.     
*/
public with sharing class PSA_AssignmentActions {

    /* on before insert relate  the project's project contract line item to it */
    public static void checkForProjectContractLineItemToAssociate(List<pse__Assignment__c> assignList) {
        Set<Id> projIds = new Set<Id>();
        for (pse__Assignment__c row : assignList) {
            projIds.add(row.pse__Project__c);
        }
        List<Project_Contract_Line_Item__c> projContLineItems = [Select Id, Project__c 
                                                From Project_Contract_Line_Item__c 
                                                Where Project__c in :projIds];
                                                
        Map<Id, Id> projIdToProjContItemId = new Map<Id, Id>();                                     
        if (projContLineItems != null && projContLineItems.size() > 0) {
            for (Project_Contract_Line_Item__c row : projContLineItems) {       
                projIdToProjContItemId.put(row.Project__c, row.Id);
            }                               
            for (pse__Assignment__c assignRow : assignList) {
                assignRow.Project_Contract_Line_Item__c = projIdToProjContItemId.get(assignRow.pse__Project__c);
            }                                       
        }                                           
    }
    public static void checkForValidClosedForTimeEntry(List<pse__Assignment__c> oldList, List<pse__Assignment__c> newList)
    {
      Map<Id, pse__Assignment__c> oldMap = new Map<Id, pse__Assignment__c>(oldList);
        list<pse__Assignment__c> assign2check = new list<pse__Assignment__c>();
        for(pse__Assignment__c a1: newList)
        {
            if(oldMap.get(a1.Id).pse__Closed_for_Time_Entry__c != TRUE && a1.pse__Closed_for_Time_Entry__c == TRUE)
            {
                assign2check.add(a1);
            }
        }
        if(assign2check.size()>0)
          checkforSavedSubmittedTimecards(assign2check);  
                
    }
    
    public static void checkforSavedSubmittedTimecards(list<pse__Assignment__c> a1)
    {
        list<pse__timecard_header__c> tclist = [select id,pse__Project__r.PSA_Ignore_Saved_Timecards__c, pse__Total_Hours__c,pse__Status__c, pse__Assignment__c from pse__timecard_header__c 
                                               where pse__Assignment__c in :a1 and pse__Status__c in ('Saved','Submitted','Approver Level 1','Rejected')];
       map<pse__Assignment__c,list<pse__timecard_header__c>> assgnTc = new map<pse__Assignment__c,list<pse__timecard_header__c>>();
       double numSubmittedHours,numSavedHours;
       for(pse__Assignment__c a2:a1)
       {
           for(pse__timecard_header__c tc:tclist)
           {
              if(tc.pse__Assignment__c == a2.Id)
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
       for(pse__Assignment__c a3:a1)
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
               a3.addError('Note that this Assignment has Saved/Rejected Hours = ' + numSavedHours +'. If you check "Closed for Time Entry" flag resources will not be able to Submit these hours. Check the "Ignore Saved Timecards" flag to lose saved hours and continue.');
           else if(numSubmittedHours!=0)
               a3.addError('Please take action on the Pending Timecards before closing it for Time Entry. This Assignment has Submitted Hours = '+ numSubmittedHours + ' Hours');  
       }
    }
    
}