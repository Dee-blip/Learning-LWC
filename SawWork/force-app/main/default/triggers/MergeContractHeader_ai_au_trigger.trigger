/**
 * History:
 * =========================
 * Developer  Date  Description
 * --------------------------------------------------------------------------------------------------
 * Sonia Sawhney 30/09/13 CR 2394210 - Need to disable code. Bypass logic for records created through S2S sync
 **/
trigger MergeContractHeader_ai_au_trigger on Merge_Contract_Header__c (after insert, after update) 
{
//bypass logic for S2S created records
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    { 

    List<Merge_Contract_Header__c> mchAccountUpdatedList = new List<Merge_Contract_Header__c>();
    List<Merge_Contract_Header__c> mchOpptyUpdatedList = new List<Merge_Contract_Header__c>();
    List<Merge_Contract_Header__c> mchAKAMNAPMasterUpdatedList = new List<Merge_Contract_Header__c>();
        //HC- added these variables
    Set<Id> mchAccIdSet = new Set<Id>();
    Set<Id> mchOpptyIdSet = new Set<Id>();
   
    Map<Id,Id> mchIdAccIdMap = new Map<Id,Id>();
    Map<Id,Id> mchIdOppIdMap = new Map<Id,Id>();
    Set<Id> tobeRemovedContractIdSet = new Set<Id>();
    list<string> jarvisContractsForPermissioning = new list<string>();
        
   if (Trigger.isInsert)
   {
       // call the method that picks up atm / otm and adds to Merge_Contract_Header__Share and Contract_Share__c tables
       for (Merge_Contract_Header__c mch : Trigger.new)
       {
           if (mch.Account_Name__c!=null)
               {
                mchAccountUpdatedList.add(mch);
                mchAccIdSet.add(mch.Account_Name__c);
                   

               }
           if (mch.Opportunity_Name__c!=null)
               {
                mchOpptyUpdatedList.add(mch);
                mchOpptyIdSet.add(mch.Opportunity_Name__c);
               }
            if (mch.Akam_NAP_Master_Contract_ID__c!=null)
                    mchAKAMNAPMasterUpdatedList.add(mch);
          
            jarvisContractsForPermissioning.add(mch.Id); 
       }
       
   }
   if (!Trigger.isInsert)
   {
       for (Merge_Contract_Header__c mch : Trigger.new)
       {
           if (mch.Account_Name__c!=null && mch.Account_Name__c != Trigger.oldMap.get(mch.Id).Account_Name__c)
           {
                mchAccountUpdatedList.add(mch);
                mchAccIdSet.add(mch.Account_Name__c);


                if (Trigger.oldMap.get(mch.Id).Account_Name__c!= null)
                {
                    mchIdAccIdMap.put(mch.Id,Trigger.oldMap.get(mch.Id).Account_Name__c);
                    tobeRemovedContractIdSet.add(mch.Id);
                }
           }   
           if (mch.Opportunity_Name__c!=Trigger.oldMap.get(mch.Id).Opportunity_Name__c)
           {
                if(mch.Opportunity_Name__c!=null)
                {
                    mchOpptyUpdatedList.add(mch);
                    mchOpptyIdSet.add(mch.Opportunity_Name__c);
                }

                if (Trigger.oldMap.get(mch.Id).Opportunity_Name__c!= null)
                {
                    mchIdOppIdMap.put(mch.Id, Trigger.oldMap.get(mch.Id).Opportunity_Name__c);
                    tobeRemovedContractIdSet.add(mch.Id);
                }
           }   
            if(Util.hasChanges('Akam_NAP_Master_Contract_ID__c', Trigger.oldMap.get(mch.Id), mch))
                {
                    mchAKAMNAPMasterUpdatedList.add(mch);
                }
            jarvisContractsForPermissioning.add(mch.Id);    
       }
   }
   // Call ContractSharing Class  method that remove atm/otm users from MCHShare table.    
   if (mchIdAccIdMap.size()>0 || mchIdOppIdMap.size()>0)
      ContractSharing.removeATMOTMShareOnAccOpptyUpdate(mchIdAccIdMap,mchIdOppIdMap,tobeRemovedContractIdSet);     
   
   //Call Contract Sharing Class method to add new ATMs and OTMs ofr new Account/Oppty Association to Contract
   if (mchAccountUpdatedList.size()>0)
       ContractSharing.addATMToContractShare(mchAccountUpdatedList,mchAccIdSet, Trigger.newMap);
   if (mchOpptyUpdatedList.size()>0)
       ContractSharing.addOTMToContractShare(mchOpptyUpdatedList,mchOpptyIdSet, Trigger.newMap);
       //Added batch check
  if(jarvisContractsForPermissioning.size()>0 && !SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk && !system.isFuture() && !system.isBatch())
    {
        SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk = true;
        SC_Jarvis_CoreSecurityController.createPublicGroupForSObject(jarvisContractsForPermissioning,'Contract');
    }

        if (mchAKAMNAPMasterUpdatedList.size()>0)
            MergeContractHeaderTriggerClass.populateNAPMasterContractID(mchAKAMNAPMasterUpdatedList);
    }
}