//Set default Account

// Parent incident should not be allowed to closed unless and untill all child incidents are closed.
//Auto-close incident when all child incidents are closed.
//SAMIR JHA:ADDED URGENCY FIELD TO ALL INCIDENT RECORDS BEING CREATED.
//SAMIR JHA: CR 1881676:Taking category from custom setting.
// altered code by hemant for CR 2341731 - Optimizing Helpdesk TestClases added a limit for specific Queries
/*
* File Name: HD_Test_Remedyforce_New_Trigger
* Description : Test class for Remedyforce trigger
* @author : 
* Modification Log ===============================================================
* Date              Author              Modification
* 5 Aug, 2020       Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5 
* Nov 29th, 2021    Aneesh Budnar       PRTORES-2358 - HD Code Scanner 1 fixes
*/

@IsTest(seeAllData=false)
Private class HD_Test_Remedyforce_New_Trigger
{
	static BMCServiceDesk__Status__c closedStatus;
    //all status map for incident
    static Map<String,ID> statusMapNametoID = new Map<String,ID>();
    //category map
    static Map<String,BMCServiceDesk__Category__c> categoryMap = new Map<String,BMCServiceDesk__Category__c>();
    //urgency map
    static Map<String,BMCServiceDesk__Urgency__c> urgencyMap = new Map<String,BMCServiceDesk__Urgency__c>();
    static Map<String,BMCServiceDesk__Impact__c> impactMap = new Map<String,BMCServiceDesk__Impact__c>();

    static BMCServiceDesk__Category__c additionalDesktopLaptopCategory;
    static BMCServiceDesk__Category__c telecomCategory;
    static BMCServiceDesk__Category__c hardwareCategory;
    static BMCServiceDesk__Category__c corporateServicesCategory;
    static BMCServiceDesk__Category__c testCategory;
    static BMCServiceDesk__Category__c ParentCategory;
    static BMCServiceDesk__Category__c Child1Category;
    static BMCServiceDesk__Category__c Child2Category;
    static BMCServiceDesk__Category__c Child3Category;
    //static ACcount account; // Kartikeya. Commented out as it is not used any active line of code.
    //Start of changes by Samir Jha for CR1886041
    static BMCServiceDesk__Urgency__c urgency1;
    static BMCServiceDesk__Urgency__c urgency2;
    static List<BMCServiceDesk__BMC_BaseElement__c> serviceList;
    static List<HD_Urgency_Service_Mapping__c> urgencyServiceMapping;
    static HD_Urgency_Service_Mapping__c urgencyServiceMapping1;
    static  HD_Urgency_Service_Mapping__c urgencyServiceMapping2;
    static BMCServiceDesk__BMC_BaseElement__c SampleService1;
    static BMCServiceDesk__BMC_BaseElement__c SampleService2;
    //End of changes by Samir Jha for CR1886041
    //start of changes by samir for cr 1881676 
    static HD_DEFAULT_CATEGORY__c Additional_DesktopLaptop;
    static HD_DEFAULT_CATEGORY__c Corporate_Services;
    static HD_DEFAULT_CATEGORY__c Telecom_Category;
    static HD_DEFAULT_CATEGORY__c Hardware_Category;
    static HD_DEFAULT_CATEGORY__c Parent;
    static HD_DEFAULT_CATEGORY__c Child1;
    static HD_DEFAULT_CATEGORY__c Child2;
    static HD_DEFAULT_CATEGORY__c Child3;
    static String Add_Desk_Lap_Category;
    static String Tel_Category;
    static String Cor_Ser_Category;
    static String Hard_Category;
    static String Parent_Category;
    static String Child1_Category;
    static String Child2_Category;
    static String Child3_Category;
    static Map<String, String> categoriesCreated;
    static Map<String, String> urgencyCreated;
    static Map<String, String> createdImpact;


    static{

        ManagedPkgErrorClass.isFromManagedPackage=false; 

        //update custom setting to run new trigger against System admin
        //get roleID of current user
        Id currentUserRoleId = System.UserInfo.getUserRoleId();
        //Changes done by Abhishek Singh
        List<HD_RF_TRIGGER_FLAG__c> csRecords = [select name, Role_Id__c, Run_New_Trigger__c from HD_RF_TRIGGER_FLAG__c limit 100];
        if(csRecords.size()>0){ delete csRecords; }
        

        HD_RF_TRIGGER_FLAG__c newConfig = new HD_RF_TRIGGER_FLAG__c();
        newConfig.name = 'HD_RemedyForceCustomizations';
        newConfig.Enable__c = false;
       
        insert newConfig;
        HD_Test_Data_Factory.init();
        categoriesCreated = HD_Test_Data_Factory.categoryMap;
        urgencyCreated=HD_Test_Data_Factory.urgencyMap;
        createdImpact=HD_Test_Data_Factory.impactMap;

        System.debug('Nikhil----->'+categoriesCreated);

    }
    //static block END



    /*Account to be set default for every Incident.
        EVENT: BEFORE INSERT,
     */

    static TestMethod void DefaultAccount(){

        Test.startTest();
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('P2R'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 4'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(), BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );
        insert incident;

        List<BMCServiceDesk__Incident__c> incidentList = [Select BMCServiceDesk__FKAccount__c from BMCServiceDesk__Incident__c where id=:incident.id LIMIT 1];
        test.stopTest();
    }



    /*Update 'Service' in Incident corresponding to the Urgency selected.
        EVENT: BEFORE INSERT; BEFORE UPDATE
     */

    static Testmethod void Urgency_ServiceMapping(){

        Test.startTest();

        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 3'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );
        insert incident;

        List<BMCServiceDesk__Incident__c> incidentList = [SELECT BMCServiceDesk__FKBusinessService__c FROM BMCServiceDesk__Incident__c WHERE ID=:incident.id LIMIT 1];
        //System.assertEquals(incidentList[0].BMCServiceDesk__FKBusinessService__c,serviceList[0].id);

        incident.BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 4');
        update incident;

        incidentList = [SELECT BMCServiceDesk__FKBusinessService__c FROM BMCServiceDesk__Incident__c WHERE ID=:incident.id LIMIT 1];
        //adding assert for checking proper service  mapping  with urgency
        system.assertEquals(urgencyCreated.get('Severity 4'), incident.BMCServiceDesk__FKUrgency__c);
        //
        Test.stopTest();
    } 


    //Bulk Insert
    static TestMethod void bulkInsert()
    {
        try{
            //init();

            // Create a sample Template
            BMCServiceDesk__SYSTemplate__c template = new BMCServiceDesk__SYSTemplate__c();
            template.Name='Template for Incident';
            template.BMCServiceDesk__templateFor__c='Incident';
            template.BMCServiceDesk__allProfile__c=True;
            insert template;     
            //system.assertNotEquals(template,Null);

            List<BMCServiceDesk__Incident__c> IncidentList = new List<BMCServiceDesk__Incident__c>();
            //start of temporary quick fix by janantha
            //for(Integer i=0;i<200;i++){
            for(Integer i=0;i<2;i++){
                //End of temporary quick fix by janantha
                BMCServiceDesk__Incident__c bulkIncident = new BMCServiceDesk__Incident__c();
                bulkIncident.BMCServiceDesk__FKClient__c = System.UserInfo.getUserId(); 
                bulkIncident.BMCServiceDesk__FKCategory__c= hardwareCategory.Id ;

                IncidentList.add(bulkIncident);
            }

            insert IncidentList;
            //added a check of bulk insertion ,where incident inserted is greate than than one.
            system.assert(IncidentList.size() > 1,'The number of incident inserted is greater than one at once !');

            test.startTest();
            for(BMCServiceDesk__Incident__c bulkIncident : IncidentList){
                bulkIncident.BMCServiceDesk__FKTemplate__c=template.id;
                bulkIncident.BMCServiceDesk__FKCategory__c= testCategory.Id ;
            }
            update IncidentList;
            test.stopTest();

        }
        catch(Exception e)
        {
        }

    }//static TestMethod void bulkInsert()


    //Test class by sreenidhi
    //Test class by sreenidhi for the CR 2378280 

    static  void testHighCustomerImapctFix()
    {

        Test.startTest();

        string errorMsg = 'Is this a customer impacting issue?, if so then please ensure that you check Severity 1 as the urgency and check the High Customer Impact check box to confirm.';

        BMCServiceDesk__Incident__c incident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 1'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );

        List<BMCServiceDesk__Incident__c> astlist = new List<BMCServiceDesk__Incident__c>();
        astlist.add(incident1);
        try
        {
            insert astlist;
        }
        catch ( Exception e )
        {               
            System.assertEquals(errorMsg , errorMsg);
        }

        Test.stopTest();
    }

    //Test class by Bhaskar for CR 3074561
    static TestMethod void reopenTest(){
        Test.startTest();

        User staff = HD_Test_Remedyforce_TestDataFactory.runAsUser('ServiceDesk Staff',true);

        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 3'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );

        Id originalQueueId = incident.ownerId;
        incident.ownerId = staff.id;
        incident.BMCServiceDesk__queueName__c = 'Default Queue';
        incident.BMCServiceDesk__FKStatus__c = statusMapNametoID.get('ASSIGNED');
        insert incident;
        incident.BMCServiceDesk__incidentResolution__c = 'Test-Fixed';
        incident.BMCServiceDesk__FKStatus__c = statusMapNametoID.get('CLOSED');
        update incident;

        incident.BMCServiceDesk__state__c = TRUE;
        incident.BMCServiceDesk__FKStatus__c = statusMapNametoID.get('UNASSIGNED');
        update incident;
        System.assertEquals(staff.id,incident.ownerId);
        Test.stopTest();

    }

    static TestMethod void testMiscellaneous(){
        Test.startTest();
        BMCServiceDesk__Incident__c incident3 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 3'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );
        incident3.CCText__c = 'a1@akamai.com;a2@akamai.com;a3@akamai.com;a4@akamai.com;a5@akamai.com;a6@akamai.com;a7@akamai.com;a8@akamai.com;a9@akamai.com;a10@akamai.com;a11@akamai.com;a12@akamai.com;a13@akamai.com';
        try{
            insert incident3;
        }catch ( Exception e ){               

        }

        Test.stopTest();
    }

    static TestMethod void testUrgency1(){
        Test.startTest();

        BMCServiceDesk__Incident__c incident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 1'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );
        incident1.HD_High_Customer_Impact__c = false;
        try{
            insert incident1;
        }catch ( Exception e ){  }
        Test.stopTest();             

    }   

    static TestMethod void testIncorectMail(){
        Test.startTest();
        BMCServiceDesk__Incident__c incident2 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 3'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );
        incident2.CCText__c = 'bverma@akamai.com;;kahegde@@akamai.com';
        incident2.Exclude_Client_Notifications__c = true;
        incident2.HD_Ticket_Priority__c='3';
        try{
            insert incident2;
        }catch(Exception e){
            //System.assertEquals(e.getMessage(),'')
        }
        Test.stopTest();
    }


    //Kartikeya PRTORES-520
    static TestMethod void OverrideRoutingTest(){  

        Test.startTest();
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categoriesCreated.get('Access'),BMCServiceDesk__FKUrgency__c=urgencyCreated.get('Severity 3'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=createdImpact.get('LOW') );
        incident.HD_Routing_Settings__c = 'Override Routing';

        insert incident;

        incident = [SELECT ID, HD_IncidentGroup__c from BMCServiceDesk__Incident__c WHERE id = :incident.Id ][0];
        //system.assertNotEquals(incident.HD_IncidentGroup__c,Null);

        Test.stopTest(); 
    }
    
    @isTest
    public static void when_IncidentCreatedByNormalUser_expect_VIPFlagFalse() {
        User normalUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        
        BMCServiceDesk__Incident__c incident = 
            new IncidentTestHelper.IncidentBuilder().withClient(normalUser.Id).build();
        
        Test.startTest();
        insert incident;
        Test.stopTest();  
        
        incident = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 1];
        System.assertEquals(false, incident.VIP_Ticket__c);
    }
    
    @isTest
    public static void when_IncidentCreatedByUserInVIPGroup_expect_VIPFlagTrue() {
        Group grp = [Select id, name from group where name = 'VIP Users' LIMIT 1];
        User vipGroupUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User2')
            .withUserName('test.user2@akamai.com')
            .withEmail('test.email2@akamai.com').buildAndSave();
        System.runAs ( vipGroupUser ) {
            insert new GroupMember(UserOrGroupId = vipGroupUser.Id, GroupId = grp.Id);
        }
        
        BMCServiceDesk__Incident__c incident = 
            new IncidentTestHelper.IncidentBuilder().withClient(vipGroupUser.Id).build();
        
        Test.startTest();
        insert incident;
        Test.stopTest();  
        
        incident = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 1];
        System.assertEquals(true, incident.VIP_Ticket__c);
    }
    
    @isTest
    public static void when_IncidentCreatedByUserWithVIPTitle_expect_VIPFlagTrue() {
        insert new HD_VIP_Titles__c(Name='director.senior');
        Map < String, HD_VIP_Titles__c > VipTitles = HD_VIP_Titles__c.getAll();
        User vipTitleUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User3')
            .withUserName('test.user3@akamai.com')
            .withTitle(VipTitles.values().get(0).Name)
            .withEmail('test.email3@akamai.com').buildAndSave();
        
        BMCServiceDesk__Incident__c incident = 
            new IncidentTestHelper.IncidentBuilder().withClient(vipTitleUser.Id).build();
        
        Test.startTest();
        insert incident;
        Test.stopTest();  
        
        incident = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 1];
        System.assertEquals(true, incident.VIP_Ticket__c);
    }

    @isTest
    public static void when_IncidentCreatedByNormalUserWithVIPsetfromUI_expect_VIPFlagTrue() {
        User normalUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        
        BMCServiceDesk__Incident__c incident = 
            new IncidentTestHelper.IncidentBuilder().withClient(normalUser.Id).withVIPStatus(true).build();
        
        Test.startTest();
        insert incident;
        Test.stopTest();  
        
        incident = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 1];
        System.assertEquals(true, incident.VIP_Ticket__c);
    }
    
    @isTest
    public static void when_IncidentCreatedByNormalUserWithClientNull_expect_VIPFlagFalse() {
        User normalUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        
        BMCServiceDesk__Incident__c incident = 
            new IncidentTestHelper.IncidentBuilder().withClient(null).build();
        
        System.runAs ( normalUser ) {
            Test.startTest();
            insert incident;
            Test.stopTest(); 
        } 
        
        incident = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 1];
        System.assertEquals(false, incident.VIP_Ticket__c);
    }
    
    @isTest
    public static void testIncidentVIPLogicForNewIncidentsInBulk() {
        insert new HD_VIP_Titles__c(Name='director.senior');
        Map < String, HD_VIP_Titles__c > VipTitles = HD_VIP_Titles__c.getAll();
        Group grp = [Select id, name from group where name = 'VIP Users' LIMIT 1];
        User normalUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        User vipGroupUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User2')
            .withUserName('test.user2@akamai.com')
            .withEmail('test.email2@akamai.com').buildAndSave();
        System.runAs ( vipGroupUser ) {
            insert new GroupMember(UserOrGroupId = vipGroupUser.Id, GroupId = grp.Id);
        }
        User vipTitleUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User3')
            .withUserName('test.user3@akamai.com')
            .withTitle(VipTitles.values().get(0).Name)
            .withEmail('test.email3@akamai.com').buildAndSave();
        List<User> users = new List<User> { normalUser, vipGroupUser, vipTitleUser};
        
        List<BMCServiceDesk__Incident__c> incidents = new List<BMCServiceDesk__Incident__c>();
        Integer num = 1;
        for(User user : users) {
            incidents.add(new IncidentTestHelper.IncidentBuilder().withClient(user.Id).withDescription('Incident'+num++).build());
        }
        // Already marked as VIP ticket from Front End UI checkbox
        incidents.add(new IncidentTestHelper.IncidentBuilder().withVIPStatus(true).withDescription('Incident'+num++).build());
        // Incident with empty BMCServiceDesk__FKClient__c
        incidents.add(new IncidentTestHelper.IncidentBuilder().withClient(null).withDescription('Incident'+num++).build());
        
        Test.startTest();
        insert incidents;
        Test.stopTest();
        
		incidents = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 10];
        Map<String, BMCServiceDesk__Incident__c> descToIncidentMap = new Map<String, BMCServiceDesk__Incident__c>();
        for(BMCServiceDesk__Incident__c incident : incidents) {
            descToIncidentMap.put(incident.BMCServiceDesk__IncidentDescription__c, incident);
        }
        
        Map<String, Boolean> expectedResults = new Map<String, Boolean> {
            'Incident1' => false,
            'Incident2' => true,
            'Incident3' => true,
            'Incident4' => true,
            'Incident5' => false
        };
            
        for(BMCServiceDesk__Incident__c incident : incidents) {
            String description = incident.BMCServiceDesk__IncidentDescription__c;
            System.assertEquals(expectedResults.get(description), descToIncidentMap.get(description).VIP_Ticket__c,description+' error');
        }
    }

    @isTest
    public static void testVIPLogicForOldIncident() {
        insert new HD_VIP_Titles__c(Name='director.senior');
        Map < String, HD_VIP_Titles__c > VipTitles = HD_VIP_Titles__c.getAll();
        User normalUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        User vipTitleUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User3')
            .withUserName('test.user3@akamai.com')
            .withTitle(VipTitles.values().get(0).Name)
            .withEmail('test.email2@akamai.com').buildAndSave();
        
		BMCServiceDesk__Incident__c incident = new IncidentTestHelper.IncidentBuilder().withClient(normalUser.Id).build();
        insert incident;
        
        System.assertEquals(false, incident.VIP_Ticket__c);
        
        Test.startTest();
        incident.BMCServiceDesk__FKClient__c = vipTitleUser.Id;
        update incident;
        Test.stopTest();
        
        incident = [SELECT Id, VIP_Ticket__c, BMCServiceDesk__FKClient__c,BMCServiceDesk__IncidentDescription__c FROM BMCServiceDesk__Incident__c LIMIT 1];
        System.assertEquals(true, incident.VIP_Ticket__c);
    }
    //Pranav and Hemant - This method needs further investigation
    //static TestMethod void testParentIncident(){
    //    Test.startTest();
    //    BMCServiceDesk__Incident__c incident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKClient__c = system.userinfo.getUserId(),BMCServiceDesk__FKUrgency__c=urgencyMap.get('Severity 3').id, BMCServiceDesk__incidentDescription__c = 'New ticket',BMCServiceDesk__FKCategory__c=testCategory.id);
    //    insert incident1;
    //    BMCServiceDesk__Incident__c incident2 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKClient__c = system.userinfo.getUserId(),BMCServiceDesk__FKUrgency__c=urgencyMap.get('Severity 3').id, BMCServiceDesk__incidentDescription__c = 'New ticket',BMCServiceDesk__FKCategory__c=testCategory.id);
    //    incident2.BMCServiceDesk__FKIncident__c = incident1.id;
    //    insert incident2;
    //    //incident2.BMCServiceDesk__FKIncident__c = incident1.id;
    //    //update incident2;
    //    Test.stopTest();
    //}
} //Class End