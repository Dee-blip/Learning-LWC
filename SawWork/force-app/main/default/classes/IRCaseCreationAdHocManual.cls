/**
IRCaseCreationAdHocManual
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This handles Adhoc manual case creation in SFDC.

    @History
    --Developer           --Date            --Change
    Ali KM                06/02/2013        Created the class
    										CR 2068273 - Handles Ad Hoc IR Case creation.
	Ali KM				13/05/2013		CR 2175068 - IR Cases - Case created for Missing Draft Invoice with wrong Description.
											- Ensuring that missing check for 'FinalInvoices' only occures on First Import.
  Ankit Chawla            23/08/2018 -      OTB-765 (#2) Feature to check for Draft and Final Threshold on AdHoc Draft Invoice Generation.
  Ankit Chawla            7/03/2019- SFDC-4414: No flux case should be created for non billable direct customer
  Ankit               13/9/2019      JIRA MOM-951 - Final threshold check should always use previous month final amount from DI
  Ankit               12/02/2021      IRC-21 - Copy over the manual draft's owner to case if case is getting created for the first time
*/
public without sharing class IRCaseCreationAdHocManual
{
    private static Map<String,Id> irQueuesMap;
    private static Map<String,Id> irRectypesMap;
    private static Date reviewDate;

    private static Map<Id,Id> mchIDCaseIDMap = new Map<Id,Id>();
    private static Map<Id,Case> existingCaseMap = new Map<Id,Case>();
    private static Map<Id,Id> mCHIdDIIdMap = new Map<Id,Id>();
    private static Set<Id> mchIdsSet = new Set<Id>();

    private static Map<Id,Id> mchAccIdMap = new Map<Id,Id>();
    private static Map<Id,Merge_Contract_Header__c> mchMap = new Map<Id,Merge_Contract_Header__c>();
    private static Map<Id,Id> accIdOwnerIdMap = new Map<Id,Id>();
    private static Map<Id,Merge_Contract_Manual_List__c> mchIDManualListMap = new Map<Id,Merge_Contract_Manual_List__c>();

    private static List<Draft_Invoice__c> diList = new List<Draft_Invoice__c>();
    private static Map<Id,Draft_Invoice__c> diMap = new Map<Id,Draft_Invoice__c>();
    private static  Map<Id,InvoiceReviewCaseWrapper> contractIDCaseWrapperMap = new  Map<Id,InvoiceReviewCaseWrapper>();

    private static List<Case> toUpsertCasesList = new List<Case>();
    private static Map<String, GSM_Settings__mdt> gsmCustomMetadata = GsmUtilClass.getGSMSettingValue();

    public IRCaseCreationAdHocManual(Draft_Invoice__c[] pToProcessManualDIList, Map<Id,Draft_Invoice__c> pDINewMap)
    {
        diList = pToProcessManualDIList;
        diMap = pDINewMap;

        for (Draft_Invoice__c di : diList)
        {
            mchIdsSet.add(di.Original_Contract_Id__c);
            mCHIdDIIdMap.put(di.Original_Contract_Id__c,di.Id);
        }

        init();
    }

    public static void init()
    {
        reviewDate = diList[0].Invoice_Date__c;
        initIrRectypesMap();
        //initIrQueuesMap();
        initExistingCases();
        initContractAccount();
    }

    public void doService()
    {
        initializeWrapper();
        //OTB-765
        String fluxCheckEnabled = GsmUtilClass.getGSMSettingValue('Enable_Flux_Calculation');
        if(fluxCheckEnabled == 'true'){
          checkThresholdViolation();
        }
        echoClassState();
        createManualCase();
        //updateDIList();
    }

    private static void createManualCase()
    {
        if (contractIDCaseWrapperMap.size()<1)
            return;

        for (InvoiceReviewCaseWrapper ircw : contractIDCaseWrapperMap.values())
        {
            if (!ircw.toUpdateInsert || !ircw.isAdHocManual)
                continue;

            case tempCase = ircw.associatedCase;
            tempCase.IR_Invoice_Number__c = ircw.associatedDraftInvoice.Name;
            tempCase.IR_Invoice_Date__c = ircw.associatedDraftInvoice.Invoice_Date__c;
            tempCase.IR_CurrentInvoiceImportDate__c = ircw.associatedDraftInvoice.CreatedDate;
            tempCase.IR_CurrentInvoiceAmount__c = ircw.associatedDraftInvoice.Original_Amount__c;
            tempCase.IR_CurrentInvoiceNumber__c = ircw.associatedDraftInvoice.Name;
            if(tempCase.OwnerId == null){
              tempCase.OwnerId = ircw.ircaseOwnerId;
            }
            if(ircw.hasDraftThresholdViolation != null ){
              tempCase.IRCache_hasDraftThresholdViolation__c = ircw.hasDraftThresholdViolation;
            }
            if(ircw.hasFinalThresholdViolation != null){
              tempCase.IRCache_hasThresholdViolation__c = ircw.hasFinalThresholdViolation;
            }
            //tempCase.Description =  ircw.description;
            tempCase.IR_Original_Contract_Id__c = ircw.contractId;
            if (ircw.isExisting && tempCase.Description!=null)
            {

                tempCase.Description =  ircw.description + '\n' + ircw.associatedCase.Description;
            }
            else
                tempCase.Description =  ircw.description;
            if (accIdOwnerIdMap.containsKey(mchAccIdMap.get(ircw.contractId)))
                tempCase.IR_Account_Team__c = accIdOwnerIdMap.get(mchAccIdMap.get(ircw.contractId));
            tempCase.RecordTypeId = getIrRectypesByDevName(GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default')); //irCaseRecordTypeId;
            tempCase.status = GsmUtilClass.GetCustomSettingValue('IR_Status_Default');
            tempcase.AccountID = mchAccIdMap.get(ircw.contractId);
            if (mchIDManualListMap.containsKey(ircw.contractId))
                tempCase.Contract_Manual_List_Priority__c = mchIDManualListMap.get(ircw.contractId).Priority__c;
            System.debug('ircw=' + ircw);
            System.debug('tempCase=' + tempCase);
            if(ircw.associatedDraftInvoice != null)
            {
              tempCase.IR_Priority_level__c = IRCaseHelperClass.calculateIRCasePriority(ircw.associatedDraftInvoice.Original_Amount__c , ircw.associatedDraftInvoice.Conversion_Rate_to_USD__c);
            }
            toUpsertCasesList.add(tempCase);
        }

        if (toUpsertCasesList.size()>0)
        {
            Schema.SObjectField f = Case.Fields.Id;
            Database.UpsertResult[] results = Database.upsert(toUpsertCasesList,f,false);
            //insert toUpsertCasesList;
            for(Database.UpsertResult sr:results){
              if(!sr.isSuccess()){
                String strErrorLog = sr.getErrors()[0].getMessage();
                System.debug('Case Upsert Error: '+strErrorLog);
              }
            }
            Map<Id,Id> diIDNewCaseIDMap = new Map<Id,Id>();
            for (Case c : toUpsertCasesList)
            {
                if (mCHIdDIIdMap.containsKey(c.IR_Original_Contract_Id__c))
                    diIDNewCaseIDMap.put(mCHIdDIIdMap.get(c.IR_Original_Contract_Id__c),c.Id);
            }

            if (diIDNewCaseIDMap.size()>0)
            {
                List<Draft_Invoice__c> diToUpdateCaseIdList = new List<Draft_Invoice__c>();
                for (Id invId : diIDNewCaseIDMap.keySet())
                {
                    Id caseId = diIDNewCaseIDMap.get(invId);
                    diToUpdateCaseIdList.add(new Draft_Invoice__c(id=invId,Case__c=caseId,Validation_Override__c=true,processedForIRCase__c=true));
                }

                update diToUpdateCaseIdList;
            }


        }
    }

    private static void initContractAccount()
    {
        for (Merge_Contract_Header__c mch : [Select Name,Account_Name__c,Account_Name__r.OwnerId,Account_Name__r.Owner.isActive,Original_Contract_Id__c,Active__c,Locked__c,Manual_List__c,Double_Invoice_Review__c,Effective_Start_Date__c,
            Effective_End_Date__c,Revision_Effective_Start_Date__c,First_Bill_Run_Date__c,Signed_Date__c,Parent_Account_Name__c,Parent_Contract__c,Cancellation_Date__c,
                Acceptance_Date__c,Accepted_By_First_Name__c,Accepted_By_Last_Name__c, Contract_Type__c, (Select Id, Name,End_Date__c,Priority__c,Owner__c from Merge_Contract_Manual_Lists__r Where
                    End_Date__c!=null Order by End_Date__c DESC limit 1) from Merge_Contract_Header__c where Id IN :mchIdsSet])
                    {
                        mchAccIdMap.put(mch.Id,mch.Account_Name__c);
                        mchMap.put(mch.Id,mch);
                        if (mch.Account_Name__r.Owner.isActive)
                            accIdOwnerIdMap.put(mch.Account_Name__c,mch.Account_Name__r.OwnerId);
                        if (mch.Merge_Contract_Manual_Lists__r.size()>0)
                            mchIDManualListMap.put(mch.Id,mch.Merge_Contract_Manual_Lists__r[0]);
                    }
    }

    private static void initializeWrapper()
    {
        String tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_SFDC_Ad_hoc_Invoice;

        for (Draft_Invoice__c di : diList)
        {
            if(mchIDCaseIDMap.containsKey(di.Original_Contract_Id__c))
            {
            	tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_SFDC_Ad_hoc_Invoice_Existing;
                //di.addError( Label.IR_Error_Duplicate_Manual_Case + existingCaseMap.get(mchIDCaseIDMap.get(di.Original_Contract_Id__c)).IR_Invoice_Number__c);
                contractIDCaseWrapperMap.put(di.Original_Contract_Id__c, (new InvoiceReviewCaseWrapper(existingCaseMap.get(mchIDCaseIDMap.get(di.Original_Contract_Id__c)),di, tempDesc, true, true, di.Original_Contract_Id__c,di.OwnerId, true)));

            }
            else
            {
                contractIDCaseWrapperMap.put(di.Original_Contract_Id__c, (new InvoiceReviewCaseWrapper((new Case()),di,null,tempDesc,true,false,false,false,false,di.Original_Contract_Id__c,di.OwnerId,null,false,false,true, false,false)));
            }
        }
    }

    private static void echoClassState()
    {
        System.Debug('### START - ECHOING CLASS STATE ###');
        System.Debug('irRectypesMap=' + irRectypesMap);
        System.Debug('reviewDate=' + reviewDate);
        System.Debug('irQueuesMap=' + irQueuesMap);
        System.Debug('mchIDCaseIDMap=' + mchIDCaseIDMap);
        System.Debug('existingCaseMap=' + existingCaseMap);
        System.Debug('mchIdsSet=' + mchIdsSet);
        System.Debug('diList=' + diList);
        System.Debug('diMap.size()=' + diMap.size());
        System.Debug('contractIDCaseWrapperMap.size()=' + contractIDCaseWrapperMap.size());
        System.Debug('contractIDCaseWrapperMap.keySet()=' + contractIDCaseWrapperMap.keySet());
        System.Debug('mchAccIdMap=' + mchAccIdMap);
        System.Debug('mchMap.size()=' + mchMap.size());
        System.Debug('accIdOwnerIdMap=' + accIdOwnerIdMap);
        System.Debug('mchIDManualListMap=' + mchIDManualListMap);
        System.Debug('### END - ECHOING CLASS STATE ###');
    }

    private static void initExistingCases()
    {
        for (Case c : [Select Id,IR_Original_Contract_Id__c,IR_Invoice_Number__c,Description, IRCache_hasDraftThresholdViolation__c, IRCache_hasThresholdViolation__c, OwnerId from Case where IR_Invoice_Date__c = :reviewDate AND IR_Original_Contract_Id__c!=null
            AND RecordTypeId IN :irRectypesMap.values() AND IR_Original_Contract_Id__c IN :mchIdsSet])
            {
                mchIDCaseIDMap.put(c.IR_Original_Contract_Id__c,c.Id);
                existingCaseMap.put(c.Id,c);
            }
    }

    public static void initIrRectypesMap()
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

    public static void initIrQueuesMap()
    {
        if (irQueuesMap==null)
        {
            irQueuesMap = new Map<String,Id>();
            List<String> tempStr = new List<String>();
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName'));
            for (Group irGroup : [SELECT Id, DeveloperName FROM Group where Name IN :tempStr and Type = 'Queue'])
                irQueuesMap.put(irGroup.DeveloperName,irGroup.Id);
            System.debug('irQueuesMap=' + irQueuesMap);
        }
    }

    public static Id getIrRectypesByDevName(String pDevName)
    {
        if (irRectypesMap.containsKey(pDevName))
            return irRectypesMap.get(pDevName);
        else
            return null;
    }

    public Map<Id,Id> getMchIDCaseIDMap()
    {
        return mchIDCaseIDMap;
    }

    public Map<Id,Case> getExistingCaseMap()
    {
        return existingCaseMap;
    }

    //OTB-765
    private static void checkThresholdViolation(){
      checkDraftThresholdViolation();
      checkFinalThresholdViolation();
    }

    private static void checkDraftThresholdViolation(){
      String tempDesc = Label.IR_ThresholdViolation_PreviousImport;
      Boolean hasDraftThresholdDiff = false;
      Integer draftInvoiceThresholdPercentage = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_DraftInvThresPercent'));
      Decimal thresholdVal=0.0;
      Decimal amountDiffInUsd = 0.0;

      Map<Id, Draft_Invoice__c> mchIdDIMap = new Map<Id, Draft_Invoice__c>();
      Set<Id> diIDSet = (new Map<Id,SObject>(diList)).keySet();
      System.debug('diIDSet: '+diIDSet);

      List<Draft_Invoice__c> pastDIList = [Select Id, Name, Case__c, CreatedDate, Original_Amount__c, Invoice_Date__c, Invoice_Review_Case_Audit__c, Original_Contract_Id__c, Validation_Override__c FROM Draft_Invoice__c WHERE Original_Contract_Id__c!=null AND Invoice_Date__c!=null AND Invoice_Date__c= :reviewDate AND isDuplicate__c=false AND hasAttachment__c=true
      AND Id NOT IN :diIDSet
      //SFDC-4414: Filter out DIs for non billable direct child contracts
      AND ((NOT Original_Contract_Id__r.contract_type__c like 'Direct%') OR (Billable_Flag__c != 'N'))
      AND Original_Contract_Id__c IN :mchIdsSet Order by CreatedDate Desc];

      Id dIContractId ;

      for (Draft_Invoice__c di : pastDIList){
        if(dIContractId == null || dIContractId != di.Original_Contract_Id__c){
          mchIdDIMap.put(di.Original_Contract_Id__c, di);
        }
        dIContractId = di.Original_Contract_Id__c;
      }

      System.debug('mchIdDIMap: '+mchIdDIMap);
      if(mchIdDIMap.size() < 1)
        return;
      else {
        for (Draft_Invoice__c di : diList){
          Case existingCase;
          InvoiceReviewCaseWrapper ircw = contractIDCaseWrapperMap.get(di.Original_Contract_Id__c);
          if(mchIdDIMap.get(di.Original_Contract_Id__c) == null){
            continue;
          } else {
            Draft_Invoice__c preImportDI = mchIdDIMap.get(di.Original_Contract_Id__c);
            System.debug('preImportDI: '+preImportDI);
            existingCase = existingCaseMap.get(mchIDCaseIDMap.get(di.Original_Contract_Id__c));
            if(existingCase == null || (existingCase!=null && !existingCase.IRCache_hasDraftThresholdViolation__c)){
              if ((di.Original_Amount__c < 0) || preImportDI.Original_Amount__c<0 || di.Original_Amount__c==null
              || preImportDI.Original_Amount__c==null || di.Original_Amount__c == preImportDI.Original_Amount__c || di.Conversion_Rate_to_USD__c==null)
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

              tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + tempDesc.replaceAll('#param1#',thresholdVal.toPlainString());
              ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
              ircw.hasDraftThresholdViolation=true;
              contractIDCaseWrapperMap.put(di.Original_Contract_Id__c, ircw);
            }
          }
        }
      }
    }

    private static void checkFinalThresholdViolation(){
      String tempDesc = Label.IR_ThresholdViolation_PreviousMonth;
      Boolean hasFinalThresholdDiff = false;
      Integer finalInvoiceThresholdPercentage = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_FinalInvThresPercent'));
      Decimal thresholdVal=0.0;
      Decimal prevMonthOutstandingAmount;
      Decimal amountDiffInUsd = 0.0;
      // Invoice__c preImportFinalInvoice;

      Map<Id, Invoice__c> mchIdInvoiceMap = new Map<Id, Invoice__c>();
      Set<Id> diIDSet = (new Map<Id,SObject>(diList)).keySet();
      System.debug('diIDSet: '+diIDSet);
      List<Invoice_Review_Case_Audit__c> irca = [Select Id from Invoice_Review_Case_Audit__c where Invoice_Review_Date__c = :reviewDate ORDER BY CreatedDate LIMIT 1 ];

      Boolean firstImport = false;
      if(irca.size() == 0){
        firstImport = true;
      }

      Id invoiceContractId ;


      for (Draft_Invoice__c di : diList){
        Case existingCase;
        InvoiceReviewCaseWrapper ircw = contractIDCaseWrapperMap.get(di.Original_Contract_Id__c);

        existingCase = existingCaseMap.get(mchIDCaseIDMap.get(di.Original_Contract_Id__c));

        if(firstImport || existingCase == null || (existingCase!=null && !existingCase.IRCache_hasThresholdViolation__c)){

            prevMonthOutstandingAmount = di.Previous_Month_Outstanding_Amount__c;


            String contractType = mchMap.get(di.Original_Contract_Id__c).Contract_Type__c;
            if ((di.Original_Amount__c < 0) || prevMonthOutstandingAmount<0 || di.Original_Amount__c==null
            || prevMonthOutstandingAmount==null || di.Original_Amount__c == prevMonthOutstandingAmount || di.Conversion_Rate_to_USD__c==null ||
            (contractType.contains('Direct')==true && di.billable_flag__c == 'N')) //SFDC-4414
                continue;

            thresholdVal=IRCaseHelperClass.calculateThreshhold(prevMonthOutstandingAmount, di.Original_Amount__c);

            amountDiffInUsd = IRCaseHelperClass.calculateAmountDiffInUsd(prevMonthOutstandingAmount, di.Original_Amount__c, di.Conversion_Rate_to_USD__c);

            if ((thresholdVal>=finalInvoiceThresholdPercentage) && (amountDiffInUsd >= 25000))
            {
                hasFinalThresholdDiff=true;
            }

            System.debug('thresholdVal=' + thresholdVal);
            System.debug('amountDiffInUsd=' + amountDiffInUsd);

            if (!hasFinalThresholdDiff)
                continue;

            tempDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + tempDesc.replaceAll('#param1#',thresholdVal.toPlainString());
            ircw.description = IRCaseHelperClass.getFormattedDesc(ircw.description, tempDesc);
            ircw.hasFinalThresholdViolation=true;
            contractIDCaseWrapperMap.put(di.Original_Contract_Id__c, ircw);
          }
      }
    }
}