global class UpdateLeadStatusBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global final string query;
    global List<String> LeadStatusList = new List<String>();
    global Id marketoRecordTypeID;
    global DMLResults results;
    global Boolean triggerDelete=false;

    global UpdateLeadStatusBatchClass()
    {
        String LeadStatuses = GsmUtilClass.getGSMSettingValue('DoNotStampMemberStatusForLeadStatus');
        LeadStatusList = LeadStatuses.split(',');
        String recordType = 'Marketo Lead';
        marketoRecordTypeID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recordType).getRecordTypeId();

        query = 'select Id,CampaignId,ContactId,LeadId,Status,Lead.Associated_Contact__c,Lead.Status from CampaignMember where LeadId != null and Lead.Status not IN :LeadStatusList and Lead.recordTypeId != :marketoRecordTypeID order by CampaignId asc';
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    { 
         results = new DMLResults();
         return Database.getQueryLocator(query); 
     }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Id> CampaignList = new List<Id>();
        List<Id> ContactList = new List<Id>();
        List<CampaignMember> LeadCampaignMembers = new List<CampaignMember>();

        LeadCampaignMembers = (List<CampaignMember>)scope;

        for(CampaignMember singleMember : LeadCampaignMembers)
        {
            CampaignList.add(singleMember.CampaignId);
        }

        for(CampaignMember singleMember : LeadCampaignMembers)
        {
            ContactList.add(singleMember.Lead.Associated_Contact__c);
        }

        List<CampaignMember> leadCMList = new List<CampaignMember>();
        List<CampaignMember> contactCmpgnMemberList = new List<CampaignMember>();
        List<CampaignMember> leadCmpgnMemberList = new List<CampaignMember>();

        //Get all the Campiagn Member Records associated with the Camapign 
        //contactCmpgnMemberList = [Select Id,CampaignId,ContactId,LeadId,Status,Lead.Associated_Contact__c,Lead.Status From CampaignMember Where CampaignId IN :CampaignList and ContactId != null];
        
        contactCmpgnMemberList = [Select Id,CampaignId,ContactId,LeadId,Status,Lead.Associated_Contact__c,Lead.Status From CampaignMember Where CampaignId IN :CampaignList and ContactId IN :ContactList and ContactId != null];

        for(CampaignMember campLead : LeadCampaignMembers)
        {
            for(CampaignMember campContact : contactCmpgnMemberList)
            {

                if(campLead.CampaignId == campContact.CampaignId && campLead.Lead.Associated_Contact__c == campContact.ContactId && campLead.Status != campContact.Status)
                {
                    campLead.Status = campContact.Status;
                    leadCMList.add(campLead);

                }
            }
        }

        System.debug('Update List :'+leadCMList);

        if(leadCMList.size()>0)
        {
            results.dmlUpdate(leadCMList);
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        results.withJobName('Update Lead Campaign Member Status').toAddress(GsmUtilClass.getGSMSettingValue('UpdateLeadStatusBatchClassEmailId')).sendLogMail();
    }
}