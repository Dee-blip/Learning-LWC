@isTest
public class ChannelMappingCronJobTest {
	//static User
    static User dmlUser = utilTestClass.getTestRunUser();

    //@testSetup
    static void setupMethod()
    {
    	System.runAs(dmlUser) {
	    	Account partnerAcc = utilTestClass.CreateAccount('__Test Partner Account');
	        partnerAcc.Partner_Type__c = 'ADS Partner';
	        partnerAcc.Partner_status__c = 'Partner';
	        insert partnerAcc;
	            
	        partnerAcc.IsPartner = true;
	        partnerAcc.IsPartnerCustom__c = true;
	        partnerAcc.Validation_Override__c=true;
	        update partnerAcc;
    	}
    }

    static testmethod void testChannelMappingCronJob(){
        
        System.runAs(dmlUser)
        {
            ChannelMappingCronJobTest.setupMethod();
            Test.StartTest();
            ChannelMappingCronJob cmcj = new ChannelMappingCronJob();
            Integer size = cmcj.executeCronJob();
            System.debug('Mayank, size:'+size);
            System.assertEquals(size,1);
            Test.stopTest();
        }
    }
}