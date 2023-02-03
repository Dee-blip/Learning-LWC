/** SpecialistCompTeamTriggerTestClass

@author : Ruchika Sharma <rsharma@akamai.com>
@Description : Test class to test SpecialistCompTeamTriggerClass and SpecialistCompTeamTrigger_bi_bu trigger
   
   
    @History
    --Developer           --Date            --Change
    Ruchika Sharma		23/09/2014  	Created the Test class for CR 2703054 - Product Specialist Crediting 
**/

@isTest(SeeAllData=false)
public class SpecialistCompTeamTriggerTestClass{
	//Commenting below code, as making this test class with seeAllData= true
	//static{
	//	 utilTestClass.insertCustomSettings();
	//}

	//CR 2842869 : rsharma- creating static user with current users id to be put inside system.runAs, so as to avoid mixed-dml exception
    static User dmlUser = new User(id=UserInfo.getUserId());
	static User getSpecialistUser(String userName){
		User ProductSpecialist = utilTestClass.CreateUser(userName, 'Business Operations', 'Sales Operations');
		insert ProductSpecialist;
		ProductSpecialist = [SELECT alias, email,emailencodingkey, lastname,  username,name, profileid, UserRoleId FROM User where id= :ProductSpecialist.id];
		
		return ProductSpecialist;
	}
	
	static testMethod void 	verifyProdSpecialist(){
		User ProductCarrierSpecialist;
		User ProductSecuritySpecialist;
		//CR 2842869 : rsharma- putting system.runAs to avoid mixed-dml exception    
    	System.runAs(dmlUser){
			// create a Specialist Comp team object with type = Carrier Specialist		
			ProductCarrierSpecialist = getSpecialistUser('CSTstUsr');
			
			// create a Specialist Comp team object with type = Security Specialist
			ProductSecuritySpecialist = getSpecialistUser('SSTstUsr');
			
		}
			Specialist_Comp_Team__c SCTCarrierObj = new Specialist_Comp_Team__c(Name = 'TestCarrierSpecialist', Product_Specialist__c = ProductCarrierSpecialist.id, Type__c = 'Carrier Specialist');
			Specialist_Comp_Team__c SCTSecurityObj = new Specialist_Comp_Team__c(Name = 'TestCarrierSpecialist', Product_Specialist__c = ProductSecuritySpecialist.id, Type__c = 'Security Specialist');
		//Specialist_Comp_Team__c SCTDupCarrierObj = new Specialist_Comp_Team__c(Name = 'TestCarrierSpecialistDup', Product_Specialist__c = ProductCarrierSpecialist.id, Type__c = 'Carrier Specialist');
		
		Opportunity oppty = utilTestClass.CreateOpportunity('TestSpecialistOppty','1-Create');
		oppty.CloseDate = Date.today().addMonths(4);
		Test.startTest();
		insert SCTCarrierObj;
		insert SCTSecurityObj;
		//oppty.Carrier_Specialist__c = SCTCarrierObj.id;
		oppty.Security_Specialist__c = SCTSecurityObj.id;
		insert oppty;

		try {
			SCTSecurityObj.Product_Specialist__c = ProductCarrierSpecialist.id;
			upsert SCTSecurityObj;
     	} catch (DmlException e) { 
     		// Verify that the Product Specialist is unique	across Specialist Comp Team Objects
     		System.assertEquals('DUPLICATE_VALUE', e.getDmlStatusCode(0));
     	}

		Test.stopTest();
		SCTCarrierObj = [SELECT Name,Product_Specialist__c, Type__c FROM Specialist_Comp_Team__c WHERE id = :SCTCarrierObj.id];
		// Verify that the name of SpecialistCompTeamObject is '$Prod Specialsit' + 'Comp Team'
		System.assertEquals(SCTCarrierObj.name,ProductCarrierSpecialist.Name);
		
		//verify that the Product specialist is added to sales team of oppty object.
		List<OpportunityTeamMember> opptyTeamMember = [SELECT UserId,OpportunityId FROM OpportunityTeamMember WHERE OpportunityId = :oppty.id];
		System.assertNotEquals(opptyTeamMember,null);
	}
	


}