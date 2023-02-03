/**
    @author: Ali KM
    @Description:   Created this class for IR Case functionality. This holds all the IR Case creation
                    criteria that needs be run for all Active/Locked Contracts.
    @History
    --Developer         --Date          --Comments
    Ali KM              4/Apr/2013      CR 2175626 - IR Case - For multiple manual lists the highest priority value needs to be updated at the case level.
    Chakri K            26/June/2014    CR 2684118  - Update the logic of creating Case - IRCA for active Manual List
    Ankit               24/Mar/2015     CR 2867070 - Adding pIrcaAuditRecId in the parameter list of initLastDraftInvData to get the draft invoice linked to the last IRCA
    Ankit               24/Mar/2015     CR 2965556 - If the case status or Escal status is Rejected  and correction notes are null, then case should not be updated
                                                     If there is a contract change, then a case which is already in Approved status, should be reopened.
    Ankit               06/04/2017      CR 3713022 - Removed unused methods to increase code coverage.
*/
public without sharing class IRCaseCreationData
{
    private Invoice_Review_Case_Audit__c ircaAuditRec = new Invoice_Review_Case_Audit__c();
    private Invoice_Review_Case_Audit__c lastInvoiceReviewCaseAuditRec  = new Invoice_Review_Case_Audit__c();
    private Boolean firstInvoiceImport = false;
    private String source = '';

    private List<Case> existingIRCaseList = new List<Case>();
    private Map<Id,Case> existingMCHIdCaseMap = new Map<Id,Case>();
    private Map<Id,Case> mchOldCaseMap = new Map<Id,Case>();

    private Set<Id> mchIdsSet = new Set<Id>();
    private List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
    private Map<Id, Merge_Contract_Header__c> mchMap = new Map<Id,Merge_Contract_Header__c>();
    private Map<Id,Merge_Contract_Manual_List__c> mchIDManualListMap = new Map<Id,Merge_Contract_Manual_List__c>();
    private Map<String,Id> manualListUserAliasIdMap = new Map<String,Id>();
    private Map<Id,String> manualListUserIdAliasMap = new Map<Id,String>();
    private Map<Id,Id> mchIdAccIdMap = new Map<Id,Id>();

    private Map<Id,Id> accOwnerIdMap = new Map<Id,Id>();
    private Map<Id,List<AccountTeamMember>> accATMMap = new Map<Id,List<AccountTeamMember>>();
    private Map<Id,AccountTeamMember> accIRCaseOwnerATMMap = new Map<Id,AccountTeamMember>();
    private Map<Id,AccountTeamMember> accIRCaseEscalOwnerATMMap = new Map<Id,AccountTeamMember>();

    private List<Draft_Invoice__c> dIList = new List<Draft_Invoice__c>();
    private Map<Id,Draft_Invoice__c> dIMap = new Map<Id,Draft_Invoice__c>();
    private Map<Id,Id> dIMCHIdsMap = new Map<Id,Id>();
    private Map<Id,Id> mCHDIIdsMap = new Map<Id,Id>();

    private Map<Id, Draft_Invoice__c> lastImportDIMap = new Map<Id, Draft_Invoice__c>();
    private Map<Id,Id> lastImportDIMCHIdsMap = new Map<Id,Id>();
    private Map<Id,Id> lastImportMCHDIIdsMap = new Map<Id,Id>();

    private List<Invoice__c> lastReviewFinalInvoiceList = new List<Invoice__c>();
    private Map<Id,Invoice__c> lastReviewFinalInvoiceMap = new Map<Id,Invoice__c>();
    private Map<Id,Id> lastReviewFinalMCHInvoiceIdsMap = new Map<Id,Id>();
    private Map<Id,Id> lastReviewFinalInvoiceMCHIdsMap = new Map<Id,Id>();

    private Map<Id,List<String>> mchDataErrorsMap = new Map<Id,List<String>>();
    private Map<String,List<String>> mchUpsertErrorsMap = new Map<String,List<String>>();
    private Map<Id,List<String>> DuplicateDIMap = new Map<Id,List<String>>();

    private Map<String,Id> irQueuesMap;
    private Map<String,Id> irRectypesMap;

    private List<Case> upsertCaseList = new List<Case>();
    private Map<Id,Case> upsertMCHIDCaseMap = new Map<Id,Case>();

    private Map<Id,IRCaseWrapper> contractIDCaseWrapperMap=new Map<Id,IRCaseWrapper>();

    //Added by chakri for CR-
    private Map<Id,Boolean> activeManualList = new Map<Id,Boolean>();

    private Map<String,Id> contractNameIdMap = new Map<String,Id>();
    private Map<Id, List<IR_Case_Info__c>> contractIRCaseInfoMap = new Map<Id, List<IR_Case_Info__c>>();
    private Map<String, Draft_Invoice__c> draftInvNameValueMap = new Map<String, Draft_Invoice__c>();


    public IRCaseCreationData(List<Merge_Contract_Header__c> pMchList, Invoice_Review_Case_Audit__c pIrcaAuditRec, Invoice_Review_Case_Audit__c plastIrcaAuditRec, String pSource)
    {
        this.source = pSource;
        this.mchList = pMchList;
        this.ircaAuditRec = pIrcaAuditRec;
        if (plastIrcaAuditRec==null)
            this.firstInvoiceImport=true;
        else
            lastInvoiceReviewCaseAuditRec = plastIrcaAuditRec;
        System.debug('###Constructor CHECK###');
        System.debug('this.source=' + this.source);
        System.debug('this.mchList.size=' + this.mchList.size());
        System.debug('this.ircaAuditRec=' + this.ircaAuditRec);
        System.debug('this.firstInvoiceImport=' + this.firstInvoiceImport);
        System.debug('this.lastInvoiceReviewCaseAuditRec=' + this.lastInvoiceReviewCaseAuditRec);
        System.debug('###Constructor END###');
        init();
    }

    private void init()
    {
        initIrRectypesMap();
        initIrQueuesMap();
    }

    public void initLastDraftInvData(Set<Id> pMCHIdsSet, Date pInvoiceReviewPeriodDate, DateTime pLastImportStartDate, DateTime pCurrImportStartDate,Id pIrcaAuditRecId) //2867070
    {
        // Last Import Data:
        for (Draft_Invoice__c di : [Select Id,Name,Case__c,CreatedDate,Original_Amount__c,Invoice_Date__c,Invoice_Review_Case_Audit__c,Original_Contract_Id__c,Validation_Override__c, Billable_Flag__c, Previous_Month_Outstanding_Amount__c, Conversion_Rate_to_USD__c, Billable_Invoice_Id__c FROM Draft_Invoice__c WHERE Invoice_Date__c= :pInvoiceReviewPeriodDate AND
            Original_Contract_Id__c!=null AND Invoice_Date__c!=null AND CreatedDate>= :pLastImportStartDate AND CreatedDate<:pCurrImportStartDate AND isDuplicate__c=false
            AND hasAttachment__c=true AND Invoice_Review_Case_Audit__c= :pIrcaAuditRecId AND Original_Contract_Id__c IN :pMCHIdsSet
            //SFDC-4414: Filter out DIs for non billable direct child contracts
            AND ((NOT Original_Contract_Id__r.contract_type__c like 'Direct%') OR (Billable_Flag__c != 'N'))
            Order by CreatedDate Desc])//2867070
            {
                if (lastImportMCHDIIdsMap.containsKey(di.Original_Contract_Id__c))
                    continue;
                lastImportDIMap.put(di.Id,di);
                lastImportDIMCHIdsMap.put(di.Id,di.Original_Contract_Id__c);
                lastImportMCHDIIdsMap.put(di.Original_Contract_Id__c, di.Id);
            }
        System.debug('###initLastDraftInvData CHECK###');
        System.debug('lastImportDIMap=' + lastImportDIMap);
        System.debug('lastImportDIMCHIdsMap=' + lastImportDIMCHIdsMap);
        System.debug('lastImportMCHDIIdsMap=' + lastImportMCHDIIdsMap);
        System.debug('###initLastDraftInvData END###');
    }

    public void initFinalInvoices(Set<Id> pMCHIdsSet, Date pInvoiceReviewPeriodDate)
    {
        for (Invoice__c finalInvoice : [Select Id, Name, Invoice_Date__c,Original_Amount__c,Outstanding_Amount__c,Due_Date__c,Account_Name__c,PO_Number__c,Original_Contract_Id__c, (Select Id from Attachments), (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks)
            from Invoice__c where Invoice_Date__c!=null AND Invoice_Date__c >= :pInvoiceReviewPeriodDate.addMonths(-1) AND Invoice_Date__c < :pInvoiceReviewPeriodDate AND (NOT Name like '9%') AND Original_Contract_Id__c!=null AND CreatedDate = LAST_N_DAYS:90
                AND Original_Contract_Id__c IN :pMCHIdsSet Order By CreatedDate ASC])
                {
                    if (finalInvoice.Attachments.size()==0 && finalInvoice.ContentDocumentLinks.size() == 0)
                        continue;
                    lastReviewFinalInvoiceList.add(finalInvoice);
                    lastReviewFinalInvoiceMap.put(finalInvoice.id,finalInvoice);
                    if(!lastReviewFinalMCHInvoiceIdsMap.containsKey(finalInvoice.Original_Contract_Id__c)){
                      lastReviewFinalInvoiceMCHIdsMap.put(finalInvoice.Id,finalInvoice.Original_Contract_Id__c);
                      lastReviewFinalMCHInvoiceIdsMap.put(finalInvoice.Original_Contract_Id__c, finalInvoice.Id);
                    }
                }
        System.debug('###initFinalInvoices CHECK###');
        System.debug('lastReviewFinalInvoiceList=' + lastReviewFinalInvoiceList);
        System.debug('lastReviewFinalInvoiceMap=' + lastReviewFinalInvoiceMap);
        System.debug('###initFinalInvoices END###');
    }

    public void initCurrDraftInvData(Set<Id> pMCHIdsSet, Id pIrcaAuditRecId, Date pInvoiceReviewPeriodDate)
    {
        // Curr Import Data:
        for(Draft_Invoice__c di : [Select Id,Name,Case__c,CreatedDate,Original_Amount__c,Invoice_Date__c,Invoice_Review_Case_Audit__c,Original_Contract_Id__c,Validation_Override__c, Billable_Flag__c, Previous_Month_Outstanding_Amount__c, Conversion_Rate_to_USD__c, Billable_Invoice_Id__c  FROM Draft_Invoice__c
            Where Original_Contract_Id__c!=null AND Invoice_Date__c!=null AND Invoice_Date__c= :pInvoiceReviewPeriodDate AND isDuplicate__c=false AND hasAttachment__c=true AND CreatedDate=LAST_N_DAYS:60
                AND Invoice_Review_Case_Audit__c= :pIrcaAuditRecId AND Original_Contract_Id__c IN :pMCHIdsSet
                //SFDC-4414: Filter out DIs for non billable direct child contracts
                AND ((NOT Original_Contract_Id__r.contract_type__c like 'Direct%') OR (Billable_Flag__c != 'N'))
                Order by CreatedDate Desc]) //
                {
                    dIList.add(di);
                    dIMap.put(di.id,di);
                    dIMCHIdsMap.put(di.Id,di.Original_Contract_Id__c);
                    mCHDIIdsMap.put(di.Original_Contract_Id__c,di.Id);
                }
        System.debug('### initCurrDraftInvData CHECK###');
        System.debug('pMCHIdsSet='+pMCHIdsSet);
        System.debug('dIList=' + dIList);
        System.debug('dIMap=' + dIMap);
        System.debug('dIMCHIdsMap=' + dIMCHIdsMap);
        System.debug('mCHDIIdsMap=' + mCHDIIdsMap);
        System.debug('###initCurrDraftInvData END###');
    }

    public void initIRcaseInfo(Map<Id,Merge_Contract_Header__c> pMchMap, Date pInvoiceReviewPeriodDate, List<Draft_Invoice__c> dIList){
        //prepare the map with key as Name(original contract id) and value as Id of the contract
       for(Id mchId: pMchMap.keySet())
       {
           contractNameIdMap.put(pMchMap.get(mchId).Name, mchId);
       }

       for(Draft_Invoice__c di: dIList){
           draftInvNameValueMap.put(di.Name, di);
       }
       //query the data from info table with contract ID and inv review date
      // prepare a map with ID contract id and value list ofIR_Case_Info__c records associated to that contract ID
      for(IR_Case_Info__c info: [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                 Invoice_Date__c from IR_Case_Info__c where Order_Id__c IN: contractNameIdMap.keySet() and Invoice_Date__c = :pInvoiceReviewPeriodDate])
       {
           Id mchID = contractNameIdMap.get(info.Order_Id__c);
           List<IR_Case_Info__c> value = new List<IR_Case_Info__c>();
           if (contractIRCaseInfoMap.containsKey(mchID))
           {
             value = contractIRCaseInfoMap.get(mchID);
             value.add(info);
             contractIRCaseInfoMap.put(mchID,value);
           }
           else
           {
              value.add(info);
              contractIRCaseInfoMap.put(mchID,value);
           }
       }
       System.debug(Logginglevel.INFO,'###initIRcaseInfo CHECK###');
       System.debug(Logginglevel.INFO,'contractNameIdMap******' + contractNameIdMap);
       System.debug(Logginglevel.INFO,'contractIRCaseInfoMap**********'+ contractIRCaseInfoMap);
       System.debug(Logginglevel.INFO,'###initIRcaseInfo END###');

   }


    public void initExistingCaseData(Set<Id> pMCHIdsSet, Date pInvoiceReviewPeriodDate)
    {
        for (Case irCase : [Select Id,IR_Case_Locked__c, OwnerId, Description,RecordTypeId,Contract_Manual_List_Priority__c,IR_Defer_Until__c, IR_Escal_Owner__c,IR_Invoice_Number__c,IR_Invoice_Date__c,Status,IR_Escal_Status__c,IR_Original_Contract_Id__c, //2965556
            Validation_Override__c,CreatedDate,IR_CurrentInvoiceAmount__c, IR_CurrentInvoiceImportDate__c, IR_CurrentInvoiceNumber__c, IRCache_Acceptance_Date__c, IRCache_hasDoubleInvoiceReview__c, IRCache_isManual__c,
                IRCache_AkamOpportunityId__c,IRCache_isMissingFinalInvCheck__c, IRCache_isNewInvoice__c, IRCache_hasThresholdViolation__c ,IRCache_hasDraftThresholdViolation__c, IR_Correction_Notes__c,Approved_On__c, IRCache_hasMissingInvoiceLastMonth__c,IR_Case_Type__c  from Case where IR_Invoice_Date__c = :pInvoiceReviewPeriodDate AND
                    IR_Original_Contract_Id__c!=null AND RecordTypeId IN :irRectypesMap.values() AND IR_Original_Contract_Id__c IN :pMCHIdsSet AND CreatedDate=LAST_N_DAYS:30])
                    {
                        existingIRCaseList.add(irCase);
                        existingMCHIdCaseMap.put(irCase.IR_Original_Contract_Id__c, irCase);
                        contractIDCaseWrapperMap.put(irCase.IR_Original_Contract_Id__c, new IRCaseWrapper(irCase.IR_Original_Contract_Id__c,irCase,true));
                    }
        System.debug('### initExistingCaseData CHECK###');
        System.debug('existingIRCaseList=' + existingIRCaseList);
        System.debug('existingMCHIdCaseMap=' + existingMCHIdCaseMap);
        System.debug('contractIDCaseWrapperMap=' + contractIDCaseWrapperMap);
        System.debug('###initExistingCaseData END###');
    }

    public void initOwnerData(Set<Id> pMCHIdsSet, Date pInvoiceReviewPeriodDate, List<Id> pAccIdList)
    {
        List<String> tmpSTR = new List<String>();
        tmpSTR.add(GsmUtilClass.GetCustomSettingValue('IR_EscalOwner_TeamMemberRole'));
        tmpSTR.add(GsmUtilClass.GetCustomSettingValue('IR_Owner_TeamMemberRole'));

        for (Account acc: [Select Id, Name, OwnerId, Owner.Alias, Owner.isActive, (Select Id, IR_Original_Contract_ID__c, OwnerID, Owner.isActive, Owner.Alias From Cases where RecordTypeID IN :irRectypesMap.values()
            AND IR_Invoice_Date__c < :pInvoiceReviewPeriodDate AND IR_Original_Contract_ID__c IN :pMCHIdsSet ORDER BY LastModifiedDate DESC limit 1), (Select Id, AccountId, UserId, User.isActive,
                User.Alias, TeamMemberRole From AccountTeamMembers where TeamMemberRole IN :tmpSTR) From Account Where Id IN :pAccIdList])
                {
                    if (acc.Owner.isActive)
                        accOwnerIdMap.put(acc.Id,acc.OwnerId);
                    System.debug('Cases SiZe=' + acc.Cases.size());
                    if (acc.Cases.size()>0)
                    {
                        System.debug('acc case=' + acc.Cases[0]);
                        mchOldCaseMap.put(acc.Cases[0].IR_Original_Contract_ID__c, acc.Cases[0]);
                    }
                    if (acc.AccountTeamMembers.size()>0)
                    {
                        accATMMap.put(acc.id,acc.AccountTeamMembers);
                    }
                }

        for (Id acc : accATMMap.keySet())
        {
            for (AccountTeamMember atm : accATMMap.get(acc))
            {
                if (atm.TeamMemberRole == GsmUtilClass.GetCustomSettingValue('IR_Owner_TeamMemberRole'))
                    accIRCaseOwnerATMMap.put(acc,atm);
                else if (atm.TeamMemberRole == GsmUtilClass.GetCustomSettingValue('IR_EscalOwner_TeamMemberRole'))
                    accIRCaseEscalOwnerATMMap.put(acc,atm);
            }
        }

        System.debug('###initOwnerData CHECK###');
        System.debug('mchOldCaseMap=' + mchOldCaseMap);
        System.debug('accOwnerIdMap=' + accOwnerIdMap);
        System.debug('accATMMap=' + accATMMap);
        System.debug('accIRCaseOwnerATMMap=' + accIRCaseOwnerATMMap);
        System.debug('accIRCaseEscalOwnerATMMap=' + accIRCaseEscalOwnerATMMap);
        System.debug('### initOwnerData END###');
    }

    public void initContractData(List<Merge_Contract_Header__c> pMchList, Date pInvoiceReviewDate)
    {
        for (Merge_Contract_Header__c mch : pMCHList)
        {
            mchIdsSet.add(mch.Id);
            mchIdAccIdMap.put(mch.Id,mch.Account_Name__c);
            mchMap.put(mch.Id,mch);
            Integer activeCount=0; //Added by ckasturi default active count to 0
            for (Merge_Contract_Manual_List__c mcml: mch.Merge_Contract_Manual_Lists__r)
            {
                if(((mcml.Review_Frequency__c==null || !mcml.Review_Frequency__c.equalsIgnoreCase('one time'))
                            &&
                    ((mcml.Review_Date__c==null && (mcml.End_Date__c==null || (mcml.End_Date__c!=null && mcml.End_Date__c>pInvoiceReviewDate.addMonths(-1))))
                        ||
                    (mcml.Review_Date__c !=null && (mcml.Review_Date__c <= pInvoiceReviewDate && (mcml.End_Date__c==null || (mcml.End_Date__c!=null && mcml.End_Date__c>pInvoiceReviewDate.addMonths(-1)) )))))
                        ||
                   (mcml.Review_Frequency__c!=null && mcml.Review_Frequency__c.equalsIgnoreCase('one time')
                        && ((mcml.Review_Date__c!=null && mcml.Review_Date__c == pInvoiceReviewDate)
                            ||
                    (mcml.Review_Date__c==null && (mcml.End_Date__c==null || (mcml.End_Date__c!=null && mcml.End_Date__c>pInvoiceReviewDate.addMonths(-1)))))))
                            {
                                if (mchIDManualListMap.containsKey(mch.id))
                                {
                                    System.debug('===INSIDE MANUAL LIST MORE THAN ONE CHECK===');
                                    System.debug('contract=' +mch.id+ '; Priority=' + mcml.Priority__c);
                                    System.debug('existing map value for above mchid=' + mchIDManualListMap.get(mch.id));
                                    if (IRCaseHelperClass.isNewPriorityGreater(mchIDManualListMap.get(mch.id).Priority__c, mcml.Priority__c))
                                        mchIDManualListMap.put(mch.id,mcml);
                                    System.debug('after comparision value for above mchid=' + mchIDManualListMap.get(mch.id));
                                    System.debug('===END===');
                                }
                                else
                                {
                                    mchIDManualListMap.put(mch.Id,mcml);
                                    System.debug('===INSIDE NEW MANUAL LIST===');
                                    System.debug('contract=' +mch.id+ '; Priority=' + mcml.Priority__c);
                                    System.debug('existing map value for above mchid=' + mchIDManualListMap.get(mch.id));
                                    System.debug('===END===');
                                }
                                activeCount++;
                            }
            }
            if(activeCount > 1){
                activeManualList.put(mch.id,true);
            }else{
                activeManualList.put(mch.id,false);
            }
        }

        Set<String> manualListOwnerAliasSet = new Set<String>();
        for (Merge_Contract_Manual_List__c mcml : mchIDManualListMap.values())
        {
            if (mcml.Owner__c!=null)
                manualListOwnerAliasSet.add((mcml.Owner__c).trim());
        }

        for (User usr: [Select Id, alias, isActive from User where isActive = true AND alias IN : manualListOwnerAliasSet])
        {
            manualListUserAliasIdMap.put(usr.alias,usr.Id);
            manualListUserIdAliasMap.put(usr.Id,usr.alias);
        }

        System.debug('### initContractData CHECK###');
        System.debug('mchIdAccIdMap=' + mchIdAccIdMap);
        System.debug('mchIdsSet=' + mchIdsSet);
        System.debug('mchList=' + mchList);
        System.debug('mchMap=' + mchMap);
        System.debug('mchIDManualListMap=' + mchIDManualListMap);
        System.debug('manualListUserAliasIdMap=' + manualListUserAliasIdMap);
        System.debug('manualListUserIdAliasMap=' + manualListUserIdAliasMap);
        System.debug('### initContractData END###');
    }

    private void initIrRectypesMap()
    {
        if (irRectypesMap==null)
        {
            irRectypesMap = new Map<String,Id>();
            List<String> tempStr = new List<String>();
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Readonly'));
            for (RecordType recType : [SELECT Id, DeveloperName FROM RecordType where DeveloperName IN :tempStr])
                        irRectypesMap.put(recType.DeveloperName,recType.Id);
            System.debug('irRectypesMap=' + irRectypesMap);
        }
    }

    private void initIrQueuesMap()
    {
        if (irQueuesMap==null)
        {
            irQueuesMap = new Map<String,Id>();
            List<String> tempStr = new List<String>();
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName'));
            for (Group irGroup : [SELECT Id, DeveloperName FROM Group where DeveloperName IN :tempStr and Type = 'Queue'])
                irQueuesMap.put(irGroup.DeveloperName,irGroup.Id);
            System.debug('irQueuesMap=' + irQueuesMap);
        }
    }

    //Getters and setters for the Active Manual List Count
    public void setActiveManualList(Map<Id,Boolean> flag){
        this.activeManualList = flag;
    }
    public Map<Id,Boolean> getActiveManualList(){
        return activeManualList;
    }

    public Boolean getFirstInvoiceImport()
    {
        return firstInvoiceImport;
    }

    public void setExistingIRCaseList( List<Case> pExistingIRCaseList)
    {
        this.existingIRCaseList = pExistingIRCaseList;
    }
    public List<Case> getExistingIRCaseList()
    {
        return existingIRCaseList;
    }


    public Map<Id,Case> getExistingMCHIdCaseMap()
    {
        return existingMCHIdCaseMap;
    }
    public Map<Id,Case> getMchOldCaseMap()
    {
        return mchOldCaseMap;
    }

    public Set<Id> getMchIdsSet()
    {
        return mchIdsSet;
    }

    public List<Merge_Contract_Header__c> getMchList()
    {
        return mchList;
    }

    public Map<Id,Merge_Contract_Header__c> getMchMap()
    {
        return mchMap;
    }

    public List<Draft_Invoice__c> getDIList()
    {
        return dIList;
    }

    public Map<Id,Draft_Invoice__c> getDIMap()
    {
        return dIMap;
    }
    public Map<Id,Merge_Contract_Manual_List__c> getMchIDManualListMap()
    {
        return mchIDManualListMap;
    }

    public Map<String,Id> getManualListUserAliasIdMap()
    {
        return manualListUserAliasIdMap;
    }

    public Map<Id,String> getManualListUserIdAliasMap()
    {
        return manualListUserIdAliasMap;
    }

    public Map<Id,Id> getAccOwnerIdMap()
    {
        return accOwnerIdMap;
    }

    public Map<Id,List<AccountTeamMember>> getAccATMMap()
    {
        return accATMMap;
    }


    public Map<Id,AccountTeamMember> getAccIRCaseOwnerATMMap()
    {
        return accIRCaseOwnerATMMap;
    }

    public Map<Id,AccountTeamMember> getAccIRCaseEscalOwnerATMMap()
    {
        return accIRCaseEscalOwnerATMMap;
    }

    public Map<Id,Id> getMchIdAccIdMap()
    {
        return mchIdAccIdMap;
    }

    public Map<Id,Id> getDIMCHIdsMap()
    {
        return dIMCHIdsMap;
    }

    public Map<Id,Id> getMCHDIIdsMap()
    {
        return mCHDIIdsMap;
    }

    public Map<Id,Draft_Invoice__c> getLastImportDIMap()
    {
        return lastImportDIMap;
    }

    public Map<Id,Id> getLastImportDIMCHIdsMap()
    {
        return lastImportDIMCHIdsMap;
    }

    public Map<Id,Id> getLastImportMCHDIIdsMap()
    {
        return lastImportMCHDIIdsMap;
    }

    public List<Invoice__c> getLastReviewFinalInvoiceList()
    {
        return lastReviewFinalInvoiceList;
    }

    public Map<Id,Invoice__c> getLastReviewFinalInvoiceMap()
    {
        return lastReviewFinalInvoiceMap;
    }
    public Map<Id,Id> getLastReviewFinalMCHInvoiceIdsMap()
    {
        return lastReviewFinalMCHInvoiceIdsMap;
    }

    public Map<Id,Id> getLastReviewFinalInvoiceMCHIdsMap()
    {
        return lastReviewFinalInvoiceMCHIdsMap;
    }

    public Map<Id,IRCaseWrapper> getContractIDCaseWrapperMap()
    {
        return contractIDCaseWrapperMap;
    }
    public void addToContractIDCaseWrapperMap(Id pMchId, IRCaseWrapper pIRCaseWrapper)
    {
        if (!contractIDCaseWrapperMap.containsKey(pMchId))
            contractIDCaseWrapperMap.put(pMchId,pIRCaseWrapper);
    }

    public Id getIRQueueByDevName(String pDevName)
    {
        return irQueuesMap.get(pDevName);
    }
    public Id getIrRectypesByDevName(String pDevName)
    {
        return irRectypesMap.get(pDevName);
    }

     public Map<String,Id> getContractNameIdMap(){
      return contractNameIdMap;
    }

    public Map<Id, List<IR_Case_Info__c>> getContractIRCaseInfoMap(){
      return contractIRCaseInfoMap;
    }

    public Map<String, Draft_Invoice__c> getDraftInvNameValueMap(){
      return draftInvNameValueMap;
    }

}