@isTest
public with sharing class PACE_UserSpecificHomepageBaseTestClass {
  
  
  private static  User CreateUser(String pUsrAlias, String pProfile, String pRole)
  {
    Profile pr = [select Id from Profile where Name=:pProfile][0];
    UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
    User newUser = new User(alias = pUsrAlias+'test', email=pUsrAlias+'tet@akamai.com',emailencodingkey='UTF-8', lastname='NewOwnertet', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + 'test@akamai.com',profileid = pr.Id, UserRoleId = null,AKAM_User_ID__c='test1'+pUsrAlias );
    return newUser;     
  }
  
  private  static PACE_Program__c CreatePACEProgram(String name,User productManager1, User generalUser1){
    
    PACE_Program__c program = new PACE_Program__c();
    program.Division__c = 'Media';
    program.Product_Manager__c = productManager1.Id;
    program.Program_Manager__c = productManager1.Id;
    program.Program_Type__c = 'New Product';
    program.Version__c = '1.0';
    
    return program;
    
    
  }
  
  testmethod static  void getObjectList_PositiveTest(){
    
    List<User> usersList = new List<User>();
    User productManager = CreateUser('xyz', 'Product Operations', 'Worldwide');
    usersList.add(productManager);
    

    User generalUser = CreateUser('TST', 'Sales Operations', 'Sales Operations');
    usersList.add(generalUser);
    User sysadmin = CreateUser('sya', 'System Administrator', 'Worldwide');
    usersList.add(sysadmin);
    
    insert usersList;

    System.runas(sysadmin){
      utilTestClass.insertCustomSettings();
    }

    

    System.runas(productManager){
    
    Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line123');
    insert plc;
    
    PACE_Program__c testProgram = CreatePACEProgram('ipv81',productManager, generalUser);
    insert testProgram;
    
    PACE_UserSpecificHomepageBaseClass baseObject = new PACE_UserSpecificHomepageBaseClass(); 
    
    // Test.startTest();
    List<sOBject> objList = new List<PACE_Program__c>();
    objList = baseObject.getObjectList('PACE_Program__c','','');
    List<PACE_Program__c> programList = (List<PACE_Program__c>)objList;
    System.assertEquals(1,programList.size());
    // Test.stopTest();
    }
    
  }
  
}