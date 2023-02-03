@isTest(SeeAllData=false)
public class HD_CMR_Test_CMR_ACTIONS {
    
    public static List<User> SD_Stafs = [select Id, username from User where Profile.name = 'ServiceDesk Staff' and isActive = true limit 5];
    public static List<User> HD_Clients = [select Id, username from User where Profile.name = 'HelpDesk Client-Chatter Only' and isActive = true limit 5];
    static{
        HD_ChangeRequestTestDataFactory initObj = new HD_ChangeRequestTestDataFactory();
    }


    private static void updateOutages() {
        List<BMCServiceDesk__Projected_Service_Outage__c> psouts = [SELECT Name, BMCServiceDesk__End_Date__c, BMCServiceDesk__Start_Date__c FROM BMCServiceDesk__Projected_Service_Outage__c where BMCServiceDesk__Inactive__c = false];
        Boolean rtval = false;
        for ( BMCServiceDesk__Projected_Service_Outage__c pso : psouts) {
            pso.BMCServiceDesk__End_Date__c = System.now().addDays(801);
            pso.BMCServiceDesk__Start_Date__c = System.now().addDays(800);
        }
        update psouts;
    }
    
    @isTest(seeallData = false)
    static void testSubmitForApproval() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';

        insert changeReq;

        HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');

        test.stopTest();
    }



    @isTest(seeallData = false)
    static void testGetFieldValues() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';

        insert changeReq;

        HD_CMRActions_Controller.getFieldValues(changeReq);

        test.stopTest();
    }

    @isTest(seeallData = false)
    static void testGetPIR() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';

        insert changeReq;

        HD_CMRActions_Controller.getPIR(changeReq);

        test.stopTest();
    }

    @isTest(seeallData = false)
    static void testChangeCMRStatus() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'AUTHORIZED';
        changeReq.CR_Approval_Status__c = 'AUTHORIZED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';
        

        insert changeReq;

        //changeReq.HD_Change_Status__c='AUTHORIZED'

        //update changeReq;

        HD_CMRActions_Controller.changeCMRStatus(changeReq,'IN PROGRESS');

        test.stopTest();
    }


    @isTest(seeallData = false)
    static void testCloneCMR() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';

        insert changeReq;

        HD_CMRActions_Controller.cloneCMR(changeReq.Id);

        test.stopTest();
    }

    @isTest(seeallData = false)
    static void testCreatePIR() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';

        insert changeReq;

        HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');


        changeReq.CR_Approval_Status__c = 'RECALLED';

        try{
        HD_CMRActions_Controller.createPIR(changeReq,'No','No','No','No','No','CHANGE FAILED');
        }catch(Exception e){
            System.debug('Exception Occurred while creating pir in HD_CMRActions_Controller class.createPIR method. Error:'+e.getMessage());
        }

        test.stopTest();
    }

    @isTest(seeallData = false)
    static void testRecallForApproval() {
        test.startTest();

        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();

        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';

        insert changeReq;

        HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');
        HD_CMRActions_Controller.recallForApproval(changeReq.Id,'recalling');

        test.stopTest();
    }
}