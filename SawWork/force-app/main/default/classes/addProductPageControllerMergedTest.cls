@isTest
private class addProductPageControllerMergedTest {
  static User dmlUser = new User(id=UserInfo.getUserId());
    static
    {
      utilTestClass.insertCustomSettings();
    } 
  private static List<Opportunity> testOppty = new List<Opportunity>();
  private static Integer oliSize = 2;
  public static Account acc= new Account();
  private static Map<Id, List<OpportunityLineItem>> opptyIdToOLIList= new Map<Id, List<OpportunityLineItem>>();
  @testSetup static void createTestData() {
    Opportunity opp = utilTestClass.CreateOpportunity('testOpptyForEMRI','1-Create');
        opp.CurrencyIsoCode = 'USD';

    opp.CloseDate = Date.today().addDays(60);
    testOppty.add(opp);
    insert testOppty;
    Test.startTest();
    opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(testOppty,oliSize , 'USD');
    Test.stopTest();

    
        System.runAs(utilTestClass.getTestRunUser())
        {
      User accOwnerUser = utilTestClass.CreateUser('accUsr2', 'Marketing Operations', 'Marketing Operations');
          insert accOwnerUser;

          acc = utilTestClass.CreateAccount('tstAcc');
          acc.OwnerId = accOwnerUser.Id;
          acc.BillingCountry = 'USA';
          acc.BillingPostalCode ='89789';
          acc.BillingState = 'MA';
          acc.Vertical__c = 'Akamai Internal';
          acc.Website = 'www.nowwhere@torun.com';
          system.runAs(accOwnerUser){
            insert acc;
          }
        }

    //if(opptyIdToOLIList!=null && !opptyIdToOLIList.isEmpty())
    
    //    oliList.addAll(opptyIdToOLIListValues);
    System.debug('opptyIdToOLIList: '+opptyIdToOLIList);
    System.debug('testOppty: '+testOppty);
  }
  
  @isTest static void testProductWizardPageMethods() {
    // Implement test code
      //createTestData();
      Test.startTest();
      testOppty = [select id, name, CloseDate from opportunity where Name = 'testOpptyForEMRI'];
      System.debug('testOppty in test_method_one: '+testOppty);
      System.debug('testOppty[0].id: '+testOppty[0].id);
      //Account acc = [select id,name from Account];
      if(testOppty!=null && !testOppty.isEmpty()){
        System.debug('inside if: ');
        PageReference pageRef = Page.addProductPageMerged;
              Test.setCurrentPage(pageRef);
              ApexPages.CurrentPage().getparameters().put('oppId',testOppty[0].id);

          ApexPages.StandardController sc = new ApexPages.StandardController(testOppty[0]);
          addProductPageControllerMerged testController = new addProductPageControllerMerged(sc);
          //addProductPageControllerMerged.opportunityLineItemWrapper inneropportunityLineItemWrapperObject = new addProductPageControllerMerged.opportunityLineItemWrapper();
          addProductPageControllerMerged.opportunityWrapper oppWrapperObj = (addProductPageControllerMerged.opportunityWrapper)JSON.deserialize(testController.OpptyJson, addProductPageControllerMerged.opportunityWrapper.class);
          List<addProductPageControllerMerged.opportunityLineItemWrapper> oliws = (List<addProductPageControllerMerged.opportunityLineItemWrapper>)JSON.deserialize(testController.getOliRecords(), List<addProductPageControllerMerged.opportunityLineItemWrapper>.class);

          System.debug('testController: '+testController);
          testController.getProfile();
          testController.getaddedLineItems();
          testController.getOliRecords();
          
          testController.getDependentPicklist();
          //String oppCategory = testController.getOpportunitySubCategoryToLossReasonMap();
          testController.getProducts();
          testController.getFieldsToTheirEditMode();
          testController.getFieldsToValue();
          addProductPageControllerMerged.searchAccount(acc.Name);
          //addProductPageControllerMerged.searchAccount(acc.name);
          //Object accWrapperObj = addProductPageControllerMerged.searchAccount(acc.name);
          //System.debug('accWrapperObj.accountName: '+accWrapperObj.get(0).accountName);
          //System.assertEquals(String.valueOf(accWrapperObj.accountName),acc.name);
          System.assertEquals(oliSize,oliws.size());
          //System.debug('getOliRecord: '+testController.getOliRecord());
          System.assertEquals(oppWrapperObj.Name,testOppty[0].name);
          System.assertEquals(oppWrapperObj.oppId,testOppty[0].id);
          addProductPageControllerMerged.save(testController.OliRecords,testController.OpptyJson,testController.OliRecords);
            }
            Test.stopTest();

  }
    
    @isTest static void getOpportunityCategoryToLossReasonMapTest()
    {
        Test.startTest();
        testOppty = [select id, name, CloseDate from opportunity where Name = 'testOpptyForEMRI'];
        PageReference pageRef = Page.addProductPageMerged;
              Test.setCurrentPage(pageRef);
              ApexPages.CurrentPage().getparameters().put('oppId',testOppty[0].id);

          ApexPages.StandardController sc = new ApexPages.StandardController(testOppty[0]);
          addProductPageControllerMerged testController = new addProductPageControllerMerged(sc);
        String json = testController.getOpportunityCategoryToLossReasonMap();
        System.assertNotEquals(null, json);
        Test.stopTest();
    }
  
}