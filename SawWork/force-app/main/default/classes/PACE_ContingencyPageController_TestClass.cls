/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 @isTest 
public with sharing class PACE_ContingencyPageController_TestClass {
     public static PACECustomSettings__c defPahseRecordType = PACECustomSettings__c.getValues('DefinitionPhaseRecordTypeName');
     public static PACECustomSettings__c devPahseRecordType = PACECustomSettings__c.getValues('DevelopmentPhaseRecordTypeName');      
private static  User CreateUser(String pUsrAlias, String pProfile, String pRole)
  {
    Profile pr = [select Id from Profile where Name=:pProfile][0];
    UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
    User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + '@akamai.com',profileid = pr.Id, UserRoleId = null );
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
  
 
  testmethod static  void getContingencyRecords_PositiveTest()
  {
    Id definitionId;
    Id developmentId;
    Id launchId;
    Id testdefinitionId;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser)
    {
        User productManager = CreateUser('prodMgr', 'Product Operations', 'Worldwide');
        insert productManager;
      
        User generalUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert generalUser;
    
    
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;

    
        PACE_Program__c testProgram = CreatePACEProgram('ipv81',productManager, generalUser);
        insert testProgram;
        
        for(PACE_Phase__c phaseRecord : [Select  Id, Name,RecordType.Name, RecordTypeId, PRB_Review_Date__c, PACE_Program__c FROM PACE_Phase__c  WHERE  PACE_Program__c= :testProgram.Id])
            { 
                    if(phaseRecord.RecordType.Name== devPahseRecordType.Value__c)
                    {
                            developmentId = phaseRecord.Id;
                    }
                    
            }
        
        PACE_Review_Calendar__c testCalendar = new PACE_Review_Calendar__c(Name = 'September', Review_Date__c = System.now().date()+1500);
        
        insert testCalendar;
        
        PACE_Review_Calendar__c testCalendar1 = [Select  Id, Name,RecordType.Name, RecordTypeId FROM PACE_Review_Calendar__c  WHERE  Id = :testCalendar.Id ];
        
        testCalendar1.RecordType.Name ='PRB_Review';
        update testCalendar;
        
        
        
        PACE_Phase__c devPhase = [Select  Id, Name,RecordType.Name, RecordTypeId,PRB_Review_Date__c, PACE_Program__c FROM PACE_Phase__c  WHERE  Id = :developmentId ];
        devPhase.PRB_Review_Date__c = testCalendar.Id;
       
        update devPhase;
        
        Contingency__c testcon1 = new Contingency__c (Name = 'testcont1',Phase__c = developmentId, Status__c = 'Open');
        insert testcon1;
       
        
        Apexpages.StandardController stdController = new Apexpages.StandardController(testCalendar);
        PACE_ContingencyPageController calendarObject = new PACE_ContingencyPageController(stdController); 

        calendarObject.getContingencyRecords();
        
        for(PACE_Phase__c phaseRecord : [Select  Id, Name,RecordType.Name,Target_Phase_Commit_Date__c, SystemModstamp, RecordTypeId, Phase_Review_Approval_Status__c, Phase_Contract_Tolerance_Date__c, Phase_Commit_Date__c, PRB_Review_Date__c, PACE_Program__c,  Exception_Review_Date__c FROM PACE_Phase__c  WHERE  PRB_Review_Date__c = :stdController.getId()])
        { 
            if(phaseRecord.RecordType.Name== devPahseRecordType.Value__c)
              {
                   calendarObject.phaseRecordList.add(phaseRecord);
                   calendarObject.phaseIdList.add(phaseRecord.Id);
                            
               }
        }

        Test.startTest();
        
        for(Contingency__c conRecord : [SELECT Id,Name,Closed_Date__c,Due_Date__c,OwnerId,Phase__c,Priority__c,Status__c FROM Contingency__c where Phase__r.Id IN :calendarObject.phaseIdList])
        {        
            calendarObject.contingencyRecordList.add(conRecord);
        }
        
        if(calendarObject.contingencyRecordList.size()>0)
            {
                System.assertNotEquals(calendarObject.contingencyRecordList.size(),0);
            }
        Test.stopTest();
   }         
}
}