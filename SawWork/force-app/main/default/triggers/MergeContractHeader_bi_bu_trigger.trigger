/**
  MergeContractHeader_bi_bu_trigger
  
  @author      - Chandra Mohan Lohani
  @description - This trigger will ne called when ever a contract header is inseted or updated. 
  
  @history 
  
     Date            Developer                  Description
    01/15/2011     Chandra Mohan Lohani		   Created the class
    
    03/17/2011     Chandra Mohan Lohani        Modified for CR 1016688,
                                               removed the code to throw 'Account can not be updated after insert' error and added code to check for any update,
                                               since relationship between Conract and Account has been changed from Master-detail to Lookup.    
	
	09/30/2013	   Sonia Sawhney			   CR 2394210 - Need to disable code. Bypass logic for records created through S2S sync
*/
trigger MergeContractHeader_bi_bu_trigger on Merge_Contract_Header__c (before insert, before update) 
{
	//bypass logic for S2S created records
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {   
        // For resolving account Foreign Keys
        List<Merge_Contract_Header__c> accountForeignKeyResolveList=new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert)||(trigger.isUpdate && con.CI_Account_Name__c !=trigger.oldMap.get(con.Id).CI_Account_Name__c))
            {
                accountForeignKeyResolveList.add(con);
            }
        }
        if(accountForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_AccountForeignKeys(accountForeignKeyResolveList);
        }
        // For resolving parent Contract Foreign Keys
        List<Merge_Contract_Header__c> parentContractForeignKeyResolveList=new List<Merge_Contract_Header__c>();

        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert) || (trigger.isUpdate && con.CI_Parent_Contract__c !=trigger.oldMap.get(con.Id).CI_Parent_Contract__c))
            {
                parentContractForeignKeyResolveList.add(con);
            }
        }
        if(parentContractForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_ParentContractHeaderForeignKeys(parentContractForeignKeyResolveList);
        }

        // For resolving Bill to Contact Foreign Keys
        List<Merge_Contract_Header__c> billToContactForeignKeyResolveList=new List<Merge_Contract_Header__c>();

        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert) || (trigger.isUpdate && con.CI_Bill_To_Contact__c !=trigger.oldMap.get(con.Id).CI_Bill_To_Contact__c))
            {
                billToContactForeignKeyResolveList.add(con);
            }
        }
        if(billToContactForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_BillToContactForeignKeys(billToContactForeignKeyResolveList);
        }

        // For resolving Contract Transferred To Foreign Keys
        List<Merge_Contract_Header__c> contractTransferredToForeignKeyResolveList=new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert) || (trigger.isUpdate && con.CI_Contract_Transferred_To__c !=trigger.oldMap.get(con.Id).CI_Contract_Transferred_To__c))
            {
                contractTransferredToForeignKeyResolveList.add(con);
            }
        }
        if(contractTransferredToForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_ContractTransferredToForeignKeys(contractTransferredToForeignKeyResolveList);
        }
        // For resolving Opportunity Foreign Keys
        List<Merge_Contract_Header__c> opportunityForeignKeyResolveList=new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert) || (trigger.isUpdate && con.CI_Opportunity_Name__c !=trigger.oldMap.get(con.Id).CI_Opportunity_Name__c))
            {
                opportunityForeignKeyResolveList.add(con);
            }
        }
        if(opportunityForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_OpportunityForeignKeys(opportunityForeignKeyResolveList);
        }
        // For resolving parent Account Name Foreign Keys
        List<Merge_Contract_Header__c> parentAccountForeignKeyResolveList=new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert) || (trigger.isUpdate && con.CI_Parent_Account_Name__c !=trigger.oldMap.get(con.Id).CI_Parent_Account_Name__c))
            {
                parentAccountForeignKeyResolveList.add(con);
            }
        }
        if(parentAccountForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_ParentAccountForeignKeys(parentAccountForeignKeyResolveList);
        }
        // For resolving referred by Account Foreign Keys
        List<Merge_Contract_Header__c> referredByAccountForeignKeyResolveList=new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c con : trigger.New)
        {
            if((trigger.isInsert) || (trigger.isUpdate && con.CI_Referred_By_Account__c !=trigger.oldMap.get(con.Id).CI_Referred_By_Account__c))
            {
                referredByAccountForeignKeyResolveList.add(con);
            }
        }
        if(referredByAccountForeignKeyResolveList.size()>0)
        {
            CastIronClass.Resolve_Contract_Header_ReferredByAccountForeignKeys(referredByAccountForeignKeyResolveList);
        }
        List<Merge_Contract_Header__c> mchPartnerTypeUpdatedList = new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c mch : trigger.New)
        {
            if(Trigger.isInsert)
            {
                if (mch.Partner_Type__c!=null)
                    mchPartnerTypeUpdatedList.add(mch);
            }

            if(Trigger.isUpdate)
            {
                if (mch.Partner_Type__c!=Trigger.oldMap.get(mch.Id).Partner_Type__c) 
                {    
                    mchPartnerTypeUpdatedList.add(mch);
                }

            }
        }

        if (mchPartnerTypeUpdatedList.size()>0)
            MergeContractHeaderTriggerClass.updateAccountPartnerStatus(mchPartnerTypeUpdatedList); 
    }
}