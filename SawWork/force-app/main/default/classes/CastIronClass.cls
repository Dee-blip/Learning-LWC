/***
    CastIronClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class is used to resolve foreign key relationships during Cast Iron Integration.
                   The design is :
                   1. Cast Iron sets the AKAM Id in a "CI_%" field.
                   2. The logic in this class will lookup the corresponding object and fetch the Salesforce ID.
                   3. The logic in this class will then set the Lookup according to the fetched value in Step 2.
                   
                   Currently, the following keys are resolved :
                   1.   Merge_Contract_Activity__c.Opportunity_Name__c
                   2.   Merge_Contract_Activity__c.Original_Contract_Id__c
                   3.   Merge_Contract_Manual_List__c.Original_Contract_Id__c
                   4.   Merge_Contract_PO__c.Original_Contract_Id__c
                
    @History
    --Developer           --Date            --Change
    Karteek Kumar M       05/08/2010        Created the class as per CR 737434 Add reference key triggers to custom objects.
    Karteek Kumar M       10/08/2010        Adding resolve for Merge_Contract_PO__c.Original_Contract_Id__c
    Chandra Mohan Lohani  24/09/2010        Added methods to resolve Invoice__c.Original_Contract_Id__c and Invoice__c.Account_Name__c 
    Ali KM                06/02/2013        CR 2068273 - Invoice Review Cases Process migration from Siebel to SF.
                                                - added resolving of CI fields to a new Object: Draft_Invoice__c.
                                                - Created: Resolve_Draft_Invoice_ContractHeaderForeignKeys()
                                                - Created: Resolve_Draft_Invoice_ByContractHeaderSFId
                                                - Update: Resolve_Invoice_ContractHeaderForeignKeys
    Ali KM                06/02/2013        CR 2068273 - reverting all changes related to IR Cases out of 3.21 release.
    Ali KM                10/03/2013        CR 2068273 - adding IR Case related changes back to 3.23 codeline.  
    Pramod Kamath V       15/04/2013        CR 2181485- IR Case:Need to roll-up/add code to update ManualList flag from Contract Manual List.
    Lisha Murthy          02/08/2013        CR 2318375 - Add more details to email sent out from Cron job monitoring Castiron Polling
                                                - Replaced the emails being used to send out castiron polling notification with email template.
                                              
                                                                                     
*/
global class CastIronClass 
{
/* Moving code to Merge COntract Manual List
    public static Boolean firstRunFlagManualListActiveCheck=false;
        public static void contractManualList_checkForActiveInActive(List<Merge_Contract_Manual_List__c> pTriggerNew)
    {
        if (CastIronClass.firstRunFlagManualListActiveCheck)
            return;
            
        
        Map<Id,Merge_Contract_Header__c> mchToUpdateMap = new Map<Id,Merge_Contract_Header__c>();  
        List<Merge_Contract_Header__c> mchToUpdateList = new List<Merge_Contract_Header__c>();
        Set<Id> mchIdSet = new Set<Id>(); 
        for(Merge_Contract_Manual_List__c mcml : pTriggerNew)       
        { 
            mchIdSet.add(mcml.Original_Contract_Id__c); 
        }       
        
        // loop over every contract and every CML within it. Check for a condition. Mark contract.Manual_List__c=true if condition success. 
        for (Merge_Contract_Header__c mch : [Select Id, Name, Manual_List__c, (SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,
            Priority__c,Review_Date__c,Review_Frequency__c,Owner__c from Merge_Contract_Manual_Lists__r Order by End_Date__c DESC) From Merge_Contract_Header__c where Id IN: mchIdSet])
            {
                for (Merge_Contract_Manual_List__c mcml : mch.Merge_Contract_Manual_Lists__r)
                {
                    if(((mcml.Review_Frequency__c==null || !mcml.Review_Frequency__c.equalsIgnoreCase('one time')) && 
                        (mcml.End_Date__c==null || (mcml.End_Date__c!=null && mcml.End_Date__c>=Date.Today().toStartOfMonth().addMonths(Integer.valueOf( GsmUtilClass.GetCustomSettingValue('IR_ManualList_GraceMonths')))))) || 
                            (mcml.Review_Frequency__c!=null && mcml.Review_Frequency__c.equalsIgnoreCase('one time') && ((mcml.Review_Date__c!=null && mcml.Review_Date__c>=Date.Today().toStartOfMonth().addMonths(Integer.valueOf( GsmUtilClass.GetCustomSettingValue('IR_ManualList_GraceMonths')))) || 
                                (mcml.Review_Date__c==null && (mcml.End_Date__c==null || (mcml.End_Date__c!=null && mcml.End_Date__c>Date.Today().toStartOfMonth().addMonths(Integer.valueOf( GsmUtilClass.GetCustomSettingValue('IR_ManualList_GraceMonths')))))))))
                                {   
                                    mchToUpdateMap.put(mch.Id, new Merge_Contract_Header__c(id=mch.Id,Manual_List__c=true));
                                    
                                    break;
                                    
                                }
                                else if (!mchToUpdateMap.containsKey(mch.Id)) 
                                {
                                    System.debug('Inside Qualifies for Manual List FALSE');
                                    mchToUpdateMap.put(mch.Id, new Merge_Contract_Header__c(id=mch.Id,Manual_List__c=false));
                                    System.debug('Inside Qualifies for Manual List False, After mch.Manual_List__c=' + mch.Manual_List__c);
                                }
                }   
            }
            
        if (mchToUpdateMap.size()>0)
        {
            mchToUpdateList = mchToUpdateMap.values();
            System.debug('mchToUpdateMap=' + mchToUpdateMap.size());
            System.debug('mchToUpdateList=' + mchToUpdateList);
            update mchToUpdateList;
        }
        CastIronClass.firstRunFlagManualListActiveCheck=true;       
    }
    
    Moving code to Merge COntract Manual List class */
    
    
    
    
    
    /**
        Resolve_MergeContractActivity_OpportunityForeginKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Opportunity_Name via field Merge_Contract_Header__c.CI_Opportunity_Name
    */
    public static void Resolve_MergeContractActivity_OpportunityForeginKeys(Merge_Contract_Activity__c[] mc_activities)
    {
        // Form a Set
        Set<String> oppAkamIdSet = new Set<String>();
        for(Merge_Contract_Activity__c activity : mc_activities)
            oppAkamIdSet.add(activity.CI_Opportunity_Name__c);
            
        // Query and Create a Map
        Map<String, Id> oppIdMap = new Map<String, Id>();
        for(Opportunity opp : [select Id, 
                                      AKAM_Opportunity_ID__c
                               from Opportunity
                               where AKAM_Opportunity_ID__c IN :oppAkamIdSet])
            oppIdMap.put(opp.AKAM_Opportunity_ID__c, opp.Id);
            
        // Make the Update
        for(Merge_Contract_Activity__c activity : mc_activities)
        {
           if(activity.CI_Opportunity_Name__c !=null)
            {
            activity.Opportunity_Name__c = oppIdMap.get(activity.CI_Opportunity_Name__c);
            if((activity.CI_Opportunity_Name__c != '' && activity.CI_Opportunity_Name__c != null) && activity.Opportunity_Name__c == null)
                activity.addError('Invalid Opportunity Id : ' + activity.CI_Opportunity_Name__c);
            }
            else
            {
                activity.Opportunity_Name__c=null;
            }
        }
    }
    /**
        Resolve_MergeContractActivity_ContractHeaderForeginKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Original_Contract_Id__c via field Merge_Contract_Activity__c.CI_Original_Contract_Id__c       
    */  
    public static void Resolve_MergeContractActivity_ContractHeaderForeginKeys(Merge_Contract_Activity__c[] mc_activities)
    {
        // Form a Set
        Set<String> contractAkamIdSet = new Set<String>();
        for(Merge_Contract_Activity__c activity : mc_activities)
        {
            if(activity.CI_Original_Contract_Id__c != null && activity.CI_Original_Contract_Id__c != '')
                contractAkamIdSet.add(activity.CI_Original_Contract_Id__c);
            else
                activity.Original_Contract_Id__c = null;
        }
            
        // Query and Create a Map
        Map<String, Id> contractIdMap = new Map<String, Id>();
        for(Merge_Contract_Header__c contract : [select Id, 
                                                        Name
                                                 from Merge_Contract_Header__c
                                                 where Name IN :contractAkamIdSet])
            contractIdMap.put(contract.Name, contract.Id);
                
        // Make the Update
        for(Merge_Contract_Activity__c activity : mc_activities)
        {
            activity.Original_Contract_Id__c = contractIdMap.get(activity.CI_Original_Contract_Id__c);
            if((activity.CI_Original_Contract_Id__c != '' && activity.CI_Original_Contract_Id__c!=null) && activity.Original_Contract_Id__c == null)
                activity.addError('Invalid Contract Header Id : ' + activity.CI_Original_Contract_Id__c);
        }
    }   
    /**
        Resolve_MergeContractManualList_ContractHeaderForeginKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Manual_List__c.Original_Contract_Id__c via field Merge_Contract_Manual_List__c.CI_Original_Contract_Id__c       
    */  
    public static void Resolve_MergeContractManualList_ContractHeaderForeginKeys(Merge_Contract_Manual_List__c[] mlists)
    {
        // Form a Set
        Set<String> contractAkamIdSet = new Set<String>();
        for(Merge_Contract_Manual_List__c mlist : mlists)
        {
            if(mlist.CI_Original_Contract_Id__c != null && mlist.CI_Original_Contract_Id__c != '')
                contractAkamIdSet.add(mlist.CI_Original_Contract_Id__c);
            else
                mlist.Original_Contract_Id__c = null;
        }
            
        // Query and Create a Map
        Map<String, Id> contractIdMap = new Map<String, Id>();
        for(Merge_Contract_Header__c contract : [select Id, 
                                                        Name
                                                 from Merge_Contract_Header__c
                                                 where Name IN :contractAkamIdSet])
            contractIdMap.put(contract.Name, contract.Id);
                
        // Make the Update
        for(Merge_Contract_Manual_List__c mlist : mlists)
        {
            mlist.Original_Contract_Id__c = contractIdMap.get(mlist.CI_Original_Contract_Id__c);
            if((mlist.CI_Original_Contract_Id__c != '' && mlist.CI_Original_Contract_Id__c != null) && mlist.Original_Contract_Id__c == null)
                mlist.addError('Invalid Contract Header Id : ' + mlist.CI_Original_Contract_Id__c);
        }
    }   
    /**
        Resolve_MergeContractPO_ContractHeaderForeginKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_PO__c.Original_Contract_Id__c via field Merge_Contract_PO__c.CI_Original_Contract_Id__c     
    */  
    public static void Resolve_MergeContractPO_ContractHeaderForeginKeys(Merge_Contract_PO__c[] orders)
    {
        // Form a Set
        Set<String> contractAkamIdSet = new Set<String>();
        for(Merge_Contract_PO__c order : orders)
        {
            if(order.CI_Original_Contract_Id__c != null && order.CI_Original_Contract_Id__c != '')
                contractAkamIdSet.add(order.CI_Original_Contract_Id__c);
            else
                order.Original_Contract_Id__c = null;
        }
            
        // Query and Create a Map
        Map<String, Id> contractIdMap = new Map<String, Id>();
        for(Merge_Contract_Header__c contract : [select Id, 
                                                        Name
                                                 from Merge_Contract_Header__c
                                                 where Name IN :contractAkamIdSet])
            contractIdMap.put(contract.Name, contract.Id);
                
        // Make the Update
        for(Merge_Contract_PO__c order : orders)
        {
            order.Original_Contract_Id__c = contractIdMap.get(order.CI_Original_Contract_Id__c);
            if((order.CI_Original_Contract_Id__c != '' && order.CI_Original_Contract_Id__c != null) && order.Original_Contract_Id__c == null)
                order.addError('Invalid Contract Header Id : ' + order.CI_Original_Contract_Id__c);
        }
    }
    /** Added by Chandra
        Resolve_Invoice_AccountNameForeginKeys()
        - Resolved the Foreign Key relation of the field Invoice__c.Account_Name__c via field Invoice__c.CI_Account_Name__c     
    */  
    public static void Resolve_Invoice_AccountForeignKeys(List<Invoice__c> invoiceLists)
    {
        // Form a Set
        Set<String> InvoiceAkamIdSet = new Set<String>();
        for(Invoice__c invoicelist : invoiceLists)
        {
            if(invoicelist.CI_Account_Name__c != null && invoicelist.CI_Account_Name__c != '')
                InvoiceAkamIdSet.add(invoicelist.CI_Account_Name__c);
            else
                invoiceList.Account_Name__c = null;
        }
            
        // Query and Create a Map
        Map<String, Id> accountIdMap = new Map<String, Id>();
        for(Account account : [select Id,Akam_Account_Id__c
                                        from Account
                                                 where Akam_Account_Id__c IN :InvoiceAkamIdSet])
            accountIdMap.put(account.Akam_Account_Id__c, account.Id);
                
        // Make the Update
        for(Invoice__c invoiceList : invoiceLists)
        {
            invoiceList.Account_Name__c = accountIdMap.get(invoiceList.CI_Account_Name__c);
            System.debug('Acount Resolve - invoice Name=' + invoiceList.Name);
            System.debug('Acount Resolve - invoice OriginalContractID=' + invoiceList.Original_Contract_Id__c);
            if((invoiceList.CI_Account_Name__c != '' && invoiceList.CI_Account_Name__c !=null) && invoiceList.Account_Name__c == null)
                invoiceList.addError('Invalid Account Id : ' + invoiceList.CI_Account_Name__c);
        }
    }   
    /**
        Added by Chandra
        Resolve_Invoice_ContractHeaderForeignKeys()
        - Resolved the Foreign Key relation of the field Invoice__c.Original_Contract_Id__c via field Invoice__c.CI_Original_Contract_Id__c     
    */  
    public static void Resolve_Invoice_ContractHeaderForeignKeys(List<Invoice__c> invoiceLists)
    {
        System.debug('inside resolve Invoice Original Contract ID');
        // Form a Set
        Set<String> InvoiceAkamIdSet = new Set<String>();
        for(Invoice__c invoicelist : invoiceLists)
        {
            if(invoicelist.CI_Original_Contract_Id__c != null && invoicelist.CI_Original_Contract_Id__c != '')
                InvoiceAkamIdSet.add(invoicelist.CI_Original_Contract_Id__c);
            else
                invoiceList.Original_Contract_Id__c = null;
        }
        // Query and Create a Map
        Map<String, Id> contractIdMap = new Map<String, Id>();
                for(Merge_Contract_Header__c contract : [select Id, 
                                              Name
                                            from Merge_Contract_Header__c
                                            where Name IN :InvoiceAkamIdSet])
                    contractIdMap.put(contract.Name, contract.Id);
                
                // Make the Update
                for(Invoice__c invoiceList : invoiceLists)
                {
                    invoiceList.Original_Contract_Id__c = contractIdMap.get(invoiceList.CI_Original_Contract_Id__c);
                    System.debug('invoice Name=' + invoiceList.Name);
                    System.debug('invoice OriginalContractID=' + invoiceList.Original_Contract_Id__c);
                    if((invoiceList.CI_Original_Contract_Id__c != '' && invoiceList.CI_Original_Contract_Id__c != null) && invoiceList.Original_Contract_Id__c == null)
                        invoiceList.addError('Invalid Contract Header Id : ' + invoiceList.CI_Original_Contract_Id__c);
                }
    }
    /**
        Added by Chandra
        Resolve_Contract_Header_ParentContractHeaderForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Parent_Contract__c via field Merge_Contract_Header__c.CI_Parent_Contract__c       
    */
     public static void Resolve_Contract_Header_ParentContractHeaderForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Parent_Contract__c != null && con.CI_Parent_Contract__c != '')
                contractAkamIdSet.add(con.CI_Parent_Contract__c);
            else
                con.Parent_Contract__c = null;
        }
        
        Map<String, Id> contractIdMap=new Map<String,Id>();
        for(Merge_Contract_Header__c contract : [select Id, Name from Merge_Contract_Header__c where Name IN :contractAkamIdSet])
            {
                contractIdMap.put(contract.Name, contract.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Parent_Contract__c=contractIdMap.get(con.CI_Parent_Contract__c);
            if((con.CI_Parent_Contract__c != '' && con.CI_Parent_Contract__c != null) && con.Parent_Contract__c == null)
                con.addError('Invalid Parent Contract Header Id : ' + con.CI_Parent_Contract__c);
        }
     }
     /**
        Added by Chandra
        Resolve_Contract_Header_AccountForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Account_Name__c via field Merge_Contract_Header__c.CI_Account_Name__c     
    */
     public static void Resolve_Contract_Header_AccountForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractAccountAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Account_Name__c != null && con.CI_Account_Name__c != '')
                contractAccountAkamIdSet.add(con.CI_Account_Name__c);
            else
                con.Account_Name__c = null;
        }
        
        Map<String, Id> contractAccountIdMap=new Map<String,Id>();
        for(Account account : [select Id, Akam_Account_Id__c from Account where Akam_Account_Id__c IN :contractAccountAkamIdSet])
            {
                contractAccountIdMap.put(account.Akam_Account_Id__c, account.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Account_Name__c=contractAccountIdMap.get(con.CI_Account_Name__c);
            if((con.CI_Account_Name__c != '' && con.CI_Account_Name__c != null) && con.Account_Name__c == null)
                con.addError('Invalid Account Id : ' + con.CI_Account_Name__c);
        }
     }
      /**
        Added by Chandra
        Resolve_Contract_Header_BillToContactForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Bill_To_Contact__c via field Merge_Contract_Header__c.CI_Bill_To_Contact__c       
    */
     public static void Resolve_Contract_Header_BillToContactForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractContactAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Bill_To_Contact__c != null && con.CI_Bill_To_Contact__c != '')
                contractContactAkamIdSet.add(con.CI_Bill_To_Contact__c);
            else
                con.Bill_To_Contact__c = null;
        }
        
        Map<String, Id> contractContactIdMap=new Map<String,Id>();
        for(Contact contact : [select Id, Akam_Contact_Id__c from Contact where Akam_Contact_Id__c IN :contractContactAkamIdSet])
            {
                contractContactIdMap.put(contact.Akam_Contact_Id__c, contact.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Bill_To_Contact__c=contractContactIdMap.get(con.CI_Bill_To_Contact__c);
            if((con.CI_Bill_To_Contact__c != '' && con.CI_Bill_To_Contact__c != null) && con.Bill_To_Contact__c == null)
                con.addError('Invalid Contact Id : ' + con.CI_Bill_To_Contact__c);
        }
     }
  /**
        Added by Chandra
        Resolve_Contract_Header_ContractTransferredToForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Contract_Transferred_To__c via field Merge_Contract_Header__c.CI_Contract_Transferred_To__c       
  */
     public static void Resolve_Contract_Header_ContractTransferredToForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractTransferredToAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Contract_Transferred_To__c != null && con.CI_Contract_Transferred_To__c != '')
                contractTransferredToAkamIdSet.add(con.CI_Contract_Transferred_To__c);
            else
                con.Contract_Transferred_To__c = null;
        }
        
        Map<String, Id> contractTransferredToIdMap=new Map<String,Id>();
        for(Merge_Contract_Header__c contract : [select Id, Name from Merge_Contract_Header__c where Name IN :contractTransferredToAkamIdSet])
            {
                contractTransferredToIdMap.put(contract.Name, contract.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Contract_Transferred_To__c=contractTransferredToIdMap.get(con.CI_Contract_Transferred_To__c);
            if((con.CI_Contract_Transferred_To__c != '' && con.CI_Contract_Transferred_To__c != null) && con.Contract_Transferred_To__c == null)
                con.addError('Invalid Contract_Transferred_To Id : ' + con.CI_Contract_Transferred_To__c);
        }
     }  
     
 /**
        Added by Chandra
        Resolve_Contract_Header_OpportunityForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Opportunity_Name__c via field Merge_Contract_Header__c.CI_Opportunity_Name__c     
  */
     public static void Resolve_Contract_Header_OpportunityForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractOpportunityAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Opportunity_Name__c != null && con.CI_Opportunity_Name__c != '')
                contractOpportunityAkamIdSet.add(con.CI_Opportunity_Name__c);
            else
                con.Opportunity_Name__c = null;
        }
        
        Map<String, Id> contractOpportunityIdMap=new Map<String,Id>();
        for(Opportunity opp : [select Id, AKAM_Opportunity_ID__c from Opportunity where AKAM_Opportunity_ID__c IN :contractOpportunityAkamIdSet])
            {
                contractOpportunityIdMap.put(opp.AKAM_Opportunity_ID__c, opp.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Opportunity_Name__c=contractOpportunityIdMap.get(con.CI_Opportunity_Name__c);
            if((con.CI_Opportunity_Name__c != '' && con.CI_Opportunity_Name__c != null) && con.Opportunity_Name__c == null)
                con.addError('Invalid Opportunity Id : ' + con.CI_Opportunity_Name__c);
        }
     }
 /**
        Added by Chandra
        Resolve_Contract_Header_ParentAccountForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Parent_Account_Name__c via field Merge_Contract_Header__c.CI_Parent_Account_Name__c       
  */
     public static void Resolve_Contract_Header_ParentAccountForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractParentAccountAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Parent_Account_Name__c != null && con.CI_Parent_Account_Name__c != '')
                contractParentAccountAkamIdSet.add(con.CI_Parent_Account_Name__c);
            else
                con.Parent_Account_Name__c = null;
        }
        
        Map<String, Id> contractParentAccountIdMap=new Map<String,Id>();
        for(Account acc : [select Id, AKAM_Account_ID__c from Account where AKAM_Account_ID__c IN :contractParentAccountAkamIdSet])
            {
                contractParentAccountIdMap.put(acc.AKAM_Account_ID__c, acc.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Parent_Account_Name__c=contractParentAccountIdMap.get(con.CI_Parent_Account_Name__c);
            if((con.CI_Parent_Account_Name__c != '' && con.CI_Parent_Account_Name__c != null) && con.Parent_Account_Name__c == null)
                con.addError('Invalid Parent_Account Id : ' + con.CI_Parent_Account_Name__c);
        }
     }
 /**
        Added by Chandra
        Resolve_Contract_Header_ReferredByAccountForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Header__c.Referred_By_Account__c via field Merge_Contract_Header__c.CI_Referred_By_Account__c       
  */
     public static void Resolve_Contract_Header_ReferredByAccountForeignKeys(List<Merge_Contract_Header__c> contractList)
     {
        Set<String> contractReferredByAccountAkamIdSet=new Set<String>();
        for(Merge_Contract_Header__c con : contractList)
        {
            if(con.CI_Referred_By_Account__c != null && con.CI_Referred_By_Account__c != '')
                contractReferredByAccountAkamIdSet.add(con.CI_Referred_By_Account__c);
            else
                con.Referred_By_Account__c = null;
        }
        
        Map<String, Id> contractReferredByAccountIdMap=new Map<String,Id>();
        for(Account acc : [select Id, AKAM_Account_ID__c from Account where AKAM_Account_ID__c IN :contractReferredByAccountAkamIdSet])
            {
                contractReferredByAccountIdMap.put(acc.AKAM_Account_ID__c, acc.Id);
            }
        for(Merge_Contract_Header__c con : contractList)
        { 
            con.Referred_By_Account__c=contractReferredByAccountIdMap.get(con.CI_Referred_By_Account__c);
            if((con.CI_Referred_By_Account__c != '' && con.CI_Referred_By_Account__c != null) && con.Referred_By_Account__c == null)
                con.addError('Invalid Referred_By_Account Id : ' + con.CI_Referred_By_Account__c);
        }
     }
     /**
        Added by Chandra
        Resolve_Contract_Detail_ContractHeaderForeignKeys()
        - Resolved the Foreign Key relation of the field Merge_Contract_Detail__c.Original_Contract_Id__c via field Merge_Contract_Header__c.CI_Original_Contract_Id__c     
  */
     public static void Resolve_Contract_Detail_ContractHeaderForeignKeys(List<Merge_Contract_Detail__c> contractDetailList)
     {
        Set<String> contractAkamIdSet=new Set<String>();
        for(Merge_Contract_Detail__c con : contractDetailList)
        {
            if(con.CI_Original_Contract_Id__c != null && con.CI_Original_Contract_Id__c != '')
                contractAkamIdSet.add(con.CI_Original_Contract_Id__c);
            else
                con.Original_Contract_Id__c = null;
        }
        
        Map<String, Id> contractIdMap=new Map<String,Id>();
        for(Merge_Contract_Header__c contract : [select Id, Name from Merge_Contract_Header__c where Name IN :contractAkamIdSet])
            {
                contractIdMap.put(contract.Name, contract.Id);
            }
        for(Merge_Contract_Detail__c con : contractDetailList)
        { 
            con.Original_Contract_Id__c=contractIdMap.get(con.CI_Original_Contract_Id__c);
            if((con.CI_Original_Contract_Id__c != '' && con.CI_Original_Contract_Id__c != null) && con.Original_Contract_Id__c == null)
                con.addError('Invalid Contract Id : ' + con.CI_Original_Contract_Id__c);
        }
     }  

     //SFDC-7449
     public static void populateAKAMFields(List<Merge_Contract_Detail__c> contractDetailList)
     {
        Set<String> contactIDs = new Set<String>();
        Map<String,String> contactLoginMap = new Map<String,String>();

        for(Merge_Contract_Detail__c eachMCD : contractDetailList)
        {
            contactIDs.add(eachMCD.AKAM_Created_By_Id__c);
            contactIDs.add(eachMCD.AKAM_Modified_By_Id__c);
        }

        List<Contact> contactList = [select Akam_Contact_Id__c,Login__c from Contact where Akam_Contact_Id__c in :contactIDs];
        for(Contact eachContact : contactList)
        {
        	if(eachContact.Login__c != null && eachContact.Login__c != '')
            	contactLoginMap.put(eachContact.Akam_Contact_Id__c, eachContact.Login__c.toUpperCase());
        }

        for(Merge_Contract_Detail__c eachMCD : contractDetailList)
        {
            eachMCD.AKAM_Created_By__c = contactLoginMap.get(eachMCD.AKAM_Created_By_Id__c);
            eachMCD.AKAM_Modified_By__c = contactLoginMap.get(eachMCD.AKAM_Modified_By_Id__c);
        }
     }
     
     public static String checkCastIronPolling()
     {
        String res='1:';
        //Features_Toggle__c CastIronMonitoringFeature=Features_Toggle__c.getInstance('IsCastIronMonitoringEnabled');
        Boolean CastIronMonitoringFeature = GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IsCastIronMonitoringEnabled');
        
        String CastIronMonitoringFeatureMsg = GsmUtilClass.featureToggleMsg('IsCastIronMonitoringEnabled');
        
        
        //String castIronPollingExceptions=Gsm_Custom_Settings__c.getInstance('CastIronClass#PollingExceptions').value__c;
      try
      {
       if(CastIronMonitoringFeature || Test.isRunningTest())
       {
        List<CastIron_Polling__c> castIronPollingRecords=[select Id,Name,LastSucessfulRunTime__c from CastIron_Polling__c where Verify_Polling__c = TRUE AND Inactive__c = FALSE];
        //List<CastIron_Polling__c> castIronPollingRecordsToAlert=new List<CastIron_Polling__c>();
        String castIronPollingNames='';
        String msgBody='';
        String msgSub='';
        //String msgBody=Gsm_Custom_Settings__c.getInstance('CastIronClass#AlertMsgBody').value__c;
        //String msgSub=Gsm_Custom_Settings__c.getInstance('CastIronClass#AlertSubject').value__c;
        for(CastIron_Polling__c ciPolling : castIronPollingRecords)
        {
            if(ciPolling.LastSucessfulRunTime__c < DateTime.now().addHours((-1)*Integer.valueOf(GsmUtilClass.getGSMSettingValue('CastIronClass_AlertHourSetting'))))
            {
                castIronPollingNames=castIronPollingNames+ciPolling.Name+',';
            }
        }
        if(castIronPollingNames != '')
        {
            EmailTemplate em=[select Body,Subject from EmailTemplate where DeveloperName=:GsmUtilClass.getGSMSettingValue('CastIronClass_EmailTemplateName')][0];
            
            msgBody=em.Body;
            msgBody=msgBody.replace('##PollingRecords##',castIronPollingNames);
            msgBody=msgBody.replace('##hours##',GsmUtilClass.getGSMSettingValue('CastIronClass_AlertHourSetting'));
            msgBody=msgBody.replaceAll('\n','<br/>');
            msgSub=em.Subject;
            
            res= res+castIronPollingNames;
            //msgBody=msgBody+castIronPollingNames;
            Messaging.SingleEmailMessage msg= new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[]{GsmUtilClass.getGSMSettingValue('CastIronClass_AlertToAddress')});            
            msg.setHtmlBody(msgBody);
            msg.setSubject(msgSub);
            msg.setReplyTo(GsmUtilClass.getGSMSettingValue('CastIronClass_ReplyToAddress'));
            
            msg.setOrgWideEmailAddressId(GsmUtilClass.getGSMSettingValue('CastIronClass_OrgWideAddressId'));
            
            List<Messaging.SendemailResult> mailSentResult=Messaging.sendEmail( new Messaging.SingleEmailMessage[] {msg});
            res=res+'\n Mail sent = ' + mailSentResult[0].isSuccess();
        }
        else
        {
            res= res+' There are no cast iron polling records to alert.';
        }
      }
      else
      {
        res=res+CastIronMonitoringFeatureMsg;
      }
     }
    catch(Exception e)
    {
        res='0:'+ e.getMessage();
    }
        return res;
  }
  
    /** 
        Resolve_Draft_Invoice_ContractHeaderForeignKeys()
        - Resolved the Foreign Key relation of the field Draft_Invoice__c.Original_Contract_Id__c via field Draft_Invoice__c.CI_Original_Contract_Id__c
        - take a snapshot of ContractHeader.Acceptance Date/Opportunity Name/Manual List.       
    */  
    public static void Resolve_Draft_Invoice_ContractHeaderForeignKeys(List<Draft_Invoice__c> pDraftInvoiceList)
    {   
        Set<String> assocContractAkamIdSet = new Set<String>();
        for(Draft_Invoice__c di : pDraftInvoiceList)
            assocContractAkamIdSet.add(di.CI_Original_Contract_Id__c);
            
        // Query and Create a Map
        Map<String, Merge_Contract_Header__c> assoContractsMap = new Map<String, Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c contract : [select Id,Name,Account_Name__c,Original_Contract_Id__c from Merge_Contract_Header__c where Name IN :assocContractAkamIdSet]) 
            {
                assoContractsMap.put(contract.Name, contract);
            }
                
        // Make the Update
        for(Draft_Invoice__c di : pDraftInvoiceList)
        {   
            if(assoContractsMap.containsKey(di.CI_Original_Contract_Id__c))
                di.Original_Contract_Id__c = assoContractsMap.get(di.CI_Original_Contract_Id__c).Id;
                
            if(di.CI_Original_Contract_Id__c != '' && di.Original_Contract_Id__c == null)
            {
                di.addError('Invalid Contract Header Id : ' + di.CI_Original_Contract_Id__c);
            }
            else
            {
                System.debug('invoice Name=' + di.Name);
                System.debug('invoice OriginalContractID=' + di.Original_Contract_Id__c);
                di.Account_Name__c = assoContractsMap.get(di.CI_Original_Contract_Id__c).Account_Name__c;
            }
        }
        
    }
    /**
        Resolving Draft Invoice fields based on Original_Contract_ID__c, 
    */
    public static void Resolve_Draft_Invoice_ByContractHeaderSFId(List<Draft_Invoice__c> pDraftInvoiceContractToResolveList)
    {
        Set<String> diMCHSet=new Set<String>();
        Map<Id,Merge_Contract_Header__c> mchMap = new Map<Id,Merge_Contract_Header__c>();
        for(Draft_Invoice__c di : pDraftInvoiceContractToResolveList)
        {
            diMCHSet.add(di.Original_Contract_Id__c);
        }
        
        for(Merge_Contract_Header__c contract : [select Id, Name, Account_Name__c from Merge_Contract_Header__c where Id IN :diMCHSet])
            {
                mchMap.put(contract.Id, contract);
            }
            
        for(Draft_Invoice__c di : pDraftInvoiceContractToResolveList)
        { 
            if (!mchMap.containsKey(di.Original_Contract_Id__c))
                continue;
            di.Account_Name__c = mchMap.get(di.Original_Contract_Id__c).Account_Name__c;
        }
    }                                               
  
   public static void Resolve_Payment_Invoice_ForeignKeys(List<Payment__c> paymentList)
     {
        Set<String> akamInvoiceIdIdSet=new Set<String>();
        for(Payment__c payment : paymentList)
        {
            if(payment.CI_Akam_Invoice_Id__c != null && payment.CI_Akam_Invoice_Id__c != '')
                akamInvoiceIdIdSet.add(payment.CI_Akam_Invoice_Id__c);
            else
                payment.Invoice_Number__c=null;
        }
        Map<String, Id> InvoiceIdMap=new Map<String,Id>();
        for(Invoice__c inv : [select Id,Name from Invoice__c where Name in :akamInvoiceIdIdSet])
        {
            InvoiceIdMap.put(inv.Name,inv.id);
        }
        for(Payment__c payment: paymentList)
        {
            payment.Invoice_Number__c=InvoiceIdMap.get(payment.CI_Akam_Invoice_id__c);
            System.Debug('Payment Invoice Number: '+payment.Invoice_Number__c);
            if((payment.CI_Akam_Invoice_id__c !='' && payment.CI_Akam_Invoice_id__c !=null) && payment.Invoice_Number__c==null)
            {
             payment.addError('Invalid Invoice Id : '+payment.CI_Akam_Invoice_id__c);
            }
        }
     }
     

     
    public static void updateAccountLastPaymentDetails(List<Payment__c> payList)
   {
        List<Id> invoiceIds=new List<Id>();
        for(Payment__c payment: payList)
        {
            invoiceIds.add(payment.Invoice_Number__c);
        }
       List<Invoice__c> invoiceList=[select Id,Account_Name__c from Invoice__c where id in : invoiceIds];
       Set<Id> invoiceAccountIds=new Set<Id>();
       for(Invoice__c inv : invoiceList)
       {
        invoiceAccountIds.add(inv.Account_Name__c);
       }
       
       //for existing payments 
       List<Payment__c> existingPayments=[select Id,Invoice_Number__c,payment_Date__c,Total_Payment_Amount__c 
                                            from Payment__c 
                                            where Invoice_Number__r.Account_Name__c in :invoiceAccountIds
                                            and Name = 'RECEIPT'];
       Map<Id,Map<Date,List<Double>>> existingInvoicePaymentListMap =new Map<Id,Map<Date,List<Double>>>();
        for(Payment__c epay: existingPayments)
        {
            Map<Date,List<Double>> ePaymentMap=null;
            if(existingInvoicePaymentListMap.containsKey(epay.Invoice_Number__c))
            {
             ePaymentMap=existingInvoicePaymentListMap.get(epay.Invoice_Number__c);         
            }
            else
            {
             ePaymentMap=new Map<Date,List<Double>>();
            }
            List<Double> paymentAmountList=null;
            if(ePaymentMap.containsKey(epay.Payment_Date__c))
            paymentAmountList=ePaymentMap.get(epay.Payment_Date__c);
            else
            paymentAmountList=new List<Double>();
            
            paymentAmountList.add(epay.Total_Payment_Amount__c);
            ePaymentMap.put(epay.Payment_Date__c,paymentAmountList);
            existingInvoicePaymentListMap.put(epay.Invoice_Number__c,ePaymentMap);
        }
        Map<Id,Payment__c> accountLastPaymentMap=new Map<Id,Payment__c>();
        Map<Id,Map<Date,List<Double>>> accountPaymentMap=new Map<Id,Map<Date,List<Double>>>();
        for(Invoice__c inv: invoiceList)
        {
            Map<Date,List<Double>> lastPaymentDateAmounListMap= new Map<Date,List<Double>>();
            if(accountPaymentMap.containsKey(inv.Account_Name__c))
            {
                lastPaymentDateAmounListMap=accountPaymentMap.get(inv.Account_Name__c);
            }
            Map<Date,List<Double>> existingPaymentMap=existingInvoicePaymentListMap.get(inv.Id);
            for(Date d: existingPaymentMap.keySet())
            {
                if(lastPaymentDateAmounListMap.containsKey(d))
                {
                    List<Double> paymentAmountList=lastPaymentDateAmounListMap.get(d);
                    paymentAmountList.addAll(existingPaymentMap.get(d));
                    lastPaymentDateAmounListMap.put(d,paymentAmountList);
                }
            }
            List<Double> paymentlist=null; 
            for(Payment__c payment: payList)
            {
                if(inv.id==payment.Invoice_Number__c)
                {
                    if(lastPaymentDateAmounListMap.containsKey(payment.Payment_Date__c))
                    {
                        paymentlist=lastPaymentDateAmounListMap.get(payment.Payment_Date__c);
                    }
                    else
                        paymentlist=new List<Double>();
                    paymentlist.add(payment.Total_Payment_Amount__c);
                    lastPaymentDateAmounListMap.put(payment.Payment_Date__c,paymentlist);    
                }
                
            }
            if(lastPaymentDateAmounListMap.keySet().size()>0)
            {
              List<Date> lastPaymentDateList=new List<Date>();
              lastPaymentDateList.addAll(lastPaymentDateAmounListMap.keySet());
              lastPaymentDateList.sort();
              Date maxLastPaymentDate=lastPaymentDateList[lastPaymentDateList.size()-1];
              List<Double> LastPaymentAmountList=lastPaymentDateAmounListMap.get(maxLastPaymentDate);
              LastPaymentAmountList.sort();
              Double maxLastPaymentAmount=LastPaymentAmountList[LastPaymentAmountList.size()-1];
              accountPaymentMap.put(inv.Account_Name__c,lastPaymentDateAmounListMap);
              accountLastPaymentMap.put(inv.Account_Name__c,new Payment__c(Payment_Date__c=maxLastPaymentDate,Total_Payment_Amount__c=maxLastPaymentAmount));
            }
         }
         if(accountLastPaymentMap.keyset().size()>0)
         {
            
          Set<Id> accountIds=accountLastPaymentMap.keyset();
          List<Account> accountList=new List<Account>();
          for(Id accId: accountIds)
          {
            Map<Date,List<Double>> debugMap=accountPaymentMap.get(accId);
            Payment__c maxPayment=accountLastPaymentMap.get(accId);
            Account acc=new Account(Id=accId,Last_Payment_Date__c=maxPayment.Payment_Date__c,Last_Payment_Amount__c=maxPayment.Total_Payment_Amount__c);
            accountList.add(acc);
          }
          if(accountList.size()>0)
          {         
            update accountList;
          }
        }                                       
    }                                       
}