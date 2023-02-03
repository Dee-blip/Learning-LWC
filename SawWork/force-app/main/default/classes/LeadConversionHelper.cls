/***
  AGH - Helps Leads
*/

public  without sharing class LeadConversionHelper
{
    public static Boolean hasManualConversionRun = false;
    public static Boolean hasAutoConversionRun = false;
    public static Boolean checkONAAccountsFirstRun = true;
    //MARIT-543
    public static Boolean isLeadConversionAsynModeSet = false;
    public static String akamaiPartnerAdminId = MarketingUtilClass.getMarketingSettingsValue('AkamaiPartnerAdministrator');
    public static String crmIntegrationId = MarketingUtilClass.getMarketingSettingsValue('CRMIntegration');
    public static String mulesoftIntegrationId = MarketingUtilClass.getMarketingSettingsValue('MulesoftIntegration');
    public static String leadAutoConvertRuleLogicExecution = MarketingUtilClass.getMarketingSettingsValue('LeadAutoConvertRuleLogicExecution');//MARIT-1108

    public static List<Lead> populateAutoConvertSource(List<Lead> leadsToBeChecked) 
    {
        Map<Id,Boolean> leadIdToFoundMatchingRule = checkLeadAutoConvertRules(leadsToBeChecked);
        System.Debug(LoggingLevel.Error, 'AGH_D leadIdToFoundMatchingRule'+leadIdToFoundMatchingRule);
        for (Integer i=leadsToBeChecked.size()-1;i>=0;i--) 
        {
            if (leadIdToFoundMatchingRule.containsKey(leadsToBeChecked[i].Id) && leadIdToFoundMatchingRule.get(leadsToBeChecked[i].Id)==true) 
            {
                leadsToBeChecked[i].Auto_Convert_Source__c='Lead Auto Convert rule';
            }
        }
        return leadsToBeChecked;
    }

    public static List<Lead> populateAutoConvertSource(Set<Id> leadIdsWithoutAutoConvertPopulated) 
    {
        List<Lead> leadsToBeChecked = LeadConversionHelper.getPopulatedLeads(leadIdsWithoutAutoConvertPopulated);
        return populateAutoConvertSource(leadsToBeChecked);
    }

    // SFDC-4662 - Added By Prabhanjan
    public static Map<Id,Boolean> checkLeadAutoConvertRules (List<Lead> leadsToBeChecked) 
    {
        Map<Id,Boolean> leadIdToFoundMatchingRule = new Map<Id,Boolean>();
        Map <String, String> jsonObject = (Map <String, String>) JSON.deserialize(
                GSMSettings.getVerbose(Test.isRunningTest()? 'LeadAutoConvertRuleMappingForTestClasses': 'LeadAutoConvertRuleMapping'), Map<String, String>.class);

        List<String> allFields = new List<String>{'Id'};
        allFields.addAll(jsonObject.keySet());

        String queryString = 'Select ' + String.join(allFields, ',') + ' from LeadAutoConvertRule__c';
        List<LeadAutoConvertRule__c> leadAutoConvertRules = Database.query(queryString);
        for (Lead ithLead : leadsToBeChecked) 
        {
            leadIdToFoundMatchingRule.put(ithLead.Id,false);
            for (LeadAutoConvertRule__c leadAutoConvertRule : leadAutoConvertRules) 
            {
                Boolean allChecksPassed=true;
                for (String fieldName : jsonObject.keySet()) 
                {
                    if(ithLead.Associated_Account__c != null)
                    {
                        Object leadFieldValue = ithLead.getSobject('Associated_Account__r').get(jsonObject.get(fieldName));
                        if (leadFieldValue == null || leadAutoConvertRule.get(fieldName) == null) 
                        {
                            allChecksPassed = false;
                            break;
                        }
                        if ((leadFieldValue instanceof String) && (leadAutoConvertRule.get(fieldName) instanceof String)) 
                        {
                            String leadFieldValueToCompare = (String)leadFieldValue;
                            String leadAutoConvertRuleValueToCompare = (String)leadAutoConvertRule.get(fieldName);
                            if (leadFieldValueToCompare.contains(';') && leadAutoConvertRuleValueToCompare.contains(';')) 
                            {
                                Set<String> leadPickListValues = new Set<String>(leadFieldValueToCompare.split(';'));
                                Set<String> leadAutoConvertRulePicklistValue = new Set<String>(leadAutoConvertRuleValueToCompare.split(';'));
                                if (leadPickListValues.equals(leadAutoConvertRulePicklistValue)) 
                                {
                                    leadFieldValue = leadAutoConvertRule.get(fieldName);
                                }
                            }
                        }
                        String fieldVal = leadFieldValue.toString();
                        String lacrVal = leadAutoConvertRule.get(fieldName).toString();
                        if (leadFieldValue != leadAutoConvertRule.get(fieldName) && (fieldName == 'Target_Lists__c' && !(fieldVal.contains(lacrVal))))
                        {
                            allChecksPassed = false;
                            break;
                        }
                    }
                    else
                    {
                        allChecksPassed=false;
                        break;
                    }
                }
                if (allChecksPassed && jsonObject.keySet().size()>0) 
                {
                    leadIdToFoundMatchingRule.put(ithLead.Id,allChecksPassed);
                    break;
                }
            }
        }
        return leadIdToFoundMatchingRule;
    }
    

    public static List<String> getDeficiencies(Lead ithLead, Boolean isManual, Boolean isBeforeUpdateAndInsert)
    {
        List<String> errorList = new List<String>();
        System.debug('Mayank, isManual: '+ isManual);
        System.debug('Mayank, Status: '+ ithLead.Status);
        if(!isBeforeUpdateAndInsert){
         if(!isManual && !(ithLead.Status.equals('New') || ithLead.Status == 'In Process'))
            errorList.add('Lead Status needs to be in New or In Process');

        if(ithLead.Associated_Opportunity__c!=null)
            errorList.add('This Lead is already converted');
        
        if(ithLead.Associated_Account__c==null) //SFDC-4547-12
            errorList.add('You cannot convert a lead without an account');

        //MARIT-617 Commenting below check
        //if(!isLeadConversionAsynModeSet && ithLead.Associated_Contact__c==null)
         //   errorList.add('You cannot convert a lead without an associated contact');

        if(ithLead.RecordTypeId==GSMSettings.getValue('LeadMarketoRecordTypeId'))
            errorList.add('Marketo Leads cannot be converted');

        if(!isManual && ithLead.OwnerId!=GSMSettings.getValue('LeadAutoConvert_QueueId'))
            errorList.add('Only leads belonging to Auto-Convert Queue are auto converted');

        if(ithLead.Associated_Account__c!=null && (ithLead.Associated_Account__r.Type.contains('Akamai Internal') || GSMSettings.contains('AkamaiInternalAccountAkamIds', ithLead.Associated_Account__r.AKAM_Account_ID__c)))
            errorList.add('Leads belonging to Akamai Internal accounts cannot be converted');

        if(!ithLead.Associated_Account__r.Owner.isActive)//SFDC-4547-12
            errorList.add('Opportunities cannot have an account with an inactive owner. On the account page click on the "Reassign Button" to reassign the account an active user.');

        //SFDC-4547-12
        if(!Test.isRunningTest() && ithLead.Associated_Account__c!=null && GsmUtilClass.getGSMSettingValue('ONAPoolOpsIdList').contains(ithLead.Associated_Account__r.OwnerId) &&
            (ithLead.Associated_Account__r.adg_Projected_Account_Owner__c == null))//MARIT-346
            errorList.add('Opportunities without a valid Account Owner or Projected Account Owner Record cannot be converted');

        //MARIT-581,671
        if(isLeadConversionAsynModeSet && !ithLead.Validation_Override__c && ithLead.Associated_Contact__c == null){
            if(ithLead.LastName != null && ithLead.LastName.length() > 50){
                errorList.add('Last Name should not be greater than 50 characters');
            }
            if(ithLead.Department__c != null && ithLead.Department__c.length() > 50){
                errorList.add('Department should not be greater than 50 characters');
            }
            if(ithLead.Title != null && ithLead.Title.length() > 128){
                errorList.add('Title should not be greater than 128 characters');
            }
            if(ithLead.FirstName == null){
                errorList.add('First Name is Mandatory');
            }
            if(ithLead.Title_Local__c != null && ithLead.Title_Local__c.length() > 128){
                errorList.add('Title should not be greater than 128 characters');
            }
            //MARIT-1867 : Validation on phone field on Account object is not allowing marketo lead conversion if phone number has alphabets
            if(ithLead.Phone != null && ithLead.Associated_Account__r.createdDate > date.newInstance(2020, 1, 13)) {
               string phoneRegex = '[0-9+\\-\\(\\)\\s]*';
               Pattern phoneNumberPattern = Pattern.compile(phoneRegex);
               Matcher phoneNumberMatcher = phoneNumberPattern.matcher(ithLead.Phone);	
               if (!phoneNumberMatcher.matches()) {
                   errorList.add('Alphabetic characters not allowed in Phone Number field.');
               }
            }
        }

        if(GSMSettings.contains('WWWLeadGenAKAMAccountIds',ithLead.Associated_Account__r.AKAM_Account_ID__c))//SFDC-4547-12
            errorList.add('Leads belonging to WWW-Lead-Gen Accounts cannot be converted'); 
            } else {
            // throwing error if the lead which is to be converted is owned by a queue rather than auto convert to opportunity
            //PDG 2.0
              String leadOwnerId = ithLead.OwnerId;
              if(!Test.isRunningTest() && isManual && (ithLead.Status == 'Converted' || ithLead.Lead_Qualification_Status__c == 'Converted') && !ithLead.Validation_Override__c && leadOwnerId.startsWith('00G') && ithLead.OwnerId != GSMSettings.getValue('LeadAutoConvert_QueueId')) {
                errorList.add('Cannot convert a Lead that is owned by a Queue.');
            }
            }

        return errorList;
    }


    public static List<Lead> getPopulatedLeads(Set<Id> lIds)
    {
        //SFDC-2492
        return [Select Id
                ,Name
                ,Product_line__c
                ,Status
                ,Disposition__c
                ,Akam_Lead_Id__c
                ,OwnerId
                ,Associated_Contact__c
                ,Auto_Convert_Source__c
                ,Partner_Involved__c
                ,Associated_Opportunity__c
                ,AKAM_Created_By__c
                ,Competitor__c
                ,Business_Pain__c
                ,Authority__c
                ,Need__c
                ,Urgency__c
                ,Money__c
                ,ANUM_Description__c
                ,Associated_Contact__r.AccountId
                ,Associated_Contact__r.Account.Id
                ,Associated_Contact__r.Account.Name
                ,Validation_Override__c
                ,Associated_Contact__r.Account.OwnerId
                ,Associated_Contact__r.Account.Account_Owner_Alias__c
                ,Associated_Contact__r.Account.AKAM_Account_ID__c
                ,Associated_Contact__r.AKAM_Contact_ID__c
                ,Associated_Contact__r.Double_Byte__c
                ,Associated_Contact__r.Account.Type
                ,Associated_Contact__r.Account.Owner.IsActive
                ,Associated_Contact__r.Account.Projected_Sales_Owner__c //SFDC-4547-9
                ,Associated_Account__r.adg_Projected_Account_Owner__c//MARIT-346
                ,Associated_Contact__r.Account.Projected_Sales_Owner__r.isActive //SFDC-4547-9
                ,LeadSource
                ,RecordTypeId
                ,Description
                //,Do_Not_Notify_MAE__c MARIT-320
                ,Project_TimeFrame__c
                ,Associated_Contact__r.MailingCity
                ,Associated_Contact__r.MailingCountry
                ,Associated_Contact__r.MailingState
                ,Associated_Contact__r.Account.Industry__c
                ,Associated_Contact__r.Account.Target_Category__c
                ,Associated_Contact__r.Account.Account_Status__c
                ,Lead_Type__c
                ,Akam_Lead_Score__c
                ,Primary_Campaign__c
                ,Primary_Campaign__r.OwnerId
                ,Primary_Campaign__r.Division__c
                ,Primary_Campaign__r.Auto_Convert_Lead__c 
                ,QFA_Meeting_Date__c // SFDC-3443 @Nagaraj Desai
                ,Primary_Campaign__r.DDOS_Attack__c 
                ,Associated_Contact__r.Account.Customer_Type__c
                ,Convert_to_Opportunity__c //SFDC-4349
                ,Associated_Account__r.Anaplan_Sub_Territory__c
                ,Associated_Account__r.Akamai_Top_50__c
                ,Associated_Account__r.Global_Account_Relationships__c
                ,Associated_Account__r.Target_Category__c
                ,Associated_Account__r.Target_Lists__c
                ,Associated_Account__r.OwnerId //SFDC-4547-12
                ,Associated_Account__r.Projected_Sales_Owner__c//SFDC-4547-12
                ,Associated_Account__r.Projected_Sales_Owner__r.Id//SFDC-4547-12
                ,Associated_Account__r.Projected_Sales_Owner__r.isActive//SFDC-4547-12
                ,adg_Projected_Account_Owner__c//SFDC-4547-12
                ,Associated_Account__r.Type//SFDC-4547-12
                ,Associated_Account__r.AKAM_Account_ID__c//SFDC-4547-12
                ,Associated_Account__r.Owner.isActive//SFDC-4547-12
                ,Reasons_of_Conversion_Fail__c //SFDC-4547-12
                ,Associated_Account__r.Sales_Account__c
                ,Parent_Lead__c
                ,Lead_Qualification_Stage__c //PDG 2.0
                ,Lead_Qualification_Status__c
                ,Buyer_Pain_Points__c
                ,Associated_Account__r.TERR_HIER_1__c
                ,Associated_Account__r.TERR_HIER_2__c
                ,Associated_Account__r.TERR_HIER_3__c
                ,Associated_Account__r.TERR_HIER_4__c
                ,Associated_Account__r.TERR_HIER_5__c
                ,Has_BIS__c
                from Lead where id in :lIds];
    }

    //MARIT-543
    public static List<Lead> getPopulatedAkamaiLeads(Set<Id> lIds){
        //SFDC-2492 , PDG2.0
        System.debug('In getPopulatedAkamaiLeads function');
        String soql = 'Select Id,Phone,Associated_Account__r.createdDate,Name,FirstName,Has_BIS__c,LastName,Title,Title_Local__c,Department__c,Product_line__c,Status,Disposition__c,Akam_Lead_Id__c,OwnerId,Associated_Contact__c,Auto_Convert_Source__c,Partner_Involved__c,Associated_Opportunity__c,AKAM_Created_By__c,Competitor__c,Business_Pain__c,Authority__c,Need__c,Urgency__c,Money__c,ANUM_Description__c,Associated_Account__r.Id,Associated_Account__r.Name,Validation_Override__c,Associated_Account__r.Sales_Account__c,Associated_Account__r.Account_Owner_Alias__c,Associated_Account__r.adg_Projected_Account_Owner__c,LeadSource,RecordTypeId,Description,Project_TimeFrame__c,Associated_Account__r.BillingCity,Associated_Account__r.BillingState,Associated_Account__r.BillingCountry,Associated_Account__r.Industry__c,Associated_Account__r.Account_Status__c,Lead_Type__c,Akam_Lead_Score__c,Primary_Campaign__c,Primary_Campaign__r.OwnerId,Primary_Campaign__r.Division__c,Primary_Campaign__r.Auto_Convert_Lead__c ,QFA_Meeting_Date__c,Primary_Campaign__r.DDOS_Attack__c ,Associated_Account__r.Customer_Type__c,Convert_to_Opportunity__c ,Associated_Account__r.Anaplan_Sub_Territory__c,Associated_Account__r.Akamai_Top_50__c,Associated_Account__r.Global_Account_Relationships__c,Associated_Account__r.Target_Category__c,Associated_Account__r.Target_Lists__c,Associated_Account__r.OwnerId,Associated_Account__r.Projected_Sales_Owner__c,Associated_Account__r.Projected_Sales_Owner__r.Id,Associated_Account__r.Projected_Sales_Owner__r.isActive,adg_Projected_Account_Owner__c,Associated_Account__r.Type,Associated_Account__r.AKAM_Account_ID__c,Associated_Account__r.Owner.isActive,Reasons_of_Conversion_Fail__c,Parent_Lead__c,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Buyer_Pain_Points__c,Associated_Account__r.TERR_HIER_1__c,Associated_Account__r.TERR_HIER_2__c,Associated_Account__r.TERR_HIER_3__c,Associated_Account__r.TERR_HIER_4__c,Associated_Account__r.TERR_HIER_5__c from Lead where id in ';
        soql += MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(lIds));
        return (List<Lead>)MarketingUtilClass.fetchFromDataBase(soql);
    }
    //SFDC-4547-12
    public static void createReassignmentsForONAAccounts(List<Lead> leadList, Boolean isManual)
    {
        if (!checkONAAccountsFirstRun)
            return;

        Map<Id, Id> UserToAccReassignmentRuleMap = new Map<Id, Id>();
        List<Lead> leadListNotPassedTollGates = new List<Lead>();
        System.debug('In createReassignmentsForONAAccounts function');
        for(Lead lead: leadList)
        {
            System.debug('Mayank, lead: '+lead.Associated_Account__c);
            if(lead.Associated_Account__c != null && GsmUtilClass.getGSMSettingValue('ONAPoolOpsIdList').contains(lead.Associated_Account__r.OwnerId)) 
            {
                if(lead.adg_Projected_Account_Owner__c != null)
                {
                    UserToAccReassignmentRuleMap.put(lead.Associated_Account__r.Id, lead.adg_Projected_Account_Owner__c);
                }
            }
        }
        //SFDC-4547-2
        if(UserToAccReassignmentRuleMap.size() > 0) 
        {
            MARIT_AccountTriggerClass.createAccountReassignmentRequest(UserToAccReassignmentRuleMap);
        }

        checkONAAccountsFirstRun = false;
    }

    public static Map<Id, List<String>> runConversion(Set<Id> setOfLeadsToBeConverted , Boolean isManual)
    {
        Map<Id, List<String>> leadIdToErrors = new Map<Id, List<String>>();

        if((isManual && hasManualConversionRun) || (!isManual && hasAutoConversionRun))
            return leadIdToErrors;

        List<Lead> leadsToBeConverted = LeadConversionHelper.getPopulatedLeads(setOfLeadsToBeConverted);
        if(leadAutoConvertRuleLogicExecution.equalsIgnoreCase('TRUE') || Test.isRunningTest()) //MARIT-1108
            leadsToBeConverted = populateAutoConvertSource(leadsToBeConverted);

        Integer total = leadsToBeConverted.size();

          for (integer i=total-1;i>=0;i--) 
          {
              if (leadsToBeConverted[i].Auto_Convert_Source__c!='Lead Auto Convert rule') 
              {
                  List<String> errs = getDeficiencies(leadsToBeConverted[i], isManual, false);
                  System.Debug(Logginglevel.Error, 'AGH_D errs:'+errs.size());
                  if (errs.size() > 0) 
                  {
                      if (!leadIdToErrors.containsKey(leadsToBeConverted[i].Id)) 
                      {
                          leadIdToErrors.put(leadsToBeConverted[i].Id, new List<String>());
                      }
                      leadIdToErrors.get(leadsToBeConverted[i].Id).addAll(errs);
                      leadsToBeConverted.remove(i);
                  }
              }
        }


        System.Debug(Logginglevel.Error, 'AGH_D found leads to convert'+leadsToBeConverted+' ismanual:'+isManual);
        if(leadsToBeConverted.size()>0)
        {
            LeadConversionHelper.createReassignmentsForONAAccounts(leadsToBeConverted, isManual);
            LeadConversionFacade leadConverter = new LeadConversionFacade(leadsToBeConverted);
            LeadConversionResult lcr = leadConverter.convert(isManual);
            //insert lcr.generateErrorLogRecords();
            List<Error_Log__c> errs = lcr.generateErrorLogRecords();

            if(!isManual)
            {
                insert errs;
            }
            else
            {
                for(Error_Log__c el : errs)
                {
                    if(!leadIdToErrors.containsKey(el.RecordId__c))
                    {
                        leadIdToErrors.put(el.RecordId__c, new List<String>());
                    }
                    leadIdToErrors.get(el.RecordId__c).add(el.Error_Message__c);
                }
            }
        }

        //commenting due to MARIT-804
        //if(isManual)
        //    hasManualConversionRun = true;
        //else
        //    hasAutoConversionRun = true;

        return leadIdToErrors;

    }

    //MARIT-543
    public static Map<Id, List<String>> runAsyncLeadConversion(Set<Id> setOfLeadsToBeConverted , Boolean isManual)
    {
        //setOfLeadsToBeConverted - akamai lead ids
        System.debug('In runAsyncLeadConversion function');
        Map<Id, List<String>> leadIdToErrors = new Map<Id, List<String>>();
        
        if((isManual && hasManualConversionRun) || (!isManual && hasAutoConversionRun))
            return leadIdToErrors;
        
        
        List<Lead> leadsToBeConverted = LeadConversionHelper.getPopulatedAkamaiLeads(setOfLeadsToBeConverted); //get akamai leads info
        if(leadAutoConvertRuleLogicExecution.equalsIgnoreCase('TRUE') || Test.isRunningTest()) //MARIT-1108
            leadsToBeConverted = populateAutoConvertSource(leadsToBeConverted); // Is this needed for manual conversion? Validate with team
        
        Integer total = leadsToBeConverted.size();
        LeadConversionHelper.isLeadConversionAsynModeSet = true; //set true since async mode. Used to escape check for null Associated Contact id
        for (integer i=total-1;i>=0;i--) 
        {
            if (leadsToBeConverted[i].Auto_Convert_Source__c!='Lead Auto Convert rule') 
            {
                List<String> errs = getDeficiencies(leadsToBeConverted[i], isManual, false); //check for any oppt creation condition blockers
                System.Debug(Logginglevel.Error, 'AGH_D errs:'+errs);
                if (errs.size() > 0) 
                {
                    if (!leadIdToErrors.containsKey(leadsToBeConverted[i].Id)) 
                    {
                        leadIdToErrors.put(leadsToBeConverted[i].Id, new List<String>());
                    }
                    leadIdToErrors.get(leadsToBeConverted[i].Id).addAll(errs); //add all the errors from getDeficiencies()
                    leadsToBeConverted.remove(i); //remove that akamai lead from oppt creation
                }
            }
        }
        LeadConversionHelper.isLeadConversionAsynModeSet = false;
        System.Debug(Logginglevel.Error, 'AGH_D found leads to convert'+leadsToBeConverted+' ismanual:'+isManual);
        if(leadsToBeConverted.size()>0)
        {
            LeadConversionHelper.createReassignmentsForONAAccounts(leadsToBeConverted, isManual); //Reassign for ONA Accounts (PAO change)
            LeadConversionFacade leadConverter = new LeadConversionFacade(leadsToBeConverted); //create decorated lead and initialize them
            // Create Oppt, Update akamai lead with Oppt details, make it converted and call async job for Contact and OCR creation
            LeadConversionResult lcr = leadConverter.convertAsyncLead(isManual);
            //insert lcr.generateErrorLogRecords();
            List<Error_Log__c> errs = lcr.generateErrorLogRecords();
            
            if(!isManual)
            {
                insert errs;
            }
            else
            {
                for(Error_Log__c el : errs)
                {
                    if(!leadIdToErrors.containsKey(el.RecordId__c))
                    {
                        leadIdToErrors.put(el.RecordId__c, new List<String>());
                    }
                    leadIdToErrors.get(el.RecordId__c).add(el.Error_Message__c);
                }
            }
        }
        
        if(isManual)
            hasManualConversionRun = true;
        else
            hasAutoConversionRun = true;
        
        return leadIdToErrors;
        
    }

}