@isTest
private class GDRAT_Test_Territory_Sec_Assign {
    
    static User user1;
    static User user2;
    static User user3;
    static DGRAT_Configuration__c testConfig;
    
    @isTest static void TestMethod1(){
        
        user1 = [SELECT id,profile.name, IsActive FROM User WHERE profile.name = 'System Administrator' and IsActive = True LIMIT 1];
        Territory_Security_Assignment__c testInsert1 = new Territory_Security_Assignment__c(UserLogin__c  = user1.id, Sales_Division__c = 'Enterprise');
        insert testInsert1;
        
        testConfig = new DGRAT_Configuration__c(Effective_From__c = System.now(),Make_ReadOnly__c = True);
        insert testConfig;
        
        try{
        	update testInsert1;
        }
        catch (dmlException e){
            system.assert(e.getMessage().contains('Application is currently running on read-only mode'),e.getMessage());
        }
        
    }
    
    @isTest static void TestMethod2(){
        
        user1 = [SELECT id,profile.name, IsActive FROM User WHERE profile.name = 'System Administrator' and IsActive = True LIMIT 1];
        Territory_Security_Assignment__c testInsert1 = new Territory_Security_Assignment__c(UserLogin__c  = user1.id, Is_Deleted__c = false, Sales_Division__c = 'Web');
        insert testInsert1;
        
        Boolean deleted = DGRAT_Actions_controller.isDeleted(testInsert1.Id);
        system.assertEquals(deleted,false);
        
		Territory_Security_Assignment__c tsaObj = DGRAT_Actions_controller.toggle_soft_delete(testInsert1.Id);      
        system.assertEquals(tsaObj.Is_Deleted__c,true);
        //system.assert(tsaObj.Is_Deleted__c,true);
        
        user2 = [SELECT id,profile.name, IsActive FROM User WHERE profile.name = 'Engineering' and IsActive = True LIMIT 1];
        Territory_Security_Assignment__c testInsert2 = new Territory_Security_Assignment__c(UserLogin__c  = user2.id, Is_Deleted__c = true, Sales_Division__c = 'Enterprise');
        insert testInsert2;
        
        Boolean deleted1 = DGRAT_Actions_controller.isDeleted(testInsert2.Id);
        system.assertEquals(deleted1,true);
        
		Territory_Security_Assignment__c tsaObj1 = DGRAT_Actions_controller.toggle_soft_delete(testInsert2.Id);   
        system.assertEquals(tsaObj1.Is_Deleted__c,false);
        
        
        user3 = [SELECT id,profile.name, IsActive FROM User WHERE profile.name = 'ServiceDesk Staff' and IsActive = True LIMIT 1];
        Territory_Security_Assignment__c testInsert3 = new Territory_Security_Assignment__c(UserLogin__c  = user3.id, Is_Deleted__c = false, Sales_Division__c = 'Enterprise');
        insert testInsert3;
		testConfig = new DGRAT_Configuration__c(Effective_From__c = System.now(),Make_ReadOnly__c = True);  
		insert testConfig;
        
        try{
        	Territory_Security_Assignment__c tsaObj3 = DGRAT_Actions_controller.toggle_soft_delete(testInsert3.Id);  
        }
        catch (Exception e){
        	System.assert(e.getMessage().contains('Script-thrown exception'),e.getMessage());
        	//system.assert(e.getMessage().contains('Application is currently running on read-only mode'),e.getMessage());
        }
        
    }
}