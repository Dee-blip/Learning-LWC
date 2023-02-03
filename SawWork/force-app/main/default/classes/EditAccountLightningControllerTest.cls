/**
   History test
      
      --Developer       --Date         --Description        --Story
      Ruchika sharma    30/06/2017     Created this Class   SFDC-1592
        
*/
@isTest
private class EditAccountLightningControllerTest {
	private static Integer numberOfTestAccounts=10;
	 @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();

            Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();
            User accOwner = utilTestClass.CreateUser(utilTestClass.getRandomString(6), testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
            User ddUser = utilTestClass.CreateUser(utilTestClass.getRandomString(4)+'dd', 'Deal Desk', 'Deal Desk');
            List<User> userList = new List<User>();
            userList.add(ddUser);
            userList.add(accOwner);
            insert userList;        
           
            System.runAs(accOwner)
            {
                List<Account> activeAccounts = new List<Account>();
                activeAccounts.add(new Account(Name='Deal Desk', BillingCountry='USA', ShippingCountry='United States Of America',Type='Indirect Customer - Active', Website='testinacc.com', BillingState='MA'));
				activeAccounts.add(new Account(Name='Deal Desk No country', Website='testinacc.com'));
                insert activeAccounts;

            }
        }
    }
	@isTest static void test_method_Pos() {
		// Implement test code
		List<Account> listOfTestAccounts = [select id,name, Deal_Desk_Special_Instructions__c from Account where name='Deal Desk'];
		List<User> ddUser = [select id from user where profile.Name='Deal Desk' And isActive=true];
		System.debug(LoggingLevel.ERROR,'ddUser in EditAccountLightningControllerTest'+ddUser);
		String deslDeskInstructionTest = 'testing deslDeskInstructionTest';
		if(ddUser!=null && !ddUser.isEmpty()){
		for(Account acc: listOfTestAccounts){
						System.runAs(ddUser[0]){
						PageReference pageRef = Page.EditAccountLightning;
			            Test.setCurrentPage(pageRef);
			            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
					    EditAccountLightningController testController = new EditAccountLightningController(sc);
					    EditAccountLightningController.updateAccountRecord(acc.id,deslDeskInstructionTest);
					    
				}
			}
			Account ddAcc = [select id, Deal_Desk_Special_Instructions__c from Account where id=:listOfTestAccounts[0].id];
			System.debug(LoggingLevel.Error,'deslDeskInstructionTest:: '+ ddAcc.Deal_Desk_Special_Instructions__c);
			System.assertEquals(ddAcc.Deal_Desk_Special_Instructions__c,deslDeskInstructionTest);
		}

	}

	@isTest static void test_method_Neg() {
		// Implement test code
		List<Account> listOfTestAccounts = [select id,name, Deal_Desk_Special_Instructions__c from Account where name='Deal Desk No country'];
		List<User> ddUser = [select id from user where profile.Name='Deal Desk' And isActive=true];
		System.debug(LoggingLevel.ERROR,'ddUser in EditAccountLightningControllerTest'+ddUser);
		String deslDeskInstructionTest = 'testing deslDeskInstructionTest';
		if(ddUser!=null && !ddUser.isEmpty()){
		for(Account acc: listOfTestAccounts){
						System.runAs(ddUser[0]){
						PageReference pageRef = Page.EditAccountLightning;
			            Test.setCurrentPage(pageRef);
			            //ApexPages.CurrentPage().getparameters().put('id',listOfTestAccounts[0].id);
			            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
					    EditAccountLightningController testController = new EditAccountLightningController(sc);
					    try{
					    	EditAccountLightningController.updateAccountRecord(acc.id,deslDeskInstructionTest);
						}catch(Exception e){
							 System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
							
						}
					}
					    
				}
			}
			
		}
	

	
}