/*=====================================================================================================+
Class name          :   SC_RelatedCaseExistingController_TC
Author              :   Aditi Singh
Created             :   02-03-2021
Purpose             :   This is a Test class for Lightning migration of Cases. Code coverage for below components
						1.RelatedCaseExistingController
+=====================================================================================================*/
@isTest
public class SC_RelatedCaseExistingController_TC {
    
    // For Test Data setup
    @testSetup 
    static void datasetup() {
        
        //Create all custom settings
        utilTestClass.createCustomSettings();
        
        // Creating Account
        Account accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active');
        insert accRec;  
        
        List<Case> casesToTest = new List<Case>();
        for(Integer i=0;i<10;i++){
            Case newCase = new Case();
            newCase.Subject = 'TestCase AMG '+i;
            newCase.Description = 'TestDescription AMG '+i;
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
            newCase.validation_override__c = true;
            newCase.AccountId = accRec.Id;
            newCase.Service__c  = 'Accounts Audits';
            newCase.Request_Type__c  = 'Customer Offboarding';
            newCase.Do_Not_Show_In_Portal_Picklist__c  = 'Internal Only';
            newCase.Request_Sub_Type__c  = 'N/A - Not Applicable';
            newCase.origin='Akamai';
            casesToTest.add(newCase);
        }
        insert casesToTest;
    }
    
    @isTest
    static void Test_PositiveAllFunctionality(){
        
        List<Case> csLst = [Select Id,Akam_Case_Id__c,CaseNumber,ParentId,Status,Solution_Summary__c, LOE_Hours__c,LOE_Minutes__c ,Resolution_Field__c,PRISM_Used__c,ResolvableByPartner__c from case];
        System.debug('csLst :: '+csLst.size());
        if(csLst != null){
            
            List<String> strToSearchLst = new List<String>();
            List<Case> casesToUpdate = new List<Case>();
            String strForJSON = '[ {  "Id" : "'+csLst[0].Id+'",  "ParentId" : "'+null+'",  "AKAM_Case_ID__c" : "'+csLst[0].Akam_Case_Id__c+'"},{  "Id" : "'+csLst[2].Id+'",  "ParentId" : "'+null+'",  "AKAM_Case_ID__c" : "'+csLst[2].Akam_Case_Id__c+'"},{  "Id" : "'+csLst[3].Id+'",  "ParentId" : "'+null+'",  "AKAM_Case_ID__c" : "'+csLst[3].Akam_Case_Id__c+'"}]';
            
            for(Integer i=0;i<10;i++){
                if(i==1 || i== 2 || i==3){
                    strToSearchLst.add(csLst[i].Akam_Case_Id__c);
                }
                else{
                    strToSearchLst.add(csLst[i].Akam_Case_Id__c);
                }
                if(i==4){
                    csLst[i].ParentId = csLst[0].Id;
                    casesToUpdate.add(csLst[i]);
                }
                if(i==5){
                    csLst[i].Status = 'Closed';
                    csLst[i].Solution_Summary__c = 'Testing';
                    csLst[i].LOE_Hours__c = 1;
                    csLst[i].LOE_Minutes__c = 1;
                    csLst[i].Resolution_Field__c = 'Deprovisioning account';
                    csLst[i].PRISM_Used__c = 'No';
                    csLst[i].ResolvableByPartner__c = 'N/A';
                    casesToUpdate.add(csLst[i]);
                }
            }
            String strToSearch = JSON.serialize(strToSearchLst);
            System.debug('strToSearch :: '+strToSearch);
            
            //Updating a case with parent Id
            update casesToUpdate;
            
            Test.startTest();
            List<RelatedCaseExistingController.SearchWrapper> wrapperLst = RelatedCaseExistingController.getCaseRecords(strToSearch,csLst[0].Id);
            System.assertEquals(csLst.size(), wrapperLst.size());
            
            RelatedCaseExistingController.ParentData pdata = RelatedCaseExistingController.getOnLoadCaseNumber(csLst[0].Id);
            System.assertEquals(csLst[0].Akam_Case_Id__c, pdata.akamId);
            
            RelatedCaseExistingController.ErrorMessageWrapper updateVal = RelatedCaseExistingController.updateParentCase(strForJSON,csLst[0].Id);
            System.debug('updateVal :: '+updateVal);
            System.assertNotEquals(updateVal.errorMsg, null);
            System.assertNotEquals(updateVal.successMsg, null);
            //System.assertEquals(csLst[0].Akam_Case_Id__c, pdata.akamId);
            Test.stopTest();
        }
        
    }

}