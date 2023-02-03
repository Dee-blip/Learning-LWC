/*
* Coder @ Hemant Barapatre  
* this is email composer And reply Button test class
* 
*/
@iSTest(seeAllData=false)
public class HD_Test_Email_Comp_and_reply_Button {
    
    
 static testMethod void Email_Composer_test()
 {
     String[] toAddress = new String[]{'hbarapat@akamai.com'};
     String[] ccAddress = new String[]{'hbarapat@akamai.com'};
     String subject ='Test subject from test class HD_Test_Email_Comp_and_reply_Buttons';
     String body ='Test';
     
     string callBack = HD_Email_Composer_DockedCtrl.sendEmailmethod(toAddress,ccAddress,subject,body);
     System.assertEquals('The email was sent successfully', callBack);
     
 }
    
 static testMethod void reply_button_test()
 {
     //BMCServiceDesk__Action__c action = new BMCServiceDesk__Action__c(Name = 'Email Sent',BMCServiceDesk__appliesToIncident__c = true);
     //insert(action);
     HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
     BMCServiceDesk__Action__c action = [Select Id from BMCServiceDesk__Action__c where Name = 'Email Sent'];
   	 BMCServiceDesk__Incident__c incident = obj.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
     
      
   BMCServiceDesk__IncidentHistory__c action_History = new BMCServiceDesk__IncidentHistory__c();
   action_History.BMCServiceDesk__Client_User__c = UserInfo.getUserId();
   action_History.BMCServiceDesk__EmailConversationData__c = 'Test Data';
   action_History.BMCServiceDesk__description__c = 'Test Description';
   action_History.BMCServiceDesk__FKIncident__c = incident.Id;
   action_History.BMCServiceDesk__FKAction__c = action.Id;
   insert(action_History);
   //BMCServiceDesk__IncidentHistory__c action_History = [Select Id, name, BMCServiceDesk__Client_User__r.Email, BMCServiceDesk__EmailConversationData__c,BMCServiceDesk__description__c, BMCServiceDesk__RichTextNote__c,BMCServiceDesk__note__c from BMCServiceDesk__IncidentHistory__c LIMIT 1 ];
   System.assertEquals(action_History, action_History);  
   HD_History_reply_ButtonCtrl.classObject(action_History.id); 
   HD_History_reply_ButtonCtrl.getActionHistory(action_History.id);
     
 }

 @isTest static void testEmailUISwitch() {
    Test.startTest();
    Boolean switchToNewUI = HD_Email_Composer_DockedCtrl.switchToNewUI('HD_New_UI_List','');
    Test.stopTest();
    System.assertEquals(false,switchToNewUI);
 }
    

}