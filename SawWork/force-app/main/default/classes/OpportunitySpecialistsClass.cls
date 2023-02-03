public class OpportunitySpecialistsClass{

    private static Boolean refreshFirstRunFlag = true;
    private static final String teamMemberRole=GSMSettings.getValue('Opportunity_SalesOverlay_TeamRole');
    private static final String teamMemberAccess = GSMSettings.getValue('Opportunity_SalesOverlay_OTMAccess');

    public static void refreshOTMsAndShares(List<OpportunitySpecialistRelation> newSpecialists, List<OpportunitySpecialistRelation> oldSpecialists)
    {
        if(!refreshFirstRunFlag)
            return;

        Map<Id, Id> specialistCompTeamToUserId = new Map<Id, Id>();
        Set<Id> specialistCompTeamIds = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        List<OpportunityTeamMember> newSpecialistOTMs = new List<OpportunityTeamMember>();


        for(OpportunitySpecialistRelation osr : newSpecialists)
        {
            if(!osr.isUser)
            {
                specialistCompTeamIds.add(osr.userOrRelatedId);
            }
            else
            {
                newSpecialistOTMs.add(createOTMRecord(osr.opportunityId, osr.userOrRelatedId));
            }
        }

        for(OpportunitySpecialistRelation osr : oldSpecialists)
        {
            if(!osr.isUser)
            {
                specialistCompTeamIds.add(osr.userOrRelatedId);
            }
            opportunityIdSet.add(osr.OpportunityId);
        }

        if(specialistCompTeamIds.size()>0)
        {
            for(Specialist_Comp_Team__c sct : [select Id, Product_Specialist__c from Specialist_Comp_Team__c where Id in :specialistCompTeamIds])
            {
                specialistCompTeamToUserId.put(sct.Id, sct.Product_Specialist__c);
            }
        }

        //change relatedid to userid
        for(OpportunitySpecialistRelation osr : oldSpecialists)
        {
            if(!osr.isUser)
            {
                osr.setUserId(specialistCompTeamToUserId.get(osr.userOrRelatedId));
            }
        }

        for(OpportunitySpecialistRelation osr : newSpecialists)
        {
            if(!osr.isUser)
            {
                osr.setUserId(specialistCompTeamToUserId.get(osr.userOrRelatedId));
            }
            newSpecialistOTMs.add(createOTMRecord(osr.opportunityId, osr.userOrRelatedId));
        }

        System.Debug(LoggingLevel.Error, 'AGH_D teamMemberRole'+teamMemberRole+' and teamMemberAccess '+teamMemberAccess);
        // query the otms to be deleted
        if(opportunityIdSet.size()>0)
        {
            List<OpportunityTeamMember> otmsToBeDeleted = new List<OpportunityTeamMember>();

            for(OpportunityTeamMember otm : [select id,UserId,OpportunityId from OpportunityTeamMember where OpportunityId in :opportunityIdSet and TeamMemberRole=:teamMemberRole])
            {
                System.Debug(LoggingLevel.Error, 'AGH_D otm'+otm);

                for(OpportunitySpecialistRelation osr : oldSpecialists)
                {
                    System.Debug(LoggingLevel.Error, 'AGH_D osr'+osr);
                    if(otm.UserId==osr.userOrRelatedId && otm.OpportunityId==osr.OpportunityId)
                    {
                        System.Debug(LoggingLevel.Error, 'AGH_D otm match');
                        otmsToBeDeleted.add(otm);
                        // there can be only one team member per user,oppty
                        break;
                    }
                }
            }

            if(otmsToBeDeleted.size()>0)
            {
                Database.delete(otmsToBeDeleted);
            }

            List<OpportunityShare> sharesToBeDeleted = new List<OpportunityShare>();


            for(OpportunityShare oShare : [select id,UserOrGroupId,OpportunityId from OpportunityShare where OpportunityId in :opportunityIdSet and OpportunityAccessLevel=:teamMemberAccess and RowCause='Manual'])
            {
                System.Debug(LoggingLevel.Error, 'AGH_D otm'+oShare);
                for(OpportunitySpecialistRelation osr : oldSpecialists)
                {
                    System.Debug(LoggingLevel.Error, 'AGH_D osr'+osr);
                    if(oShare.UserOrGroupId==osr.userOrRelatedId && oShare.OpportunityId==osr.OpportunityId)
                    {
                        System.Debug(LoggingLevel.Error, 'AGH_D oshare match');
                        sharesToBeDeleted.add(oShare);
                        // no break since there can be multiple shares
                    }
                }
            }

            if(sharesToBeDeleted.size()>0)
            {
                Database.delete(sharesToBeDeleted);
            }
        }

        if(newSpecialistOTMs.size()>0)
        {
            Database.insert(newSpecialistOTMs);
        }

        refreshFirstRunFlag=false;
    }


    public OpportunitySpecialistsClass() {}

    private static OpportunityTeamMember createOTMRecord(Id oppId, Id userId)
    {
        return new OpportunityTeamMember(OpportunityId=oppId, UserId=userId, TeamMemberRole=teamMemberRole, OpportunityAccessLevel=teamMemberAccess);
    }

    public class OpportunitySpecialistRelation
    {
        public Id userOrRelatedId{get;private set;}
        public Id opportunityId {get;private set;}
        public Boolean isUser {get; private set;}

        public OpportunitySpecialistRelation(Id userOrRelatedId, Id opportunityId)
        {
            this.userOrRelatedId=userOrRelatedId;
            this.opportunityId=opportunityId;
            this.isUser=false;

            if(((String)userOrRelatedId).startsWith('005'))
            {
                this.isUser=true;
            }
        }

        public void setUserId(Id usId)
        {
            this.userOrRelatedId = usId;
            this.isUser=true;
        }

    }
}