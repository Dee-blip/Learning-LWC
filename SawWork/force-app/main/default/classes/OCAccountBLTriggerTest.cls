/**
	OCAccountBLTriggerTest
    
    @Author: Ruchika Sharma <rsharma@akamai.com>
    
    @Description: Test class to test OCAccountBl_bi_bu trigger
 */
/* Putting seeAllData = true, to avoid inserting custom settings
with utilTestClass.insertCustomSetting methods, as it may hit governor limit*/
@isTest(seeAllData=false)
class OCAccountBLTriggerTest{

	static User dmlUser = new User(id=UserInfo.getUserId());
	static Account blAccount;
	static Campaign_Package__c testpack;
	static Account blAccount1;
	//util method to get Blacklisted account object
	static Online_Channel_Account_Blacklist__c getBlAccount(String accountId, String packageId ){
		Online_Channel_Account_Blacklist__c blAccountObj = new Online_Channel_Account_Blacklist__c(Account__c = accountId, Online_Channel_Package__c= packageId);
		return blAccountObj;
	}

	// u
	static Campaign_Package__c getOCPackage(){
		testpack=new Campaign_Package__c();
        testpack.Name='Testpack';
        testpack.Package_Id__c='esla';
        testpack.Is_Valid__c=true;
        return testPack;
	}

	static void init(){
		blAccount = utilTestClass.CreateAccount('gacct');
		testpack = getOCPackage();
		blAccount1 = utilTestClass.CreateAccount('ttesta');
		System.runAs(dmlUser){
			insert blAccount;
			insert testPack;
			insert blAccount1;
		}
	}

	static testMethod void uniqueBlAccountPositive(){
		init();
		//create a blacklist account object with a unique account, no error should come
		Online_Channel_Account_Blacklist__c blAccountObj = getBlAccount(blAccount.id, testPack.id);
		//create a blacklist account object with no account
		Online_Channel_Account_Blacklist__c blAccountObj1 = getBlAccount(null, testPack.id);
		//create a blacklist account object with some other account
		Online_Channel_Account_Blacklist__c blAccountObj2 = getBlAccount(blAccount1.id, testPack.id);	
		Campaign_Package__c testpack1 = getOCPackage();
		insert testpack1;
		//create a blacklist account object with same account but different package, error should not be thrown
		Online_Channel_Account_Blacklist__c blAccountObj3 = getBlAccount(blAccount1.id, testPack1.id);	

		Test.startTest();
		insert blAccountObj;
		insert blAccountObj2;
		insert blAccountObj1;
		insert blAccountObj3;
		Test.stopTest();
		System.assertNotEquals(blAccountObj.id,null);
		System.assertNotEquals(blAccountObj1.id,null);
		System.assertNotEquals(blAccountObj2.id,null);
		System.assertNotEquals(blAccountObj3.id,null);
	}

	static testMethod void uniqueBlAccountNegative(){
		init();
		//create a blacklist account object with account and package
		Online_Channel_Account_Blacklist__c blAccountObj = getBlAccount(blAccount.id, testPack.id);
		//create another blacklist account object with same account and package, error should be thrown.
		Online_Channel_Account_Blacklist__c blAccountObj1 = getBlAccount(blAccount.id, testPack.id);	
		//create a blacklist account object with some other account 
		Online_Channel_Account_Blacklist__c blAccountObj2 = getBlAccount(blAccount1.id, testPack.id);	
		Test.startTest();
		insert blAccountObj;
        String blAccountObj18DigitId = blAccountObj.id;
        String blAccountObj15DigitId = blAccountObj18DigitId.substring(0,15);
		insert blAccountObj2;
		try{
	        insert blAccountObj1;
		}
		catch(dmlException e){
            //Assert that an exception is thrown with duplication of account
			System.Assert(e.getMessage().contains('DUPLICATE_VALUE,'));
            //Assert that the already existing account id is of blAccountObj
		//	System.Assert(e.getMessage().contains(blAccountObj15DigitId));  Commenting as part of SFDC-2566
		}
        catch(Exception e){
            System.debug('exception is :'+e.getMessage()+' name is : '+e.getTypeName());
		}
		try{
			// update blAccountObj2 with alreday existing blacklisted account -> error should be thrown.
			blAccountObj2.Account__c = blAccount.id;
			update blAccountObj2;
		}
		catch(Exception e){
            //Assert that an exception is thrown with duplication of account
			System.Assert(e.getMessage().contains('DUPLICATE_VALUE,'));
            //Assert that the already existing account id is of blAccountObj
		//	System.Assert(e.getMessage().contains(blAccountObj15DigitId));	Commenting as part of SFDC-2566
		}
		Test.stopTest();
	}	
	
}