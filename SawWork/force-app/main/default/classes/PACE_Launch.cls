public class PACE_Launch extends PACE_Phase {

    public static Id launchPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Launch').getRecordTypeId();


    public static List<PACE_Phase__c> getLaunchList(List<PACE_Phase__c> pList)
    { 
        List<PACE_Phase__c> launchList = new List<PACE_Phase__c>();
        for (PACE_Phase__c launchRecord: pList) 
        {
            if(launchRecord.RecordType.Name=='PACE_Launch')
            {
                launchList.add(launchRecord);
            }
        }
        return launchList;
    }

    public static PACE_Phase__c initialize(PACE_Program__c program){

        PACE_Phase__c launch = new PACE_Phase__c();
        launch.Name = program.Name + ' - Launch';
        launch.PACE_Program__c = program.Id;
        launch.RecordTypeId = launchPhaseRecordTypeId;
        /*launch.Actual_End_Date__c = program.Launch_Actual_End_Date__c;
        launch.Actual_Start_Date__c = program.Launch_Actual_Start_Date__c;
        launch.Planned_End_Date__c = program.Launch_Planned_End_Date__c;
        launch.Planned_Start_Date__c = program.Launch_Planned_Start_Date__c;
        launch.Phase_Contract_Tolerance_Date__c = program.Launch_Phase_Contract_Tolerance_Date__c;
        launch.Exception_Review_Date__c = program.Launch_Exception_Review_Date__c;
        launch.PRB_Review_Date__c = program.Launch_PRB_Review_Date__c;*/

        return launch;
    }


    public static PACE_Phase__c setValuesForUpdate(Id phaseId, PACE_Program__c program){

        PACE_Phase__c launch = new PACE_Phase__c(Id = phaseId);
        /*launch.Actual_End_Date__c = program.Launch_Actual_End_Date__c;
        launch.Actual_Start_Date__c = program.Launch_Actual_Start_Date__c;
        launch.Planned_End_Date__c = program.Launch_Planned_End_Date__c;
        launch.Planned_Start_Date__c = program.Launch_Planned_Start_Date__c;
        launch.Phase_Contract_Tolerance_Date__c = program.Launch_Phase_Contract_Tolerance_Date__c;
        launch.Exception_Review_Date__c = program.Launch_Exception_Review_Date__c;
        launch.PRB_Review_Date__c = program.Launch_PRB_Review_Date__c;*/
        return launch;


    }

    public static List<PACE_Step__c> initializeLaunchSteps(PACE_Phase__c self){
        Integer  counter = 0;
        List<PACE_StepDefinition__c> refList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Launch' order by Position__c];
        List<PACE_Step__c> launchSteps = new List<PACE_Step__c>();
        for (PACE_StepDefinition__c defnStep: refList) {
            counter++;
            launchSteps.add(PACE_Step.initialize(self,'4.'+counter+' '+defnStep.Name, Integer.valueOf(defnStep.Position__c)));
        }

        return launchSteps;     

    }

    public static List<PACE_Step__c> initializeLaunchSteps(PACE_Phase__c self,List<PACE_StepDefinition__c> refList){
        Integer  counter = 0;
        List<PACE_Step__c> launchSteps = new List<PACE_Step__c>();
        for (PACE_StepDefinition__c defnStep: refList) {
            counter++;
            launchSteps.add(PACE_Step.initialize(self,'4.'+counter+' '+defnStep.Name, Integer.valueOf(defnStep.Position__c)));
        }

        return launchSteps;     

    }

}