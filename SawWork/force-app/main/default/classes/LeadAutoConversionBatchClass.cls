global class LeadAutoConversionBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global LeadConversionResult lcr = new LeadConversionResult();
    global Static String leadAutoConvertRuleLogicExecution = MarketingUtilClass.getMarketingSettingsValue('LeadAutoConvertRuleLogicExecution');//MARIT-1108
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        Set<String> leadGenAndInternalAkamAccountIds= new Set<String>();
        leadGenAndInternalAkamAccountIds.addAll(GSMSettings.getValue('WWWLeadGenAKAMAccountIds').split(','));

        leadGenAndInternalAkamAccountIds.addAll(GSMSettings.getValue('AkamaiInternalAccountAkamIds').split(','));

        if(Test.isRunningTest()){
            return Database.getQueryLocator([Select Id
                ,Name
                ,Product_line__c
                ,Status
                ,Disposition__c
                ,Akam_Lead_Id__c
                ,OwnerId
                ,Associated_Contact__c
                ,AKAM_Created_By__c
                ,Authority__c
                ,Need__c
                ,Urgency__c
                ,Money__c
                ,ANUM_Description__c
                ,Partner_Involved__c
                ,Associated_Opportunity__c
                ,Competitor__c
                ,Business_Pain__c
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
                ,LeadSource
                ,RecordTypeId
                ,Description
                //,Do_Not_Notify_MAE__c  MARIT-320
                ,Project_TimeFrame__c
                ,Associated_Contact__r.MailingCity
                ,Associated_Contact__r.MailingCountry
                ,Associated_Contact__r.MailingState
                ,Associated_Contact__r.Account.Industry__c
                ,Associated_Contact__r.Account.Target_Category__c
                ,Lead_Type__c
                ,Akam_Lead_Score__c
                ,Primary_Campaign__c
                ,Primary_Campaign__r.Division__c
                ,Primary_Campaign__r.Auto_Convert_Lead__c
                ,Primary_Campaign__r.OwnerId
                ,QFA_Meeting_Date__c
                ,Associated_Contact__r.Account.Account_Status__c
                ,Primary_Campaign__r.DDOS_Attack__c 
                ,Associated_Contact__r.Account.Customer_Type__c
                ,Convert_to_Opportunity__c
                ,Lead_Qualification_Stage__c   //PDG 2.0
                ,Buyer_Pain_Points__c
                ,Parent_Lead__c
                ,Auto_Convert_Source__c
                ,Associated_Contact__r.Account.Projected_Sales_Owner__c
                ,Associated_Contact__r.Account.Projected_Sales_Owner__r.isActive
                ,Associated_Account__r.TERR_HIER_1__c
                ,Associated_Account__r.TERR_HIER_2__c
                ,Associated_Account__r.TERR_HIER_3__c
                ,Associated_Account__r.TERR_HIER_4__c
                ,Associated_Account__r.TERR_HIER_5__c
                ,Has_BIS__c
                from Lead where (Status='New' or Status='In Process')]);
        }
        
        return Database.getQueryLocator([Select Id
                ,Name
                ,Product_line__c
                ,Status
                ,Disposition__c
                ,Akam_Lead_Id__c
                ,OwnerId
                ,Associated_Contact__c
                ,AKAM_Created_By__c
                ,Authority__c
                ,Need__c
                ,Urgency__c
                ,Money__c
                ,ANUM_Description__c
                ,Partner_Involved__c
                ,Associated_Opportunity__c
                ,Competitor__c
                ,Business_Pain__c
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
                ,LeadSource
                ,RecordTypeId
                ,Description
                //,Do_Not_Notify_MAE__c  MARIT-320
                ,Project_TimeFrame__c
                ,Associated_Contact__r.MailingCity
                ,Associated_Contact__r.MailingCountry
                ,Associated_Contact__r.MailingState
                ,Associated_Contact__r.Account.Industry__c
                ,Associated_Contact__r.Account.Target_Category__c
                ,Lead_Type__c
                ,Akam_Lead_Score__c
                ,Primary_Campaign__c
                ,Primary_Campaign__r.Division__c
                ,Primary_Campaign__r.Auto_Convert_Lead__c
                ,Primary_Campaign__r.OwnerId
                ,QFA_Meeting_Date__c
                ,Associated_Contact__r.Account.Account_Status__c
                ,Primary_Campaign__r.DDOS_Attack__c 
                ,Associated_Contact__r.Account.Customer_Type__c
                ,Convert_to_Opportunity__c
                ,Lead_Qualification_Stage__c   //PDG 2.0
                ,Buyer_Pain_Points__c
                ,Parent_Lead__c
                ,Auto_Convert_Source__c
                ,Associated_Contact__r.Account.Projected_Sales_Owner__c
                ,Associated_Contact__r.Account.Projected_Sales_Owner__r.isActive
                ,Associated_Account__r.TERR_HIER_1__c
                ,Associated_Account__r.TERR_HIER_2__c
                ,Associated_Account__r.TERR_HIER_3__c
                ,Associated_Account__r.TERR_HIER_4__c
                ,Associated_Account__r.TERR_HIER_5__c
                ,Has_BIS__c
                from Lead where (Status='New' or Status='In Process')
                and Associated_Opportunity__c=null 
                and OwnerId= :GSMSettings.getValue('LeadAutoConvert_QueueId') 
                and RecordTypeId!=:GSMSettings.getValue('LeadMarketoRecordTypeId') 
                and Associated_Contact__c!=null 
                and Associated_Contact__r.Account.Account_Owner_Alias__c!='ONA'
                and Associated_Contact__r.Account.Owner.IsActive=true
                and (NOT Associated_Contact__r.Account.Type like 'Akamai Internal')
                and Associated_Contact__r.Account.AKAM_Account_ID__c NOT in :leadGenAndInternalAkamAccountIds]);
                //and Primary_Campaign__r.Auto_Convert_Lead__c=true]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Lead> leadsToBeConverted = (List<Lead>)scope;
        //SFDC-4662 - Added By Prabhanjan
        List<Lead> leadsEligibleForConverison = new List<Lead>();
        //If this flag is true, then we need to re-evaluate Auto_Convert_Source__c logic and needs to check for all three scenarios and any other scneario which is in Lead ASsignment Rules
        if(leadAutoConvertRuleLogicExecution.equalsIgnoreCase('TRUE') || Test.isRunningTest()) //MARIT-1108
        {
            leadsToBeConverted= LeadConversionHelper.populateAutoConvertSource(leadsToBeConverted);

            for (Lead ithLead : leadsToBeConverted) {
                if (ithLead.Primary_Campaign__r.Auto_Convert_Lead__c 
                || ithLead.Convert_to_Opportunity__c 
                || ithLead.Auto_Convert_Source__c=='Lead Auto Convert rule')
                {
                    leadsEligibleForConverison.add(ithLead);
                }
            }
        } else {
            leadsEligibleForConverison.addAll(leadsToBeConverted);
        }

        if (leadsEligibleForConverison.size()>0) {
            LeadTriggerClass.setConverted(leadsEligibleForConverison);
            LeadConversionFacade leadConverter = new LeadConversionFacade(leadsEligibleForConverison);
            lcr.addAll(leadConverter.convert(false));
        }

    }

    global void finish(Database.BatchableContext BC)
    {
        Util.updateCronRunWithResult('Lead Auto-Conversion To Opportunity', lcr.generateTextLog());
    }
}