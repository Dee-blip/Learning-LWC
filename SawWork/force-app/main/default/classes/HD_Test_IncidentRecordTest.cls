@isTest(SeeAllData=false)
public class HD_Test_IncidentRecordTest {
    static BMCServiceDesk__Category__c testCategory;
    static ListView testListView;
    static BMCServiceDesk__Incident__c testIncident;
    static Id testCategoryId;
    static{

        HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
        testCategoryId = HD_Test_Data_Factory.categoryMap.get('P2R Team');
        testListView = [SELECT Id, Name FROM ListView WHERE SobjectType = 'BMCServiceDesk__Incident__c' limit 1];
    }
    
    //get incident list - blank ticket number
    @isTest
    static void testGetIncidentList(){
        HD_IncidentRecord.wrapperClass result = HD_IncidentRecord.getIncidentList(testListView.Id, '10', '', 1, 'HD_Ticket_Priority__c', 'asc');
        System.assertNotEquals(null, result);
    }
    
     //get incident list - with ticket number
    @isTest
    static void testGetIncidentListByTicketNumber(){
        HD_IncidentRecord.wrapperClass result = HD_IncidentRecord.getIncidentList(testListView.Id, '10', testIncident.Name, 1, 'HD_Ticket_Priority__c', 'asc');
        System.assertNotEquals(null, result);
    }

    //get incident list - blank ticket number
    @isTest
    static void testGetIncidentList_V2(){
        HD_IncidentRecord.wrapperClass result = HD_IncidentRecord.getIncidentList_V2(testListView.Id, '10', '', 1, 'HD_Ticket_Priority__c', 'asc');
        System.assertNotEquals(null, result);
    }

    //get incident list - with ticket number
    @isTest
    static void testGetIncidentListByTicketNumber_V2(){
        HD_IncidentRecord.wrapperClass result = HD_IncidentRecord.getIncidentList_V2(testListView.Id, '10', testIncident.Name, 1, 'HD_Ticket_Priority__c', 'asc');
        System.assertNotEquals(null, result);
    }
    
    //get list views - positive: type = Incident/Service Request
    @isTest
    static void testGetListViewsWithType(){
        List<ListView> incResult = HD_IncidentRecord.getListViews('Incident');
        List<ListView> sreqResult = HD_IncidentRecord.getListViews('Service Request');
        System.assertNotEquals(null, incResult, 'Incident List View is null');
        System.assertNotEquals(null, sreqResult, 'SR List View is null');
    }
    
    //get list views : type = null/some random value
    @isTest
    static void testGetListViewsWithoutType(){
        List<ListView> result1 = HD_IncidentRecord.getListViews(null);
        List<ListView> result2 = HD_IncidentRecord.getListViews('Test Value');
        System.assertNotEquals(null, result1, 'List View is null');
        System.assertNotEquals(null, result2, 'List View is null');
    }
    
   
    //get columns
    @isTest
    static void testGetColumns(){
        Map<String,String> result = HD_IncidentRecord.getColumns();
        System.assertNotEquals(null, result, 'Columns map is null');
    }
   
    @isTest
    static void testGetUserColumns(){

        Map<String,String> result = HD_IncidentRecord.getUserColumns();
        System.assertNotEquals(null, result, 'Columns map is null');
    }

    @isTest
    static void testUpdateSelectedColumns(){
        Id user = System.UserInfo.getUserId();
        if(HD_UserConfig__c.getValues(user)==null)
        {
            insert new HD_UserConfig__c(SetupOwnerId=user,Field1__c='Owner:::Owner');
        }
        HD_IncidentRecord.updateSelectedColumns(new Map<String, String>{'Owner' => 'Owner'});
        
    }
    
    //get categories
    @isTest
    static void testGetCategories(){
        BMCServiceDesk__Category__c[] result = HD_IncidentRecord.getCategories();
        System.assertNotEquals(null, result, 'Categories List is null');
    }
    
    //get users
    @isTest
    static void testGetActiveUsers(){
        Map<String,Id> result = HD_IncidentRecord.getActiveUsers('will');
        System.assertNotEquals(null, result, 'Users map is null');
    }
    
    //create incident
    @isTest
    static void testCreateIncident(){
        ManagedPkgErrorClass.isFromManagedPackage = false;
        try{
            List<String> fileData = new List<String>();
        	fileData.add('{\"fileName\":\"EntCatQA.csv\",\"fileType\":\"text/csv\",\"fileContents\":\"SWQsUkFfQ2F0ZWdvcnlfR3JvdXBfX2MNCmE1OEcwMDAwMDAwTDJORSxSRVNUUklDVEVEIFBBUkVOVA%3D%3D\"}');
            Test.startTest();
        	String result = HD_IncidentRecord.createIncident(System.UserInfo.getUserId(), '2', testCategoryId, 'test', true, true, true, true, true, true, false, true, true, 'Chatter', 'abc@akamai.com',fileData);
             System.assertNotEquals(null, result, 'Incident is null');
        }    
       
        catch(Exception e){
            System.debug('Exception in testCreateIncident');
        }
        Test.stopTest();
        //String incId = result.split(';').get(0);
        //System.assertEquals(System.UserInfo.getUserId(), )
    }
    
    //init records
    @isTest
     static void testInitRecords(){
        String result = HD_IncidentRecord.initRecords(testListView.Id);
        System.assertEquals('initialized',result);
     }
    
    @isTest
    static void testGetRequestDefinitionsList(){
        Test.startTest();
        Map<String,Id> result = HD_IncidentRecord.getRequestDefinitionsList();
        System.assertNotEquals(null, result);
        Test.stopTest();
    }
    
}