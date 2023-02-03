/*=====================================================================================================+
|   Class Name : SC_NextCaseUpdateDueDateController
|   Test Class : SC_NextCaseUpdateDueDateController_Test
|  HISTORY  |                                                                            
|  DATE           DEVELOPER     CR        DESCRIPTION                                                       
|  ===========    =========   =======     ===========                                                        
|  21-Jan-2016    Deepak      3249741     Controller Class for SC_NextCaseUpdateDueDate
|  22 April 2020  Sharath     ESESP-1342  Added Isclassic property

+=====================================================================================================*/
public with sharing class SC_NextCaseUpdateDueDateController {
    public String NextUpdateTime{get;set;}
    //Changes by Sharath: checking for Classic theme
    public boolean isClassic{
    get
    {
    return (UserInfo.getUiThemeDisplayed() == 'Theme3');
    }
    set;
    }
    public SC_NextCaseUpdateDueDateController(ApexPages.StandardController controller) {
        Case c = (Case)controller.getRecord();
        c = [Select Override_Next_Case_Update__c From Case Where Id = :c.Id];
        if(c.Override_Next_Case_Update__c != null)
        {
            NextUpdateTime = c.Override_Next_Case_Update__c.format();
        
        }
        else
        {
            //List<MilestoneType> milestoneTypeList = [Select Id From MilestoneType WHere Name = 'Case Update'];
            List<CaseMilestone> caseMilestoneList = new List<CaseMilestone>();
            //if(milestoneTypeList.size() > 0)
                caseMilestoneList = [Select TargetDate From CaseMilestone Where CaseId = :c.Id AND MilestoneType.Name = 'Case Update' AND ISCompleted = False Order By TargetDate];
            if(caseMilestoneList.size() > 0)
                NextUpdateTime = caseMilestoneList[0].TargetDate.format();
        }
        
    }

}