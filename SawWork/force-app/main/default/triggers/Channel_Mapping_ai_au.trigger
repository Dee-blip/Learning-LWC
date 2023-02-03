trigger Channel_Mapping_ai_au on Channel_Mapping__c (after insert, after update) {
	list<Channel_Mapping__c> cmlist= new list<Channel_Mapping__c>();
	//List<Channel_Mapping__c> camList = new List<Channel_Mapping__c>();

	Map<Id,Id> mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping = new Map<Id,Id>();
	Map<Id,Id> mapOfUsersToAddToOpptyTeamAndShareToChannelMapping	 = new Map<Id,Id>();
	Map<Id,Channel_mapping_Opportunity_Settings__mdt> mapOfUsersToChannelMappingMemberData = new Map<Id,Channel_mapping_Opportunity_Settings__mdt>();
	Map<Id,Channel_Mapping__c> mapOfChannelMappingIdToChannelMapping = new Map<Id,Channel_Mapping__c>();
	List<String> listOfParameterNames = new List<String>();


	for(Channel_Mapping__c cm: Trigger.New)
	{
		if(Trigger.isUpdate && cm.Temp_PAE__c!=Trigger.oldMap.get(cm.id).Temp_PAE__c && cm.Temp_PAE__c!=null)
		{
			cmlist.add(cm);
		}
		
	//	if(Trigger.isUpdate && cm.Global_Account_Manager6__c != Trigger.oldMap.get(cm.Id).Global_Account_Manager6__c && cm.Global_Account_Manager6__c != null)
	//		camList.add(cm);
	//}
	//if(cmlist.size()>0)
	//{
	//	ChannelMappingTriggerClass.AddTempPAEtoSalesTeam(cmlist);
	//}
	
	//if(camList.size() > 0)
	//	ChannelMappingTriggerClass.addCAMtoSalesTeam(camList);



		for(Channel_mapping_Opportunity_Settings__mdt channelMappingMember : [Select API_name__c,Opportunity_Access__c,Role__c,MasterLabel from Channel_mapping_Opportunity_Settings__mdt])
		{
			if(Util.isInserted(channelMappingMember.API_name__c,cm) || (Trigger.isUpdate && Util.hasChanges(channelMappingMember.API_name__c, Trigger.oldMap.get(cm.Id),cm)))
			{
				if(Trigger.isUpdate  && Trigger.oldMap.get(cm.Id).get(channelMappingMember.API_name__c)!=null)
				{
					mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.put((Id)Trigger.oldMap.get(cm.Id).get(channelMappingMember.API_name__c),cm.Id);
					mapOfUsersToChannelMappingMemberData.put((Id)Trigger.oldMap.get(cm.Id).get(channelMappingMember.API_name__c),channelMappingMember);
				}

				if(cm.get(channelMappingMember.API_name__c)!=null)
				{
					mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.put((Id)cm.get(channelMappingMember.API_name__c),cm.Id);
					mapOfUsersToChannelMappingMemberData.put((Id)cm.get(channelMappingMember.API_name__c),channelMappingMember);
				}

				mapOfChannelMappingIdToChannelMapping.put(cm.Id, cm);
				//listOfParameterNames.add(channelMappingMember.API_name__c);
				listOfParameterNames.add('Channel_Manager__r.'+channelMappingMember.API_name__c.replace('__c','__r') + '.isActive');

			}

		}

	}

	if(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping.size()>0 || mapOfUsersToAddToOpptyTeamAndShareToChannelMapping.size()>0)
		ChannelMappingTriggerClass.setOpportunityTeamForChannelMappingMembersFromChannelMapping(mapOfUsersToDeleteFromOpptyTeamAndShareToChannelMapping,mapOfUsersToAddToOpptyTeamAndShareToChannelMapping,mapOfUsersToChannelMappingMemberData,listOfParameterNames,mapOfChannelMappingIdToChannelMapping);

}