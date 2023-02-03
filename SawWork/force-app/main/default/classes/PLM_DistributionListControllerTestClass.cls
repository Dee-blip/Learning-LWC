/**
	Test class for PLM_DistributionListController
	@author  - sveerapp@akamai.com
*/	
		
	
public class PLM_DistributionListControllerTestClass {
	
	//Set up util method - Used to create a user
	private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
	{
    	Profile pr = [select Id from Profile where Name=:pProfile][0];
		UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
		User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + '@akamai.com',profileid = pr.Id, UserRoleId = null );
		return newUser;		
	}
		
	//Set up util method - Used to set up distribution list	
	private static List<Product_Launch_RASCI_List__c> addUsersToDistributionList_Setup(List<String> selectedUsersList, List<String> selectedProductLines) {
        
        List<Product_Launch_RASCI_List__c> plmNotificationList = new List<Product_Launch_RASCI_List__c>();
        
        Product_Launch_RASCI_List__c temp  = null;
        
        for(String productLineId: selectedProductLines){
            for(String userId : selectedUsersList){
                
                temp = new Product_Launch_RASCI_List__c();
                temp.User__c = userId;
                temp.Product_Line__c = productLineId;
                plmNotificationList.add(temp);
            }
            
        }

        insert plmNotificationList;
        return plmNotificationList;
        
    }
	
	
	
	testmethod static void addUsersToDistributionList_PositiveTest(){
		
		PLM_DistributionListController controller = new PLM_DistributionListController();
		String[] temp = new List<String>();
		
		Product_Line__c plc = new Product_Line__c();
		plc.name = 'Product Line 1';
		insert plc;
		
		User testUser = CreateUser('TST_1U1', 'Sales Operations', 'Sales Operations');
		insert testUser;
		
		temp.add(plc.Id);
		controller.setSelectedProductLines(temp);
		
		temp = new List<String>();
		temp.add(testUser.Id);
		
		controller.setSelectedUsersList(temp);
		
		Test.startTest();
		controller.addUsersToDistributionList();
		
		List<Product_Launch_RASCI_List__c>  plrList = [select User__c from Product_Launch_RASCI_List__c where Product_Line__c = :plc.Id];
		Product_Launch_RASCI_List__c plr = plrList.get(0);
		System.assertEquals(plr.User__c, testUser.Id);
		
		Test.stopTest();
		
	}
	
	testmethod static void removeUsers_PositiveTest(){
		
		PLM_DistributionListController controller = new PLM_DistributionListController();
		String[] tempUser = new List<String>();
		String[] tempProdLine = new List<String>();
		
		Product_Line__c plc = new Product_Line__c();
		plc.name = 'Product Line 1';
		insert plc;
		
		User testUser = CreateUser('TST_2U2', 'Sales Operations', 'Sales Operations');
		insert testUser;
		
		tempProdLine.add(plc.Id);
		tempUser.add(testUser.Id);
		
		List<Product_Launch_RASCI_List__c> plrl  = addUsersToDistributionList_Setup(tempUser, tempProdLine);
		
		PLM_Product_Launch_RASCI_Wrapper rw = new PLM_Product_Launch_RASCI_Wrapper();
		rw.rascidistributionRecord = plrl.get(0);
		rw.isSelected = true;
		
		List<PLM_Product_Launch_RASCI_Wrapper> wrpList = new List<PLM_Product_Launch_RASCI_Wrapper>();
		wrpList.add(rw);
		
		controller.setRasciWrapperList(wrpList);
		
		Test.startTest();
		controller.removeUsers();
		
		List<Product_Launch_RASCI_List__c>  plrList = [select User__c from Product_Launch_RASCI_List__c where Product_Line__c = :plc.Id and User__c = :testUser.Id];
		System.assert(plrList.size() <= 0);
		
		
		Test.stopTest();
		
			
	}
	
	
	testmethod static void getUserList_PositiveTest(){
		
		PLM_DistributionListController controller = new PLM_DistributionListController();
		List<SelectOption> userList = controller.getUserList();
		
		System.assert(userList!=null);
		
	}
	
	
	testmethod static void getProductLines_PositiveTest(){
		
		PLM_DistributionListController controller = new PLM_DistributionListController();
		List<SelectOption> productLineList = controller.getProductLines();
		
		System.assert(productLineList!=null);
		
	}
	
	
	
	testmethod static void getDistributionList_PositiveTest(){
		
		PLM_DistributionListController controller = new PLM_DistributionListController();
		List<PLM_Product_Launch_RASCI_Wrapper> distributionList = controller.getDistributionList();
		
	}
	
	// Dummy test required to get 90% coverage. Hence, combined three getter test into one method
	testmethod static void getterMethods_PositiveTest(){
		
		    String[] selectedProductLines = new String[]{};
			String[] selectedUsersList = new String[]{};
			List<PLM_Product_Launch_RASCI_Wrapper> rasciWrapperList;    

		
		
		PLM_DistributionListController controller = new PLM_DistributionListController();
		
		
		controller.setSelectedProductLines(selectedProductLines);
		System.assertEquals(controller.getSelectedProductLines(),selectedProductLines) ;
		
		controller.setSelectedUsersList(selectedUsersList);
		System.assertEquals(controller.getSelectedUsersList(),selectedUsersList) ;		
		
		controller.setRasciWrapperList(rasciWrapperList);		
		System.assertEquals(controller.getRasciWrapperList(),rasciWrapperList) ;
		
		
	}	
	

}