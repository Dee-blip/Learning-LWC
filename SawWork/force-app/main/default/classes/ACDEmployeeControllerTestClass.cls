@isTest(SeeAllData=true)
public class ACDEmployeeControllerTestClass {
    
    private static User getUser(String username){
        User user = [select id,username, firstname, lastname, email, alias from User where Name = :username][0];
        return User;
    }
    /*
    testmethod static void testClass(){
    	String alias = 'ashegde1';
        String p  = '00eA0000000QkKrIAK';
        User user = new User(alias = alias, email=alias+'@akamai.com',emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= alias + '@akamai.com',profileid = p);
        //insert user;
       // sObject userObj = user;
        List<sObject> userList = new List<sObject>();
        userList.add(user);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(userList);
		ACDEmployeeController acdController = new ACDEmployeeController(stdSetController);   
    }*/
    
    testmethod static void getURLTest(){
      Test.startTest();
      String url = '/apex/ACDEmployees?teamid=aHnJ0000000000GKAQ';
      PageReference pageRef = new PageReference(url);
      Test.setCurrentPage(pageRef);  
      ACDEmployeeController acdEmployeeController = new ACDEmployeeController();
      //System.assertEquals(url, acdEmployeeController.getURL());  
      Test.stopTest();  
    }
    
     testmethod static void refreshTest(){
      Test.startTest();
      String url = '/apex/ACDEmployees?teamid=aHnJ0000000000GKAQ';
      PageReference pageRef = new PageReference(url);
      Test.setCurrentPage(pageRef);  
      ACDEmployeeController acdEmployeeController = new ACDEmployeeController();
         acdEmployeeController.refresh();
      //System.assertEquals(url, acdEmployeeController.getURL());  
      Test.stopTest();  
    }
    testmethod static void getUserSkillsTest(){
       List<TS_ProductMember__c>  ts_skills = new List<TS_ProductMember__c>();

      Test.startTest(); 
      User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1];
      PageReference pageRef = new PageReference('/apex/ACDEmployees');
      Test.setCurrentPage(pageRef);
      ApexPages.currentPage().getParameters().put('userId',u1.Id);

	  TS_Product_Skill__c skill1 = new TS_Product_Skill__c();
	  skill1.Product_Skill_Name__c = 'Skill1 Name';
	  skill1.Description__c = 'Skill1 Description';
	  insert skill1;	  
	  
	  TS_ProductMember__c prodMember = new TS_ProductMember__c();
	  prodMember.TS_Product_Skill__c = skill1.Id;
	  prodMember.ProductMember__c = u1.Id;
	  insert prodMember;
	  
      ts_skills = [SELECT  TS_Product_Skill__r.Id, TS_Product_Skill__r.Product_Skill_Name__c, Skill_Level__c from TS_ProductMember__c where ProductMember__c=:u1.Id]; 
      ACDEmployeeController acdEmployeeController = new ACDEmployeeController();
      acdEmployeeController.getUserSkills();
      System.assertEquals(ts_skills,acdEmployeeController.ts_skills);
      Test.stopTest();
        
    }
    
    testmethod static void getUserSkillsPollTest(){
       List<TS_ProductMember__c>  ts_skills = new List<TS_ProductMember__c>();
       Test.startTest(); 
       User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1];
       TS_Product_Skill__c skill1 = new TS_Product_Skill__c();
	   skill1.Product_Skill_Name__c = 'Skill1 Name';
	   skill1.Description__c = 'Skill1 Description';
	   insert skill1;	  
	  
	   TS_ProductMember__c prodMember = new TS_ProductMember__c();
	   prodMember.TS_Product_Skill__c = skill1.Id;
	   prodMember.ProductMember__c = u1.Id;
	   insert prodMember;
       ts_skills = [SELECT  TS_Product_Skill__r.Id, TS_Product_Skill__r.Product_Skill_Name__c, Skill_Level__c from TS_ProductMember__c where ProductMember__c=:u1.Id]; 
       ACDEmployeeController acdEmployeeController = new ACDEmployeeController();
       acdEmployeeController.userId = u1.Id;
       acdEmployeeController.getUserSkillsPoll();
       System.assertEquals(ts_skills,acdEmployeeController.ts_skills);
       Test.stopTest();
        
    }
}