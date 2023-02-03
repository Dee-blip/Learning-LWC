/*
* File Name: HD_KA_Viewer_Controller_Test
* Description : Test class for 'HD_KA_Viewer_Controller'
* @author : Aneesh Budnar 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 22nd, 2021    Aneesh Budnar       PRTORES-2123 - HD Create Knowledge article Search and view Panel in LWC for Lighting UI for staff Part 2
*/
@IsTest
public class HD_KA_Viewer_Controller_Test {
    static {
        HD_Test_Data_Factory.init();
    }
    
	@IsTest
    public static void whenLinkKAAndIncInvokedExpectLinkToBeCreated() {    
        User user = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        BMCServiceDesk__Incident__c inc = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withRegion('India')
            .withDescription('Incident 4')
            .withClient(user.Id)
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave(); 
        BMCServiceDesk__KM_KnowledgeArticle__c ka = new BMCServiceDesk__KM_KnowledgeArticle__c (
            BMCServiceDesk__Question__c = 'Question',
            BMCServiceDesk__Answer__c = 'Answer',
            BMCServiceDesk__Status__c = 'In Review',
            BMCServiceDesk__Title__c = 'Test KA Link', 
            HD_Article_Review_Date__c = Date.today().addDays(1), 
            HD_Knowledge_Article_Group__c = 'EAE-Ops',
            BMCServiceDesk__FKCategory__c  = HD_Test_Data_Factory.categoryMap.get('Compensation')
        );
        insert ka;
        Test.startTest();
        HD_KA_Viewer_Controller.linkKAToIncident(ka.Id,inc.Id);
        Test.stopTest();
        List<BMCServiceDesk__KM_KnowledgeArticle__c> linkedKAs = 
            (List<BMCServiceDesk__KM_KnowledgeArticle__c>)JSON.deserialize(HD_KA_Viewer_Controller.getAllLinkedKnowledgeArticles(inc.Id),List<BMCServiceDesk__KM_KnowledgeArticle__c>.class);
        System.assertEquals(1, linkedKAs.size(), 'Actual value not same as expected');
        Exception unexpectedException;
        try
        {
            HD_KA_Viewer_Controller.linkKAToIncident('test','test');
        }
        catch (Exception ex)
        {
            unexpectedException = ex;
        }
        
        system.assertNotEquals(null, unexpectedException, 'Exceptions should be handled by the method');
    }
    
	@IsTest
    public static void whenRemoveLinkKAAndIncInvokedExpectLinkToBeDeleted() {    
        User user = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        BMCServiceDesk__Incident__c inc = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withRegion('India')
            .withDescription('Incident 4')
            .withClient(user.Id)
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave(); 
        BMCServiceDesk__KM_KnowledgeArticle__c ka = new BMCServiceDesk__KM_KnowledgeArticle__c (
            BMCServiceDesk__Question__c = 'Question',
            BMCServiceDesk__Answer__c = 'Answer',
            BMCServiceDesk__Status__c = 'In Review',
            BMCServiceDesk__Title__c = 'Test KA Link', 
            HD_Article_Review_Date__c = Date.today().addDays(1), 
            HD_Knowledge_Article_Group__c = 'EAE-Ops',
            BMCServiceDesk__FKCategory__c  = HD_Test_Data_Factory.categoryMap.get('Compensation')
        );
        insert ka;
        HD_KA_Viewer_Controller.linkKAToIncident(ka.Id,inc.Id);
       
        Test.startTest();
        HD_KA_Viewer_Controller.removeLinkBWKAAndIncident(ka.Id,inc.Id);
        Test.stopTest();
        
        List<BMCServiceDesk__KM_KnowledgeArticle__c> linkedKAs = 
            (List<BMCServiceDesk__KM_KnowledgeArticle__c>)JSON.deserialize(HD_KA_Viewer_Controller.getAllLinkedKnowledgeArticles(inc.Id),List<BMCServiceDesk__KM_KnowledgeArticle__c>.class);
        System.assertEquals(0, 
                            linkedKAs.size(),
                            'Actual value not same as expected');
        Exception unexpectedException;
        try
        {
            HD_KA_Viewer_Controller.removeLinkBWKAAndIncident('test','test');
        }
        catch (Exception ex)
        {
            unexpectedException = ex;
        }
        System.assertNotEquals(null,unexpectedException , 'Exceptions should be handled by the method');
    }    
    
	@IsTest
    public static void whenFavouriteKAsInvokedExpectFavouritesReturned() { 
        BMCServiceDesk__KM_KnowledgeArticle__c ka = new BMCServiceDesk__KM_KnowledgeArticle__c (
            BMCServiceDesk__Question__c = 'Question',
            BMCServiceDesk__Answer__c = 'Answer',
            BMCServiceDesk__Status__c = 'In Review',
            BMCServiceDesk__Title__c = 'Test KA Link', 
            HD_Article_Review_Date__c = Date.today().addDays(1), 
            HD_Knowledge_Article_Group__c = 'EAE-Ops',
            BMCServiceDesk__FKCategory__c  = HD_Test_Data_Factory.categoryMap.get('Compensation')
        );
        insert ka;
        
        List<BMCServiceDesk__KM_KnowledgeArticle__c> favouriteKAs = 
            (List<BMCServiceDesk__KM_KnowledgeArticle__c>)JSON.deserialize(HD_KA_Viewer_Controller.getFavouriteKAs(),List<BMCServiceDesk__KM_KnowledgeArticle__c>.class);
        System.assertEquals(0, 
                            favouriteKAs.size(),
                            'Actual value not same as expected');
        Exception unexpectedException = null;
        try
        {
            HD_KA_Viewer_Controller.getAllLinkedKnowledgeArticles('test');
        }
        catch (Exception ex)
        {
            unexpectedException = ex;
        }
        
        system.assertNotEquals(null, unexpectedException, 'Exceptions should be handled by the method');
    }
}