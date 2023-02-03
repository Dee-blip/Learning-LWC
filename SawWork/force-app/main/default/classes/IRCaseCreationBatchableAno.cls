/*
    09/May/2016         CR 3400411 - Create a script to find out all eligible IRCA records that are processed by system
    04/May/2017     CR 3619951 - IR Case for missing contracts
*/
global class IRCaseCreationBatchableAno implements Database.Batchable<sObject>
{
    global String query;
    private Invoice_Review_Case_Audit__c ircaAuditRec = new Invoice_Review_Case_Audit__c();
    private Invoice_Review_Case_Audit__c lastIrcaAuditRec;
    private Map<String,List<String>> mchUpsertErrorsMap = new Map<String,List<String>>();
    private Set<String> currentBatchMCHIDSet = new Set<String>();
    private String strError = '';
    private Boolean hasErrors = false;
    private Date invoiceReviewPeriodDate;
    private Boolean firstImport=false;
    private Boolean initialized=false;
    private Id documentId;

    global  IRCaseCreationBatchableAno(Invoice_Review_Case_Audit__c pIrcaAuditRec, Invoice_Review_Case_Audit__c pLastIrcaAuditRec)
    {
        this.ircaAuditRec = pIrcaAuditRec;
        this.invoiceReviewPeriodDate = ircaAuditRec.Invoice_Review_Date__c;
        if (pLastIrcaAuditRec==null)
            firstImport=true;
        else
            this.lastIrcaAuditRec = pLastIrcaAuditRec;
        this.initialized=doInitialize();
        this.documentId = getDocument();
    }

    global database.querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    private Id getDocument(){
        List<Folder> folders = [select id from folder where name = 'Shared Documents'];
        Document d = new Document();
        d.Name = 'IRCaseData_'+DateTime.now().format() + '.csv';
        d.FolderId = folders[0].Id;
        d.Body = Blob.valueOf('OrderId,IRCache_isManual__c,IRCache_isNewInvoice__c,IRCache_isMissingDraftInvCheck__c,IRCache_isMissingFinalInvCheck__c,IRCache_hasThresholdViolation__c,IRCache_hasDraftThresholdViolation__c,Description');
        d.ContentType = 'application/csv';
        d.Type = 'csv';
        insert d;
        return d.Id;
    }

    private void updateDocument(string myContent){
        Document d = [Select Id,Body from Document where Id = :this.documentId];
        d.Body = Blob.valueOf(d.Body.toString() + '\n' + myContent);
        update d;
    }
    public Boolean doInitialize()
    {
        if (this.ircaAuditRec.Invoice_Review_Date__c==null || !this.ircaAuditRec.Import_Status__c.equalsIgnoreCase('Success') || this.ircaAuditRec.Import_End_Date__c==null)
            return false;

            //3668332 : Adding currency__c in the query
        String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c  from Merge_Contract_Manual_Lists__r Order by End_Date__c DESC), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; //limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(invoiceReviewPeriodDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(invoiceReviewPeriodDate.addMonths(-1)) + ')';

        this.query = query;
        return true;
    }

    private void setMchUpsertErrorsMap(String pMchId, String pErrorMsg)
    {
        if (mchUpsertErrorsMap.containskey(pMchId))
               mchUpsertErrorsMap.get(pMchId).add(pErrorMsg);
          else
               mchUpsertErrorsMap.put(pMchId, new String[]{pErrorMsg});
    }

    global void finish(Database.BatchableContext BC)
    {
        // need to write a logic to dump as a CSV
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        try
        {
            System.debug('invoiceReviewPeriodDate=' + IRCaseHelperClass.getDateStringGmt(invoiceReviewPeriodDate));
            System.debug('query=' + query);

            if (!this.initialized)
                return;

            IRCaseCreationData irCaseData = new IRCaseCreationData(scope,ircaAuditRec,lastIrcaAuditRec,'batch');
            irCaseData.initContractData(scope,invoiceReviewPeriodDate);
            irCaseData.initExistingCaseData(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate);
            irCaseData.initOwnerData(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate, irCaseData.getMchIdAccIdMap().values());
            irCaseData.initCurrDraftInvData(irCaseData.getMchIdsSet(),ircaAuditRec.Id, invoiceReviewPeriodDate);
            irCaseData.initFinalInvoices(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate);
            
            if (!irCaseData.getFirstInvoiceImport())
                irCaseData.initLastDraftInvData(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate, lastIrcaAuditRec.Import_Start_Date__c, ircaAuditRec.Import_Start_Date__c,lastIrcaAuditRec.Id); //2867070


            Id unassignedQueueId = irCaseData.getIRQueueByDevName(GSMUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
            List<Case> existingIRCaseList = irCaseData.getExistingIRCaseList();
            Map<Id,Case> existingMCHIdCaseMap = irCaseData.getExistingMCHIdCaseMap();
            Map<Id,Case> mchOldCaseMap = irCaseData.getMchOldCaseMap();

            Set<Id> mchIdsSet = irCaseData.getMchIdsSet();
            List<Merge_Contract_Header__c> mchList = irCaseData.getMchList();
            Map<Id, Merge_Contract_Header__c> mchMap = irCaseData.getMchMap();
            Map<Id,Merge_Contract_Manual_List__c> mchIDManualListMap = irCaseData.getMchIDManualListMap();
            Map<String,Id> manualListUserAliasIdMap = irCaseData.getManualListUserAliasIdMap();
            Map<Id,String> manualListUserIdAliasMap = irCaseData.getManualListUserIdAliasMap();
            Map<Id,Id> mchIdAccIdMap = irCaseData.getMchIdAccIdMap();

            Map<Id,Id> accOwnerIdMap = irCaseData.getAccOwnerIdMap();
            Map<Id,List<AccountTeamMember>> accATMMap = irCaseData.getAccATMMap();
            Map<Id,AccountTeamMember> accIRCaseOwnerATMMap = irCaseData.getAccIRCaseOwnerATMMap();
            Map<Id,AccountTeamMember> accIRCaseEscalOwnerATMMap = irCaseData.getAccIRCaseEscalOwnerATMMap();

            List<Draft_Invoice__c> dIList = irCaseData.getDIList();
            Map<Id,Draft_Invoice__c> dIMap = irCaseData.getDIMap();
            Map<Id,Id> dIMCHIdsMap = irCaseData.getDIMCHIdsMap();
            Map<Id,Id> mCHDIIdsMap = irCaseData.getMCHDIIdsMap();

            //if (!irCaseData.getFirstInvoiceImport())
            Map<Id, Draft_Invoice__c> lastImportDIMap = irCaseData.getLastImportDIMap();
            Map<Id,Id> lastImportDIMCHIdsMap = irCaseData.getLastImportDIMCHIdsMap();
            Map<Id,Id> lastImportMCHDIIdsMap = irCaseData.getLastImportMCHDIIdsMap();

            List<Invoice__c> lastReviewFinalInvoiceList = irCaseData.getLastReviewFinalInvoiceList();
            Map<Id,Invoice__c> lastReviewFinalInvoiceMap = irCaseData.getLastReviewFinalInvoiceMap();
            Map<Id,Id> lastReviewFinalMCHInvoiceIdsMap = irCaseData.getLastReviewFinalMCHInvoiceIdsMap();
            Map<Id,Id> lastReviewFinalInvoiceMCHIdsMap = irCaseData.getLastReviewFinalInvoiceMCHIdsMap();

            Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = irCaseData.getContractIDCaseWrapperMap();
            System.debug(contractIDCaseWrapperMap);

            // check IR Case creation criteria
            //CR 3272721 - commented call to checkForContractChangeBulk
            //IRCaseCreationCriteria.checkForContractChangeBulk(irCaseData, invoiceReviewPeriodDate);
            IRCaseCreationCriteria.checkForManualContractBulk(irCaseData, invoiceReviewPeriodDate);
            IRCaseCreationCriteria.checkForDoubleInvoiceReviewBulk(firstImport,mchList,irCaseData,invoiceReviewPeriodDate, contractIDCaseWrapperMap,accOwnerIdMap,mchIdAccIdMap,accIRCaseEscalOwnerATMMap);
            IRCaseCreationCriteria.checkForMissingInvoiceBulk(irCaseData, invoiceReviewPeriodDate);
            IRCaseCreationCriteria.checkForNewInvoiceBulk(irCaseData, invoiceReviewPeriodDate);
            IRCaseCreationCriteria.checkForNegativeAmountBulk(irCaseData, invoiceReviewPeriodDate);
            //IRCaseCreationCriteria.createCaseThresholdViolation(irCaseData);
            IRCaseCreationCriteria.checkForThresholdViolationBulk(irCaseData, invoiceReviewPeriodDate);
            //CR 3619951
            IRCaseCreationCriteria.checkForMissingPreviousMonthInvoiceBulk(irCaseData, invoiceReviewPeriodDate);
            //System.debug('In Batchable');
            //System.debug('Case Values : '+contractIDCaseWrapperMap.values());
            //Added ckasturi for CR-2684118
            Map<Id,Boolean> activeManualListMap = irCaseData.getActiveManualList();
            List<Id> mchIds = new List<Id>();
            Map<Id, Datetime > manualListCreatedDateMap = new Map<Id, Datetime>();
            for (IRCaseWrapper ircw : contractIDCaseWrapperMap.values())
            {
                mchIds.add(mchMap.get(ircw.contractId).Id);
            }

            List<Merge_Contract_Manual_List__c> mcml = [Select Akam_Created_Date__c, original_contract_id__c from Merge_Contract_Manual_List__c
                                                     where original_contract_id__c IN :mchIds order by akam_created_date__c desc ];

            
            for (Merge_Contract_Manual_List__c mch: mcml) {
                manualListCreatedDateMap.put(mch.original_contract_id__c, mch.Akam_Created_Date__c);
            }
                

            // create Cases
            List<Case> toUpsertCasesList = new List<Case>();
            for (IRCaseWrapper ircw : contractIDCaseWrapperMap.values())
            {
                System.debug('ircW=' + ircw);
                Merge_Contract_Header__c mch = mchMap.get(ircw.contractId);
                currentBatchMCHIDSet.add(mch.Name);
                Draft_Invoice__c assDI;
                Case tempCase = ircw.associatedCase;
                //3668332: Assigning contract currency code to the case currency iso code
                tempCase.CurrencyIsoCode=mchMap.get(ircw.contractId).Currency__c;
                /** Using 'manualListCreatedDate' datetime field to get the latest created manual list
                **  attached to a contract. Defaulting it to a very old date. If manualListCreatedDate > date when the case was approved
                **  the case has to be re-opened.
                **  CR 2965556
                */
                Datetime manualListCreatedDate = Datetime.newInstance(1950, 1, 1);
                //To get the created date of latest manual list


                if(manualListCreatedDateMap.containsKey(mch.Id)) {
                    manualListCreatedDate = manualListCreatedDateMap.get(mch.Id);
                }

                System.debug('manualListCreatedDate: '+manualListCreatedDate);

                if (existingMCHIdCaseMap.containsKey(mch.Id))
                {
                    tempCase=existingMCHIdCaseMap.get(mch.Id);
                    //3668332: Assigning contract currency code to the case currency iso code
                    tempCase.CurrencyIsoCode=mchMap.get(ircw.contractId).Currency__c;
                }
                if (mCHDIIdsMap.containsKey(mch.Id))
                {
                    ircw.associatedDraftInvoice = dIMap.get(mCHDIIdsMap.get(mch.Id));
                    assDI=ircw.associatedDraftInvoice;
                }
                System.debug('assDI=' + assDI);
                //2965556
                if (ircw.isExisting &&
                    ((tempCase.Status.containsIgnoreCase('Rejected') || (tempCase.IR_Escal_Status__c!= null && tempCase.IR_Escal_Status__c.containsIgnoreCase('Rejected'))) && tempCase.IR_Correction_Notes__c == null)) //IRCasesBUG
                {
                    if (assDI!=null)
                    {
                        tempCase.IR_CurrentInvoiceImportDate__c = assDI.CreatedDate;
                        tempCase.IR_CurrentInvoiceAmount__c = assDI.Original_Amount__c;
                        tempCase.IR_CurrentInvoiceNumber__c = assDI.Name;
                    }
                }
                else if (ircw.isExisting && tempCase.Status.containsIgnoreCase('Deferred') && tempCase.IR_Defer_Until__c!=null && tempCase.IR_Defer_Until__c > Date.today())
                {
                    tempCase.Description = IRCaseHelperClass.getFormattedDesc(tempCase.Description, ircw.description);
                    if (assDI!=null)
                    {
                        tempCase.IR_CurrentInvoiceImportDate__c = assDI.CreatedDate;
                        tempCase.IR_CurrentInvoiceAmount__c = assDI.Original_Amount__c;
                        tempCase.IR_CurrentInvoiceNumber__c = assDI.Name;
                    }
                }
                //2965556
                else if (ircw.isExisting && tempCase.Status.containsIgnoreCase('Approved') && (!ircw.hasPaperChange && !mch.Manual_List__c)
                        ||(!ircw.hasPaperChange && (mch.Manual_List__c && manualListCreatedDate < tempCase.Approved_On__c)))
                {
                    if (assDI!=null)
                    {
                        tempCase.IR_CurrentInvoiceImportDate__c = assDI.CreatedDate;
                        tempCase.IR_CurrentInvoiceAmount__c = assDI.Original_Amount__c;
                        tempCase.IR_CurrentInvoiceNumber__c = assDI.Name;
                    }
                }
                else
                {
                    tempCase.Description = IRCaseHelperClass.getFormattedDesc(tempCase.Description, ircw.description);
                    if (accOwnerIdMap.containsKey(mchIdAccIdMap.get(ircw.contractId)))
                        tempCase.IR_Account_Team__c = accOwnerIdMap.get(mchIdAccIdMap.get(mch.Id));
                    if (ircw.isManualInvoice && ircw.ircaseOwnerId!=null)
                        tempCase.OwnerId = ircw.ircaseOwnerId;
                        //else if (accIRCaseOwnerATMMap.containsKey(mchIdAccIdMap.get(mch.Id)) && accIRCaseOwnerATMMap.get(mchIdAccIdMap.get(mch.Id)).User.isActive)
                    //if (!ircw.isExisting && !ircw.isManualInvoice && accIRCaseOwnerATMMap.containsKey(mchIdAccIdMap.get(mch.Id)) && accIRCaseOwnerATMMap.get(mchIdAccIdMap.get(mch.Id)).User.isActive)
                    else if (!ircw.isExisting && !mch.Manual_List__c && accIRCaseOwnerATMMap.containsKey(mchIdAccIdMap.get(mch.Id)) && accIRCaseOwnerATMMap.get(mchIdAccIdMap.get(mch.Id)).User.isActive)
                        tempCase.OwnerId = accIRCaseOwnerATMMap.get(mchIdAccIdMap.get(mch.Id)).UserId;

                    System.debug('tempcase ownerId post assignment=' + tempCase.OwnerId);
                    if (tempCase.OwnerId==null)// && !ircw.isExisting)
                        tempCase.OwnerId = unassignedQueueId;
                    System.debug('tempcase ownerId post Default assignment=' + tempCase.OwnerId);

                    tempCase.IR_Original_Contract_Id__c = ircw.contractId;
                    tempCase.RecordTypeId = irCaseData.getIrRectypesByDevName(GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default'));
                    tempCase.status = GsmUtilClass.GetCustomSettingValue('IR_Status_Default');
                    tempcase.AccountID = mch.Account_Name__c;
                    if (mch.Manual_List__c && mchIDManualListMap.containsKey(mch.Id))
                        tempCase.Contract_Manual_List_Priority__c = mchIDManualListMap.get(mch.Id).Priority__c;
                    if (ircw.hasDoubleInvoiceReview)// && !ircw.isExisting)
                    {
                        tempCase.IR_Escal_Owner__c = ircw.ircaseEscalOwnerId;
                        tempCase.IR_Escal_Status__c = GsmUtilClass.GetCustomSettingValue('IR_EscalStatus_Default');
                    }

                    // cache Fields:
                    tempCase.IRCache_Acceptance_Date__c=mch.Acceptance_Date__c;
                    tempCase.IRCache_AkamOpportunityId__c=mch.Opportunity_Name__r.AKAM_Opportunity_ID__c;
                    tempCase.IRCache_hasDoubleInvoiceReview__c=mch.Double_Invoice_Review__c;

                    if (ircw.isManualInvoice)
                        tempCase.IRCache_isManual__c=ircw.isManualInvoice;
                    if (ircw.isNewDInv)
                        tempCase.IRCache_isNewInvoice__c=ircw.isNewDInv;
                    if (ircw.isMissingInDInv) //2965556
                        tempCase.IRCache_isMissingDraftInvCheck__c=ircw.isMissingInDInv;
                    if (ircw.isMissingInFinalInv)
                        tempCase.IRCache_isMissingFinalInvCheck__c=ircw.isMissingInFinalInv;
                    if (ircw.hasFinalThresholdViolation)
                        tempCase.IRCache_hasThresholdViolation__c=ircw.hasFinalThresholdViolation;//CR 2723520
                    if (ircw.hasDraftThresholdViolation)
                        tempCase.IRCache_hasDraftThresholdViolation__c=ircw.hasDraftThresholdViolation;//CR 2723520
                  if (ircw.isMissingInLastMonthInv)
                      tempCase.IRCache_hasMissingInvoiceLastMonth__c=ircw.isMissingInLastMonthInv;
                    tempCase.Validation_Override__c=true;

                    if (assDI==null)
                        tempCase.IR_Invoice_Date__c = invoiceReviewPeriodDate;
                    else
                    {
                        tempCase.IR_Invoice_Date__c = assDI.Invoice_Date__c;
                        tempCase.IR_CurrentInvoiceAmount__c = assDI.Original_Amount__c;
                        tempCase.IR_CurrentInvoiceNumber__c = assDI.Name;
                        tempCase.IR_CurrentInvoiceImportDate__c = assDI.CreatedDate;
                        tempCase.IR_Invoice_Number__c = assDI.Name;
                    }
                }
                //Added by ckasturi to set the flag for Active Manual List
                if(activeManualListMap.size() > 0){
                    tempCase.Multiple_Manual_Lists__c = activeManualListMap.get(mch.id);
                }

                toUpsertCasesList.add(tempCase);
                System.debug('toUpsertCasesList size=' + toUpsertCasesList.size());
                System.debug('toUpsertCasesList =' + toUpsertCasesList);
                if(toUpsertCasesList.size()>0)
                {
                   for(Case c:toUpsertCasesList){
                        String flags=c.IRCache_isManual__c+','+c.IRCache_isNewInvoice__c+','+c.IRCache_isMissingDraftInvCheck__c+','+c.IRCache_isMissingFinalInvCheck__c+','+c.IRCache_hasThresholdViolation__c+','+c.IRCache_hasDraftThresholdViolation__c+','+c.Description;
                        updateDocument(mchMap.get(c.IR_Original_Contract_Id__c).Name+','+flags);
                   }
                }
            }
        } catch (Exception ex)
        {
            hasErrors=true;
            strError += '\n----\n';
            strError += ex;//ex.getMessage();
            strError += '; Cause=' + ex.getCause();
            strError += '; LineNumber=' + ex.getLineNumber();
            strError += '; StackTrace=' + ex.getStackTraceString();
            strError += '; TypeName=' + ex.getTypeName();
            strError += '\n----\n';
            strError += 'List of MCH Ids in this Batch=' + currentBatchMCHIDSet;
            strError += '\n----\n';
        }
        finally
        {
            if (!hasErrors)
                return;

            if (mchUpsertErrorsMap.size()>0)
            {
                strError += 'Failed Upserts=' + mchUpsertErrorsMap;
                strError += '\n----\n';
            }
        }
    }
}