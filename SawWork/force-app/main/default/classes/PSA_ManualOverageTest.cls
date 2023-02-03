@isTest(SeeAllData=false)
public class PSA_ManualOverageTest {
    static
    {
        createTestData();
    }
    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;

    Public static pse__Proj__c proj1;
    Public static pse__Practice__c pract;
    Public static pse__Grp__c grp;
    Public static Id practId;
    Public static pse__Milestone__c milestone;
    Public static User usr;
    Public static User usr2;
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetailCommitted;
    Public static Merge_Contract_Detail__c contDetailOverage;
    Public static pse__Permission_Control__c pc;
    Public static Id gssId;
	Public static Id financeId;
    Public static Id gssOpsId;
	Public static PS_Overage_Hours__c overageRec;
	Public static PS_Overage_Schedule__c sched;

    Public static void createTestData()
    {

        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        
        // insert scSetting;
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
		
		for (Profile profileRec  :[Select id, name from Profile where name in ('GSS Professional Services','Finance', 'GSS Operations')])
		{
            //20.2 changed from GSS Professional Services to GSS Operations
			if(profileRec.name =='GSS Professional Services')
			{
				gssId = profileRec.Id;
			}
			else if (profileRec.name =='Finance')
			{
				financeId = profileRec.Id;
			}
            else if(profileRec.name =='GSS Operations')
            {
                gssOpsId = profileRec.Id;
            }
		}
		

        usr2 = testUtil.newUserSysAdmin(false);
		usr2.profileId = gssOpsId;
        usr2.UserName = '678' + usr2.UserName;
		usr2.title = 'Manager..Service Line';
		usr2.Cost_Center__c = 50620.0;
		insert usr2;

        usr = testUtil.newUserSysAdmin(false); 
		usr.profileId = gssId;
        usr.UserName = '134'+ usr.UserName;
		usr.title = 'Manager..Service Line';
        usr.ManagerId = usr2.id;
        usr.DelegatedApproverId = usr2.id;
        usr.PS_Out_of_Office__c = true;		        
        insert usr;
        

        System.runAs(usr)
        {
        	acct = testUtil.newAccount(true);
            System.debug('acct from PSA Manual testclass  : '+ acct);
            System.debug('acct from PSA Manual testclass  : '+ acct.AKAM_Account_ID__c);
        }

        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;
        
        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        

        contract = testUtil.newContract(false, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contract.CI_Account_Name__c = acct.AKAM_Account_ID__c;
        insert contract;
 
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        contDetailCommitted = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetailCommitted.Record_Type__c = 'Committed';
        contDetailCommitted.Billing_Duration__c = 'Monthly';
        contDetailCommitted.Product_Id__c = 'M-LC-160618';
        contDetailCommitted.Units_Low__c = 30;
        contDetailCommitted.Product__c = 'Test1';
        contDetailCommitted.Unit_of_Measure__c = 'Hour';
        contDetailCommitted.Product_Id__c = 'tets1';
		details.add(contDetailCommitted);
        
        contDetailOverage = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetailOverage.Record_Type__c = 'Overage';
        contDetailOverage.Billing_Duration__c = 'Monthly';
        contDetailOverage.Product_Id__c = 'M-LC-160618';
        contDetailOverage.Units_Low__c = 30;
        contDetailOverage.Product__c = 'Test1';
        contDetailOverage.Unit_of_Measure__c = 'Hour';
        contDetailOverage.Product_Id__c = 'tets1';
        details.add(contDetailOverage);

        insert details;

        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 

		Set<Date> holidays = new Set<Date>();			

		Date firstDate = Date.today().addMonths(1).toStartOfMonth();
		Date secondDate = firstDate.addMonths(1);
		Date firstReminderDate;

		sched = new PS_Overage_Schedule__c();
		sched.Number_of_Mails_Sent__c  = 0;

		firstReminderDate = PSA_OverageController.addBusinessDays(firstDate, 1,holidays);                        
		sched.Reminder_Mail_Date__c = PSA_OverageController.convertToESTCutOff(firstReminderDate, 12);
		 
		firstReminderDate = PSA_OverageController.addBusinessDays(firstDate, 3,holidays);                        
		sched.Lock_Date__c  = PSA_OverageController.convertToESTCutOff(firstReminderDate, 17);

		sched.Send_File_to_CMG__c = false;

		insert sched;    
		
		String recordTypeId = Schema.getGlobalDescribe().get('PS_overage_Hours__c').getDescribe().getRecordTypeInfosByName().get('Manual').getRecordTypeId();					
		overageRec = new PS_Overage_Hours__c();
		overageRec.End_Customer_Name__c = acct.Id;
		overageRec.Project_ID__c = proj1.id;
        overageRec.Original_Contract_Id__c = contract.Id;
		overageRec.Original_Detail_ID__c = contDetailOverage.id;
		overageRec.To_be_Billed_Hours__c = 12;
		overageRec.Billing_Period_End_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(10);
		overageRec.Billing_Period_Start_Date__c = Date.today().addMonths(-1).toStartOfMonth();
		overageRec.Justification__c = 'Test';
		overageRec.recordTypeId = recordTypeId;
		overageRec.Validation_Override__c = true;
        
    }

    @isTest public static void queueableJobCoverage()
	{
		System.runAs(usr)
		{
			insert overageRec;
            overageRec.Automated_Overage__c = true;
            overageRec.Overage_Action__c = 'Bill';
            overageRec.Overage_Hours__c  = 100; 
            overageRec.To_be_Billed_Hours__c = 90;
            PSA_OverageController.checkRecursion = false;
            PSA_OverageController.checkRecursionPost = false;
            
            overageRec.Overage_Lock_Date__c = Datetime.now();
            overageRec.Trigger_Sign_Off__c = true;
            
            List<PS_Overage_Hours__c> overagesToUpdateList = new List<PS_Overage_Hours__c>();
            overagesToUpdateList.add(overageRec);
            Test.startTest();
            System.enqueueJob(new PSA_OveragesSuccessRecordUpdate(overagesToUpdateList));
            Test.stopTest();
		}
		

	}

    @isTest public static void testManualOverage()
    {

			Test.startTest();

				
				System.runAs(usr)
				{
					insert overageRec;
					
					List<PS_Overage_Hours__c> overages = new List<PS_Overage_Hours__c>();
			  		overages.add(overageRec);

			  		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(overages);
			  		stdSetController.setSelected(overages);
			  		PSA_OverageController controller = new PSA_OverageController(stdSetController);					

			        PSA_OverageController.checkRecursion = false;
			        PSA_OverageController.checkRecursionPost = false;

			  		controller.bulkSignOffOverage();

				}

				System.runAs(usr2)
				{
			        PSA_OverageController.checkRecursion = false;
			        PSA_OverageController.checkRecursionPost = false;

					overageRec.Trigger_Sign_Off__c = true;

					update overageRec;
 				}

 				PSA_OverageController.sendFileToCMG(true);

			Test.stopTest();

			 

    }
	
	@isTest public static void testSignOff()
    {
    	    Test.startTest();  
			
				System.runAs(usr)
				{
					insert overageRec;
					overageRec.Automated_Overage__c = true;
					overageRec.Overage_Action__c = 'Bill';
                    overageRec.Overage_Hours__c  = 100; 
                    overageRec.To_be_Billed_Hours__c = 90;
			        PSA_OverageController.checkRecursion = false;
			        PSA_OverageController.checkRecursionPost = false;

                    overageRec.Overage_Lock_Date__c = Datetime.now();
					overageRec.Trigger_Sign_Off__c = true;

					update overageRec;
					 					
				}


				sched.Number_of_Mails_Sent__c++;
				update sched;

				sched.Send_File_to_CMG__c = true;
				update sched;

				sched.Finance_Reminder__c = true;
				update sched;


			Test.stopTest();
    }


	@isTest public static void testSignOffError()
    {
    	    Test.startTest();  
			
				System.runAs(usr)
				{
					insert overageRec;
			        PSA_OverageController.checkRecursion = false;
			        PSA_OverageController.checkRecursionPost = false;

					overageRec.Trigger_Sign_Off__c = true;

					update overageRec;
					 					
				}
				try
				{
			        PSA_OverageController.checkRecursion = false;
			        PSA_OverageController.checkRecursionPost = false;

					overageRec.Trigger_Sign_Off__c = true;

					update overageRec;

				}
				catch(Exception e)
				{

				}

			Test.stopTest();
    }
	@isTest public static void testCLIlink()
    {
    	    Test.startTest();  
			    Project_Contract__c projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        		testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetailCommitted.Id, projCont.Id);
	
				System.runAs(usr)
				{
                    overageRec.Original_Detail_ID__c = null;
					insert overageRec;
					 					
				}
        		List<String> projids = new List<String>();
        		projids.add(proj1.Id);        		
        		PSA_OverageController.getCLILinkedToProject(JSON.serialize(projids));
			Test.stopTest();
    }

}