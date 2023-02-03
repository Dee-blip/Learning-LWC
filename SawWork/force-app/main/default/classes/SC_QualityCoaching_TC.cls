/*---------------------------------------------------------------------------------
    Class name      	: 	SC_QualityCoaching_TC
	Test Class For		:	1. SC_QualityCoaching_Case_Handler
							2. SC_QualityCoaching_Escalation_Handler
							3. SC_QualityCoaching_Transition_Handler

    Author              :   Pinkesh
    Created             :   22-Sep-19
	JIRA				:	ESESP-2316
    Purpose             :  	Quality Coaching Create/Edit
             
    Last Modified         Developer                 Purpose            
    ============= ========================         ==========

* --------------------------------------------------------------------------------*/
@isTest
public class SC_QualityCoaching_TC {
    //Data setup
    @testSetup static void setup(){
        //create custom settings
        utilTestClass.createCustomSettings();
        
        //Get active Akatec User
        User akaTecUser = [Select Id from User where IsActive = true and Profile.Name = 'Support - Tech Support Agent' order by LastModifiedDate Limit 1];
        
        //Create Account
		Account acc = utilTestClass.CreateAccount('TestAccount');
        
        //Create Case
        Case c = new Case(AccountId = acc.Id, Subject = 'Test Case', Origin = 'Phone', Validation_Override__c = true, OwnerId = akaTecUser.Id);
        insert c;
        
        //Create Escalation
        Engagement_Request__c er = new Engagement_Request__c(Case__c = c.Id);
        insert er;
        er.Assigned_To__c = UserInfo.getUserId();
        update er;
        
        //Create case Transition
        Case_Transition__c ct = new Case_Transition__c(Case__c = c.Id, Target_Shift__c = 'Transition Now', Previous_Owner__c = akaTecUser.Id, Validation_Override__c = true);
        insert ct;
        
    }
    
    //Method 1
    @isTest static void testMethod1(){
        Case c = [Select Id, AccountId, Subject, Origin, OwnerId, Owner.Name from Case limit 1];
        Engagement_Request__c er = [Select Id, ownerId from Engagement_Request__c limit 1];
        Case_Transition__c ct = [Select Id, Previous_Owner__c from Case_Transition__c limit 1];
        System.debug(c);
        System.debug(er);
        System.debug(ct);
        
        
        Test.startTest();
        //for cases
        SC_QualityCoaching_Case_Handler.QualityCoachingWrapper qcwForCase = SC_QualityCoaching_Case_Handler.getRecords(c.Id, 'Case', 'Case');
        String tdwForCase = JSON.serialize(qcwForCase.tableData);
        SC_QualityCoaching_Case_Handler.updateQualityCoachingDetails(tdwForCase, 'Test Notes', c.Id, 'Case', 'Case');
        SC_KCS_Scorecard__c qcCase = [Select Id from SC_KCS_Scorecard__c where Case__c =:c.Id limit 1];
        SC_KCS_Scorecard_Dashboard.getParentType(qcCase.Id);
        
        //for escalation
        SC_QualityCoaching_Escalation_Handler.QualityCoachingWrapper qcwForEscalation = SC_QualityCoaching_Escalation_Handler.getRecords(er.Id, 'Escalation', 'Escalation');
        String tdwForEscalation = JSON.serialize(qcwForEscalation.tableData);
        SC_QualityCoaching_Escalation_Handler.updateQualityCoachingDetails(tdwForEscalation, 'Test Notes', er.Id, 'Escalation', 'Escalation');
        SC_KCS_Scorecard__c qcEscalation = [Select Id from SC_KCS_Scorecard__c where Escalation__c =:er.Id limit 1];
        SC_KCS_Scorecard_Dashboard.getParentType(qcEscalation.Id);
        
        //for case transition
        SC_QualityCoaching_Transition_Handler.QualityCoachingWrapper qcwForTransition = SC_QualityCoaching_Transition_Handler.getRecords(ct.Id, 'Transition', 'Transition');
        String tdwForTransition = JSON.serialize(qcwForTransition.tableData);
        SC_QualityCoaching_Transition_Handler.updateQualityCoachingDetails(tdwForTransition, 'Test Notes', ct.Id, 'Transition', 'Transition');
        SC_KCS_Scorecard__c qcTransition = [Select Id from SC_KCS_Scorecard__c where Transition__c =:ct.Id limit 1];
        SC_KCS_Scorecard_Dashboard.getParentType(qcTransition.Id);
        
        Test.stopTest();
        
        
    }
}