@isTest
private class MTVSetupControllerTests {

    testMethod static void testMTVSetupController() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            MTVSetupController ctrl = new MTVSetupController();
            ctrl.getAvailableAccessLevels();
            ctrl.getAvailablePortalRoles();
            ctrl.onSave();
            ctrl.onCancel();
            System.assertEquals(Configuration.ACCESS_READ, ctrl.associationSettings[0].Access_Level__c);
        }
    }
}