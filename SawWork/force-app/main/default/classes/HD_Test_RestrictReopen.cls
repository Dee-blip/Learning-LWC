/*
* File Name: HD_Test_RestrictReopen
* Description : Test class for HD_RestrictReopen
* @author : 
* Modification Log ===============================================================
* Date              Author              Modification
* 5 Aug, 2020       Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5 
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1811 - Code Scanner part 5 fixes
*/
@isTest(seeAllData = false)
public class HD_Test_RestrictReopen {
    //COMMENT

    public static List<BMCServiceDesk__Incident__c> incidentList;
    public static BMCServiceDesk__Urgency__c urgency;
    public static BMCServiceDesk__Category__c category;
    public static BMCServiceDesk__Impact__c impact;
    public static Map<Id, User> userMap;
    public static Map<String, Group> groupMap ;
    public static Map<String, Id> statusMap;
    public static Id currentUser; 

    static{

        HD_IncidentTestDataFactory rfFactory =  new HD_IncidentTestDataFactory();
        BMCServiceDesk__Incident__c testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
        System.debug('logging incident from test data nikhil'+testIncident);

        category = [select id, name, BMCServiceDesk__parentTree__c, BMCServiceDesk__AvailableForIncidents__c, BMCServiceDesk__inactive__c from BMCServiceDesk__category__c limit 1 ];
        category.BMCServiceDesk__parentTree__c='Corporate IT';
        category.BMCServiceDesk__AvailableForIncidents__c=true;
        category.BMCServiceDesk__inactive__c=false;
        update category;
    }

    static {
        currentUser = (Id)system.userinfo.getUserId();
        incidentList = new List<BMCServiceDesk__Incident__c>();
        urgency = [select id from BMCServiceDesk__Urgency__c where name = 'Severity 2' limit 1];
        category = [select id, name, BMCServiceDesk__parentTree__c, BMCServiceDesk__AvailableForIncidents__c, BMCServiceDesk__inactive__c from BMCServiceDesk__category__c  where BMCServiceDesk__AvailableForIncidents__c = true  and BMCServiceDesk__inactive__c = false and  BMCServiceDesk__parentTree__c like '%Corporate%' limit 1 ];

        impact = [select id, name from BMCServiceDesk__Impact__c where name = 'LOW'];
        userMap = new Map<Id, User>([select id, name from user where isactive = true LIMIT 44000]);
        //Test Incident
        groupMap = new Map<String, Group>([Select id, name from group where name = 'VIP Users' OR Type = 'Queue' LIMIT 5000]);
        statusMap = HD_Test_RestrictReopen.createStatusMap();
    }

    static Map<String, Id> createStatusMap() {
        List<BMCServiceDesk__Status__c> statusList = [select id, name from BMCServiceDesk__Status__c limit 500];
        Map<String, Id> stMap = new Map<String, Id>();
        for (BMCServiceDesk__Status__c status : statusList) {
            stMap.put(status.name, status.id);
        }
        return stMap;
    }


    static Testmethod void checkInstanceNotNull() {

        BMCServiceDesk__Incident__c testIncident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKClient__c = currentUser, BMCServiceDesk__FKUrgency__c = urgency.id, BMCServiceDesk__FKCategory__c = category.id, BMCServiceDesk__FKImpact__c = impact.id);
        incidentList.add(testIncident1);
        insert incidentList;
        Test.startTest();
        HD_RestrictReopen instance = HD_RestrictReopen.getInstance(incidentList, incidentList, groupMap, userMap);
        System.assertNotEquals(null, instance);
        Test.stopTest();
    }

    static TestMethod void checkBeforeUpdateChanges() {

        BMCServiceDesk__Incident__c temp = new BMCServiceDesk__Incident__c();
        ID tempId = null;
        BMCServiceDesk__Incident__c testIncident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKClient__c = currentUser, BMCServiceDesk__FKUrgency__c = urgency.id, BMCServiceDesk__FKCategory__c = category.id, BMCServiceDesk__FKImpact__c = impact.id, BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED'), BMCServiceDesk__incidentResolution__c = 'closed');
        BMCServiceDesk__Incident__c testIncident2 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKClient__c = currentUser, BMCServiceDesk__FKUrgency__c = urgency.id, BMCServiceDesk__FKCategory__c = category.id, BMCServiceDesk__FKImpact__c = impact.id, BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED'), BMCServiceDesk__incidentResolution__c = 'closed');
        incidentList.add(testIncident1);
        incidentList.add(testIncident2);
        insert incidentList;
        temp.id = incidentList[1].id;
        temp.OwnerId = [SELECT Id FROM User WHERE UserName like '%abudnar@akamai.com%' LIMIT 1].Id;
        temp.BMCServiceDesk__FKStatus__c = statusMap.get('CANCELED');
        temp.Effort_Estimation__c = '01:11';
        temp.BMCServiceDesk__incidentResolution__c = 'CANCELED';
        System.debug('before update ' + [select BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where id = :temp.id].BMCServiceDesk__FKStatus__c);
        update temp;
        System.debug('after update ' + [select BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where id = :temp.id].BMCServiceDesk__FKStatus__c);
        Test.startTest();
        tempId = temp.id;
        temp  = new BMCServiceDesk__Incident__c();
        temp.id = tempId;
        temp.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED');

        ManagedPkgErrorClass.isFromManagedPackage = false;
        update temp;
        ManagedPkgErrorClass.isFromManagedPackage = true;

        Test.stopTest();

    }



}