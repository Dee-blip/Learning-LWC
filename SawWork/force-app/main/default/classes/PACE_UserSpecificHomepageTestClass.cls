@isTest
public with sharing class PACE_UserSpecificHomepageTestClass {
  
  
  
  private static  User CreateUser(String pUsrAlias, String pProfile, String pRole)
  {
    Profile pr = [select Id from Profile where Name=:pProfile][0];
    UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
    User newUser = new User(alias = pUsrAlias+'test', email=pUsrAlias+'tet@akamai.com',emailencodingkey='UTF-8', lastname='NewOwnertet', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + 'test@akamai.com',profileid = pr.Id, UserRoleId = null,AKAM_User_ID__c='test1'+pUsrAlias );
    return newUser;     
  }

    private  static PACE_Program__c CreatePACEProgram(String name,User productManager1, User generalUser1,Product_Line__c plc){
      PACE_Program__c program = new PACE_Program__c();
      program.Name = name;
      program.Division__c = 'Media';
      program.Product_Manager__c = productManager1.Id;
      program.Program_Manager__c = productManager1.Id;
      program.Program_Type__c = 'New Product';
      program.Original_CC__c = Date.today();
      program.Planned_CC__c = Date.today();
      program.Version__c = '1.0';
      program.Division__c = 'Media';
      program.Product_Line__c = plc.Id ;
      return program;
    }
    
    
    testmethod static  void getData_PositiveTest()
    {
      Id definitionId;
      Id developmentId;
      Id launchId;
      
      Id definitionPhaseRecordTypeId =  Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();
      Id launchPhaseRecordTypeId =      Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Launch').getRecordTypeId();
      Id developmentPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Development').getRecordTypeId();
      
      
      
      User productManager = CreateUser('pr', 'Product Operations', 'Worldwide');
      insert productManager;
      
      User generalUser = CreateUser('TS_', 'Sales Operations', 'Sales Operations');
      insert generalUser;
      
      User testUser = CreateUser('TST', 'Sales Operations', 'Sales Operations');
      insert testUser;

      User sysadmin = CreateUser('sya', 'System Administrator', 'Worldwide');
      insert sysadmin;

      System.runas(sysadmin){
        utilTestClass.insertCustomSettings();
      }

      System.RunAs(testUser){
        
        //Test.startTest();
        
        Product_Line__c plc = new Product_Line__c();
        plc.Name = 'Application Acceleration';
        insert plc;
        
        PACE_Program__c testProgram = CreatePACEProgram('ipv81',productManager, generalUser,plc);
        insert testProgram;
        
        PACE_Program__c testProgram2 = CreatePACEProgram('ipv82',productManager, generalUser,plc);
        insert testProgram2;
        PLU__c pluRec = new PLU__c(PLU_Date__c = Date.TODAY() + 2, Name = 'Test-2020');
        insert pluRec ;
        // Launch_Item__c li = new Launch_Item__c();
        // li.Product_Manager__c = testUser.Id;
        // li.Name = 'test_launch_item';       
        // li.Product_Line_pickList__c = plc.Id;
        // li.Division__c='Media';
        // li.Program__c=testProgram.Id;
        // li.PLU__c = pluRec.Id;
        // insert li;
        for(PACE_Phase__c phaseRecord : [Select  Id, Name,RecordTypeId,RecordType.Name,PRB_Review_Date__c, PACE_Program__c, Exception_Review_Date__c,SIR_Meeting_Date__c FROM PACE_Phase__c  WHERE  PACE_Program__c= :testProgram.Id])
        { 
          if(phaseRecord.RecordTypeId == definitionPhaseRecordTypeId)
          {
            
            definitionId = phaseRecord.Id;
          }
          else if(phaseRecord.RecordTypeId== developmentPhaseRecordTypeId)
          {
            
            developmentId = phaseRecord.Id;
          }
          else if(phaseRecord.RecordTypeId== launchPhaseRecordTypeId)
          {
            
            launchId = phaseRecord.Id;
          }
        }
        RecordType rtId = [select Id,name from RecordType where name='PRB Review'] ;
        PACE_Review_Calendar__c  calRecord = new PACE_Review_Calendar__c(Name = 'TestPRBCal',Review_Date__c = Date.TODAY() + 3000, RecordType = rtId);
        insert calRecord;
        
        Contingency__c conRecord2 = new Contingency__c(Name ='TEst Con2', Status__c ='Open',Phase__c =definitionId);
        insert conRecord2;
        
        PACE_UserSpecificHomepageController programObject = new PACE_UserSpecificHomepageController();
        PACE_UserSpecificHomepageBaseClass baseClassObject = new PACE_UserSpecificHomepageBaseClass();
        List<sOBject> objList = new List<PACE_Program__c>();
        objList = baseClassObject.getObjectList('PACE_Program__c','','');
        List<PACE_Program__c> programList = (List<PACE_Program__c>)objList;
        
        
        programObject.division = 'Media';
        programObject.productline = plc.Id;
        programObject.callqueries();
        
        system.assertEquals(programObject.programMProgramList.size(),2);
        
        programObject.division_con = 'Media';
        programObject.productline_con = plc.Id;
        programObject.callqueries();
        
      
        
        programObject.activation = pluRec.Id;
        //system.assertEquals(programObject.activeLaunchItemList.size() >= 1,True);
        
        programObject.reviewmonth = calRecord.Review_Month__c;
        system.assertEquals(programObject.progrmMreviewCalendarList.size()>=1,True);
        programObject.setProductline('all');
        system.assertEquals(programObject.getProductline(),'all');
        programObject.setProductline_con('all');
        system.assertEquals(programObject.getProductline_con(),'all');
        
        programObject.setDivision('all');
        system.assertEquals(programObject.getDivision(),'all');
        programObject.setDivision_con('all');
        system.assertEquals(programObject.getDivision_con(),'all');
        
        programObject.setActivation('all');
        system.assertEquals(programObject.getActivation(),'all');
        
        programObject.setReviewmonth('all');
        system.assertEquals(programObject.getReviewmonth(),'all');
        
        programObject.setActiveli('all');
        system.assertEquals(programObject.getActiveli(),'all');
        
        List<SelectOption> monthList= programObject.getMonthitems();
        system.assertEquals(monthList.size(),13);
        
        List<SelectOption> mymonthList= programObject.getMymonthitems();
        system.assertEquals(mymonthList.size(),14);
        
        List<SelectOption> divList= programObject.getItems();
        system.assertEquals(divList.size(),6);
        
        
        programObject.activeli='none';
        programObject.getApprovalTesks();
        system.assertEquals(programObject.launchItemApproval.size(),0);
        
        programObject.productlines.clear();
        programObject.productlines.add(plc);
        List<SelectOption> pli=programObject.getPlitems();
        System.assertEquals(pli.size(),2);
        
        programObject.activationlist.clear();
        programObject.activationlist.add(pluRec);
        
        List<SelectOption> plu1=programObject.getActitems();
        System.assertEquals(plu1.size(),2);
        
        programObject.activeLaunchItemList.clear();
        //programObject.activeLaunchItemList.add(li);
        List<SelectOption> lilist=programObject.getActiveitems();
        //System.assertEquals(lilist.size(),2);
        
        programObject.activemyLaunchItemList.clear();
        //programObject.activemyLaunchItemList.add(li);
        List<SelectOption> lilist2=programObject.getActivemyitems();
        //System.assertEquals(lilist2.size(),2);
        programObject.userId=productManager.Id;
        System.runAs(productManager)
        {
          programObject.callqueries();
          System.assertEquals(programObject.programManProgramList.size(),2);
          
        }
        
      }
    }
  }