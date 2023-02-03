/*
* Created By 	: Vandhana Krishnamurthy
* Purpose		: Test Class for SC_CaseTriggerHelperClass3
* Date			: 22 June 2020
* 
* Developer                        Date                            						Changes
* ___________________________________________________________________________________________________________________________________________________
* Vandhana                      22 June 2020              ESESP-2597 : New "instant Engagement Request" flag for Sev 1 cases for support advocacy services
  Sumukh SS					 27 Dec 2020			   ESESP-2235 : Akatec Enhanced Milestones
  Vishnu Sharma                02 Dec 2020              ESESP-5772 : Prevent OCID field update if team member not present
*/ 

@isTest(seeAllData=false)
public class SC_CaseTriggerHelperClass3Test 
{
    
    @testSetup
    static void dataSetup()
    {
        utilTestClass.createCustomSettings();
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestSepcialEscalationAccount');   
        acc.Support_Advocacy_Special_Escalation__c = true;
        acc.Support_Level__c='Standard';
        accList.add(acc);
        insert accList;
        
        List<Technical_Escalation_Config_Interface__c> lstTECI = new List<Technical_Escalation_Config_Interface__c>();
        Technical_Escalation_Config_Interface__c teci;
        for(Integer i=0; i<3; i++)
        {
            teci = new Technical_Escalation_Config_Interface__c();
            teci.Support_Level__c = 'supportAdvocacySpecialEscalation';
            teci.Severity__c = i+1;
            teci.Time_Hours__c = i;
            lstTECI.add(teci);
        }
        insert lstTECI;
    }
    
    public static testMethod void testSpecialEscalation()
    {
        Id accId = [Select Id from Account where Support_Advocacy_Special_Escalation__c = true limit 1].Id;
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = accId;
        newCase.origin='Akamai';
        newCase.Severity__c = '1';
        newCase.Sub_Type__c = 'Product Support';
        newCase.Work_Type__c = 'Reactive';
        newCase.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        newCase.Status = 'Unassigned';
        newCase.Request_Sub_Type__c = 'N/A - Not Applicable';
        
        Test.startTest();
        insert newCase;
        newCase.Escalate_Technical_Mgmt_Case__c = true;
        update newCase;
        Test.stopTest();
    }
    
    static testMethod void testAMGUseCase()
    {
        Account acc = utilTestClass.CreateAccount('__ Test1 Account121');  
        insert acc;
        
        Profile pr = [select id from profile where name='Support - AMG Agent'][0];
        User usr = new User(alias = 'user', email='testa@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='8592472__usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;        
        List<Case> csList = new List<Case>();        
        Case cp2 = new Case();
        cp2.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        cp2.AccountId= acc.id;
        cp2.Subject= 'Test AMG autogen';
        cp2.Description ='Test AMG autogen';
        cp2.Origin='Autogen';
        cp2.Status = 'Assigned';
        cp2.Validation_Override__c = true;
        cp2.OwnerId = usr.Id;
        csList.add(cp2);
        
        
        insert csList;
        Test.startTest();
        cp2.Status = 'Closed';
        cp2.AKAM_Closed_Date__c = Date.today();
        cp2.Validation_Override__c = true;        
        update cp2;     
        cp2.Status = 'Assigned';
        update cp2;
        test.stopTest();
    }
    
    public static testMethod void testEnhancedMilestone()
    {
        Test.startTest();
        
        User usr = [select id from user where isactive=true and profile.name='Support - Tech Support Manager' limit 1];
        
        /*Account acc = utilTestClass.CreateAccount('__ Test Enhanced Acc');
        acc.Support_Level__c='Standard';
        insert acc;*/
       	Account acc = new Account(Name='Test Account IP Address Akatec',Type='Brand - Active', support_level__c = 'Standard', Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert acc;  
                
        Id akaSLAProcessId = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess where Name = 'Standard' and IsVersionDefault = TRUE and IsActive = TRUE].Id;
        
        Entitlement akaEnt = new Entitlement();
        akaEnt.SlaProcessId = akaSLAProcessId;
        akaEnt.StartDate = System.today();
        akaEnt.Name = 'Standard';
        akaEnt.AccountId = acc.Id;
        insert akaEnt;
        
        List<Case> csList = new List<Case>();        
        Case newCase = new Case();
        newCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.AccountId= acc.Id;
        newcase.EntitlementId=akaEnt.id;
        newCase.Subject= 'Test Akatec';
        newCase.Description ='Test Akatec';
        newCase.Origin='Email';
        newCase.Sub_Type__c = 'Product Support';
        newCase.Request_Sub_Type__c = 'N/A - Not Applicable';
        newCase.Severity__c = '1';
        newCase.Work_Type__c = 'Reactive';
        newCase.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        newCase.Status = 'Unassigned';
        newCase.Validation_Override__c = true;
        newCase.OwnerId = usr.Id;
        
        csList.add(newCase);
        insert csList;
        
        newCase.Override_Next_Case_Update__c =datetime.now().addDays(1);
                newCase.Severity__c = '2';

        update newCase;
        Try{
            User techSupportManager = [SELECT Id FROM User WHERE Profile.Name = 'Support - Tech Support Manager' AND Isactive = True LIMIT 1];
        	System.runAs(techSupportManager){
                List<Enhanced_Milestone__c> enhancedMilestoneList = [Select Id from Enhanced_Milestone__c];
                Delete enhancedMilestoneList;
        	}
            List<Enhanced_Milestone__c> enhancedMilestoneList = [Select Id from Enhanced_Milestone__c];
            Delete enhancedMilestoneList;
        }
        Catch(Exception ex){
            System.debug('---Delete Failed--');
        }
		test.stopTest();
        
    }
    
    // test method to cover method validationForAuthorizedUserForOCIDEdit of class SC_CaseTriggerHelperClass3
     public static testMethod void testvalidationForAuthorizedUserForOCIDEdit()
    {
        Test.startTest();
        Try{
        Account acc = utilTestClass.CreateAccount('__ Test1 Account12213');  
        insert acc;
        Merge_Contract_Header__c contractRec1 = new Merge_Contract_Header__c();
      contractRec1.Name = 'Test1234';
      contractRec1.Account_Name__c = acc.ID;
      contractRec1.Original_Contract_Id__c ='Test1234';
      contractRec1.Contract_Type__c = 'Tier 1 Reseller';
    //  contractRec1.Parent_Contract__c =  contractRec.id;      
      insert contractRec1;
        List<Case> lstCase = new List<Case>();
        Case cs1 = new Case();
        cs1.Description = 'testPS1';
        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        cs1.Subject = 'testS2ET1';
        cs1.Service__c = 'Managed Integration';
        cs1.Validation_Override__c = true;
        cs1.AccountId = acc.Id;
        cs1.IR_Original_Contract_Id__c = contractRec1.Id;
        lstCase.add(cs1);
        insert lstCase;
        }catch(Exception ex){
            System.debug('Exception expected in Case insert'+ex);
        }
        Test.stopTest();
    }
    
}