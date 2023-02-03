/**
IRCaseHelperClass
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This is util class for IR Case flow.

    @History
    --Developer         --Date          --Change
    Ali KM              06/02/2013      Created the class
                                        CR 2068273 - Invoice Review Cases Process migration from Siebel to SF.
    Ali KM              4/Apr/2013      CR 2175626 - IR Case - For multiple manual lists the highest priority value needs to be updated at the case level.
    Ali KM              24/04/2013      CR 2175590 - IR Case - Remove fields from New Draft Page.
                                        - Added helper methods to set Default Invoice Date
    Ali KM              24/04/2013      CR 2175581 - IR Case - For Ad hoc Manual Draft Invoices, auto-populate the Invoice number.
                                        - Auto-populate Invoice Number for Ad-hoc Case creation.
    Ali KM              13/05/2013      CR 2219258 - IR Case - Update the logic for Invoice Date defaulting for Ad-hoc IR Case creation
                                        - Calculating the Invoice Review Date based on: Last successfull IRCAudit record, if not found then based on cut-off DayOfMonth.
    Ali KM              30/05/2013      CR 2204912 - IR Case - Lock Screen VF giving - Time Limit Exceeded message.
                                        - Moving the IR Case lockdown to @future method call.
    Sripad              04/02/2014      CR 2486721 - Change data type on field Case.Manual Invoice Approved Date to DateTime Field
                                        -Commented old field and added new date time field in the update
    Ankit               06/04/2017      CR 3713022 - Updating method so that it can be called in IRCasesTestClass. Improving code coverage.
    Ankit               04/06/2019      -JIRA: IRC-1 Optimized the loop
	Ankit				23/09/2019		-JIRA: MOM-980 Removed lockIRCasesFuture method and created IRCaseLockQueueable and IRCaseLockClass classes for batch processing of IRCase lock
*/
global class IRCaseHelperClass
{
    private static Map<String,Id> irQueuesMap =new Map<String,Id>();
    public static void restrictDelete(List<sObject> so)
    {
        for (Sobject s : so)
        {
            if (!GsmUtilClass.GetCustomSettingValue('AccountDelete', 'EnabledProfileId').contains(UserInfo.getProfileId()))
                s.addError(Label.IR_Insufficient_Delete_AccessErrorMessage);
        }
    }

    public static String fetchNowInGMTDateTime()
    {
        return datetime.now().format('MM-dd-yyyy K:mm a z ','GMT');
    }

    public static Set<Id> diffP1MinusP2(Set<Id> p1, Set<Id> p2)
    {
        Set<Id> onlyP1 = new Set<Id>();
        System.debug('p1=' + p1);
        System.debug('p2=' + p2);
        for (Id p1Id : p1)
        {
            if (!p2.contains(p1Id))
                onlyP1.add(p1Id);
        }
        System.debug('onlyP1=' + onlyP1);
        return onlyP1;
    }

    /*
        Priority levels:
            1 - ASAP
            2 - High
            3 - Medium
        Implying Priority 1 is higher than 2 & 3 and so on.
    */
    public static Boolean isNewPriorityGreater(String currPriority, String newPriority)
    {
        Boolean newIsGreater=false;
        try
        {
            if (Integer.valueOf(newPriority.left(1))<Integer.valueOf(currPriority.left(1)))
                newIsGreater=true;

            return newIsGreater;
        }
        catch (Exception ex)
        {
         System.debug('exception msg=' + ex.getMessage());
         return newIsGreater;
        }
    }

    public static Decimal calculateThreshhold(Decimal oldAmt, Decimal currAmt)
    {
        if (oldAmt==0)
            return (currAmt * 100);
        else
        {
            System.debug('threshold val' + (math.abs(oldAmt - currAmt) * 100).Divide(oldAmt,2));
            return ((math.abs(oldAmt - currAmt) * 100).Divide(oldAmt,2));
        }
    }

    public static Decimal calculateAmountDiffInUsd(Decimal oldAmt, Decimal currAmt, Decimal conversionRateToUsd)
    {
        return (math.abs(oldAmt - currAmt) * conversionRateToUsd);
    }


     /**
        Invoice Review Cases code below.... @todo: Move it to respective class.
    */
    /**
        btnExecute()
        - Used to invoke apex code on Cases via buttons.
    */
    WebService static String btnExecute(String pAction, String pCaseId, Id pCaseOwnerId)
    {
        if (pAction.equals('FIN-US') || pAction.equals('FIN-Intl'))
            return updateIRCaseOwner(pAction, pCaseId, pCaseOwnerId);
        else if (pAction.equals('manualIRCaseApproval'))
            return manualIRCaseApproval(pCaseId);
        else
            return '0:Action undefined';
    }

    /**
        manualIRCaseApproval
        - update Case Owner to IR Case Queues.
    */
    public static String manualIRCaseApproval(Id pCaseId)//, Decimal pAmount, String pManualContract)
    {
        if (!hasIRCaseBtnAccess(userinfo.getProfileID()))
            return '0:Insufficient Access';
        //else if (pAmount<0 || pManualContract.EqualsIgnoreCase('No'))
            //return '0:' + Label.IR_Case_Does_Not_Qualify_For_Manual_Invoice_Approval;

        case c = new Case(id=pCaseId);
        c.Validation_Override__c=true;
        c.IR_Manual_Invoice_Approval__c=true;
        c.Status='Approved';
        c.IR_Manual_Invoice_Approved_by__c = Userinfo.getUserId();
        //c.IR_Manual_Invoice_Approved_Date__c = Date.today();
        c.IRC_Manual_Invoice_Approved_Date__c = System.now();
        try
        {
            update c;
        }
        catch (System.Dmlexception ex)
        {
            for (Integer i = 0; i < ex.getNumDml(); i++)
            {
                return '0:'+ex.getDMLMessage(i);

            }
        }
        return '1:Successfully approved.';
    }

    public static Id getIRQueues(String pDevName)
    {
        if (irQueuesMap.size()<1)
        {

            List<String> tempStr = new List<String>();
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));
            tempStr.add(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName'));
            for (Group irGroup : [SELECT Id, DeveloperName FROM Group where DeveloperName IN :tempStr and Type = 'Queue'])
                irQueuesMap.put(irGroup.DeveloperName,irGroup.Id);
        }
        return irQueuesMap.get(pDevName);
    }

    /**
        updateIRCaseOwner
        - update Case Owner to IR Case Queues.
    */
    public static String updateIRCaseOwner(String pAction, Id pCaseId, Id pCaseOwnerId)
    {
        Id finUSQ = getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));
        Id finIntlQ = getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName'));

        if (pAction==null)
            return '0:Queue user is empty. Please refresh the page and try again and if problem persists get in touch with eae-ops@akamai.com for further assistance.';
        if (pCaseId==null)
            return '0:Case Id is null. Please refresh the page and try again and if problem persists get in touch with eae-ops@akamai.com for further assistance.';
        if (!hasIRCaseBtnAccess(userinfo.getProfileID()))
            return '0:Insufficient Access';
        case c = new Case(id=pCaseId);
        c.Validation_Override__c=true;

        if (pAction.equals('FIN-US'))
        {
            if (pCaseOwnerID==finUSQ)
                return '0: Case is already assigned to the Queue user.';
            else
                c.OwnerId = finUSQ;
        }
        else if (pAction=='FIN-Intl')
        {
            if (pCaseOwnerID==finIntlQ)
                return '0: Case is already assigned to the Queue user.';
            else
                c.OwnerId = finIntlQ;
        }
        else
        {
            return '0:Queue user does not exist. Please contact eae-ops@akamai.com for further assistance.';
        }

        try
        {
            update c;
        }
        catch (System.Dmlexception ex)
        {
            for (Integer i = 0; i < ex.getNumDml(); i++)
            {
                return '0:'+ex.getDMLMessage(i);

            }
        }
        return '1:Successfully updated the Case Owner';
    }

    public static Boolean hasIRCaseBtnAccess(Id pProfileID)
    {
        return (GSMUtilClass.GetCustomSettingValue('IR_CaseAccessProfileIDs').containsIgnoreCase(userinfo.getProfileID()));
    }

    /**
        checkForInprogressSync()
    */
    public static Boolean hasOtherIRCIntegrationInProgress()
    {
        List<Invoice_Review_Case_Audit__c> ircaIds = [Select Id from Invoice_Review_Case_Audit__c where Case_Creation_Completed__c=false AND CreatedDate = LAST_N_DAYS:30 WITH SECURITY_ENFORCED ];
        return (ircaIds.size()>0);
    }

    /**
    */
    public static String getDateStringGmt(Date pDate)
    {
        return pDate.year() + '-' + getPaddedDateComponent(pDate.month()) + '-' + getPaddedDateComponent(pDate.day());
    }

    public static String getDateTimeStringGmt(Datetime pDatetime)
    {
        return pDatetime.yearGmt() + '-' + getPaddedDateComponent(pDatetime.monthGmt()) + '-' + getPaddedDateComponent(pDatetime.dayGmt()) + 'T' +  getPaddedDateComponent(pDatetime.hourGmt()) + ':'
            + getPaddedDateComponent(pDatetime.minuteGmt()) + ':' + getPaddedDateComponent(pDatetime.secondGmt()) + '.000Z';
    }

    public static String getPaddedDateComponent(Integer pDtComponent)
    {
        String temp=String.valueOf(pDtComponent);
         if (pDtComponent<10)
            temp = '0' + String.valueOf(pDtComponent);
        return temp;
    }

    public static String lockIRCases()
    {
         if (!GsmUtilClass.GetCustomSettingValue('AccountDelete', 'EnabledProfileId').contains(UserInfo.getProfileId()))
                return '0:Insufficient Access';//Label.IR_Insufficient_Delete_AccessErrorMessage
        String results = '1:No Cases to process for this Invoice Review Period';
        List<Case> csToLockList = new List<Case>();
        List<Id> csToIgnoreIdList = new List<Id>();
        Invoice_Review_Case_Audit__c ircaRec = new Invoice_Review_Case_Audit__c();
        Date InvoiceReviewDate;

        ircaRec = [Select Id, Invoice_Review_Date__c, Name from Invoice_Review_Case_Audit__c where Case_Creation_Status__c='Success' AND Import_Status__c='Success' AND Invoice_Review_Date__c!=null Order by LastModifiedDate DESC][0];
        System.debug('ircaRec=' + ircaRec);

        if (ircaRec==null)
            return '0:No valid Invoice Review Case Audit record found, please talk to the Administrator.';
        else
            InvoiceReviewDate = ircaRec.Invoice_Review_Date__c;
        System.debug('Default RecordTypeName=' + GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default'));

        for (Case cs : [Select Id, Status, IR_Manual_Contract__c, Description, IR_Case_Locked__c, IR_Defer_Until__c, RecordTypeId, IR_Invoice_Date__c from Case where
            RecordType.DeveloperName = :GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default') and IR_Invoice_Date__c >= :InvoiceReviewDate.toStartOfMonth() and IR_Invoice_Date__c < :InvoiceReviewDate.addMonths(1) limit 9000])
            {
                if (cs.Status=='Deferred')
                {
                    //if (cs.Description==null || ( cs.Description!=null && !cs.Description.containsIgnoreCase('Manual Contract')) && cs.IR_Defer_Until__c > Date.today())
                    if (!cs.IR_Manual_Contract__c.equalsIgnoreCase('Yes') && cs.IR_Defer_Until__c > Date.today())
                    {
                        csToIgnoreIdList.add(cs.Id);
                        continue;
                    }
                    //else if (cs.Status=='Deferred' && cs.Description!=null  && cs.Description.containsIgnoreCase('Manual Contract'))
                    cs.Status='Approved';
                }
                //String strStatus = 'Approved, Approved without Review';
                //if (!strStatus.containsIgnoreCase(cs.Status))
                if(cs.Status=='Rejected')
                    cs.Status = 'Approved';

                cs.IR_Case_Locked__c=true;
                cs.Validation_Override__c=true;
                csToLockList.add(cs);
            }
        System.debug('csToIgnoreIdList Size=' + csToIgnoreIdList.size());
        System.debug('csToIgnoreIdList=' + csToIgnoreIdList);
        System.debug('csToLockList Size=' + csToLockList.size());

        //return 'finished';
        if (csToLockList.size()<1)
            return results;
        else
        {
            try
            {
                update csToLockList;
            }
            catch (System.Dmlexception ex)
            {
                for (Integer i = 0; i < ex.getNumDml(); i++)
                {
                    return '0:'+ex.getDMLMessage(i);
                }
            }
            return '1:Successfully Locked all Invoice Review Cases with Invoice Date:' + InvoiceReviewDate;//.format();
        }
    }

    public static String lockIRCases(Date pStartDate, Date pEndDate)
    {
        if (!GsmUtilClass.GetCustomSettingValue('AccountDelete', 'EnabledProfileId').contains(UserInfo.getProfileId()))
                return '0:Insufficient Access!';//Label.IR_Insufficient_Delete_AccessErrorMessage
        String results = '1:No Cases to lockdown for specified date range.';
        List<Case> csToLockList = new List<Case>();
        List<Id> csToIgnoreIdList = new List<Id>();
        Integer csToProcessCount = [Select count() from Case where RecordType.DeveloperName = :GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default')
            and IR_Invoice_Date__c >= :pStartDate and IR_Invoice_Date__c <= :pEndDate and LastModifiedDate = LAST_N_DAYS:180 limit 9000];

        if (csToProcessCount>0)
        {
            ID jobID = System.enqueueJob(new IRCaseLockQueueable(pStartDate, pEndDate, Userinfo.getUserId()));
            results = '1:IR Case lockdown process has begun, you will receive an email on completion.';
        }
        return results;
    }

    /**
        btnExecute()
        - Used to invoke apex code on Cases via buttons.
    */
    WebService static String btnExecuteLockIRCases(String pAction)
    {
        if (pAction.equals('lockIRCases'))
            return lockIRCases();
        else
            return '0:Action undefined';
    }

    public static String getFormattedDesc(String pCurrDesc, String pNewDesc)
    {
        if (pCurrDesc=='' || pCurrDesc==null)
            return pNewDesc;
        else if (pNewDesc=='' || pNewDesc==null)
            return pCurrDesc;
        else
            return (pNewDesc + '\n' + pCurrDesc);
    }

    public static Date getCurrentReviewCycleInvoiceDate()
    {
        Date invDate=null;
        for (Invoice_Review_Case_Audit__c irca: [SELECT Invoice_Review_Date__c,Id, CreatedDate FROM Invoice_Review_Case_Audit__c
            WHERE CreatedDate = LAST_N_DAYS:90 AND Case_Creation_Completed__c=true Order by CreatedDate Desc limit 1])
            {
                if (irca.Invoice_Review_Date__c!=null)
                    invDate = irca.Invoice_Review_Date__c;
            }

        System.debug('irca.invDate=' + invDate);
        if (invDate==null)
        {
            if (Date.today().day()>Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCase_CutOffDayOfMonth')))
                invDate=Date.today().addMonths(1).toStartOfMonth();
            else
                invDate=Date.today().toStartOfMonth();
        }

        System.debug('invDate=' + invDate);
        return invDate;
    }

    public static Date getCurrentReviewCycleInvoiceDate(String pInvNo)
    {
        Boolean defaultDate = true;
        Integer yy=0;
        Integer mm=0;
        Date myDate;
        try
        {
            String tempStr = pInvNo.subString(0,4);
            if (tempStr!=null && tempStr!='' && tempStr.isNumeric())
            {
                 yy = Integer.valueOf('20'+tempStr.subString(0,2));
                 mm = Integer.valueOf(tempStr.subString(2,4));
                 String strDate = yy + '-' + mm + '-' + '01';
                 myDate = date.valueOf(strDate);
                 defaultDate=false;
            }
        }
        catch (Exception ex)
        {
          System.debug('ex message=' + ex.getMessage());
        }
        finally
        {
            if (defaultDate)
                myDate = getCurrentReviewCycleInvoiceDate();
        }
        System.debug('calculated Date=' + myDate);
        return myDate;
    }

    public static Case getExistingIRCase(Id pMCHID, Date pInvoiceReviewDate)
    {
        Case existingCase = null;
        for (Case cs : [Select Id,IR_Original_Contract_Id__c,IR_Invoice_Number__c,Description,IR_Invoice_Date__c,CurrencyIsoCode,IRCache_isNewInvoice__c ,IRCache_hasMissingInvoiceLastMonth__c from Case where IR_Invoice_Date__c!=null  //CR 3713022
            AND IR_Invoice_Date__c = :pInvoiceReviewDate AND IR_Original_Contract_Id__c!=null AND RecordType.DeveloperName = :GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default')
                AND IR_Original_Contract_Id__c = :pMCHID AND CreatedDate=LAST_N_DAYS:60 Order by LastModifiedDate DESC])
                {
                    existingCase = cs;
                    break;
                }
        return existingCase;
    }

    public static Draft_Invoice__c getExistingDraftInvoice(Id pMCHID, Date pInvoiceReviewDate)
    {
        Draft_Invoice__c existingDI = null;
        for (Draft_Invoice__c di : [Select Id,Name,Invoice_Date__c,Original_Contract_Id__c FROM Draft_Invoice__c Where Original_Contract_Id__c!=null AND Original_Contract_Id__c= :pMCHID
            AND Invoice_Date__c!=null AND Invoice_Date__c= :pInvoiceReviewDate AND CreatedDate=LAST_N_DAYS:60 Order by LastModifiedDate Desc])
            {
                existingDI = di;
                break;
            }
        return existingDI;
    }

    public static String getReplacedOrInsertedDescription(String pCurrDesc, String pNewDesc, String pIdentifier)
    {
        //find current description of the case is null, simple insert the new one
        if(String.IsBlank(pCurrDesc)){
          return pNewDesc;
        }
        //if its not null split the description and to find if there any description matching the type to be replaced
        List<String> splitStrings = pCurrDesc.split('\n');
        String dataToReplace;
        for(String data: splitStrings){
            if(data.contains(pIdentifier)){
                dataToReplace = data;
            }
        }
        //if there is no already existing string of the alert type in description simple insert the new desc at the end
        if(dataToReplace == null){
          return pCurrDesc + '\n' + pNewDesc;
        }
        //the description already has description corresponding to identifier find it and replace with it new one
        Integer index = splitStrings.indexOf(dataToReplace);
        splitStrings.set(index,pNewDesc);
        String updatedDescription='';
        for(String data: splitStrings){
            updatedDescription= updatedDescription + data+'\n';
        }
        updatedDescription = updatedDescription.removeEnd('\n');
        return updatedDescription;
      }

    public static String calculateIRCasePriority(Decimal amt , Decimal conversionRateToUsd)
    {
      Decimal amountInUsd = amt * conversionRateToUsd;
      if(amountInUsd >= Decimal.valueOf(GsmUtilClass.getGSMSettingValue('IR_Case_Priority_Threshold')))
      {
        return 'High';
      } else {
        return null;
      }
    }
}