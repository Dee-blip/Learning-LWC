/* ========================================================================
    *Template     : Apex Class
    *Version      : 1.0
    *@author      : Pranav Prashant @ Akamai Technologies Ltd.
    *Created Date : 18th March, 2018
    *Purpose      : Part of Test Data Factory Framework to
                    create dummy data for HD test classes

 ======================================================================== */



@isTest(seeAllData = false)
public class HD_IncidentTestDataFactory extends HD_Test_Data_Factory {

    public enum Team {CORPIT, EAEOPS, HR, GENERIC, RESTRICTEDACCESS, OPENTICKETASSIGNMENT}

    public BMCServiceDesk__Incident__c  getIncidentTestData(Team team) {
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc = getNewIncident(team);
        insert inc;
        return inc;
    }

    public BMCServiceDesk__Incident__c getNewIncident(Team team) {
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.BMCServiceDesk__FKImpact__c = impactMap.get('LOW');
        inc.BMCServiceDesk__FKUrgency__c = urgencyMap.get('Severity 4');
        inc.BMCServiceDesk__FKClient__c = System.UserInfo.getUserId();

        if (team == HD_IncidentTestDataFactory.Team.CORPIT) {
            inc.BMCServiceDesk__FKCategory__c = categoryMap.get('Hardware');

        } else if (team == HD_IncidentTestDataFactory.Team.EAEOPS) {
            inc.BMCServiceDesk__FKCategory__c = categoryMap.get('Access');
        } else if (team == HD_IncidentTestDataFactory.Team.RESTRICTEDACCESS) {
            inc.BMCServiceDesk__FKCategory__c = categoryMap.get('Restricted Area Access');
        }else if (team == HD_IncidentTestDataFactory.Team.HR) {
            inc.BMCServiceDesk__FKCategory__c = categoryMap.get('Compensation');
        } else if (team == HD_IncidentTestDataFactory.Team.OPENTICKETASSIGNMENT) {
            inc.BMCServiceDesk__FKCategory__c = categoryMap.get('OTA');
        }
        else {
            inc.BMCServiceDesk__FKCategory__c = categoryMap.get('P2R');
        }
        return inc;
    }


    public HD_IncidentTestDataFactory() {
        super();
    }
}