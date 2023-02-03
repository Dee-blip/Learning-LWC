/*
* File Name: HD_Test_CMR_ChangeCalendar
* Description : Test class for HD_CMR_ChangeCalendar
* @author :
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Aug 08th, 2020     Aneesh Budnar        PRTORES-1810 - Code scanner fixes
* Oct 29th, 2021     Aneesh Budnar        PRTORES-2335 - HD redesign the CMR approval progress indicator using LWC
* Jan 20th, 2022    Aneesh Budnar   PRTORES-2413 - HD CMR switch between the old & new UI based on pilot users
*/
@isTest(SeeAllData = false)
public class HD_Test_CMR_ChangeCalendar {
    public static List<User> SD_Stafs = [select Id, username from User where Profile.name = 'ServiceDesk Staff' and isActive = true limit 5];
    public static List<User> hdClients = [select Id, username from User where Profile.name = 'HelpDesk Client Profile' and isActive = true limit 5];
    public static List<User> SecondlvlApprovers = [SELECT ID, Name, HD_CMR_TAG__C FROM USER where (title like '%CIO%' or manager.title like '%CIO%' or title like 'Director%' or title like '%Vice President%') and isActive = true and HD_CMR_Tag__c like '%SLA%']; 
    
    
    static
    {
        HD_ChangeRequestTestDataFactory initObj = new HD_ChangeRequestTestDataFactory();
    }
    
    
    @isTest
    static void testGetChange() 
    {
        
        BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
        insert change;
        test.startTest();  
        HD_CMR_ChangeCalendar.getChange(change.Id);
        test.stopTest();
        
    }
    
    @isTest
    static void testHasFeatureAccess() 
    {
        User testUser = new UserTestHelper.UserBuilder().buildAndSave();
        System.assertEquals(false, HD_CMR_ChangeCalendar.hasFeatureAccess('HD_Pilot_Users'), 'Expected value not similar to actual');
        System.runAs(testUser) {
            insert new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = [SELECT Id, Name FROM PermissionSet WHERE Name = 'HD_View_New_LWC_UI'].Id);
        	System.assertEquals(false, HD_CMR_ChangeCalendar.hasFeatureAccess('HD_Pilot_Users'), 'Expected value not similar to actual');
        }
    }
    
    @isTest
    static void testGetUserType() 
    {
        
        BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
        insert change;
        test.startTest();  
        HD_CMR_ChangeCalendar.getUserType();
        test.stopTest();
    }
    
    @isTest
    static void testGetCalCMR() 
    {
        
        BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
        insert change;
        test.startTest();
        DateTime sT = change.BMCServiceDesk__Scheduled_Start_Date__c;
        DateTime eT = change.BMCServiceDesk__Scheduled_End_Date__c;
        String sDate = sT.year()+'-'+ sT.month()+'-'+sT.day(); 
        String eDate = eT.year()+'-'+ eT.month()+'-'+eT.day(); 
        HD_CMR_ChangeCalendar.getCalCMR(sDate,eDate);
        test.stopTest();
        
    }
    
    @isTest(seeallData = false)
    static void testGetApprovalHistory() {
        test.startTest();
        
        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();
        
        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';
        
        changeReq.OwnerId = UserInfo.getUserId();
        changeReq.Change_Coordinator_Primary__c = UserInfo.getUserId();
        changeReq.BMCServiceDesk__FKInitiator__c = UserInfo.getUserId();
        //changeReq.Second_Level_Approver__c = UserInfo.getUserId();
        changeReq.Second_Level_Approver__c = SecondlvlApprovers[0].Id;
        
        insert changeReq;
        
        HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');
        
        HD_CMR_ChangeCalendar.getApprovalHistory(changeReq.Id);
        
        test.stopTest();
    }
    
    @isTest(seeallData = false)
    static void testGetListOfActionsWhichUserCanPerform() {
        test.startTest();
        
        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();
        
        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';
        
        changeReq.OwnerId = UserInfo.getUserId();
        changeReq.Change_Coordinator_Primary__c = UserInfo.getUserId();
        changeReq.BMCServiceDesk__FKInitiator__c = UserInfo.getUserId();
        //changeReq.Second_Level_Approver__c = UserInfo.getUserId();
        changeReq.Second_Level_Approver__c = SecondlvlApprovers[0].Id;
        
        insert changeReq;
        
        HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');
        HD_CMRActions_Controller.recallForApproval(changeReq.Id,'recalling');
        
        
        
        String currentUserId=UserInfo.getUserId();
        List<GroupMember> groupMemberList=Database.query('SELECT Id, group.id, group.name, group.type FROM GroupMember where UserOrGroupId = :currentUserId');
        
        HD_CMR_ChangeCalendar.getListOfActionsWhichUserCanPerform(changeReq,currentUserId,groupMemberList);
        
        HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');
        HD_CMR_ChangeCalendar.getListOfActionsWhichUserCanPerform(changeReq,currentUserId,groupMemberList);
        
        test.stopTest();
    }
    
    
    @isTest(seeallData = false)
    static void testApproveOrRejectCMR_Approve() {
        
        
        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();
        
        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';
        
        changeReq.OwnerId = UserInfo.getUserId();
        changeReq.Change_Coordinator_Primary__c = UserInfo.getUserId();
        changeReq.BMCServiceDesk__FKInitiator__c = UserInfo.getUserId();
        //changeReq.Second_Level_Approver__c = UserInfo.getUserId();
        changeReq.Second_Level_Approver__c = SecondlvlApprovers[0].Id;
        
        insert changeReq;
        
        List<ListView> listViews = HD_CMR_ChangeCalendar.getAllListViews();
        try{
            
            HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');
            //ProcessInstance pInstance=[SELECT Id, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems) FROM ProcessInstance WHERE TargetObjectId=:changeReq.Id][0];
            ProcessInstanceWorkitem[] workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :changeReq.Id
                                                   AND ProcessInstance.Status = 'Pending'];
            test.startTest();
            HD_CMR_ChangeCalendar.approveOrRejectCMR(workItems[0].Id,'test','Approve',changeReq);
            test.stopTest();
            
        } catch(Exception e){
            
        }
    }
    
    @isTest(seeallData = false)
    static void testApproveOrRejectCMR_Recall() {
        
        
        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();
        
        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';
        
        changeReq.OwnerId = UserInfo.getUserId();
        changeReq.Change_Coordinator_Primary__c = UserInfo.getUserId();
        changeReq.BMCServiceDesk__FKInitiator__c = UserInfo.getUserId();
        //changeReq.Second_Level_Approver__c = UserInfo.getUserId();
        changeReq.Second_Level_Approver__c = SecondlvlApprovers[0].Id;
        
        insert changeReq;
        
        
        try{
            
            HD_CMRActions_Controller.submitForApproval(changeReq.Id,'testSubmitForApproval');
            ProcessInstance pInstance=[SELECT Id, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems) FROM ProcessInstance WHERE TargetObjectId=:changeReq.Id][0];
            test.startTest();
            HD_CMR_ChangeCalendar.approveOrRejectCMR(pInstance.Id,'test','Recall',changeReq);
            test.stopTest();
            
        }catch(Exception e){
            
        }
    }
    
    @isTest(seeallData = false)
    static void testGetListViewRecords() {
        test.startTest();
        
        BMCServiceDesk__Change_Request__c changeReq = HD_ChangeRequestTestDataFactory.getchange();
        
        changeReq.HD_Resources__c = 'vmata@akamai.com';
        changeReq.Change_Summary__c = 'Test Test';
        changeReq.HD_Change_Status__c = 'OPENED';
        changeReq.Status_Change_Notification__c = 'vmata@akamai.com';
        
        changeReq.OwnerId = UserInfo.getUserId();
        changeReq.Change_Coordinator_Primary__c = UserInfo.getUserId();
        changeReq.BMCServiceDesk__FKInitiator__c = UserInfo.getUserId();
        //changeReq.Second_Level_Approver__c = UserInfo.getUserId();
        changeReq.Second_Level_Approver__c = SecondlvlApprovers[0].Id;
        
        insert changeReq;
        
        
        try{
            ListView myCMR;
            for(ListView listView : [SELECT Id, Name  FROM ListView WHERE SobjectType = 'BMCServiceDesk__Change_Request__c']) {
                if(listView.Name == 'My Change Requests') {
                    myCMR = listView;
                    break;
                }
            }
            
            HD_CMR_ChangeCalendar.getListViewRecords(myCMR.Id);
        }catch(Exception e){
            
        }
        
        test.stopTest();
    }
    
    
}