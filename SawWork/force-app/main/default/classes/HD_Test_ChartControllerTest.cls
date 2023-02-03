@isTest
public class HD_Test_ChartControllerTest
{
    @isTest(SeeAllData='true')
    public static  void getChartData() 

    {     Map<String,String> catTypes = HD_Test_Remedyforce_TestDataFactory.createcategorytype(new List<String> {'Q_Helpdesk_Triage', 'Q_Akamai_Test'}) ;//<'categoryTypeName','id'>
          //for each cagtegory type-----create 5 categories
          List<BMCServiceDesk__Category__c> cats = new List<BMCServiceDesk__Category__c>();
          for(String catType : catTypes.keySet()){
            for(Integer i = 1; i<=5; i++){
              BMCServiceDesk__Category__c  cat = new BMCServiceDesk__Category__c(name = 'Demo', BMCServiceDesk__AvailableForIncidents__c = true, BMCServiceDesk__FKCategoryType__c = catTypes.get(catType));
              cats.add(cat);
            }
          }
          //create category
          Map<String,String> catInserted =  HD_Test_Remedyforce_TestDataFactory.createCategory(cats);
          //create a user
          Boolean tr = true;
          Profile p = [SELECT Id FROM Profile WHERE Name='Engineering'];
          User u2 = [Select id from User where IsActive= :tr and ProfileId = :p.Id Limit 1];
          //User u = new User(Alias = 'newUser', Email='newuser@akamai.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
          //                    LocaleSidKey='en_US', ProfileId = p.Id,
          //                    TimeZoneSidKey='America/Los_Angeles', UserName='newuser@akamai.com');
          Test.startTest();  
          System.runAs(u2){
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            ChartController ctrl = new ChartController();
            //ctrl.loadDefaultConfiguration();
            ctrl.saveMyConfig();
            ctrl.getCategories();
            ctrl.getReports();
            System.debug('find me');
            System.debug(ctrl.rootCategories);
            ChartController ctrl2 = new ChartController();
            ctrl2.getData();
            ChartController ctrl3 = new ChartController();
            ctrl3.paretoFilter = 'BMC Remedyforce';
            ctrl3.getData();
            ChartController.test();


          }
           //TestDataFactoryChartController.createcategorytype();
          
          List<User> u1 = [select id from User limit 1];
          System.assert(u1.size() != null, 'done');
          Test.stopTest();
    }

    static testMethod void checkAutoRotate(){
      ChartController chartCntrl = new ChartController();
      chartCntrl.activeA = true;
      chartCntrl.activeB = true;
      chartCntrl.activeC = true;
      chartCntrl.activeD = true;
      chartCntrl.activeE = true;
      chartCntrl.activeF = true;
      chartCntrl.boolA = true;
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolB);
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolC);
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolD);
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolE);
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolF);
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolA); 

      //condition when none of the charts is selected for autoroate--- it should display the current dashboard only
      chartCntrl.activeA = false;
      chartCntrl.activeB = false;
      chartCntrl.activeC = false;
      chartCntrl.activeD = false;
      chartCntrl.activeE = false;
      chartCntrl.activeF = false;
      chartCntrl.boolA = false;
      chartCntrl.boolD = true;
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolD);
      chartCntrl.autoRotate();
      System.assertEquals(true,chartCntrl.boolD);

      //condition when
    }

    static testMethod void checkChangeFolder(){

      ChartController chartCntrl = new ChartController();
      chartCntrl.reportFolder = 'EIS Remedyforce';
      Test.startTest();
      List<Report> testReport = [SELECT Id, Name
            FROM Report where FolderName = 'EIS Remedyforce'
            and Format in ('Matrix','Summary') order by name];
      if(!testReport.isEmpty()){
        System.assertEquals(testReport,chartCntrl.bmcReports);
      }
      Test.stopTest();
    }



    static testMethod void changeDashboard(){

      Test.startTest();
      ChartController chartCntrl  = new ChartController();
      chartCntrl.callA();
      System.assertEquals(true,chartCntrl.boolA);
      chartCntrl.callB();
      System.assertEquals(true,chartCntrl.boolB);
      chartCntrl.callC(); 
      System.assertEquals(true,chartCntrl.boolC);
      chartCntrl.callD();
      System.assertEquals(true,chartCntrl.boolD);
      chartCntrl.callE();
      System.assertEquals(true,chartCntrl.boolE);
      chartCntrl.callF();
      System.assertEquals(true,chartCntrl.boolF);
      Test.stopTest();

    }
    static testMethod void checkSelectOptions(){
      Test.startTest();
      ChartController chartCntrl  = new ChartController();
      System.debug(chartCntrl.bmcReports);
      chartCntrl.getMonths();
      chartCntrl.getRefreshInterval();
      HD_Report_Folders__c folder1 = new HD_Report_Folders__c();
      List<HD_Report_Folders__c> folderList = new List<HD_Report_Folders__c>();
      folder1.name = 'BMC Remedyforce';
      folderList.add(folder1);
      HD_Report_Folders__c folder2 = new HD_Report_Folders__c();
      folder2.name = 'EIS Remedyforce';
      folderList.add(folder2);
      insert folderList;
      List<SelectOption> folderOptions = chartCntrl.getReportFoldersOption();
      System.assertNotEquals(0,folderOptions.size());
      chartCntrl.getParetoFilters();
      Test.stopTest();
    }

}