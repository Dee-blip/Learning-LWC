/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    24/05/2018     Created this Class - SFDC-2706
    
*/
public without sharing class PartnerMarketingClass {
	public static Boolean approvalFirstRunFlag = true;
	public static Boolean createFundBudgetFirstRunFlag = true;
    public static Boolean populateApproverFieldsFirstRunFlag=true;
	public static Boolean createCampaignFirstRunFlag = true;
    public static Boolean populatePartnerLookupOnPMAsFirstRunFlag=true;
    public static Boolean populatePartnerLookupOnPMPsFirstRunFlag=true;
    //SFDC-4582
    public static Boolean populatePlanFundingApprovedFirstRunFlag=true;
    public static Boolean addPMAChangeErrorFirstRunFlag=true;
    public static Boolean addPMPChangeErrorAndModifyRecFirstRunFlag=true;
    public static Boolean addPMPChangeErrorOnExcludedFirstRunFlag=true;
	public static Boolean addPMPApprovedErrorFirstRunFlag=true;
    public static Boolean copyOverDefaultMDFCurrencyToPartnerMDFObjectsHasRun = false;

	public PartnerMarketingClass() {

	}
	public void captureApprovalFields(List<sObject> pmList){

		for(sObject pm: pmList){
			pm.put('Approved_By__c',UserInfo.getName());
         	pm.put('Approved_Date__c',Datetime.now());
         }
	}

	public void addPMPChangeErrorAndModifyRec(List<Partner_Marketing_Activity__c> pmList,Map<Id,Partner_Marketing_Activity__c> pmaTriggerOldMap){
		if(!addPMPChangeErrorAndModifyRecFirstRunFlag)
			return;
		String error = GsmUtilClass.getGSMSettingValue('PM_PartnerMarketingPlanChangeError');
		//query associated FBA
		List<SFDC_MDF__c> frs = [select id,Partner_Marketing_Activity__c from SFDC_MDF__c where Partner_Marketing_Activity__c in :pmList];
		Map<Id,Id> pmatoFR = new Map<Id,Id>();
		List<Id> campaignToModify = new List<Id>();
		List<Id> pmpFBToModify = new List<Id>();
		List<Campaign> cmpList = new List<Campaign>();
		List<SFDC_Budget__c> fbList = new List<SFDC_Budget__c>();
		for(SFDC_MDF__c fr: frs)
			pmatoFR.put(fr.Partner_Marketing_Activity__c,fr.id);
		List<Budget_Allocation__c> budgetAlloc = [select id, Budget__c, Fund_Request__c, Amount__c from Budget_Allocation__c where Fund_Request__c in :frs AND RecordType.Name!='Cancelled'];
		Map<Id,Id> frToBudgetAlloc = new Map<Id,Id>();
		//SFDC-4582, Modify plan funding approved logic and FB amount calc. to get calculated only from sum of approved/In Progress PMAs when they go through approval and neither on status change of PMA nor on reparenting.
		//Map<Id,Decimal> pmpToActivityCost = new Map<Id,Decimal>();

		Set<String> changedFields = new Set<String>();
		changedFields.addAll(GsmUtilClass.getGSMSettingValue('PartnerMarketing_FieldChangesToModif').split(','));
		for(Budget_Allocation__c budget: budgetAlloc)
			frToBudgetAlloc.put(budget.Fund_Request__c,budget.id);
		for(Partner_Marketing_Activity__c pm: pmList){
			Partner_Marketing_Activity__c pmaRecOld =(Partner_Marketing_Activity__c)pmaTriggerOldMap.get(pm.Id);
			//check if there is an associated FBA then add error else deactivate campaign
			if(!pm.Validation_Override__c && frToBudgetAlloc.containsKey(pmatoFR.get(pm.id)))
				pm.addError(error);
			else if(Util.hasChanges(changedFields,pmaRecOld,pm)){
				campaignToModify.add(pm.Indirect_Campaign__c);
				//SFDC-4582
				//pmpFBToModify.add(pmaRecOld.Partner_Marketing_Plan__c);
				////Reparenting, subtract from old and add to new
				//system.debug(LoggingLevel.ERROR,'pmpToActivityCost inside:: '+pmpToActivityCost);
				////update old PMP FB amount by decreasing
				//if(pmpToActivityCost.containsKey(pmaRecOld.Partner_Marketing_Plan__c))
				//	pmpToActivityCost.put(pmaRecOld.Partner_Marketing_Plan__c,pmpToActivityCost.get(pmaRecOld.Partner_Marketing_Plan__c)-pmaRecOld.Activity_Cost__c);
				//else
				//	pmpToActivityCost.put(pmaRecOld.Partner_Marketing_Plan__c,pmaRecOld.PMP_Plan_Funding_Approved_Formula__c-pmaRecOld.Activity_Cost__c);
				////update new PMP FB amount by increasing if the PMA status is still approved
				////SFDC-4058
				//if(pm.Partner_Marketing_Plan__c!=pmaRecOld.Partner_Marketing_Plan__c && (pm.Activity_Status__c=='Approved' || pm.Activity_Status__c=='In Progress')){
				//	pmpFBToModify.add(pm.Partner_Marketing_Plan__c);
				//	system.debug(LoggingLevel.ERROR,'pm.PMP_Plan_Funding_Approved_Formula__c:: '+pm.PMP_Plan_Funding_Approved_Formula__c);
				//	if(pmpToActivityCost.containsKey(pm.Partner_Marketing_Plan__c))
				//		pmpToActivityCost.put(pm.Partner_Marketing_Plan__c,pmpToActivityCost.get(pm.Partner_Marketing_Plan__c)+pm.Activity_Cost__c);
				//	else
				//		pmpToActivityCost.put(pm.Partner_Marketing_Plan__c,pm.PMP_Plan_Funding_Approved_Formula__c+pm.Activity_Cost__c);

				//}


			}
         }
         //To Do: use cmp id and no SOQL
         //cmpList = [select id,IsActive from Campaign where id in :campaignToModify];
         //fbList  = [select id,Amount__c,Partner_Marketing_Plan__c from SFDC_Budget__c where Partner_Marketing_Plan__c in :pmpFBToModify];
         //fetch all PMAs of PMP to recalculate roll up
         //List<Partner_Marketing_Activity__c> plannedPmaList = [select id,Activity_Status__c,Activity_Cost__c,Partner_Marketing_Plan__c from Partner_Marketing_Activity__c where Activity_Status__c='Approved' and Partner_Marketing_Plan__c in :pmpFBToModify];

         //pmpToActivityCost = calculateTotalActivityCost(plannedPmaList);
         //system.debug(LoggingLevel.ERROR,'pmpToActivityCost outside:: '+pmpToActivityCost);
         for(Id cmpId: campaignToModify){
         		Campaign cmp = new Campaign(Id=cmpId);
         		cmp.IsActive = false;
         		cmpList.add(cmp);
         }
         //for(SFDC_Budget__c fb:fbList)
         //		fb.Amount__c= pmpToActivityCost.get(fb.Partner_Marketing_Plan__c);
         //system.debug(LoggingLevel.ERROR,'fbList:: '+fbList);
         GsmUtilClass.doDatabaseUpdate(cmpList,'PartnerMarketingClass','addPMPChangeErrorAndModifyRec Cmp');
         //GsmUtilClass.doDatabaseUpdate(fbList,'PartnerMarketingClass','addPMPChangeErrorAndModifyRec FB');
         addPMPChangeErrorAndModifyRecFirstRunFlag = false;
	}

//public Map<Id,Decimal> approvePlannedPMAs(List<sObject> pmpList){
//		Map<Id,Decimal> pmpToActivityCost = new Map<Id,Decimal>();
//		if(approvalFirstRunFlag){
//			system.debug(LoggingLevel.ERROR,'in approvePlannedPMAs');
//			//and Approved__c!=true
//			List<Partner_Marketing_Activity__c> pmaList = [select id,Activity_Status__c,Activity_Cost__c,Partner_Marketing_Plan__c from Partner_Marketing_Activity__c where (Activity_Status__c='Planned' OR Activity_Status__c='Excluded') and Partner_Marketing_Plan__c in :pmpList];
//			//allow reparenting for excluded pmas
//			for(Partner_Marketing_Activity__c pmas: pmaList){
//				//pmas.Approved__c = true;
//				if(pmas.Activity_Status__c=='Excluded' && Approval.isLocked(pmas))
//                	Approval.unlock(pmas);
//				else if(pmas.Activity_Status__c=='Planned'){
//					pmas.Activity_Status__c = 'Approved';
//					if(pmas.Activity_Cost__c!=null){
//						if(!pmpToActivityCost.containsKey(pmas.Partner_Marketing_Plan__c))
//							pmpToActivityCost.put(pmas.Partner_Marketing_Plan__c,pmas.Activity_Cost__c);
//						else
//							pmpToActivityCost.put(pmas.Partner_Marketing_Plan__c,pmpToActivityCost.get(pmas.Partner_Marketing_Plan__c)+pmas.Activity_Cost__c);
//						}
//					}
//			}
//			system.debug(LoggingLevel.ERROR,'pmpToActivityCost:: '+pmpToActivityCost);
//			system.debug(LoggingLevel.ERROR,'pmaList:: '+pmaList);
//			GsmUtilClass.doDatabaseUpdate(pmaList,'PartnerMarketingClass','approvePlannedPMAs');
//			approvalFirstRunFlag = false;
//		}
//		return pmpToActivityCost;
//	}

	//SFDC-4058, SFDC-4582
	public void addPMPChangeErrorOnExcluded(List<Partner_Marketing_Activity__c> pmList,Map<Id,Partner_Marketing_Activity__c> pmaTriggerNewMap,String changedField){
		if(!addPMPChangeErrorOnExcludedFirstRunFlag)
			return;
		String activityError = GsmUtilClass.getGSMSettingValue('PM_PartnerMarketingActivityChangeError');
		String pmpError = GsmUtilClass.getGSMSettingValue('PM_PartnerMarketingPMChangeError');
		/*** Begin Rajesh Kumar JIRA # SFDC-5777 **/ // Added condition when FR  is Approved
		List<Partner_Marketing_Activity__c> pmaList = [select id, (select id from Fund_Requests__r where status__c = 'Approved'),  (select id from Opportunities__r),(select id from leads__r)  from Partner_Marketing_Activity__c where id in :pmList];
		/*** End Rajesh Kumar JIRA # SFDC-5777 **/ // Added condition when FR  is Approved
		for(Partner_Marketing_Activity__c pmaObj: pmaList){
			system.debug(LoggingLevel.ERROR,'Fund_Requests__r '+pmaObj.Fund_Requests__r.size()+'Opportunities__r '+pmaobj.Opportunities__r.size()+'leads__r '+pmaobj.leads__r.size() );
			if(pmaObj.Fund_Requests__r.size()!=0 || pmaobj.Opportunities__r.size()!=0 || pmaobj.leads__r.size()!=0){
				String error = '';
				if(changedField.contains('Activity_Status__c'))
					error = activityError;
				if(changedField.contains('Partner_Marketing_Plan__c')){
					if(!String.isEmpty(error))
						error+='</br>';
						// SFDC-5895 - Added By Prabhanjan
						error += String.escapeSingleQuotes(pmpError);
				}
				pmaTriggerNewMap.get(pmaobj.id).addError(error,false);
			}
		}
		addPMPChangeErrorOnExcludedFirstRunFlag = false;
	}

    public static void populatePartnerLookupOnPMAs(List<Partner_Marketing_Activity__c> pmaListForPartnerLookupUpdate)
    {
        if(!populatePartnerLookupOnPMAsFirstRunFlag)
            return;
        Set<Id> pmpIds = new Set<Id>();

        for(Partner_Marketing_Activity__c pma: pmaListForPartnerLookupUpdate)
        {
            pmpIds.add(pma.Partner_Marketing_Plan__c);
        }

        Map<Id,Id> pmpToPartnerAccountId = new Map<Id,Id>();

        for(Partner_Marketing_Plan__c pmp:[select Id,Business_Plan__r.Partner_Account__c from Partner_Marketing_Plan__c where id in :pmpIds])
        {
            pmpToPartnerAccountId.put(pmp.Id, pmp.Business_Plan__r.Partner_Account__c);
        }

        for(Partner_Marketing_Activity__c pma: pmaListForPartnerLookupUpdate)
        {
            pma.Partner__c = pmpToPartnerAccountId.get(pma.Partner_Marketing_Plan__c);
        }

        populatePartnerLookupOnPMAsFirstRunFlag=false;

    }

    public static void populatePartnerLookupOnPMPs(List<Partner_Marketing_Plan__c> pmpListForPartnerLookupUpdate)
    {
        if(!populatePartnerLookupOnPMPsFirstRunFlag)
            return;
        Set<Id> planIds = new Set<Id>();

        for(Partner_Marketing_Plan__c pmp: pmpListForPartnerLookupUpdate)
        {
            planIds.add(pmp.Business_Plan__c);
        }

        Map<Id,Id> planIdToPartnerAccountId= new Map<Id,Id>();

        for(SFDC_Channel_Account_Plan__c plan:[select Id,Partner_Account__c from SFDC_Channel_Account_Plan__c where id in :planIds])
        {
            planIdToPartnerAccountId.put(plan.Id, plan.Partner_Account__c);
        }

        for(Partner_Marketing_Plan__c pmp: pmpListForPartnerLookupUpdate)
        {
            pmp.Partner__c = planIdToPartnerAccountId.get(pmp.Business_Plan__c);
        }

        populatePartnerLookupOnPMPsFirstRunFlag=false;

    }
	public Map<Id,Decimal> approvePlannedPMAs(List<sObject> pmpList){
		Map<Id,Decimal> pmpToActivityCost = new Map<Id,Decimal>();
		if(approvalFirstRunFlag){
			system.debug(LoggingLevel.ERROR,'in approvePlannedPMAs');
			//and Approved__c!=true
			//SFDC-4389
			Boolean ifPmaPrefixToInclude = (GsmUtilClass.getGSMSettingValue('PM_Include_PM_Name_Prefix')=='T'?true:false);
			system.debug(LoggingLevel.ERROR,'ifPmaPrefixToInclude:: '+ifPmaPrefixToInclude);
			String pmaPrefixToInclude = GsmUtilClass.getGSMSettingValue('PM_Name_Prefix');
			system.debug(LoggingLevel.ERROR,'pmaPrefixToInclude:: '+pmaPrefixToInclude);
			//SFDC-4058
			// SFDC-7222
			List<Partner_Marketing_Activity__c> plannedPmaList = [select id,Activity_Status__c,Activity_Cost__c,Partner_Marketing_Plan__c,name,Changed_Fields_after_approval__c,Fields_Changed_After_Approval__c  from Partner_Marketing_Activity__c where (Activity_Status__c='Planned' OR Activity_Status__c='Approved' OR Activity_Status__c='In Progress') and Partner_Marketing_Plan__c in :pmpList];
			List<Partner_Marketing_Activity__c> modifiedPlannedPmaList = new List<Partner_Marketing_Activity__c>();
			for(Partner_Marketing_Activity__c pmas: plannedPmaList){
				//pmas.Approved__c = true;
				//SFDC-4058
				if(pmas.Activity_Status__c=='Planned'){
					pmas.Activity_Status__c = 'Approved';
					//SFDC-4582
					pmas.Validation_Override__c = true;
					//SFDC-4389
					//At the time of PMP Final Approval, change all of the Approved PMA record Names to start with a custom prefix like  "PMA - " unless they already have that name
					system.debug(LoggingLevel.ERROR,'pmas.name:: '+pmas.name);
					if(ifPmaPrefixToInclude && !pmas.name.startsWith(pmaPrefixToInclude))
						pmas.name = pmaPrefixToInclude+' '+pmas.name;
						//SFDC-5580
					if(pmas.name.length() >80)
						pmas.name = pmas.name.substring(0,80);
					modifiedPlannedPmaList.add(pmas);
				}else{
					// SFDC-7222
					// Since PMP got approved and there could be PMAs which were approved in prev approval cycle, need to rest changed fields flag.
					
					// resetChangedFieldsOnPMAAfterReApproval(pmas)
					Boolean isChanged = false;
					if(pmas.Changed_Fields_after_approval__c!=''){
						pmas.Changed_Fields_after_approval__c = '';
						pmas.Fields_Changed_After_Approval__c = false;
						pmas.Validation_Override__c = true;
						isChanged = true;
					}
					system.debug(LoggingLevel.Error,'resetChangedFieldsOnPMAAfterReApproval(pmas):: '+pmas.Changed_Fields_after_approval__c+ ' : '+pmas.Fields_Changed_After_Approval__c);
					if(isChanged)
						modifiedPlannedPmaList.add(pmas);
				}

			}
			pmpToActivityCost = calculateTotalActivityCost(plannedPmaList);
			system.debug(LoggingLevel.ERROR,'pmpToActivityCost:: '+pmpToActivityCost);
			system.debug(LoggingLevel.ERROR,'plannedPmaList:: '+plannedPmaList);
			GsmUtilClass.doDatabaseUpdate(modifiedPlannedPmaList,'PartnerMarketingClass','approvePlannedPMAs');
			approvalFirstRunFlag = false;
		}
		return pmpToActivityCost;
	}

	public Map<Id,Decimal> calculateTotalActivityCost(List<Partner_Marketing_Activity__c> plannedPmaList){
		Map<Id,Decimal> pmpToActivityCost = new Map<Id,Decimal>();
			system.debug(LoggingLevel.ERROR,'in calculateTotalActivityCost');
			//and Approved__c!=true
			for(Partner_Marketing_Activity__c pmas: plannedPmaList){
				if(pmas.Activity_Cost__c!=null){
					if(!pmpToActivityCost.containsKey(pmas.Partner_Marketing_Plan__c))
						pmpToActivityCost.put(pmas.Partner_Marketing_Plan__c,pmas.Activity_Cost__c);
					else
						pmpToActivityCost.put(pmas.Partner_Marketing_Plan__c,pmpToActivityCost.get(pmas.Partner_Marketing_Plan__c)+pmas.Activity_Cost__c);
					}
			}
			system.debug(LoggingLevel.ERROR,'pmpToActivityCost:: '+pmpToActivityCost);
			system.debug(LoggingLevel.ERROR,'plannedPmaList:: '+plannedPmaList);
		return pmpToActivityCost;
	}

	public void createFundBudget(List<sObject> pmpList,Map<Id,Decimal> pmpToActivityCost){
		/**Begin Rajesh Kumar JIRA#  SFDC-6262*/
		 List<String> fundreqCliammonths = GSMSettings.getValue('fundreqclaimdeadline').split('#');
		/**End Rajesh Kumar JIRA#  SFDC-6262*/
		if(!createFundBudgetFirstRunFlag)
			return;
		List<SFDC_Budget__c> fbList = new List<SFDC_Budget__c>();
		//SFDC-6915
		Set<String> parameters = new Set<String>();
		// SFDC-6737
		Map<String,String> pmpFbMapping = GsmUtilClass.getPRMSettingKeyValue('PMPCrFB_');
		//SFDC-6915- added Prevent_Auto_Update_of_Dates__c in query
		for(Schema.FieldSetMember f : SObjectType.SFDC_Budget__c.FieldSets.FB_Override_Date_Setting.getFields()) 
				parameters.add(f.getFieldPath());
		List<SFDC_Budget__c> fbExisting = [select id,Amount__c,Partner_Marketing_Plan__c,Prevent_Auto_Update_of_Dates__c from SFDC_Budget__c where Partner_Marketing_Plan__c in :pmpToActivityCost.keySet()];
		Map<Id,SFDC_Budget__c> pmpToFb = new Map<Id,SFDC_Budget__c>();
		for(SFDC_Budget__c fb: fbExisting){
			pmpToFb.put(fb.Partner_Marketing_Plan__c,fb);
		}
		for(sObject pmp: pmpList){
			Partner_Marketing_Plan__c pmpObj = (Partner_Marketing_Plan__c) pmp;
			SFDC_Budget__c fb = new SFDC_Budget__c();
			if(pmpToFb.containsKey(pmpObj.id))
				 fb = pmpToFb.get(pmpObj.id);

				for(String mapping: pmpFbMapping.keySet()){
					// SFDC-6737
					fb.put(pmpFbMapping.get(mapping),pmp.get(formulateField(mapping,'PMPCrFB_')));
				}
				//Date baseDate = getBaseDate(pmp.Plan_Period__c);
				fb.put('Amount__c',pmpToActivityCost.get(fb.Partner_Marketing_Plan__c));

				Date baseDate = getBaseDate(pmpObj.Plan_Period__c);
				if(baseDate!=null){
					//SFDC-6915
					if(fb.Prevent_Auto_Update_of_Dates__c!=null && fb.Prevent_Auto_Update_of_Dates__c){
						if(!parameters.contains('Start_Earned_Date__c'))
							fb.Start_Earned_Date__c = baseDate;
						if(!parameters.contains('End_Earned_Date__c'))
							fb.End_Earned_Date__c = fb.Start_Earned_Date__c.addMonths(6).addDays(-1);
						if(!parameters.contains('Fund_Request_Deadline__c'))
							fb.Fund_Request_Deadline__c = fb.End_Earned_Date__c.addMonths(Integer.valueOf(fundreqCliammonths[0])); //SFDC-6262
						if(!parameters.contains('Fund_Claim_Deadline__c'))
							fb.Fund_Claim_Deadline__c = fb.Start_Earned_Date__c.addMonths(Integer.valueOf(fundreqCliammonths[1])).addDays(-1); //SFDC-6262
					}else{
						fb.Start_Earned_Date__c = baseDate;
						fb.End_Earned_Date__c = fb.Start_Earned_Date__c.addMonths(6).addDays(-1);
						fb.Fund_Request_Deadline__c = fb.End_Earned_Date__c.addMonths(Integer.valueOf(fundreqCliammonths[0])); //SFDC-6262
						fb.Fund_Claim_Deadline__c = fb.Start_Earned_Date__c.addMonths(Integer.valueOf(fundreqCliammonths[1])).addDays(-1); //SFDC-6262
					}
				}
				fb.Validation_Override__c = true;
				system.debug(LoggingLevel.ERROR,'fb:: '+fb);
				fbList.add(fb);
			}


         //upsert fbList;
        GsmUtilClass.doDatabaseUpsert(fbList,'PartnerMarketingClass','createFundBudget',false);
         //GsmUtilClass.doDatabaseInsert(fbList,'PartnerMarketingClass','createFundBudget',false);
         createFundBudgetFirstRunFlag = false;

	}

	//SFDC-4582
	public void populatePlanFundingApproved(List<Partner_Marketing_Plan__c> pmpList,Map<Id,Decimal> pmpToActivityCost){
		if(!populatePlanFundingApprovedFirstRunFlag)
			return;
		List<Partner_Marketing_Plan__c> pmptoModify = [select id,Plan_Funding_Approved__c from Partner_Marketing_Plan__c where id in :pmpList];
		for(Partner_Marketing_Plan__c pmp: pmptoModify){
			pmp.Plan_Funding_Approved__c = pmpToActivityCost.get(pmp.id);
			pmp.Validation_Override__c = true;
		}
		GsmUtilClass.doDatabaseUpdate(pmptoModify,'PartnerMarketingClass','populatePlanFundingApproved');
		populatePlanFundingApprovedFirstRunFlag = false;
	}

	private Date getBaseDate(String planPeriod){
		if(String.isBlank(planPeriod))
			return null;
		Integer Year = 0;
		List<String> tokenized = new List<String>();
		system.debug(LoggingLevel.ERROR,'planPeriod:: '+planPeriod);
		tokenized=planPeriod.split(' ');
		if(!tokenized.isEmpty()){
			Try{
			 Year = Integer.valueOf(tokenized.get(tokenized.size()-1));
			}Catch(Exception e){
				Error_Log__c el = new Error_Log__c(Name='PartnerMarketingClass', Class__c='getBaseDate', Error_Message__c=e.getMessage());
                System.debug(LoggingLevel.Error, 'error in conversion'+el);
                Insert el;
			}
		}
		if(Year!=0){
			if(tokenized.get(0)=='1H')
				return Date.newInstance(year-1,7,1);
			else if(tokenized.get(0)=='2H')
				return Date.newInstance(year,1,1);
		}

		return null;

	}
	public void createCampaign(List<sObject> pmaList){
		//system.debug(LoggingLevel.ERROR,'pmaList:: '+pmaList);
		if(!createCampaignFirstRunFlag)
			return;
		List<Campaign> cmpList = new List<Campaign>();
		// SFDC-6737
		Map<String,String> pmaCmpMapping = GsmUtilClass.getPRMSettingKeyValue('PMAcrCmp_');
		Map<Id,Partner_Marketing_Activity__c> pmaIdObjMap = new Map<Id,Partner_Marketing_Activity__c>();
		system.debug(LoggingLevel.ERROR,'pmaCmpMapping:: '+pmaCmpMapping);
		for(sObject pma: pmaList){
			Partner_Marketing_Activity__c pmaObj = (Partner_Marketing_Activity__c) pma;
			Campaign cmp = new Campaign();
			//SFDC-4058
			if(pmaObj.Indirect_Campaign__c!=null)
				cmp.id = pmaObj.Indirect_Campaign__c;
			for(String mapping: pmaCmpMapping.keySet()){
				// SFDC-6737
				cmp.put(pmaCmpMapping.get(mapping),pmaObj.get(formulateField(mapping,'PMAcrCmp_')));
			}
			//To DO: Use RecordTypeInfo
			cmp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(GsmUtilClass.getGSMSettingValue('PM_Campaign_RecordType')).getRecordTypeId();//'012G0000001IrMuIAK';
			cmp.Indirect_Campaign__c = true;
			cmp.IsActive = true;
			system.debug(LoggingLevel.ERROR,'pmaObj.Partner_Marketing_Plan__r.Parent_Campaign__c:: '+pmaObj.Partner_Marketing_Plan__r.Parent_Campaign__c);
            cmp.ParentId = GsmUtilClass.getGSMSettingValue('PM_Tactic_Campaign_Parent');//pmaObj.Parent_Campaign__c;
            cmp.Audience_Focus__c= GSMSettings.getValue('PM_Tactic_Audience_Focus');
            //SFDC-6149
            //cmp.Type=GSMSettings.getValue('PM_Tactic_Type');
            cmp.Division__c=GSMSettings.getValue('PM_Tactic_Routing_Division');
            cmp.Product_Line__c=GSMSettings.getValue('PM_Tactic_Product_Line');
            cmp.Campaign_Description_for_ADEs_and_MAEs__c=GSMSettings.getValue('PM_Tactic_Campaign_Description');
            // SFDC-7197
			cmp.Event_Start_Date__c = pmaObj.Activity_Start_Date__c;

			cmpList.add(cmp);
			pmaIdObjMap.put(pmaObj.id,pmaObj);
         }
         //SFDC-4058
         GsmUtilClass.doDatabaseUpsert(cmpList,'PartnerMarketingClass','createCampaign',false);
         //associate created indirect campaign with PMA
         for(Campaign cmpn : cmpList){
         	if(pmaIdObjMap.containsKey(cmpn.Partner_Marketing_Activity__c)){
         		pmaIdObjMap.get(cmpn.Partner_Marketing_Activity__c).Indirect_Campaign__c = cmpn.id;
         		system.debug(LoggingLevel.ERROR,'pmaIdObjMap.get(cmpn.Partner_Marketing_Activity__c).Indirect_Campaign__c:: '+pmaIdObjMap.get(cmpn.Partner_Marketing_Activity__c).Indirect_Campaign__c);
         	}
         }
         createCampaignFirstRunFlag = false;

	}

    public static void populateApproverFieldsAndEnsureSinglePMPPerPlanPeriod(List<Partner_Marketing_Plan__c> submittedPMPs)
    {
        if(!populateApproverFieldsFirstRunFlag)
            return;

        Set<Id> partnerAccountIds = new Set<Id>();

        for(Partner_Marketing_Plan__c pmp: submittedPMPs)
        {
            if(pmp.Partner__c!=null)
                partnerAccountIds.add(pmp.Partner__c);
        }

        Map<Id, Channel_Mapping__c> partnerAccountToMasterCM = new Map<Id, Channel_Mapping__c>();


        for(Channel_Mapping__c cm: [SELECT Id,
                                            MDF_Approver__c,
                                            Partner_Name__c ,
                                            PAE_ID__c
                                            from Channel_Mapping__c
                                            WHERE MDF_Approver__c!= null
                                            AND VAR_Manager_Status__c = 'Active'
                                            AND Master_Channel_Mapping__c=true
                                            AND Active__c=true
                                            AND MDF_Approver__r.IsActive=true
                                            AND Partner_Name__c in :partnerAccountIds
                                            order by CreatedDate asc])
        {
            partnerAccountToMasterCM.put(cm.Partner_Name__c, cm);
        }

        for(Partner_Marketing_Plan__c pmp: submittedPMPs)
        {

            if(partnerAccountToMasterCM.containsKey(pmp.Partner__c))
            {
                pmp.Field_Marketing_Manager__c=partnerAccountToMasterCM.get(pmp.Partner__c).MDF_Approver__c;
                pmp.PAE__c=partnerAccountToMasterCM.get(pmp.Partner__c).PAE_ID__c;
            }
        }

        ensureSinglePMPPerPlanPeriod(submittedPMPs, partnerAccountIds);

        populateApproverFieldsFirstRunFlag=false;

    }

    private static void ensureSinglePMPPerPlanPeriod(List<Partner_Marketing_Plan__c> submittedPMPs, Set<Id> partnerAccountIds)
    {

        Set<String> planPeriods = new Set<String>();

        for(Partner_Marketing_Plan__c pmp : submittedPMPs)
        {
            planPeriods.add(pmp.Plan_Period__c);
        }

        Map<String, Integer> accountIdToPMPCount = new Map<String, Integer>();
        for(AggregateResult ag: [select Partner__c partner, Plan_Period__c planPeriod, count(id) pmpCount from Partner_Marketing_Plan__c where Partner__c in :partnerAccountIds and Plan_Status__c in ('Submitted','Approved') and Active__c=true and Id not in :submittedPMPs and Plan_Period__c in :planPeriods group by Partner__c,Plan_Period__c])
        {
            accountIdToPMPCount.put((String)ag.get('partner')+(String)ag.get('planPeriod'), Integer.valueOf(ag.get('pmpCount')));
        }

        for(Partner_Marketing_Plan__c pmp: submittedPMPs)
        {
            String kee = pmp.Partner__c+pmp.Plan_Period__c;
            if(accountIdToPMPCount.containsKey(kee) && accountIdToPMPCount.get(kee)>0)
            {
                pmp.addError('There is already a marketing plan for this period.');
            }
        }
    }

	public String formulateField(String rawField,String suffix){
		String processedField = rawField.substringAfter(suffix);
		if(processedField.endsWith('_c'))
			processedField=processedField.substringBeforeLast('_c')+'__c';
		return processedField;
	}

	//SFDC-4389
	/*public static void movePMAToInProgress(List<Id> pmaId){
		List<Partner_Marketing_Activity__c> pmaList = new List<Partner_Marketing_Activity__c>();
		for(Id pma: pmaId){
			Partner_Marketing_Activity__c pmaObj = new Partner_Marketing_Activity__c(Id = pma);
	        pmaObj.Activity_Status__c = 'In Progress';
	        //SFDC-4582
	        pmaObj.Validation_Override__c = true;
	        pmaList.add(pmaObj);
    	}
    	update pmaList;
	}*/

    public static void addPMANotInProgressValidation(List<sObject> objList) {

		List<Id> pmaIdsList = new List<Id>();
		String validationMsg = GsmUtilClass.getNAPSettingValue('PartnerLeadPMANotInProgressValidationMsg');
		List<Partner_Marketing_Activity__c> pmaList = new List<Partner_Marketing_Activity__c>();
		Map<Id,String> pmaIdToStatusMap = new Map<Id,String>();

		for (sObject obj:objList) {
			pmaIdsList.add((Id)obj.get('Partner_Marketing_Activity__c'));
		}

		pmaList = [Select id,Activity_Status__c From Partner_Marketing_Activity__c where id IN:pmaIdsList];
		for (Partner_Marketing_Activity__c pma:pmaList) {
			pmaIdToStatusMap.put(pma.id,pma.Activity_Status__c);
		}

		if (pmaIdToStatusMap.size() > 0) {
			for (sObject obj:objList) {
				if (pmaIdToStatusMap.get((Id)obj.get('Partner_Marketing_Activity__c')) != 'In Progress') {
					obj.addError(validationMsg);
				}
			}
		}
	}

	//SFDC-4582
	public static void addPMPApprovedError(List<Partner_Marketing_Plan__c> pmpListForApprovedError){
		if(!addPMPApprovedErrorFirstRunFlag)
			return;
			system.debug(LoggingLevel.ERROR,'addPMPApprovedErrorFirstRunFlag:::: '+addPMPApprovedErrorFirstRunFlag);
		String pmpError = GsmUtilClass.getGSMSettingValue('PM_RecordUnlockError');
		for(Partner_Marketing_Plan__c pmp : pmpListForApprovedError){
			if(!pmp.Validation_Override__c)
				pmp.addError(pmpError);
		}
		addPMPApprovedErrorFirstRunFlag=false;
	}

    //SFDC-5995
	public static void copyOverDefaultMDFCurrencyToPartnerMDFObjects(Map<Id, SObject> mapOfAccountIdVsObject, String sobjectType) {
		if(copyOverDefaultMDFCurrencyToPartnerMDFObjectsHasRun) {
			return;
		}
		copyOverDefaultMDFCurrencyToPartnerMDFObjectsHasRun = true;
		Map<String, String> objectToReferringAccountFieldAPIName = new Map<String, String>{
                        'SFDC_Channel_Account_Plan__c' => 'Partner_Account__c',
                        'Partner_Marketing_Plan__c' => 'Partner__c',
                        'Partner_Marketing_Activity__c' => 'Partner__c'
        };
		Set<Object> soqlSelectSet = new Set<Object>();
		soqlSelectSet.add(objectToReferringAccountFieldAPIName.get(sobjectType));
		soqlSelectSet.add(objectToReferringAccountFieldAPIName.get(sobjectType).replace('__c', '__r')  + '.Default_MDF_Currency__c');
		String queryString = new al.SoqlBuilder()
  						.selectx(soqlSelectSet)
  						.fromx(sobjectType)
  						.wherex(
							  new al.SetCondition().field(objectToReferringAccountFieldAPIName.get(sobjectType)).inx(new List<Id>(mapOfAccountIdVsObject.keySet()))
  						).toSoql(new al.SoqlOptions().wildcardStringsInLikeOperators());

		try {
			List<SObject> listOfRecords = Database.query(queryString);
			for(SObject eachRecord : listOfRecords) {
				SObject referenceRecord = mapOfAccountIdVsObject.get(String.valueOf(eachRecord.get(objectToReferringAccountFieldAPIName.get(sobjectType))));
				if(eachRecord.getSobject(objectToReferringAccountFieldAPIName.get(sobjectType).replace('__c', '__r')).get('Default_MDF_Currency__c') != null) {
					referenceRecord.put('CurrencyISOCode', eachRecord.getSobject(objectToReferringAccountFieldAPIName.get(sobjectType).replace('__c', '__r')).get('Default_MDF_Currency__c'));
				}
				//if null check with Dhinesh
			}
		}
		catch (Exception e) {
			Error_Log__c el = new Error_Log__c(Name='copyOverDefaultMDFCurrencyToPartnerMDFObjectsError', Class__c='PartnerMarketingClass', Error_Message__c = String.valueOf(e));
            insert el;
		}
	}

	// SFDC-7222
	public void populateChangedFieldsAfterApproval(List<Partner_Marketing_Activity__c> changedFieldsAfterApprovalPMA, Map<Id,Partner_Marketing_Activity__c> pmaTriggerOldMap){
		List<Schema.FieldSetMember> fsChangedFields = SObjectType.Partner_Marketing_Activity__c.FieldSets.Fields_to_be_checked_for_change_after_PM.getFields();
		for(Partner_Marketing_Activity__c pmaRecNew: changedFieldsAfterApprovalPMA){
			String changedFields = pmaRecNew.Changed_Fields_after_approval__c;
			for(Schema.FieldSetMember changedField : fsChangedFields){
				
						if((pmaTriggerOldMap.get(pmaRecNew.id).get(changedField.getFieldPath()) != pmaRecNew.get(changedField.getFieldPath()))){
								if(String.isBlank(changedFields)){
									changedFields = changedField.getLabel();
								}
								if(!changedFields.contains(changedField.getLabel()))
										changedFields += ', '+ changedField.getLabel();
							
						}
					}
				if(String.isNotBlank(changedFields)){
					pmaRecNew.Changed_Fields_after_approval__c = changedFields;
					pmaRecNew.Fields_Changed_After_Approval__c = true;
				}
			}
			
	}

}
//Resoved Conflict