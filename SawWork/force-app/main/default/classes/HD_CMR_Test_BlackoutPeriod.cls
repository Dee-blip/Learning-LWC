@isTest(SeeAllData = false)
private class HD_CMR_Test_BlackoutPeriod {

  public static List<User> SD_Stafs = [select Id, username from User where Profile.name = 'ServiceDesk Staff' and isActive = true limit 5];
  public static List<User> HD_Clients = [select Id, username from User where Profile.name = 'HelpDesk Client-Chatter Only' and isActive = true limit 5];
  public static List<User> DirectorUsers = [select Id, username from User where (manager.title like '%CIO%' or title like 'Director%' or title like '%Vice President%')  and isActive = true AND HD_CMR_TAG__C like '%SLA%' limit 5];

    static
    {
		HD_ChangeRequestTestDataFactory initObj = new HD_ChangeRequestTestDataFactory();
    }


   
   @isTest
    static void verifyCMRMatching() {
        
        BMCServiceDesk__Change_Request__c ch1 = HD_ChangeRequestTestDataFactory.getChange();
        BMCServiceDesk__Change_Request__c ch2 = HD_ChangeRequestTestDataFactory.getChange();
        BMCServiceDesk__Change_Request__c ch3 = HD_ChangeRequestTestDataFactory.getChange();
        

        List<BMCServiceDesk__Change_Request__c> changes =  new List<BMCServiceDesk__Change_Request__c>();
        List<BMCServiceDesk__Change_Request__c> MatchingChanges1 =  new List<BMCServiceDesk__Change_Request__c>();
        List<BMCServiceDesk__Change_Request__c> MatchingChanges2 =  new List<BMCServiceDesk__Change_Request__c>();
        
        
        ch1.HD_Service_Impacted__c = 'Others';
        ch1.HD_Sub_services_Impacted__c = 'Others';
        
        ch1.Specify_Service_Impacted__c = 'Test others';
        ch1.Specify_Sub_Services_Impacted__c = 'Test Others';
        ch1.OwnerId =UserInfo.getUserId();
        ch1.Second_Level_Approver__c = DirectorUsers[0].Id;
        
        ch2.OwnerId =UserInfo.getUserId(); 
        ch2.Customer_Impacted__c = 'ITOC';
        ch2.CR_Risk__c = 'High';
        ch2.Second_Level_Approver__c = DirectorUsers[0].Id;
        ch2.HD_Service_Impacted__c = 'Others';
        ch2.HD_Sub_services_Impacted__c = 'Others';
        ch2.Specify_Service_Impacted__c = 'Test others';
        ch2.Specify_Sub_Services_Impacted__c = 'Test Others';
        
        BMCServiceDesk__Projected_Service_Outage__c newSo = new BMCServiceDesk__Projected_Service_Outage__c();
        
        newSO.BMCServiceDesk__Start_Date__c = System.now().addDays(-2);
        newSO.BMCServiceDesk__End_Date__c =  System.now().addDays(32);
        newSO.Service_Outage_Type__c = 'Enhanced Review Period';
        newSO.Affected_Services_Picklist__c = 'Others';
        newSO.Sub_Services_Affected__c = 'Others';
        
        newSO.Name = 'New SO';
        newSO.OwnerId = UserInfo.getUserId();
         insert newSO;
        BMCServiceDesk__Projected_Service_Outage__c SO1 = new BMCServiceDesk__Projected_Service_Outage__c();

        SO1 = newSO;
        SO1.Id = null;
        SO1.Name = ' Test SO 1';
        SO1.Service_Outage_Type__c = 'Conditional Blackout Period';
        SO1.BMCServiceDesk__Start_Date__c = System.now().addDays(10);
        SO1.BMCServiceDesk__End_Date__c =  System.now().addDays(15);
        insert SO1;

       BMCServiceDesk__Projected_Service_Outage__c SO2 = new BMCServiceDesk__Projected_Service_Outage__c();
        SO2 = newSO;
        SO2.Id = null;
        SO2.Name = ' Test SO 2';
        SO2.BMCServiceDesk__Blackout__c = true;
        SO2.Service_Outage_Type__c = '';
        SO2.BMCServiceDesk__Start_Date__c = System.now().addDays(20);
        SO2.BMCServiceDesk__End_Date__c =  System.now().addDays(25);
        
        List<BMCServiceDesk__Projected_Service_Outage__c> newList = new List<BMCServiceDesk__Projected_Service_Outage__c>();
       
        
        insert SO2;

             
        BMCServiceDesk__Projected_Service_Outage__c newSo1 = new BMCServiceDesk__Projected_Service_Outage__c();
        
        newSO1.BMCServiceDesk__Start_Date__c = System.now().addDays(-2);
        newSO1.BMCServiceDesk__End_Date__c =  System.now().addDays(32);
        newSO1.Service_Outage_Type__c = 'Enhanced Review Period';
        newSO1.Outage_Condition__c = 'Customer_Impacted__c#~#ITOC&OR&Customer_Impacted__c#=#ITOC&OR&Customer_Impacted__c#!=#Low&AND&Customer_Impacted__c#!~#Low';
        newSO1.Name = 'New SO 1';
        newSO1.OwnerId = UserInfo.getUserId();
        
        insert newSO1;

        Boolean notsaved  = false;

        BMCServiceDesk__Change_Request__c ch5 = new BMCServiceDesk__Change_Request__c();
        BMCServiceDesk__Change_Request__c ch6 = new BMCServiceDesk__Change_Request__c();

        ch5 = ch2;
        ch6 = ch1;
        ch5.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(13);
        ch5.BMCServiceDesk__Scheduled_End_Date__c   = System.now().addDays(16);

        ch6.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(21);
        ch6.BMCServiceDesk__Scheduled_End_Date__c   = System.now().addDays(24);
        ch6.Second_Level_Approver__c = DirectorUsers[0].Id;

         Database.SaveResult saveresult  = Database.insert(ch1, false); 
          if (!saveresult.isSuccess()){  
            notsaved = true;

          }  
        changes.add(ch2);
        
    
        List<BMCServiceDesk__Projected_Service_Outage__c> matchingSO = new List<BMCServiceDesk__Projected_Service_Outage__c>();

           
       List<BMCServiceDesk__Change_Request__c> inlist =  new List<BMCServiceDesk__Change_Request__c>();
       List<BMCServiceDesk__Change_Request__c> nwLst =  new List<BMCServiceDesk__Change_Request__c>();
       ch5.id = null;
       ch6.id = null;

        inList.add(ch5);
        inList.add(ch6);
        Test.startTest();
        
        HD_CMR_BlackoutPeriod.matchCMRWithServiceOutage(changes,nwLst);
        matchingChanges1 = HD_CMR_BlackoutPeriod.getSOMatchingCMRList(newSO.id);
        matchingChanges2 = HD_CMR_BlackoutPeriod.getSOMatchingCMRList(newSO1.id);
        matchingSO = HD_CMR_BlackoutPeriod.matchingServiceOutage(ch2);
 
        User usr = [SELECT id,Name, Email from user where id =:ch2.OwnerId];
        System.debug(' EMAIL '+usr.EMail);
        System.debug(' EMAIL 1 '+ch2.Owner.Email);
       // String str = HD_CMR_BlackoutPeriod.notifyOwner(ch2.Id);
        insert inList;

        Test.stopTest();
        List<Id> ids = new List<Id>{inList[0].Id, inList[1].Id};


        List<BMCServiceDesk__Change_Request__c> res = [Select Name,Id, CR_Approval_Type__c from BMCServiceDesk__Change_Request__c WHERE ID IN :ids];
        
        System.assertNotEquals('',res[0].CR_Approval_Type__c);
        System.assertNotEquals('',res[1].CR_Approval_Type__c);

        System.assertNotEquals(0,matchingChanges1.size());
        System.assertNotEquals(0,matchingSO.size());
        
        
    } 
    
   
    
    @isTest
    static void verifyAuraMethods(){
        
             
        BMCServiceDesk__Projected_Service_Outage__c newSo = new BMCServiceDesk__Projected_Service_Outage__c();
        
        newSO.BMCServiceDesk__Start_Date__c = System.now().addDays(-2);
        newSO.BMCServiceDesk__End_Date__c =  System.now().addDays(32);
        newSO.Service_Outage_Type__c = 'Enhanced Review Period';
        newSO.Services_Affected__c = 'Others';
        newSO.Sub_Services_Affected__c = 'Others';
        
        newSO.Name = 'New SO';
        newSO.OwnerId = UserInfo.getUserId();
        
        insert newSO;
        
             
        BMCServiceDesk__Projected_Service_Outage__c newSo1 = new BMCServiceDesk__Projected_Service_Outage__c();
        BMCServiceDesk__Projected_Service_Outage__c newSo2 = new BMCServiceDesk__Projected_Service_Outage__c();
        
        newSO1.BMCServiceDesk__Start_Date__c = System.now().addDays(-2);
        newSO1.BMCServiceDesk__End_Date__c =  System.now().addDays(32);
        newSO1.Service_Outage_Type__c = 'Enhanced Review Period';
        newSO1.Outage_Condition__c = 'Customer_Impacted__c#~#ITOC&OR&Customer_Impacted__c#=#ITOC&OR&Customer_Impacted__c#!=#Low&AND&Customer_Impacted__c#!~#Low';
        newSO1.Name = 'New SO 1';
        newSO1.OwnerId = UserInfo.getUserId();
        string jsonstring = JSON.serialize(newSO1);
        insert newSO1;
        
       BMCServiceDesk__Projected_Service_Outage__c so = HD_CMR_BlackoutPeriod.toggleActiveSO(newSO1.id, true);
       System.assertEquals(true,so.BMCServiceDesk__Inactive__c); 
        
        HD_CMR_BlackoutPeriod.deleteSO(newSO1.id);
        
       
       newSO1.Name = 'Another Test';
        
        
       BMCServiceDesk__Projected_Service_Outage__c nso = HD_CMR_BlackoutPeriod.saveSO(jsonstring);
       List<HD_CMR_BlackoutPeriod.SelectOption> options =  HD_CMR_BlackoutPeriod.getOptionlist();
       BMCServiceDesk__Projected_Service_Outage__c nso2 = HD_CMR_BlackoutPeriod.getSO(newSO.Id);
       List<BMCServiceDesk__Projected_Service_Outage__c> soList = HD_CMR_BlackoutPeriod.getServiceOutages();
       System.assertNotEquals(0,soList.size());
    }
    
  
    
    @isTest
    static void testNotifyOwner(){
        
        BMCServiceDesk__Change_Request__c ch1 = HD_ChangeRequestTestDataFactory.getChange();
        
        
        ch1.HD_Service_Impacted__c = 'Others';
        ch1.HD_Sub_services_Impacted__c = 'Others';
        
        ch1.Specify_Service_Impacted__c = 'Test others';
        ch1.Specify_Sub_Services_Impacted__c = 'Test Others';
        ch1.OwnerId =UserInfo.getUserId();
        insert ch1;
        System.debug(' AFTER INSERT '+ch1.Id);
        String str = '';
        Test.startTest();
         str = HD_CMR_BlackoutPeriod.notifyOwner(ch1.Id);
        Test.stopTest();
        System.assertNotEquals('',str);
    }
   
}