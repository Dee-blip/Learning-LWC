/*
Author          :  Pinkesh
Description     :  Test class for SOCC Car RunBooks

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh                              SOCC CAR 2 - RunBooks 
17 Dec 2020         Tejaswini                   ESESP-3732      Changed few methods signatures
17 Feb 2021         Tejaswini                   ESESP-4822      Changed few methods signatures and Increasing Code coverage
------------------------------------------------------------------------------------------------------------------
*/
@isTest(seeAllData=false)
public class SC_SOCC_Instruction_Manager_TC {
    @testSetup
    static void setupMethod(){
        utilTestClass.createCustomSettings();
        
        Profile pr = [select id from profile where name='SFCommunityCustomers'][0];
        
        // Creating Account Records
        Account accRec = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111');
        insert accRec;
        
        //Creating Community
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c='.akamai';
        cs.Communities_User_Account_Id__c=accRec.id;
        cs.Name='Community';
        cs.Self_Registration_Community_Profile_Id__c=pr.id;
        insert cs;
        
        //Create contact
        Contact conRec = new Contact(AccountId=accRec.Id, Login__c='Test_xyz', Email='Test_xyz@akamai.com', No_Longer_with_Company__c=false, LastName='Test ContactAcc',Primary_Contact_Method__c = 'Phone');
        insert conRec;
        
        // Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD1';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Test Prod 123';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        //Creating Authorized Contact
        Authorized_Contact__c authConRec = new Authorized_Contact__c(Policy_Domain__c=pdRec.Id, Contact_Name__c=conRec.Id, Product_Interests__c='All');
        insert authConRec;
        
        // Creating Handler Type
        Handler_Type__c  handlerTypeRec = new Handler_Type__c(Name='Phone Call Handler Type', Fields_To_Show__c='Situation_Instruction__c,Escalation_List__c');
        insert handlerTypeRec; 
        
        //Creating Handler
        Handler__c handlerRec = new Handler__c(Name='TestHandler', Policy_Domain__c=pdRec.Id, Handler_Type__c=handlerTypeRec.Id);
        insert handlerRec;
        
        //Creating Escalation List
        SC_SOCC_Escalation_List__c esclistRec = new SC_SOCC_Escalation_List__c(Name='Test escalation list name', Policy_Domain__c=pdRec.Id);
        insert esclistrec; 
        //Changes by Tejaswini for ESESP-4822 
        //Creating Case records
        //List<Case> lCase = new List<Case>();
        
        /*Case c1 = new Case();
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c1.AccountId=accRec.Id;
        c1.Living_Summary_Next_Steps__c = 'Test case 1';
        c1.Subject = 'Testing the case 1';
        c1.origin = 'Akamai'; 
        c1.Do_Not_Show_in_Portal__c = true;
        c1.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        c1.Severity__c = '3';
        c1.Priority = 'Low';
        c1.Policy_Domain__c = pdRec.Id;
        c1.Sub_Type__c = 'Runbook Review';
        c1.Service_Category__c = 'Managed Security';
        c1.Problem__c = 'N/A - Not Applicable';
        c1.Case_Assignment_Using_Active_Rules__c = false;
        c1.Validation_Override__c = true;
        
        lCase.add(c1);
        
        Case c2 = new Case();
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c2.AccountId=accRec.Id;
        //c2.Living_Summary_Next_Steps__c = 'Test case 2';
        c2.Subject = 'Testing the case 2';
        c2.origin = 'Akamai'; 
        c2.Do_Not_Show_in_Portal__c = true;
        c2.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        c2.Severity__c = '3';
        c2.Priority = 'Low';
        c2.Policy_Domain__c = pdRec.Id;
        c2.Sub_Type__c = 'Runbook Review';
        c2.Service_Category__c = 'Managed Security';
        c2.Problem__c = 'N/A - Not Applicable';
        c2.Case_Assignment_Using_Active_Rules__c = false;
        c2.Validation_Override__c = true;
        
        lCase.add(c2);
        
        Case c3 = new Case();
        c3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c3.AccountId=accRec.Id;
        c3.Living_Summary_Next_Steps__c = 'Test case 3';
        c3.Subject = 'Testing the case 3';
        c3.origin = 'Akamai'; 
        c3.Do_Not_Show_in_Portal__c = true;
        c3.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        c3.Severity__c = '3';
        c3.Priority = 'Low';
        c3.Policy_Domain__c = pdRec.Id;
        c3.Sub_Type__c = 'Runbook Review';
        c3.Service_Category__c = 'Managed Security';
        c3.Problem__c = 'N/A - Not Applicable';
        c3.Case_Assignment_Using_Active_Rules__c = false;
        c3.Validation_Override__c = true;
        
        lCase.add(c3);
        
        Case c4 = new Case();
        c4.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c4.AccountId=accRec.Id;
        c4.Living_Summary_Next_Steps__c = 'Test case 4';
        c4.Subject = 'Testing the case 4';
        c4.origin = 'Akamai'; 
        c4.Do_Not_Show_in_Portal__c = true;
        c4.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        c4.Severity__c = '3';
        c4.Priority = 'Low';
        c4.Policy_Domain__c = pdRec.Id;
        c4.Sub_Type__c = 'Runbook Review';
        c4.Service_Category__c = 'Managed Security';
        c4.Problem__c = 'N/A - Not Applicable';
        c4.Case_Assignment_Using_Active_Rules__c = false;
        c4.Validation_Override__c = true;
        lCase.add(c4);
        insert lCase;*/
        
        //Creating Instructions records
        List<Instruction__c> lInstruction = new List<Instruction__c>();
        Instruction__c instruction1 = new Instruction__c(Handler__c=handlerRec.Id,/*Case__c=c1.Id,*/ Instructions_Type__c='Situation Instruction', Status__c='In Progress', Value__c='Test Situation Instruction');
        lInstruction.add(instruction1);
        Instruction__c instruction2 = new Instruction__c(Handler__c=handlerRec.Id,/*Case__c=c2.Id,*/ Instructions_Type__c='Ignore Condition', Status__c='In Progress', Value__c='Test Ignore Condition');
        lInstruction.add(instruction2);
        Instruction__c instruction3 = new Instruction__c(Policy_Domain__c=pdRec.Id,/*Case__c=c3.Id, */Instructions_Type__c='Policy Domain Instruction', Status__c='In Progress', Value__c='Test Policy Domain Instruction');
        lInstruction.add(instruction3);
        Instruction__c instruction4 = new Instruction__c(Escalation_List__c=esclistrec.Id,/*Case__c=c4.Id,*/ Instructions_Type__c='Escalation List Instruction', Status__c='In Progress', Value__c='Test Escalation List Instruction');
        lInstruction.add(instruction4);
        
        insert lInstruction;
    }
    
    @isTest
    public static void testHandlerInstructionSubmition(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //69
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];
        Handler__c handlerRec = [SELECT Id FROM Handler__c LIMIT 1];
        
        Test.startTest();
        SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdRec.Id, handlerRec.Id, new Map<String, String>{'Situation Instruction'=>'Test Situation Instruction'});
        SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdRec.Id, handlerRec.Id, new Map<String, String>{'Ignore Condition'=>'Test Ignore Condition'});
        
        handlerRec.Situation_Instruction__c = 'Test Bulk Situation Instruction';
        handlerRec.Ignore_Condition__c = 'Test Bulk Ignore Condition';
        SC_SOCC_Instruction_Manager.saveInstructionCreateCase(new List<Handler__c>{handlerRec}, pdRec.Id);
        
        /*Instruction__c instRec = [Select Id,Case__c from Instruction__c LIMIT 1];
        Case caseRec = [Select Id from Case LIMIT 1];
        instRec.Case__c=caseRec.Id;
        update instRec;
        
        System.debug('The int Id is '+instRec.Id);
        System.debug('The int Case Id is '+instRec.Case__c);
        System.debug('The Case id is'+caseRec.Id);
        List<SC_SOCC_Instruction_Manager.InstructionWrapper> lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions(pdRec.Id, false,false);
        String instructionWrapperJSON1 = null;
        for(SC_SOCC_Instruction_Manager.InstructionWrapper rec:lInstructionWrapper)
        {
			System.debug('the inst are'+rec);
            System.debug('The case case is '+rec.caseId);
            if(rec.caseId!=null)
                instructionWrapperJSON1=JSON.serialize(rec);
        }
        //String instructionWrapperJSON1 = JSON.serialize(lInstructionWrapper[0]);
        System.debug('The case id '+instructionWrapperJSON1);
        if(instructionWrapperJSON1!=null){
            SC_SOCC_Instruction_Manager.approveInstruction(pdRec.Id, instructionWrapperJSON1, true,false,'test comment');
        }
        */
        
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //70
        Test.stopTest();
    }
    
    @isTest
    public static void testPDnELInstructionSubmition(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //69
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];
        SC_SOCC_Escalation_List__c esclistRec = [SELECT Id FROM SC_SOCC_Escalation_List__c LIMIT 1];
        //Instruction__c instRec = [Select ]
        
        Test.startTest();
        //SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdRec.Id, pdRec.Id, new Map<String, String>{'Policy Domain Instruction'=>'Test Policy Domain Instruction'});
        SC_SOCC_Instruction_Manager.submitInstructionForPD(pdRec.Id, 'Test Policy Domain Instruction');
        SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdRec.Id, esclistRec.Id, new Map<String, String>{'Escalation List Instruction'=>'Test Escalation List Instruction'});
        
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //33
        Test.stopTest();
    }
    
    @isTest
    public static void testInstructionApprovalAction(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //69
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];
       
        Test.startTest();
        
        SC_SOCC_Instruction_Manager.InstructionsWithShiftManager instructionsWithShiftManager = SC_SOCC_Instruction_Manager.getData(pdRec.Id);
        List<SC_SOCC_Instruction_Manager.InstructionWrapper> lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions(pdRec.Id, false,false);
        lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions('', false,true);
        lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions('', true,false);
        
        String instructionWrapperJSON1 = JSON.serialize(lInstructionWrapper[0]);
        String instructionWrapperJSON2 = JSON.serialize(lInstructionWrapper[1]);
        String instructionWrapperJSON3 = JSON.serialize(lInstructionWrapper[2]);
        String instructionWrapperJSON4 = JSON.serialize(lInstructionWrapper[3]);
        
        lInstructionWrapper = SC_SOCC_Instruction_Manager.approveInstruction(pdRec.Id, instructionWrapperJSON1, true,false,'test comment');
        lInstructionWrapper = SC_SOCC_Instruction_Manager.approveInstruction(pdRec.Id, instructionWrapperJSON2, true,false,'test comment');
        lInstructionWrapper = SC_SOCC_Instruction_Manager.approveInstruction(pdRec.Id, instructionWrapperJSON3, true,false,'test comment');
        lInstructionWrapper = SC_SOCC_Instruction_Manager.approveInstruction(pdRec.Id, instructionWrapperJSON4, true,false,'test comment');
        SC_SOCC_Instruction_Manager.checkPendingInstructionForPD(pdRec.Id);
            
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //59
        Test.stopTest();
    }
    
    @isTest
    public static void testInstructionOtherActions(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //67
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];

        Test.startTest();
        List<SC_SOCC_Instruction_Manager.InstructionWrapper> lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions('', true,false);
        
       
        
        String instructionWrapperJSON1 = JSON.serialize(lInstructionWrapper[0]);
        String instructionWrapperJSON2 = JSON.serialize(lInstructionWrapper[1]);
        String instructionWrapperJSON3 = JSON.serialize(lInstructionWrapper[2]);
       
        
        lInstructionWrapper = SC_SOCC_Instruction_Manager.rejectInstruction(pdRec.Id, instructionWrapperJSON1, true,false,'test comment');
       
        lInstructionWrapper = SC_SOCC_Instruction_Manager.saveEditedInstruction(pdRec.Id, instructionWrapperJSON2, true,false);
        lInstructionWrapper = SC_SOCC_Instruction_Manager.revokeInstruction(pdRec.Id, instructionWrapperJSON3, true,false);
        
        SC_SOCC_Handler_Controller.saveHandlerCreateInstruction('Test Handler For Controller', null, 'Phone Call Handler Type', pdRec.Id, null, 'Test Situation', 'Test Ignore');
            
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //59
        Test.stopTest();
    }
    
    @isTest
    public static void testInstructionBulkApprovalAction(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //67
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];

        Test.startTest();
        List<SC_SOCC_Instruction_Manager.InstructionWrapper> lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions('', false,false);
        
        String lInstructionWrapperJSON = JSON.serialize(lInstructionWrapper);
        
        lInstructionWrapper = SC_SOCC_Instruction_Manager.bulkApproveInstruction(pdRec.Id, lInstructionWrapperJSON, true,false,'test comment');
        List<Instruction__c> lInstruction = SC_SOCC_Instruction_Manager.getChangedBulkInstructions(lInstructionWrapperJSON);
        
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //59
        Test.stopTest();
    }
    
    @isTest
    public static void testInstructionBulkOtherActions(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //67
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];

        Test.startTest();
        List<SC_SOCC_Instruction_Manager.InstructionWrapper> lInstructionWrapper = SC_SOCC_Instruction_Manager.getLInstructions('', true,false);
        
        String lInstructionWrapperJSON1 = JSON.serialize(new List<SC_SOCC_Instruction_Manager.InstructionWrapper>{lInstructionWrapper[0]});
        String lInstructionWrapperJSON2 = JSON.serialize(new List<SC_SOCC_Instruction_Manager.InstructionWrapper>{lInstructionWrapper[1]});
        
        lInstructionWrapper = SC_SOCC_Instruction_Manager.bulkRejectInstruction(pdRec.Id, lInstructionWrapperJSON1, true,false,'test comment');
        lInstructionWrapper = SC_SOCC_Instruction_Manager.bulkRevokeInstruction(pdRec.Id, lInstructionWrapperJSON2, true,false);
            
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //59
        Test.stopTest();
    }
    
    @isTest
    public static void test_SC_SOCC_RUN_BOOK(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //67
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];
        Handler_Type__c handlerTypeRec = [SELECT Id FROM Handler_Type__c LIMIT 1];

        Test.startTest();
        //Creating Handler
        List<Handler__c> lHandler = new List<Handler__c>();
        Handler__c handlerRec1 = new Handler__c(Name='Test Handler 1', Policy_Domain__c=pdRec.Id, Handler_Type__c=handlerTypeRec.Id);
        lHandler.add(handlerRec1);
        Handler__c handlerRec2 = new Handler__c(Name='Test Handler 2', Policy_Domain__c=pdRec.Id, Handler_Type__c=handlerTypeRec.Id);
        lHandler.add(handlerRec2);
        insert lHandler;
        
        String handlerIdInstMap = '[{"situationInstruction":"Testing Situation","situationId":null,"ignoreCondition":"Testing Ignore","handlerId":"' + handlerRec2.Id + '"}]';
        
        SC_SOCC_RUN_BOOK.addInstructionforApproval(pdRec.Id, handlerRec1.Id, 'Situation Instruction', 'Ignore Condition');
        SC_SOCC_RUN_BOOK.addMultipleInstructionforApproval(handlerIdInstMap, pdRec.Id);
        
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //59
        Test.stopTest();
    }
    
    @isTest
    public static void testPDnELInstructionSubmitionCommunity(){
        Test.startTest();
        Profile pr = [select id from profile where name='SFCommunityCustomers'][0];
        //Create Contact
        Contact contactRec = [Select id from contact limit 1];
        
        //Create Customer User
        User usr = new User(contactId = contactRec.id,alias = 'user',CompanyName = 'Akamai', email='salesoptest75xv8rj@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        
        Policy_Domain__c pdRec = [SELECT Id FROM Policy_Domain__c LIMIT 1];
        
        System.runAs(usr) {
            SC_SOCC_Instruction_Manager.submitInstructionForPD(pdRec.Id, 'Test Policy Domain Instruction');
        }
        Test.stopTest();
    }
    
}