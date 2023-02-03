/**
 * @description       : FFPSA-558
 * @author            : Sujay
 * date               : October 2018
 * @last modified on  : 07-12-2021
**/
@isTest(SeeAllData=false)
public without sharing class IW_Investment_Workbox_Test
{
    public static Account acct;
    public static Account acct2;
    public static Opportunity opp;
    
    Public static Contact resource;
    Public static pse__Practice__c pract;
    Public static Id practId;
    public static PSA_TestUtility testUtil; 
    public static User usr; 
    public static User usr2; 
    Public static User req;
    //Public static pse__Region__c div;
    //Public static pse__Region__c div2;
    Public static pse__Region__c geo;
    Public static pse__Region__c geo2;
    Public static pse__Region__c reg;
    Public static pse__Region__c reg2;
    Public static pse__Region__c area;
    Public static pse__Region__c area2;
    Public static pse__Region__c zone;
    Public static pse__Region__c zone2;
    Public static pse__Region__c terr;
    Public static pse__Region__c terr2;
    Public static Id iwRecordTypeId;
    public static Id ddRecordTypeId;
    public static Id ramdRecordTypeId;
    public static Id chimeRecordTypeId;
    //public static Id discreteTypeId;
    //public static Id securityTypeId;
    public static Id globalTypeId;
    public static List<User> userInsert;
    public static List<Account> accountInsert;
    public static IW_getRequestWatchers requestWatchers;
    public static String currentYear;
    
    static
    {
        userInsert = new List<User>();
        accountInsert =new List<Account>();
        iwRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Investment Workbox').getRecordTypeId();
        ddRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('DealDesk').getRecordTypeId();
        ramdRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('RAMD').getRecordTypeId();
        chimeRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Chime').getRecordTypeId();
        //discreteTypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Security Slot').getRecordTypeId();
        globalTypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Global Services').getRecordTypeId();
        //securityTypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Discrete Slot').getRecordTypeId();
        testUtil = new PSA_TestUtility();

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
        
        Environment_Setup__c esSetting = new Environment_Setup__c();
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';
        insert esSetting;
        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        PSA_Settings__c workItemLimit;

        if(PSA_Settings__c.getInstance('Engineering Team Email') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Engineering Team Email';
            workItemLimit.Value__c = 'services-engg@akamai.com';
            psaSettings.add(workItemLimit);
            
        }

        if(!psaSettings.isEmpty())
        {
            insert psaSettings;
        }
        
        acct = testUtil.newAccount(false);
        acct.Name = 'Living Church Of God';
        acct.TERR_HIER_1__c  = 'Media Americas_Media';
        acct.TERR_HIER_2__c  = 'Media Americas_Media';
        acct.TERR_HIER_3__c  = 'Broadcasting';
        acct.TERR_HIER_4__c  = 'Media East';
        acct.TERR_HIER_5__c  = 'Media East';

        accountInsert.add(acct);
        
        acct2 = testUtil.newAccount(false);
        acct2.Name = 'Unknown Account';
        acct2.TERR_HIER_1__c = 'Unknown_Unknown';
        acct2.TERR_HIER_2__c = 'Unknown_Unknown';
        acct2.TERR_HIER_3__c = 'Unknown';
        acct2.TERR_HIER_4__c = 'Unknown';
        acct2.TERR_HIER_5__c = 'Unknown';

        accountInsert.add(acct2);
        
        insert accountInsert;
        
        opp = testUtil.newOpportunity(false,acct.Id, '0=Plan', System.today());
        opp.StageName = '1. Identify Need';
        opp.Validation_Override__c = TRUE;
        insert opp;
        
        //div = testUtil.newRegionMaster(false);
        //div.Name = 'Unknown (Division)';
        //div.psa_Old__c =false;
        //insert div;
        
        //div2 = testUtil.newRegionMaster(false);
        //div2.Name = 'Media (Division)';
        //div2.psa_Old__c =false;
        //insert div2;
        
        geo = testUtil.newRegionMaster(false);
        geo.Name = 'Media Americas_Media (Geography)';
        geo.psa_Old__c =false;
        insert geo;
        
        geo2 = testUtil.newRegionMaster(false);
        geo2.Name = 'Unknown_Unknown (Geography)';
        geo2.psa_Old__c =false;
        insert geo2;
        
        reg = testUtil.newRegionMaster(false);
        reg.Name = 'Media Americas_Media (Region)';
        reg.psa_Old__c =false;
        reg.pse__Parent_Region__c = geo.Id;
        insert reg;
        
        reg2 = testUtil.newRegionMaster(false);
        reg2.Name = 'Unknown_Unknown (Region)';
        reg2.psa_Old__c =false;
        reg2.pse__Parent_Region__c = geo2.Id;
        insert reg2;
        
        area = testUtil.newRegionMaster(false);
        area.Name = 'Broadcasting (Area)';
        area.psa_Old__c =false;
        area.pse__Parent_Region__c = reg.Id;
        insert area;
        
        area2 = testUtil.newRegionMaster(false);
        area2.Name = 'Unknown (Area)';
        area2.psa_Old__c =false;
        area2.pse__Parent_Region__c = reg2.Id;
        insert area2;

        zone = testUtil.newRegionMaster(false);
        zone.Name = 'Media East (Zone)';
        zone.psa_Old__c =false;
        zone.pse__Parent_Region__c = area.Id;
        insert zone;
        
        zone2 = testUtil.newRegionMaster(false);
        zone2.Name = 'Unknown (Zone)';
        zone2.psa_Old__c =false;
        zone2.pse__Parent_Region__c = area2.Id;
        insert zone2;
        
        terr = testUtil.newRegionMaster(false);
        terr.Name = 'Media East (Territory)';
        terr.psa_Old__c =false;
        terr.pse__Parent_Region__c = zone.Id;
        insert terr;
        
        terr2 = testUtil.newRegionMaster(false);
        terr2.Name = 'Unknown (Territory)';
        terr2.psa_Old__c =false;
        terr2.pse__Parent_Region__c = zone2.Id;
        insert terr2;
        
        
        usr2 = testUtil.newUserSysAdmin(false); 
        usr2.UserName =  '123' + usr2.UserName;
        usr2.Cost_Center__c = 10138;
        usr2.Title = 'Director..Service Line';
        usr2.Division = 'Support Services';
        userInsert.add(usr2);
        //insert usr2;
        
        usr = testUtil.newUserSysAdmin(false);
        usr.UserName =  '456' + usr.UserName;
        usr.Title = 'Manager..Service Line';
        usr.Cost_Center__c = 10138;
        usr.Division = 'Support Services';
        usr.managerId = usr2.id;
        userInsert.add(usr);
        //insert usr;
        insert userInsert;
        
        currentYear = String.valueOf(Date.Today().Year());
        Inv_Workbox_Region_Quarter_Mapping__c rqMap = testUtil.newInvestmentWorkAdmin(false,reg2.Id, 1000,1000,1000,1000, currentYear, globalTypeId);
        insert rqMap;
        
        System.debug('rqMap Tets :: '+ rqMap);
        
        Inv_Workbox_Region_Quarter_Mapping__c rqMap2 = testUtil.newInvestmentWorkAdmin(false,reg.Id, 1000,1000,1000,1000, currentYear, globalTypeId);
        insert rqMap2;
        System.debug('rqMap2 Tets :: '+ rqMap2);
        
        rqMap.Planned_Hours__c = 2000;
        //update rqMap;
        rqMap.UnPlanned_Hours__c = 2000;
        //update rqMap;
        rqMap.Product_Platform_Hours__c = 2000;
        
        InvWB_RQMapHandler.firstRun =true;
        update rqMap;
        
        List<Inv_WorkBox_Region_Mapping__c> gssRegions = new List<Inv_WorkBox_Region_Mapping__c>();
        
        Inv_WorkBox_Region_Mapping__c BroadSlot = testUtil.newGSSUserRegion(false,usr2.Id,NULL,reg2.Id,NULL,NULL,NULL,iwRecordTypeId);
        gssRegions.add(BroadSlot);
        
        Inv_WorkBox_Region_Mapping__c dealDeskRegion = testUtil.newGSSUserRegion(false,usr2.Id,NULL,NULL,area2.Id,NULL,NULL,ddRecordTypeId);
        //gssRegions.add(dealDeskRegion);
        
        Inv_WorkBox_Region_Mapping__c RamdRegion = testUtil.newGSSUserRegion(false,usr2.Id,NULL,NULL,NULL,NULL,terr2.Id,ramdRecordTypeId);
        gssRegions.add(RamdRegion);
        
        Inv_WorkBox_Region_Mapping__c chimeRegion = testUtil.newGSSUserRegion(false,usr2.Id,NULL,NULL,NULL,NULL,terr2.Id,chimeRecordTypeId);
        gssRegions.add(chimeRegion);
        
        System.debug('gssRegions :: '+ gssRegions);
        
        insert gssRegions;
        
    }

    
     @isTest
    static void testMethodWactherCls()
    {
        Investment_Workbox__c workRequest;
        test.startTest();
            
        System.runAs(usr) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct.Id, 42, 0,usr.Id,'Saved',false);
            workRequest.IW_Classification__c = 'Planned Investment';
            insert workRequest;
            
            string watcherList = '[{"Id":'+'\"'+usr.Id+'\"'+',"Name":"Sujay Ravi"}]';
            
            IW_getRequestWatchers.getWatchers(workRequest.Id);  
            IW_getRequestWatchers.saveWatchers(watcherList,workRequest.Id);
            
            //IW_getRequestWatchers.handleButtonEvent(workRequest.Id,'submit','5','30','None','Test');
            IW_getRequestWatchers.getLoeBudget(acct.id,'10','30',workRequest.Id);
            //IW_getRequestWatchers.handleButtonEvent(workRequest.Id,'reject','10','30',acct.id,'Test');
            //IW_getRequestWatchers.handleButtonEvent('','escalate','10','30',acct.id,'Test');
            //19.6 for IW security check
            IW_getRequestWatchers.handleButtonEvent('','escalate','10','30',acct.id,'Test',false, '');
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);
            //19.6 for IW security check
            //IW_getRequestWatchers.availableLoeBudget(acct.id, 'Region'); 
            IW_getRequestWatchers.availableLoeBudget(acct.id, 'Region', workRequest.IW_Classification__c); 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Saved';
            update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Awaiting Approval';
            update workRequest;
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);
            
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Cancelled';
            update workRequest;
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);
        } 
        
        test.stopTest();
    } 

    @isTest
    static void testMethodWactherCls1()
    {
        Investment_Workbox__c workRequest;
        test.startTest();
            
        System.runAs(usr) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct.Id, 42, 0,usr.Id,'Saved',false);
            workRequest.IW_Classification__c = 'Planned Investment';
            insert workRequest;
            
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Saved';
            update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Awaiting Approval';
            update workRequest;
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);
            
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Escalated';
            update workRequest;
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        } 
        
        test.stopTest();
    }

    @isTest
    static void testMethodWactherCls2()
    {
        Investment_Workbox__c workRequest;
        test.startTest();
            
        System.runAs(usr) 
        {  
            workRequest = testUtil.newInvestmentWork(false, acct.Id, 42, 0,usr.Id,'Saved',false);
            workRequest.IW_Classification__c = 'Planned Investment';
            insert workRequest;
            
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Saved';
            update workRequest; 
            
            /*workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Escalated';
            update workRequest;
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);
            
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Escalate Approved';
            update workRequest;*/
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        } 
        
        test.stopTest();
    }

    @isTest
    static void testMethodWactherCls3()
    {
        Investment_Workbox__c workRequest;
        test.startTest();
            
        System.runAs(usr) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct.Id, 42, 0,usr.Id,'Saved',false);
            workRequest.IW_Classification__c = 'Planned Investment';
            workRequest.Submitted_Date__c = Datetime.now();
            insert workRequest;
            
            
            // workRequest.Validation_Override__c = false;
            // workRequest.IW_Modify__c = true;
            // workRequest.status__c = 'Saved';
            // update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Auto-Approved';
            update workRequest;
            IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        } 
        
        test.stopTest();
    }

    @isTest
    static void autoapprovemailtest()
    {
        Investment_Workbox__c workRequest;
        usr2.Title = 'Manager..Service Line';
        List<User> newUsers = new List<User>();
        update usr2;

        User usr11;
        usr11 = testUtil.newUserSysAdmin(false);
        usr11.UserName =  '4567' + usr.UserName;
        usr11.Title = 'Manager.Senior.Service Line';
        usr11.Cost_Center__c = 10138;
        usr11.Division = 'Support Services';
        usr11.managerId = usr2.id;
        newUsers.add(usr11);
        //insert usr;


        User usr12;
        usr12 = testUtil.newUserSysAdmin(false);
        usr12.UserName =  '4568' + usr.UserName;
        usr12.Title = 'Manager.Senior.Service Enablement';
        usr12.Cost_Center__c = 10138;
        usr12.Division = 'Support Services';
        usr12.managerId = usr2.id;
        newUsers.add(usr12);


        User usr1;
        usr1 = testUtil.newUserSysAdmin(false);
        usr1.UserName =  '4569' + usr.UserName;
        usr1.Title = 'Manager..Service Enablement';
        usr1.Cost_Center__c = 10138;
        usr1.Division = 'Support Services';
        usr1.managerId = usr2.id;
        //insert usr;
        newUsers.add(usr1);

        insert newUsers;


        List<Inv_WorkBox_Region_Mapping__c> newList = new List<Inv_WorkBox_Region_Mapping__c>();


        Inv_WorkBox_Region_Mapping__c BroadSlot1 = testUtil.newGSSUserRegion(false,usr2.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot1);
        

        Inv_WorkBox_Region_Mapping__c BroadSlot2 = testUtil.newGSSUserRegion(false,usr1.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot2);

        Inv_WorkBox_Region_Mapping__c BroadSlot3 = testUtil.newGSSUserRegion(false,usr11.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot3);

        Inv_WorkBox_Region_Mapping__c BroadSlot4 = testUtil.newGSSUserRegion(false,usr12.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot4);

        insert newList;

        System.debug(' what ? ' +  [SELECT RecordType.Name, TERR_HIER_2_F__c, TERR_HIER_1_F__c FROM Inv_WorkBox_Region_Mapping__c WHERE User__r.isActive = TRUE AND RecordType.Name = 'Investment Workbox' AND User__r.Division != Null AND TERR_HIER_1__r.psa_Old__c = false and id =:BroadSlot1.Id ] );
        
        test.startTest();
            
        System.runAs(usr) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct2.Id, 42, 0,usr.Id,'Saved',false);
            workRequest.IW_Classification__c = 'Planned Investment';
            workRequest.Submitted_Date__c = Datetime.now();
            insert workRequest;
            
            
            // workRequest.Validation_Override__c = false;
            // workRequest.IW_Modify__c = true;
            // workRequest.status__c = 'Saved';
            // update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Auto-Approved';
            update workRequest;
            //IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        }
        test.stopTest();
    }

    @isTest
    static void autoapprovemailtest2()
    {
        Investment_Workbox__c workRequest;
        usr2.Title = 'Manager..Service Line';
        List<User> newUsers = new List<User>();
        update usr2;

        User usr11;
        usr11 = testUtil.newUserSysAdmin(false);
        usr11.UserName =  '4567' + usr.UserName;
        usr11.Title = 'Manager.Senior.Service Line';
        usr11.Cost_Center__c = 10138;
        usr11.Division = 'Support Services';
        usr11.managerId = usr2.id;
        newUsers.add(usr11);
        //insert usr;


        User usr12;
        usr12 = testUtil.newUserSysAdmin(false);
        usr12.UserName =  '4568' + usr.UserName;
        usr12.Title = 'Manager.Senior.Service Enablement';
        usr12.Cost_Center__c = 10138;
        usr12.Division = 'Support Services';
        usr12.managerId = usr2.id;
        newUsers.add(usr12);


        User usr1;
        usr1 = testUtil.newUserSysAdmin(false);
        usr1.UserName =  '4569' + usr.UserName;
        usr1.Title = 'Manager..Service Enablement';
        usr1.Cost_Center__c = 10138;
        usr1.Division = 'Support Services';
        usr1.managerId = usr2.id;
        //insert usr;
        newUsers.add(usr1);

        insert newUsers;


        List<Inv_WorkBox_Region_Mapping__c> newList = new List<Inv_WorkBox_Region_Mapping__c>();


        Inv_WorkBox_Region_Mapping__c BroadSlot1 = testUtil.newGSSUserRegion(false,usr2.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot1);
        

        Inv_WorkBox_Region_Mapping__c BroadSlot2 = testUtil.newGSSUserRegion(false,usr1.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot2);

        Inv_WorkBox_Region_Mapping__c BroadSlot3 = testUtil.newGSSUserRegion(false,usr11.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot3);

        Inv_WorkBox_Region_Mapping__c BroadSlot4 = testUtil.newGSSUserRegion(false,usr12.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot4);

        insert newList;

        System.debug(' what ? ' +  [SELECT RecordType.Name, TERR_HIER_2_F__c, TERR_HIER_1_F__c FROM Inv_WorkBox_Region_Mapping__c WHERE User__r.isActive = TRUE AND RecordType.Name = 'Investment Workbox' AND User__r.Division != Null AND TERR_HIER_1__r.psa_Old__c = false and id =:BroadSlot1.Id ] );
        
        test.startTest();
            
        System.runAs(usr) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct2.Id, 42, 0,usr.Id,'Saved',false);
            workRequest.IW_Classification__c = 'Product/Platform Work';
            workRequest.Submitted_Date__c = Datetime.now();
            insert workRequest;
            
            
            // workRequest.Validation_Override__c = false;
            // workRequest.IW_Modify__c = true;
            // workRequest.status__c = 'Saved';
            // update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Auto-Approved';
            update workRequest;
            //IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        }
        test.stopTest();
    }

    @isTest
    static void autoapprovemailtest21()
    {
        Investment_Workbox__c workRequest;
        usr2.Title = 'Manager..Service Line';
        List<User> newUsers = new List<User>();
        update usr2;

        User usr11;
        usr11 = testUtil.newUserSysAdmin(false);
        usr11.UserName =  '4567' + usr.UserName;
        usr11.Title = 'Manager.Senior.Service Line';
        usr11.Cost_Center__c = 10138;
        usr11.Division = 'Support Services';
        usr11.managerId = usr2.id;
        newUsers.add(usr11);
        //insert usr;


        User usr12;
        usr12 = testUtil.newUserSysAdmin(false);
        usr12.UserName =  '4568' + usr.UserName;
        usr12.Title = 'Manager.Senior.Service Enablement';
        usr12.Cost_Center__c = 10138;
        usr12.Division = 'Support Services';
        usr12.managerId = usr2.id;
        newUsers.add(usr12);


        User usr1;
        usr1 = testUtil.newUserSysAdmin(false);
        usr1.UserName =  '4569' + usr.UserName;
        usr1.Title = 'Manager..Service Enablement';
        usr1.Cost_Center__c = 10138;
        usr1.Division = 'Support Services';
        usr1.managerId = usr2.id;
        //insert usr;
        newUsers.add(usr1);

        insert newUsers;


        List<Inv_WorkBox_Region_Mapping__c> newList = new List<Inv_WorkBox_Region_Mapping__c>();


        Inv_WorkBox_Region_Mapping__c BroadSlot1 = testUtil.newGSSUserRegion(false,usr2.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot1);
        

        Inv_WorkBox_Region_Mapping__c BroadSlot2 = testUtil.newGSSUserRegion(false,usr1.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot2);

        Inv_WorkBox_Region_Mapping__c BroadSlot3 = testUtil.newGSSUserRegion(false,usr11.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot3);

        Inv_WorkBox_Region_Mapping__c BroadSlot4 = testUtil.newGSSUserRegion(false,usr12.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot4);

        insert newList;

        
        test.startTest();
            
        System.runAs(usr12) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct2.Id, 42, 0,usr.Id,'Awaiting Approval',false);
            workRequest.IW_Classification__c = 'Product/Platform Work';
            workRequest.Submitted_Date__c = Datetime.now();
            insert workRequest;
            
            
            // workRequest.Validation_Override__c = false;
            // workRequest.IW_Modify__c = true;
            // workRequest.status__c = 'Saved';
            // update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Awaiting Approval';
            update workRequest;
            //IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        }
        test.stopTest();
    }

    @isTest
    static void autoapprovemailtest222()
    {
        Investment_Workbox__c workRequest;
        usr2.Title = 'Manager..Service Line';
        List<User> newUsers = new List<User>();
        update usr2;

        User usr11;
        usr11 = testUtil.newUserSysAdmin(false);
        usr11.UserName =  '4567' + usr.UserName;
        usr11.Title = 'Manager.Senior.Service Line';
        usr11.Cost_Center__c = 10138;
        usr11.Division = 'Support Services';
        usr11.managerId = usr2.id;
        newUsers.add(usr11);
        //insert usr;


        User usr12;
        usr12 = testUtil.newUserSysAdmin(false);
        usr12.UserName =  '4568' + usr.UserName;
        usr12.Title = 'Manager.Senior.Service Enablement';
        usr12.Cost_Center__c = 10138;
        usr12.Division = 'Support Services';
        usr12.managerId = usr2.id;
        newUsers.add(usr12);


        User usr1;
        usr1 = testUtil.newUserSysAdmin(false);
        usr1.UserName =  '4569' + usr.UserName;
        usr1.Title = 'Manager..Service Enablement';
        usr1.Cost_Center__c = 10138;
        usr1.Division = 'Support Services';
        usr1.managerId = usr2.id;
        //insert usr;
        newUsers.add(usr1);

        insert newUsers;


        List<Inv_WorkBox_Region_Mapping__c> newList = new List<Inv_WorkBox_Region_Mapping__c>();


        Inv_WorkBox_Region_Mapping__c BroadSlot1 = testUtil.newGSSUserRegion(false,usr2.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot1);
        

        Inv_WorkBox_Region_Mapping__c BroadSlot2 = testUtil.newGSSUserRegion(false,usr1.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot2);

        Inv_WorkBox_Region_Mapping__c BroadSlot3 = testUtil.newGSSUserRegion(false,usr11.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot3);

        Inv_WorkBox_Region_Mapping__c BroadSlot4 = testUtil.newGSSUserRegion(false,usr12.Id,null,null,NULL,NULL,NULL,iwRecordTypeId);
        newList.add(BroadSlot4);

        insert newList;

        
        test.startTest();
            
        System.runAs(usr12) 
        {
            workRequest = testUtil.newInvestmentWork(false, acct2.Id, 112, 0,usr.Id,'Awaiting Approval',false);
            workRequest.IW_Classification__c = 'Product/Platform Work';
            workRequest.Submitted_Date__c = Datetime.now();
            insert workRequest;
            
            
            // workRequest.Validation_Override__c = false;
            // workRequest.IW_Modify__c = true;
            // workRequest.status__c = 'Saved';
            // update workRequest; 
            
            workRequest.Validation_Override__c = false;
            workRequest.IW_Modify__c = true;
            workRequest.status__c = 'Awaiting Approval';
            update workRequest;
            //IW_getRequestWatchers.getButtonVisibility(workRequest.Id);

        }
        test.stopTest();
    }

    @isTest
    static void testMethodnew()
    {
        Investment_Workbox__c workRequest = testUtil.newInvestmentWork(false,acct2.id, 42, 0,usr.Id,'Awaiting Approval',false);
        workRequest.IW_Classification__c = 'Planned Investment';
        
        System.runAs(usr) 
        {
            insert workRequest;
        }
        test.startTest();

        System.runAs(usr) 
        {
            boolean b = IW_getRequestWatchers.getWatchersAccess(workRequest.Id);
                        
        } 
        
    }


    @isTest
    static void getIwdetailsTest()
    {
        Investment_Workbox__c workRequest = testUtil.newInvestmentWork(false,acct2.id, 42, 0,usr.Id,'Awaiting Approval',false);
        workRequest.IW_Classification__c = 'Planned Investment';
        
        System.runAs(usr) 
        {
            insert workRequest;
        }
        test.startTest();

        System.runAs(usr) 
        {
            String b = IW_getRequestWatchers.getIWDetails(workRequest.Id);
                        
        } 

        test.stopTest();
        
    }

    // @isTest
    // static void testMethod1()
    // {
        
    //     Investment_Workbox__c workRequest = testUtil.newInvestmentWork(false,acct2.id, 42, 0,usr.Id,'Awaiting Approval',false);
    //     workRequest.IW_Classification__c = 'Planned Investment';
        
    //     System.runAs(usr) 
    //     {
    //         insert workRequest;
    //     }
    //     test.startTest();
    //     System.runAs(usr) 
    //     {
    //         //IW_getRequestWatchers.handleButtonEvent(workRequest.Id,'escalate','10','30',acct2.id,'Test');
    //         //IW_getRequestWatchers.handleButtonEvent(workRequest.Id,'cancel','10','30',acct2.id,'Test');
    //         //19.6 for IW security check
    //         IW_getRequestWatchers.handleButtonEvent(workRequest.Id,'escalate','10','30',acct2.id,'Test', false, workRequest.IW_Classification__c);
    //         IW_getRequestWatchers.handleButtonEvent(workRequest.Id,'cancel','10','30',acct2.id,'Test', false, workRequest.IW_Classification__c);
    //         boolean b = IW_getRequestWatchers.getWatchersAccess(workRequest.Id);
    //         //workRequest.Validation_Override__c = false;
    //         //workRequest.IW_Modify__c = true;
    //         //workRequest.status__c = 'Awaiting Approval';
    //         //update workRequest;
    //         IW_getRequestWatchers.getButtonVisibility(workRequest.Id);
            
    //     } 
        
    //     System.runAs(usr2){
    //         workRequest.Status__c = 'Approved';
    //         update workRequest;
    //     }

        
    //     System.runAs(usr)
    //     {
    //         pse__Milestone__c milestone = [select id,createdby.Name,Validation_Override__c,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__r.Id,pse__Closed_for_Time_Entry__c,PSA_Ignore_Saved_Timecards__c,Investment_Work__c,Investment_Work__r.Security__c from pse__Milestone__c where Investment_Work__c!=null];
    //         milestone.Validation_Override__c = true;
    //         update milestone;
    //         workRequest.Validation_Override__c = false;
    //         workRequest.IW_Modify__c = true;
    //         workRequest.status__c = 'Cancelled';
    //         update workRequest;
    //     }
        
    //     test.stopTest();

    // }

    /*@isTest
    static void testSecurityRoutingChange()
    {
        Investment_Workbox__c securityWR;
        requestWatchers = new IW_getRequestWatchers();
       
        test.startTest();
        System.runAs(usr) 
        {
            securityWR = testUtil.newInvestmentWork(false,acct3.id, 30, 0,usr.Id,'Awaiting Approval',false);
            insert securityWR;

        }

        System.runAs(usr2){
            securityWR.Status__c = 'Approved';
            update securityWR;
        }
        //requestWatchers.getSecurityProj();

        IW_getRequestWatchers.getSecurityProj();


        test.stopTest();

    }*/

    //@isTest
    // static void testSecurityRoutingChangeLOE50()
    // {
        
    //     Investment_Workbox__c securityWR1;
    //     pse__Proj__c proj1;
    //     test.startTest();
    //     System.runAs(usr) 
    //     {
    //         resource = testUtil.newResource(false, acct2.Id, usr.Id);
    //         resource.email = 'PSAProjMgr2@akamai.com';
    //         insert resource;
        
    //         pract = testUtil.newPracticeMaster(true);
    //         practId = pract.ID;
    //         proj1 = testUtil.newProject(true,terr2.id,practId,true,'One-Time: Fixed Price', resource.Id, acct2.Id);
            
    //         Inv_Workbox_Region_Quarter_Mapping__c rqMp = testUtil.newInvestmentWorkAdmin(true,geo2.Id, 1000,1000,1000,1000, currentYear, globalTypeId);
            
    //         securityWR1 = testUtil.newInvestmentWork(false,acct2.id, 50, 0,usr.Id,'Awaiting Approval',true);
    //         securityWR1.Project__c = proj1.Id;
    //         insert securityWR1;

    //     }

    //     System.runAs(usr2){
    //         securityWR1.Status__c = 'Approved';
    //         update securityWR1;
    //     }
    //     test.stopTest();

    // }


    // @isTest
    // static void testSecurityRoutingChangeLOE90()
    // {
    //     Investment_Workbox__c securityWR2;
    //     pse__Proj__c proj1; 
    //     usr2.Title = 'Vice President';

    //     test.startTest();
    //         System.runAs(usr) 
    //         {
    //             update usr2;
    //             resource = testUtil.newResource(false, acct2.Id, usr.Id);
    //             resource.email = 'PSAProjMgr2@akamai.com';
    //             insert resource;
            
    //             pract = testUtil.newPracticeMaster(true);
    //             practId = pract.ID;
    //             proj1 = testUtil.newProject(true,terr2.id,practId,true,'One-Time: Fixed Price', resource.Id, acct2.Id);
                
    //             Inv_Workbox_Region_Quarter_Mapping__c rqMp = testUtil.newInvestmentWorkAdmin(true,geo2.Id, 1000,1000,1000,1000, currentYear, globalTypeId);
    
    //             securityWR2 = testUtil.newInvestmentWork(false,acct2.id, 90, 0,usr.Id,'Awaiting Approval',true);
    //             securityWR2.Project__c = proj1.Id;
    //             insert securityWR2;
    
    //         }
    
    //         System.runAs(usr2){
    //             securityWR2.Status__c = 'Approved';
    //             update securityWR2;
    //         }
    //     test.stopTest();

    // }
    
    
    // to cover GSS User Region Handler + Component
    // @isTest
    // static void testMethod2()
    // {
    //     test.startTest();
    //         Inv_WorkBox_Region_Mapping__c adminSlot = new Inv_WorkBox_Region_Mapping__c();
    //         adminSlot.User__c = usr.Id; 
    //         adminSlot.TERR_HIER_2__c = reg.Id;
    //         insert adminSlot;
        
    //         adminSlot.TERR_HIER_1__c = geo2.id;
    //         update adminSlot;
        
    //         adminSlot.TERR_HIER_2__c = reg2.id;
    //         update adminSlot;
        
    //         adminSlot.TERR_HIER_2__c = reg.id;
    //         update adminSlot;
        
    //         adminSlot.TERR_HIER_2__c = reg2.id;
    //         update adminSlot;
        
    //         delete adminSlot;
            
    //         List<IW_Region> regsList = new List<IW_Region>();
    //         IW_Region regs = new IW_Region();
    //         regs.type = 'Region';
    //         regs.Id = reg.Id;
    //         regsList.add(regs);
            
    //         String params;
    //         IW_NewRegionWrapper newRegion = new IW_NewRegionWrapper();
    //         newRegion.user = usr.Id;
    //         newRegion.regions = regsList;
    //         newRegion.recordType = 'Investment Work';
            
    //         params = JSON.serialize(newRegion);
    //         IW_NewUserRegionCntrl.createNewUserRegion(params);
        
    //         IW_NewRegionWrapper newRegion2 = new IW_NewRegionWrapper();
    //         newRegion2.user = usr.Id;
    //         newRegion2.regions = regsList;
    //         newRegion2.recordType = 'Chime';
            
    //         params = JSON.serialize(newRegion2);
    //         IW_NewUserRegionCntrl.createNewUserRegion(params);
        
            
    //         IW_NewRegionWrapper newRegion3 = new IW_NewRegionWrapper();
    //         newRegion3.user = usr.Id;
    //         newRegion3.regions = regsList;
    //         newRegion3.recordType = 'RAMD';
            
    //         params = JSON.serialize(newRegion3);
    //         IW_NewUserRegionCntrl.createNewUserRegion(params);
            
    //     test.stopTest();

    // }
    
    @isTest
    static void testMethod3()
    {
        test.startTest();
            String currentYear = String.valueOf(Date.Today().Year());
            Inv_Workbox_Region_Quarter_Mapping__c rqMp = testUtil.newInvestmentWorkAdmin(false,reg2.Id, 1000,1000,1000,1000, currentYear, globalTypeId);
            try{
                insert rqMp;
            }
            catch (Exception e){
                
            }
        
        test.stopTest();

    }
    
    //Reuquest gets autoApproved + handling Comp Handler Events + Clone func + sending Email
    @isTest
    static void testMethod4()
    {
        test.startTest();
            System.runAs(usr) 
            {
                Investment_Workbox__c wr2 = testUtil.newInvestmentWork(false,acct2.Id, 3, 0,usr.Id,'Awaiting Approval',false);
                wr2.IW_Classification__c = 'Product/Platform Work';
                insert wr2;
                // 19.6 
                //IW_getRequestWatchers.handleButtonEvent(wr2.Id,'submit','10','30','None','Test');
                IW_getRequestWatchers.handleButtonEvent(wr2.Id,'submit','10','30','None','Test', false, wr2.IW_Classification__c);
                //19.1 covers ApproverDisplay component.
                IW_getRequestWatchers.getApprovers(wr2.Id);
                //19.1 covers send Email when Slots available is < that LOE Entered.
                IW_getRequestWatchers.calculateValueforNotifyLowSlot('3000','0', wr2.Account__c, wr2.Justification__c , wr2.IW_Classification__c);
                //19.6
                //IW_getRequestWatchers.handleButtonEvent(wr2.Id,'submit','5000','30',acct2.id,'Test');
                IW_getRequestWatchers.handleButtonEvent(wr2.Id,'submit','5000','30',acct2.id,'Test', false , wr2.IW_Classification__c);
                IW_CloneInvestmentRecord cloneController = new IW_CloneInvestmentRecord();
                IW_CloneInvestmentRecord.cloneRecord(wr2.Id);
            }
        test.stopTest();
    }
    
    @isTest
    static void testMethod5()
    {
        test.startTest();
            System.runAs(usr) 
            {
                Investment_Workbox__c wr3 = testUtil.newInvestmentWork(false,acct2.Id, 8, 0,usr.Id,'Awaiting Approval',false);
                insert wr3;
                
                //wr3.Status__c = 'Approved';
                //update wr3;
            }
        test.stopTest();
    }
    
    // get Request Approved + cancel the IW to make milestone invalid for TimeEntry
    @isTest
    static void testMethod6()
    {
        test.startTest();
            System.runAs(usr) 
            {
                Investment_Workbox__c wr4 = testUtil.newInvestmentWork(false,acct2.Id, 3, 0,usr.Id,'Awaiting Approval',false);
                
                insert wr4;
                
                wr4.IW_Modify__c = true;
                wr4.Status__c = 'Cancelled';
                wr4.Validation_Override__c = false;

                pse__Milestone__c milestone = [select id,createdby.Name,Validation_Override__c,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__r.Id,pse__Closed_for_Time_Entry__c,PSA_Ignore_Saved_Timecards__c,Investment_Work__c,Investment_Work__r.Security__c from pse__Milestone__c where Investment_Work__c!=null];
                milestone.Validation_Override__c = true;
                update milestone;
                
                
                update wr4;
            }
        test.stopTest();
    }
    
    @isTest
    static void bulkController(){
        test.startTest();
            List<watcherWrapperCls> wrapList = new List<watcherWrapperCls>();
            watcherWrapperCls wrap = new watcherWrapperCls();
            wrap.Name = acct2.Name;
            wrap.Id =  acct2.Id;
            wrapList.add(wrap);
            String params = JSON.serialize(wrapList);
            Decimal LOE = 8;
            IW_BulkReqFormCntrl.getRgionAccountSlots(params, LOE, 'Marketing', 'Planned Investment');
        test.stopTest();
    }
    
    @isTest
    static void createDataSetCmp(){
        test.startTest();
        //IW_CreateNewDataSet.createRegionRecsPresentYear();
        IW_CreateNewDataSet.createRegionRecs();
        test.stopTest();
    }
    
    @isTest
    static void LookupCntrl(){

        test.startTest();
        String objectName = 'Account';
        String fld_API_Text = 'Id';
        String fld_API_Val = 'Name';
        Integer lim = 2; 
        String fld_API_Search = 'Name';
        String searchText = 'Living';
        String addSearchFilter ; 
        String fieldFilter ;
        String recordType = '';
        String secAcc = '';
        
        InvWB_Lookup.searchDB(objectName, fld_API_Text, fld_API_Val, 
                                   lim, fld_API_Search, searchText, addSearchFilter, fieldFilter, secAcc, recordType);
        
        objectName = 'User';
        InvWB_Lookup.searchDB(objectName, fld_API_Text, fld_API_Val, 
                                   lim, fld_API_Search, searchText, addSearchFilter, fieldFilter, secAcc, recordType );
        
        addSearchFilter = '(Region)';
        fieldFilter = 'psa_old__c';
        objectName = 'pse__Region__c';
        
        InvWB_Lookup.searchDB(objectName, fld_API_Text, fld_API_Val, 
                                   lim, fld_API_Search, searchText, addSearchFilter, fieldFilter, secAcc, recordType );
        
        recordType = 'Non-Internal Project';
        secAcc = '00';
        InvWB_Lookup.searchDB(objectName, fld_API_Text, fld_API_Val, 
                                   lim, fld_API_Search, searchText, addSearchFilter, fieldFilter, secAcc, recordType );
        
        secAcc = acct.Id;
        objectName = 'Opportunity';
        searchText = 'TestOpp';
        InvWB_Lookup.searchDB(objectName, fld_API_Text, fld_API_Val, 
                                   lim, fld_API_Search, searchText, addSearchFilter, fieldFilter, secAcc, recordType );
        
        test.stopTest();
    }
    
   @isTest
    public static void searchControllerTest()
    {
        test.startTest();
        SearchRecordsCheckboxDisplayCtrl.getAllRecs('select id, name, psa_old__c from pse__Region__c', 'pse__Region__c',
                                              'psa_old__c');
        SearchRecordsCheckboxDisplayCtrl.getPickListValuesIntoList('pse__Proj__c','Project_Sub_Type__c');
        Investment_Workbox__c workRequest = testUtil.newInvestmentWork(false,acct2.Id, 42, 0,usr.Id,'Saved',false);
        
        System.runAs(usr) 
        {
            insert workRequest;
        }
        SearchRecordsCheckboxDisplayCtrl.getRgionAccountSlot(workRequest.Id,'hours');
        IW_reUsableMultiSelectLookupCtrl.fetchLookUpValues('Broadcasting','pse__Region__c',new List<pse__Region__c>{reg});
        Test.stopTest();
    }
    
    // DD GSS User Region Changes
    @isTest
    public static void userRegionTest(){
        test.startTest();
            List<Inv_WorkBox_Region_Mapping__c> gssRegions = new List<Inv_WorkBox_Region_Mapping__c>();
            Inv_WorkBox_Region_Mapping__c dealDeskRegion1 = testUtil.newGSSUserRegion(false,usr2.Id,NULL,NULL,area2.Id,NULL,NULL,ddRecordTypeId);
                /*dealDeskRegion1.User__c =usr2.Id; 
                dealDeskRegion1.RecordTypeId = ddRecordTypeId;
                dealDeskRegion1.Area__c = area2.id;*/
                gssRegions.add(dealDeskRegion1);
            
            Inv_WorkBox_Region_Mapping__c dealDeskRegion2 = testUtil.newGSSUserRegion(false,usr2.Id,NULL,NULL,NULL,NULL,terr2.Id,ddRecordTypeId);
                /*dealDeskRegion2.User__c =usr2.Id; 
                dealDeskRegion2.RecordTypeId = ddRecordTypeId;
                dealDeskRegion2.Territory__c = terr2.id;*/
                gssRegions.add(dealDeskRegion2);
            
            Inv_WorkBox_Region_Mapping__c dealDeskRegion3 = testUtil.newGSSUserRegion(false,usr2.Id,geo2.Id,NULL,NULL,NULL,NULL,ddRecordTypeId);
                /*dealDeskRegion3.User__c =usr2.Id; 
                dealDeskRegion3.RecordTypeId = ddRecordTypeId;
                dealDeskRegion3.Division__c = div2.id;*/
                gssRegions.add(dealDeskRegion3);
            
            //Insert gssRegions;
            
            gssRegions[0].TERR_HIER_3__c = area.id;
            gssRegions[1].TERR_HIER_5__c = terr.id;
            
            gssRegions[2].TERR_HIER_1__c = geo.id;
            
            //Update gssRegions;
        test.stopTest();
        
    }
    
    // covers : PSA_Inv_WorkBoxReagionHandler 
    @isTest
    public static void userRegionTestIW()
    {
        test.startTest();
            Inv_WorkBox_Region_Mapping__c iwRegion1 = testUtil.newGSSUserRegion(false,usr2.Id,geo2.Id,NULL,NULL,NULL,NULL,iwRecordTypeId);
            Insert iwRegion1;
        
            iwRegion1.TERR_HIER_2__c = reg2.Id;
            update iwRegion1;
        
            iwRegion1.TERR_HIER_3__c = area2.Id;
            update iwRegion1;
            
        test.stopTest();
        
    }
    
    
    // covers : PSA_Inv_WorkBoxReagionHandler 
    @isTest 
    public static void userRegionTestRAMD()
    {
        test.startTest();
        
            Inv_WorkBox_Region_Mapping__c iwRegion2 = testUtil.newGSSUserRegion(false,usr2.Id,geo.Id,NULL,NULL,NULL,NULL,ramdRecordTypeId);
            Insert iwRegion2;
            
            iwRegion2.TERR_HIER_4__c = zone.Id;
            update iwRegion2;
        
            iwRegion2.TERR_HIER_5__c = terr.Id;
            update iwRegion2;
        
        test.stopTest();
        
    }
    
    // covers : PSA_Inv_WorkBoxReagionHandler 
    @isTest 
    public static void userRegionTestCHIME()
    {
        test.startTest();
        
            Inv_WorkBox_Region_Mapping__c iwRegion3 = testUtil.newGSSUserRegion(false,usr2.Id,geo.Id,NULL,NULL,NULL,NULL,chimeRecordTypeId);
            Insert iwRegion3;
            
            iwRegion3.TERR_HIER_1__c = geo2.Id;
            update iwRegion3;
        test.stopTest();
        
    }

    @isTest 
    public static void IW_reUsableMultiSelectLookupCtrlTest()
    {
        test.startTest();
        IW_reUsableMultiSelectLookupCtrl.getAccountInternal(acct2.Id);
        test.stopTest();
    }


    @isTest 
    public static void accountandProd()
    {
        test.startTest();
        IW_getRequestWatchers.getAccountIdInternal(acct.Id);
        IW_getRequestWatchers.getProductValues();
        test.stopTest();
    }
    
    class IW_NewRegionWrapper {
        Id user;
        List<IW_Region> regions;
        String recordType;
    }
    
    class IW_Region {
        String type;
        Id id;
    }
    
    class watcherWrapperCls{ 
        public String Id;
        Public String Name;
        watcherWrapperCls(){}   
    }
}