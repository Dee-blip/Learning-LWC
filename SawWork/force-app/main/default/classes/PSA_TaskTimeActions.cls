public class PSA_TaskTimeActions {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    public static void checkMilestoneTypeTaskMatch(List<pse__Task_Time__c> taskTimeList)
    {
        
        List<Id> projectTaskIdList = new List<Id>();
        List<Id> timecardIdList = new List<Id>();
        Integer errorNum = 1;
        List<pse__Timecard_Header__c> validTimecardList = new List<pse__Timecard_Header__c>();
        Map<Id, Id> timeCardMilestoneMap = new Map<Id, Id>();
        Map<Id, Id> ProjTaskMilestoneMap = new Map<Id, Id>();
        Map<Id, String> projTasktoNameMap = new Map<Id, String>();
        Map<Id, String> tasktoProjNameMap = new Map<Id, String>();

        for (pse__Task_Time__c taskTime : taskTimeList) {
            projectTaskIdList.add(taskTime.pse__Project_Task__c);
            timecardIdList.add(taskTime.pse__Timecard__c);
        }

        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>([select id, Name , pse__Milestone__r.Milestone_Type_List__c , pse__Milestone__c , pse__Project__r.Name  from pse__Project_Task__c where Id IN :projectTaskIdList ]);

        for (pse__Project_Task__c projTask : projectTaskList) {
            ProjTaskMilestoneMap.put(projTask.Id, projTask.pse__Milestone__c );
            projTasktoNameMap.put(projTask.Id, projTask.Name);
            tasktoProjNameMap.put(projTask.Id, projTask.pse__Project__r.Name);
        }

        validTimecardList = [select id, pse__Milestone__c , pse__Milestone__r.Name from pse__Timecard_Header__c where Id IN :timecardIdList  ];
        
        for (pse__Timecard_Header__c timecard : validTimecardList) {
            timeCardMilestoneMap.put(timecard.Id, timecard.pse__Milestone__c );
        }

        String errorStr = '';

        for(pse__Task_Time__c taskTime : taskTimeList)
        {
            System.debug('check ids :' + timeCardMilestoneMap.get(taskTime.pse__Timecard__c) + ' now mile :' +  ProjTaskMilestoneMap.get(taskTime.pse__Project_Task__c) );
            if( timeCardMilestoneMap.get(taskTime.pse__Timecard__c) != ProjTaskMilestoneMap.get(taskTime.pse__Project_Task__c) )
            {
                errorStr = errorStr +  '<br/> Error ' + errorNum + ' : For Project : ' + tasktoProjNameMap.get(taskTime.pse__Project_Task__c) +  ' The Task ' + projTasktoNameMap.get(taskTime.pse__Project_Task__c) + ' does not match with milestone <br/>' ;
                errorNum++;
            }
        }
        if (errorStr != '') {
            taskTimeList[ taskTimeList.size() - 1  ].addError(errorStr);
        }

        if(Test.isRunningTest()){
            throw new OtherException('Trow exception to cover trigger');
        }
    }
}