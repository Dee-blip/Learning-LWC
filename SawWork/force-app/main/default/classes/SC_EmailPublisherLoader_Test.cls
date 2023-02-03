/*
__________________________________________________________________________________________________
* Name             : SC_EmailPublisherLoader_Test
* Created By       : Vandhana Krishnamurthy
* Created Date     : 17 December, 2016
* Purpose          : Test class for SC_EmailPublisherLoader

Last Modified Date          Last Modified BY              Purpose
----------------------   --------------------------     -------------
24 May 2017                 kusharma                        ESESP-529
21 February, 2018           Vandhana Krishnamurthy          ESESP-852
26 August, 2018             Vamsee S                        Changed Test Class to Seealldata False(ESESP-1624)
4 September 2018            Vandhana Krishnamurthy          ESESP-1559
29 September 2018           Vishnu Vardhan                  ESESP-2587
25 March 2020               Sumukh SS                       SOCC Runbooks changes
__________________________________________________________________________________________________
*/

@isTest(seeAllData=false)
public class SC_EmailPublisherLoader_Test 
{
    
    Static User newUser; 
    Static User adminUser;
    Static User adminUser3;
    Static List<User> lUsersToInsert = new List<User>();
    
    Static
    {
        newUser = utilTestClass.CreateUser('TstUsr1', 'Worldwide', 'Support - Tech Support Agent');
        lUsersToInsert.add(newUser);
        
        adminUser = utilTestClass.CreateUser('TstUsr2', 'Worldwide', 'System Administrator');
        lUsersToInsert.add(adminUser);
        
        User adminUser2 = utilTestClass.CreateUser('TstUsr3', 'Worldwide', 'System Administrator');
        lUsersToInsert.add(adminUser2);
        
        adminUser3 = utilTestClass.CreateUser('TstUsr4', 'Worldwide', 'System Administrator');
        lUsersToInsert.add(adminUser3);
        
        insert lUsersToInsert;
        
        CollaborationGroup cg = new CollaborationGroup();
        cg.Name = 'Service Incident Notifications';
        cg.CollaborationType = 'Public';
        
        
        System.runAs(adminUser2)
        {
            utilTestClass.createCustomSettings();
            insert cg;
        }
        
        Id cgId = [Select Id from CollaborationGroup where Name = 'Service Incident Notifications' limit 1].Id;
        FeedItem fi = new FeedItem();
        fi.Body = 'Post body 1';
        fi.Title = 'New Title';
        fi.ParentId = cgId;
        
        System.runAs(newUser)
        {
            insert fi;
        }
        
        fi = [Select Body from FeedItem where Title = 'New Title'];
        fi.Body = 'Updated body';
        
        System.runAs(newUser)
        {
            update fi;
        }
    }
    
    @isTest static void testEmailLoader()
    {
        /*User newUser = utilTestClass.CreateUser('TstUsr1', 'Worldwide', 'Support - Tech Support Agent');
insert newUser;
User adminUser = utilTestClass.CreateUser('TstUsr2', 'Worldwide', 'System Administrator');
insert adminUser;*/
        System.runAs(adminUser)
        {
            SC_EmailPublisherLoader obj = new SC_EmailPublisherLoader();
            Account acc = utilTestClass.CreateAccount('test displayCaseTasks');
            insert acc;
            Case objCase = utilTestClass.createcase(acc.id);
            objCase.OwnerId = newUser.Id;
            objCase.Subject = 'Test Subject';
            update objCase;
            
            List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
            {
                new Map<String, Object>
                {
                    'targetSObject' => new EmailMessage(Subject = objCase.Subject,CcAddress = 'testuser@akamai123.com'),
                        'contextId' => objCase.Id,
                        'actionType' => 'Email',
                        'actionName' => 'Case.Email',
                        'fromAddressList' => new List<String> { 'salesforce@test.com' }
                }
            };
                List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
            Test.startTest();
            obj.onInitDefaults(defaultsSettings); 
            Test.stopTest();
        }
    }
    
    @isTest static void testNominumCarrierProd()
    {
        System.runAs(adminUser)
        {
            SC_EmailPublisherLoader obj = new SC_EmailPublisherLoader();
            Account acc = utilTestClass.CreateAccount('TestAcc');
            insert acc;
            
            Contact con = new Contact(FirstName = 'FirstName1',LastName = 'LastName2', AccountId = acc.Id, email = 'someaddress123@testemail.com',Login__c = 'test login',MailingCountry = 'India');
            insert con;
            
            Test.startTest();
            Case objCase = new case();
            objCase.OwnerId = newUser.Id;
            objCase.Subject = 'Test CP Case critical';
            objCase.ContactId = con.Id;
            objCase.AccountId = acc.Id;
            objCase.Do_Not_Show_in_Portal__c = false;
            objCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            objCase.Sub_Type__c = 'Carrier';
            objCase.Origin = 'Peer';
            insert objCase;
            
            List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
            {
                new Map<String, Object>
                {
                    'targetSObject' => new EmailMessage(Subject = objCase.Subject),
                        'contextId' => objCase.Id,
                        'actionType' => 'Email',
                        'actionName' => 'Case.Email',
                        'fromAddressList' => new List<String> { 'someaddress123@testemail.com' }
                }
            };
                List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
            
            obj.onInitDefaults(defaultsSettings); 
            Test.stopTest();
        }
    }
    
    @isTest static void testEmailLoaderForMSAzure()
    {   
        
        System.runAs(adminUser){
            Account msAzureAccount = utilTestClass.CreateAccount('Microsoft Azure');
            insert msAzureAccount;
            
            SC_EmailPublisherLoader obj = new SC_EmailPublisherLoader();
            Case objCase = new Case();
            objCase.AccountId = msAzureAccount.Id;
            objCase.Subject = '__ Test Subject';
            objCase.origin = 'Phone';
            objCase.description = 'Test Case from TC';            
            objCase.Partner_Account__c = msAzureAccount.Id;
            objCase.Partner_Joint_Troubleshooting_Status__c = 'Open';
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = false;
            objCase.OwnerId = newUser.Id;
            objCase.setOptions(dmo);
            insert objCase;                        
            List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
            {
                new Map<String, Object>
                {
                    'targetSObject' => new EmailMessage(Subject = objCase.Subject,CcAddress = 'testuser@akamai123.com'),
                        'contextId' => objCase.Id,
                        'actionType' => 'Email',
                        'actionName' => 'Case.Email',
                        'fromAddressList' => new List<String> { 'salesforce@test.com' }
                }
            };
                List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
            
            Test.startTest();
            obj.onInitDefaults(defaultsSettings); 
            Test.stopTest();
        }
    }
    
    static testMethod void testCreateFeedTracker()
    {
        List<FeedItem> fiList = new List<FeedItem>();
        fiList = [Select CreatedDate,CreatedById,LastEditDate,LastEditById,Body,Revision,ParentId
                  from FeedItem where CreatedDate = TODAY limit 1
                 ];
        System.assertNotEquals(fiList.size(),0);
    }
    
    /*** SOCC Related Changes ***/
    @isTest static void testManagedSecurityEmailAction()
    {
        System.runAs(adminUser)
        {
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            
            Account acc = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
            insert acc; 
            
            //Creating Case Product
            EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c();
            eb_product.Name = 'Kona DDoS Defender';
            eb_product.EB_MarkedForDeletion__c = false;
            eb_product.EB_Product__c='Kona DDoS Defender';
            eb_product.EB_Account__c=acc.id;
            insert eb_product;
            
            Contact con = new Contact(FirstName = 'FirstName1',LastName = 'LastName2', AccountId = acc.Id, email = 'someaddress123@testemail.com',Login__c = 'test login',MailingCountry = 'India', Primary_Contact_Method__c = 'Phone');
            insert con;
            
            // Creating Policy Domain
            Policy_Domain__c  Policy = new Policy_Domain__c();
            Policy.Name = 'TestClassPolicyDomain';
            Policy.Account_Name__c = acc.Id;
            Policy.Product__c = 'Kona DDoS Defender';
            Policy.Policy_Domain_State__c  = 'Active';
            Policy.Additional_Product__c = 'Application-based Monitoring';
            Insert Policy;
            
            authorized_contact__c authorizedcont = new authorized_contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=con.id, Case_Communication_Preferences__c='All Case Communications',Product_Interests__c='All');
            insert authorizedcont;
            
            Test.startTest();
            SC_SOCC_Escalation_List__c esclistrec=new SC_SOCC_Escalation_List__c (Policy_Domain__c =Policy.id,Name='Test escalation list name');
            insert esclistrec; 
            
            SC_SOCC_Escalation_via_Case_Email__c esccontactForEmail = new SC_SOCC_Escalation_via_Case_Email__c(Name='test',Escalation_List__c=esclistrec.id, Authorized_Contact__c=authorizedcont.id);
            insert esccontactForEmail;
            
            // Creating Handler Type
            Handler_Type__c  HandTypeRec = new Handler_Type__c (Name='Phone Call Handler Type',Fields_To_Show__c ='Situation_Instruction__c,Escalation_List__c');
            insert HandTypeRec;  
            
            // Creating Situation Catalog
            SC_SOCC_Situation_Catalog__c  SitCatRec = new SC_SOCC_Situation_Catalog__c (Handler_Type__c =HandTypeRec.id,Name='Kona DDoS DefenderAttack',Product__c	='Kona DDoS Defender',Situation_Class__c ='Attack',Handler_Type_picklist__c ='Phone Call Handler Type');
            insert SitCatRec; 
            
            
            Handler__c handlerrec= new Handler__c (Name='TestHandler',Handler_Type__c =HandTypeRec.id, Policy_Domain__c =Policy.id,Escalation_List__c =esclistrec.id);
            insert handlerrec;
            
            // Creating situation to handler mapping
            SC_SOCC_Situation_to_Handler_Mapping__c s2hrec = new SC_SOCC_Situation_to_Handler_Mapping__c (Policy_Domain__c =Policy.id,Situation__c =SitCatRec.id, Handler__c =handlerrec.id);
            insert s2hrec;
            
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            SC_EmailPublisherLoader obj = new SC_EmailPublisherLoader();
            
            Case objCase = new case();
            objCase.Subject = 'Test CP Case critical';
            objCase.ContactId = con.Id;
            objCase.Do_Not_Show_in_Portal__c=false;
            objCase.AccountId = acc.Id;
            objCase.Case_Product__c = eb_product.id;
            objCase.Policy_Domain__c=Policy.id;
            objCase.AuthorizedContacts__c = 'test@soocunique.com;test2@soccunique.com';
            objCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            objCase.Case_Situation_Handler__c = s2hrec.id;
            insert objCase;
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
            {
                new Map<String, Object>
                {
                    'targetSObject' => new EmailMessage(Subject = objCase.Subject),
                        'contextId' => objCase.Id,
                        'actionType' => 'SendEmail',
                        'actionName' => 'Case.Send_Email_SOCC',
                        'fromAddressList' => new List<String> { 'someaddress123@testemail.com' }
                }
            };
                List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
            
            obj.onInitDefaults(defaultsSettings);
            Test.stopTest();
            
            
        }
    }
    
    /*** END of SOCC Related Changes ***/
    
    /*** ESESP-2587 ***/
    @isTest static void testSecSalesEmail()
    {
        System.runAs(adminUser)
        {
            SC_EmailPublisherLoader obj = new SC_EmailPublisherLoader();
            Account acc = utilTestClass.CreateAccount('TestAccSOCC');
            insert acc;
            
            Contact con = new Contact(FirstName = 'FirstName1',LastName = 'LastName2', AccountId = acc.Id, email = 'someaddress123@testemail.com',Login__c = 'test login',MailingCountry = 'India');
            insert con;
            
            Case objCase = new case();
            objCase.Subject = 'Test CP Case critical';
            objCase.ContactId = con.Id;
            objCase.AccountId = acc.Id;
            objCase.AuthorizedContacts__c = 'test@soocunique.com;test2@soccunique.com';
            objCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('SecSales').getRecordTypeId();
            insert objCase;
            
            List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
            {
                new Map<String, Object>
                {
                    'targetSObject' => new EmailMessage(Subject = objCase.Subject),
                        'contextId' => objCase.Id,
                        'actionType' => 'SendEmail',
                        'actionName' => 'Case.SendEmailLightning_SecSales',
                        'fromAddressList' => new List<String> { 'someaddress123@testemail.com' }
                }
            };
                
                
                List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
            Test.startTest();
            obj.onInitDefaults(defaultsSettings);
            Test.stopTest();
        }
    }    
}