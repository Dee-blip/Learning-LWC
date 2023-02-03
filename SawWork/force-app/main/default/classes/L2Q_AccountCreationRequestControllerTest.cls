@isTest(seeAllData=false)

public class L2Q_AccountCreationRequestControllerTest {
    
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            User newUser = utilTestClass.CreateUser('TST_USR', 'Business Operations', 'Business Operations');
            insert newUser;
        }
    }
        static User dmlUser = utilTestClass.getTestRunUser();


        static ApexPages.StandardController stdController;

       private static testmethod void L2Q_AccountCreationTest(){
       
        Profile pr = [select id from profile where name='Business Operations'][0];
        Profile MarkProfileId = [select id from profile where name='Marketing - wo Import'][0];
        
            UserRole role = [select id, Name from UserRole where name=:GsmUtilClass.getGSMSettingValue('User_Role')][0];
            
            User accOwnerUser = new User(alias = 'bususer', email='businessop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='Businessops@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
          User MarkingUser = new User(alias = 'Maruser', email='Marksop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='Markops@akamai.com',profileid = MarkProfileId.Id, UserRoleId = role.Id );
          
          Account Acc= new Account();
          
          
            
       Account_Creation_Request__c ACR=new Account_Creation_Request__c();
       Account_creation_request__c ACR1= new Account_creation_request__c();
      Territory_Mapping__c territoryMapping1;
           Account_Reassignment_Rule__c rule;
           system.runAs(dmlUser){
            User newUser = [Select Id, Alias, Name from User where Alias = 'TST_USR' limit 1][0];
            
             //territoryMapping1 = utilTestClass.createTerritoryMapping('ANZ - ANZ EAST' , 'Carrier North America_Carrier North America' , 'ANZ');
            territoryMapping1 = utilTestClass.createTerritoryMapping('APJ Carrier & Channels - Carrier ANZ', 'APJ', 'APJ Adjust');
            insert territoryMapping1;
            
             rule = utilTestClass.CreateAccountReassignmentRule(newUser.Name, newUser.Id, 'Sales Operations');
            rule.Territory_ID__c = territoryMapping1.Id;
            insert rule;
           }
         
       system.runas(accOwnerUser){
       test.starttest();
           

           ACR.Account_Name__c='ACR_Name';
           ACR.Website__c='www.google.com';
           ACR.country__c='India';
           ACR.state__c='Odisha';
           ACR.Vertical__c ='Public Sector';
           ACR.Sub_Vertical__c = 'PS - Higher Ed';
           ACR.Assign_To__c = rule.Id;
           insert ACR;
           
          
           Acc.Name='ACR__Swati';
           Acc.website='www.ACR.com';
           Insert Acc;
           
           ApexPages.currentPage().getParameters().put('id',ACR.Id);
            stdController=new ApexPages.StandardController(ACR);
            ApexPages.StandardController sc = new ApexPages.StandardController(Acc);
           AccountCreationController cntrl=new AccountCreationController(sc);
           cntrl.AddNewAccount();
           //cntrl.Cancel();
           
           ACRNewtoAssignedController ACRcntrl = new ACRNewtoAssignedController();
           ACRcntrl.AssignedTo();
           ACR.Status__c='Closed - Denied';
           ACR.Rejection_Reason_Code__c='Incomplete Information';
           update ACR;
           ACRcntrl.Cancel();
           
           L2Q_NewAccountCreationController NewAccCntrl =new L2Q_NewAccountCreationController();
           try{
           L2Q_NewAccountCreationController.DupAccountCheck(ACR.id);
           L2Q_NewAccountCreationController.CreateNewAccount(ACR.id);
           L2Q_NewAccountCreationController.CreateNewAccount(ACR.id);
           }catch(exception ex){
           
           }
          // NewAccCntrl.Cancel();
           L2Q_NewAccountCreationController.getErrorMessage(ACR.id);
           ACR.status__c='Closed - Denied';
           
           ACR.Rejection_Reason_Code__c='Incomplete Information';
           update ACR;
          
           ACRcntrl.AssignedTo();
           //ACRcntrl.Cancel();
           test.stoptest();
        }
        system.runas(MarkingUser){
       ApexPages.StandardController sc = new ApexPages.StandardController(Acc);
           AccountCreationController cntrl=new AccountCreationController(sc);
           cntrl.AddNewAccount();
           
           
           }
       
       }

       public static testmethod void testConvertCurrency()
        {

         Account Acc= new Account();
         acc.name='opptyacc';
         acc.website='www.oppacc.com';
         insert acc;
            Test.startTest();
           // Opportunity testOppty = SobjectRepository.getOpportunity();
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
   // opp.Channel_Manager__c = cm.Id;
    opp.End_Customer_Country__c = 'USA';
    opp.End_Customer_State__c = 'NY';
    opp.End_Customer_City__c = 'Buffalo';
    opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
    opp.CloseDate= Date.today();
    opp.Partner_Involved__c = acc.Id;
    opp.AccountId = acc.Id;
    opp.Deal_Reg_Account_Status__c='New Account';
    opp.Deal_Reg_Opportunity_Status__c='New Opportunity';
    insert opp;
    
    Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        oa.Order_Expires_Unless_Duly_Executed_By__c = Date.today().addMonths(8);
        insert oa;

            opp=SF1_OpportunityService.getOpportunity(opp.Id);
            SF1_OpportunityService.getExistingOpportunityList(opp, 1,1,null);
            SF1_OpportunityService.getOAForCurrentOpportunity(opp.Id);
            SF1_OpportunityService.getOpportunitiesForCurrentOwner(opp.Id);

            Test.stopTest();
        }

   


}