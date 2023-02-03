/*=====================================================================================================+
Class name          :   SC_Case_Utility_Lighting_TC
Author              :   Supreeth,Sumukh,Himanshu
Created             :   10-Sep-18
Purpose             :   This is a Test class for Lightning migration of Cases. Code coverage for below components
						1.SC_Case_LightningUtility

Last Modified Developer     			Purpose            
============= ========================  =======
10-SEP-18     Supreeth,Sumukh,Himanshu  Initial Development(Jira Ticket# ESESP-1529 )
12-Feb-19	  Sumukh SS, Pinkesh R		Code coverage for additional features added for Akatec Lightning Migration
07-Sep-21     Jay R                     Added Test case for getToolUrl
+=====================================================================================================*/

@isTest
public class SC_Case_Utility_Lighting_TC {
        
    // For Test Data setup
    @testSetup static void datasetup() {
        
        //Create all custom settings
        utilTestClass.createCustomSettings();
        
        // Creating Account
        Account accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active');
        insert accRec;  
        
        // Creating Case 
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = accRec.Id;
        newCase.origin='Email';
        newCase.Sub_Type__c = 'Product Support';
		insert(newCase);
        
         // Creating Case non product support 
        Case newCase2 = new Case();
        newCase2.Subject = 'TestCase2';
        newCase2.Description = 'TestDescription';
        newCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase2.validation_override__c = true;
        newCase2.AccountId = accRec.Id;
        newCase2.origin='Email';
        newCase2.Sub_Type__c = 'CMP Alerts';
		insert(newCase2) ;       
        
          // For Case Product
    EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c(Name='Test Product',EB_MarkedForDeletion__c = false,EB_Product__c='Test-456',
    EB_Account__c=accRec.id);
        insert eb_product;
        
         EmailMessage[] newEmail = new EmailMessage[0];
        newEmail.add(new EmailMessage(FromAddress = 'test@abc.org', Incoming = True, ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', Subject = 'Test email', TextBody = '23456 ', ParentId = newCase.Id, CcAddress = 'abc@xyz.com', BccAddress = 'xyz.abc.com')); 
        insert newEmail;

    }
    
    @isTest
    static void Test_Lightning()
    {   
        String s='==';
     	string getCaseID= [Select Id from Case where Subject = 'TestCase' LIMIT 1][0].Id;
        string getCaseID2= [Select Id from Case where Subject = 'TestCase2' LIMIT 1][0].Id;
     	string getproductID= [Select Id from EB_AccountProductMap__c LIMIT 1][0].Id;
        Test.startTest(); 
     
        // Calling all the Methods for Code Coverage
     	List<String> lists = SC_Case_LightningUtility.fetchRecordTypeValues();
     	Id ids = SC_Case_LightningUtility.getRecTypeId('Technical');
     	Case cases = SC_Case_LightningUtility.getCaseReopenDetails(getCaseID);
     	String getReturn = SC_Case_LightningUtility.updateCaseStatusReopen(getCaseID);
     	List<RecordType> rt = SC_Case_LightningUtility.fetchRecordTypeDetails_LC();
     	getReturn = SC_Case_LightningUtility.cloneCase(getCaseID);
     	getReturn = SC_Case_LightningUtility.is_ps_case(getCaseID);
     	case akam=SC_Case_LightningUtility.getAkamAccountID(getCaseID);
        getReturn=SC_Case_LightningUtility.closeInvalid(getCaseID,'Test comment');
        getReturn=SC_Case_LightningUtility.getcaseclosedetails(getCaseID);
        getReturn=SC_Case_LightningUtility.getcaseclosedetails(getCaseID2);
        getReturn=SC_Case_LightningUtility.getCaseProductList(getCaseID);
        getReturn=SC_Case_LightningUtility.saveProduct(getCaseID,getproductID);
		//ids=SC_Case_LightningUtility.getReportId();
		ids=SC_Case_LightningUtility.getParentCaseId(getCaseID);
        boolean returnval=SC_Case_LightningUtility.sendEmailSOCC(getCaseID);
        getReturn=SC_Case_LightningUtility.CreateRelatedCase(getCaseID,'PS','{"Description":"jjj","Living_Summary_Next_Steps__c":"<p>dasd</p>","Customer_Expectations__c":"ascasd","Service__c":"","Request_Type__c":"","Request_Sub_Type__c":""}');

        String getCurrentCaseRecordTypeId = SC_Case_LightningUtility.getRecordTypeIdOfCase(getCaseID);
        SC_Case_LightningUtility.DeleteclonedCase(getCaseID);

        
        //Added by Aditi to cover the method queryParentAccountId
        System.debug('getCaseID :: '+getCaseID);
        String accId = SC_Case_LightningUtility.queryParentAccountId(getCaseID);

         try{
             for(Integer i=1;i<9;i++) 
             {
                 s=s+s;
             }
             string ss = SC_Case_LightningUtility.updateCaseStatusReopen('');
         }catch(exception e){}
        
     Test.stopTest(); 
    }

    @IsTest
    static void test_getToolUrl(){
        String caseId= [SELECT Id,Owner.Type FROM Case WHERE Subject = 'TestCase' LIMIT 1][0].Id;
        Test.startTest();
        String toolUrl = SC_Case_LightningUtility.getToolUrl(caseId);
        Test.stopTest();
        System.assert(!String.isBlank(toolUrl),'ToolUrl should not be blank');
    }

    
    
    
    
}