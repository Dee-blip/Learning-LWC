/**
* ByPassAndLimitUtilsTest
* Author        Date        Description
* Ruchika Sharma  10/12/17  Created Class
                    SFDC-2130 : PSOR -- Refresh Job that links Contract to Account Header.
*/
@isTest
Public class ByPassAndLimitUtilsTest {

static{
        utilTestClass.insertCustomSettings();
    }

	private static testMethod void testByPassAndLimitUtils(){
	// code names
		string cls1 = 'OpportunityTriggerHandler';
		string mtd1 = 'OpportunityTriggerHandler.beforeInsertBeforeUpdateTrigger()';
		string trg1 = 'OpportunityTriggerGeneric';
		String trg2 = 'OpportunityShares';


		ByPassAndLimitUtils.startTest(cls1);
		system.assertEquals(true, ByPassAndLimitUtils.isTest(cls1));
		system.assertEquals(true, ByPassAndLimitUtils.isRegistered(cls1));

		// since it hasn't been executed the class should be executable able at least once
		system.assertEquals(true, ByPassAndLimitUtils.canRun(cls1));

		// same goes for sets
		system.assertEquals(true, ByPassAndLimitUtils.canRun(new Set<String>{cls1,'no_block'}));

		// DISABLE TRIGGER

		ByPassAndLimitUtils.disable(trg1);
		ByPassAndLimitUtils.disable(trg2);
		system.assertNotEquals(true, ByPassAndLimitUtils.canRun(new Set<String>{trg1,trg2}));
		system.assertEquals(true, ByPassAndLimitUtils.isDisabled(trg1));
		//check that opp trigger is not getting invoked.
		Test.startTest();
		Account acc=utilTestClass.CreateAccount('Test acc__1');
        insert acc;
		Opportunity opp = utilTestClass.CreateOpportunity('test bypass','1. Identify Need');
		opp.CloseDate = Date.today();
		opp.AccountId = acc.Id;
        opp.Deal_Type__c='Direct';
		insert opp;
		opp.Name='test bypass updated';
		update opp;
		// EXECUTE CLASS
		// Excute the class for the first time
		system.assertEquals(true, ByPassAndLimitUtils.run(cls1));
		system.assertEquals(true, ByPassAndLimitUtils.canRun(cls1));

		// to build the hierarchy, buildMethod needs to be executed 10, times
		// in order to reach 100% test coverage use register instead of inline defintion
		ByPassAndLimitUtils.doRegisteration(mtd1, 10);
		for(integer i = 0; i<10;i++){
		system.assertEquals(true, ByPassAndLimitUtils.run(mtd1));
		}
		system.assertEquals(false, ByPassAndLimitUtils.canRun(mtd1));

		// ENABLE & EXECUTE TRIGGER
		ByPassAndLimitUtils.enable(trg1);
		system.assertEquals(false,ByPassAndLimitUtils.isDisabled(trg1));

		system.assertEquals(true,ByPassAndLimitUtils.isFutureCallAvailable());

		ByPassAndLimitUtils.doRegisteration(new List<String>{mtd1,trg1},0);
		ByPassAndLimitUtils.disable(new List<String>{mtd1,trg1});
		system.assertEquals(true, ByPassAndLimitUtils.isDisabled(mtd1));

		ByPassAndLimitUtils.remainingCPUTime(mtd1);
		ByPassAndLimitUtils.remainingSOQLS(mtd1);
		ByPassAndLimitUtils.remainingHeapSize(mtd1);
		// Finsh the Test
		ByPassAndLimitUtils.stopTest(cls1);
		system.assertEquals(false,ByPassAndLimitUtils.isTest(cls1));
		Test.stopTest();
	}
	/*private static testMethod void testOpportunitySharesCoverage(){
		Opportunity opp = utilTestClass.CreateOpportunity('test OpportunityShares','1. Identify Need');
		opp.CloseDate = Date.today();
		UpdateDollarMRROnAllOLIBatchClass.nowRunningDataFix=true;
		insert opp;
	}*/

	private static testMethod void testOpportunitySharesCoverage2(){
		Opportunity opp = utilTestClass.CreateOpportunity('test OpportunityShares','1. Identify Need');
		opp.CloseDate = Date.today();
		OpportunityLineItemTriggerClass.churnFutureMethodFlag=true;
		insert opp;
	}

	private static testMethod void testOpportunitySharesCoverage3(){
		Opportunity opp = utilTestClass.CreateOpportunity('test OpportunityShares','1. Identify Need');
		opp.CloseDate = Date.today();
        // fixing compilation error
		L2Q_AccountTriggerClass.partnerInvolvedAndSetPartnerAuthorisedCountryFlag=true;
		insert opp;
	}

	private static testMethod void testOpportunitySharesCoverage4(){
		Opportunity opp = utilTestClass.CreateOpportunity('test OpportunityShares','1. Identify Need');
		opp.CloseDate = Date.today();
		L2Q_AccountTriggerClass.accountIdAndSetPartnerAuthorisedCountryFlag=true;
		insert opp;
	}

	private static testMethod void testOpportunitySharesCoverage5(){
		Map<String, String> objectToCustomSettingResource = new Map<String, String>();
		objectToCustomSettingResource.put('Configuration__c', 'CS_Object_Share_Settings');
		utilTestClass.insertCustomSettings(objectToCustomSettingResource);
		List<Account> accList = new List<Account>();
		Account acc=utilTestClass.CreateAccount('Test acc__1');
        //insert acc;
        accList.add(acc);
		Account Partneracc=utilTestClass.CreateAccount('Test Partneracc__1');
		//Partneracc.Partner_Type__c = 'Unknown';
        accList.add(Partneracc);
        insert accList;
        Partneracc.IsPartner=true;
        Partneracc.Validation_Override__c=true;
        Partneracc.Partner_Type__c='Unknown';
        update Partneracc;
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
        opp.CloseDate = Date.today().addMonths(4);
        opp.AccountId = acc.Id;
        opp.Deal_Type__c='Indirect';
        opp.Partner_Involved__c=Partneracc.id;
        insert opp;
        GroupSharingHelper.run = true;
        opp.stagename= '2. Explore Options';
        update opp;
        //List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,Partneracc.id);

    }

}