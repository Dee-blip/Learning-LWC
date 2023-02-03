trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (before insert,before update, after insert, after delete) {
    if(Trigger.isBefore && Trigger.isInsert)
    {

        List<Id> opptyIds =new List<Id>();
        List<Id> userIds=new List<Id>();
        for(OpportunityTeamMember oTm: Trigger.new)
        {
            opptyIds.add(otm.OpportunityId);
            userIds.add(otm.UserId);
        }    

        Map<Id,Opportunity> opportunityMap=new Map<Id,Opportunity>([select Id
                ,Partner_Involved__r.ParentId
                ,Partner_Involved__c
                ,Deal_type__c 
                from Opportunity
                where id in :opptyIds]);
        Map<Id,User> userMap=new Map<Id,User>([select Id,Contact.Account.ParentId,Contact.AccountId, Contact.NetAlliance_User_Active__c, UserType from User where id in :userIds]); //SFDC-6913 add Contact.NetAlliance_User_Active__c, UserType in query
        //Start-SFDC-6913
        Map<Id, OpportunityTeamMember> mapOfOpptyIdVsOpportunityTeamMember = new Map<Id, OpportunityTeamMember>();
        for(OpportunityTeamMember eachOTM : [SELECT Id, TeamMemberRole, OpportunityId FROM OpportunityTeamMember WHERE OpportunityId IN :opptyIds AND TeamMemberRole = 'Partner']) {
            mapOfOpptyIdVsOpportunityTeamMember.put(eachOTM.OpportunityId, eachOTM);
        }
        //End-SFDC-6913
        for(OpportunityTeamMember oTm: Trigger.new)
        {
            Id partnerParentAccount=userMap.get(otm.UserId).Contact.Account.ParentId;
            Id partnerContactAccount=userMap.get(otm.UserId).Contact.AccountId;
            Id OpportunityPartnerInvolvedParent=opportunityMap.get(otm.OpportunityId).Partner_Involved__r.ParentId;
            Id OpportunityPartnerInvolved=opportunityMap.get(otm.OpportunityId).Partner_Involved__c;

            if(OpportunityPartnerInvolved !=null && partnerContactAccount!=null && partnerContactAccount!=OpportunityPartnerInvolved && partnerContactAccount!=OpportunityPartnerInvolvedParent)
            {
                otm.addError('Partner Contact should have a relationship with Opportunity Partner Involved.');
            }
            //Start-SFDC-6913
            if(!oTm.Validation_Override__c && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('OTM_ActiveUser_Validation') && oTm.TeamMemberRole == 'Partner' && (userMap.get(otm.UserId).Contact == null || (userMap.get(otm.UserId).Contact != null && userMap.get(otm.UserId).Contact.NetAlliance_User_Active__c == 'NO'))) {
                oTm.addError(GsmUtilClass.getGSMSettingValue('OTM_ActiveUser_ValidationMessage'));
            }
            if(!oTm.Validation_Override__c && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('OTM_ExistingUser_Validation') && oTm.TeamMemberRole == 'Partner' && mapOfOpptyIdVsOpportunityTeamMember.containsKey(oTm.OpportunityId)) {
                oTm.addError(GsmUtilClass.getGSMSettingValue('OTM_ExistingUser_ValidationMessage'));
            }
            //End-SFDC-6913
        }                   
    }
    if(Trigger.isBefore ){
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('DuplicateTeamMemberRoleEnabled')){

            Set<id> opptyIds = new Set<id>();
            string dupTeamRole =GsmUtilClass.getGSMSettingValue('TeamMemberRoleList');

            for(OpportunityTeamMember otm : Trigger.new){

                if(otm.TeamMemberRole != null && dupTeamRole.contains(otm.TeamMemberRole)){
                    if(Trigger.isinsert || (Trigger.isupdate && util.hasChanges('TeamMemberRole',Trigger.oldMap.get(otm.id),otm)))
                    
                        opptyIds.add(otm.OpportunityId);
                 }
             }
             system.debug('Swati::'+opptyIds);
                 if(opptyIds.size()>0)
                     L2Q_OpportunityTeamMemberTriggerHandler.duplicateRoleCheck(Trigger.new,opptyIds,dupTeamRole);
        }
    }


    if( Trigger.isAfter && Trigger.isInsert)
    {
        

        List<OpportunityTeamMember> upsertOTMList = new List<OpportunityTeamMember>();
        Map<Id,Id> mapOppIDOTMId = new Map<Id,Id>();
        Map<Id,List<OpportunityTeamMember>> opptyIdToOTMListMap = new Map<Id,List<OpportunityTeamMember>>();
                System.Debug(Logginglevel.Error, 'Inside Trigger');

        for(OpportunityTeamMember otm: Trigger.new)
        {
            if(!opptyIdToOTMListMap.containsKey(otm.OpportunityId))
            {
                List<OpportunityTeamMember> tempList = new List<OpportunityTeamMember>();
                tempList.add(otm);
                opptyIdToOTMListMap.put(otm.OpportunityId,tempList);
            }
            else {
            List<OpportunityTeamMember> tempList = opptyIdToOTMListMap.get(otm.OpportunityId);
            tempList.add(otm);
            opptyIdToOTMListMap.put(otm.OpportunityId,tempList);
            }

            mapOppIDOTMId.put(otm.OpportunityId,otm.UserId);
            
        }
        System.Debug(Logginglevel.Error, 'Inside Trigger'+opptyIdToOTMListMap);

        if(!opptyIdToOTMListMap.isEmpty())
            ContractSharing.upsertOTMContractShares(opptyIdToOTMListMap);

        
        
        if(!mapOppIDOTMId.isEmpty())    
            CaseTriggerClass_OA.oaCaseShareWithOTM(Trigger.newMap,mapOppIDOTMId,true);       
    }



    // you cannot update OpportunityId or UserId in oppty team members

    if(Trigger.isDelete && Trigger.isAfter)
    {
        //Set<Id> otmsToBeDeleted = new Set<Id>();
        Map<Id,Id> mapOppIDOTMId = new Map<Id,Id>();
        Map<Id,Id> opptyIDtoOTMIdMap = new Map<Id,Id>();
        Map<Id,Id> emptyMap = new Map<Id,Id>();

        for(OpportunityTeamMember otm : Trigger.old)
        {
            opptyIDtoOTMIdMap.put(otm.OpportunityId,otm.Id);
            mapOppIDOTMId.put(otm.OpportunityId,otm.UserId);
        }

        if(!opptyIDtoOTMIdMap.isEmpty())
        {
            ContractSharing.deleteATMOTMContractShares(emptyMap,opptyIDtoOTMIdMap);
            CaseTriggerClass_OA.oaCaseShareWithOTM(Trigger.oldMap,mapOppIDOTMId,false);
        }

    }
    

}