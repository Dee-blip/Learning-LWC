public without sharing class L2Q_FlowLeadConvert {
	public String partnerInvolved {
		get;
		set;
	}
	public Boolean isPartneruser {
		get;
		set;
	}
	//Begin SFDC-6406
	public String recordId {
		get;
		set;
	}
	//End SFDC-6406 //
	public L2Q_FlowLeadConvert(ApexPages.StandardController stdController) {
		//Begin SFDC-6548
		String relationshipId = ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('Opp_PMRA_Relationship_Id')) ;
		recordId = String.isNotBlank(relationshipId) ? relationshipId : '';
		//End SFDC-6548
		partnerInvolved = [Select Id, Name, profileId, UserType, Contact.AccountId from user where id =: UserInfo.getUserId() limit 1].Contact.AccountId;
		isPartneruser = (UserInfo.getUserType().toLowerCase().contains('partner')) ? true : false; //SFDC-6406
	}
}