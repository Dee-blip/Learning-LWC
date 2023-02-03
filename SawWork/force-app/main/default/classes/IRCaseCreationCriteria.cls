/*
    @author: Ali KM
    @Description:   Created this class for IR Case functionality. This holds all the IR Case creation
                    criteria that needs be run for all Active/Locked Contracts.
    @History
    --Developer         --Date          --Comments
    Ali KM              2/Apr/2013      CR 2175230 - Contract paper change not updated for an IR case
                                            -Changed the ContractPaper Change criteria check to look at Acceptance Date/Opportunity AKAM ID
                                            changes from NULL to some value.
    Ali KM              13/05/2013      CR 2175068 - IR Cases - Case created for Missing Draft Invoice with wrong Description.
                                            - Ensuring that missing check for 'FinalInvoices' only occures on First Import.
    Ankit               13/08/14        CR 2723520 - Draft Threshold violation case should still be created if there is no previous month final invoice available.
                                                     Also added another boolean hasDraftThresholdDiff  to capture both Previous Month Final and Current Month Draft Invoice Threshold Case.
    Ankit               24/Mar/2015     CR 2965556 - If the case status or Escal status is Rejected  and correction notes are null, then case should not be updated
                                 If there is a contract change, then a case which is already in Approved status, should be reopened.
    Ankit               06/Apr/2016     CR 3713022 - Improving code coverage of IR classes by removing redundant code. Removed methods checkForContractChangeBulk and createCaseThresholdViolation
    Chakri              04/May/2017     CR 3619951 - IR Case Generation for Contracts
    Ankit               10/10/2018      JIRA OTB-765 - 1. Adding condition to check flux for indirect invoices,
                                                      2. Flux should only get calculated if amount is >= USD 25000
    Ankit               13/9/2019      JIRA MOM-951 - Final threshold check should always use previous month final amount from DI
*/

public without sharing class IRCaseCreationCriteria
{
    public static void checkForManualContractBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    {
        Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
        Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
        List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();
        Map<Id,Case> existingMCHIdCaseMap = pIrCaseData.getExistingMCHIdCaseMap();
        Map<Id,Case> mchOldCaseMap = pIrCaseData.getMchOldCaseMap();
        Map<Id,Merge_Contract_Manual_List__c> mchIDManualListMap = pIrCaseData.getMchIDManualListMap();
        Map<String,Id> manualListUserAliasIdMap = pIrCaseData.getManualListUserAliasIdMap();
        Id unassignedQueueId = pIrCaseData.getIRQueueByDevName(GSMUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
        //Boolean isActiveManualList = pIrCaseData.getActiveManualList();
        for (Merge_Contract_Header__c mch : mchList)
        {
            if (!mch.Manual_List__c)
                continue;
            String tempDesc='';
            Case existingCase;
            Merge_Contract_Manual_List__c assocManualList;
            Id manualCaseOwnerId;
            IRCaseWrapper ircw;

            if (existingMCHIdCaseMap.containsKey(mch.Id))
                existingCase =  existingMCHIdCaseMap.get(mch.Id);
            if (mchIDManualListMap.containsKey(mch.Id))
                assocManualList = mchIDManualListMap.get(mch.Id);
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
                ircw = contractIDCaseWrapperMap.get(mch.Id);

            if (assocManualList!=null && (firstImport || existingCase==null || (existingCase!=null && !existingCase.IRCache_isManual__c)))
            {
                tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_ManualContract;
                if (manualListUserAliasIdMap.containsKey(assocManualList.Owner__c)) // to do: toUpper(); currently it will fail if Owner is in Lower Case.
                    manualCaseOwnerId=manualListUserAliasIdMap.get(assocManualList.Owner__c);
                else
                    manualCaseOwnerId=unassignedQueueId;
                if (ircw!=null)
                {
                    ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                    ircw.isManualInvoice=true;
                    ircw.ircaseOwnerId=manualCaseOwnerId;
                    ircw.toUpdateInsert=true;
                }
                else
                    pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                        new IRCaseWrapper(mch.Id,new Case(),null,tempDesc,true,false,true,false,false,false,false,false,false,false,false,manualCaseOwnerId,null,null,null,null,null,false,null));
            }
        }
    }

    /*
        if (first Import || Case Doesn't Exist || Case.dblInvoiceReview=false)
        {
            if (mch.dblInvReview=true)
            {
                Description: CaseRequiresDoubleInvoiceReview
                Case.dblInvoiceReview=true;
                Escal Status = Pending Review;
                if (ATM contains Servcies Secondary)
                    Escal Owner = ATM Services Secondary
                else if (AccOwnerMap.contains(mch.AccId)
                    Escal owner = Acc Owner
            }
        }
    */
    //public static void checkForDoubleInvoiceReviewBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    public static void checkForDoubleInvoiceReviewBulk(Boolean pFirstImport, List<Merge_Contract_Header__c> pMchList, IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate,
        Map<Id,IRCaseWrapper> pContractIDCaseWrapperMap,Map<Id,Id> pAccOwnerIdMap, Map<Id,Id> pMchIdAccIdMap, Map<Id,AccountTeamMember> pAccIRCaseEscalOwnerATMMap)
        {
            //Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
            //Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
            List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();
            for (Merge_Contract_Header__c mch : pMchList)
            {
                if (!mch.Double_Invoice_Review__c)
                    continue;

                String tempDesc=IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_DoubleInvoiceReview;
                Id escalOwnerId;

                IRCaseWrapper ircw;
                if (pContractIDCaseWrapperMap.containsKey(mch.Id))
                    ircw = pContractIDCaseWrapperMap.get(mch.Id);

                if (pFirstImport || ircw==null || ircw.associatedCase.Id==null || (ircw.associatedCase.Id!=null && !ircw.associatedCase.IRCache_hasDoubleInvoiceReview__c))
                //if (mch.Double_Invoice_Review__c)
                {
                    if (pAccIRCaseEscalOwnerATMMap.containsKey(pMchIdAccIdMap.get(mch.Id)) && pAccIRCaseEscalOwnerATMMap.get(pMchIdAccIdMap.get(mch.Id)).User.isActive)
                        escalOwnerId = pAccIRCaseEscalOwnerATMMap.get(pMchIdAccIdMap.get(mch.Id)).UserId;
                    else if (pAccOwnerIdMap.containsKey(pMchIdAccIdMap.get(mch.Id)))
                        escalOwnerId = pAccOwnerIdMap.get(pMchIdAccIdMap.get(mch.Id));

                    if (ircw!=null)
                    {
                        ircw.ircaseEscalOwnerId=escalOwnerId;
                        ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                        ircw.hasDoubleInvoiceReview=true;
                        ircw.toUpdateInsert=true;
                    }
                    else
                    {
                        pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                                    new IRCaseWrapper(mch.Id,new Case(),null,tempDesc,true,false,false,false,false,false,true,false,false,false,false,null,escalOwnerId,null,null,null,null,false,null));
                    }
                }
            }
        }

    /*
        Run thru Missing Invoice check:
        if (First Import || Case Doesn't Exist)
        {
            if (lastFinalInv.contains(mch) && !currDIMap.contains(mch))
                Description: Missing in this month Import and present in Last Month Invoice.
                case.missingFInalInvcheck=true;

        }
        else if (Case Exists)
        {
            if (lastImport.contains(mch) && !currDIMap.contains(mch))
            {
                Description: Missing in this import, present in last import.
                case.missingLastDraftInvcheck=true;
            }

        }
    */
    public static void checkForMissingInvoiceBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    {
        Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
        Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
        List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();

        Map<Id,Draft_Invoice__c> dIMap = pIrCaseData.getDIMap();
        Map<Id,Id> mCHDIIdsMap = pIrCaseData.getMCHDIIdsMap();

        Map<Id, Draft_Invoice__c> lastImportDIMap = pIrCaseData.getLastImportDIMap();
        Map<Id,Id> lastImportMCHDIIdsMap = pIrCaseData.getLastImportMCHDIIdsMap();

        Map<Id,Invoice__c> lastReviewFinalInvoiceMap = pIrCaseData.getLastReviewFinalInvoiceMap();
        Map<Id,Id> lastReviewFinalMCHInvoiceIdsMap = pIrCaseData.getLastReviewFinalMCHInvoiceIdsMap();

        for (Merge_Contract_Header__c mch : mchList)
        {
            String tempDesc='';
            Boolean missingInvoice=false;

            IRCaseWrapper ircw;
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
                ircw = contractIDCaseWrapperMap.get(mch.Id);
            if (lastReviewFinalMCHInvoiceIdsMap.size()>0 && firstImport)
            {
                if (lastReviewFinalMCHInvoiceIdsMap.containsKey(mch.Id) && !mCHDIIdsMap.containsKey(mch.Id))
                {
                    tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_MissingInvoice_PreviousMonth;
                    if (ircw!=null)
                    {
                        ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                        ircw.isMissingInFinalInv=true;
                        ircw.toUpdateInsert=true;
                    }
                    else
                        pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                            new IRCaseWrapper(mch.Id,new Case(),null,tempDesc,true,false,false,true,false,false,false,false,false,false,false,null,null,null,null,null,null,false,null));
                }
            }
            else if (lastImportMCHDIIdsMap.size()>0 && lastImportMCHDIIdsMap.containsKey(mch.Id) && !mCHDIIdsMap.containsKey(mch.Id))
            {
                tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_MissingInvoice_PreviousImport;
                if (ircw!=null)
                {
                    ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                    ircw.isMissingInDInv=true;
                    ircw.toUpdateInsert=true;
                }
                else
                    pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                        new IRCaseWrapper(mch.Id,new Case(),null,tempDesc,true,false,false,false,true,false,false,false,false,false,false,null,null,null,null,null,null,false,null));
            }
        }
    }
    /*
        if (first Import || Case Doesn't Exist || Case.newInvoice=false)
        {
            if( mch.Inv.size()<1 && currDIMap.contains(mch)
            {
                Description: New Invoice;
                case.newInvoice=true;
            }
        }
    */
    public static void checkForNewInvoiceBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    {
        Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
        Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
        List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();
        Map<Id,Id> mCHDIIdsMap = pIrCaseData.getMCHDIIdsMap();
        Map<Id,Draft_Invoice__c> dIMap = pIrCaseData.getDIMap();


        for (Merge_Contract_Header__c mch : mchList)
        {
            if (mCHDIIdsMap.size()<1)
                break;

            String tempDesc=IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_NewCustomer;
            Boolean isNewInvoice=false;
            IRCaseWrapper ircw;
            Draft_Invoice__c di;
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
            {
                ircw=contractIDCaseWrapperMap.get(mch.Id);
                System.debug('ircw.associatedCase=' + ircw.associatedCase);
            }

            System.Debug('mch ircw)=' + ircw);
            System.Debug('mch Name)=' + mch.Name);
            System.Debug('mCHDIIdsMap.containsKey(mch.Id)=' + mCHDIIdsMap.containsKey(mch.Id));
            System.Debug('mch.Invoices__r.size()==0' + mch.Invoices__r.size());

            if (firstImport || ircw==null || (ircw!=null && ircw.associatedCase.Id==null))// || ircw==null || (ircw!=null && ircw.associatedCase.Id!=null && !ircw.associatedCase.IRCache_isNewInvoice__c))
            {
                System.debug('mch.Invoices__r.size()=' + mch.Invoices__r.size());
                System.debug('mCHDIIdsMap=' + mCHDIIdsMap);
                System.debug('mmCHDIIdsMap.containsKey(mch.Id)=' + mCHDIIdsMap.containsKey(mch.Id));
                di = dIMap.get(mCHDIIdsMap.get(mch.Id));
                if (mCHDIIdsMap.containsKey(mch.Id) && mch.Invoices__r.size()==0 && di.billable_flag__c == 'Y')
                {
                    if (ircw!=null)
                    {
                        ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                        ircw.toUpdateInsert=true;
                        ircw.isNewDInv=true;
                        ircw.associatedDraftInvoice=di;
                    }
                    else
                        pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                            new IRCaseWrapper(mch.Id,new Case(),di,tempDesc,true,false,false,false,false,true,false,false,false,false,false,null,null,null,null,null,null,false,null));
                }
            }
        }
    }
    public static void checkForNegativeAmountBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    {
        Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
        Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
        List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();
        Map<Id,Id> mCHDIIdsMap = pIrCaseData.getMCHDIIdsMap();
        Map<Id,Draft_Invoice__c> dIMap = pIrCaseData.getDIMap();

        for (Merge_Contract_Header__c mch : mchList)
        {
            if (mCHDIIdsMap.size()<1)
                break;
            if (!mCHDIIdsMap.containsKey(mch.Id))
                continue;

            String tempDesc=IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_NegativeInvoice;
            IRCaseWrapper ircw;
            Draft_Invoice__c di = dIMap.get(mCHDIIdsMap.get(mch.Id));
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
                ircw=contractIDCaseWrapperMap.get(mch.Id);

            if (di.Original_Amount__c<0)
            {
                if (ircw!=null)
                {
                    ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                    ircw.toUpdateInsert=true;
                    ircw.associatedDraftInvoice=di;
                }
                else
                    pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                            new IRCaseWrapper(mch.Id,new Case(),di,tempDesc,true,false,false,false,false,false,false,false,false,false,false,null,null,null,null,null,null,false,null));
            }
        }
    }
    public static void checkForThresholdViolationBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    {
        Integer finalInvoiceThresholdPercentage = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_FinalInvThresPercent')); //CR 2723520
        Integer draftInvoiceThresholdPercentage = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_DraftInvThresPercent')); //CR 2723520

        Decimal prevMonthOutstandingAmount;
        Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
        Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
        List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();
        Map<Id,Id> mCHDIIdsMap = pIrCaseData.getMCHDIIdsMap();
        Map<Id,Draft_Invoice__c> dIMap = pIrCaseData.getDIMap();

        Map<Id, Draft_Invoice__c> lastImportDIMap = pIrCaseData.getLastImportDIMap();
        Map<Id,Id> lastImportMCHDIIdsMap = pIrCaseData.getLastImportMCHDIIdsMap();

        Map<Id,Case> existingMCHIdCaseMap = pIrCaseData.getExistingMCHIdCaseMap();

        for (Merge_Contract_Header__c mch : mchList)
        {
            //if (mCHDIIdsMap.size()<1)
                //break;
            if (!mCHDIIdsMap.containsKey(mch.Id))
                continue;

            String tempDesc = Label.IR_ThresholdViolation_PreviousMonth;
            //
            Boolean hasFinalThresholdDiff = false;
            Decimal thresholdVal=0.0;
            Decimal amountDiffInUsd = 0.0;
            Draft_Invoice__c di = dIMap.get(mCHDIIdsMap.get(mch.Id));
            System.debug('di=' + di);
            System.debug('firstImport: '+firstImport);

            IRCaseWrapper ircw;
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
                ircw=contractIDCaseWrapperMap.get(mch.Id);

            Case existingCase;
            if (existingMCHIdCaseMap.containsKey(mch.Id))
                existingCase=existingMCHIdCaseMap.get(mch.Id);


            if (firstImport || existingCase==null || (existingCase!=null && !existingCase.IRCache_hasThresholdViolation__c))
            {
              prevMonthOutstandingAmount = di.Previous_Month_Outstanding_Amount__c;

              System.debug('prevMonthOutstandingAmount= '+prevMonthOutstandingAmount);
               if ((di.Original_Amount__c<0) || (prevMonthOutstandingAmount<0 || di.Original_Amount__c==null
              || prevMonthOutstandingAmount==null || di.Original_Amount__c==prevMonthOutstandingAmount))
                  continue;

              thresholdVal=IRCaseHelperClass.calculateThreshhold(prevMonthOutstandingAmount,di.Original_Amount__c);

              amountDiffInUsd = IRCaseHelperClass.calculateAmountDiffInUsd(prevMonthOutstandingAmount, di.Original_Amount__c, di.Conversion_Rate_to_USD__c);

              if ((thresholdVal>=finalInvoiceThresholdPercentage) && (amountDiffInUsd >= 25000))
              {
                  hasFinalThresholdDiff=true;
              }

              System.debug('thresholdVal=' + thresholdVal);
              System.debug('amountDiffInUsd=' + amountDiffInUsd);

              if (!hasFinalThresholdDiff)
                  continue;

              System.debug('hasFinalThresholdDiff: '+hasFinalThresholdDiff);
              tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + tempDesc.replaceAll('#param1#',thresholdVal.toPlainString());
              if (ircw!=null)
              {
                  //System.debug('ircw NOT NULL : hasFinalThresholdDiff TRUE');
                  ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                  ircw.toUpdateInsert=true;
                  ircw.associatedDraftInvoice=di;
                  ircw.hasFinalThresholdViolation=true;
              }
              else
                  //System.debug('ircw IS NULL : hasFinalThresholdDiff TRUE');
                  pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                          new IRCaseWrapper(mch.Id,new Case(),di,tempDesc,true,false,false,false,false,false,false,false,false,true,false,null,null,null,null,null,null,false,null));
            }
        }

        for (Merge_Contract_Header__c mch : mchList)
        {
            if (mCHDIIdsMap.size()<1)
                break;
            if (!mCHDIIdsMap.containsKey(mch.Id)){
                continue;
            }
            if (!lastImportMCHDIIdsMap.containsKey(mch.Id)){
                continue;
            }
            String tempDesc = Label.IR_ThresholdViolation_PreviousImport;
            Boolean hasDraftThresholdDiff = false;
            Decimal thresholdVal=0.0;
            Decimal amountDiffInUsd = 0.0;
            Draft_Invoice__c di = dIMap.get(mCHDIIdsMap.get(mch.Id));
            System.debug('DraftThreshold DI: '+di);
            Draft_Invoice__c preImportDI = lastImportDIMap.get(lastImportMCHDIIdsMap.get(di.Original_Contract_Id__c));
            System.debug('DraftThreshold preImportDI: '+preImportDI);
            IRCaseWrapper ircw;
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
                ircw=contractIDCaseWrapperMap.get(mch.Id);

            Case existingCase;
            if (existingMCHIdCaseMap.containsKey(mch.Id))
                existingCase=existingMCHIdCaseMap.get(mch.Id);

                if ((preImportDI!=null) && (existingCase == null || (existingCase!=null && !existingCase.IRCache_hasDraftThresholdViolation__c))) //CR 2723520
            {
                if ((di.Original_Amount__c<0) || preImportDI.Original_Amount__c<0 || di.Original_Amount__c==null
                || preImportDI.Original_Amount__c==null || di.Original_Amount__c==preImportDI.Original_Amount__c)
                    continue;

                thresholdVal = IRCaseHelperClass.calculateThreshhold(preImportDI.Original_Amount__c,di.Original_Amount__c);

                amountDiffInUsd = IRCaseHelperClass.calculateAmountDiffInUsd(preImportDI.Original_Amount__c, di.Original_Amount__c, di.Conversion_Rate_to_USD__c);

                if ((thresholdVal>=draftInvoiceThresholdPercentage) && (amountDiffInUsd >= 25000))
                {
                    hasDraftThresholdDiff=true;
                }

                System.debug('thresholdVal=' + thresholdVal);
                System.debug('amountDiffInUsd=' + amountDiffInUsd);

                if (!hasDraftThresholdDiff)
                    continue;

                System.debug('hasDraftThresholdDiff: '+hasDraftThresholdDiff);
                tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + tempDesc.replaceAll('#param1#',thresholdVal.toPlainString());
                if (ircw!=null)
                {
                    //System.debug('ircw NOT NULL : hasDraftThresholdDiff TRUE');
                    ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                    ircw.toUpdateInsert=true;
                    ircw.associatedDraftInvoice=di;
                    ircw.hasDraftThresholdViolation=true;
                }
                else
                    //System.debug('ircw IS NULL : hasDraftThresholdDiff TRUE');
                    pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                            new IRCaseWrapper(mch.Id,new Case(),di,tempDesc,true,false,false,false,false,false,false,false,false,false,true,null,null,null,null,null,null,false,null));
            }
        }
    }

    //CR 3619951
    public static void checkForMissingPreviousMonthInvoiceBulk(IRCaseCreationData pIrCaseData, Date pInvoiceReviewDate)
    {
        Boolean firstImport = pIrCaseData.getFirstInvoiceImport();
        Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
        List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();

        Map<Id,Draft_Invoice__c> dIMap = pIrCaseData.getDIMap();
        Map<Id,Id> mCHDIIdsMap = pIrCaseData.getMCHDIIdsMap();

        Map<Id, Draft_Invoice__c> lastImportDIMap = pIrCaseData.getLastImportDIMap();
        Map<Id,Id> lastImportMCHDIIdsMap = pIrCaseData.getLastImportMCHDIIdsMap();

        Map<Id,Id> lastReviewFinalMCHInvoiceIdsMap = pIrCaseData.getLastReviewFinalMCHInvoiceIdsMap();

        for (Merge_Contract_Header__c mch : mchList)
        {
            String tempDesc='';
            Boolean missingInvoice=false;

            IRCaseWrapper ircw;
            if (contractIDCaseWrapperMap.containsKey(mch.Id))
                ircw = contractIDCaseWrapperMap.get(mch.Id);
                if (mch != null && !lastReviewFinalMCHInvoiceIdsMap.containsKey(mch.Id) && mCHDIIdsMap.containsKey(mch.Id)
                   && ((ircw!=null && ircw.associatedCase.IRCache_hasMissingInvoiceLastMonth__c  == false)|| ircw == null)
                   && mch.Invoices__r.size()>0 && dIMap.get(mCHDIIdsMap.get(mch.Id)).billable_flag__c == 'Y')
                {
                    tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_MissingInvoice_LastMonth;
                    if (ircw!=null)
                    {
                        ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
                        ircw.isMissingInLastMonthInv=true;
                        ircw.toUpdateInsert=true;
                    }
                    else
                        pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                            new IRCaseWrapper(mch.Id,new Case(),null,tempDesc,true,false,false,false,false,false,false,false,false,false,false,null,null,null,null,null,null,true,null));
                }

        }
    }

    //MOM-1877
    public static void checkForAlerts(IRCaseCreationData pIrCaseData){
      List<Merge_Contract_Header__c> mchList = pIrCaseData.getMchList();
      Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();
      Map<Id, List<IR_Case_Info__c>> contractIRCaseInfoMap = pIrCaseData.getContractIRCaseInfoMap();
      Map<String, Draft_Invoice__c> draftInvNameValueMap= pIrCaseData.getDraftInvNameValueMap();
      //check if mch in there in the map
      for (Merge_Contract_Header__c mch : mchList)
      {
        if(contractIRCaseInfoMap.containsKey(mch.Id) && contractIRCaseInfoMap.get(mch.Id) != null && contractIRCaseInfoMap.get(mch.Id).size() > 0){

          IRCaseWrapper ircw;
          if (contractIDCaseWrapperMap.containsKey(mch.Id))
          {
            ircw = contractIDCaseWrapperMap.get(mch.Id);
          }

          // Get the initial description as concatenation of already associated case decription and also those descrition
           // that could have got appended in the previous criteria to process in this method
          String tempDesc = ircw != null ? IRCaseHelperClass.getFormattedDesc(ircw.associatedCase.Description, ircw.description) : '';

           //Get the initial alert type as the one associated to the case existing if there is a case already existing
          String tempAlertType = ircw != null ? ircw.associatedCase.IR_Case_Type__c : '';

          Draft_Invoice__c associatedDraftInv = new Draft_Invoice__c();

          for(IR_Case_Info__c info: contractIRCaseInfoMap.get(mch.Id)){
            //String alertDescription = info.Alert_Line__c;
            associatedDraftInv = draftInvNameValueMap.get(info.Billable_Invoice_Id__c);


            Boolean isExistingType = false;

            //Check if the alert type is already associated to case
            if(ircw != null && String.IsNotBlank(ircw.associatedCase.IR_Case_Type__c)){
                isExistingType = ircw.associatedCase.IR_Case_Type__c.contains(info.Alert_Name__c);
           }

            //skip for this condition as for the below conditions where there is not alert already existing and the flag is N then we skip
            if(ircw != null && !isExistingType && info != null && info.Active_Flag__c != null &&  info.Active_Flag__c == false) {
              continue;
            }

            //skip those info record whose flag is N and there is not case present for the contract
            if(ircw == null && info != null && info.Active_Flag__c != null && info.Active_Flag__c == false){
              continue;
            }

            String alertDescriptionToInsert = IRCaseHelperClass.fetchNowInGMTDateTime() + info.Alert_Line__c;
            tempDesc = IRCaseHelperClass.getReplacedOrInsertedDescription(tempDesc, alertDescriptionToInsert, info.Alert_Name__c);

            if(!isExistingType){
              tempAlertType = String.IsNotBlank(tempAlertType) ? (tempAlertType + ';' + info.Alert_Name__c) : info.Alert_Name__c;
            }
          }
          if(ircw != null && String.IsNotBlank(tempDesc) && String.IsNotBlank(tempAlertType) ){
            ircw.description = tempDesc;
            ircw.alertType = tempAlertType;
            ircw.associatedDraftInvoice = associatedDraftInv;
            ircw.toUpdateInsert=true;
          }
          else{
            //create new case only if the tempDesc or TempAlert is populated, it gets populated only if there is an info record with active falg true
            if(String.IsNotBlank(tempDesc) && String.IsNotBlank(tempAlertType)){
              pIrCaseData.addToContractIDCaseWrapperMap(mch.Id,
                  new IRCaseWrapper(mch.Id,new Case(),associatedDraftInv,tempDesc,true,false,false,false,false,false,false,false,false,false,false,null,null,null,null,null,null,false,tempAlertType));
            }
          }

        }
      }
    }

}