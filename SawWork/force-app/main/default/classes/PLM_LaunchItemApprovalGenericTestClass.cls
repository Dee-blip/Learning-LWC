/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 *  no data to the database, and are flagged with the testMethod
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
private class PLM_LaunchItemApprovalGenericTestClass {

    public static Features_Toggle__c launchItemApprovalFeature=Features_Toggle__c.getInstance('LaunchItemApproval');
    public static Profile userProfile=[select Id, Name from Profile where Name =:'Product Management'][0];
    public static UserRole userRole =[select Id,Name from UserRole where Name =: 'Worldwide'][0];
    public static Profile prodOpsProfile=[select Id from Profile where Name =: 'Product Operations'][0];
    public static User prodOpsUser=[select Id from User where ProfileId =:prodOpsProfile.Id and isActive =:true][0];
    public static Product_Line__c plc;
    public static PLU__c plu;
    public static Launch_Item__c li;
    public static User testUser; 
    
    public static List<Launch_Item_Approval__c>  createGlobalTeam()
    {
       
       List<Launch_Item__c> deleteExistingLaunchItems=[select id from Launch_item__c where Archive__c =false];
      
      if(deleteExistingLaunchItems !=null && deleteExistingLaunchItems.size()>0)
      {
        delete deleteExistingLaunchItems;
      }
      testUser=createUser('Test11','User','Engineering','TestBusiness Unit'
                                    ,3243,322,'testUser1@akamai.com','Test Deptt.','Test Division'
                                    ,'t1User', 'UTF-8','en_US'
                                    ,'en_US','America/Los_Angeles','test1User@akamai.com',userProfile.Id,userRole.Id);
        
        insert testUser;    
       List<Launch_Item_Approval__c> memberList=new List<Launch_Item_Approval__c>();
       List<Launch_Item_Approval__c> standingDelmemberList=new List<Launch_Item_Approval__c>();
       List<Schema.PicklistEntry> divisionPickList=Schema.Launch_Item_Approval__c.Division__c.getDescribe().getPicklistValues();
       List<Schema.PicklistEntry> functionPickList=Schema.Launch_Item_Approval__c.Function__c.getDescribe().getPicklistValues();
       
       
       
       for(Schema.PicklistEntry p: divisionPickList)
         {
          Launch_Item_Approval__c litm=new Launch_Item_Approval__c(Division__c=p.getValue());
          memberList.add(litm);
         }
       for(Schema.PicklistEntry p: functionPickList)
         {
          Launch_Item_Approval__c litm=new Launch_Item_Approval__c(function__c=p.getValue());
         memberList.add(litm);
          for(Schema.PicklistEntry q: divisionPickList)
          {
            Launch_Item_Approval__c lia = new Launch_Item_Approval__c(Function__c = p.getValue(),Division__c = q.getValue());
            standingDelmemberList.add(lia);
            //memberList.add(lia);
          } 
         }
       List<User> userList =new List<User>();
       List<User> userListglobal =new List<User>();
       List<User> userListdelegation =new List<User>();
       for(Integer i=0;i<standingDelmemberList.size();i++)
        {
            User newUser=createUser('Test1','User1'+i,'Engineering','TestBusiness Unit'
                                    ,3243,322,'testUser11'+ i +'@akamai.com','Test Deptt.','Test Division'
                                    ,'tUser'+ i, 'UTF-8','en_US'
                                    ,'en_US','America/Los_Angeles','testUser11'+ i +'@akamai.com',userProfile.Id,userRole.Id);
            userListdelegation.add(newUser);
            userList.add(newUser);
        }
        
       for(Integer i=0;i<memberList.size();i++)
        {
            User newUser=createUser('Test','User'+i,'Engineering','TestBusiness Unit'
                                    ,3243,322,'testUser'+ i +'@akamai.com','Test Deptt.','Test Division'
                                    ,'tUser'+ i, 'UTF-8','en_US'
                                    ,'en_US','America/Los_Angeles','testUser'+ i +'@akamai.com',userProfile.Id,userRole.Id);
            userListglobal.add(newUser);
            userList.add(newUser);
        }
        
        insert userList;
        for(Integer i=0;i<memberList.size();i++)
        {
            memberList[i].Approver__c=userListglobal[i].Id;
        }
        for(Integer i=0;i<standingDelmemberList.size();i++)
        {
            standingDelmemberList[i].Delegate_Approver__c=userListdelegation[i].Id;
            standingDelmemberList[i].StandingDelegationCheck__c = true;
        }
        
        List<Launch_Item_Approval__c> deleteExistingLaunchItemApproval=[select Id from Launch_Item_Approval__c where Global_Setting_Id__c =null     and Launch_Item__c =null];
        if(deleteExistingLaunchItemApproval!=null && deleteExistingLaunchItemApproval.size()>0)
        {
            delete deleteExistingLaunchItemApproval;
        }
        
        
        
        for(Launch_Item_Approval__c lia : standingDelmemberList)
        memberList.add(lia);
        insert memberList;
        //insert standingDelmemberList;
       return memberList;
    }
    
   /* private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager1, User generalUser1,Product_Line__c plc1)
  {

    //PACE_Concept__c 
    PACE_Concept__c concept = new PACE_Concept__c();

    concept.Comments__c = 'Some comment which no-body reads, but knew you would!';
    concept.Concept_Commit_Date__c = Date.today();

    concept.Concept_Type__c = conceptType;
    concept.Division__c = 'Media';
    concept.Executive_Sponsor__c = generalUser1.Id;
    concept.Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    concept.Product_Line__c = plc1.Id;
    concept.Product_Manager__c = generalUser1.Id;
    concept.Program_Manager__c = generalUser1.Id;
    concept.Name = name;

    return concept;

  }*/
    private static  User CreateUser(String pUsrAlias, String pProfile, String pRole)
  {
    Profile pr = [select Id from Profile where Name=:pProfile][0];
    UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
    User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + '@akamai.com',profileid = pr.Id, UserRoleId = null );
    return newUser;     
  }

  

  private  static PACE_Program__c CreatePACEProgram(String name,User productManager1, User generalUser1){

    PACE_Program__c program = new PACE_Program__c();
      program.Name = name;
    //program.Additional_Detail__c = 
  //  program.Concept__c = concept1.Id;
    //program.Concept_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Concept_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Definition_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Definition_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Definition_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Definition_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
 //   program.Definition_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
 //   program.Definition_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
//    //program.Definition_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
 //   program.Development_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Development_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Dev_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Development_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   // program.Development_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   // program.Development_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Development_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Division__c = 'Media';
  //  program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Launch_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Launch_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Launch_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Launch_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Launch_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Product_Manager__c = productManager1.Id;
    program.Program_Manager__c = productManager1.Id;
    program.Program_Type__c = 'New Product';
   // program.Target_Definition_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   // program.Target_Development_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   // program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Version__c = '1.0';

    return program;


  }
    private static void init()
    {
        plc = new Product_Line__c();
        plc.Name = 'Application Acceleration';
        insert plc;
        
        plu = new PLU__c();
        
        plu.Name = 'Apr-2012';
        plu.PLU_Date__c = Date.today().addDays(1);
        insert plu;
        
        User productManager = CreateUser('prodMgr', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
      //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
       // insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        li = new Launch_Item__c();
        li.Product_Manager__c = testUser.Id;
        li.Name = 'test_launch_item';
        li.Product_Line_pickList__c=plc.Id;
        li.Division__c='Media';
        li.PLU__c=plu.Id;  
        li.Version_Number__c='1.0';
        li.Product_Phase__c='Beta';
        li.Program__c=ppc.Id;     
        insert li;
    }
    public static Boolean checkAndEnableLaunchItemApprovalFeature(Boolean toggle)
    {
        Boolean isFeatureToggled=false;
        if(!toggle)
        {
            if(launchItemApprovalFeature.Toggle__c)
            {
                launchItemApprovalFeature.Toggle__c=false;
                update launchItemApprovalFeature;
                isFeatureToggled=true;
            }
        }
        else if(toggle)
        {
           launchItemApprovalFeature.Toggle__c=true;
           update launchItemApprovalFeature;
        }
        return isFeatureToggled;
    }
    public static User createUser(String firstName,String lastName,String title, String businessUnitName
                                  ,Double businessUnitNo,Double costCenter,String email,String dept,String division
                                  ,String alias, String emailEncodingKey, String languageLocalekey
                                  ,String localSidKey,String timeZoneSidKey, String userName,String profileId, String roleId)
    {
      User newtestUser=new User();
      newtestUser.FirstName=firstName;
      newtestUser.LastName=lastName;
      newtestUser.Title=title;
      newtestUser.Business_Unit_Name__c=businessUnitName;
      newtestUser.Business_Unit_Number__c=businessUnitNo;
      newtestUser.Email=email;
      newtestUser.Cost_Center__c=costCenter;
      newtestUser.Department=dept;
      newtestUser.Division=division;
      newtestUser.Alias=alias;
      newtestUser.emailencodingkey=emailEncodingKey;
      newtestUser.languagelocalekey=languageLocalekey;
      newtestUser.localesidkey=localSidKey;
      newtestUser.timezonesidkey=timeZoneSidKey; 
      newtestUser.username=userName;
      newtestUser.ProfileId=profileId;
      newtestUser.UserRoleId=roleId;
      return newtestUser;
    }
    

    static testMethod void CreateGlobalApprovalTeam_PositiveTest() 
    {
       Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        List<Launch_Item_Approval__c> deleteExistingLaunchItemApproval=[select Id from Launch_Item_Approval__c where Launch_Item__C =:'' and Global_Setting_Id__C =:''];
        if(deleteExistingLaunchItemApproval!=null && deleteExistingLaunchItemApproval.size()>0)
        {
            delete deleteExistingLaunchItemApproval;
        }
        testUser=createUser('Test1','User','Engineering','TestBusiness Unit'
                                    ,3243,322,'testUser@akamai.com','Test Deptt.','Test Division'
                                    ,'t1User', 'UTF-8','en_US'
                                    ,'en_US','America/Los_Angeles','test1User@akamai.com',userProfile.Id,userRole.Id);
        
        insert testUser;
        System.runAs(prodOpsUser)
        {
        String url='/apex/PLM_SetFunctionalDivisionalApprovers?retURL=';
        String retURL='/apex/PLM_PLUHomepage';
        PageReference pageRef= new PageReference(url+EncodingUtil.urlEncode(retURL,'UTF-8'));
        test.setCurrentPageReference(pageRef);
        PLM_LaunchItemApprovalGeneric launchItemApprovalGeneric=new PLM_LaunchItemApprovalGeneric();
        //assert default poupulation of Global Approval team
        System.assert(launchItemApprovalGeneric.dataClass.getLaunchTeamDivisionalMemberList().size()>0);
        System.assert(launchItemApprovalGeneric.dataClass.getLaunchTeamFunctionalMemberList().size()>0);
        //assert pageName
        System.assertEquals(launchItemApprovalGeneric.dataClass.getPageName(),'PLM_SetFunctionalDivisionalApprovers');
        launchItemApprovalGeneric.edit();
        List<PLM_LaunchItemApprovalWrapperClass> memberList=launchItemApprovalGeneric.dataClass.getLaunchTeamFunctionalDivisionalList();
        List<User> userList= new List<User>();
        
        for(Integer i=0;i<memberList.size();i++)
        {
            User newUser=createUser('Test','User'+i,'Engineering','TestBusiness Unit'
                                    ,3243,322,'testUser'+ i +'@akamai.com','Test Deptt.','Test Division'
                                    ,'tUser'+ i, 'UTF-8','en_US'
                                    ,'en_US','America/Los_Angeles','testUser'+ i +'@akamai.com',userProfile.Id,userRole.Id);
            userList.add(newUser);
        }
        insert userList;
        for(Integer i=0;i<memberList.size();i++)
        {           
            memberList[i].teamMember.Approver__c=userList[i].Id;            
        }
        Test.startTest();
        launchItemApprovalGeneric.save();
        init();     
        test.stopTest();
        //refresh Global Team
        String strtest = PLM_Custom_Settings__c.getValues('LaunchApprvl#Division').value__c;
        List<String> divisionListtest = strtest.split(':', 0) ;
        Integer countTest = divisionListtest.size() + 8;
        List<Launch_Item_Approval__c> liaList=[select Id from Launch_Item_Approval__c where Launch_Item__c = null and Global_setting_Id__c = null and   StandingDelegationCheck__c = false ];
        //System.assertEquals(liaList.size(),countTest);
        //refresh launch Item Approval team
        liaList=[select Id from Launch_Item_Approval__c where Launch_Item__c =: li.Id and StandingDelegationCheck__c = false];
       //System.assertEquals(liaList.size(),9);
        }
      }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      } 
    }
   static testMethod void updateGlobalApprovalTeam_Positive()
    {
        Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        List<Launch_Item_Approval__c> createdGlobalTeam=createGlobalTeam();
        init();
        String url='/apex/PLM_SetFunctionalDivisionalApprovers?retURL=';
        String retURL='/apex/PLM_PLUHomepage';
        PageReference pageRef= new PageReference(url+EncodingUtil.urlEncode(retURL,'UTF-8'));
        
        test.setCurrentPageReference(pageRef);
        PLM_LaunchItemApprovalGeneric launchItemApprovalGeneric=new PLM_LaunchItemApprovalGeneric();
        
        //assert exsting global team
        List<PLM_LaunchItemApprovalWrapperClass> exsitingGlobalteam=launchItemApprovalGeneric.dataClass.getLaunchTeamFunctionalDivisionalList();
        
        for(PLM_LaunchItemApprovalWrapperClass litmClass: exsitingGlobalteam)
        {
            System.assert(litmClass.isExisting);
        }
        
        for(PLM_LaunchItemApprovalWrapperClass litmClassD: launchItemApprovalGeneric.dataClass.getLaunchTeamDivisionalMemberList())
        {
            if(litmClassD.teamMember.Division__c != null && litmClassD.teamMember.Division__c=='Media')
            {
                litmClassD.teamMember.Approver__c=testUser.Id;
            }
        }
        launchItemApprovalGeneric.dataClass.setIsApplyToExisting(true);
        system.debug(' is Apply to Existing'+ launchItemApprovalGeneric.dataClass.getIsApplyToExisting());
        launchItemApprovalGeneric.save();
        // refresh launch item approval team
        
        Launch_Item_Approval__c lia=[select Id, Approver__c from Launch_item_Approval__c where launch_Item__c =: li.Id and division__c !=null and StandingDelegationCheck__c = false][0];
        
        System.assertEquals(lia.Approver__c,testUser.Id);
      }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      }  
     
    } 
    
    static testMethod void sendNotificationToFunctionRepresentatives_Positive()
    {
      Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        createGlobalTeam();
        init();
        String url='/apex/PLM_PLUViewPage';
        PageReference pageRef=new PageReference(url);
        pageRef.getParameters().put('id',plu.Id);
      System.runAs(prodOpsUser)
      {
        Test.startTest();
        Test.setCurrentPageReference(pageRef);
        PLM_PLUViewController pluViewController=new PLM_PLUViewController();
        pluViewController.createFunctionalApprovals();
        System.assert(pluViewController.isNotificationsSent);
        List<Launch_Item_Approval__c> launchItemLaunchTeam=[select Id, Name from Launch_Item_Approval__c where Launch_Item__c =:li.Id and isVisible__c =:true and StandingDelegationCheck__c = false];
        System.assert(pluViewController.isNotificationsSent);
        System.assertEquals(launchItemLaunchTeam.size(),8);
        Test.stopTest();
       }
     }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      } 
    }
   
    static testMethod void sendNotificationToDivisionApprover_Positive()
    {
      Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        createGlobalTeam();
        init();
      System.runAs(prodOpsUser)
      {
        Test.startTest();
        List<Launch_Item_Approval__c> launchItemLaunchTeam=[select Id, Name from Launch_Item_Approval__c where Launch_Item__c =:li.Id and isVisible__c =:true and Division__c != null and StandingDelegationCheck__c = false];
       if(launchItemLaunchTeam==null)
       {
        launchItemLaunchTeam=new List<Launch_Item_Approval__c>();
       }
      System.assertEquals(launchItemLaunchTeam.size(),0);
      String result=PLM_LaunchItemApprovalGeneric.makeVisibleAndNotifyDivisionApprover(li.Id,'');
      system.assertEquals(PLM_Custom_Settings__c.getInstance('LaunchItem#NotifyGMConfirmMsg').value__c,result);
      launchItemLaunchTeam=[select Id, Name from Launch_Item_Approval__c where Launch_Item__c =:li.Id and isVisible__c =:true and Division__c != null and StandingDelegationCheck__c = false];
      System.assertEquals(launchItemLaunchTeam.size(),1);
      Test.stopTest();
      }
     }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      } 
    }
    
    static testMethod void launchItemApprovalPageSummaryTest()
    {
      Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
       createGlobalTeam();
       init();
      System.runAs(prodOpsUser)
     {
        Test.startTest();
                
        String urlNew='/apex/PLM_LIARelatedList';
        PageReference pageRefNew=new PageReference(urlNew);
        pageRefNew.getParameters().put('id',li.Id);
        Test.setCurrentPageReference(pageRefNew);
        PLM_LaunchItemApprovalGeneric rlController=new PLM_LaunchItemApprovalGeneric();
        System.assertEquals(rlController.dataClass.getLaunchTeamFunctionalMemberList().size(),0);
        System.assertEquals(rlController.dataClass.getLaunchTeamDivisionalMemberList().size(),0);

        urlNew='/apex/PLM_PLUViewPage';
        pageRefNew=new PageReference(urlNew);
        pageRefNew.getParameters().put('id',plu.Id);
        Test.setCurrentPageReference(pageRefNew);
        PLM_PLUViewController pluViewController=new PLM_PLUViewController();
        pluViewController.createFunctionalApprovals();
        
        urlNew='/apex/PLM_LIARelatedList';
        pageRefNew=new PageReference(urlNew);
        pageRefNew.getParameters().put('id',li.Id);
        Test.setCurrentPageReference(pageRefNew);
        rlController=new PLM_LaunchItemApprovalGeneric();
        
        rlController.getRecordTypeIdPLU('ArchivedPLU'); //added by nagdeep
        rlController.getRecordTypeId('Launch_Item_Archived'); // added by nagdeep
     
        List<Launch_Item__c> lis= new List<Launch_Item__c>();
        lis.add(li); 
        rlController.updateExistingDivisionalApprovals(lis); // added by nagdeep
        System.assertEquals(rlController.dataClass.getLaunchTeamFunctionalMemberList().size(),8);
        System.assertEquals(rlController.dataClass.getLaunchTeamDivisionalMemberList().size(),0);
        Test.stopTest();
     }
     }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      }
    }
   
    static testMethod void SentNotificationRemindersEmailTest()
    {
      Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        createGlobalTeam();
        init();
        PLU__c plu1 = new PLU__c();
        plu1.Name = 'Jan-2011';
        plu1.PLU_Date__c = Date.today().addDays(3);
        insert plu1;
        User productManager = CreateUser('prod32', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TST_U5', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
     //   PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
     //   insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        PLM_LaunchItemClass.firstRun=true;
        PLM_LaunchItemApprovalGeneric.launchItemInsertFirstRunFlag=true;
        Launch_Item__c li1 = new Launch_Item__c();
        li1.Product_Manager__c = testUser.Id;
        li1.Name = 'test_launch_item';
        li1.Product_Line_pickList__c=plc.Id;
        li1.Division__c='Media';
        li1.PLU__c=plu1.Id;
        li1.Version_Number__c='1.0';
        li1.Product_Phase__c='Beta';  
        li1.Program__c=ppc.Id;      
        insert li1;
        
        
        PLU__c plu2= new PLU__c();
        plu2.Name = 'Jan-2011';
        plu2.PLU_Date__c = Date.today();
        insert plu2;
        
        PLM_LaunchItemClass.firstRun=true;
        PLM_LaunchItemApprovalGeneric.launchItemInsertFirstRunFlag=true;
        Launch_Item__c li2 = new Launch_Item__c();
        li2.Product_Manager__c = testUser.Id;
        li2.Name = 'test_launch_item';
        li2.Product_Line_pickList__c=plc.Id;
        li2.Division__c='Media';
        li2.PLU__c=plu2.Id; 
        li2.Program__c=ppc.Id;   
        li2.Version_Number__c='1.0';
        li2.Product_Phase__c='Beta';         
        insert li2;
        
        Test.startTest();
        String urlNew='/apex/PLM_PLUViewPage';
        PageReference pageRefNew=new PageReference(urlNew);
        Test.setCurrentPageReference(pageRefNew);
        pageRefNew.getParameters().put('id',plu.Id);
        PLM_PLUViewController pluController=new PLM_PLUViewController();
        pluController.createFunctionalApprovals();
        urlNew='/apex/PLM_PLUViewPage';
        pageRefNew=new PageReference(urlNew);
        Test.setCurrentPageReference(pageRefNew);
        pageRefNew.getParameters().put('id',plu1.Id);
        pluController=new PLM_PLUViewController();
        pluController.createFunctionalApprovals();
        urlNew='/apex/PLM_PLUViewPage';
        pageRefNew=new PageReference(urlNew);
        Test.setCurrentPageReference(pageRefNew);
        pageRefNew.getParameters().put('id',plu2.Id);
        pluController=new PLM_PLUViewController();
        pluController.createFunctionalApprovals();
        PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
        String res=plmClass.sendNotificationReminders();
        System.assert(res.contains('1:'));
        Test.stopTest();
      }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      }
    }
   
    static testMethod void UpdateDivisionalApprovals_PositiveTest()
    {
        Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        createGlobalTeam();
        init();
        System.runAs(prodOpsUser)
        {
        
        PLM_LaunchItemClass.firstRun = true;
        li.Division__c='Media';
        update li;
        
        Launch_Item_Approval__c lia=[select Id , Division__c, Approver__c from Launch_Item_Approval__c where Launch_Item__c =:li.Id and Division__c != null and StandingDelegationCheck__c = false][0]; 
        system.assertEquals('Media', lia.Division__c);
        }
      }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      }
    }
    
    static testMethod void launchItemApprovalPageTest()
    {
      Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
      {
        createGlobalTeam();
        init();
        Test.startTest();
        System.runAs(prodOpsUser)
        {               
         String urlNew='/apex/PLM_PLUViewPage';
         PageReference pageRefNew=new PageReference(urlNew);
         pageRefNew.getParameters().put('id',plu.Id);
         Test.setCurrentPageReference(pageRefNew);
         PLM_PLUViewController pluViewController=new PLM_PLUViewController();
         pluViewController.createFunctionalApprovals();
         }
        List<Launch_Item_Approval__c> liaList=[select Id,isCurrentUserApprover__c,Approver__c,Delegate_Approver__c from Launch_Item_Approval__c where Launch_Item__c =:li.Id and isVisible__c=:true and StandingDelegationCheck__c = false];
        
        User approverUser=[select Id from User where Id =:liaList[0].Approver__c][0];
        
        System.runAs(approverUser)
        {
          String urlNew='/apex/PLM_LIApprovalPage';
          PageReference pageRefNew=new PageReference(urlNew);
          pageRefNew.getParameters().put('id',liaList[0].Id);
          //pageRefNew.getParameters().put('launchItemId',li.Id);
          Test.setCurrentPageReference(pageRefNew);
          PLM_LaunchItemApprovalGeneric approvalController=new PLM_LaunchItemApprovalGeneric();
          approvalController.dataClass.setDelgateApprover('Test');
          approvalController.searchUser();
          if(approvalController.dataClass.getUserList() !=null && approvalController.dataClass.getUserList().size()>0)
          {
            pageRefNew.getParameters().put('userId',(approvalController.dataClass.getUserList())[0].Id);
            approvalController.selectUser();
            approvalController.reassign();
            System.assert(approvalController.dataClass.getUserDelegated());
          }
          approvalController.approve();
          System.assert(approvalController.dataClass.getIsApprovalApproved());
          approvalController.reject(); 
          System.assert(approvalController.dataClass.getIsApprovalRejected());
        }
        
        
     Test.stopTest();
     }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      }
    }
    
    static testmethod void LaunchApprovalBulkDelegation_Positive()
    {
     Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
        {
          List<Launch_Item_Approval__c> memberList=createGlobalTeam();
          init(); 
          List<Launch_Item__c> launchItemList=new List<Launch_Item__C>(); 
          
          
          User productManager = CreateUser('prodMgr4', 'Product Operations', 'Worldwide');
            insert productManager;
    
        User generalUser = CreateUser('TST_R12', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
       // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
       // insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        
        
        
          for(Integer i=0;i<10;i++)
          {
            Launch_Item__c newLauncItem=new Launch_Item__c();
            newLauncItem.Product_Manager__c = testUser.Id;
            newLauncItem.Name = 'test_launch_item';
            newLauncItem.Product_Line_pickList__c=plc.Id;
            newLauncItem.Division__c='Media';
            newLauncItem.PLU__c=plu.Id;
            newLauncItem.Version_Number__c='1.0';
            newLauncItem.Product_Phase__c='Beta';      
            newLauncItem.isFunctionalApprovalNotificationsSent__c=true;  
            newLauncItem.Program__c=ppc.Id;     
            launchItemList.add(newLauncItem);
          }
          PLM_LaunchItemClass.firstRun = true;
          PLM_LaunchItemApprovalGeneric.launchItemInsertFirstRunFlag=true;
          insert launchItemList;
          Test.startTest();
          User approverUser=[select Id, Name from User where alias =: 'tUser1'][0];
          Boolean isUserExists=false;
          if(approverUser!=null)
          {
            isUserExists=true;
          }
          system.assertEquals(isUserExists,true);
          System.runAs(approverUser)
          {
          String url='/apex/PLM_LIABulkDelegationPage';
          PageReference pageRefNew=new PageReference(url);
          test.setCurrentPageReference(pageRefNew);
          ApexPages.StandardSetController controller=new ApexPages.StandardSetController(new List<Launch_Item_Approval__c>());
          PLM_LaunchItemApprovalGeneric delegationController=new PLM_LaunchItemApprovalGeneric(controller);
          List<Launch_Item_Approval__c> launchApprovalList=[select Id,Approver__c from Launch_Item_Approval__c  where isCurrentUserApprover__c =1 and isVisible__c =:true and StandingDelegationCheck__c = true];
         // List<Launch_Item_Approval__c> launchApprovalList=[select Id,Approver__c from Launch_Item_Approval__c  where isCurrentUserApprover__c =1 and isVisible__c =:true];
          system.assertEquals(launchApprovalList.size(),delegationController.dataClass.getApprovalsToDelegate().size());
          url='/apex/PLM_CustomUserLookup';
          pageRefNew=new PageReference(url);
          test.setCurrentPageReference(pageRefNew);
          PLM_LaunchItemApprovalGeneric lookupController=new PLM_LaunchItemApprovalGeneric();
          lookupController.dataClass.setQuery('chandra');
          lookupController.runQuery();
          if(delegationController.dataClass.getApprovalsToDelegateWrapper().size()>0)
          {
          url='/apex/PLM_LIABulkDelegationPage';
          pageRefNew=new PageReference(url);
          test.setCurrentPageReference(pageRefNew);
          delegationController=new PLM_LaunchItemApprovalGeneric(controller);
          delegationController.dataClass.getApprovalWrapperClass().userId=testUser.Id;  
          delegationController.reassign();
          List<ApexPages.Message> messageList=ApexPages.getMessages();
          String message=messageList[0].getDetail();
          system.assertEquals(message,'Please select a record to reassign');
          delegationController.dataClass.setIsAllSelected(true);
          delegationController.selectAll();
          delegationController.reassign();
          // referesh
          delegationController.dataClass.setIsAllSelected(false);
          delegationController.selectAll();
          launchApprovalList=[select Id,Delegate_Approver__c from Launch_Item_Approval__c where id IN : launchApprovalList];
          for(Launch_Item_Approval__c lia: launchApprovalList)
          {
            System.assertEquals(lia.Delegate_Approver__c,testUser.Id);
          }
          
          }
          test.stopTest();
         }
       }
      if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      } 
    }
   
   static testmethod void LaunchItemStatusUpdateToApprovedTest()
    {
        Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
        {
          createGlobalTeam();
          init();
          test.startTest();
          String result=PLM_LaunchItemApprovalGeneric.makeVisibleAndNotifyDivisionApprover(li.Id,'');
          system.assertEquals(PLM_Custom_Settings__c.getInstance('LaunchItem#NotifyGMConfirmMsg').value__c,result);
          Launch_Item_Approval__c lia=[select Id, Approver__c,status__c from Launch_Item_Approval__c where isVisible__c =true and Launch_Item__c =:li.Id and division__c!=null and StandingDelegationCheck__c = false][0];
          System.assertEquals(lia.status__C,'Pending');
          User approverUser=[select Id from User where Id =: lia.Approver__c][0];
          System.runAs(approverUser)
          {
           String url='/apex/PLM_LIApprovalPage';
           PageReference pageref=new PageReference(url);
           pageref.getParameters().put('id',lia.Id);
           test.setCurrentPageReference(pageref);
           PLM_LaunchItemApprovalGeneric approvalController=new PLM_LaunchItemApprovalGeneric();
           approvalController.approve();
           test.stopTest();
           
           lia=[select Id, Approver__c,status__c from Launch_Item_Approval__c where isVisible__c =true and Launch_Item__c =:li.Id and division__c!=null and StandingDelegationCheck__c = false][0];
           system.assertEquals(lia.Status__c,'Approved');
           
           Launch_Item__c litest=[select id,Phase_Status__c,Activity_Status__c from Launch_Item__C where id=:li.Id][0];
           
           system.assertEquals(litest.Phase_Status__c,'Launch Tracking');
           system.assertEquals(litest.Activity_Status__c,'PLU - Approved');
          }
          
        }
        if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      } 
    }
    
   
    
    static testmethod void LaunchItemStatusUpdateToRejectedTest()
    {
        Boolean isToggled=false;
      if(!launchItemApprovalFeature.Toggle__c)
      {
       checkAndEnableLaunchItemApprovalFeature(true);
       isToggled=true;
      }
      if(launchItemApprovalFeature.Toggle__c)
        {
          createGlobalTeam();
          init();
          test.startTest();
          String result=PLM_LaunchItemApprovalGeneric.makeVisibleAndNotifyDivisionApprover(li.Id,'');
          system.assertEquals(PLM_Custom_Settings__c.getInstance('LaunchItem#NotifyGMConfirmMsg').value__c,result);
          Launch_Item_Approval__c lia=[select Id, Approver__c,status__c from Launch_Item_Approval__c where isVisible__c =true and Launch_Item__c =:li.Id and division__c!=null and StandingDelegationCheck__c = false][0];
          System.assertEquals(lia.status__C,'Pending');
          User approverUser=[select Id from User where Id =: lia.Approver__c][0];
          System.runAs(approverUser)
          {
           String url='/apex/PLM_LIApprovalPage';
           PageReference pageref=new PageReference(url);
           pageref.getParameters().put('id',lia.Id);
           test.setCurrentPageReference(pageref);
           PLM_LaunchItemApprovalGeneric approvalController=new PLM_LaunchItemApprovalGeneric();
           approvalController.reject();
           test.stopTest();
           
           lia=[select Id, Approver__c,status__c from Launch_Item_Approval__c where isVisible__c =true and Launch_Item__c =:li.Id and division__c!=null and StandingDelegationCheck__c = false][0];
           system.assertEquals(lia.Status__c,'Rejected');
           
           Launch_Item__c litest=[select id,Phase_Status__c,Activity_Status__c from Launch_Item__C where id=:li.Id][0];
           
           system.assertEquals(litest.Phase_Status__c,'Launch Tracking');
           system.assertEquals(litest.Activity_Status__c,'PLU - Rejected');
          }
          
        }
        if(isToggled)
      {
        checkAndEnableLaunchItemApprovalFeature(false);
      } 
    }
}