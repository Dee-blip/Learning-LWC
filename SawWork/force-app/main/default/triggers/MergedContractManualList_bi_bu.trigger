trigger MergedContractManualList_bi_bu on Merge_Contract_Manual_List__c (before insert, before update) 
{
  // Cast Iron Integration : Resolve the Contract Header Foreign Keys
  List<Merge_Contract_Manual_List__c> mlistContractResolveList = new List<Merge_Contract_Manual_List__c>(); 
  for(Merge_Contract_Manual_List__c mlist : Trigger.new)
  {
    if(Trigger.isInsert && mlist.CI_Original_Contract_Id__c != null)  
      mlistContractResolveList.add(mlist);
    else if(!Trigger.isInsert && mlist.CI_Original_Contract_Id__c != Trigger.oldMap.get(mlist.ID).CI_Original_Contract_Id__c)
      mlist.addError('Original Contract Id cannot be updated after insert.');
  }
  if(mlistContractResolveList.size() > 0)
    CastIronClass.Resolve_MergeContractManualList_ContractHeaderForeginKeys(mlistContractResolveList);  
//  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    Id MulesoftIntegrationProfileId = Id.valueOf(GsmUtilClass.getGSMSettingValue('ProfileIdMulesoftIntegration'));
    for(Merge_Contract_Manual_List__c tm : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getProfileId() == MulesoftIntegrationProfileId && (tm.AKAM_Created_By__c =='' || 
          tm.AKAM_Created_Date__c == null ||tm.AKAM_System__c =='')) || UserInfo.getProfileId() != MulesoftIntegrationProfileId ) {
          tm.AKAM_Created_By__c = tm.AKAM_Alias__c ;
          tm.AKAM_Created_Date__c = system.now();
          tm.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getProfileId() == MulesoftIntegrationProfileId && (tm.AKAM_Modified_Date__c  == null|| 
        tm.AKAM_Modified_By__c == '' || tm.AKAM_Modified_By__c == null)) || UserInfo.getProfileId() != MulesoftIntegrationProfileId )  {
        tm.AKAM_Modified_By__c = tm.AKAM_Alias__c;
        tm.AKAM_Modified_Date__c =  system.now();  
      }
    }
  } 
}