/*
 07/Mar/2013        CR 2138851 - IR Rejected cases status remain rejected after the run
                        - Ensure that the Case is processed even if it doesn't qualify for IR Case Criteria in a particular Import run.
 03/Apr/2013        CR 2175626 - IR Case - For multiple manual lists the highest priority value needs to be updated at the case level.
                        - Restricting the Case.Priority field update only if Contract.Manual_List__c = true.
 29/05/2013         CR 2148112 - IR Case - Error Capturing during IR Case creation and alerting enhancements.
                        - added try/catch block for capturing errors and updating the associated IRCA rec with the same.
 27/June/2014       CR 2684118 - Update the logic of creating Case - IRCA
 13/Aug/2014        CR 2723520 - Changing the logic of Threshold case creation so that even if a final invoice is not present,draft invoice
                                 threshold case should be created.
 24/Mar/2015        CR 2867070 - Adding lastIrcaAuditRec.Id in the call to initLastDraftInvData to get the draft invoice linked to the last IRCA
 24/Mar/2015        CR 2965556 - If the case status or Escal status is Rejected  and correction notes are null, then case should not be updated
                                 If there is a contract change, then a case which is already in Approved status, should be reopened.
 29/Jan/2016        CR 3272721 - CMG wanted to stop Cases creation for scenarios of "contract change in the prior month"
 26/Mar/2017        CR 3668332 - Currency for amount on Case is USD even if the associated contract is in another currency.
 04/May/2017    CR 3619951 - IR Case for missing contracts
 15/Oct/2018    JIRA-OTB-765 - Fixing looped query as part of OTB-765
*/
global class IRCaseCreationBatchable implements Database.Batchable<sObject>
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

    global  IRCaseCreationBatchable(Invoice_Review_Case_Audit__c pIrcaAuditRec, Invoice_Review_Case_Audit__c pLastIrcaAuditRec)
    {
        this.ircaAuditRec = pIrcaAuditRec;
        this.invoiceReviewPeriodDate = ircaAuditRec.Invoice_Review_Date__c;
        if (pLastIrcaAuditRec==null)
            firstImport=true;
        else
            this.lastIrcaAuditRec = pLastIrcaAuditRec;
        this.initialized=doInitialize();
    }

    global database.querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
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

    private void updateIRCAWithError(Invoice_Review_Case_Audit__c pIrcaAuditRec, String pStrError)
    {
        System.debug('strError=' + pStrError);
        System.debug('strError len=' + pStrError.length());
        System.debug('ircaAuditRec.Case_Creation_Results__c=' + pIrcaAuditRec.Case_Creation_Results__c);
        if (pIrcaAuditRec.Case_Creation_Results__c!=null && pIrcaAuditRec.Case_Creation_Results__c!='')
            pStrError = pStrError + pIrcaAuditRec.Case_Creation_Results__c;
        if (pStrError.length()>31900)
            pStrError = pStrError.substring(0,31900);
        Invoice_Review_Case_Audit__c irRec = new Invoice_Review_Case_Audit__c(Id=pIrcaAuditRec.Id,Case_Creation_Results__c=pStrError, Case_Creation_Status__c='Error', Case_Creation_Completed__c = true);
        update irRec;
    }

    global void finish(Database.BatchableContext BC)
    {
        //Invoice_Review_Case_Audit__c irRec = new Invoice_Review_Case_Audit__c(Id=ircaAuditRec.Id,Case_Creation_Completed__c = true,Case_Creation_Status__c='Success',Case_Creation_End_Date__c=Datetime.now());
        Invoice_Review_Case_Audit__c irRec = [Select Id, Case_Creation_Status__c, Case_Creation_Results__c, Invoice_Review_Date__c from Invoice_Review_Case_Audit__c where id = :ircaAuditRec.Id];
        irRec.Case_Creation_Completed__c=true;
        irRec.Case_Creation_Status__c='Success';
        irRec.Case_Creation_End_Date__c = Datetime.now();
        update irRec;

        String[] recipientEmailList = GsmUtilClass.GetCustomSettingValue('IRCasesEAlert_RecipientList').split(',');

        String baseURL = [Select Division from Organization Limit 1][0].Division;
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob WHERE Id = :BC.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String[] toAddresses = recipientEmailList;
        mail.setToAddresses(toAddresses);
        mail.setSubject('IRCaseCreationBatchable Apex job is ' + a.Status);
        //mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');

        String strTextBody = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n';
        if (irRec.Case_Creation_Results__c!=null && irRec.Case_Creation_Results__c!='')
            strTextBody += 'For error(s) see IR Case creation summary page: ' + baseURL + '/' + ircaAuditRec.Id;
        else
            strTextBody += 'Link to IR Case creation summary: ' + baseURL + '/' + ircaAuditRec.Id;
        mail.setPlainTextBody(strTextBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        try
        {
            System.debug('invoiceReviewPeriodDate=' + IRCaseHelperClass.getDateStringGmt(invoiceReviewPeriodDate));
            System.debug('query=' + query);

            if (!this.initialized)
                return;
            CaseTriggerClass.isIRCaseCreationInprogress=true;
            IRCaseCreationData irCaseData = new IRCaseCreationData(scope,ircaAuditRec,lastIrcaAuditRec,'batch');
            irCaseData.initContractData(scope,invoiceReviewPeriodDate);
            irCaseData.initExistingCaseData(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate);
            irCaseData.initOwnerData(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate, irCaseData.getMchIdAccIdMap().values());
            irCaseData.initCurrDraftInvData(irCaseData.getMchIdsSet(),ircaAuditRec.Id, invoiceReviewPeriodDate);
            irCaseData.initFinalInvoices(irCaseData.getMchIdsSet(), invoiceReviewPeriodDate);
            irCaseData.initIRcaseInfo(irCaseData.getMchMap(), invoiceReviewPeriodDate,irCaseData.getDIList());
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
            IRCaseCreationCriteria.checkForAlerts(irCaseData);
            //System.debug('In Batchable');
            //System.debug('Case Values : '+contractIDCaseWrapperMap.values());
            //Added ckasturi for CR-2684118
            Map<Id,Boolean> activeManualListMap = irCaseData.getActiveManualList();

            // create Cases
            List<Case> toUpsertCasesList = new List<Case>();
          List<IRCaseWrapper> ircwList = contractIDCaseWrapperMap.values();
          Set<Id> mchIds = new Set<Id>();
          Map<Id, List<Merge_Contract_Manual_List__c>> mchIdMcmlListMap = new Map<Id, List<Merge_Contract_Manual_List__c>>();

          for(IRCaseWrapper ircw : ircwList){
            if(mchMap.get(ircw.contractId) != null){
              mchIds.add(ircw.contractId);
            }
          }

          List<Merge_Contract_Manual_List__c> mcmlList = [Select original_contract_id__c, Akam_Created_Date__c from Merge_Contract_Manual_List__c where original_contract_id__c IN : mchIds order by akam_created_date__c desc];

          ID mchId;
          List<Merge_Contract_Manual_List__c> mlList = new List<Merge_Contract_Manual_List__c>();

          for(Merge_Contract_Manual_List__c mcml : mcmlList ){
            if(mchId != mcml.original_contract_id__c){
              if(mchId != null){
                mchIdMcmlListMap.put(mchId, mlList);
              }
              mchId = mcml.original_contract_id__c;
              mlList = new List<Merge_Contract_Manual_List__c>();
            }
            mlList.add(mcml);
          }

          for (IRCaseWrapper ircw : contractIDCaseWrapperMap.values()){
            System.debug('ircW=' + ircw);
            Merge_Contract_Header__c mch = mchMap.get(ircw.contractId);
            currentBatchMCHIDSet.add(mch.Name);
            Draft_Invoice__c assDI;
            Case tempCase = ircw.associatedCase;
            //3668332: Assigning contract currency code to the case currency iso code
            tempCase.CurrencyIsoCode=mchMap.get(ircw.contractId).Currency__c;

            //assigning the alert type to case if its present
            if(String.IsNotBlank(ircw.alertType)){
              tempCase.IR_Case_Type__c = ircw.alertType;
            }

            /** Using 'manualListCreatedDate' datetime field to get the latest created manual list
            **  attached to a contract. Defaulting it to a very old date. If manualListCreatedDate > date when the case was approved
            **  the case has to be re-opened.
            **  CR 2965556
            */
              Datetime manualListCreatedDate = Datetime.newInstance(1950, 1, 1);
              //To get the created date of latest manual list

              List<Merge_Contract_Manual_List__c> mcml = mchIdMcmlListMap.get(mch.Id);

              if(mcml != null && mcml.size() > 0)
                  manualListCreatedDate = mcml[0].AKAM_Created_Date__c;

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

              // if alert type is not blank which means there is already a formatted description that needs to updated on case
              if(String.IsNotBlank(ircw.alertType)){
                  tempCase.Description = ircw.description;
                }

            if(assDI != null)
            {
              tempCase.IR_Priority_level__c = IRCaseHelperClass.calculateIRCasePriority(assDI.Original_Amount__c , assDI.Conversion_Rate_to_USD__c);
            }
              
            toUpsertCasesList.add(tempCase);
          }
          System.debug('toUpsertCasesList size=' + toUpsertCasesList.size());
          System.debug('toUpsertCasesList =' + toUpsertCasesList);
          if  (toUpsertCasesList.size()>0){
            Schema.SObjectField f = Case.Fields.Id;
            Database.UpsertResult[] results = Database.upsert(toUpsertCasesList,f,false);
            List<Draft_Invoice__c> diToUpdateList = new List<Draft_Invoice__c>();
            Draft_Invoice__c di;// = new Draft_Invoice__c();
            Integer i=0;
            String strErrorLog='';
            for(Database.UpsertResult sr:results)
            {
              di=null;
              System.debug('Case Id=' + toUpsertCasesList[i].Id);
              System.debug('Case ContractID=' + toUpsertCasesList[i].IR_Original_Contract_Id__c);
              if (contractIDCaseWrapperMap.get(toUpsertCasesList[i].IR_Original_Contract_Id__c).associatedDraftInvoice!=null)
                  di = contractIDCaseWrapperMap.get(toUpsertCasesList[i].IR_Original_Contract_Id__c).associatedDraftInvoice;
              System.debug('DI=' + di);
              if(sr.isSuccess())
              {
                  if (di!=null)
                      diToUpdateList.add(new Draft_Invoice__c(id=di.Id,case__c=toUpsertCasesList[i].Id,Validation_Override__c=true,processedForIRCase__c=true));
              }
              else
              {
                hasErrors=true;
                  strErrorLog = sr.getErrors()[0].getMessage();
                  if (mchMap.containsKey(toUpsertCasesList[i].IR_Original_Contract_Id__c))
                    setMchUpsertErrorsMap(mchMap.get(toUpsertCasesList[i].IR_Original_Contract_Id__c).Name, strErrorLog);
              }
              i++;
            }

            System.debug('diToUpdateList size=' + diToUpdateList.size());

            if (diToUpdateList.size()>0)
            {
              i=0;
              strErrorLog='';
              List<Database.SaveResult> updateResults = Database.update(diToUpdateList, false);
                for(Database.SaveResult sr:updateResults)
              {
                if (!sr.isSuccess())
                {
                  hasErrors=true;
                  strErrorLog = sr.getErrors()[0].getMessage();
                  setMchUpsertErrorsMap(diToUpdateList[0].Id, strErrorLog);
                }
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
            updateIRCAWithError(ircaAuditRec, strError);
        }
    }
}