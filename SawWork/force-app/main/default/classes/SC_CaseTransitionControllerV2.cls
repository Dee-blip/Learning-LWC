/* Author           :  Jay
   Date             :  July 6 , 2015
   Purpose          :  This class creates trasition. User can create transition.
                       Someone can approve transition. 
                       Reference CR:3018620
    Test Classes    :  SC_Case_Trgr_EmlServc_Class_TC
------------------------------------------------------------------------
Date            Developer       CR              Summary
27-Apr-2016     Vamsee          3172971         Modified the Cae Transition creation logic - CT record is created when Lead or manager approves it.
09-Jan-2016     Pinkesh         CR 3528581      Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)
27-Apr-2017     Pinkesh         ESESP-542       Added case transition feature for BOCC
6-June-2017     Vandhana        ESESP-624       Make Case Product mandatory before Transitioning a Case
28-Sep-2017     Vamsee          ESESP-714       Case Transition for DR
24-May-2020     Vamsee          ESESP-3567      Removed case transition feature for BOCC (BOCC is Migrating to Technical)
5-April-2021    Vandhana        ESESP-2346      Carrier LX Migration
31-May-2022		Saiyam			ESESP-5957		Added Case transition feature for BOCC
------------------------------------------------------------------------
*/
public class SC_CaseTransitionControllerV2 
{
    //This is to store the Current case details
    public Case currentCase{get;set;}
    //This is used to create the CT object
    public Case_transition__c caseTransitionObject
    {
        get
        {
            if(caseTransitionObject == NULL)
                caseTransitionObject = new Case_transition__c();
            return caseTransitionObject;
        } 
        set;
    }
    
    //This will store current shift 
    public String currentShift {get;set;} 
    
    //This will store the ID of the Case
    Id caseId ;
    
    //This will store the current recordType Name
    String recordTypeName;
    
    //This is to store the wakeupTime of the Case
    public String wakeupTime{get;set;}
    
    //This flag is required to display the approve button
    public boolean flag{get;set;}

    //Map to store Case RecordType with corresponding Case_Transition RecordType
    Map<String, String> mCT_RecordType = new Map<String, String>();
    
    //changes by Saiyam - ESESP-5957 - added logic to determine if sub type is BOCC to fetch corresponding record from meta data.
    public SC_CaseTransitionControllerV2(ApexPages.StandardController stdController) 
    {
        caseId = ApexPages.currentPage().getParameters().get('id');
        for(SC_Case_Transition_RecordType_Map__mdt ct : [Select Case_RecordType__c, Case_Transition_RecordType__c 
                                                         from SC_Case_Transition_RecordType_Map__mdt])
        {
           mCT_RecordType.put(ct.Case_RecordType__c, ct.Case_Transition_RecordType__c);
        }
        
        flag = true;
        initialise();
        String recordSubType = '';
        if(currentCase.Sub_Type__c == 'BOCC') 
            recordSubType = 'BOCC';
        else
            recordSubType = currentCase.RecordType.Name;
        recordTypeName = mCT_RecordType.get(recordSubType);
        caseTransitionObject.RecordTypeId = Case_transition__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(mCT_RecordType.get(recordSubType)).getRecordTypeId();
    }
    
    //This method is to get details of the Current Case
    public void initialise()
    {
        currentCase = [SELECT id,ownerId,owner.name,
                       recordType.Name,severity__c,has_active_transition__c,
                       Issue_Summary__c,Troubleshooting_to_Date__c,
                       Data_Collected__c,Customer_Expectations__c,
                       Next_Action_Recommendation__c,Case_Product__c,Sub_Type__c
                       FROM Case
                       WHERE id = :caseId
                       LIMIT 1];
    }
     /* Once the lead or manager approves the transition CT gets created
     * Copy 5 fields which are present on case to CT object
     * This function will create CT object with proper fields
     * */
    public void approveTransition()
    {
        initialise();
        if (isValidateTransition())
        {
            caseTransitionObject.case__c = currentCase.id;
            casetransitionObject.severity__c = currentcase.severity__c;
            caseTransitionObject.Approved_by__c = userinfo.getUserId();
            caseTransitionObject.Approved_Date__c = system.now();
            caseTransitionObject.Issue_Summary__c = currentcase.Issue_Summary__c;
            caseTransitionObject.Troubleshooting_to_Date__c = currentcase.Troubleshooting_to_Date__c;
            caseTransitionObject.Data_Collected__c = currentcase.Data_Collected__c;
            caseTransitionObject.Customer_Expectations__c = currentcase.Customer_Expectations__c;
            caseTransitionObject.Next_Action_Recommendation__c =  currentcase.Next_Action_Recommendation__c;
            if(caseTransitionObject.Target_Shift__c != 'Transition Now')
            {
                caseTransitionObject.Shift_Tracker__c = true;   
            } 
            try
            {
                upsert caseTransitionObject;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Approved Successfully');
                ApexPages.addMessage(myMsg);
                initialise();
            }
            
            // changes by Vandhana - make Case Product mandatory before Case Transition
            catch(exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,CommonUtilClass.ExtractValidationExMsg(e)));
            }
        }
    }
     /* This function is called when user clicks on Save button on VF page(Living Summary Tab)
     * This function will update Case record 
     * 
   public void saveTransition(){
        try {
            update currentCase;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Record Saved Successfully');
            ApexPages.addMessage(myMsg);
        }
        catch(exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
            ApexPages.addMessage(myMsg);
           }
    } */
    
    /* dont display any approve button if case is in transition.
     * Also there should be transition created by someone .
     * then non case owner can approve this */
    
    //changes by Saiyam - ESESP-5957 - added BOCC_Transition_Queue in currentCase owner if condition.
    public boolean getDisplayTransitionButton(){
      currentShift = SC_utility.getCurrentShiftDetails(recordTypeName);
        //caseTransitionObject.id != null && removed
        if (currentCase.has_active_transition__c == true)
            return false;
        
        if(currentCase.owner.name == 'ATS_Transition_Queue' || currentCase.owner.name == 'BOCC_Transition_Queue')
            return false;
        
        
        if(currentCase.OwnerId == userinfo.getUserId())
            return false;
        
        return true;
    }
    
    /* This fuction will returns true if the case is in active transition state
     * This function is used to display the approve button on VF page(Transition Tab)
     * */
    public boolean getActiveTransition(){
        return currentCase.id != null && currentCase.has_active_transition__c == true ;
    }
    
    
    /* This fuction will returns true if the Transition is a valid one
      */
    //changes by Saiyam - ESESP-5957 - added BOCC_Transition_Queue filter in query.
    private boolean isValidateTransition(){
        currentShift = SC_utility.getCurrentShiftDetails(recordTypeName);
        if(currentCase != null && currentCase.OwnerId != null && string.valueOf(currentCase.OwnerId).substring(0,3) == '00G')
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Case is owned by Queue. Cannot create transition');
            ApexPages.addMessage(myMsg);
            return false;
        }
        //This condition is to check the Living Summary fields
        if(isBlank(currentcase.Issue_Summary__c) || isBlank(currentcase.Troubleshooting_to_Date__c)|| isBlank(currentcase.Data_Collected__c) || isBlank(currentcase.Customer_Expectations__c)|| isBlank(currentcase.Next_Action_Recommendation__c))
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'All Living Summary fields are mandatory to create a Transition.');
            ApexPages.addMessage(myMsg);
            return false;
        }
        //will try to get current shift details again. page might be in stale state
        if (isBlank(caseTransitionObject.target_shift__c) || '--None--' == caseTransitionObject.target_shift__c)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select valid target shift');
            ApexPages.addMessage(myMsg);
            return false;
        }
        if (caseTransitionObject.target_shift__c != 'Transition Now')
        {
            List<group> transitionQueueList = [SELECT id,
                                               name,
                                               email 
                                               FROM GROUP
                                               WHERE type = 'queue' 
                                               AND name in ('ATS_Transition_Queue','BOCC_Transition_Queue')];
            if (transitionQueueList ==null || transitionQueueList.size() == 0){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Transition queue is not configured.');
                ApexPages.addMessage(myMsg);
                return false;
            }    
        }
        if (caseTransitionObject != null && caseTransitionObject.target_shift__c == currentShift)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Target Shift cannot be same Shift. Use Transition Now');
            ApexPages.addMessage(myMsg);
            return false;
        }
        
        return true;
    }
    /* This method is to check empty string
*/
    
    public boolean isBlank(String s){
        if(s==null || s.trim()==''){
            return true;
        }
        return false;
    }
    
    /* This functioned is called from the VF page to update the wakeup time based on target shift
*/
    public void updateTargetDate(){
        flag =true;
        if (caseTransitionObject == null || isBlank(caseTransitionObject.target_shift__c) || '--None--' == caseTransitionObject.target_shift__c)
            wakeupTime = '';
        else if(caseTransitionObject.target_shift__c == 'Transition Now' )
            wakeupTime = String.valueOf(System.now().format());
        else 
            wakeupTime = String.ValueOf(sc_utility.getShiftDateTime(caseTransitionObject.Target_Shift__c, recordTypeName).format()) ;
        flag =false;
    }
    
    /* This method is called from trigger
    * This method is to update the CT object and Case
    */
    @future
    public static void updateCaseAsync(List<id> lTransitionId, List<id> lCaseId)
    {
        //This is to prevent updates on DR Org
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        
        if(environmentSetup.Active_Org__c){
            List<Case_Transition__c> lTransitionObject = new List<Case_Transition__c>();
            
            for(id transitionId : lTransitionId){
                case_transition__c transitionObject = new case_transition__c(id=transitionId);
                transitionObject.start_date__c = system.now();
                lTransitionObject.add(transitionObject);
            }
            List<Database.SaveResult> saveTransitionObject = Database.update(lTransitionObject, false);
            SC_Utility.processSaveResult(saveTransitionObject, lTransitionId);
            List<Case> lC = new List<Case>();
            
            for(id caseId : lCaseId){
                Case c = new Case(id=caseId); 
                c.Case_Assignment_Using_Active_Rules__c = true;
                c.has_active_transition__c = true;
                c.Case_In_Transition_Queue__c = false;
                c.Validation_Override__c = true;
                lC.add(c);
            }
            List<Database.SaveResult> saveCase = Database.update(lC, false);
            SC_Utility.processSaveResult(saveCase, lCaseId);
        }
        else
        {
            System.debug('---INACTIVE ORG---');
        }
    }
    
    //Use @AuraEnabled to enable client- and server-side access to the method
    @AuraEnabled
    public static String getUserName() 
    {
        return UserInfo.getName();
    }
    
    /* This method is called from SC_CaseTransitionController.js
    * This method is to provide currentShiftDetails for BOCC.
    */
    @AuraEnabled
    public static String getCurrentShiftDetailsBOCC() 
    {
        return SC_utility.getCurrentShiftDetails('BOCC');
    }
    
    @AuraEnabled
    public static String getCurrentShiftDetails() 
    {
        return SC_utility.getCurrentShiftDetails('Akatec');
    }
    
    @AuraEnabled
    public static Id getCaseTransRecTypeId(String recordTypeLabel)
    {
        return Schema.SObjectType.Case_Transition__c.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();
    } 
    
    /* This method is called from SC_CaseTransitionController.js
    * This method is to provide wakeUpTime for BOCC.
    */
    @AuraEnabled
    public static String wakeUpTimeMethodBOCC(String targetShiftTime)
    {
        String wakeUpTime = '';
        if(String.isBlank(targetShiftTime) || targetShiftTime.containsIgnoreCase('None'))
        {
            wakeUpTime = '';
        }
        else
            if(targetShiftTime.equalsIgnoreCase('transition now'))
        {
            wakeUpTime = String.valueOf(System.now().format());
        }
        else
        {
            wakeupTime = String.ValueOf(SC_Utility.getShiftDateTime(targetShiftTime,'BOCC').format()) ;
        }
        
        return wakeUpTime;
        
        
    }
    
    @AuraEnabled
    public static String wakeUpTimeMethod(String targetShiftTime)
    {
        String wakeUpTime = '';
        if(String.isBlank(targetShiftTime) || targetShiftTime.containsIgnoreCase('None'))
        {
            wakeUpTime = '';
        }
        else
            if(targetShiftTime.equalsIgnoreCase('transition now'))
        {
            wakeUpTime = String.valueOf(System.now().format());
        }
        else
        {
            wakeupTime = String.ValueOf(SC_Utility.getShiftDateTime(targetShiftTime,'Akatec').format()) ;
        }
        
        return wakeUpTime;
        
        
    }
    
    @AuraEnabled
    public static Case retCaseDetails(Id caseId)
    {
        Case currentCase = [SELECT OwnerId,Owner.Name,
                            RecordType.Name,Severity__c,has_active_transition__c,
                            Issue_Summary__c,Troubleshooting_to_Date__c,
                            Data_Collected__c,Customer_Expectations__c,
                            Next_Action_Recommendation__c,Case_Product__c,Sub_Type__c
                            FROM Case
                            WHERE id = :caseId
                            LIMIT 1];
        return currentCase;
    }
    
    // changes by Vandhana for ESESP-2346 Carrier LX Migration
    //changes by Saiyam for ESESP-5957 - BOCC case transition.
    @AuraEnabled
    public static Boolean canCreateCT(Case caseObj)
    {
        // Case Owners can create Transition records on Carrier Cases
        if(caseObj.Owner.Name == 'ATS_Transition_Queue' || caseObj.Owner.Name == 'BOCC_Transition_Queue' || (caseObj.OwnerId == UserInfo.getUserId() && caseObj.Sub_Type__c != 'Carrier') || String.valueOf(caseObj.OwnerId).startsWith('00G'))
        {
            return false;
        }
        return true;
    }
    
    //changes by Saiyam for ESESP-5957 - BOCC case transition.
    @AuraEnabled
    public static String createTransitionRec(Case caseRec, Boolean warmTrans, String targetShift)
    {
        String recordSubType = 'Akatec';
        if(caseRec.Sub_Type__c == 'BOCC') 
            recordSubType = 'BOCC';
        Case_Transition__c ctRec = new Case_Transition__c();
        ctRec.Case__c = caseRec.id;
        ctRec.RecordTypeId = Schema.SObjectType.Case_Transition__c.getRecordTypeInfosByName().get(recordSubType).getRecordTypeId();
        ctRec.Severity__c = caseRec.severity__c;
        ctRec.Approved_by__c = UserInfo.getUserId();
        ctRec.Approved_Date__c = System.now();
        ctRec.Warm_Transition_Needed__c = warmTrans;
        ctRec.Target_Shift__c = targetShift;
        ctRec.Issue_Summary__c = caseRec.Issue_Summary__c;
        ctRec.Troubleshooting_to_Date__c = caseRec.Troubleshooting_to_Date__c;
        ctRec.Data_Collected__c = caseRec.Data_Collected__c;
        ctRec.Customer_Expectations__c = caseRec.Customer_Expectations__c;
        ctRec.Next_Action_Recommendation__c =  caseRec.Next_Action_Recommendation__c;
        if(ctRec.Target_Shift__c != 'Transition Now')
        {
            ctRec.Shift_Tracker__c = true;   
        } 
        try
        {
            upsert ctRec;
            return 'success';
        }
        
        // changes by Vandhana - make Case Product mandatory before Case Transition
        catch(exception e)
        {
            return CommonUtilClass.ExtractValidationExMsg(e);
        }
    }

}