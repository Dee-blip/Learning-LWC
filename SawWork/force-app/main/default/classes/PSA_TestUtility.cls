/***
    PSA_TestUtility
    @author Liz Ichihashi
    @Description : This Class contains methods to create object for use in test cases.
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         12/04/2010        Created the class.  
    janantha              03/12/2014        Modified the class to set the record type to PSA resource for the contact.   
    Sharath               26 june 2018      Modified the function:Changes by Sharath for FFPSA-607: removed the query from the for loop and created the method for timedate creation
*/
@isTest
public without sharing class PSA_TestUtility {

    //flip actuals calculation mode to Scheduled
    public PSA_TestUtility() {
        try { 

            appirio_core__Config_Value__c configVal = [Select appirio_core__Value__c, appirio_core__Config_Option__r.Name 
                                                     From appirio_core__Config_Value__c
                                                     Where  appirio_core__Config_Option__r.Name  = 'CalculationMode'
                                                     and appirio_core__Config_Option__r.appirio_core__Config_Group__r.Name = 'Actuals'];

            if (configVal != null && configVal.appirio_core__Value__c == 'Immediate') {                                              
                configVal.appirio_core__Value__c = 'Scheduled';
                update configVal;
            }
        } catch (Exception e) {
            System.debug('error setting config value to Scheduled in PsaTestHarness');
        }       
    }

// *************************************************************************************************
// GLOBALS and CONSTANTS
// *************************************************************************************************

// general constants
public final String CURRENCY_DEFAULT = 'USD';
public final String COUNTRY_DEFAULT = 'US';
public final Id NULL_ID = null;
public final Decimal NULL_DECIMAL = null;
public final String NULL_STRING = null;

// standard object constants
public final String USER_EMAIL_ENCODING_KEY_DEFAULT = 'ISO-8859-1';
public final String USER_LANGUAGE_LOCALE_KEY_DEFAULT = 'en_US';
public final String USER_LOCALE_SID_KEY_DEFAULT = 'en_US';
//Start of changes by janantha to change the time zone
public final String USER_TIME_ZONE_SID_KEY_DEFAULT= 'America/Los_Angeles';
//End of changes by janantha to change the time zone
public final String OPP_STAGE_NAME_CLOSED_WON = 'Closed Won';
public final String OPP_STAGE_NAME_CLOSED_LOST = 'Closed Lost';

// psa organization constants
public final String RESOURCE_RECORD_TYPE_NAME = ''; // leave empty if not using record types on contact for resources
public final String RESOURCE_ROLE_DEFAULT = 'Consultant';
public final Decimal RESOURCE_BILL_RATE_DEFAULT = 100.0;
public final Decimal RESOURCE_COST_RATE_DEFAULT = 80.0;

// psa project constants
public final String TIMECARD_STATUS_SAVED = 'Saved';
public final String TIMECARD_STATUS_SUBMITTED = 'Submitted';
public final String TIMECARD_STATUS_APPROVED = 'Approved';
public final String TIMECARD_STATUS_REJECTED = 'Rejected';

// psa schedule patterns
public final String SCHEDULE_PATTERN_8x5 = '8x5';
public final String SCHEDULE_PATTERN_10x4 = '10x4';
public final String SCHEDULE_PATTERN_0 = '0';
public final String SCHEDULE_PATTERN_1 = '1';

public final String EXPENSE_REPORT_STATUS_DRAFT = 'Draft';
public final String EXPENSE_REPORT_STATUS_SUBMITTED = 'Submitted';
public final String EXPENSE_REPORT_STATUS_APPROVED = 'Approved';
public final String EXPENSE_REPORT_STATUS_REJECTED = 'Rejected';
public final String EXPENSE_REPORT_DESC_DRAFT = 'Description';

public final Decimal EXPENSE_AMOUNT_DEFAULT = 100.0;
public final String EXPENSE_EXPENSE_TYPE_DEFAULT = 'Taxi';

public final Decimal TIMECARD_HOURS_PER_DAY_DEFAULT = 8;

// global variables
public Integer nameIndex = 0; // used to ensure uniqueness for new records
public Map<String,Id> mapRecordTypeIds = new Map<String,Id>();

// *************************************************************************************************
// STANDARD OBJECT METHODS
// *************************************************************************************************

// ============================================================================
// Account 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Account getAccount(){
  List<Account> lstAccounts = new List<Account>([
    SELECT Id
      FROM Account
     WHERE Name = 'TestAccount'
     LIMIT 1
  ]);
  
  if(lstAccounts.size() == 1){
    return lstAccounts[0];
  } else {
    return newAccount(true);
  }
}


public Account newAccount(Boolean isInsert){
    
    //to set this Akam Account Id as an external Id while creating the Account.
    Integer len = 5;
  String str = string.valueof(Math.abs(Crypto.getRandomLong()));
  String randomNumber = str.substring(0, len);
    
  Account rec = new Account(
    Name = 'TestAccountFFAccCreation',
  AKAM_Account_ID__c = 'AkamFF' + randomNumber,
    BillingCity = 'New York',
    BillingStreet = '100 Main st',
    BillingState = 'NY',
    BillingPostalCode = '11111',
    BillingCountry = COUNTRY_DEFAULT,
    Contract_Currency__c = 'USD'
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}

public Account newAccountForRR(Boolean isInsert,String Random,String Geo_Division,String Region,String Territory){
  Account rec = new Account(
    Name = 'RRTestAccount'+ Random,
    BillingCity = 'New York',
    BillingStreet = '100 Main st',
    BillingState = 'NY',
    BillingPostalCode = '11111',
    BillingCountry = COUNTRY_DEFAULT,
    Contract_Currency__c = 'USD',
    Parent_Division__c = Geo_Division,
    Region__c = Region,
    Area__c = Territory
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}

// ============================================================================
// Contact 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Contact getResource(
  Id accountId, 
  Id userId,
  Id regionId, 
  Id workCalendarId
){
  
  // filter for record type if used
  List<Contact> lstContacts = new List<Contact>([
    SELECT Id 
      FROM Contact 
     WHERE pse__Is_Resource__c = true 
       AND pse__Is_Resource_Active__c = true 
       AND pse__Region__c = :regionId
       AND pse__Salesforce_User__c = :userId 
     LIMIT 1 
  ]);
  
  if(lstContacts.size() == 1){
    return lstContacts[0];
  } else {
    return newResource(true, accountId, userId, regionId, workCalendarId);
  }
}


public Contact newResource(
  Boolean isInsert, 
  Id accountId,
  Id userId
  ){
  
  return newResource(
    isInsert,
    accountId,
    userId,
    NULL_ID,
    NULL_ID
  );
}


public Contact newResource(
  Boolean isInsert, 
  Id accountId, 
  Id userId,
  Id regionId, 
  Id workCalendarId
){
  Contact rec = new Contact(
    AccountId = accountId,
    FirstName = 'F Name Test_' + (nameIndex++),
    LastName = 'Test_' + (nameIndex++),
    pse__Region__c = regionId,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    pse__Is_Resource_Active__c = true,
    pse__Is_Resource__c = true,
    pse__Resource_Role__c = RESOURCE_ROLE_DEFAULT,
    pse__Default_Cost_Rate__c = RESOURCE_COST_RATE_DEFAULT,
    pse__Work_Calendar__c = workCalendarId,
    pse__Salesforce_User__c = userId,
    /*change by janantha for setting the record type to PSA Resource */
    RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId()
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}

public pse__Resource_Request__c newResourceRequest(
  Boolean isInsert, 
  Id accountId, 
  Id contId,
  Date startDt, 
  Date endDt,
  Id projId,
  Id oppId,
  Id regId
){
  pse__Resource_Request__c rec = new pse__Resource_Request__c(
    Originating_Account__c = accountId,
    pse__Start_Date__c = startDt,
    pse__End_Date__c = endDt,
    Product__c = 'Aqua',
    Severity__c = '1 - Major Impact',
    pse__Request_Priority__c = 'Implememtation',
    Resource_Request_Sub_Type__c = 'Standard',
    pse__SOW_Hours__c = 40,
    pse__Project__c = projId,
    pse__Opportunity__c = oppId,
    pse__Status__c = 'Draft',
    pse__Region__c = regId
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}

public pse__Resource_Request__c newResourceRequestforRR(
  Boolean isInsert, 
  Id accountId, 
  Id contId,
  Date startDt, 
  Date endDt,
  Id projId,
  Id oppId,
  Id regId,
  String Type,
  String Subtype,
  String Product,
  String Role
){
  pse__Resource_Request__c rec = new pse__Resource_Request__c(
    Originating_Account__c = accountId,
    pse__Start_Date__c = startDt,
    pse__End_Date__c = endDt,
    Product__c = Product,
    Severity__c = '1 - Major Impact',
    pse__Request_Priority__c = Type,
    Resource_Request_Sub_Type__c = Subtype,
    pse__SOW_Hours__c = 40,
    pse__Project__c = projId,
    pse__Opportunity__c = oppId,
    pse__Status__c = 'Ready to Staff',
    pse__Resource_Role__c=Role,
    pse__Region__c = regId
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


// ============================================================================
// Opportunity 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Opportunity getOpportunity(){
  
  List<Opportunity> lstOpportunity = new List<Opportunity>([
    SELECT Id 
      FROM Opportunity 
     LIMIT 1 
  ]);
  
  if(lstOpportunity.size() == 1){
    return lstOpportunity[0];
  } else {
    return newOpportunity(true);
  }
}


public Opportunity newOpportunity(
  Boolean isInsert
  ){
  
  return newOpportunity(
    isInsert,
    getAccount().Id,
    (String)null,
    (Date)null
  );
}

public Opportunity newOpportunity(
  Boolean isInsert,
  Id accountId
  ){
  
  return newOpportunity(
    isInsert,
    accountId,
    (String)null,
    (Date)null
  );
}

public Opportunity newOpportunity(
  Boolean isInsert, 
  Id accountId,
  String stageName,
  Date closeDate
  ){
  
  // set defaults
  if(stageName == null || stageName == ''){
    stageName = OPP_STAGE_NAME_CLOSED_WON;
  }
  if(closeDate == null){
    closeDate = Date.today();
  }
  
  Opportunity rec = new Opportunity(
    Name = 'TestOpp',
    AccountId = accountId,
    StageName = stageName,
    CloseDate = closeDate,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    Validation_Override__c = TRUE,
    Carrier_Application__c='Retail CDN services'
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}

public List<OpportunityLineItem> createOpportunityItems(Id oppId, Integer NumberOfItems) {
    List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
    
    Product2 prod = new Product2(Name = 'Carrier1', Family = 'Carrier1', CurrencyIsoCode = 'USD');
    insert prod;
    System.debug('prod id : ' + prod.Id);
    Id standardPriceBookId = Test.getStandardPricebookId();
    PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = prod.Id, IsActive = true, UnitPrice = 0, CurrencyIsoCode = 'USD');
    insert standardPrice;
    System.debug('standpriceid : ' + standardPrice.Id);

    Pricebook2 customPB = new Pricebook2(Name='Carrier1', isActive=true, CurrencyIsoCode = 'USD' );
    insert customPB;
    System.debug('customPB : ' + customPB.Id);
    
    //Changes by Sharath for FFPSA-607: removed the query from the for loop
    List<PricebookEntry> priceBookList = new List<PricebookEntry>();    
    priceBookList = [select Id from PricebookEntry where IsActive = true and currencyISOCode = 'USD' and Product2.Name!='Carrier' and Product2.Family !='Carrier' limit 1];
    Id priceBookId;
    if(!priceBookList.isEmpty())
    { 
      priceBookId = priceBookList.get(0).Id;
    }
    
    for (Integer idx = 0; idx < NumberOfItems; idx++) {
        OpportunityLineItem line = new OpportunityLineItem();       
        line.PricebookEntryId = priceBookId;
        line.Quantity = 2;
        line.ServiceDate = System.today();
        line.UnitPrice = 5000;  
        line.Description = 'test line ' + idx;
        line.OpportunityId = oppId;
        line.Validation_Override__c = TRUE;
        
        lines.add(line);
    }   
    insert lines;
    return lines;
}





// ============================================================================
// User 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public User getUserSysAdmin(){
  
  List<User> lstUsers = new List<User>([
  SELECT Id
    FROM User
   WHERE Profile.Name = 'System Administrator'
    AND IsActive = true
   LIMIT 1   
  ]);
  
  if(lstUsers.size() > 0){
    return lstUsers[0];
  } else {
    return newUserSysAdmin(true);
  }
}


public User newUserSysAdmin(Boolean isInsert){
  
  Double dRandom = Math.random();
  String d = String.valueOf(dRandom);
  String i = String.valueOf(dRandom).substring(0,1);
  System.debug('i='+i);
  
  List<Profile> lstProfiles = new List<Profile>([
    SELECT Id 
      FROM Profile 
     WHERE Name = 'System Administrator' 
    LIMIT 1
  ]);
  if(lstProfiles.size() == 0) {
    System.debug('ERROR: no system admin profile found');
    return null;
  }
  
  User rec = new User(
    
    firstName = 'testGR' + i,
    LastName = 'testGR' + i,
    Alias = 'tst' + i,
    Email = 'testgr' + i + '.test@akamai.com',
    UserName='test'+ Math.random().format()+i+'user1@akamai.com',
    EmailEncodingKey = USER_EMAIL_ENCODING_KEY_DEFAULT,
    LanguageLocaleKey = USER_LANGUAGE_LOCALE_KEY_DEFAULT,
    TimeZoneSidKey = USER_TIME_ZONE_SID_KEY_DEFAULT,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    LocaleSidKey = USER_LOCALE_SID_KEY_DEFAULT,
    ProfileId = lstProfiles[0].Id,
    IsActive=true
    );
  
  rec.CommunityNickname = d;
  System.debug('rec.CommunityNickname='+rec.CommunityNickname);
  if(isInsert){
      try
      {
          insert rec;
      }  
      catch(Exception e)
      {
          rec.UserName = 'test'+ Math.random().format() + Math.random().format()+'user1@akamai.com';
          insert rec;
      }
    
  }
  return rec;
}


// *************************************************************************************************
// PSA ORGANIZATION OBJECT METHODS
// *************************************************************************************************

// ============================================================================
// Permission Controls 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Permission_Control__c newPermissionControl(
  Boolean isInsert,
  Id userId,
  Id regionId
){
  return newPermissionControl(
    isInsert,
    userId,
    regionId,
    NULL_ID,
    NULL_ID,
    NULL_ID,
    NULL_ID,
    true
  );
}

public pse__Permission_Control__c newPermissionControl(
  Boolean isInsert,
  Id userId,
  Id regionId,
  Id practiceId,
  Id groupId,
  Id projectId,
  Id resourceId,
  Boolean isCascading
){
  
  pse__Permission_Control__c rec = new pse__Permission_Control__c(
    pse__User__c = userId,
    pse__Resource__c = resourceId,
    pse__Region__c = regionId,
    pse__Practice__c = practiceId,
    pse__Group__c = groupId,
    pse__Project__c = projectId,
    pse__Cascading_Permission__c = isCascading,
    pse__Timecard_Ops_Edit__c = true,
    pse__Timecard_Entry__c = true,
    pse__Staffing__c = true,
    pse__Skills_And_Certifications_View__c = true,
    pse__Skills_And_Certifications_Entry__c = true, 
    pse__Resource_Request_Entry__c = true,
    pse__Invoicing__c = true,
    pse__Forecast_View__c = true,
    pse__Forecast_Edit__c = true,
    pse__Expense_Ops_Edit__c = true,
    pse__Expense_Entry__c = true,
    pse__Billing__c = true
  );
  
  if(isInsert){
    insert rec;
  }
  
  return rec;
}


// ============================================================================
// Region 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Region__c getRegionMaster(){
  List<pse__Region__c> lstRecs = new List<pse__Region__c>([
    SELECT Id
      FROM pse__Region__c
     WHERE pse__Hierarchy_Depth__c = 0
     LIMIT 1
  ]);
  
  if(lstRecs.size() == 1){
    return lstRecs[0];
  } else {
    return newRegionMaster(true);
  }
}


public pse__Region__c newRegionMaster(Boolean isInsert){
  pse__Region__c rec = new pse__Region__c(
    Name = 'Region1'
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}

//==============================
//Create Practice for Test Classes
//Added:SAJHA
//================================

public pse__Practice__c newPracticeMaster(Boolean isInsert){
    pse__Practice__c recPrac = new pse__Practice__c (Name='Practice1');
    if(isInsert){
    insert recPrac ;
  }
  return recPrac ;
}

//==============================
//Create Group for Test Classes
//Added:SAJHA
//================================

public pse__Grp__c newGroupMaster(Boolean isInsert){
    pse__Grp__c recGroup= new pse__Grp__c (Name='Group1');
    if(isInsert){
    insert recGroup;
  }
  return recGroup;
}


// ============================================================================
// Work Calendar 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Work_Calendar__c newWorkCalender(Boolean isInsert){
  pse__Work_Calendar__c rec = new pse__Work_Calendar__c(
    Name ='Test Calender',
    pse__Week_Start_Day__c = 'Sunday',
    pse__Sunday_Hours__c = 0.0,
    pse__Monday_Hours__c = 8.0,
    pse__Tuesday_Hours__c = 8.0,
    pse__Wednesday_Hours__c = 8.0,
    pse__Thursday_Hours__c =8.0,
    pse__Friday_Hours__c = 8.0,
    pse__Saturday_Hours__c = 0.0
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


// *************************************************************************************************
// PSA PROJECT OBJECT METHODS
// *************************************************************************************************


// ============================================================================
// Project 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
//Changes By Sharath:  Added the planned hours parameter: This is set to 1. Due to the new validation rule, planned hours cannot be 0 or null for non-internal projects
public pse__Proj__c newProject(
  Boolean isInsert,
  Id regionId,
  Id practiceId,
  Boolean isBillable, 
  String billingType,
  Id projectMgr,
  Id acctId
){
  
  pse__Proj__c project = new pse__Proj__c(
    Name= 'Test Project',
    pse__Region__c = regionId,
    pse__Practice__c = practiceId, 
    pse__Is_Billable__c  = IsBillable, 
    pse__Closed_for_Time_Entry__c = false,
    pse__Closed_for_Expense_Entry__c = false,
    pse__Stage__c = 'In Progress',
    pse__Is_Active__c = true,
    pse__Allow_Timecards_Without_Assignment__c=true,
    pse__Allow_Expenses_Without_Assignment__c=true,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    /*Start of changes by janantha for changing the product type from customer product to gss product and populating sub type*/
    pse__Project_Type__c = 'GSS Product',
    Project_Sub_Type__c = 'Akamai University',
    /*End of changes by janantha for changing the product type from customer product to gss product and populating sub type*/
    pse__Billing_Type__c = billingType,
    pse__Expense_Budget__c = 1000,
    pse__Start_Date__c = Date.today(),
    pse__End_Date__c = Date.today().addDays(1),
    Contract_Closed__c = 'No',
    pse__Project_Manager__c = projectMgr,
    pse__Account__c = acctId,
    pse__Planned_Hours__c = 1
  );
  if(isInsert){
    insert project;
  }
  return project;
}

// ============================================================================
// Contract
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Merge_Contract_Header__c newContract(
  Boolean isInsert,
  Id acctId,
  String contId,
  String contType,
  Id origContId,  
  Date startDate,
  Date endDate){
  
  Merge_Contract_Header__c contract = new Merge_Contract_Header__c(
    Account_Name__c = acctId,
    Contract_Id__c = contId,
    Contract_Type__c = contType,
    Original_Contract_Id__c = origContId,
    Effective_Start_Date__c = startDate,
    Revision_Effective_Start_Date__c = startDate,
    Effective_End_Date__c = endDate
  );
  if(isInsert){
  System.debug('contract header : '+ contract);
    insert contract;
  }
  return contract;
}

// ============================================================================
// Merge_Contract_Detail__c
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Merge_Contract_Detail__c newContractDetail(
  Boolean isInsert,
  String prod,
  String prodId,
  Id origContId,
  Date startDate,
  Date endDate){
  
  Merge_Contract_Detail__c contractDetail = new Merge_Contract_Detail__c(
    Product__c = prod,
    Product_Id__c = prodId,
    Original_Contract_Id__c = origContId,
    Effective_Start_Date__c = startDate,
    Effective_End_Date__c = endDate
  );
  if(isInsert){
    insert contractDetail;
  }
  return contractDetail;
}

// ============================================================================
// Project Contract
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Project_Contract__c newProjectContract(
  Boolean isInsert,
  Id projId,
  Id contractId,
  Id acctId){
  
  Project_Contract__c projectContract = new Project_Contract__c(
    Project__c = projId,
    Original_Contract_Id__c = contractId,
    Account__c = acctId,
    Valid_Delete__c = true
  );
  System.debug('projectContract : '+ projectContract);
  if(isInsert){
    insert projectContract;
  System.debug('projectContract after Insert: '+ projectContract);
  }
  return projectContract;
}


// ============================================================================
// Project Contract Line Item
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Project_Contract_Line_Item__c newProjectContractLineItem(
  Boolean isInsert,
  Id projId,
  Id contractId,
  Id contractDetailId,
  Id projectContractId){  
  
  Project_Contract_Line_Item__c projectContractLineItem = new Project_Contract_Line_Item__c(
    Project__c = projId,
    Original_Contract_Id__c = contractId,
    Contract_Detail__c = contractDetailId,
    Project_Contract__c = projectContractId,
    Valid_Create__c = true,
    Valid_Delete__c = true
  );
  if(isInsert){
    insert projectContractLineItem;
  }
  return projectContractLineItem;
}


// ============================================================================
// Project Methodology (Project Product)
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Project_Methodology__c newProjectProduct(
  Boolean isInsert,
  Id projId,
  String nm){
  
  pse__Project_Methodology__c projectProduct = new pse__Project_Methodology__c(
    pse__Project__c = projId,
    Name = nm,
    Basic_Implementation_Complete__c = System.today().addDays(5),
    pse__Description__c = 'testmethodlogy',
    pse__Start_Date__c = System.today().addDays(-10),
    pse__End_Date__c = System.today().addDays(10),
    Product__c = 'Aqua'
  );
  if(isInsert){
    insert projectProduct;
  }
  return projectProduct;
}

// ============================================================================
// Milestone 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Milestone__c newMilestone(
  Boolean isInsert,
  Id projectId,
  Decimal milestoneAmount, 
  Date targetDate
){
  
  pse__Milestone__c rec = new pse__Milestone__c(  
    Name= 'Test Milestone',
    pse__Project__c = projectId,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    pse__Milestone_Amount__c = milestoneAmount,
    pse__Target_Date__c = targetDate,
    Billable__c = true
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}

// ============================================================================
// Assignment 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Assignment__c newMilestone(
  Boolean isInsert,
  Id projectId){
  
  pse__Assignment__c rec = new pse__Assignment__c(  
    Name= 'Test Assignment',
    pse__Project__c = projectId,
    CurrencyIsoCode = CURRENCY_DEFAULT);
  if(isInsert){
    insert rec;
  }
  return rec;
}

// ============================================================================
// pse__Budget__c 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Budget__c newBudget(
  Boolean isInsert,
  Id projectId,
  Decimal budgetAmount, 
  Date effDate
){
  
  pse__Budget__c rec = new pse__Budget__c(  
    Name= 'Test Milestone',
    pse__Project__c = projectId,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    pse__Amount__c = budgetAmount,
    pse__Type__c = 'Customer Purchase Order',
    pse__Effective_Date__c = effDate
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}

// ============================================================================
// Assignment and Schedules
// 
// Methods for retrieving and creating records of this type
// ============================================================================

public pse__Schedule__c newSchedule(
  Boolean isInsert, 
  Date startDate,
  Date endDate
){
  
  // build a schedule 
  pse__Schedule__c s = new pse__Schedule__c(
    pse__Start_Date__c = startDate,
    pse__End_Date__c = endDate,
    pse__Monday_Hours__c = 0, 
    pse__Tuesday_Hours__c = 0,
    pse__Wednesday_Hours__c = 0,
    pse__Thursday_Hours__c = 0,
    pse__Friday_Hours__c = 0,
    pse__Saturday_Hours__c = 0,
    pse__Sunday_Hours__c = 0
  );
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule__c newSchedule(
  Boolean isInsert
){
  
  // build a schedule 
  pse__Schedule__c s = newSchedule(false, Date.today(), Date.today());
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule__c newSchedule(
  Boolean isInsert, 
  Date startDate,
  Date endDate,
  String schedulePattern
){
  
  pse__Schedule__c s = newSchedule(false, startDate, endDate);
  
  if(schedulePattern == null || 
     schedulePattern == '' || 
     schedulePattern == SCHEDULE_PATTERN_0 ){
    // do nothing - pattern of 0's
  } else if (schedulePattern == SCHEDULE_PATTERN_8x5){
    s.pse__Monday_Hours__c    = 8;
    s.pse__Tuesday_Hours__c   = 8;
    s.pse__Wednesday_Hours__c = 8;
    s.pse__Thursday_Hours__c  = 8;
    s.pse__Friday_Hours__c    = 8;
  } else if (schedulePattern == SCHEDULE_PATTERN_10x4){
    s.pse__Monday_Hours__c    = 10;
    s.pse__Tuesday_Hours__c   = 10;
    s.pse__Wednesday_Hours__c = 10;
    s.pse__Thursday_Hours__c  = 10;
    s.pse__Friday_Hours__c    = 0;
  } else if (schedulePattern == SCHEDULE_PATTERN_1){
    s.pse__Monday_Hours__c    = 1;
    s.pse__Tuesday_Hours__c   = 1;
    s.pse__Wednesday_Hours__c = 1;
    s.pse__Thursday_Hours__c  = 1;
    s.pse__Friday_Hours__c    = 1;
    s.pse__Saturday_Hours__c    = 1;
    s.pse__Sunday_Hours__c    = 1;
  }
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule__c newSchedule(
  Boolean isInsert, 
  Date startDate,
  Date endDate,
  Decimal mondayHours,
  Decimal tuesdayHours,
  Decimal wednesdayHours,
  Decimal thursdayHours,
  Decimal fridayHours,
  Decimal saturdayHours,
  Decimal sundayHours
){
  
  pse__Schedule__c s = newSchedule(false, startDate, endDate);
  
  s.pse__Monday_Hours__c    = mondayHours;
  s.pse__Tuesday_Hours__c   = tuesdayHours;
  s.pse__Wednesday_Hours__c = wednesdayHours;
  s.pse__Thursday_Hours__c  = thursdayHours;
  s.pse__Friday_Hours__c    = fridayHours;
  s.pse__Saturday_Hours__c  = saturdayHours;
  s.pse__Sunday_Hours__c    = sundayHours;
  
  if(isInsert){
    insert s;
  }
  return s;
}


// get the schedule by Id and return null if not found
public static pse__Schedule__c getSchedule(Id scheduleId){
  List<pse__Schedule__c> lstSchedules = new List<pse__Schedule__c>([
    SELECT Id, 
           pse__Start_Date__c,
           pse__End_Date__c
      FROM pse__Schedule__c
     WHERE id = :scheduleId
  ]);
  
  if(lstSchedules.size() == 1){
    return lstSchedules[0];
  } else {
    return null;
  }
}


// --
// Schedule Exceptions
// --

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert, 
  Id scheduleId,
  Date startDate,
  Date endDate
){
  
  // build a schedule 
  pse__Schedule_Exception__c s = new pse__Schedule_Exception__c(
    pse__Schedule__c = scheduleId,
    pse__Date__c = startDate,
    pse__End_Date__c = endDate,
    pse__Monday_Hours__c = 0, 
    pse__Tuesday_Hours__c = 0,
    pse__Wednesday_Hours__c = 0,
    pse__Thursday_Hours__c = 0,
    pse__Friday_Hours__c = 0,
    pse__Saturday_Hours__c = 0,
    pse__Sunday_Hours__c = 0
  );
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert,
  Id scheduleId
){
  
  // build a schedule 
  pse__Schedule_Exception__c s = newScheduleException(false, scheduleId, Date.today(), Date.today());
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert, 
  Id scheduleId,
  Date startDate,
  Date endDate,
  String schedulePattern
){
  
  pse__Schedule_Exception__c s = newScheduleException(false, scheduleId, startDate, endDate);
  
  if(schedulePattern == null || 
     schedulePattern == '' || 
     schedulePattern == SCHEDULE_PATTERN_0 ){
    // do nothing - pattern of 0's
  } else if (schedulePattern == SCHEDULE_PATTERN_8x5){
    s.pse__Monday_Hours__c    = 8;
    s.pse__Tuesday_Hours__c   = 8;
    s.pse__Wednesday_Hours__c = 8;
    s.pse__Thursday_Hours__c  = 8;
    s.pse__Friday_Hours__c    = 8;
  } else if (schedulePattern == SCHEDULE_PATTERN_10x4){
    s.pse__Monday_Hours__c    = 10;
    s.pse__Tuesday_Hours__c   = 10;
    s.pse__Wednesday_Hours__c = 10;
    s.pse__Thursday_Hours__c  = 10;
    s.pse__Friday_Hours__c    = 0;
  } else if (schedulePattern == SCHEDULE_PATTERN_1){
    s.pse__Monday_Hours__c    = 1;
    s.pse__Tuesday_Hours__c   = 1;
    s.pse__Wednesday_Hours__c = 1;
    s.pse__Thursday_Hours__c  = 1;
    s.pse__Friday_Hours__c    = 1;
    s.pse__Saturday_Hours__c  = 1;
    s.pse__Sunday_Hours__c    = 1;
  }
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert, 
  Id scheduleId,
  Date startDate,
  Date endDate,
  Decimal mondayHours,
  Decimal tuesdayHours,
  Decimal wednesdayHours,
  Decimal thursdayHours,
  Decimal fridayHours,
  Decimal saturdayHours,
  Decimal sundayHours
){
  
  pse__Schedule_Exception__c s = newScheduleException(false, scheduleId, startDate, endDate);
  s.pse__Monday_Hours__c    = mondayHours;
  s.pse__Tuesday_Hours__c   = tuesdayHours;
  s.pse__Wednesday_Hours__c = wednesdayHours;
  s.pse__Thursday_Hours__c  = thursdayHours;
  s.pse__Friday_Hours__c    = fridayHours;
  s.pse__Saturday_Hours__c  = saturdayHours;
  s.pse__Sunday_Hours__c    = sundayHours;
  
  if(isInsert){
    insert s;
  }
  return s;
}


//----


public pse__Assignment__c newAssignment(
  Boolean isInsert, 
  Id projectId, 
  Id resourceId,
  Id scheduleId
){
  
  // create the Assignment using the normal user Resource
  pse__Assignment__c a = new pse__Assignment__c(
    Name                     = 'AssignmentName',
    pse__Project__c          = projectId,
    pse__Schedule__c         = scheduleId,
    pse__Bill_Rate__c        = RESOURCE_BILL_RATE_DEFAULT,
    pse__Is_Billable__c      = true,
    pse__Cost_Rate_Amount__c = RESOURCE_COST_RATE_DEFAULT,
    CurrencyIsoCode          = CURRENCY_DEFAULT,
    pse__Resource__c         = resourceId
  );
  if(isInsert){
    insert a;
  }
  return a;
}

// ============================================================================
// Timecards
// 
// Methods for retrieving and creating records of this type
// ============================================================================

public pse__Timecard_Header__c newTimecardHeader(
  Boolean isInsert, 
  Id resourceId,
  Id projectId,
  Id assignmentId,
  Id milestoneId,
  Date startDate,
  Date endDate,
  Decimal sunHours,
  Decimal monHours,
  Decimal tueHours,
  Decimal wedHours,
  Decimal thrHours,
  Decimal friHours,
  Decimal satHours,
  String sunNotes,
  String monNotes,
  String tueNotes,
  String wedNotes,
  String thrNotes,
  String friNotes,
  String satNotes
  ){
  
  pse__Timecard_Header__c rec = new pse__Timecard_Header__c(
    pse__Resource__c = resourceId,
    pse__Project__c = projectId,
    pse__Assignment__c = assignmentId,
    pse__Milestone__c = milestoneId,
    pse__Start_Date__c = startDate,
    pse__End_Date__c = endDate,
    pse__Sunday_Hours__c = sunHours,
    pse__Monday_Hours__c = monHours,
    pse__Tuesday_Hours__c = tueHours,
    pse__Wednesday_Hours__c = wedHours,
    pse__Thursday_Hours__c = thrHours,
    pse__Friday_Hours__c = friHours,
    pse__Saturday_Hours__c = satHours,
    pse__Sunday_Notes__c = sunNotes,
    pse__Monday_Notes__c = monNotes,
    pse__Tuesday_Notes__c = tueNotes,
    pse__Wednesday_Notes__c = wedNotes,
    pse__Thursday_Notes__c = thrNotes,
    pse__Friday_Notes__c = friNotes,
    pse__Saturday_Notes__c = satNotes
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
  
}


public pse__Timecard_Header__c newTimecardHeader(
  Boolean isInsert, 
  Id resourceId,
  Id projectId,
  Id assignmentId,
  Id milestoneId,
  Date startDate,
  Date endDate,
  Decimal sunHours,
  Decimal monHours,
  Decimal tueHours,
  Decimal wedHours,
  Decimal thrHours,
  Decimal friHours,
  Decimal satHours
){
  
  final String defaultNoteText = 'note';
  
  return newTimecardHeader(
    isInsert,
    resourceId,
    projectId,
    assignmentId,
    milestoneId,
    startDate,
    endDate,
    sunHours,
    monHours,
    tueHours,
    wedHours,
    thrHours,
    friHours,
    satHours,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText
  );
}


public pse__Timecard_Header__c newTimecardHeader(
  Boolean isInsert, 
  Id resourceId,
  Id projectId,
  Id assignmentId,
  Id milestoneId,
  Date startDate,
  Date endDate
){
  
  final Decimal defaultHours = 0.0;
  
  return newTimecardHeader(
    isInsert,
    resourceId,
    projectId,
    assignmentId,
    milestoneId,
    startDate,
    endDate,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours
  );
}

// ============================================================================
// Expense Reports 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Expense_Report__c newExpenseReport(
  Boolean isInsert,
  Id projectId,
  Id resourceId
){
  pse__Expense_Report__c rec = new pse__Expense_Report__c(
    pse__Project__c = projectId,
    pse__Resource__c = resourceId,
    pse__Status__c = EXPENSE_REPORT_STATUS_DRAFT,
    pse__Billable__c = true,
    CurrencyIsoCode = CURRENCY_DEFAULT
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


public pse__Expense__c newExpense(
  Boolean isInsert,
  Id expenseReportId
){
  
  return newExpense(
    isInsert,
    expenseReportId,
    NULL_ID,
    NULL_STRING,
    NULL_DECIMAL
  );
}


public pse__Expense__c newExpense(
  Boolean isInsert,
  Id expenseReportId,
  Id resourceId,
  String expenseType,
  Decimal expenseAmount
){
  
  List<pse__Expense__c> lstRecs = newExpenses(
    isInsert,
    expenseReportId,
    resourceId,
    expenseType,
    expenseAmount,
    1
  );
  return lstRecs[0];
}


public List<pse__Expense__c> newExpenses(
  Boolean isInsert,
  Id expenseReportId,
  Id resourceId,
  String expenseType,
  Decimal expenseAmount,
  Integer recCount
){
  
  if(recCount == null || recCount < 1){
    recCount = 1;
  }
  
  if(expenseType == null || expenseType == ''){
    expenseType = EXPENSE_EXPENSE_TYPE_DEFAULT;
  }
  
  if(expenseAmount == null){
    expenseAmount = EXPENSE_AMOUNT_DEFAULT;
  }
  
  List<pse__Expense__c> lstRecs = new List<pse__Expense__c>();
  for(Integer i = 0 ; i < recCount ; i++){
    pse__Expense__c rec = new pse__Expense__c(
      pse__Expense_Report__c = expenseReportId,
      pse__Resource__c = resourceId,
      //pse__Project__c = projectId,
      pse__Expense_Date__c = Date.today().addDays(i+2),
      pse__type__c = expenseType,
      pse__Description__c = EXPENSE_REPORT_DESC_DRAFT,
      //pse__Status__c = EXPENSE_REPORT_STATUS_DRAFT,
      pse__Billable__c = true,
      pse__Amount__c =  expenseAmount
    );
    lstRecs.add(rec);
  }
  
  if(isInsert){
    insert lstRecs;
  }
  return lstRecs;
}


// ============================================================================
// Billing Events 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Billing_Event__c  newBillingEvent(
  Boolean isInsert,
  ID projectID
){
  pse__Billing_Event__c rec = new pse__Billing_Event__c(
    pse__Project__c = projectID
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}


public  pse__Billing_Event_Item__c newBillingEventItem(
  Boolean isInsert,
  Id billingEvtID,
  String objectID,
  String category,
  ID projectID
){
  pse__Billing_Event_Item__c rec = new pse__Billing_Event_Item__c(
    pse__Billing_Event__c = billingEvtID,
    pse__Object_Id__c =  objectID,
    pse__Category__c = category,
    pse__Project__c = projectID
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}

//creating the method to create timedate records
public List<pse__Time_Date__c> createTimeDates(List<pse__Timecard_Header__c> timecards)
{
    List<pse__Time_Date__c> timeDates = new List<pse__Time_Date__c>();
    pse__Time_Date__c timeDate;
    for (pse__Timecard_Header__c timecard : timecards)
    {
        if(timecard.pse__Monday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c.addDays(1);
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Monday_Hours__c;
            timeDates.add(timeDate);

        }
        if(timecard.pse__Tuesday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c.addDays(2);
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Tuesday_Hours__c;
            timeDates.add(timeDate);

        }
        if(timecard.pse__Wednesday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c.addDays(3);
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Wednesday_Hours__c;
            timeDates.add(timeDate);

        }
        if(timecard.pse__Thursday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c.addDays(4);
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Thursday_Hours__c;
            timeDates.add(timeDate);

        }
        if(timecard.pse__Friday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c.addDays(5);
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Friday_Hours__c;
            timeDates.add(timeDate);

        }
        if(timecard.pse__Saturday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c.addDays(6);
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Saturday_Hours__c;
            timeDates.add(timeDate);

        }
        if(timecard.pse__Sunday_Hours__c != 0)
        {
            timeDate = new pse__Time_Date__c();
            timeDate.pse__timecard__c = timecard.id;
            timeDate.psE__Date__c = timecard.pse__Start_Date__c;
            timeDate.Key__c = timecard.id;
            timeDate.pse__Hours__c = timecard.pse__Sunday_Hours__c;
            timeDates.add(timeDate);

        }

    }
    return timeDates;
}
    
    
//============================================================================
// Project 
// 
// Methods for closing a project with all necessary fiels and values set
//============================================================================
public List<pse__Proj__c> closeProjects(
  Boolean isInsert,
  List<pse__Proj__c> projectsList,
  Id contactId
){
    List<Customer_Contact__c> customerContactsList = new List<Customer_Contact__c>();
    for(pse__Proj__c eachProject : projectsList)
    {
        eachProject.Basic_Implementation_Complete__c = System.today().addDays(5);
        eachProject.Customer_Acceptance_Requested__c = System.today().addDays(3);
        customerContactsList.add(newCustomerContact(false,eachProject.Id,eachProject.pse__Account__c,contactId));   
        eachProject.pse__Stage__c = 'Closed';
        eachProject.Close_Code__c = 'Complete';
    }
    insert customerContactsList;
    if(isInsert)
    {
        update projectsList;
    }
    
    
    return projectsList;
}


    
//============================================================================
//  Customer_Contact__c 
// 
// Methods for creating a new customer contact
//============================================================================
public  Customer_Contact__c newCustomerContact(
  Boolean isInsert,
  Id projectId,
  Id accountId,
  Id contactId
){
  
  Customer_Contact__c customerContact = new Customer_Contact__c(
    Project__c = projectId,
    Account__c = accountId,
    Contact__c = contactId
  );
  if(isInsert){
    insert customerContact;
  }
  return customerContact;
        
}
    
    
   
//============================================================================
//  Investment Work 
// 
// Methods for creating a new Investment Work
//============================================================================

  public Investment_Workbox__c newInvestmentWork(
    Boolean isInsert,
        Id accountId,
        Decimal loeHours,
        Decimal loeMinutes,
        Id requestorId,
        String status,
        boolean security
    )
    {
        Investment_Workbox__c workRequest = new Investment_Workbox__c();
        
        workRequest.Account__c = accountId; 
        workRequest.Work_Type__c = 'Maintenance/Optimization'; 
        workRequest.LOE_Hours__c = loeHours;  
        workRequest.LOE_Minutes__c = loeMinutes;
        workRequest.Products__c  = 'Dynamic Site Accelerator,Kona Site Defender,Fast DNS';
        workRequest.Requestor__c = requestorId;
        workRequest.Justification__c = 'Customer Satisfaction/Retainment';
        workRequest.isProductSelected__c = true;
        workRequest.IW_Modify__c = true;
        workRequest.status__c = status;
        workRequest.Validation_Override__c = false;
        workrequest.Security__c = security;
        workrequest.Product_BU__c = 'Edge Technology Group';
        
        if(isInsert)
        {
            insert workRequest;
        }
        return workRequest;
        
    }
    
//============================================================================
//  Investment Work Admin
// 
// Methods for creating a new Investment Work Admin
//============================================================================

    public Inv_Workbox_Region_Quarter_Mapping__c newInvestmentWorkAdmin(
    Boolean isInsert,
        Id regionId,
        Decimal allcotedQ1,
        Decimal allcotedQ2,
        Decimal allcotedQ3,
        Decimal allcotedQ4,
        String year,
        Id rTypeId
    )
    {
        Inv_Workbox_Region_Quarter_Mapping__c rqMap = new Inv_Workbox_Region_Quarter_Mapping__c();
        
        rqMap.Region__c = regionId;
        // rqMap.Allocated_for_Quarter_1__c = allcotedQ1;
        // rqMap.Allocated_for_Quarter_2__c = allcotedQ2;
        // rqMap.Allocated_for_Quarter_3__c = allcotedQ3;
        // rqMap.Allocated_for_Quarter_4__c = allcotedQ4;
        rqMap.Planned_Hours__c = allcotedQ1;
        rqMap.Product_Platform_Hours__c = allcotedQ2;
        rqMap.UnPlanned_Hours__c = allcotedQ3;
        rqMap.Year__c = year;
        rqMap.RecordtypeId = rTypeId; 
        
        if(isInsert){
            insert rqMap;
        }
        return rqMap;
        
    }
    
//============================================================================
//  GSS User Region
// 
// Methods for creating a new GSS User Region.
//============================================================================

    public Inv_WorkBox_Region_Mapping__c newGSSUserRegion(
    Boolean isInsert,
        Id userId,
        Id geoId,
        Id RegionId,
        Id areaId,
        Id zoneId,
        Id territoryId,
        Id recordtypeId
    )
    {   
        Inv_WorkBox_Region_Mapping__c userRegion = new Inv_WorkBox_Region_Mapping__c();
    
        userRegion.User__c = userId; 
        userRegion.TERR_HIER_1__c = geoId;
        userRegion.TERR_HIER_2__c = RegionId;
        userRegion.TERR_HIER_3__c = areaId;
        userRegion.TERR_HIER_4__c = zoneId;
        userRegion.TERR_HIER_5__c = territoryId;
        userRegion.RecordTypeId = recordtypeId;
        
        if(isInsert)
        {
            insert userRegion;
        }
        return userRegion;
        
    }

    public SC_SupportEmail__c newSCEmailSetup(boolean isInsert)
    {
        SC_SupportEmail__c setItUp = new SC_SupportEmail__c();
        setItUp.Support_Email_AutoGen__c = 'tets@akamaitets.com';
        setItUp.Name = '1';
        if(isInsert)
        {
        insert setItUp;
      }
      return setItUp;
    }

 
    
// *************************************************************************************************
// PSA UTILITY METHODS
// *************************************************************************************************


} // end of class