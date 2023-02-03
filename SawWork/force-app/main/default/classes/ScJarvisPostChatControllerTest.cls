/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-22-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   02-22-2022   Vishnu Vardhan   Initial Version
**/
@istest
public class ScJarvisPostChatControllerTest {
    @istest static void postChatCtrlTestMethod(){
        test.startTest();
        utilTestClass.createCustomSettings();
        Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
        User usr = [select Id from User where IsActive = True and ProfileId = :pfl.Id limit 1];
        RecordType rectype= [select id from RecordType where sObjectType='Case' and Name='Technical' and isActive=true limit 1];
        Case csRec = new Case(subject='Test', description='test',Ownerid = usr.Id,AKAM_Case_ID__c='ehsdsg',
            RecordTypeId=rectype.Id,Do_not_show_in_portal__c = true,Origin = 'Email');
        Insert csRec;
        
        PageReference pageRef = Page.PostChatLiveAgentJarvis;
        String jsonStr = '{"CaseId":"'+csRec.Id+'"}';
        pageRef.getParameters().put('attachedRecords',jsonStr);
        Test.setCurrentPage(pageRef);
        ScJarvisPostChatController ctrlInstance = new ScJarvisPostChatController();
        ctrlInstance.akamCaseIdValue = csRec.AKAM_Case_ID__c;
        ctrlInstance.saveRecord();
        test.stopTest();
    }
}