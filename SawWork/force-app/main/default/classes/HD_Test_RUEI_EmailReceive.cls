@isTest(SeeAllData=false)
public class HD_Test_RUEI_EmailReceive {


    static{

        HD_IncidentTestDataFactory rfFactory =  new HD_IncidentTestDataFactory();
        BMCServiceDesk__Incident__c testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);

    }
    @isTest(SeeAllData=false) public static void ruei_alert_test_positive_method()
    {

        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        email.subject = 'Test';
        email.plainTextBody = 'Test email body';
        //DoNotReply@akamai.com
        HD_RUEI_EmailReceive_addr__c cs = new HD_RUEI_EmailReceive_addr__c();
        cs.Name = 'rueifromaddr';
        cs.emailid__c = 'nmurthy@akamai.com';

        HD_RUEI_EmailReceive_addr__c cs1 = new HD_RUEI_EmailReceive_addr__c();
        cs1.Name = 'siebelruei';
        cs1.emailid__c = 'nmurthy@akamai.com';
        if(HD_RUEI_EmailReceive_addr__c.getInstance('rueifromaddr')==null)
        {
            insert(cs);

        }
        if(HD_RUEI_EmailReceive_addr__c.getInstance('siebelruei')==null)
        {
            insert(cs1);

        }

        HD_RUEI_EmailReceive_addr__c rueifromaddr=HD_RUEI_EmailReceive_addr__c.getInstance('rueifromaddr');
        email.fromAddress = rueifromaddr.emailid__c;

        HD_RUEI_EmailReceive ruei = new HD_RUEI_EmailReceive();

        Test.startTest();
        System.debug('Debug HD_Test_RUEI_EmailReceive: '+email+'----'+envelope);
        Messaging.InboundEmailResult result = ruei.handleInboundEmail(email, envelope);
        System.debug('Debug HD_Test_RUEI_EmailReceive: '+result);
        //System.assertEquals( true, result.success );
        Test.stopTest();
    }
    //public  static testMethod void ruei_alert_test_negative_method()
    //{
    //    Messaging.InboundEmail email  = new Messaging.InboundEmail();
    //    Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
    //    HD_RUEI_EmailReceive ruei = new HD_RUEI_EmailReceive();
    //    Test.startTest();
    //    Messaging.InboundEmailResult result = ruei.handleInboundEmail(email, envelope);
    //    System.assertEquals( false, result.success );
    //    Test.stopTest();

    //}

}