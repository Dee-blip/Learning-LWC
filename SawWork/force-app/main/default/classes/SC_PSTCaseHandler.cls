/****************************************************************************

* Class name          :   SC_PSTCaseHandler.cls
* Author              :   Vishnu Vardhan
* Created             :   20-August-2020
* Purpose             :   PST Case Handler
* Test Class          :   
-------------------------------------------------------------------------------
* MethodName          : Purpose 
-------------------------------------------------------------------------------
* +handlePSTCasesBi         :   PST Case Before Insert logic
                                - Custom  Validations
                                - Field Updates

* +handlePSTCasesBu         :   PST Case Before Update logic
                                - Custom  Validations
                                - Field  Updates
                                - Update Parent Trf

* +handlePSTCasesAi         :   PST Case After Insert logic
                                - Split PoC PST cases with multiple Products

* -validCaseProduct         :   Validation: non PoC(PST) cases should have one Case Product
* -validPartnerFeedback     :   Validation: For few Req Type, Partner feedback is mandatory before closing
* -validPerformanceDetail   :   Validation: For few Req Type, Perform Detail is mandatory before closing
* -validDsr                 :   Validation: DSR should belong to Case opportunity
                                            CAR Cases can have only CAR DSRs
                                            PoC(PST) can have only Approved DSRs
* -validTrialRequestForm    :   Validation: Case Request Type and TRF Record Type should match

* -updateClosedCaseFields   :   Field Update - Update Closed Case Fields
* -updateLastActivity       :   Field Update - if implementation status is changed, update last customer activity date
* -updatePod                :   Field Update - if pod is blank, update it from custom metadata
* -updateUnitCount          :   Field Update - calculate and Update unit count
* -updateImplementationStatus : Field Update - Update Impl Status field

* -getCloneCases            :   Convenience method to get list of POC cases for cloning
* -getDsrMap                :   Convenience method to get map<id, dsr> for PST cases
* -getTrfMap                :   Convenience method to get map<id, trf> for trf cases

* @isPartnerFeedbackMissing :   aura method: partner feedback check, to shows button on detail page
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
Aug 20, 2020     Vishnu Vardhan   ESESP-2826      PST related Case Trigger logic
Dec 18, 2020     Vishnu Vardhan   ESESP-4539      Make Unit count field editable
Dec 20, 2020     Vishnu Vardhan   ESESP-4551      Changes in "Pending" Implementation Status
Dec 28, 2020     Vishnu Vardhan   ESESP-4609      Updated POD population logic to use Department
Dec 30, 2020     Vishnu Vardhan   ESESP-4121      Feedback form to Case Creator
Jul 23, 2020     Jay              ESESP-5146      Added updateCaseAssignor
*****************************************************************************/
public without sharing class SC_PSTCaseHandler {

    static final Id PST_RT_ID = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PST_Case').getRecordTypeId();

    static final Set<String> PERFORM_DETAIL_REQUESTS = new Set<String>{'Customer Analysis Report(Synthetic Trial)',
                                                                'Post Integration Value Confirmation', 
                                                                'Triage', 
                                                                'PoC(PST)'};
    static final Set<String> PTNR_FEEDBACK_REQUESTS = new Set<String>{'Peer Review',
                                                                'Technical Consultation', 
                                                                'Training Assistance'};
    static Set<Id> processedAiCases = new Set<Id>();
    static Boolean enablePstForcedRouting = true;
    
    /* +handlePSTCasesBi         :   PST Case Before Insert logic
                                    - Custom Validations
                                    - Default Routing
                                    - Field Updates
    */
    public static void handlePSTCasesBi(List<Case> newCaseList) {
        List<Case> pstCases = SC_Utility.filterSObjList(newCaseList,  new Map<String, Object> {'RecordTypeId' => PST_RT_ID});
        if(pstCases.isEmpty()) {
            return;
        }
        
        Map<Id, Deal_Support_Request__c> dsrMap = getDsrMap(pstCases);
        Map<Id, SC_Trial_Request_Form__c> trfMap = getTrfMap(pstCases);

        // Process Only Valid Cases
        for(Case cs: pstCases) {
            // Custom Validations
            Boolean validPstCase = cs.Validation_Override__c ||  
                                    validCaseProduct(cs, null) &&
                                    validDsr(cs, dsrMap.get(cs.Deal_Support_Request__c)) &&
                                    validTrialRequestForm(cs, trfMap.get(cs.Trial_Request_Form__c));
            if(validPstCase == false) {
                continue;
            }

            // Field Updates
            cs.Case_Assignment_Using_Active_Rules__c = enablePstForcedRouting;
            cs.Last_Customer_Activity_Date__c = System.now();
            updatePod(cs);
            updateUnitCount(cs);
            updateImplmentationStatus(cs);
        }
    }

    /* +handlePSTCasesAi      :   PST Case After Insert logic
                                - Split PoC PST cases with multiple Products
    */
    public static void handlePSTCasesAi(List<Case> newCaseList) {
        List<Case> pstCases =  SC_Utility.filterSObjList(newCaseList,  new Map<String, Object> {'RecordTypeId' => PST_RT_ID});

        if(pstCases.isEmpty()) {
            return;
        }

        List<Case> toUpsertCases = new List<Case>();

        // To Check : duplicates on recursion
        for(Case cs: pstCases) {
            if(processedAiCases.add(cs.Id)) {
                // Get To Clone Cases
                List<Case> toCloneCases  = getCloneCases(cs);
                toUpsertCases.addAll(toCloneCases);
            }
        }

        try {
            upsert toUpsertCases;
        } catch(DmlException ex) {
            for( Case cs: pstCases) {
                cs.addError(ex);
            }
        }
    }

    /* +handlePSTCasesBu         :   PST Case Before Update logic
                                    - Custom Validations
                                    - Field Updates
    */
    static Boolean isBuTriggerProcessed = false;
    public static void handlePSTCasesBu(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {

        List<Case> closedCases = new List<Case>();
        List<Case> pstCases = SC_Utility.filterSObjList(newCaseList,  new Map<String, Object> {'RecordTypeId' => PST_RT_ID});

        if(pstCases.isEmpty() || isBuTriggerProcessed) {
            return;
        }
        isBuTriggerProcessed = true;
	
        Map<Id, Deal_Support_Request__c> dsrMap = getDsrMap(pstCases);
        Map<Id, SC_Trial_Request_Form__c> trfMap = getTrfMap(pstCases);

        Map<Id, Case> queriedCaseMap = new Map<Id, Case>([select id, CreatedBy.Email, Owner.Email, Owner.Name, Account_Primary_Country__c, AKAM_Case_ID__c, Trial_Request_Form__c, Deal_Support_Request__c,
                                                        (select id from Partner_Support_Feedbacks__r limit 1 ), 
                                                        (select id from Performance_Details__r limit 1 )
                                                        from Case where id in :pstCases]);

        for(Case cs: pstCases) {
            Case queriedCase = queriedCaseMap.get(cs.Id);
            Case oldCase = oldCaseMap.get(cs.Id);

            // Custom Validations
            Boolean validPstCase = cs.Validation_Override__c ||
                                    validCaseProduct(cs, oldCase) &&
                                    validPerformanceDetail(cs, queriedCase) &&
                                    validPartnerFeedback(cs, queriedCase) &&
                                    validDsr(cs, dsrMap.get(cs.Deal_Support_Request__c)) &&
                                    validTrialRequestForm(cs, trfMap.get(cs.Trial_Request_Form__c));

            if(validPstCase == false) {
                continue;
            }
            
            if(cs.Status == 'Closed' && cs.Status != oldCase.Status && cs.Close_Code__c != 'Cancelled') {
                //closedCases.add(cs);
                closedCases.add(queriedCase);
            }

            // Field Updates
            updateClosedCaseFields(cs);
            updateLastActivity(cs,oldCase);
            updatePod(cs);
            updateUnitCount(cs);
            updateImplmentationStatus(cs);
        }
        
        //Dec 30, 2020     Vishnu Vardhan   ESESP-4121      Feedback form to Case Creator
        if(closedCases.size() > 0) {
            EmailTemplate pstEmailTmplt = [Select Id from EmailTemplate where DeveloperName = 'SC_PST_Feedback_Survey_Email'];
            List<Survey> svyList = [select id from Survey where DeveloperName = 'pst_feedback_survey'];
            String surveyId = svyList.size() > 0? svyList[0].Id: null;
            feedbackEmailToCreator(closedCases, pstEmailTmplt.Id, surveyId);
        }
    }


    static Boolean isAuTriggerProcessed = false;
    public static void handlePSTCasesAu(List<Case> newCaseList,Map<Id,Case> oldCaseMap) {
        
        List<Case> pstCases = SC_Utility.filterSObjList(newCaseList,  new Map<String, Object> {'RecordTypeId' => PST_RT_ID});
        Map<Id, Case> pstCasesMap = new Map<Id, Case>(pstCases);
        if(pstCases.isEmpty()) {
            return;
        }
        isAuTriggerProcessed = true;
        updateCaseReports(pstCasesMap,oldCaseMap);
    }

    // Field Update - Update Closed Case Fields
    static void updateClosedCaseFields(Case cs) {
        Boolean isClosedCase = (cs.Status == 'Closed'  || cs.Implementation_Status__c == 'Closed');

        if(isClosedCase) {
            cs.Status = 'Closed';
            cs.Implementation_Status__c = 'Closed';
        }
    }
    // Field Update - if implementation status is changed, update last customer activity date
    static void updateLastActivity(Case cs, Case oldCase) {
        if(cs.Implementation_Status__c != oldCase.Implementation_Status__c) {
            cs.Last_Customer_Activity_Date__c = System.now();
        }
    }
    // Field Update - if pod is blank, update it from custom metadata
    static void updatePod(Case cs) {
        //ESESP-4609 - User department will determine POD
        if(String.isBlank(cs.POD__c)) {
            if(deptPodMap.containsKey(cs.Originating_Department__c)) {
                cs.POD__c = deptPodMap.get(cs.Originating_Department__c);
            } 
        } 
    }

    // Field Update - Update Unit Count 
    static void updateUnitCount(Case cs) {
        // ESESP-4539 : Make unit count field editable
        //              If unit count is already populated, skip auto population logic
        if(cs.Unit_Count__c != null) {
            return;
        }
        String ky = cs.Request_Type__c == 'PoC(PST)'?  
                        'PoC(PST)-' + cs.PST_Case_Product__c.split(';')[0] : 
                            cs.Request_Type__c;
        String unitCount = prodUnitMap.containsKey(ky) ? prodUnitMap.get(ky): prodUnitMap.get('Others');
        cs.Unit_Count__c = Decimal.valueOf(unitCount);
    }

    static final Set<String> PENDING_IMPL_STATUSES = new Set<String> {   
        'Escalation-Scripting',
        'Escalation-Performance',
        'Awaiting Response',
        'Awaiting Response - PEM',
        'Awaiting Response - SE',
        'Awaiting Response - Partner',
        'Awaiting TE Response',
        'Waiting for Customer Confirmation',
        'Awaiting Response - Customer',
        'Awaiting Integration Call - Customer',
        'Requirements under Review',
        'Awaiting Kick Off Call - Customer',
        'Awaiting Go Live',
        'Awaiting necessary Contracts',
        'Escalated Internally to AMG/CMG',
        'Escalated Internally to LUNA support',
        'Escalated Internally to Akatec',
        'Waiting for Partner Confirmation',
        'Escalation - SME group',
        'Customer Testing',
        'Escalated Internally to ACC support'
        };
    // Field Update - Update Unit Count 
    static void updateImplmentationStatus(Case cs) {
        if(PENDING_IMPL_STATUSES.contains(cs.Implementation_Status__c) && cs.Status == 'Work in Progress') {
            cs.Status = 'Pending';
        }
    }

    // Validation: For few Req Type, Perform Detail is mandatory before closing
    static  Boolean validPerformanceDetail(case cs, Case queriedCase) {
        Boolean error = PERFORM_DETAIL_REQUESTS.contains(cs.Request_Type__c) && 
                            (cs.status == 'Closed' || cs.implementation_status__c == 'Closed') &&  
            				cs.Close_Code__c != 'Cancelled' &&
                            queriedCase.Performance_Details__r != null &&
                            queriedCase.Performance_Details__r.isEmpty();  
        if(error) {
            cs.addError('Cannot close case with out Performance Metric');
        }
        return !error;
    }

    // Validation: For few Req Type, Partner feedback is mandatory before closing
    static  Boolean validPartnerFeedback(case cs, Case queriedCase) {
        Boolean error = PTNR_FEEDBACK_REQUESTS.contains(cs.Request_Type__c) && 
                        (cs.status == 'Closed' || cs.implementation_status__c == 'Closed') && 
            			cs.Close_Code__c != 'Cancelled' &&
                        queriedCase.Partner_Support_Feedbacks__r != null &&
                        queriedCase.Partner_Support_Feedbacks__r.isEmpty();
        if(error) {
            cs.addError('Cannot close case with out Partner Feedback');
        }
        return !error;
    }
    // Validation: non PoC(PST) cases should have one Case Product
    public static Boolean validCaseProduct(Case cs, Case oldCase) {
        // errof if (case product is changed OR request Type is not PoC(PST) )AND&& have multiple case products
        Boolean caseProductError = (
                                        (Trigger.isUpdate &&  cs.PST_Case_Product__c != oldCase.PST_Case_Product__c)
                                        || cs.Request_Type__c !=  'PoC(PST)' 
                                    )
                                    && cs.PST_Case_Product__c.contains(';') ;
        if(caseProductError) {
            cs.PST_Case_Product__c.addError('Only one Case Product is allowed');
        }
        return !caseProductError;
    }

    // Validation: DSR
    public static Boolean validDsr(Case cs, Deal_Support_Request__c dsr) {
        if(dsr == null ) {
            return true;
        }
        Boolean dsrError  = false;

        if(cs.Opportunity__c != dsr.Opportunity__c) {
            cs.Deal_Support_Request__c.addError('Select DSR linked to Case Opportunity');
            dsrError = true;
        }
        else if(cs.Request_Type__c == 'Customer Analysis Report(Synthetic Trial)' && dsr.Request_Type__c != 'CAR') { 
            cs.Deal_Support_Request__c.addError('Select DSR with CAR Request Type for Customer Analysis Report cases');
            dsrError = true;
        } else if(cs.Chime_Case_Type__c != 'Chime PST Case' && cs.Origin != 'Autogen'  && cs.Request_Type__c == 'PoC(PST)' && dsr.Approval_Status__c != 'Approved') {
            cs.Deal_Support_Request__c.addError('Select Approved DSR for PoC(PST) cases');
            dsrError = true;
        }
        return !dsrError;
    }
    static final Map<String, String> REQUEST_TYPE_TO_TRF_RT_MAP = new Map<String, String>{   
                                                    'Customer Analysis Report(Synthetic Trial)'=> 'Customer Analysis Report',
                                                    'Post Integration Value Confirmation' => 'Post Integration Value Confirmation',
                                                    'Self Service Trial Support'=> 'Self Service Trial Support',
                                                    'Triage'=> 'Triage',
                                                    'Customer Integration'=> 'Self Service Integration Support',
                                                    'Partner Integration'=> 'Self Service Integration Support',
                                                    'Peer Review'=> 'Partner Support Peer Review',
                                                    'Technical Consultation'=> 'Partner Support Technical Consultation',
                                                    'Training Assistance'=> 'Partner Support Training Assistance'
                                                };


    // Validation: Trial Request Form
    public static Boolean validTrialRequestForm(Case cs, SC_Trial_Request_Form__c trf) {
        
        Boolean trfError  = false;
        String allowedTrfRt = REQUEST_TYPE_TO_TRF_RT_MAP.get(cs.Request_Type__c);
        if(trf != null && allowedTrfRt != null && allowedTrfRt != trf.RecordType.Name) {
            cs.Trial_Request_Form__c.addError('Only ' + allowedTrfRt + ' TRFs can be assigned to this Case');
            trfError = true;
        } 
        if(trf != null && trf.Cases__r != null && trf.Cases__r.size() > 1) {
            cs.Trial_Request_Form__c.addError('TRF Cannot be linked to multiple Cases');
            trfError = true;
        }
        return !trfError;
    }
    
    // on PST case closure - Send Survey Email to Case Owner
    // Dec 30, 2020     Vishnu Vardhan   ESESP-4121      Feedback form to Case Creator
    public static void feedbackEmailToCreator(List<Case> csList, Id emailTemplateId, Id surveyId){

        Map<Id, Case> caseMap = new Map<Id, Case>(csList);

        // Creating Survey Invitations
        List<SurveyInvitation> surveyInvs = new List<SurveyInvitation>();

        for( Case cs: csList) {
            surveyInvs.add( new SurveyInvitation(
                Name = cs.AKAM_Case_Id__c + ' Survey',
                Case__c = cs.Id,
                SurveyId= surveyId,
                OptionsCollectAnonymousResponse = false,
                OptionsAllowGuestUserResponse = false
            ));
        }

        insert surveyInvs;
        
        List<SurveyInvitation> queriedSvyInvs = [SELECT Id, Name, InvitationLink, Case__c FROM SurveyInvitation where id in :surveyInvs];
        List<Group> pstManagersGroup = [SELECT Id FROM Group where DeveloperName = 'SC_PST_Managers_Group'];

        // Sending Survey Link via Email 
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        List<SurveyInvitationShare> surveyInvShares = new List<SurveyInvitationShare>();
        List<OrgWideEmailAddress> owEmails = [select Id from OrgWideEmailAddress where Address in ('no-reply@akamai.com', 'no-reply-qa@akamai.com') limit 1];

        
        for(SurveyInvitation sInv: queriedSvyInvs) {
             
            Case cs = caseMap.get(sInv.Case__c);
            cs.Survey_Invitation__c = sInv.Id;
            Id caseCreatorId = cs.CreatedById;

            surveyInvShares.add(new SurveyInvitationShare(
                ParentId = sInv.Id,
                UserOrGroupId = pstManagersGroup[0].Id,
                AccessLevel = 'Edit',
                RowCause = Schema.SurveyInvitationShare.RowCause.Manual

            ));
            
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateId, caseCreatorId, sInv.Case__c);
            
            String htmlBody = email.getHtmlBody();
            htmlBody = htmlBody.replace('[[CASE_OWNER]]', cs.Owner.Name);
            htmlBody = htmlBody.replace('[[SURVEY_INVITATION_LINK]]', sInv.InvitationLink);
            
            String textBody = email.getPlainTextBody();
            textBody = textBody.replace('[[CASE_OWNER]]', cs.Owner.Name);
            textBody = textBody.replace('[[SURVEY_INVITATION_LINK]]', sInv.InvitationLink);
            
            email.setTargetObjectId(caseCreatorId);
            email.setSubject(email.getSubject());
            email.setPlainTextBody(textBody);
            email.setHtmlBody(htmlBody);
            email.saveAsActivity = false;
            
            if ( owEmails.size() > 0 ) {
                email.setOrgWideEmailAddressId(owEmails.get(0).Id);
            }
            
            messageList.add(email);
        }        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messageList);
        
        // Sharing survey with PST Managers
        insert surveyInvShares;
    }

    // Convenience method  : for  PoC(PST) cases, for  each PST Product create (clone) a case
    public static List<Case> getCloneCases(Case cs) {
        List<Case> toCloneCases = new List<Case>();
        
        // Only PoC PST Cases with multiple case products can be cloned
        Boolean eligibleForClone =  cs.Request_Type__c == 'PoC(PST)' && 
                                    String.isNotBlank(cs.PST_Case_Product__c) && 
                                    cs.PST_Case_Product__c.contains(';');
        if(eligibleForClone == false) {
            return toCloneCases;
        }

        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.useDefaultRule = true;
        SC_PSTCaseHandler.enablePstForcedRouting = false;

        list<String> caseProducts = cs.PST_Case_Product__c.split(';');
        Case parentCase = new Case(Id = cs.Id, PST_Case_Product__c = caseProducts[0]);
        parentCase.setOptions(dmlOpts);
        // Update PST Product of Current Case - to first PST Product (for Other PST Products, child Cases(cloned) will be created)
        toCloneCases.add(parentCase);

        // Cloned Cases
        for(integer i = 1; i< caseProducts.size(); i++ ) {
            Case clonnedCase = cs.clone(false, true, false, false);
            clonnedCase.PST_Case_Product__c = caseProducts[i];      
            clonnedCase.ParentId = cs.Id;
            clonnedCase.Deal_Support_Request__c = null;
            clonnedCase.AKAM_Case_ID__c =  null;
            clonnedCase.Trial_Request_Form__c =  null;
            clonnedCase.Validation_Override__c = true;
            clonnedCase.setOptions(dmlOpts);
            toCloneCases.add(clonnedCase);
        }
        return toCloneCases;
    }

    // Convenience Method to get map<id, dsr> for PST cases
    public static Map<Id, Deal_Support_Request__c> getDsrMap(List<Case> pstCases) {
        Set<Id> dsrIds = new Set<Id>();

        for(Case cs: pstCases) {
            dsrIds.add(cs.Deal_Support_Request__c);
        }
        Map<Id, Deal_Support_Request__c> dsrMap = new  Map<Id, Deal_Support_Request__c>();

        if(dsrIds.size() > 0) {
            dsrMap = new  Map<Id, Deal_Support_Request__c>([select id, Approval_Status__c, Request_Type__c, Opportunity__c 
                                                                from Deal_Support_Request__c where id  in :dsrIds]);
        }
        return dsrMap;
    }

    // Convenience method to get map<id, trf> for trf cases
    public static Map<Id, SC_Trial_Request_Form__c> getTrfMap(List<Case> pstCases) {
        Set<Id> trfIds = new Set<Id>();

        for(Case cs: pstCases) {
            trfIds.add(cs.Trial_Request_Form__c);
        }

        Map<Id, SC_Trial_Request_Form__c> trfMap = new  Map<Id, SC_Trial_Request_Form__c>();

        if(trfIds.size() > 0) {
            trfMap = new  Map<Id, SC_Trial_Request_Form__c>([select id, RecordType.Name,  (select id from Cases__r)
                                                            from SC_Trial_Request_Form__c where id  in :trfIds]); 
        }
        return trfMap;
    }
    
    // aura method: partner feedback check, to show button on detail page
    @AuraEnabled(cacheable=true)
    public static Boolean isPartnerFeedbackMissing(Id caseId){
        List<SC_Partner_Support_Feedback__c> pFeedbacks = [select id from SC_Partner_Support_Feedback__c where Case__c =:caseId limit 1];
        return pFeedbacks.isEmpty();
    }
    
    // Case Creator - POD Map
    static map<String, String> deptPodMap    {
        get {
            if(deptPodMap == null) {
                deptPodMap = new Map<String, String>();
                for( SC_PST_Metadata__mdt mInfo: [select id, key1__c, value1__c from SC_PST_Metadata__mdt where scope__c = 'DepartmentPod']) {
                    deptPodMap.put(mInfo.key1__c, mInfo.value1__c);
                }
            }
            return deptPodMap;
        }
        set;
    }

        // Unit Count Map
        static map<String, String> prodUnitMap {
        get {
            if(prodUnitMap == null) {
                prodUnitMap = new Map<String, String>();
                for( SC_PST_Metadata__mdt mInfo: [select id, key1__c, value1__c from SC_PST_Metadata__mdt where scope__c = 'ProductUnit']) {
                    prodUnitMap.put(mInfo.key1__c, mInfo.value1__c);
                }
            }
            return prodUnitMap;
        }
        set;
    }
    
    public static void updateCaseReports(Map<Id, Case> newCaseMap,Map<Id,Case> oldCaseMap) {

        Map<Id, SC_Case_Report__c> caseRepMap = new Map<Id, SC_Case_Report__c>();
        for( SC_Case_Report__c crep: [select id, Case__c, Case_Change_Log__c,CaseAssignor__c from SC_Case_Report__c where Case__c in :newCaseMap.keySet()]) {
            caseRepMap.put(crep.Case__c, crep);
        }
        
        for(Case cs: newCaseMap.values()) {
            SC_Case_Report__c cRep = caseRepMap.get(cs.Id);
            if(cRep != null) {
                Map<String, SC_CaseReportTriggerHandler.CaseChangeTracker> caseChangeLogMap = (Map<String, SC_CaseReportTriggerHandler.CaseChangeTracker>) JSON.deserialize (crep.Case_Change_Log__c, Map<String, SC_CaseReportTriggerHandler.CaseChangeTracker>.class);
                caseChangeLogMap.get('Status').addChange(cs.Status);
                caseChangeLogMap.get('Implementation_Status__c').addChange(cs.Implementation_Status__c);
                cRep.Case_Change_Log__c = JSON.serialize(caseChangeLogMap);
                updateCaseAssignor(cRep,cs,oldCaseMap.get(cs.Id));
            } else {
                Map<String, SC_CaseReportTriggerHandler.CaseChangeTracker> caseChangeLogMap = new Map<String, SC_CaseReportTriggerHandler.CaseChangeTracker> ();
                caseChangeLogMap.put('Status', new SC_CaseReportTriggerHandler.CaseChangeTracker('Status', cs.Status));
                caseChangeLogMap.put('Implementation_Status__c', new SC_CaseReportTriggerHandler.CaseChangeTracker('Implementation_Status__c', cs.Implementation_Status__c));
                cRep = new SC_Case_Report__c(Case__c = cs.Id, 
                                             Opportunity__c = cs.Opportunity__c, 
                                             Case_Change_Log__c = JSON.serialize(caseChangeLogMap)
                                            );
                updateCaseAssignor(cRep,cs,oldCaseMap.get(cs.Id));
                caseRepMap.put(cs.Id, crep);
            }
        }
        
        upsert caseRepMap.values();
    }

    //Capture name of user who changes owner from a queue to user.
    private static void updateCaseAssignor(SC_Case_Report__c report, Case newCase,Case oldCase) {
        if (String.isBlank(report.CaseAssignor__c) && !String.isBlank(oldCase.OwnerId) && String.valueOf(oldCase.OwnerId).startsWith('00G') && !String.isBlank(oldCase.OwnerId) && String.valueOf(newCase.OwnerId).startsWith('005')) {
            report.CaseAssignor__c =  UserInfo.getUserId();
        }
    }
}