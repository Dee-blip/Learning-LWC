global class CampaignTriggerClass 
{
    public static boolean populateCampaignGroupFirstRunFlag=true;
    public static boolean updateLatestCampaignOnLeadFirstRunFlag=true;
    public static boolean updateLatestCampaignOnContactFirstRunFlag=true;
    public static boolean createCampaignMemberAuditTrailFirstRunFlag=true;

    public static void  updateLatestCampaignOnLead(Set<Id> campaignIds, Set<id> leadIds)
    {
        if(!updateLatestCampaignOnLeadFirstRunFlag)
            return;

        Set<Id> leadIdsForUpdate = new Set<Id>();
        List<Lead> leadsToUpdateList= new List<Lead>();
        DMLResults dmlres= new DMLResults();
        //MARIT-72
        List<CampaignMember> cmList = new List<CampaignMember>();
        if(leadIds != null && leadIds.size() > 0){
            cmList = [select Id,Lead.Campaign_Description__c,Lead.AKAM_Created_By__c ,Lead.First_Assignment_Date__c, Lead.Latest_Campaign_AKAM_ID__c,Lead.recordTypeId,Lead.status ,Lead.Primary_Campaign__c, Campaign.AKAM_Campaign_ID__c,campaignid,campaign.Campaign_Description_for_ADEs_and_MAEs__c from CampaignMember where LeadId in :leadIds]; 
        } else{
            cmList = [select Id,Lead.Campaign_Description__c,Lead.AKAM_Created_By__c ,Lead.First_Assignment_Date__c, Lead.Latest_Campaign_AKAM_ID__c,Lead.recordTypeId,Lead.status ,Lead.Primary_Campaign__c, Campaign.AKAM_Campaign_ID__c,campaignid,campaign.Campaign_Description_for_ADEs_and_MAEs__c from CampaignMember where LeadId !=null and campaignId in :campaignIds and Lead.Status in ('New', 'In Process') order by CreatedDate DESC];
        }

        for(CampaignMember memb: cmList)
        {
            if(!leadIdsForUpdate.contains(memb.leadid))
            {
                Boolean leadHasChanges=false;
                leadIdsForUpdate.add(memb.leadid);
                Lead l =new Lead(id=memb.LeadId,Latest_Campaign_AKAM_ID__c=memb.Lead.Latest_Campaign_AKAM_ID__c, Primary_Campaign__c=memb.Lead.Primary_Campaign__c, AKAM_Created_By__c=memb.Lead.AKAM_Created_By__c, Campaign_Description__c=memb.Lead.Campaign_Description__c);
                if(l.Latest_Campaign_AKAM_ID__c!=memb.Campaign.AKAM_Campaign_ID__c)
                {
                    l.Latest_Campaign_AKAM_ID__c = memb.Campaign.AKAM_Campaign_ID__c;
                    leadHasChanges=true;
                }
                if(l.Primary_Campaign__c == null)
                {
                    l.Primary_Campaign__c = memb.CampaignId;
                    leadHasChanges=true;
                }
                if(l.First_Assignment_Date__c == null)
                {
                    l.First_Assignment_Date__c = Datetime.now();
                    leadHasChanges=true;
                }
                if(l.Campaign_Description__c == null)
                {
                    l.Campaign_Description__c =memb.Campaign.Campaign_Description_for_ADEs_and_MAEs__c; 
                    leadHasChanges=true;
                }

                if(leadHasChanges)
                {
                    l.Validation_Override__c = true;
                    leadsToUpdateList.add(l);
                }
            }
        }

        if(leadsToUpdateList.size()>0)
        {
            dmlres.dmlUpdate(leadsToUpdateList);
            dmlres.withJobName('UpdateLatestCampaignOnLead').withClassName('CampaignTriggerClass').insertRecordsInErrorLog();
        }

        updateLatestCampaignOnLeadFirstRunFlag=false;

    }

/* 
 * Commenting out this code as part of MARIT-601 because we do not need to update latest campaign on contact
 * This was getting called only when lead was getting converted to a contact and we removed the call 
 * hence, commenting the function
    public static void updateLatestCampaignOnContact(Set<Id> contactIdList)
    {
        if(!updateLatestCampaignOnContactFirstRunFlag)
            return;

        List<Contact> contactUpdateList = new List<Contact>();
        //get the campaign members and account associated with the contact
        for(Contact con:[select id
                ,Latest_Campaign_ID__c
                ,(select id, ContactId,CampaignId from CampaignMembers ORDER BY CreatedDate DESC LIMIT 1 ) 
                from contact where Id in :ContactIdList])
        {
            Id latestCampaignId;
            if(con.CampaignMembers != null && !con.CampaignMembers.isEmpty())
            {
                for(CampaignMember cmpgnMember : con.CampaignMembers)
                    latestCampaignId=cmpgnMember.CampaignId;
            }

            if(latestCampaignId != null && con.Latest_Campaign_ID__c != null && con.Latest_Campaign_ID__c!=latestCampaignId)
            {
                con.Latest_Campaign_ID__c=latestCampaignId;
                con.Validation_Override__c=true;
                contactUpdateList.add(con);
            }
        }
        if(contactUpdateList.size() > 0)
            update contactUpdateList;

        updateLatestCampaignOnContactFirstRunFlag=false;
    }

*/


    public static void createCampaignMemberAuditTrail(List<CampaignMember> campaignMemberList,Set<Id> leadIds, Boolean isDelete,Boolean isInsert)
    {

        if(!createCampaignMemberAuditTrailFirstRunFlag)
            return;

        Map<Id,String> leadIdNameMap=new Map<Id,String>();

        for(Lead l: [select Id,Name from Lead where Id IN :leadIds])
        {
            leadIdNameMap.put(l.id,l.Name);
        }

        List<CampaignMemberAuditTrail__c> camMemberAuditTrailList=new List<CampaignMemberAuditTrail__c>();

        for(CampaignMember camMember: campaignMemberList)
        {

            if(camMember.LeadId !=null)
            {

                String leadName=leadIdNameMap.get(camMember.leadId);

                CampaignMemberAuditTrail__c camMemberAuditTrail=new CampaignMemberAuditTrail__c();
                camMemberAuditTrail.Campaign__c=camMember.CampaignId;
                camMemberAuditTrail.CampaignMemberName__c=leadName;
                camMemberAuditTrail.Associated_Lead__c=camMember.LeadId;

                if(isInsert && !isDelete)
                {
                    camMemberAuditTrail.Description__c=UserInfo.getFirstName()+' '+UserInfo.getLastName()+' has added '+leadName;
                }
                else if(isDelete && !isInsert)
                {
                    camMemberAuditTrail.Description__c=UserInfo.getFirstName()+' '+UserInfo.getLastName()+' has removed '+leadName;
                }

                camMemberAuditTrailList.add(camMemberAuditTrail);
            }
        }

        insert camMemberAuditTrailList;

        createCampaignMemberAuditTrailFirstRunFlag=false;
    }

    public static void populateCampaignGroup(List<Campaign> campaignGroupPopulationList)
    {
        if(!populateCampaignGroupFirstRunFlag)
            return;

        Map<String, String> typeToGroup = GSMSettings.getLargeMap('TacticTypeToTacticGroupMapping');


        for(Campaign cmpgn: campaignGroupPopulationList)
        {
            if(typeToGroup.containsKey(cmpgn.Type))
            {
                cmpgn.Campaign_Group__c=typeToGroup.get(cmpgn.Type);
            }
        }

        populateCampaignGroupFirstRunFlag=false;
    }
}