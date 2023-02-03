/*
* File Name: HD_Test_ApprovalEmailController
* Description : Test class for HD_ApprovalEmailController
* @author :
* Modification Log ===============================================================
* Date 				Author 				Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
@isTest(seeAllData=false)
public class HD_Test_ApprovalEmailController {
	
    static BMCServiceDesk__Incident__c testIncident;
    static Group testQueue;
    static{
        HD_Test_Data_Factory.init();
        ManagedPkgErrorClass.isFromManagedPackage = false;
        testIncident = new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = System.UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKCategory__c = Id.valueOf(HD_Test_Data_Factory.categoryMap.get('Hardware'));
        testIncident.HD_Ticket_Priority__c ='4';
        testIncident.Approver__c = System.UserInfo.getUserId();
        insert testIncident;
  	}
    static testMethod void getTargetObjectId(){
        test.startTest();
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('comment');
        req1.setObjectId(testIncident.id);
        req1.setSubmitterId(System.UserInfo.getUserId());
        try{
            Approval.ProcessResult result =  Approval.process(req1);
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        HD_ApprovalEmailController ob = new HD_ApprovalEmailController();
        ob.targetObjectId = [select id from bmcservicedesk__incident__c limit 1][0].id;
        String url = ob.url;
        System.assertNotEquals(url,null);
        test.stopTest();
    }
    
    
}