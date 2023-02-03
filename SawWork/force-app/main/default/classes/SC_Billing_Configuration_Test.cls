/*=====================================================================================================+
    Test class name     :   SC_Billing_Configuration_Test 
    Author              :   Vamsee Surya
    Created             :   01-Dec-16
    Purpose             :   CR #3564721 : Test Class for Billing Configuration
+=====================================================================================================*/

@isTest
public class SC_Billing_Configuration_Test{
    
    static list<sObject> lsObjectToInsert = new list<sObject>();
    static
    {
        utilTestClass.createCustomSettings();
        SC_Resource_Configuration__c varResourceConfig = new SC_Resource_Configuration__c();
        varResourceConfig.Name = 'Billing';
        varResourceConfig.Assignment_Order__c = 0;
        lsObjectToInsert.add(varResourceConfig);
        insert lsObjectToInsert;
        SCUserIdCustomSetting__c billingQueueId = new SCUserIdCustomSetting__c();
        billingQueueId.Name = 'Billing Queue';
        billingQueueId.UserId__c = UserInfo.getUserId();
        insert billingQueueId;
    }
    public static testmethod void testBillingConfig()
    {    
        List<User> lstUsr = new list <User>();
        List<String> lstProfile = new List<String>{'Support - Billing Support Manager','Support - Billing Support Agent','Support - Tech Support Agent'};
        for(Integer i = 0;i<3;i++)
        {
            User usr = utilTestClass.CreateUser('testUsr'+i, 'System Administrator', lstProfile[0]);
            lstUsr.add(usr);
        }
        User cUser = new User(Id = Userinfo.getUserId());
        User invalidUsr = utilTestClass.CreateUser('UserInv', 'System Administrator', lstProfile[2]);
        System.runas(cUser) {
            insert lstUsr;
        }
        
        List<Billing_Case_Resource_Configuration__c> bc = new List<Billing_Case_Resource_Configuration__c>();
        List<String> Shifts = new List<String>{'EMEA 2 (2PM-11PM)','APJ 1 (6AM-3PM)','N America 4 (10PM-7AM)'};
        for(integer i = 0;i<3;i++)
        {
            Billing_Case_Resource_Configuration__c bcNew = new Billing_Case_Resource_Configuration__c();
            bcNew.Assignment_Order__c = i+1;
            bcNew.Shift__c = Shifts[i];
            bcNew.User__c = lstUsr[i].Id;
            bc.add(bcNew);
        }
        test.startTest();
        
        insert bc;
        
        bc.clear();
        
        Billing_Case_Resource_Configuration__c bcNew = new Billing_Case_Resource_Configuration__c();
        bcNew.Assignment_Order__c = 1;
        bcNew.Shift__c = Shifts[0];
        bcNew.User__c = lstUsr[0].Id;
        bc.add(bcNew);
        
        bcNew = new Billing_Case_Resource_Configuration__c();
        bcNew.Assignment_Order__c = -1;
        bcNew.Shift__c = Shifts[0];
        bcNew.User__c = lstUsr[0].Id;
        bc.add(bcNew);
        
        bcNew = new Billing_Case_Resource_Configuration__c();
        bcNew.Assignment_Order__c = 1;
        bcNew.Shift__c = Shifts[0];
        bcNew.User__c = invalidUsr.Id;
        bc.add(bcNew);
        
        try
        {
            insert bc;
        }
        catch(Exception e)
        {}
        
        bcNew = [SELECT Id,Assignment_Order__c,User__c,User_Profile__c FROM  Billing_Case_Resource_Configuration__c where User__c = :lstUsr[0].Id];
        bcNew.User__c = lstUsr[1].Id;
        try
        {
            update bcNew;
        }
        catch(Exception e) {}
        test.stopTest();
        Case c = new Case();
        c.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
        c.OwnerId = SCUserIdCustomSetting__c.getInstance('Billing Queue').UserId__c;
        insert c;    
    }
}