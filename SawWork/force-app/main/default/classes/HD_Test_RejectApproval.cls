/*
* File Name: HD_Test_RejectApproval
* Description : Test class for HD_RejectApproval
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Aug 08th, 2020    Aneesh Budnar           PRTORES-1810 - Code scanner fixes
*/
@isTest(SeeAllData=false)
public class HD_Test_RejectApproval {
    //Global variable
    private static Map<String,String> urgencymap = new Map<String,String>();
    private static Map<String,String> impactmap = new Map<String,String>();
    private static Map<String,String> cattypemap = new Map<String,String>();
    private static Map<String,String> parent_category = new Map<String,String>();
    private static Map<String,String> child_category = new Map<String,String>();
    private static Map<String,String> stagemap = new Map<String,String>();
    private static Map<String,String> statusmap = new Map<String,String>();
    private static HD_IncidentTestDataFactory rfFactory;
    private static BMCServiceDesk__Incident__c testIncident =  new BMCServiceDesk__Incident__c();
    static{
        ManagedPkgErrorClass.isFromManagedPackage = false;
        rfFactory =  new HD_IncidentTestDataFactory();
        testIncident = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);


    }//static

    //select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'APPROVAL_INFO'


    @isTest public static void InValidUserTest() {
        Boolean tr = true;
        Profile p = [SELECT Id FROM Profile WHERE Name='ServiceDesk Staff'];//ServiceDesk Staff
        User u1 = [Select id, managerId from User where IsActive= :tr and ProfileId = :p.Id and
        email like '%@akamai.com' and managerId != null Limit 1
        ];
        Id sysAdminId = System.UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKClient__c = u1.id;
        System.debug(HD_Test_Data_Factory.priorityMap);
        System.assertEquals(true,HD_Test_Data_Factory.priorityMap.size()>1);
        testIncident.HD_Ticket_Priority__c='4';
        System.debug('incident debug mode');
        System.debug(testIncident);
        insert testIncident;
            System.runAs(u1){

            /*List<BMCServiceDesk__CategoryTypes__c>  catTypes = [Select Id, Name from BMCServiceDesk__CategoryTypes__c where Name ='Q_EAE_OPS' LIMIT 1];
            Id catTypeId = catTypes.get(0).Id;
            BMCServiceDesk__Category__c testCat = new BMCServiceDesk__Category__c(Name = 'Test Category', BMCServiceDesk__AvailableForIncidents__c = true, BMCServiceDesk__FKCategoryType__c = catTypeId);
            insert testCat;
            Id catId = testCat.Id;
            //List<BMCServiceDesk__Category__c> category = [Select Id, Name from BMCServiceDesk__Category__c where Name = 'Contract Management'];
            //Id catId = category.get(0).Id;
            BMCServiceDesk__Incident__c incident1 = new BMCServiceDesk__Incident__c(bmcservicedesk__fkcategory__c =catId, HD_Ticket_Priority__c  = '3', BMCServiceDesk__FKUrgency__c = urgencymap.get('Severity 3'), BMCServiceDesk__FKImpact__c = impactmap.get('LOW'), BMCServiceDesk__FKClient__c  = u1.Id);
            incident1.BMCServiceDesk__FKClient__c = sysAdminId;
            incident1.OwnerId = sysAdminId;
            insert incident1;*/
            List<BMCServiceDesk__Incident__c> incidentList = [Select Id, Name, OwnerId from BMCServiceDesk__Incident__c LIMIT 1];
            //List<BMCServiceDesk__Incident__c> incidentList = [Select Id, Name, OwnerId from BMCServiceDesk__Incident__c where BMCServiceDesk__FKCategory__c =: catId];
            final String queueId = incidentList.get(0).OwnerId;
            System.debug('priniting q id : '+ queueId);

            BMCServiceDesk__Incident__c incident=incidentList.get(0);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(incident.id);
            req1.setSubmitterId(sysAdminId);
            req1.setProcessDefinitionNameOrId('TACACS_GROUP_MEMBERSHIP_APPROVAL');

            req1.setSkipEntryCriteria(true);
            System.debug('req1: '+req1);
            Approval.ProcessResult result;

            result = Approval.process(req1);


            System.assert(result.isSuccess());
            //System.assertEquals(String.valueof(incident.Approver__c), String.valueof(u1.managerId));
            //gm.GroupId = incident.ownerId;
            Test.startTest();
            incident=incidentList.get(0);
            String validUser = HD_RejectApproval.rejectApproval(incident.id);
            System.assertEquals('E02',validUser);

            //
            Test.stopTest();
            }//System.runAs(u1)

    }//static testMethod void InValidUserTest()




    @isTest public static void ValidUserTest() {
        Boolean tr = true;
        BMCServiceDesk__Incident__c temp;
        Profile p = [SELECT Id FROM Profile WHERE Name='ServiceDesk Staff'];//ServiceDesk Staff
        User u1 = [Select id, managerId from User where IsActive= :tr and ProfileId = :p.Id and
        email like '%@akamai.com' and managerId != null Limit 1
        ];
        Id sysAdminId = System.UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKClient__c = u1.id;
        System.debug(HD_Test_Data_Factory.priorityMap);
        System.assertEquals(true,HD_Test_Data_Factory.priorityMap.size()>1);
        testIncident.HD_Ticket_Priority__c='4';
        System.debug('incident debug mode');
        System.debug(testIncident);
        insert testIncident;
        System.runAs(u1){
            /*List<BMCServiceDesk__CategoryTypes__c>  catTypes = [Select Id, Name from BMCServiceDesk__CategoryTypes__c where Name ='Q_EAE_OPS' LIMIT 1];
            Id catTypeId = catTypes.get(0).Id;
            BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c(Name = 'Test cat', BMCServiceDesk__AvailableForIncidents__c =true, BMCServiceDesk__FKCategoryType__c = catTypeId);
            insert cat;
            Id catId = cat.Id;
            BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c(HD_Ticket_Priority__c = '3',  BMCServiceDesk__FKCategory__c = catId, BMCServiceDesk__FKUrgency__c = urgencymap.get('Severity 3'), BMCServiceDesk__FKImpact__c = impactmap.get('LOW'), BMCServiceDesk__FKClient__c = u1.id );
            incident.BMCServiceDesk__FKClient__c = sysAdminId;
            insert incident;
            System.debug('_____________________> ' + incident);
            System.debug('printihn =============> + ' +incident.ownerId );*/
            temp = [select id, ownerId, name from BMCServiceDesk__Incident__c LIMIT 1];
            System.debug('printihn temp 1=============> + ' +temp.ownerId );
         }//end sytem run as u1

         List<GroupMember> members = [Select UserOrGroupId From GroupMember where GroupId =: temp.ownerId];
         List<Id> userIds = new List<Id>();
        for(GroupMember member : members){
            userIds.add(member.UserOrGroupId);
        }
        User activeMemeber = [Select id from User where id in :userIds and IsActive = true limit 1];

         System.runAs(activeMemeber){
            System.debug('user : '+ u1.id + 'queeu ' + temp.ownerId);
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(temp.id);
            req1.setSubmitterId(sysAdminId);
            req1.setProcessDefinitionNameOrId('TACACS_GROUP_MEMBERSHIP_APPROVAL');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result;
            result = Approval.process(req1);
            System.assert(result.isSuccess());

            Test.startTest();

            String validUser = HD_RejectApproval.rejectApproval(temp.id);
            System.assertEquals('SUCCESS',validUser);

            Test.stopTest();
        }//system.runAs(activeMemeber)

    }//static testMethod void cloneIncidentToProblemTest()
}//END OF CLASS