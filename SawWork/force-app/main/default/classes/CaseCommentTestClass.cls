/************************************************************************
    Case Comment Test Class for IR Case functionality. 
|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR/JIRA          DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                    
|  20-July-2020     Komal Dwivedi    ESESP-3929   - Set seeAllData = false
												  - Added utilTestClass.createCustomSettings
												  - Running "utilTestClass.createCustomSettings" under current user context to avoid MIXED_DML EXCEPTION
*************************************************************************/
@isTest(SeeAllData=false) 
private class CaseCommentTestClass 
{
    private static User sysAdmin;
    private static Boolean initFlag=false;
    
    /**
        Init()
        - Intialize the static variables for this Test Class
    */
    private static void init()
    {
        if(initFlag)
            return;
        /*
			Creation of custom settings was throwing MIXED_DML EXCEPTION, hence wrapped the creation of custom setting in current user context.
		*/
        //User oCurrentUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        User oUser = new User(Id = UserInfo.getUserId());
        System.runAs (oUser) {
            utilTestClass.createCustomSettings(); 
        }    
        sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        insert (new User[] {sysAdmin});
        initFlag = true;        
    }
    
    static testMethod void caseComments_UnitTest() 
    {
        init();
        System.runAs(sysAdmin)
        {
            Case cs = new Case();
            cs.Description = 'this is test';
            cs.origin = 'Others';
            insert cs;

            cs = [Select Id, Description, OwnerId from Case where Id = : cs.Id][0];
            
            CaseComment cc = new CaseComment();
            cc.IsPublished=false; 
            cc.CommentBody='this is test comment';
            cc.ParentId=cs.Id;  
            insert cc;
            
            cc = [Select Id,IsPublished,CommentBody,ParentId from CaseComment where Id = :cc.Id][0];
            System.assertEquals(cs.Id,cc.ParentId);
            System.assertEquals(true,cc.IsPublished);
            System.assertEquals('this is test comment',cc.CommentBody);
            
            try {       
                    cc.IsPublished = false;
                    update cc;
            } catch (Exception ex)
            {
                System.assert(ex.getMessage().containsIgnoreCase('Insufficient'));
            }           
        }
    }
}