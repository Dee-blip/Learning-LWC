/* ========================================================================
  *Template     : Apex Class
  *Version      : 1.0
  *@author      : Pranav Prashant @ Akamai Technologies Ltd.
  *Created Date : 18th March, 2018
  *Purpose      : Part of Test Data Factory Fremwork to
                  create dummy data for HD test classes

======================================================================== */


@isTest(seeAllData = false)
public class HD_ProblemTestDataFactory extends HD_Test_Data_Factory {
    public HD_ProblemTestDataFactory() {
        super();

    }

    public List<BMCServiceDesk__Problem__c> getProblemTestdata(integer countProblem) {
        List<BMCServiceDesk__Problem__c> plist  =  problemTestdata(countProblem);
        insert plist;
        return plist;
    }



    private static List<BMCServiceDesk__Problem__c> problemTestdata(integer countProblem) {
        List<BMCServiceDesk__Problem__c> problemList = new List<BMCServiceDesk__Problem__c>();
        String serId = (Id)HD_Test_Data_Factory.categoryMap.get('Access');
        for ( integer i = 1 ; i <= countProblem ; i++  ) {
            BMCServiceDesk__Problem__c problem = new BMCServiceDesk__Problem__c();
            problem.Title_Summary__c = 'Problem Managment Title ' + i;
            problem.Category_alias__c = serId;
            problem.BMCServiceDesk__Problem_Source__c = 'Event Trigger';
            problem.BMCServiceDesk__shortDescription__c = 'Test Data Description values ' + i;
            problem.Urgency_picklist__c = 'Severity 4';
            problemList.add( problem );
        }

        return problemList;
    }

    public  List<BMCServiceDesk__Problem__c> getProblemWithIncidentTest(List<BMCServiceDesk__Incident__c> incList, integer countProblem ) {
        List<BMCServiceDesk__Problem__c> problemList = problemTestdata(countProblem);
        for ( BMCServiceDesk__Problem__c prob : problemList ) {
            prob.Parent_Incident__c = incList[0].Id;
        }

        return problemList;
    }//


}