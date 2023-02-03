/*
    This class is referenced by two pages:
        1) HD_Dashboard 
        2) HD_Pareto_Chart

    This class uses following objects
        1) Incident
        2) Categpory
        3) Reports
        4) HD_Chart_Controller_User_Config__c

    This controller is created as a part of CR 3188751 and CR 3362701

    Modification Log ===============================================================
    Line Number     Date    Author  Modification
    Line 98     July 20th, 2020     Arihant Jain    PRTORES-1809 - HD Code scan 2020 - Blockers, Criticals Part 3
*/


global with sharing class ChartController {

    public  Map<Id, String> categoryMap = new Map<Id, String>();
    Map<ID, String> reportMap = new Map<Id, String>();
    public  String SCategory {get;set;}
    public String interval {get;set;}
    public final Boolean Ture = true;
    public String reportFolder {get;set;}
    public Integer intervalValue {get;set;}
    public  String category {get;set;}//category id on dashboard 1
    public String paretoFilter {get;set;}
    public  String month{get;set;}//month value on dashboard 1
    public String report1 {get;set;}//represents chart #1,1 on dashboard 2
    public String report2 {get;set;}//represents chart #1,2 on dashboard 2
    public String report3 {get;set;}//represents chart #1,3 on dashboard 2
    public String report4 {get;set;}//represents chart #2,1 on dashboard 2
    public String report5 {get;set;}//represents chart #2,2 on dashboard 2
    public String report6 {get;set;}//represents chart #2,3 on dashboard 2
    public String report7 {get;set;}//represents chart #2,1 on dashboard 1
    public String report8 {get;set;}//represents chart #2,2 on dashboard 1
    public String report9 {get;set;}//represents chart #2,3 on dashboard 1
    public String report10 {get;set;}//represents chart #1,1 on dashboard 3
    public String report11 {get;set;}//represents chart #1,2 on dashboard 3
    public String report12 {get;set;}//represents chart #2,1 on dashboard 3
    public String report13 {get;set;}//represents chart #2,2 on dashboard 3
    public String report14 {get;set;}//represents chart #1,1 on dashboard 4
    public String report15 {get;set;}//represents chart #1,2 on dashboard 4
    public String report16 {get;set;}//represents chart #1,1 on dashboard 5
    public String report17 {get;set;}//represents chart #1,2 on dashboard 5
    public String report18 {get;set;}//represents chart #1,1 on dashboard 6
    public String report19 {get;set;}//represents chart #1,2 on dashboard 6
    public String catName; //category name for the category with categor id {caetgory}
    public String currentUserId; //holds current user information
    public List<BMCServiceDesk__Category__c> rootCategories; // holds rooth categories for incidents
    public List<Report> bmcReports; // holds reports ids under bmc folder 
    public Boolean boolA {get;set;}//when true displays dashboard 1
    public Boolean boolB {get;set;}//when true displays dashboard 2
    public Boolean boolC {get;set;}//when true displays dashboard 3
    public Boolean boolD {get;set;}//when true displays dashboard 4 
    public Boolean boolE {get;set;}//when true displays dashboard 5 
    public Boolean boolF {get;set;}//when true displays dashboard 6 
    public Boolean activeA {get;set;}//when ture dashboard 1 is enabled for auto-rotation
    public Boolean activeB {get;set;}//when ture dashboard 2 is enabled for auto-rotation
    public Boolean activeC {get;set;}//when ture dashboard 3 is enabled for auto-rotation
    public Boolean activeD {get;set;}//when ture dashboard 4 is enabled for auto-rotation
    public Boolean activeE {get;set;}//when ture dashboard 5 is enabled for auto-rotation
    public Boolean activeF {get;set;}//when ture dashboard 6 is enabled for auto-rotation
    //public List<Boolean> dashboardState {get;set;} 
    public HD_Chart_Controller_User_Config__c userConfig;
    public Integer currentActiveRow{get;set;}
    
    //dropdown options for month selection on dashboard 1
    public List<SelectOption> getMonths(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new selectOption('1','1 Month'));
        options.add(new selectOption('2','2 Months'));
        options.add(new selectOption('3','3 Months'));
        return options;    
    }

    public List<SelectOption> getParetoFilters(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new selectOption('Default','Default'));
        options.add(new selectOption('true','Open'));
        options.add(new selectOption('false','Closed'));
        return options;    
    }
    
    public List<SelectOption> getRefreshInterval(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new selectOption('300','5 Minutes'));
        options.add(new selectOption('900','15 Minutes'));
        options.add(new selectOption('1800','30 Minutes'));
        return options;
    }
    
    public List<SelectOption> getReportFoldersOption(){
        List<SelectOption> options = new List<SelectOption>();
        List<HD_Report_Folders__c> folders = [Select name from HD_Report_Folders__c limit 500];
        for(HD_Report_Folders__c folder : folders){
            options.add(new selectOption(folder.name,folder.name));
        }
        return options;
    }

    //dropdown options for category selection on dashboard 1
    public List<SelectOption> getCategories() {
        List<SelectOption> options = new List<SelectOption>();
        for(BMCServiceDesk__Category__c ct : rootCategories){
            options.add(new selectOption(ct.ID,ct.name));
            categoryMap.put(ct.Id, ct.name);
        } 
        return options;
    }
    
    //dropdown options for report selection dashboard 2
    public List<SelectOption> getReports() {
        List<SelectOption> options = new List<SelectOption>();
        for(Report rp : bmcReports){
            options.add(new selectOption(rp.ID,rp.name));
            categoryMap.put(rp.Id, rp.name);
        } 
        return options;
    }

    private void roatate(String name){
        if (name != null){
            if(name == 'D1'){
                callA();
            } else if(name == 'D2'){
                callB();
            } else if (name == 'D3'){
                callC();
            } else if (name == 'D4'){
                callD();
            } else if (name == 'D5'){
                callE();
            }else if(name == 'D6') {
                callF();
            }
        }
    }

    public void autoRotate(){
        //get the current active dashboard
        List<AutoRotate> ar = new List<AutoRotate>();
        ar.add(new AutoRotate('D1',boolA,activeA,1));
        ar.add(new AutoRotate('D2',boolB,activeB,2));
        ar.add(new AutoRotate('D3',boolC,activeC,3));
        ar.add(new AutoRotate('D4',boolD,activeD,4));
        ar.add(new AutoRotate('D5',boolE,activeE,5));
        ar.add(new AutoRotate('D6',boolF,activeF,6));
        boolA = true;
        AutoRotate temp;
        AutoRotate temp2;
        for( AutoRotate x : ar){
            if(x.state){
                temp = x;
                currentActiveRow = x.order;
                break;
            }
        }
        if(temp != null){
            Integer j = temp.order - 1;
            Integer z;
            Integer y;
            //itereate the list to find the next active dashboard
            for(z= 1 ; z < ar.size();  z++){
                //find the immidiate 
                y =  math.mod(j + z,ar.size());
                if(ar[y].active){
                    temp2 = ar[y];
                    break;
                }
            }
        }
        if (temp2 != null){
            roatate(temp2.dashboard);
        } else {
            roatate(temp.dashBoard);
        }
        PageReference nextPage = new PageReference('/apex/HD_Dashboard');
        nextPage.setRedirect(true);
    }
    
    //function to save the current configuration of the logged in user.
    public void saveMyConfig(){
        HD_Chart_Controller_User_Config__c userConfig;
        try{
            userConfig = [select user__c,Display_Dashboard_1__c, Display_Dashboard_2__c from HD_Chart_Controller_User_Config__c where user__c = :currentUserId];
        }catch(Exception e){
            System.debug('Error:' + e);
            userConfig = new HD_Chart_Controller_User_Config__c();
            userConfig.user__c = currentUserId;
        }
        userConfig.Display_Dashboard_1__c = boolA;
        userConfig.Display_Dashboard_2__c = boolB;
        userConfig.Display_Dashboard_3__c = boolC;
        userConfig.Display_Dashboard_4__c = boolD;
        userConfig.Display_Dashboard_5__c = boolE;
        userConfig.Display_Dashboard_6__c = boolF;
        userConfig.D2x11__c = report1;
        userConfig.D2x12__c = report2;
        userConfig.D2x13__c = report3;
        userConfig.D2x21__c = report4;
        userConfig.D2x22__c = report5;
        userConfig.D2x23__c = report6;
        userConfig.D3x11__c = report7;
        userConfig.D3x12__c = report8;
        userConfig.D3x21__c = report9;
        userConfig.D3x22__c = report10;
        userConfig.D1x21__c = report11;
        userConfig.D1x22__c = report12;
        userConfig.D1x23__c = report13;
        userConfig.D1xCategory__c = category;
        userConfig.Refresh_Interval__c = interval;
        userConfig.Month__c = month;
        userConfig.D4x11__c = report14;
        userConfig.D4x12__c = report15;
        userConfig.D5x11__c = report16;
        userConfig.D5x12__c = report17;
        userConfig.D6x11__c = report18;
        userConfig.D6x12__c = report19;
        userConfig.Dashboard_1_Active__c = activeA;
        userConfig.Dashboard_2_Active__c = activeB;
        userConfig.Dashboard_3_Active__c = activeC;
        userConfig.Dashboard_4_Active__c = activeD;
        userConfig.Dashboard_5_Active__c = activeE;
        userConfig.Dashboard_6_Active__c = activeF;
        userConfig.Report_Folder__c = reportFolder;
        userConfig.Pareto_Filter__c = paretoFilter;
        intervalValue = Integer.valueOf(interval);
        upsert userConfig;
        System.debug(currentUserId);
    }

    public void loadUserConfiguration(HD_Chart_Controller_User_Config__c userConfig){
        boolA = userConfig.Display_Dashboard_1__c;
        boolB = userConfig.Display_Dashboard_2__c;
        boolC = userConfig.Display_Dashboard_3__c;
        boolD = userConfig.Display_Dashboard_4__c;
        boolE = userConfig.Display_Dashboard_5__c;
        boolF = userConfig.Display_Dashboard_6__c;
        report1 = userConfig.D2x11__c;
        report2 = userConfig.D2x12__c;
        report3 = userConfig.D2x13__c;
        report4 = userConfig.D2x21__c;
        report5 = userConfig.D2x22__c;
        report6 = userConfig.D2x23__c;
        report7 = userConfig.D3x11__c;
        report8 = userConfig.D3x12__c;
        report9 = userConfig.D3x21__c;
        report10 = userConfig.D3x22__c;
        report11 = userConfig.D1x21__c;
        report12 = userConfig.D1x22__c;
        report13 = userConfig.D1x23__c;
        report14 = userConfig.D4x11__c;
        report15 = userConfig.D4x12__c;
        report16 = userConfig.D5x11__c;
        report17 = userConfig.D5x12__c;
        report18 = userConfig.D6x11__c;
        report19 = userConfig.D6x12__c;
        month = userConfig.Month__c;
        activeA = userConfig.Dashboard_1_Active__c;
        activeB = userConfig.Dashboard_2_Active__c;
        activeC = userConfig.Dashboard_3_Active__c;
        activeD = userConfig.Dashboard_4_Active__c;
        activeE = userConfig.Dashboard_5_Active__c;
        activeF = userConfig.Dashboard_6_Active__c;
        category = userConfig.D1xCategory__c;
        interval = userConfig.Refresh_Interval__c;
        paretoFilter = userConfig.Pareto_Filter__c;
        if(userConfig.Report_Folder__c == null){
            reportFolder = 'BMC Remedyforce';
        }
        else{
            reportFolder =  userConfig.Report_Folder__c;
        }
        bmcReports = [SELECT Id, Name
                        FROM Report where FolderName = :reportFolder
                        and Format in ('Matrix','Summary') order by name]; 
        intervalValue = Integer.valueOf(interval);
    }

    //wrapper class
    class AutoRotate{
        String dashBoard;
        Boolean state;
        Boolean active;
        Integer order;
        public AutoRotate(String dashBoard, Boolean state, Boolean active, Integer order){
            this.dashBoard = dashboard;
            this.state = state;
            this.active = active;
            this.order = order;
        }
    }

    public void reportInitialize(String id){
        report1 = id;
        report2 = id;
        report3 = id;
        report4 = id;
        report5 = id;
        report6 = id;
        report7 = id;
        report8 = id;
        report9 = id;
        report10 = id;
        report11 = id;
        report12 = id;
        report13 = id;
        report14 = id;
        report15 = id;
        report16 = id;
        report17 = id;
        report18 = id;
        report19 = id;
    }

    public void loadDefaultConfiguration(){
        boolA = true;
        boolB = false;
        boolC = false;
        boolD = false;
        boolE = false;
        boolF = false;
        activeA = false;
        activeB = false;
        activeC = false;
        activeD = false;
        activeE = false;
        activeF = false;
        interval = '300';
        paretoFilter = 'Default';
        reportFolder = 'BMC Remedyforce';
        try{
            bmcReports = [SELECT Id, Name
                        FROM Report where FolderName = :reportFolder
                        and Format in ('Matrix','Summary') order by name];
            System.debug('Pranav - enetered in loadDefaultConfiguration');
            System.debug(bmcReports);
            if(bmcReports[0] !=null){
                reportInitialize(bmcReports[0].id);
            }
        } catch(Exception e){
            System.debug('no reports data');
        }
        
        intervalValue = Integer.valueOf(interval);
    }
    
    public ChartController(){
        bmcReports = new List<Report>();
        
        currentUserId = UserInfo.getUserId();
        
        try{ 
            userConfig = [select user__c, Display_Dashboard_1__c, Display_Dashboard_2__c, Display_Dashboard_3__c, 
                          Display_Dashboard_4__c, Display_Dashboard_5__c,  D2x11__c, Display_Dashboard_6__c,
                          Dashboard_1_Active__c, Dashboard_2_Active__c, Dashboard_3_Active__c, 
                          Dashboard_4_Active__c, Dashboard_5_Active__c, Dashboard_6_Active__c,
                          D2x12__c, D2x13__c, D2x21__c, D2x22__c, D2x23__c, D1xCategory__c, Refresh_Interval__c,
                          D3x11__c, D3x12__c, D3x21__c, D3x22__c, D1x21__c, D1x22__c, D1x23__c, 
                          D4x11__c, D4x12__c, D5x11__c, D5x12__c, D6x11__c, D6x12__c, Month__c, Report_Folder__c, Pareto_Filter__c 
                          from HD_Chart_Controller_User_Config__c where user__c = :currentUserId];
            loadUserConfiguration(userConfig);
        }catch(Exception e){
            System.debug('Error:' + e);
            loadDefaultConfiguration();
        }
        System.debug(currentUserId);
        System.debug('Pranav Priniting -- after loadUserConfiguration ---> '+ reportFolder);
        rootCategories = new List<BMCServiceDesk__Category__c>();
        rootCategories = [select ID , name 
                            from BMCServiceDesk__Category__c where 
                            BMCServiceDesk__FKParentCategory__c = null and 
                            BMCServiceDesk__AvailableForIncidents__c = true order by name];
        System.debug(intervalValue);
    }

    public void callA(){
        boolA = true;
        boolB = false;
        boolC = false;
        boolD = false;
        boolE = false;
        boolF = false;
    }

    public void callB(){
        boolA = false;
        boolB = true;
        boolC = false;
        boolD = false;
        boolE = false;
        boolF = false;
    }
    public void callC(){
        boolA = false;
        boolB = false;
        boolC = true;
        boolD = false;
        boolE = false;
        boolF = false;
    }
    public void callD(){
        boolA = false;
        boolB = false;
        boolC = false;
        boolD = true;
        boolE = false;
        boolF = false;
    }
    public void callE(){
        boolA = false;
        boolB = false;
        boolC = false;
        boolD = false;
        boolE = true;
        boolF = false;
    }
    public void callF(){
        boolA = false;
        boolB = false;
        boolC = false;
        boolD = false;
        boolE = false;
        boolF = true;
    }

    public List<Data> getData() {
        if (category == null){
            category = rootCategories[0].id; 
        } 
        Integer monthInt = 1;
        if(month != null)
        monthInt = integer.ValueOf(month);    
         
        catName = categoryMap.get(category);
        if(paretoFilter == null){
            paretoFilter = 'Default';
        }
        return ChartController.getChartDataReal(category,catName, monthInt, paretoFilter);
    }
    public class Data {
        public String name { get; set; }
        public Integer data1 { get; set; }
        public Integer data2 { get; set; }
        public Integer data3 { get; set; }
        public Data(String name, Integer data1, Integer data2, Integer data3) {
            this.name = name;
            this.data1 = data1;
            this.data2 = data2;
            this.data3 = data3;
        }
    }
    
    public static List<Data> getChartDataReal(String cat, String ctName, Integer mnt, String paretoFilter) {
        List<Data> results = new List<Data>();
        ctName = '%-->' + ctName;
        date d = system.today().addDays(-30 * mnt);
        AggregateResult[] groupedResults;
        try{
            if(paretoFilter == 'Default' || paretoFilter == '' || paretoFilter == null){
            groupedResults = [SELECT Sum(Count_As_One__c) c,BMCServiceDesk__FKCategory__r.Name FROM 
                                            BMCServiceDesk__Incident__c where 
                                            (BMCServiceDesk__FKCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat 
                                            ) and
                                            BMCServiceDesk__openDateTime__c > :d
                                            group by BMCServiceDesk__FKCategory__r.Name 
                                            order by Sum(Count_As_One__c) desc limit 10];
            } else {
                Boolean state = Boolean.valueOf(paretoFilter);
                groupedResults = [SELECT Sum(Count_As_One__c) c,BMCServiceDesk__FKCategory__r.Name FROM 
                                            BMCServiceDesk__Incident__c where 
                                            (BMCServiceDesk__FKCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat or
                                            BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c = :cat 
                                            ) and BMCServiceDesk__state__c = :state and
                                            BMCServiceDesk__openDateTime__c > :d

                                            group by BMCServiceDesk__FKCategory__r.Name 
                                            order by Sum(Count_As_One__c) desc limit 10];
            }
            
        } catch(Exception e) {
                groupedResults.clear();
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Too many records!! Try using lower months'));
        }
       // for()

        Integer sum = 0;
        for (AggregateResult ar : groupedResults){
            Integer value = sum + Integer.valueOf(ar.get('c'));
            sum = value;
            Data data = new Data(String.valueOf(ar.get('Name')), 0,Integer.valueOf(ar.get('c')),value);
            results.add(data);
        }

        for(Data forUpdate: results){
            Integer temp = forUpdate.data3;
            Integer percent = (forUpdate.data3*100)/sum;
            forUpdate.data3 = percent;
        }
        
        if(results.size() == 0){
            Data dummy = new Data('no record',0,0,0);
            results.add(dummy);
            
        }
        return results;
    }
    
    public void  changeReportFolder(){
       try{
            bmcReports = [SELECT Id, Name
            FROM Report where FolderName = :reportFolder
            and Format in ('Matrix','Summary') order by name];
            System.debug('Pranav - enetered in loadDefaultConfiguration');
            System.debug(bmcReports);
            if(bmcReports[0] !=null){
                reportInitialize(bmcReports[0].id);
            }
        } catch(Exception e){
            System.debug('no reports data');
        }
    }

    public static PageReference test() {

        return null;
    }
}