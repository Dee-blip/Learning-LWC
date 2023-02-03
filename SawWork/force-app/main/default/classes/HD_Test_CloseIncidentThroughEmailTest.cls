/*
* File Name: HD_Test_ChangeStatusScheduler
* Description : Test class for HD_ChangeRequestScheduler
* @author :
* Modification Log ===============================================================
* Date                      Author               Modification
* Oct 13th, 2021            Aneesh Budnar        PRTORES-977 - Fix Test class failures
*/
@IsTest(seeallData=False)
Private class HD_Test_CloseIncidentThroughEmailTest
{
    static BMCServiceDesk__Urgency__c urgency1;
    static BMCServiceDesk__Urgency__c urgency2;
    static BMCServiceDesk__Impact__c impactlow;


    Static TestMethod Void positiveTestMethod()
    {

     /*ManagedPkgErrorClass.isFromManagedPackage=false;
     BMCServiceDesk__Category__c category;
     //SHANDATT TEST 09152012, commented out the creation of accounts, 2 lines
     //Account account=new Account(Name='Akamai Helpdesk');
     //insert account;
     //urgency1=[select Id from BMCServiceDesk__Urgency__c where NAME = 'Severity 3' LIMIT 1];
     if(urgency1 == null)
     {
     urgency1 = new BMCServiceDesk__Urgency__c(Name='Severity 3');
     insert urgency1;
     }

     //urgency2 = [select Id from BMCServiceDesk__Urgency__c where NAME = 'Severity 4' LIMIT 1];
     if(urgency2 == null)
     {
     urgency2 =new BMCServiceDesk__Urgency__c(Name='Severity 4');
     insert urgency2;
     }
    //Create a new sample status
    BMCServiceDesk__Status__c sampleStatus =[select Id from BMCServiceDesk__Status__c where NAME = 'UNASSIGNED' LIMIT 1];
    if(sampleStatus == null)
    {
    sampleStatus=new BMCServiceDesk__Status__c(Name='UNASSIGNED', BMCServiceDesk__appliesToIncident__c = true, BMCServiceDesk__defaultStatus__c = true, BMCServiceDesk__state__c = false);
    insert sampleStatus;
    }
    system.AssertNotEquals(sampleStatus,Null);

    //creating sample impact
         impactlow =  [ select Id from BMCServiceDesk__Impact__c where NAME = 'LOW' LIMIT 1 ];
         if (impactlow == null)
         {
           impactlow = new BMCServiceDesk__Impact__c(Name='LOW');
           insert impactlow;
         }



    //Create a new sample category
    //BMCServiceDesk__Category__c category1 = [select Id from BMCServiceDesk__Category__c where NAME = 'Additional Desktop/Laptop' LIMIT 1];
    BMCServiceDesk__Category__c category1 = [Select Id, Name, BMCServiceDesk__parentTree__c from BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c = true and (NOT BMCServiceDesk__parentTree__c LIKE '%Corporate IT%') LIMIT 1];
    if(category1 == null)
    {
        category = new BMCServiceDesk__Category__c (NAME='Additional Desktop/Laptop');

        system.AssertNotEquals(category,Null);
    }
    else
    {
        category = category1;
    }


    //Create a new incident
    BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=category.id,BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__FKUrgency__c=urgency2.id,BMCServiceDesk__FKImpact__c = impactlow.Id );
    insert incident;

    //Get Name of the incident
    List<BMCServiceDesk__Incident__c> incidentList = new List<BMCServiceDesk__Incident__c>();
    incidentList = [Select Name from BMCServiceDesk__Incident__c where id=:incident.id];

        //update owner
        incidentList.get(0).OwnerId = System.UserInfo.getUserId();
        update incidentList;

*/

        //List<BMCServiceDesk__Incident__c> incidentList1 = new List<BMCServiceDesk__Incident__c>();
        //incidentList1 = [Select Name,BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where id=:incident.id];
        //System.debug('Status: '+incidentList1.get(0).BMCServiceDesk__FKStatus__c);


        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        BMCServiceDesk__Incident__c incident = obj.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);

        Test.startTest();
        System.runAs(new UserTestHelper.UserBuilder().buildAndSave()) {
            incident = [SELECT Name FROM BMCServiceDesk__Incident__c WHERE ID=:incident.Id];
            
            //@ 5th OCT, 2018, NIKHIL KARN, adding below line to fix validation error for code coverage
            incident.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
            incident.OwnerId=System.UserInfo.getUserId();
            
            UPDATE incident;
        }
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        System.debug('test'+incident.id);
        User user = [SELECT Email FROM User WHERE ID=:System.UserInfo.getUserId()];

        // setup the data for the email
        email.subject = 'incident#'+incident.Name+' close call';
        String mailbody ='Test'+system.today();
        email.PlainTextBody=mailbody;
        List<String> toAddressList = new List<String>();
        toAddressList.add('close_incident@2s51zbp72l2a4cmxrj2qq6z9whnwxo8pqpglk8s0yljvhefth4.z-je9dmaa.z.apex.sandbox.salesforce.com');
        email.toAddresses= toAddressList;

        envelope.fromAddress = user.Email;
        email.fromAddress= user.Email;

        // Call the email service class and test it with the data in the testMethod
        HD_CloseIncidentThroughEmail cIobject = new  HD_CloseIncidentThroughEmail();
       Messaging.InboundEmailResult result = cIobject.handleInboundEmail(email, envelope);


   // incidentList = [Select BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where id=:incident.id];


    //SHANDATT 09152012, how can the status be sample, the status is actually closed in this context
    //system.assertEquals(sampleStatus.id, incidentList[0].BMCServiceDesk__FKStatus__c);

    Test.stopTest();
    System.assertNotEquals(result, null);
    }
}