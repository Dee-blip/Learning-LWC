public class ChannelMappingTriggerClass {
	public static Boolean AddTempPAEtoSalesTeamFirstRunflag = true;
	public static Boolean addCAMtoSalesTeamFirstRunFlag = true;
	public static Boolean checkActiveOppsForCMInactivationFlag = true;
	public static Boolean setChannelMappingMemberFirstRunFlag = true;
	private static Boolean setOpptyShareForChannelMappingFlag = true;

	
	public static void AddTempPAEtoSalesTeam(list<Channel_Mapping__c> cmlist)
	{
		if (!AddTempPAEtoSalesTeamFirstRunflag)
            return;
		//map<id,id> SalesTeamOpptyIdTempPaeMap= new map<id,id>();
		map<id,id> ApprovalsOpptyIdTempPaeMap= new map<id,id>();
		//map<id,string> SalesTeamOpptyIdRoleMap= new map<id,string>();
		//List<OpportunityTeamMember> addOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
		//List<OpportunityShare> updateOpptyShareSettingsList = new List<OpportunityShare>();  
		List<ProcessInstanceWorkitem> piWorkItemList = new List<ProcessInstanceWorkitem>();
		for(opportunity opp:[select id,Registration_Status__c,ownerid,Channel_Manager__r.Temp_PAE__c,Channel_Manager__r.VAR_Manager_Team_Role__c from Opportunity where Channel_Manager__c IN :cmlist ])
		{
			// If deal is in Pending status
			if(opp.Registration_Status__c=='Pending')
				{
					ApprovalsOpptyIdTempPaeMap.put(opp.id,opp.Channel_Manager__r.Temp_PAE__c);

				}
			// if temp PAE is not the owner
			//if(opp.ownerid!=opp.Channel_Manager__r.Temp_PAE__c)
			//	{
			//		SalesTeamOpptyIdTempPaeMap.put(opp.id,opp.Channel_Manager__r.Temp_PAE__c);
			//		SalesTeamOpptyIdRoleMap.put(opp.id,opp.Channel_Manager__r.VAR_Manager_Team_Role__c);
			//	}
		}
		
		//for(Id opptyid:SalesTeamOpptyIdTempPaeMap.keyset())
		//{
		//	addOpptySalesTeamMemberList.add ( OpportunityTriggerClass.opptyAddSalesTeamMember (opptyid, SalesTeamOpptyIdTempPaeMap.get(opptyid), SalesTeamOpptyIdRoleMap.get(opptyid)) );
		//	updateOpptyShareSettingsList.add(OpportunityTriggerClass.opptyAddOpportunityShareSettings(opptyid,SalesTeamOpptyIdTempPaeMap.get(opptyid),'Edit'));
		//}
		for(ProcessInstanceWorkitem piw:[SELECT Id, ActorId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId IN :ApprovalsOpptyIdTempPaeMap.keyset()])
		{
			ProcessInstanceWorkitem p = new ProcessInstanceWorkitem(Id = piw.id);
            p.ActorId = ApprovalsOpptyIdTempPaeMap.get(piw.ProcessInstance.TargetObjectId);
            piWorkItemList.add(p);
		}
		
		//if(addOpptySalesTeamMemberList.size()>0)
		//	{

	 //               database.insert(addOpptySalesTeamMemberList,false);
		//	}
		//if(updateOpptyShareSettingsList.size()>0)
		//	insert updateOpptyShareSettingsList;
		if(piWorkItemList.size()>0)
			update piWorkItemList;
		AddTempPAEtoSalesTeamFirstRunflag=false;
	}
	
	//public static void addCAMtoSalesTeam(list<Channel_Mapping__c> cmlist)
	//{
	//	if (!addCAMtoSalesTeamFirstRunFlag)
 //           return;
            
	//	map<id,id> SalesTeamOpptyIdCAMMap= new map<id,id>();
	//	map<id,string> SalesTeamOpptyIdRoleMap= new map<id,string>();
	//	List<OpportunityTeamMember> addOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
	//	List<OpportunityShare> updateOpptyShareSettingsList = new List<OpportunityShare>();  
	//	for(opportunity opp:[select id,Registration_Status__c,ownerid,Channel_Manager__r.Temp_PAE__c,Channel_Manager__r.VAR_Manager_Team_Role__c, Channel_Manager__r.Global_Account_Manager6__c, Channel_Manager__r.Global_Account_Manager6__r.isActive from Opportunity where Channel_Manager__c IN :cmlist ])
	//	{
	//		// if CAM is not the owner
	//		if(opp.ownerid!=opp.Channel_Manager__r.Global_Account_Manager6__c && opp.Channel_Manager__r.Global_Account_Manager6__r.isActive == true)
	//			{
	//				SalesTeamOpptyIdCAMMap.put(opp.id,opp.Channel_Manager__r.Global_Account_Manager6__c);
	//				SalesTeamOpptyIdRoleMap.put(opp.id,'Channel - Secondary');
	//			}
	//	}
		
	//	for(Id opptyid:SalesTeamOpptyIdCAMMap.keyset())
	//	{
	//		addOpptySalesTeamMemberList.add ( OpportunityTriggerClass.opptyAddSalesTeamMember (opptyid, SalesTeamOpptyIdCAMMap.get(opptyid), SalesTeamOpptyIdRoleMap.get(opptyid)) );
	//		updateOpptyShareSettingsList.add(OpportunityTriggerClass.opptyAddOpportunityShareSettings(opptyid,SalesTeamOpptyIdCAMMap.get(opptyid),'Edit'));
	//	}
		
	//	if(addOpptySalesTeamMemberList.size()>0)
	//    	database.insert(addOpptySalesTeamMemberList,false);
	    	
	//	if(updateOpptyShareSettingsList.size()>0)
	//		insert updateOpptyShareSettingsList;
			
	//	addCAMtoSalesTeamFirstRunFlag=false;
	//}
	
	public static void checkOpportunitiesBeforeChannelMappingInactivation(List<Channel_Mapping__c> cmlist)
	{
		String[] stage_names = new String[]{};
		set<Id> cm_opp_set = new set<Id>();
		stage_names = GsmUtilClass.getGSMSettingValue('CMapTrigger_StageNames').split(',');
		for(Opportunity opp : [select Id,stagename,Channel_Manager__c from Opportunity where Channel_Manager__c in :cmlist and stagename not in :stage_names])
		{
			if (!cm_opp_set.contains(opp.Channel_Manager__c))
				cm_opp_set.add(opp.Channel_Manager__c);
		}
			
		for(Channel_Mapping__c cm : cmlist){
			if (cm_opp_set.contains(cm.Id))
				cm.addError(Label.Channel_Mapping_Inactivation_Error);
		}
		checkActiveOppsForCMInactivationFlag = false;
	}


	public static void setOpportunityTeamForChannelMappingMembersFromChannelMapping(Map<Id,Id> mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping,Map<Id,Id> mapOfUsersToAddToOpptyTeamAndShareToChannelMapping,
			Map<Id,Channel_mapping_Opportunity_Settings__mdt> mapOfUsersToChannelMappingMemberData,List<String> listOfParameterNames,Map<Id,Channel_Mapping__c> mapOfChannelMappingIdToChannelMapping)
	{

			if(!setChannelMappingMemberFirstRunFlag)
				return;
			
			List<Opportunity> listOfRelatedOpptys 						= new List<Opportunity>();
			Map<Id,List<Opportunity>> mapOfChannelMappingToListOfOpptys = new Map<Id,List<Opportunity>> ();
			List<Id> listOfOpptyIds 									= new List<Id>();


			listOfParameterNames.add('Id');
			listOfParameterNames.add('OwnerId');
			listOfParameterNames.add('Channel_Manager__c');

			al.SoqlBuilder queryBuilder = new al.SoqlBuilder().selectx(listOfParameterNames).fromx('Opportunity');

        	al.NestableCondition condition = new al.OrCondition();

			//if(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.size()>0 && mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.size()>0)
			//{
			//	condition.add(new al.SetCondition('Channel_Manager__c').inx(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.values()));
	  //          condition.add(new al.SetCondition('Channel_Manager__c').inx(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.values()));
			//}
	                            
   //     	else if (mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.size()>0)
   //         	condition.add(new al.SetCondition('Channel_Manager__c').inx(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.values()));

   			if(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.size()>0)
				condition.add(new al.SetCondition('Channel_Manager__c').inx(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.values()));
	
			
        	if(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.size()>0)
               	condition.add(new al.SetCondition('Channel_Manager__c').inx(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.values()));


            String query = queryBuilder.wherex(condition).toSoql();

        	System.debug('query' +query);

			try
			{
			    listOfRelatedOpptys = Database.query(query);
			}
			
			catch(Exception exc)
			{
			    System.Debug('SOQL_ERROR' + exc.getMessage());
			}

			if(listOfRelatedOpptys.size()>0)
			{
				for(Opportunity oppty : listOfRelatedOpptys)
				{	
					if(!mapOfChannelMappingToListOfOpptys.containsKey(oppty.Channel_Manager__c))
						mapOfChannelMappingToListOfOpptys.put(oppty.Channel_Manager__c, new List<Opportunity>{oppty});
					else
						mapOfChannelMappingToListOfOpptys.get(oppty.Channel_Manager__c).add(oppty);

					listOfOpptyIds.add(oppty.Id);

				}

				addOpportunityTeamAndShares(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping,mapOfUsersToChannelMappingMemberData,mapOfChannelMappingToListOfOpptys,mapOfChannelMappingIdToChannelMapping);
				deleteOpportunityTeamAndShares(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping,mapOfUsersToChannelMappingMemberData,listOfOpptyIds);
			}

			System.debug('mapOfChannelMappingToOppty' + mapOfChannelMappingToListOfOpptys);

			setChannelMappingMemberFirstRunFlag = false;
	}

	private static void addOpportunityTeamAndShares(Map<Id,Id> mapOfUsersToAddToOpptyTeamAndShareToChannelMapping,Map<Id,Channel_mapping_Opportunity_Settings__mdt> mapOfUsersToChannelMappingMemberData,Map<Id,List<Opportunity>> mapOfChannelMappingToListOfOpptys,Map<Id,Channel_Mapping__c> mapOfChannelMappingIdToChannelMapping)
	{

		List<OpportunityTeamMember> addOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
        List<OpportunityShare> addOpptyShareSettingsList        = new List<OpportunityShare>();

		for(Id userId : mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.keySet())
		{
			String relationshipObjectName = mapOfUsersToChannelMappingMemberData.get(userId).API_name__c.replace('__c','__r'); 

			for(Opportunity oppty : mapOfChannelMappingToListOfOpptys.get(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.get(userId)))
			{
				if((Boolean)oppty.getSObject('Channel_Manager__r').getSObject(relationshipObjectName).get('isActive') == TRUE)
				{	
					if(userId != oppty.OwnerId)
					{
                    	OpportunityTeamMember tempMember = OpportunityTriggerClass.opptyAddSalesTeamMember(oppty.Id,
						userId,mapOfUsersToChannelMappingMemberData.get(userId).Role__c);
                    	tempMember.OpportunityAccessLevel = mapOfUsersToChannelMappingMemberData.get(userId).Opportunity_Access__c;
                     
                     	addOpptySalesTeamMemberList.add(tempMember);
					}

				}

				else
				{
					if(!mapOfChannelMappingIdToChannelMapping.get(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.get(userId)).Validation_Override__c)
						mapOfChannelMappingIdToChannelMapping.get(mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.get(userId)).addError(mapOfUsersToChannelMappingMemberData.get(userId).MasterLabel + ' is not active. Please contact partnersetup@akamai.com to help resolve this issue.');

				}

			}			
		}

		System.debug('addOpptySalesTeamMemberList' + addOpptySalesTeamMemberList);

        if (addOpptySalesTeamMemberList.size()>0)
            insert addOpptySalesTeamMemberList;

	}


	private static void deleteOpportunityTeamAndShares(Map<Id,Id> mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping,Map<Id,Channel_mapping_Opportunity_Settings__mdt> mapOfUsersToChannelMappingMemberData,List<Id> listOfOpptyIds)
	{
		
        List<OpportunityTeamMember> listOfOpptyTeamMembersToDelete    = new List<OpportunityTeamMember>();

        for(OpportunityTeamMember opptyTeamMemberObj : [select Id, UserId, OpportunityId, TeamMemberRole from OpportunityTeamMember where OpportunityId IN :listOfOpptyIds AND UserId IN : mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.keySet()])
        {
           
             if(mapOfUsersToChannelMappingMemberData.get(opptyTeamMemberObj.UserId).Role__c == opptyTeamMemberObj.TeamMemberRole)
                    listOfOpptyTeamMembersToDelete.add(opptyTeamMemberObj);
        }

        System.debug('listOfOpptyTeamMembersToDelete' + listOfOpptyTeamMembersToDelete);

        if(listOfOpptyTeamMembersToDelete.size()>0)
            delete listOfOpptyTeamMembersToDelete;        

	}

	public static void setOpportunityTeamForChannelMappingMembersFromOppportunity(Map<Id,Id> mapOfOpptyIdToOldChannelMappingId,Map<Id,Id> mapOfOpptyIdToNewChannelMappingId,Map<Id,Opportunity> mapofOpptyIdToOppty, Boolean isForGSIChannelmanager)
    {
        if(!setOpptyShareForChannelMappingFlag)
            return;

        List<Channel_Mapping__c> listOfChannelMapping = new List<Channel_Mapping__c>();
        List<String> listOfParametersToQuery = new List<String>();
        List<Channel_mapping_Opportunity_Settings__mdt> listOfChannelMappingData = new List<Channel_mapping_Opportunity_Settings__mdt>();
        Map<Id,Channel_Mapping__c> mapOfChannelMappingIdToChannelMappingObject = new Map<Id,Channel_Mapping__c>();


		List<Channel_mapping_Opportunity_Settings__mdt> cmMetadataList = new List<Channel_mapping_Opportunity_Settings__mdt>();
        String gsiIdentifier = '%' + 'GSI' + '%';
		if (isForGSIChannelmanager) {
			cmMetadataList = [Select API_name__c,Opportunity_Access__c,Role__c,MasterLabel from Channel_mapping_Opportunity_Settings__mdt where developerName like :gsiIdentifier];
		} else {
			cmMetadataList = [Select API_name__c,Opportunity_Access__c,Role__c,MasterLabel from Channel_mapping_Opportunity_Settings__mdt where NOT developerName like :gsiIdentifier];
		}
		for(Channel_mapping_Opportunity_Settings__mdt channelMappingMember : cmMetadataList)
        {
            listOfParametersToQuery.add(channelMappingMember.API_name__c);
            // need to check if the user is active
            listOfParametersToQuery.add(channelMappingMember.API_name__c.replace('__c','__r') + '.isActive');
            listOfChannelMappingData.add(channelMappingMember);
        }

        listOfParametersToQuery.add('Id');

        al.SoqlBuilder queryBuilder = new al.SoqlBuilder().selectx(listOfParametersToQuery).fromx('Channel_Mapping__c');

        al.NestableCondition condition = new al.AndCondition().add(new al.FieldCondition().field('Active__c').equals(TRUE));

        al.NestableCondition orCondition = new al.OrCondition();

        if(mapOfOpptyIdToOldChannelMappingId.size()>0)
           orCondition.add(new al.SetCondition('Id').inx(mapOfOpptyIdToOldChannelMappingId.values()));
        if(mapOfOpptyIdToNewChannelMappingId.size()>0) 
            orCondition.add(new al.SetCondition('Id').inx(mapOfOpptyIdToNewChannelMappingId.values()));
          
        condition.add(orCondition);

        //if(mapOfOpptyIdToNewChannelMappingId.size()>0 && mapOfOpptyIdToOldChannelMappingId.size()>0)
        //    condition.add(new al.OrCondition()
        //                        .add(new al.SetCondition('Id').inx(mapOfOpptyIdToOldChannelMappingId.values()))
        //                        .add(new al.SetCondition('Id').inx(mapOfOpptyIdToNewChannelMappingId.values())));

        //else if (mapOfOpptyIdToNewChannelMappingId.size()>0)
        //    condition.add(new al.SetCondition('Id').inx(mapOfOpptyIdToNewChannelMappingId.values()));

        
        String query = queryBuilder.wherex(condition).toSoql();

        System.debug('query' +query);

        try
        {
            listOfChannelMapping = Database.query(query);
        }
        catch(Exception exc)
        {
                System.Debug('SOQL_ERROR' + exc.getMessage());
        }
        for(Channel_Mapping__c channelMappingObj : listOfChannelMapping)
        {
            mapOfChannelMappingIdToChannelMappingObject.put(channelMappingObj.Id,channelMappingObj);
        }
        
        if(mapOfOpptyIdToOldChannelMappingId.size()>0)
            deleteOpportunityTeamAndShares(mapOfOpptyIdToOldChannelMappingId,mapOfChannelMappingIdToChannelMappingObject,listOfChannelMappingData,isForGSIChannelmanager);

        if(mapOfOpptyIdToNewChannelMappingId.size()>0)
            addOpportunityTeamAndShares(mapOfOpptyIdToNewChannelMappingId,mapOfChannelMappingIdToChannelMappingObject,mapofOpptyIdToOppty,listOfChannelMappingData,isForGSIChannelmanager);


        setOpptyShareForChannelMappingFlag = false;
    }

    private static void addOpportunityTeamAndShares(Map<Id,Id> mapOfOpptyIdToNewChannelMappingId,Map<Id,Channel_Mapping__c> mapOfChannelMappingIdToChannelMappingObject,Map<Id,Opportunity> mapofOpptyIdToOppty,List<Channel_mapping_Opportunity_Settings__mdt> listOfChannelMappingData, Boolean isForGSIChannelmanager)
    {

        System.debug('mapOfChannelMappingIdToChannelMappingObject' + mapOfChannelMappingIdToChannelMappingObject);
        List<OpportunityTeamMember> addOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
        List<OpportunityShare> addOpptyShareSettingsList        = new List<OpportunityShare>();

        for(Id opptyId : mapOfOpptyIdToNewChannelMappingId.keyset())
        {
            for(Channel_mapping_Opportunity_Settings__mdt channelMappingMember : listOfChannelMappingData)
            {
                String relationshipObjectName = channelMappingMember.API_name__c.replace('__c','__r'); 
                // check if the field is populated, if populated user is active and user isn't equal to the opportunity owner(as there will already be a share for opportunity owner)
                if((Id)mapOfChannelMappingIdToChannelMappingObject.get(mapOfOpptyIdToNewChannelMappingId.get(opptyId)).get(channelMappingMember.API_name__c) != null)
                {
                    if((Boolean)mapOfChannelMappingIdToChannelMappingObject.get(mapOfOpptyIdToNewChannelMappingId.get(opptyId)).getSObject(relationshipObjectName).get('isActive')== TRUE)
                    {
                        if((Id)mapOfChannelMappingIdToChannelMappingObject.get(mapOfOpptyIdToNewChannelMappingId.get(opptyId)).get(channelMappingMember.API_name__c) != mapofOpptyIdToOppty.get(opptyId).OwnerId)
                        {
                            OpportunityTeamMember tempMember = OpportunityTriggerClass.opptyAddSalesTeamMember(opptyId, 
                           (Id)mapOfChannelMappingIdToChannelMappingObject.get(mapOfOpptyIdToNewChannelMappingId.get(opptyId)).get(channelMappingMember.API_name__c),
                            channelMappingMember.Role__c);
                            tempMember.OpportunityAccessLevel = channelMappingMember.Opportunity_Access__c;
                            addOpptySalesTeamMemberList.add(tempMember);

                        }
                       
                    }

                    else
                    {
						if (isForGSIChannelmanager) {
							if(!mapofOpptyIdToOppty.get(opptyId).Validation_Override__c)
                            	mapofOpptyIdToOppty.get(opptyId).GSI_Channel_Manager__c.addError( channelMappingMember.MasterLabel + ' is not active. Please contact partnersupport@akamai.com to help resolve this issue.');

						} else {
							if(!mapofOpptyIdToOppty.get(opptyId).Validation_Override__c)
                            	mapofOpptyIdToOppty.get(opptyId).Channel_Manager__c.addError( channelMappingMember.MasterLabel + ' is not active. Please contact partnersupport@akamai.com to help resolve this issue.');
						}
						
                    }

                }
                    
            }
        }

        if (addOpptySalesTeamMemberList.size()>0)
            insert addOpptySalesTeamMemberList;

    }

    private static void deleteOpportunityTeamAndShares(Map<Id,Id> mapOfOpptyIdToOldChannelMappingId,Map<Id,Channel_Mapping__c> mapOfChannelMappingIdToChannelMappingObject,List<Channel_mapping_Opportunity_Settings__mdt> listOfChannelMappingData, Boolean isForGSIChannelmanager)
    {
        
        List<OpportunityTeamMember> listOfOpptyTeamMembersToDelete    = new List<OpportunityTeamMember>();
     

        for(OpportunityTeamMember opptyTeamMemberObj : [select Id, UserId, OpportunityId, TeamMemberRole from OpportunityTeamMember where OpportunityId IN : mapOfOpptyIdToOldChannelMappingId.keySet()])
        {
            for(Channel_mapping_Opportunity_Settings__mdt channelMappingMember : listOfChannelMappingData)
            {
                if((Id)mapOfChannelMappingIdToChannelMappingObject.get(mapOfOpptyIdToOldChannelMappingId.get(opptyTeamMemberObj.OpportunityId)).get(channelMappingMember.API_name__c) == opptyTeamMemberObj.UserId 
                    && channelMappingMember.Role__c == opptyTeamMemberObj.TeamMemberRole)
                    listOfOpptyTeamMembersToDelete.add(opptyTeamMemberObj);
            }

        }

        System.debug('listOfOpptyTeamMembersToDelete' + listOfOpptyTeamMembersToDelete);
       
        if(listOfOpptyTeamMembersToDelete.size()>0)
            delete listOfOpptyTeamMembersToDelete;

    }



}