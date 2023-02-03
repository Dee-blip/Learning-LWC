/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    01/08/2016     Created this Class
    
*/
public class addProductPageControllerMerged{
	public Static Opportunity opp {get;set;}
	public String OpptyJson {get;set;}
	public String OliRecords {get;set;}
	public String oppJson {get;set;}
	public String familyType {get;set;}
	public String oppCat {get;set;}
	public String oppSubCat {get;set;}
	public String lossReason {get;set;}
	public String competitor {get;set;}
	public String carrierApp {get;set;}
	public String aggPartner {get;set;}
	//SFDC-1290
	public String linkToFAQ {get;set;}
	//SFDC-3534
	public String oliForecastCat {get;set;}
	public String oliProductCloseDate {get;set;}
	public Boolean isUserAllowedForSpecialistEdit {get; set;}
	  public String opportunityCategorySubLossReasonMap {get;set;}
	  public List<String> profilePrefixes = new List<String>();
	public List<Product2> product2List  = new List<Product2>();
	public Map<String,String>  nameToIdMap = new Map<String,String>();
	//SFDC-6398
	public String opportunityType {get; set;}
	public Boolean autoRenewCheck {get; set;}
  
	public String zoffStatus {get;set;} //Rajesh #SFDC-7061
	public static List<opportunityLineItemWrapper> originalOLIList; 
  
	public addProductPageControllerMerged(ApexPages.StandardController stdController) {
	  String curPageId = ApexPages.currentPage().getParameters().get('oppId');
	  system.debug('curPageId:'+curPageId);
	  
	  //SFDC-3534
	  //SFDC-5573
	  opp = [select Id
			  ,ForecastCategoryName
			  ,recordtype.name
			  ,Name
			  ,Account.Name
			  ,CurrencyIsoCode
			  ,CloseDate
			  ,MRR__c
			  ,stageName
			  ,Consolidation_Account__c
			  ,Opportunity_Category__c
			  ,New_Churn__c
			  ,Opportunity_Sub_Category__c
			  ,Loss_Reason__c
			  ,Competitor__c
			  ,Strategic_MRR__c
			  ,Carrier_Application__c
			  ,Unacceptable_Terms_and_Conditions__c
			  ,Initial_Out_Clause_Description__c
			  ,Aggregation_Partner__c
			  ,Consolidation_Account__r.Name
			  ,Missing_Product_Feature__c
			  ,Opportunity_Revenue_Impact__c
			  ,Churn_No_Paper__c
			  ,EMRI_Utilization__c
			  ,Updated_By_Emri_Desk_Post_Commit__c
			  ,Loss_Cancellation_Description__c
			  ,EMRI_Comments__c
			  ,Other_Competitor_Name__c
			  ,Opportunity_Type__c //SFDC-6398
			,Zoff_Status__c  //Rajesh :- #SFDC-7061
			,Opt_Out_Reason__c // Rajesh:- #SFDC-7061
			,Auto_Renewal__c
			  ,(select id,Product_Name__c,Average_Renewal_Commit_MRR__c,Projected_Monthly_commit_fees__c,NRR__c, Term__c,unitprice,Average_Renewal_Usage_MRR__c,Projected_Avg_Rev_Non_Commit__c,Net_Non_Commit__c,EMRI__c,Specialist_Touched__c, Specialist_Forecast_Category__c, Specialist_Forecast_Touched__c,Specialist_NRR__c,Specialist_NRR_Touched__c, Specialist_Projected_Monthly_Commit__c, Specialist_Usage_Touched__c, Specialist_Close_Date__c, Specialist_Close_Date_Touched__c, Specialist_Net_MRR__c from opportunitylineitems ORDER BY Product_Name__c) from opportunity where id=:curPageId];
	  getAllForeCastingProducts();
	  List<Profile> profiles = new List<Profile>();
	  List<String> profilePrefixesToQuery = new List<String>();
	  profilePrefixes = EMRIProductSettings.getEmriProductWizardSettingValue('Profile_prefix_for_validations').split(',');
	  //SFDC-1290
	  linkToFAQ = Json.serializePretty(EMRIProductSettings.getEmriProductWizardSettingValue('Faq_Link_To_Aloha'));
	  for(String profilePrefix : profilePrefixes){
		profilePrefixesToQuery.add(profilePrefix+'%');
	  }
	  //profiles = [select id,name from profile where name like 'SA -%' OR name like 'Sales -%'];
	  profiles = [select id,name from profile where name like :profilePrefixesToQuery];
	  organizeProfiles(profiles);
  
		//SFDC-3534
	  String specialistAllowedProfilesFieldEdit = EMRIProductSettings.getEmriProductWizardSettingValue('Specialist_field_edit_allowed_Profiles');
	  isUserAllowedForSpecialistEdit=false;
	  if(specialistAllowedProfilesFieldEdit.contains(UserInfo.getProfileId()))
		isUserAllowedForSpecialistEdit=true;
	  Map<String,String> fieldNameToVar = new Map<String,String>();
	  //SFDC-6398
	  fieldNameToVar.put('Opportunity_Type__c', 'opportunityType');
	  fieldNameToVar.put('Zoff_Status__c', 'zoffStatus');//Rajesh #SFDC-7061
	  fieldNameToVar.put('Auto_Renewal__c', 'autoRenewCheck');
  
	  fieldNameToVar.put('Competitor__c', 'competitor');
	  fieldNameToVar.put('Carrier_Application__c', 'carrierApp');
	  fieldNameToVar.put('Aggregation_Partner__c', 'aggPartner');
	  fieldNameToVar.put('ForecastCategoryName', 'oliForecastCat');
	  getPicklistValues('Opportunity', fieldNameToVar);
	  //oppJson = 
	  system.debug('opp: '+opp);
	  OpptyJson = getOppJson();
	  OliRecords = getOliRecords();
	  getFieldsToHelpText();
	  
	}
  
	public void organizeProfiles(List<Profile> profiles){
	  
	  String profileIDs = '';
	  for(String profilePrefix: profilePrefixes){
	  for(Profile singleProfile: profiles){
		  if(singleProfile.name.startsWith(profilePrefix)){  
			profileIDs += singleProfile.Id+' ,';
		  }
		}
		system.debug('profileIDs: '+profileIDs);
		profileIDs.removeEnd(',');
		nameToIdMap.put(profilePrefix,profileIDs);
	  }
	  system.debug('nameToIdMap in organizeProfiles: '+nameToIdMap);
	}
  
	public String getProfile(){
	  String profile = '';
		  String userProfileId = UserInfo.getProfileId();
		  for(String profileName : nameToIdMap.keySet()){
			if(nameToIdMap.get(profileName).contains(userProfileId))
			  profile = profileName;
		  }
		  return Json.serializePretty(profile);    
	}
  
	public String getOppJson(){
	  opportunityWrapper oppWrapperObj = new opportunityWrapper();
	  oppWrapperObj.oppId = opp.id;
		  oppWrapperObj.opptyLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.id;
	  oppWrapperObj.Name = opp.name;
	  oppWrapperObj.CurrencyCode = opp.CurrencyIsoCode;  
		  Datetime gmt = datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());
	  Integer offset = UserInfo.getTimezone().getOffset(gmt);
	  Datetime local = gmt.addSeconds(offset/1000);
	  //oppWrapperObj.CloseDate = datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());
	  oppWrapperObj.CloseDate = local;
		  oppWrapperObj.MRR = opp.MRR__c;
	  oppWrapperObj.Opportunity_Category = opp.Opportunity_Category__c;
	  oppWrapperObj.New_Churn = opp.New_Churn__c;
	  oppWrapperObj.Opportunity_Sub_Category = opp.Opportunity_Sub_Category__c;
	  oppWrapperObj.Loss_Reason = opp.Loss_Reason__c;
	  oppWrapperObj.Loss_Cancellation_Description = opp.Loss_Cancellation_Description__c;
	  oppWrapperObj.Competitor = opp.Competitor__c;
	  oppWrapperObj.stageName = opp.StageName;
	  oppWrapperObj.Strategic_MRR = opp.Strategic_MRR__c;
	  oppWrapperObj.Carrier_Application = new list<String>{opp.Carrier_Application__c};
	  oppWrapperObj.CarrierApplication = opp.Carrier_Application__c;
	  oppWrapperObj.Unacceptable_Terms_and_Conditions = opp.Unacceptable_Terms_and_Conditions__c;
	  oppWrapperObj.Initial_Out_Clause_Description = opp.Initial_Out_Clause_Description__c;
	  oppWrapperObj.Aggregation_Partner = opp.Aggregation_Partner__c;
	  oppWrapperObj.EMRI_Utilization = opp.EMRI_Utilization__c;
	  oppWrapperObj.Other_Competitor_Name = opp.Other_Competitor_Name__c;
	  //SFDC-1952
	  oppWrapperObj.Updated_By_Emri_Desk_Post_Commit = opp.Updated_By_Emri_Desk_Post_Commit__c;
	  oppWrapperObj.isEMRIDeskUser = GSMUtilClass.isEMRIDeskUser();
	  if(opp.Churn_No_Paper__c)
		oppWrapperObj.Churn_No_Paper = 'Yes';
	  else
		oppWrapperObj.Churn_No_Paper = 'No';
		  if(opp.Consolidation_Account__r.Name!=null)
		  {
		oppWrapperObj.Consolidation_Account_Name = opp.Consolidation_Account__r.Name;
			 oppWrapperObj.Consolidation_Account_Id = opp.Consolidation_Account__c;
  
		  }
	  oppWrapperObj.Missing_Product_Feature = opp.Missing_Product_Feature__c;
	  oppWrapperObj.RecordTypeName = opp.recordtype.name;
	  oppWrapperObj.oppEmri = opp.Opportunity_Revenue_Impact__c;
	  oppWrapperObj.emriComments = opp.EMRI_Comments__c;
	  //SFDC-5573
	  oppWrapperObj.ForecastCat = opp.ForecastCategoryName;
	  oppWrapperObj.AccName = opp.Account.Name;
	  //SFDC-6398
	  oppWrapperObj.Opportunity_Type = opp.Opportunity_Type__c;
  
	  oppWrapperObj.autoRenewCheck = opp.Auto_Renewal__c;
	  
	  oppWrapperObj.Zoff_Status = opp.Zoff_Status__c; //Rajesh  #SFDC-7061
	  oppWrapperObj.Zoff_Opt_Out_Reason = opp.Opt_Out_Reason__c ; //Rajesh #SFDC-7061
	  return Json.serializePretty(oppWrapperObj);
	}
  
	public String getOliRecords(){
	  List<opportunityLineItemWrapper> oliWrapperObjList = new List<opportunityLineItemWrapper>();
	  for(opportunitylineitem oli: opp.opportunitylineitems){
		opportunityLineItemWrapper oliWrapperObj = getSingleOliRecord();
		oliWrapperObj.productName = oli.Product_Name__c;
		oliWrapperObj.lineItemId = oli.id;
		//if(oli.Average_Renewal_Commit_MRR__c!=null)
		  oliWrapperObj.curMonthlyCommitFee = oli.Average_Renewal_Commit_MRR__c;
		if(oli.Projected_Monthly_commit_fees__c!=null)
		  oliWrapperObj.projMonthlyCommitFee = oli.Projected_Monthly_commit_fees__c;//
		if(oli.NRR__c!=null)
		  oliWrapperObj.projOneTimeFee = oli.NRR__c;
		if(oli.unitprice!=null)
		  oliWrapperObj.netMRR = oli.unitprice;
		//if(oli.Average_Renewal_Usage_MRR__c!=null)
		  oliWrapperObj.curAvgRevNonCommit = oli.Average_Renewal_Usage_MRR__c;
		if(oli.Projected_Avg_Rev_Non_Commit__c!=null)
		  oliWrapperObj.projAvgRevNonCommit = oli.Projected_Avg_Rev_Non_Commit__c; //  
		if(oli.Net_Non_Commit__c!=null)
		  oliWrapperObj.netNonCommit = oli.Net_Non_Commit__c;
		if(oli.EMRI__c!=null)
		  oliWrapperObj.emri = oli.EMRI__c;
		if(oli.Term__c!=null){
		  oliWrapperObj.term = oli.Term__c;
		}
		//SFDC-3534
		if(oli.Specialist_Projected_Monthly_Commit__c!=null)
		  oliWrapperObj.spProjMonthlyCommitFee = oli.Specialist_Projected_Monthly_Commit__c;//
		//if(oli.Specialist_Projected_Monthly_Usage__c!=null)
		//  oliWrapperObj.spProjMonthlyUsage = oli.Specialist_Projected_Monthly_Usage__c;//
			  if(oliWrapperObj.spOneTimeFee!=null)
				  oliWrapperObj.spOneTimeFee = oli.Specialist_NRR__c;
			  //SFDC-6257
		if(oli.Specialist_Net_MRR__c != null)
		  oliWrapperObj.spNetMrr = oli.Specialist_Net_MRR__c;
		if(!oli.Specialist_Forecast_Touched__c && !oliwrapperObj.SpForecastTouched)
		  oliWrapperObj.SpForecastCategory = opp.ForecastCategoryName;//
		
		else
		  oliWrapperObj.SpForecastCategory = oli.Specialist_Forecast_Category__c;//
			  if(!oli.Specialist_Close_Date_Touched__c && !oliwrapperObj.SpCloseDateTouched){
				  Datetime gmt = datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());
			Integer offset = UserInfo.getTimezone().getOffset(gmt);
		  Datetime local = gmt.addSeconds(offset/1000);
				  System.debug('LOCAL ' + local);
		  //oliWrapperObj.SpCloseDate = datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());//opp.CloseDate;
		  oliWrapperObj.SpCloseDate = local;
			  }
			  else{
				  Datetime gmt = datetime.newInstance((oli.Specialist_Close_Date__c).year(), (oli.Specialist_Close_Date__c).month(),(oli.Specialist_Close_Date__c).day());
			Integer offset = UserInfo.getTimezone().getOffset(gmt);
		  Datetime local = gmt.addSeconds(offset/1000);
				  System.debug('LOCAL ' + local);
				  //oliWrapperObj.SpCloseDate = datetime.newInstance((oli.Specialist_Close_Date__c).year(), (oli.Specialist_Close_Date__c).month(),(oli.Specialist_Close_Date__c).day());
		  oliWrapperObj.SpCloseDate = local;
			  }
  
		  //oliWrapperObj.SpCloseDate = datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());//opp.CloseDate;
		//else
		  //oliWrapperObj.SpCloseDate = datetime.newInstance((oli.Specialist_Close_Date__c).year(), (oli.Specialist_Close_Date__c).month(),(oli.Specialist_Close_Date__c).day());
		oliwrapperObj.SpCloseDateTouched = oli.Specialist_Close_Date_Touched__c;
		oliwrapperObj.SpCommitTouched = oli.Specialist_Touched__c;
		oliwrapperObj.SpUsageTouched = oli.Specialist_Usage_Touched__c;
		oliwrapperObj.SpForecastTouched = oli.Specialist_Forecast_Touched__c;
			  oliWrapperObj.spOneTimeFeeTouched=oli.Specialist_NRR_Touched__c;
				 
		//if(oli.quantity!=null)
		//  oliWrapperObj.quantity = oli.quantity;
		oliWrapperObjList.add(oliWrapperObj);
	  }
	  system.debug('oliWrapperObjList: '+oliWrapperObjList);
	  return JSON.serializePretty(oliWrapperObjList);
	}
  
	public String getaddedLineItems(){
	  List<opportunityLineItemWrapper> oliWrapperObjList = new List<opportunityLineItemWrapper>();
	  return JSON.serializePretty(oliWrapperObjList);
	}
  
	public String getOliRecord(){
	  return JSON.serializePretty(getSingleOliRecord());  
	}
  
	public opportunityLineItemWrapper getSingleOliRecord(){
	  opportunityLineItemWrapper oliWrapperObj = new opportunityLineItemWrapper();
	  oliWrapperObj = initializeOLIWrapper(oliWrapperObj);
	  return oliWrapperObj;
	}
  
  @RemoteAction
	public static List<AccountWrapper> searchAccount(String accountName){
	  
		System.debug('accountName1' + accountName);
		//Map<String,String> mapOfAccountIdToAccountNames = new Map<String,String>();
		List<AccountWrapper> accountWrapperList;
  
	  if(accountName != null) {
		accountName = String.escapeSingleQuotes(accountName);
	  }
  
		//To DO : Sonali - put limit in query as pagination is not there.
		  List<Account> listOfAccounts = Database.query('Select Id, Name,Owner.Alias,Type,Support_Level__c,BillingCountry,BillingState,Vertical__c, AKAM_Account_ID__c from Account where Name LIKE \'%' + accountName + '%\'');
  
		  if(listOfAccounts.size()>0)
		  {
			//accountsFound = true;
			accountWrapperList = new List<AccountWrapper>();
			for(Account acc : listOfAccounts)
			{
			  AccountWrapper accountWrapperObject = new AccountWrapper()
			  .withId(acc.Id)
			  .withAccountName(acc.Name)
			  .withAccountType(acc.Type)
			  .withAccountOwnerAlias(acc.Owner.Alias)
			  .withSupportLevel(acc.Support_Level__c)
			  .withBillingCountry(acc.BillingCountry)
			  .withBillingState(acc.BillingState)
			  .withVertical(acc.Vertical__c)
			  .withAkamAccountId(acc.AKAM_Account_ID__c);
  
			  accountWrapperList.add(accountWrapperObject);
  
			}
			   // mapOfAccountIdToAccountNames.put(String.valueOf(acc.Id),acc.Name); 
		  }
	  
  
		
	   // system.debug('mapOfAccountIdToAccountNames' + mapOfAccountIdToAccountNames);
	
		return accountWrapperList;
	}
  
	public opportunityLineItemWrapper initializeOLIWrapper(opportunityLineItemWrapper oliWrapperObj){
	  
	  oliWrapperObj.opptyId = opp.Id;
	  oliWrapperObj.quantity = 1;
	  oliWrapperObj.curMonthlyCommitFee = null;
	  oliWrapperObj.projMonthlyCommitFee = 0.00;
	  oliWrapperObj.projOneTimeFee = 0.00;
	  oliWrapperObj.netMRR = 0.00;
	  oliWrapperObj.curAvgRevNonCommit = null;
	  oliWrapperObj.projAvgRevNonCommit = 0.00;
	  oliWrapperObj.netNonCommit = 0.00;
	  oliWrapperObj.emri = 0.00;
	  oliWrapperObj.cancelLink = 'Cancel';
	  oliWrapperObj.deleteLink = 'Delete';
	  oliWrapperObj.undoLink = false;
	  //oliWrapperObj.term = 0.00;
	  oliWrapperObj.nonTraffic = '';
	  //SFDC-3534
	  oliWrapperObj.spProjMonthlyCommitFee = 0.00;
	  //oliWrapperObj.spProjMonthlyUsage = 0.00;
		  oliWrapperObj.spOneTimeFee=0.00;
	  if(opp.ForecastCategoryName!=null)
		  oliWrapperObj.SpForecastCategory = opp.ForecastCategoryName;//
		  //SFDC-5573
	  oliwrapperObj.SpCloseDate = datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());//opp.closeDate
	  oliWrapperObj.SpCommitTouched = false;
	  oliWrapperObj.SpUsageTouched = false;
	  oliWrapperObj.SpForecastTouched = false;
		  oliWrapperObj.spOneTimeFeeTouched=false;
		  oliwrapperObj.SpCloseDateTouched = false;
	  return oliWrapperObj;
	}
  
	public class opportunityWrapper{
	  public Id oppId;
		  public String opptyLink;
	  public String Name;
	  public String CurrencyCode;
	  public Datetime CloseDate;
	  public Decimal MRR;
	  public String Opportunity_Category;
	  public String New_Churn;
	  public String Opportunity_Sub_Category;
	  public String Loss_Reason;
	  public String Loss_Cancellation_Description;
	  public String Competitor;
	  public String stageName;
	  public Decimal Strategic_MRR;
	  public List<String> Carrier_Application;
	  public String CarrierApplication;
	  public String Unacceptable_Terms_and_Conditions;
	  public String Initial_Out_Clause_Description;
	  public String Aggregation_Partner;
	  public String Consolidation_Account_Name;
		  public String Consolidation_Account_Id;
	  public String Missing_Product_Feature;
	  public Decimal emriTotal; 
	  public Decimal oppEmri; 
	  public String RecordTypeName;
	  public Boolean isMrrNegLineItem;
	  public String Churn_No_Paper;
	  public String EMRI_Utilization;
	  public Boolean Updated_By_Emri_Desk_Post_Commit;
	  public Boolean isEMRIDeskUser;
	  public String emriComments;
	  public String Other_Competitor_Name;
	  //SFDC-5573
	  public String AccName;
	  public String ForecastCat;
	  //SFDC-6398
	  public String Opportunity_Type;
	  public Boolean autoRenewCheck;
	  
	  public String Zoff_Status; //Rajesh #SFDC-7061
	  Public String Zoff_Opt_Out_Reason; //Rajesh #SFDC-7061
  
  
	}
  
	private class AccountWrapper {
  
	  private Id accountId;
	  private String accountName;
	  private String accountType;
	  private String ownerAlias;
	  private String supportLevel;
	  private String billingState;
	  private String billingCountry;
	  private String vertical;
	  private String winningDuplicateAccount;
	  private String akamAccountId;
  
  
	  private AccountWrapper withId(Id accountId)
	  {
		this.accountId = accountId;
		return this;
	  }
  
	  private AccountWrapper withAccountName(String accountName)
	  {
		this.accountName = accountName;
		return this;
	  }
	  private AccountWrapper withAccountType(String accountType)
	  {
		this.accountType = accountType;
		return this;
	  }
  
	  private AccountWrapper withAccountOwnerAlias(String ownerAlias)
	  {
		this.ownerAlias = ownerAlias;
		return this;
	  }
  
	  private AccountWrapper withSupportLevel(String supportLevel)
	  {
		this.supportLevel = supportLevel;
		return this;
	  }
  
	  private AccountWrapper withBillingState(String billingState)
	  {
		this.billingState = billingState;
		return this;
	  }
  
	  private AccountWrapper withBillingCountry(String billingCountry)
	  {
		this.billingCountry = billingCountry;
		return this;
	  }
	  private AccountWrapper withVertical(String vertical)
	  {
		this.vertical = vertical;
		return this;
	  }
  
	  private AccountWrapper withAkamAccountId(String akamAccountId)
	  {
		this.akamAccountId = akamAccountId;
		return this;
	  }
  
  
	}
  
  
	public void getPicklistValues(String objName, Map<String,String> fieldNameToVar){
	   List<SelectOption> options = new List<SelectOption>();
	   Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
		 for(String apiName : fieldNameToVar.keySet()){
		 List<Schema.PicklistEntry> ple = fieldMap.get(apiName).getDescribe().getPicklistValues();
		  List<String> picklistValue = new List<String>();
		  if(apiName!='Carrier_Application__c')
			picklistValue.add('--None--');
		 for( Schema.PicklistEntry f : ple)
		 {
		   options.add(new SelectOption(f.getLabel(), f.getValue()));
			picklistValue.add(f.getValue());
		 }       
	   
		 if(fieldNameToVar.get(apiName)=='competitor')
		  competitor = JSON.serializePretty(picklistValue);
		 else if(fieldNameToVar.get(apiName)=='carrierApp')
		  carrierApp = JSON.serializePretty(picklistValue);
		 else if(fieldNameToVar.get(apiName)=='aggPartner')
		  aggPartner = JSON.serializePretty(picklistValue);
				   else if (fieldNameToVar.get(apiName) == 'zoffStatus')
	   zoffStatus = JSON.serializePretty(picklistValue); //Rajesh #SFDC-7061
		  //SFDC-3534
		 else if(fieldNameToVar.get(apiName)=='oliForecastCat')
		  oliForecastCat = JSON.serializePretty(picklistValue);
		  //SFDC-6398
	    //SFDC-6398 SFDC-7597
		else if(fieldNameToVar.get(apiName)=='opportunityType')
		{
		  List<String> picklistValueType = new List<String>();
		  if(opp.Opportunity_Type__c != 'Auto-Renewal' && opp.Opportunity_Type__c != 'Renewal'){
			  picklistValueType.addAll(GSMUtilClass.getGSMSettingValue('AutoRenewalOpportunityType').split(','));
		  }
		  else{
			  picklistValueType.addAll(GSMUtilClass.getGSMSettingValue('ChangedOpportunityTypeForAutoRenewal').split(','));
		  }
		  opportunityType = JSON.serializePretty(picklistValueType);
		}
		  
		 system.debug('oppCat: '+options);
	   }
		 system.debug('oppId: '+Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Opportunity_Category__c').getDescribe().getPicklistValues());
	}
  
  
  public String getDependentPicklist()
	  {
		
		Map<String, List<String>> mapOfCategoryToSubCategory = new Map<String,List<String>>();
		Map<String, List<String>> mapOfSubCategoryToLossReason = new Map<String,List<String>>();
		Map<String, Map<String,List<String>>> mergedMap = new Map<String, Map<String,List<String>>>();
		Map<String,List<String>> tempMap = new Map<String,List<String>>();
		TStringUtils obj = new TStringUtils();
  
		mapOfCategoryToSubCategory = TStringUtils.GetDependentOptions('Opportunity', 'Opportunity_Category__c', 'Opportunity_Sub_Category__c');
		mapOfSubCategoryToLossReason = TStringUtils.GetDependentOptions('Opportunity', 'Opportunity_Sub_Category__c', 'Loss_Reason__c');
		for(String category : mapOfCategoryToSubCategory.keySet())
		{
		  tempMap = new Map<String,List<String>>();
		  if(!String.isBlank(category)){
			for(String subcategory : mapOfCategoryToSubCategory.get(category))
			{
			if(mapOfSubCategoryToLossReason.containsKey(subcategory))
			  {
				tempMap.put(subcategory,mapOfSubCategoryToLossReason.get(subcategory));
			  }
  
			}
			mergedMap.put(category,tempMap);
			tempMap = new Map<String,List<String>>();
			  tempMap.put('--None--', new List<String>{'--None--'});
			mergedMap.put('--None--', tempMap);
		}
  
		}
		return JSON.serialize(mergedMap); 
	  }
  
	// SFDC-3256 - Agility2.0 - Updating Loss reasons, Removing Subcategory, Unacceptable, Initial Out and Missing product feature fields
	//  public String getOpportunityCategoryToSubCategoryMap()
	//  {
	//    Map<String, List<String>> mapOfCategoryToSubCategory = new Map<String,List<String>>();
	  //mapOfCategoryToSubCategory = TStringUtils.GetDependentOptions('Opportunity', 'Opportunity_Category__c', 'Opportunity_Sub_Category__c');
	  //mapOfCategoryToSubCategory.put('--None--',new List<String>{'--None--'});
		
	//    System.debug('mapOfCategoryToSubCategory' + mapOfCategoryToSubCategory);
  
	//    return JSON.serialize(mapOfCategoryToSubCategory);
  
	//  }
  
  
   // SFDC-3256 - Agility2.0 - Added this method for updated dependencies Category -> Loss Reasons
	  /*public String getOpportunitySubCategoryToLossReasonMap()
	  {
		  Map<String, List<String>> mapOfSubCategoryToLossReason = new Map<String,List<String>>();
		  mapOfSubCategoryToLossReason = TStringUtils.GetDependentOptions('Opportunity', 'Opportunity_Sub_Category__c', 'Loss_Reason__c');
		  mapOfSubCategoryToLossReason.put('--None--',new List<String>{'--None--'});
  
		System.debug('mapOfSubCategoryToLossReason' + mapOfSubCategoryToLossReason);
  
		return JSON.serialize(mapOfSubCategoryToLossReason);
  
	  }*/
  
	  public String getOpportunityCategoryToLossReasonMap()
	  {
		  Map<String, List<String>> mapOfCategoryToLossReason = new Map<String,List<String>>();
		  mapOfCategoryToLossReason = TStringUtils.GetDependentOptions('Opportunity', 'Opportunity_Category__c', 'Loss_Reason__c');
		  mapOfCategoryToLossReason.put('--None--',new List<String>{'--None--'});
  
		System.debug('mapOfCategoryToLossReason' + mapOfCategoryToLossReason);
  
		return JSON.serialize(mapOfCategoryToLossReason);
  
	  }
  
	public void getAllForeCastingProducts()
	  {
		  //get all the products for record type 'Forecasting Products'
		  product2List = [Select id, Name, Description, Family, Traffic_Based__c , UOM__c, (select id from pricebookentries where CurrencyIsoCode=:opp.CurrencyIsoCode and IsActive=true) From Product2 WHERE isActive=true and RecordType.Name= 'Forecasting Products' ORDER BY Name];
		  
	  }
  
	  public String getProducts(){
		  return JSON.serializePretty(product2List);
	  }
	  
	  public String getFieldsToTheirEditMode()
	  {
		List<EMRI_Product_Wizard_Settings__mdt> listOfEMRIProductWizardSettings = new List<EMRI_Product_Wizard_Settings__mdt>();
		Map<String,String> mapOfFieldToTemplate = new Map<String,String>();
  
		listOfEMRIProductWizardSettings = EMRIProductSettings.getAll();
  
		if(listOfEMRIProductWizardSettings.size()>0)
		{
		  for(EMRI_Product_Wizard_Settings__mdt settingInstance : listOfEMRIProductWizardSettings)
		  {
			if(settingInstance.Editable__c == true)
			  mapOfFieldToTemplate.put(settingInstance.DeveloperName,'penciltemplate.html');
			else
			  mapOfFieldToTemplate.put(settingInstance.DeveloperName,'locktemplate.html');
  
		  }  
  
		}
  
		return JSON.serializePretty(mapOfFieldToTemplate);
	  }
  
  
	  public String getFieldsToHelpText(){
  
		return JSON.serializePretty(EMRIProductSettings.getFieldToValue('Help_Text_or_Error_Message__c'));
	  }
  
	  public String getFieldsToValue(){
  
		return JSON.serializePretty(EMRIProductSettings.getFieldToValue('value__c'));
	  }
  
	  public class opportunityLineItemWrapper{
	  public String cancelLink;
	  public String deleteLink;
	  public String productName;
	  public Decimal curMonthlyCommitFee;
	  public Decimal projMonthlyCommitFee;
	  public Decimal projOneTimeFee;
	  public Decimal netMRR;
	  public Decimal curAvgRevNonCommit;
	  public Decimal projAvgRevNonCommit;
	  public Decimal netNonCommit;
	  public Decimal emri;
	  public String opptyId;
	  public String lineItemId;
	  public Decimal quantity;
	  public String existing;
	  public Boolean undoLink;
	  public Decimal term;
	  public String nonTraffic;
	  //SFDC-3534
	  public Decimal spProjMonthlyCommitFee;
	  //public Decimal spProjMonthlyUsage;
		  public Decimal spOneTimeFee;
	  public String SpForecastCategory;
	  public DateTime SpCloseDate;
	  public Boolean SpCommitTouched;
	  public Boolean SpUsageTouched;
	  public Boolean SpForecastTouched;
		  public Boolean SpOneTimeFeeTouched;
		  public Boolean SpCloseDateTouched;
		  //SFDC-6257
	  public Decimal spNetMrr;
	  
	  public OpportunityLineItem toOpptyLineItem(){
			  OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opptyId,unitprice=netMRR,Net_Non_Commit__c=netNonCommit,EMRI__c=emri,Quantity__c=0, Term__c=term);
			  //if lineitemid is present then its an update else insert
			  if(!String.isBlank(lineItemId))
				oli.id=lineItemId;
			  else{
				oli.quantity=quantity;
				oli.PricebookEntryId = productName;
				//Product_Name__c=productName,
			  }
			  //update inputable fields only when they are not null
			  System.debug('Non Traffic:'+nonTraffic);
			  oli.Projected_Monthly_commit_fees__c=(projMonthlyCommitFee!=null)?projMonthlyCommitFee:0;
			  oli.Projected_Avg_Rev_Non_Commit__c=(projAvgRevNonCommit!=null)?projAvgRevNonCommit:0;
			  oli.NRR__c=(projOneTimeFee!=null)?projOneTimeFee:0;
			  //SFDC-1952
			  oli.Average_Renewal_Commit_MRR__c = curMonthlyCommitFee;
			  oli.Average_Renewal_Usage_MRR__c = curAvgRevNonCommit;
		   oli.Term__c = term;
		   //SFDC-3534
		   oli.Specialist_Projected_Monthly_Commit__c=(spProjMonthlyCommitFee!=null)?spProjMonthlyCommitFee:0;
		   //oli.Specialist_Projected_Monthly_Usage__c=(spProjMonthlyUsage!=null)?spProjMonthlyUsage:0;
			  oli.Specialist_NRR__c=(spOneTimeFee!=null)?spOneTimeFee:0;
		   oli.Specialist_Forecast_Category__c=SpForecastCategory;
		   //SFDC-5573
		   //oli.Specialist_Close_Date__c = SpCloseDate.date();//Date.newInstance(SpCloseDate.year(), SpCloseDate.month(), SpCloseDate.day());
  
		   
		/*
		   DateTime dt = DateTime.newInstance(SpCloseDate.yearGMT(), SpCloseDate.monthGMT(), SpCloseDate.dayGMT(),12,30,0);
			  System.debug('DateTime Dt:'+dt);
			  if(SpCloseDate.dayGMT()- dt.dayGMT() > 0){
				  System.debug('Difference in time : ');
				  dt = DateTime.newInstance(SpCloseDate.yearGMT(), SpCloseDate.monthGMT(), SpCloseDate.dayGMT(),15,30,0);
			  }
			  System.debug('DateTime now:'+dt);
			  oli.Specialist_Close_Date__c = dt.dateGMT();
		*/

		DateTime OriginalSpCloseDate;
        for(opportunityLineItemWrapper oliOriginal : originalOLIList){
            if(lineItemId == oliOriginal.lineItemId){
                OriginalSpCloseDate=oliOriginal.SpCloseDate;
                break;
            }
        }
  
		if(SpCloseDate != null) {
			if(SpCloseDate != OriginalSpCloseDate){
				Datetime gmt = datetime.newInstance((SpCloseDate).year(), (SpCloseDate).month(),(SpCloseDate).day());
				if(UserInfo.getTimezone().getOffset(gmt) > 0){
					Integer offset = UserInfo.getTimezone().getOffset(gmt);
					Datetime local = gmt.addSeconds(offset/1000);
					oli.Specialist_Close_Date__c = Date.newInstance(local.year(),local.month(),local.day());//Date.newInstance(SpCloseDate.year(), SpCloseDate.month(), SpCloseDate.day());
				  } 
				  else {
					oli.Specialist_Close_Date__c = SpCloseDate.date();
				}
				System.debug(LoggingLevel.ERROR,'oli.Specialist_Close_Date__c in toOpptyLineItem after: '+oli.Specialist_Close_Date__c+' SpCloseDate: '+SpCloseDate);
			}
		}
		else {
				  Opportunity parentOppty = [Select Id,CloseDate from Opportunity where id =: Id.valueOf(opptyId)];
				  Datetime gmt = datetime.newInstance((parentOppty.CloseDate).year(), (parentOppty.CloseDate).month(),(parentOppty.CloseDate).day());
		   if(UserInfo.getTimezone().getOffset(gmt) > 0){
					  Integer offset = UserInfo.getTimezone().getOffset(gmt);
					  Datetime local = gmt.addSeconds(offset/1000);
					  oli.Specialist_Close_Date__c = Date.newInstance(local.year(),local.month(),local.day());
				   } else {
						oli.Specialist_Close_Date__c = parentOppty.CloseDate;
				   }
				 
				 // oli.Specialist_Close_Date__c = parentOppty.CloseDate;//Date.newInstance(SpCloseDate.year(), SpCloseDate.month(), SpCloseDate.day());   
			  }
		   
  
		   if(!oli.Specialist_Touched__c)
			 oli.Specialist_Touched__c=SpCommitTouched;
		   if(!oli.Specialist_Usage_Touched__c)
			 oli.Specialist_Usage_Touched__c=SpUsageTouched;
		   if(!oli.Specialist_Forecast_Touched__c)
			 oli.Specialist_Forecast_Touched__c=SpForecastTouched;
			  if(!oli.Specialist_NRR_Touched__c)
				  oli.Specialist_NRR_Touched__c=SpOneTimeFeeTouched;
			  if(!oli.Specialist_Close_Date_Touched__c)
				oli.Specialist_Close_Date_Touched__c = SpCloseDateTouched;
			  return oli;
		  }
	}
  
  
	@RemoteAction
	public static List<String> save(String oliJson, String oppJson, String originalOliJson){
	  system.debug('oppJson in save: '+oppJson);
	  system.debug('oliJson in save: '+oliJson);
	  system.debug('originalOliJson in save: '+originalOliJson);
	  opportunityWrapper oppWrapperObj = new opportunityWrapper();
		  oppWrapperObj = (opportunityWrapper)JSON.deserialize(oppJson, opportunityWrapper.class);
		  system.debug('opp after deserialization: '+oppWrapperObj);
		  originalOLIList = (List<opportunityLineItemWrapper>)JSON.deserialize(originalOliJson, List<opportunityLineItemWrapper>.class);
		  List<opportunityLineItemWrapper> oliws = (List<opportunityLineItemWrapper>)JSON.deserialize(oliJson, List<opportunityLineItemWrapper>.class);
  
				List<OpportunityLineItem> olisToBeInserted = new List<OpportunityLineItem>();
			  for(opportunityLineItemWrapper oliw : oliws)
			  {
				  olisToBeInserted.add(oliw.toOpptyLineItem());
			  }
			  oliws = (List<opportunityLineItemWrapper>)JSON.deserialize(originalOliJson, List<opportunityLineItemWrapper>.class);
  
			  List<OpportunityLineItem> originalOlis = new List<OpportunityLineItem>();
			  
			  for(opportunityLineItemWrapper oliw : oliws)
			  {
				  originalOlis.add(oliw.toOpptyLineItem());   
			  }
			  
			  system.debug('originalOlis: '+originalOlis.size());
			  system.debug('originalOlis: '+originalOlis);
			  system.debug('olisToBeInserted: '+olisToBeInserted.size());
  
			  Opportunity oppty = updateOppty(oppWrapperObj);
			  
  
			  //delete olis removed in product wizard, apart from contract
			  List<OpportunityLineItem> olisToBeDeleted = new List<OpportunityLineItem>();
			  
			  Boolean oliToBeDeleted = true;
				for(opportunitylineitem oli : originalOlis){
  
				  for(OpportunityLineItem newOli : olisToBeInserted){
					system.debug('newOli: '+newOli.id+' : '+oli.id);
					if(oli.id == newOli.id){
					  oliToBeDeleted = false;
					}
				  }
				  system.debug('oliToBeDeleted: '+oliToBeDeleted);
				  if(oliToBeDeleted)
					olisToBeDeleted.add(oli);
				  oliToBeDeleted = true;
				}
			  system.debug('olisToBeInserted: '+olisToBeInserted);
			  system.debug('olisToBeDeleted: '+olisToBeDeleted);
  
			  List<String> results = new List<String>();
  
			   Set<String> resultSet = new Set<String>();
			   //SFDC-1290 : setting fromProductWizard = true
			   OpportunityTriggerClass.fromProductWizard = true;
			   
				 try
				 {
				   upsert oppty;
				 }
				 catch(DMLException de)
				 {
					system.debug('de: '+de);
					 for(integer i=0;i<de.getNumDml();i++)
					 {  system.debug('de.getDmlMessage(i) for oppty upsert'+de.getDmlMessage(i));
						 resultSet.add(de.getDmlMessage(i));
					 }
				 }
				 if(resultSet.isEmpty()){
				 try
				 {
					 //upsert oppty;
					  if(olisToBeDeleted.size()>0)
						delete olisToBeDeleted;
  
					 
				 }
				 catch(DMLException de)
				 {
					system.debug('de: '+de);
					 for(integer i=0;i<de.getNumDml();i++)
					 {  system.debug('de.getDmlMessage(i) for oppty upsert or oli delete: '+de.getDmlMessage(i));
						 resultSet.add(de.getDmlMessage(i));
					 }
				 }
				 //SFDC-1435
				 //SFDC - 1584 HC - changing the class to ForecastTriggerClass
			 //OpportunityTriggerClass.genericPopulateMRRFirstRunFlag = true;
					 OpportunityForecastingTriggerClass.genericPopulateMRRFirstRunFlag = true;
				 List<Database.upsertResult> uResults = Database.upsert(olisToBeInserted, /*allOrNone*/ false);
				  for(Database.upsertResult result:uResults) {
					//&& result.isCreated()
				 if (!result.isSuccess() ){
				   for (Database.Error error : result.getErrors())
			  {   system.debug('error.getMessage(): '+error.getMessage());
				  // all results will be here
				  resultSet.add(error.getMessage());
			  }
				 }
			   }
			 }
  
			
  
			  
			if(resultSet.size()!=0){
				results.addAll(resultSet);
				System.Debug(LoggingLevel.Error, 'AGH_re'+results);
				//return results;
			  }
			  
		 return results;
			
	  }
  
	  public static Opportunity updateOppty(opportunityWrapper oppWrapperObj){
  
		Opportunity oppty = new opportunity();
		String productWizardEmriUtilizationToggle = EMRIProductSettings.getEmriProductWizardSettingValue('Product_Wizard_Emri_Utilization_Toggle');
		oppWrapperObj = removeNoneFromPicklist(oppWrapperObj);
	  oppty.id = oppWrapperObj.oppId;
	  oppty.name= oppWrapperObj.Name;
	  oppty.CurrencyIsoCode = oppWrapperObj.CurrencyCode;
	  //datetime.newInstance((opp.CloseDate).year(), (opp.CloseDate).month(),(opp.CloseDate).day());
	  //date.newinstance((oppWrapperObj.CloseDate).year(), (oppWrapperObj.CloseDate).month(), (oppWrapperObj.CloseDate).day());
	  //oppty.CloseDate = date.newinstance((oppWrapperObj.CloseDate).year(), (oppWrapperObj.CloseDate).month(), (oppWrapperObj.CloseDate).day());
	  oppty.Opportunity_Category__c = oppWrapperObj.Opportunity_Category;
	  //oppty.Opportunity_Sub_Category__c = oppWrapperObj.Opportunity_Sub_Category;
	  oppty.Loss_Reason__c = oppWrapperObj.Loss_Reason;
	  oppty.Loss_Cancellation_Description__c = oppWrapperObj.Loss_Cancellation_Description;
	  oppty.Other_Competitor_Name__c = oppWrapperObj.Other_Competitor_Name;
	  oppty.Competitor__c = oppWrapperObj.Competitor;
	  oppty.StageName = oppWrapperObj.stageName;
	  oppty.Carrier_Application__c = oppWrapperObj.CarrierApplication;
	  //oppty.Unacceptable_Terms_and_Conditions__c = oppWrapperObj.Unacceptable_Terms_and_Conditions;
	  //oppty.Initial_Out_Clause_Description__c = oppWrapperObj.Initial_Out_Clause_Description;
	  oppty.Aggregation_Partner__c = oppWrapperObj.Aggregation_Partner;
		  if(!String.isBlank(oppWrapperObj.Consolidation_Account_Name) && !String.isBlank(oppWrapperObj.Consolidation_Account_Id))
		oppty.Consolidation_Account__c = Id.ValueOf(oppWrapperObj.Consolidation_Account_Id);
		  else
			  oppty.Consolidation_Account__c  = null;
	  //oppty.Missing_Product_Feature__c = oppWrapperObj.Missing_Product_Feature;
	  if(oppWrapperObj.Churn_No_Paper == 'Yes')
		oppty.Churn_No_Paper__c = true;
	  else
		oppty.Churn_No_Paper__c = false;
  
	  if(oppWrapperObj.emriTotal!=null){
		//SFDC-1449
		//oppty.Opportunity_Revenue_Impact__c = oppWrapperObj.emriTotal.setScale(2, RoundingMode.HALF_UP);
		oppty.EMRI_Pilot_Copy__c = oppty.Opportunity_Revenue_Impact__c;
  
	  }
	  if(productWizardEmriUtilizationToggle.equalsIgnoreCase('True'))
		oppty.EMRI_Utilization__c = oppWrapperObj.EMRI_Utilization;
	  String EMRIOpptyPostCommitStages = EMRIProductSettings.getEmriProductWizardSettingValue('Oppty_Post_Commit_Stages');
	  system.debug(LoggingLevel.ERROR,'EMRIOpptyPostCommitStages:: '+EMRIOpptyPostCommitStages);
	  system.debug(LoggingLevel.ERROR,'oppWrapperObj:: '+oppty.stageName);
	  system.debug(LoggingLevel.ERROR,'oppWrapperObj.isEMRIDeskUser:: '+oppWrapperObj.isEMRIDeskUser);
	  system.debug(LoggingLevel.ERROR,'oppWrapperObj.Updated_By_Emri_Desk_Post_Commit:: '+oppWrapperObj.Updated_By_Emri_Desk_Post_Commit);
	  //SFDC-1952
	  //if EMRI desk user has updated EMRI in Post commit stages
	  if(oppWrapperObj!=null && oppWrapperObj.isEMRIDeskUser && EMRIOpptyPostCommitStages.contains(oppty.stageName) && oppWrapperObj.Updated_By_Emri_Desk_Post_Commit)
		oppty.Updated_By_Emri_Desk_Post_Commit__c = oppWrapperObj.Updated_By_Emri_Desk_Post_Commit;
		system.debug(LoggingLevel.ERROR,'oppty.Updated_By_Emri_Desk_Post_Commit__c:: '+oppty.Updated_By_Emri_Desk_Post_Commit__c);
	  oppty.EMRI_Comments__c = oppWrapperObj.emriComments;
	  //SFDC -6398
	  oppty.Opportunity_Type__c = oppWrapperObj.Opportunity_Type; 
	  oppty.Opt_Out_Reason__c = oppWrapperObj.Zoff_Opt_Out_Reason ;//Rajesh #SFDC-7061
	  oppty.Zoff_Status__c = oppWrapperObj.Zoff_Status ;//Rajesh #SFDC-7061
	  system.debug(LoggingLevel.ERROR, 'oppty: ' + oppty);
	  return oppty;
	  }
  
	  public static opportunityWrapper removeNoneFromPicklist(opportunityWrapper oppWrapperObj){
		if(oppWrapperObj.Opportunity_Sub_Category=='--None--')
		  oppWrapperObj.Opportunity_Sub_Category='';
		if(oppWrapperObj.Opportunity_Category=='--None--')
		  oppWrapperObj.Opportunity_Category = '';
		if(oppWrapperObj.Aggregation_Partner=='--None--')
		  oppWrapperObj.Aggregation_Partner = '';
		if(oppWrapperObj.Competitor=='--None--')
		  oppWrapperObj.Competitor = '';
		if(oppWrapperObj.Loss_Reason=='--None--')
		  oppWrapperObj.Loss_Reason = '';
		//SFDC-6398
		  if(oppWrapperObj.Opportunity_Type=='--None--')
		oppWrapperObj.Opportunity_Type = '';
	  if (oppWrapperObj.Zoff_Status == '--None--')
		oppWrapperObj.Zoff_Status = '';  //Rajesh #SFDC-7061
	  return oppWrapperObj;
	}
  
  }