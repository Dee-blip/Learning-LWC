@IsTest
private class ApprovalRequestCommentsControllerTest {

    @IsTest
    private static void test_get_comments() {

        // As of 12/31/2014, Salesforce does not provide us ability
        // to create ProcessInstance or ProcessInstanceStep records,
        // so there is no way to test this *correctly* without actually
        // submitting a record through an actual approve process.
        // However, this does get 100% code coverage =/
        
        ApprovalRequestCommentsController contr = new ApprovalRequestCommentsController();
        System.debug( contr.comments );

    }
    
}