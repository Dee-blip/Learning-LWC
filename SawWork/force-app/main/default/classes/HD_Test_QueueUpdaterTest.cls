@IsTest(seeallData=false)
public class HD_Test_QueueUpdaterTest {
    static BMCServiceDesk__Incident__c testIncident;
    static Map<String,BMCServiceDesk__Status__c> statusListMap = new Map<String,BMCServiceDesk__Status__c>() ;
    static ID testCategory;
    static Group testQueue;
    static BMCServiceDesk__Incident__c testIncidentForResume;
    static BMCServiceDesk__Incident__c testIncidentForPendingStatus;

    static{
        HD_Incident_Settings__c customSet = new HD_Incident_Settings__c();
        customSet.name = 'Missing_Actions_Update';
        customSet.value__c = 'Email Sent' ;
        insert customSet;

        ManagedPkgErrorClass.isFromManagedPackage = false;
        HD_IncidentTestDataFactory  obj = new HD_IncidentTestDataFactory();
        testIncident = obj.getIncidentTestData(HD_IncidentTestDataFactory.Team.HR);

        //testQueue = [Select Id, Name from Group g where g.Id IN (SELECT QueueId FROM QueueSobject where SobjectType = 'BMCServiceDesk__Incident__c') and name like '%ITOC%' LIMIT 1];
        //testCategory = (ID)HD_Test_Data_Factory.categoryMap.get('Hardware');
        //testIncidentForResume = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        //testIncidentForPendingStatus = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);

    }


    static TestMethod void testQueueUpdater(){
        test.startTest();
        List<BMCServiceDesk__Incident__c> incList = [Select Id, OwnerId, Last_Owner__c, BMCServiceDesk__Status_ID__c,
                                                     BMCServiceDesk__Category_ID__c,
                                                     BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c,
                                                     HD_Owner_user_queue__c, HD_Routing_Settings__c  from
                                                     BMCServiceDesk__Incident__c where
                                                     (BMCServiceDesk__Status_ID__c ='UNASSIGNED' OR BMCServiceDesk__Status_ID__c ='REASSIGNED') and
                                                     HD_Owner_user_queue__c like '%Default Queue%' and
                                                     (BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c <> 'Q_HELPDESK_TRIAGE' and
                                                      BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c <> '' and
                                                      BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c <> true) and
                                                     BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT' LIMIT 10
                                                    ];
        BMCServicedesk__Incident__c incCreated = [select id, owner.name from BMCServiceDesk__Incident__c limit 1];
        List<ID> updatedIncidentIds = new List<Id>();
        for(BMCServicedesk__Incident__c inc : incList){
            updatedIncidentIds.add(inc.ID);

        }
        System.debug(incCreated);
        System.debug('size of list '+ updatedIncidentIds.size());
        HD_QueueUpdater queueUpdater = new HD_QueueUpdater();
        String Csec,Cmin,Chr1,Cday,Cmonth,CYear;

        Datetime  dt1 = System.now();
        Datetime  dt =  dt1.addDays(2);
        Cmin=String.valueof(dt.minute());
        Chr1=String.valueof(dt.hour());
        Cday=String.valueof(dt.day());
        Cmonth=String.valueof(dt.month());
        CYear=String.valueof(dt.Year());
        Csec=String.valueof(dt.addSeconds(8).second());
        String SchTimer=Csec+' '+Cmin+' '+Chr1+' '+Cday+' '+Cmonth+' ? '+CYear;

        String jobId = system.schedule('Queue Updater Test Job', SchTimer, queueUpdater);


        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        String q = 'Select Id,OwnerId from BMCServiceDesk__Incident__c where Id in :updatedIncidentIds';
        HD_BatchableQueueUpdater batch=new HD_BatchableQueueUpdater(q,updatedIncidentIds);
        System.assertEquals(SchTimer, ct.CronExpression);
        Database.executeBatch(batch, 10);

        test.stopTest();
        List<BMCServiceDesk__IncidentHistory__c>  incHist = [select id, name, BMCServiceDesk__actionId__c  from
                                                       BMCServiceDesk__IncidentHistory__c  where
                                                       BMCServiceDesk__FKIncident__c = :testIncident.Id
                                                       limit 5];
        System.assertEquals('ESCALATION_NOTE', incHist[0].BMCServiceDesk__actionId__c);



    }
}