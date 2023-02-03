@isTest
public class TestCustomCaseSearchController {
    private static User sysAdmin;
    private static Boolean initFlag=false;

    private static void init()
    {
        if(initFlag){
            return;
        }
        /* Creation of custom settings was throwing MIXED_DML EXCEPTION, hence wrapped the creation of custom setting in current user context.*/
        //User oCurrentUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        User oUser = new User(Id = UserInfo.getUserId());
        System.runAs (oUser) {
            utilTestClass.createCustomSettings(); 
        }
        sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        insert (new User[] {sysAdmin});
        initFlag = true;
    }
    
    testMethod static void customSearch() {
        init();
        System.runAs(sysAdmin){
            Case cs = new case();
            cs.Description = 'this is test';
            cs.origin = 'Others';
            insert cs;
            
            cs = [Select Id, Description, OwnerId from Case where Id = : cs.Id][0];
         
            Community_Comments__c cc = new Community_Comments__c();
            cc.comment__c = 'this is test comment';
            cc.Parent_ID__c = cs.Id;
            cc.Related_Object__c = 'Case';
            cc.Application__c = 'Jarvis';
            cc.Commented_By__c = 'Internal User';
            cc.AKAM_Created_Date__c = system.today();
            cc.AKAM_Modified_Date__c = system.today();
            insert cc;


            //invoking sosql search method
            String caseResult = customCaseSearchController.getCaseList(1,1,'this is test');
            System.assert(caseResult != '','Test Case Found');
            String commentResult = customCaseSearchController.getCommunityCommentsList(1,1,'this is test comment');
            System.assert(commentResult != '','Test Comment Found');
        }
    }
    
}