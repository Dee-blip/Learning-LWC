/*
CR 2985554 - Need to prevent case worker collision with activities on SOC cases
Created On: 24 September 2015
Created By: ssawhney
Description: Controller for SC_displayCaseTasks.page 
Modification History: 

Date            Developer       CR          Description                                                       
------------------------------------------------------------------------------------------------------------------
18-Dec-2015     Sonia       CR 3204831      Added Custom Sort Logic for Tasks
18-May-2017     Vamsee      ESESP-404       New Status on Task for Managed Security
*/
public with sharing class SC_displayCaseTasks {

    public string filter {get;set;}
    public string caseId {get;set;}
    public list<CustomTask> lstFilteredList {get;set;}

    public static Map<String,integer> sortOrder;

    static {
        sortOrder = new Map<String,integer> ();
        sortOrder.put('In Progress',0);
        sortOrder.put('Not Started',1);
        sortOrder.put('Completed Important',2);
        sortOrder.put('Completed',3);
        sortOrder.put('Waiting on someone else',4);
        sortOrder.put('Deferred',5);
    }

    
    public SC_displayCaseTasks(ApexPages.StandardController stdController) {
        caseId = ApexPages.currentPage().getParameters().get('id');
        FilterTasks(); 
    }

    public PageReference FilterTasks() {  
        lstFilteredList = new list<CustomTask>();

        if(caseId != null)
        {
            string tskQuery = 'Select Id, Type__c, Owner.Name, Status from task where WhatId = \'' + caseId + '\'';
            if(filter != null && filter != '' && filter != 'All')
                tskQuery += ' and Status = \'' + filter + '\''; 
            tskQuery += ' order by Status, CreatedDate desc';
            list<Task> lstTaskList = Database.query(tskQuery);

            for(Task tsk : lstTaskList)
            {
                lstFilteredList.add(new CustomTask(tsk));
            }

            lstFilteredList.sort();
        }
        return null;
    }

    //This class helps to custom sort the activities based on the pre-defined order of Status values
    public class CustomTask implements Comparable {
        
        
        public Task tsk { get; set; }

        public CustomTask(Task tsk) {
            this.tsk = tsk;
        }

        // This method returns an integer, that is the result of the comparison
        public Integer compareTo(Object compareTo) {
            CustomTask compareToTask = (CustomTask)compareTo;
            //if Status value is not present in the map then give higher number. This will avoid null pointer exception
            Integer instanceValue = (sortOrder.containsKey(tsk.Status) == True) ? sortOrder.get(tsk.Status) : 999;
            Integer compareToValue = (sortOrder.containsKey(compareToTask.tsk.Status) == True) ? sortOrder.get(compareToTask.tsk.Status) : 999;
            return instanceValue - compareToValue;
        }
    }
}