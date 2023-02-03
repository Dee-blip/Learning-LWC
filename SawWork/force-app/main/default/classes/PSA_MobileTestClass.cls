@isTest(seeAllData = false)
public class PSA_MobileTestClass
{
    static{
        createTestData();
    } 

        Public static PSA_TestUtility testUtil;
        Public static pse__Region__c reg;
        Public static Account acct;
        Public static Contact resource;
        Public static Contact resource1;
        Public static pse__Project_Methodology__c  product1;
        Public static pse__Proj__c proj1;
        Public static pse__Practice__c pract;
        Public static Id practId;
        Public static pse__Milestone__c milestone;
        Public static pse__Assignment__c assign;
        Public static User usr;
        Public static User usr2;
        Public static Merge_Contract_Header__c contract;
        Public static Merge_Contract_Detail__c contDetail;
        Public static Project_Contract__c projCont;
        Public static Project_Contract_Line_Item__c projContItem;
        Public static pse__Schedule__c sched;
        Public static pse__Permission_Control__c pc;
    
    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {
    	// if( SC_BOCC_Setup__c.getValues('BOCC') == null)
        // {
        //     SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        //     scSetting.Name = 'BOCC';
        //     scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        //     scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        //     scSetting.Product_Id__c = 'M-LC-160618';
        //     insert scSetting;
        // }
        
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        insert usr;
        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;


        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj1.pse__start_date__c = System.today().addDays(-10);
        proj1.pse__end_date__c = System.today().addDays(100);
        proj1.pse__Allow_Timecards_Without_Assignment__c = false;
        insert proj1;

        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today().addDays(-10), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today().addDays(-10), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        
        
    }
    
    Public static void createAdditionaldata()
    {
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(15));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);  
    }
    	 

	@isTest
	static void testApprovalController()
	{
		Test.startTest();
        createAdditionaldata();
			PSA_TimecardApprovalController.getAccess();
		    pse__Timecard_header__c timecard1;
		    System.runAs(usr)
		    {
			    resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
	            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
	            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
	            timecard1.pse__Billable__c = true;
	            timecard1.pse__Project_Methodology_Object__c = product1.Id;
	            timecard1.pse__Status__c = 'Submitted';
	            timecard1.pse__Submitted__c = true;
	            timecard1.pse__Monday_Hours__c = 1;
	            insert timecard1;
                
                

		    }
			String tc = timecard1.id;

			PSA_TimecardApprovalController.getTimecards(20,20,0,null,null);
			PSA_TimecardApprovalController.ApproveSelectedTC('Approve','Approved',tc,3);
        
        	/****** for parent project and batch job *****/
        
			pse__Proj__c proj2 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        	proj2.pse__Parent_Project__c = proj1.Id;
            proj2.pse__start_date__c = System.today().addDays(-10);
            proj2.pse__end_date__c = System.today().addDays(100);
            proj2.pse__Allow_Timecards_Without_Assignment__c = false;
            insert proj2;
        
        	pse__Proj__c proj3 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        	proj3.pse__Parent_Project__c = proj2.Id;
            proj3.pse__start_date__c = System.today().addDays(-10);
            proj3.pse__end_date__c = System.today().addDays(100);
            proj3.pse__Allow_Timecards_Without_Assignment__c = false;
            insert proj3;
        	
        	System.debug('Query of timecard that is approved :: ' + [select id, pse__Project__r.pse__Non_Billable_Internal_Hours__c , pse__Project__r.pse__Excluded_Hours__c, pse__project__r.Total_Billable_and_Non_Billable_Hours__c , pse__project__r.Total_Non_Billable_Hours__c ,pse__project__r.RecordtypeId, pse__project__c, pse__project__r.pse__Billable_Internal_Hours__c, pse__project__r.pse__Credited_Non_Billable_Internal_Hours__c, pse__Total_Hours__c, pse__Billable__c ,pse__Time_Credited__c,pse__Time_Excluded__c from pse__Timecard_Header__c where pse__status__c = 'Approved' and pse__Total_Hours__c != 0 and pse__Project__r.pse__stage__c != 'Closed' and pse__Project__r.pse__Allow_Timecards_Without_Assignment__c = false and pse__Project__r.pse__End_Date__c >= 2020-12-31  Order by pse__project__c]);
            PSA_Timecard_Approval__c stopApproval = PSA_Timecard_Approval__c.getOrgDefaults();
            stopApproval.Stop_Approval__c = false;
            upsert stopApproval;
        
        	
            
            PSA_CorrectActualsOnProjects_Batch actualsBatch = new PSA_CorrectActualsOnProjects_Batch();
            Database.executeBatch(actualsBatch);
        
        	PSA_ActualsOnProjects_Batch actualsBatch2 = new PSA_ActualsOnProjects_Batch();
            Database.executeBatch(actualsBatch2);

		Test.stopTest();	
	}
    
	@isTest
	static void testEntryController()
	{
		Test.startTest();
        createAdditionaldata();
			PSA_TimeEntryController.getAccess();
		    pse__Timecard_header__c timecard1;
		    System.runAs(usr)
		    {
			    resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
	            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);

	            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
	            timecard1.pse__Billable__c = true;
	            timecard1.pse__Project_Methodology_Object__c = product1.Id;
	            timecard1.pse__Status__c = 'Saved';
	            timecard1.pse__Monday_Hours__c = 1;
	            insert timecard1;
	            PSA_TimeEntryController.getAssignmentsTimecards(string.valueof(System.today().addDays(6)));
	            Map<String,Object> keyToValue = new Map<String,Object>();
	            keyToValue.put('pse__Resource__c',resource.Id);

	            keyToValue.put('pse__Project__c',String.valueOf(proj1.Id));
	            keyToValue.put('pse__Assignment__c',String.valueOf(assign.id));
	            keyToValue.put('pse__Milestone__c',String.valueOf(milestone.Id));
	            keyToValue.put('pse__Billable__c',true);
	            keyToValue.put('pse__Project_Methodology_Object__c',String.valueOf(product1.Id));
	            keyToValue.put('pse__Status__c','Saved');
	            keyToValue.put('pse__Monday_Hours__c',1);
	            keyToValue.put('Id',String.valueOf(timecard1.Id));

 
 	            Map<String,Map<String,Object>> a = new Map<String,Map<String,Object>>();
	            a.put('1',keyToValue);
	            String b = PSA_TimeEntryController.encodeBase64(JSON.serialize(a));
	         	PSA_TimeEntryController.saveSubmitTimecards(b,'Submit',2,string.valueof(System.today().addDays(6)));
	            

	            Map<String,String> c = new Map<String,String>();
	            c.put('1',timecard1.id);
	            String d = PSA_TimeEntryController.encodeBase64(JSON.serialize(c));

	            PSA_TimeEntryController.recallTimecards(d,'Recall',2,string.valueof(System.today().addDays(6)));
	            PSA_TimeEntryController.getTimecardsPreviousWeek(string.valueof(System.today().addDays(6)),true,true,true,true);
				//System.assertEquals(yy,null);	            
				 //PSA_TimeEntryController.deleteTimecards(d,'Delete',2,string.valueof(System.today().addDays(6)));
		    }
					
		Test.stopTest();	
	}
	@isTest
	static void testEntryController2()
	{
		Test.startTest();
        createAdditionaldata();
		    pse__Timecard_header__c timecard1;
		    System.runAs(usr)
		    {
			    resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
	            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);

	            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
	            timecard1.pse__Billable__c = true;
	            timecard1.pse__Project_Methodology_Object__c = product1.Id;
	            timecard1.pse__Status__c = 'Submitted';
	            timecard1.pse__Monday_Hours__c = 1;
	            insert timecard1;
	            Map<String,String> c = new Map<String,String>();
	            c.put('1',timecard1.id);
	            String d = PSA_TimeEntryController.encodeBase64(JSON.serialize(c));
                
            
				PSA_TimeEntryController.deleteTimecards(d,'Delete',2,string.valueof(System.today().addDays(6)));

			}
				test.stopTest();
	}
}