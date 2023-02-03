@isTest
public class SawyerUnhandledExceptionHandlerTests {
    public static testmethod void testUnhandledExceptionsApex1()
    {   
        Messaging.InboundEmail email=new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope=new Messaging.InboundEnvelope();
        email.subject='Sandbox: Developer script exception from Akamai Technologies, Inc. : ReportFinderUtil : String length exceeds maximum: 6000000 ';
        email.plainTextBody='Sandbox'+'\n'+
                            'Apex script unhandled exception by user/organization: 005G0000003dtx9/00D7c000008wIco'+'\n'+
                            'Source organization: 00DA0000000Hu5a (null)'+'\n'+
                            'Visualforce Page: /apex/SurveyPage'+'\n'+
                            'caused by: System.StringException: String length exceeds maximum: 6000000'+'\n'+
                            'Class.ReportFinderUtil.getDomDocumentFromPageReference: line 35, column 1'+'\n'+
                            'Class.ReportFinderUtil.findReportId: line 7, column 1'+'\n'+
                            'Class.SurveyAndQuestionController.<init>: line 67, column 1';
        envelope.fromAddress='info@salesforce.com';
        //Controller object --calling the email service class and test it.
        SawyerUnhandledExceptionHandler objcontroller= new SawyerUnhandledExceptionHandler();
        objcontroller.handleInboundEmail(email, envelope);
        Messaging.InboundEmailResult result = objcontroller.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);
    }
    public static testmethod void testUnhandledExceptionsApex2()
    {   
        Messaging.InboundEmail email=new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope=new Messaging.InboundEnvelope();
        email.subject='Sandbox: Developer script exception from Akamai Technologies, Inc. : ReportFinderUtil : String length exceeds maximum: 6000000 ';
        email.plainTextBody='Sandbox'+'\n'+
 							'Apex script unhandled exception by user/organization: 0058K000000OIpN/00D8K0000004eUt'+'\n'+
							'Source organization: 00DA0000000Hu5a (null)'+'\n'+
							'Failed to process batch for class LeanDataUpdateLeadWithMatchedAcc for job id 7078K00000EFMqt'+'\n'+
 							'caused by: System.LimitException: Apex CPU time limit exceeded'+'\n'+
 							'(System Code)';
		 envelope.fromAddress='info@salesforce.com';
        //Controller object --calling the email service class and test it.
        SawyerUnhandledExceptionHandler objcontroller= new SawyerUnhandledExceptionHandler();
        objcontroller.handleInboundEmail(email, envelope);
        Messaging.InboundEmailResult result = objcontroller.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);
    }
    
    public static testmethod void testUnhandledExceptionsFlow()
    {   
        Messaging.InboundEmail email=new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope=new Messaging.InboundEnvelope();
        email.subject='Sandbox: Error Occurred During Flow "Delete Incident Tag Mapping": The flow tried to delete these records: a8K7c000...';
        email.htmlbody='Flow Details'+'\n'+
                            'Flow API Name: Delete_Incident_Tag_Mapping'+'\n'+
                            'Type: Autolaunched Flow'+'\n'+
                            'Version: 1'+'\n'+
                            'Status: Active'+'\n'+
                            'Org: Akamai Technologies, Inc. (00D7c000008wIco)'+'\n'+
                            'Flow Interview Details'+'\n'+
                            'Interview Label: Delete Incident Tag Mapping 8/22/2022 5:29 PM'+'\n'+
                            'Interview GUID: 3865ed7bb5302448083b1268a44b182c55146d-aaf8'+'\n'+
                            'Current User: Hemant Barapatre (005G0000003CfjO)'+'\n'+
                            'Start time: 8/22/2022 5:29 PM'+'\n'+
                            'Duration: 1 seconds'+'\n'+
                            'How the Interview Started'+'\n'+
                            'Hemant Barapatre (005G0000003CfjO) started the flow interview.'+'\n'+
                            'API Version for Running the Flow: 54'+'\n'+
                            'Some of this flows variables were set when the interview started.'+'\n'+
                            '$Record = TopicAssignment (0FT7c000000Mv2EGAS)'+'\n'+
                            'GET RECORDS: Get the Tag Mapping Records'+'\n'+
                            'Find all HD_Tag_Mapping__c records where:'+'\n'+
                            'Assigned_Topic__c Equals {!$Record.Topic.Name} (Forreview)'+'\n'+
                            'AND Incident_Id__c Equals {!$Record.EntityId} (a5U7c000000WbN4EAK)'+'\n'+
                            'Sort records by: Id (Ascending)'+'\n'+
                            'Store those records in {!Tag_Mapping}.'+'\n'+
                            'Save these field values in the variable: Id'+'\n'+
                            'Result'+'\n'+
                            'Successfully found records.'+'\n'+
                            'DECISION: Check if the Tag Mapping Record Exists'+'\n'+
                            'Outcome executed: Tag_Mapping_Exists'+'\n'+
                            'Outcome conditions:'+'\n'+ 
                            '{!Tag_Mapping} (HD_Tag_Mapping__c (a8K7c000000Dcz5EAC)) Is null false'+'\n'+
                            'All conditions must be true (AND)'+'\n'+
                            'DELETE RECORDS: Delete Tag Mapping'+'\n'+
                            'Delete HD_Tag_Mapping__c records whose IDs are stored in {!Tag_Mapping}.'+'\n'+
                            'Variable Values'+'\n'+
                            '[Id=a8K7c000000Dcz5EAC]'+'\n'+
                            'Result'+'\n'+
                            'Failed to delete records whose IDs are in {!Tag_Mapping}.'+'\n'+
                            'Error Occurred: The flow tried to delete these records: a8K7c000000Dcz5EAC. This error occurred: ENTITY_IS_DELETED: entity is deleted. You can look up ExceptionCode values in the SOAP API Developer Guide.'+'\n'+
                            'Salesforce Error ID: 539826298-14136 (624492650)';
        
            
        envelope.fromAddress='info@salesforce.com';
        //Controlling object --calling the email service class and test it.
        SawyerUnhandledExceptionHandler objcontroller= new SawyerUnhandledExceptionHandler();
        objcontroller.handleInboundEmail(email, envelope);
        Messaging.InboundEmailResult result = objcontroller.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);
  
    }
    
    
    
    
    
    
}