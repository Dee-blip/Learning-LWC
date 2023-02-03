@isTest(SeeAllData=false)
public class HD_Test_ActionMenu_Provider {
    
	
    static TestMethod void testActionMenu_Provider()
    {
        


        HD_IncidentTestDataFactory incFactory =  new HD_IncidentTestDataFactory();
        BMCServiceDesk__Incident__c testIncident = incFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
        Test.startTest();
        
        HD_ActionMenu_ProviderV2.Classobject(testIncident.Id);
        
      
        HD_ActionMenu_Provider.getIncident(testIncident.Id);
        HD_ActionMenu_Provider.isAccessibleRecord(testIncident.Id);
        HD_ActionMenu_Provider.approvalRecordStatus(testIncident.Id);
        System.assertEquals(testIncident.Id,HD_ActionMenu_Provider.getIncident(testIncident.Id).Id);
        Test.stopTest();
    }
    
    
    
}