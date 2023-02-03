/*--=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  03-Oct-2016    Kunal      3527281     Controller class of the second version of Automating License Usage Report
+=====================================================================================================--*/
public without sharing class LicenseUsageReportController {
    
    License_Report_Run_Logger__c licenseReportRunLogger{get;set;}
    //public static Map<String, Integer> mActiveAndIdleUsers {get{if(mActiveAndIdleUsers==null)mActiveAndIdleUsers = new Map<String, Integer>(); return mActiveAndIdleUsers;} set;}
    public List<DataWrapper> lDataToDisplay {get{if(lDataToDisplay==null) lDataToDisplay = new List<DataWrapper>(); return lDataToDisplay;} set;}
    public List<DataWrapper> lPieDataToDisplay {get{if(lPieDataToDisplay==null) lPieDataToDisplay = new List<DataWrapper>(); return lPieDataToDisplay;} set;}
    //public List<DataWrapper> lAllRecordsToDisplay = new List<DataWrapper>();
    String idLicenseReportRunLogger;
    public String licenseName{get;set;}
    public Date usageStartDate {get; set;}
    String usageType {get; set;}
    String nameSpacePrefix = 'pse';
    List<Id> lUsersWithActiveLicense = new List<Id>();
    Integer pageNumber{get; set;}
    Integer pageSize{get; set;}
    public List<DataWrapper> lAllRecordsToDisplay {get{if(lAllRecordsToDisplay==null) lAllRecordsToDisplay = new List<DataWrapper>(); return lAllRecordsToDisplay;} set;}
    public Boolean disableNext{get; set;}
    public Boolean disablePrevious{get; set;}
    //public String lJSONDataToSend{get;set;}
    public Set<String> sUserIdsPresentInLogObj = new Set<String>();
    public Map<String,User> mUserDetails = new Map<String,User>();
    public List<UserLicenseUsageLog__c> lUserLicenseLogRecs = new List<UserLicenseUsageLog__c>();
    //public Set<String> sAllUsers = new Set<String>();
    
    public LicenseUsageReportController(){
        if(Apexpages.currentPage()!= NULL 
           && (String.valueOf(Apexpages.currentPage()).containsIgnoreCase('/apex/LicenseUsageDownload')
              || String.valueOf(Apexpages.currentPage()).containsIgnoreCase('/apex/LicenseUsageCSVDownload'))){ 
            licenseName = Apexpages.currentPage().getParameters().get('licenseName');
            usageStartDate = date.valueOf(ApexPages.currentPage().getParameters().get('usageStartDate'));
            usageType = ApexPages.currentPage().getParameters().get('usageType');
            runReport();
        }
        
    }
    
    public LicenseUsageReportController(ApexPages.StandardController controller){
        if(Apexpages.currentPage()!= NULL 
           && (String.valueOf(Apexpages.currentPage()).containsIgnoreCase('/apex/LicenseUsageDownload')
               || String.valueOf(Apexpages.currentPage()).containsIgnoreCase('/apex/LicenseUsageCSVDownload'))){ 
            licenseName = Apexpages.currentPage().getParameters().get('licenseName');
            usageStartDate = date.valueOf(ApexPages.currentPage().getParameters().get('usageStartDate'));
            usageType = ApexPages.currentPage().getParameters().get('usageType');
            runReport();
        }
       
        licenseReportRunLogger = (License_Report_Run_Logger__c) controller.getRecord();
        licenseReportRunLogger.Report_Creator__c = Userinfo.getUserId();
        licenseReportRunLogger.Start_Date__c = System.today().addMonths(-3);
        licenseName = licenseReportRunLogger.License_Name__c;
        usageStartDate = licenseReportRunLogger.Start_Date__c;
        usageType = licenseReportRunLogger.Filter__c;
        
    }
    
	  
    
    public void runReport(){
        if(Apexpages.currentPage()!= NULL && String.valueOf(Apexpages.currentPage()).containsIgnoreCase('/apex/LicenseUsageReport')){ 
            licenseName = licenseReportRunLogger.License_Name__c;
            usageStartDate = licenseReportRunLogger.Start_Date__c;
            usageType = licenseReportRunLogger.Filter__c;
        }
        //pageNumber = 1;
        //disableNext = false;
        lDataToDisplay.clear();
        //All the users with License
        getUsersWithLicense();
        //All the users who have entry in User License Log
        List<UserLicenseUsageLog__c> lUserToGenerateReport = getAllUsers();
        for(UserLicenseUsageLog__c varUsersInLogObj :lUserToGenerateReport){
            sUserIdsPresentInLogObj.add(varUsersInLogObj.User__c);
        }
        //lDataToDisplay = getUserUsageData(lUserToGenerateReport);
        lAllRecordsToDisplay = getUserUsageData(lUserToGenerateReport);
        mUserDetails.clear();
        lDataToDisplay.clear();
        lUserToGenerateReport.clear();
		lUsersWithActiveLicense.clear();
        //sendPaginatedRecords();
    }
    
    public PageReference sendCSVToCreator(){
        PageReference pg = new PageReference('/apex/LicenseUsageCSVDownload?licenseName='+licenseName+'&usageStartDate='+usageStartDate+'&usageType='+usageType);
        pg.setRedirect(true);
        return  pg;
        
 
    }
    
    
    private void getUsersWithLicense(){
        for(UserPackageLicense varUserLicensePakg : [SELECT Id, UserId
                                                     FROM UserPackageLicense 
                                                     WHERE PackageLicense.NamespacePrefix = :nameSpacePrefix]){
            lUsersWithActiveLicense.add(varUserLicensePakg.UserId);
            
        }
        
        for(User varUser :[SELECT Name, Id, Profile.Name, Email, Department, Manager.Name, Manager.Email
                           FROM User 
                           WHERE Id IN :lUsersWithActiveLicense]){
            mUserDetails.put(varUser.Id, varUser);
        }
    }
    
    private List<UserLicenseUsageLog__c> getAllUsers(){
		
        return [SELECT Id, User__c, LicenseUsageLog__c, User__r.Name, 
                User__r.Profile.Name, User__r.Email, User__r.Department, 
                User__r.Manager.Name, User__r.Manager.Email, Exempted_User__c
                FROM UserLicenseUsageLog__c
              	WHERE User__c IN :lUsersWithActiveLicense];
    }
    
    private List<DataWrapper> getUserUsageData(List<UserLicenseUsageLog__c> lAllUsers){
        //lPieDataToDisplay.clear();
        List<DataWrapper> lUserUsageData = new List<DataWrapper>();
        lUserUsageData.clear();
        //String licenseName;
        //Map<String,Integer> mActiveAndIdleUsers = new Map<String,Integer>{'Active Users'=>0, 'Inactive Users' =>0};
        for(UserLicenseUsageLog__c varUser :lAllUsers){
            if(varUser.LicenseUsageLog__c != '' && varUser.LicenseUsageLog__c != null){
            	List<Object> lLicenseUserHas = (List<Object>) JSON.deserializeUntyped(varUser.LicenseUsageLog__c);
                for(Object varObject : lLicenseUserHas){
                    
                    Map<String,Object> mIndividualLicense = (Map<String,Object>) varObject;                    
                    if((String) mIndividualLicense.get('licenseName') == licenseName 
                       && getFilterType(mIndividualLicense,varUser)){
                    	
                    	lUserUsageData.add(new DataWrapper((String) mIndividualLicense.get('licenseName'), 
                             			   datetime.valueOf(((String)mIndividualLicense.get('lastUsedDate')).replace('T', ' ').substringBefore('.')),
                             			   varUser.User__r.Name, (String) mIndividualLicense.get('lastUsedObject'), false,
                                           usageStartDate, '',null,
                                           varUser.User__r.Profile.Name, varUser.User__r.Email,varUser.User__r.Department,
                                           varUser.User__r.Manager.Name,varUser.User__r.Manager.Email,
                                           varUser.Exempted_User__c));
                    }                                        
                    
                }
            }
        }
        
        if(usageType.trim().equalsIgnoreCase('Inactive Users') 
          || usageType.trim().equalsIgnoreCase('All Users')){
            for(String varUserId :lUsersWithActiveLicense){
                if(! sUserIdsPresentInLogObj.contains(varUserId)){
                    lUserUsageData.add(new DataWrapper(licenseName, 
                                               Datetime.newInstanceGmt(1900, 01, 01),
                                               mUserDetails.get(varUserId).Name, 'NA', false,
                                               usageStartDate, '',null,
                                               mUserDetails.get(varUserId).Profile.Name, 
                                               mUserDetails.get(varUserId).Email,mUserDetails.get(varUserId).Department,mUserDetails.get(varUserId).Manager.Name,
                                               mUserDetails.get(varUserId).Manager.Email,false));
                }
            }
        }
        
        return lUserUsageData;
    }
    
    private Boolean getFilterType(Map<String,Object> mIndividualLicense, UserLicenseUsageLog__c userToCheck){
        Datetime dateToCompare = datetime.valueOf(((String)mIndividualLicense.get('lastUsedDate')).replace('T', ' ').substringBefore('.'));
        
        if((dateToCompare >= usageStartDate && usageType.trim().equalsIgnoreCase('Active Users'))
          ||(dateToCompare < usageStartDate && usageType.trim().equalsIgnoreCase('Inactive Users') && !userToCheck.Exempted_User__c)
          || usageType.trim().equalsIgnoreCase('All Users')){
               return true;
           }
        return false;
    }     
    
    
    public class DataWrapper{
        public String licenseName {get; set;}
        public Integer numberOfUser{get; set;}
        public DateTime lastUsedDate {get; set;}
        public String userName {get; set;}
        public String objectAccessed {get; set;}
        public Boolean selectBox {get; set;}
        public Boolean isUserIdle {get; set;}
        public Integer numberOfUsers {get; set;}
        public String typeOfUser {get; set;}
        public String profileName {get; set;}
        public String userEmail {get; set;}
        public String department{get;set;}
        public String manager {get;set;}
        public String managerEmail{get;set;}
        public Boolean exemptedUser{get;set;}
        
        public DataWrapper(String licenseName, DateTime lastUsedDate,
                           String userName, String objectAccessed,
                           Boolean selectBox, DateTime usageStartDateToWrap,
                           String typeOfUser, Integer numberOfUsers,
                           String profileName, String userEmail, String department,
                           String manager,String managerEmail,
                           Boolean exemptedUser){
            this.licenseName = licenseName;
            this.lastUsedDate = lastUsedDate;
            this.userName = userName;
            this.objectAccessed = objectAccessed;
            this.selectBox = selectBox;
            this.typeOfUser = typeOfUser;
            this.numberOfUsers = numberOfUsers;
            this.userEmail = userEmail;
            this.profileName = profileName;
            this.exemptedUser = exemptedUser;
            if(lastUsedDate > usageStartDateToWrap){
            	this.isUserIdle = false;
                
            }
            else{
                this.isUserIdle = true;
                
            }
            this.department = department;
			this.manager = manager;
			this.managerEmail = managerEmail;                               
        }
    }
}