/***
PACE_Program2Controller
@version 1.0
@author Hitesh Chawda <hchawda@akamai.com>
@Description : This Class is used for controlling the Program Detail page.
@History
--Developer           --Date            --Change
Hitesh Chawda         05-07-2012         1771607
*/
public with sharing class PACE_Program2Controller {

    public static Id conceptPhaseRecordTypeId =  Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE Concept').getRecordTypeId();
    public static Id definitionPhaseRecordTypeId =  Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();
    public static Id launchPhaseRecordTypeId =      Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Launch').getRecordTypeId();
    public static Id developmentPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Development').getRecordTypeId();

    private ApexPages.StandardController stdCtrl {get; set;}
    public List<PACE_Phase__c> conceptList {get; set;}
    public List<PACE_Phase__c> definitionList {get; set;}
    public List<PACE_Phase__c> developmentList{get;set;}
    public List<PACE_Phase__c> launchList{get; set;}
    // public List<PACE_Program__c> programList{get; set;}
    public set<Id> conStepIdset = new Set<Id>();
    public Set<Id> defStepIdset = new Set<Id>();
    public Set<Id> devStepIdset = new Set<Id>();
    public Set<Id> launchStepIdset = new Set<Id>();
    //public Set<Id> programListId = new Set<Id>();
    //public Set<Id> definitionStepIdSet= new Set<Id>();
    //public List<PACE_Step__c> conStepList {get; set;}
    public List<PACE_Step__c> defStepList{get; set;}
    public List<PACE_Step__c> devStepList{get; set;}
    public List<PACE_Step__c> launchStepList{get; set;}
    public List<PACE_Step__c> conceptstepList{get; set;}
    //public List<ContentVersion> documentList {get;set;}
    public PACE_Program__c programObj{get;set;}
    public Id ProgramId{get; set;}
    public Id conceptId{get;set;}
    public Id definitionId{get;set;}
    public Id developmentId{get;set;}
    public Id launchId{get;set;}
    //public Id phaseID{get;set;}
    //public ContentVersion document{get;set;}
    //public Boolean isDefinitionEnabled{get;set;}
    //public Boolean isConceptEnabled{get;set;}
    //public Boolean isProgramEnabled{get;set;}
    public String activeTabName{get; set;}
    public Id linkStepId{get; set;} 
    public String link{get; set;}
    public Boolean mode{get; set;}
    public Boolean showWarningMessage{get; set;}
    public String documentTitle{get; set;}
    public List<PACE_Document_Link__c> definitionStepDocumentLinkkList{get; set;}
    public String pageID = ApexPages.currentPage().getParameters().get('Id');
    public String pageID2 {get; set;}      
    public List<PACE_Step__c> conceptStepLinkkList{get; set;}
    public List<PACE_Step__c> definitionStepLinkkList{get; set;}
    public List<PACE_Step__c> developmentStepLinkkList{get; set;}
    public List<PACE_Step__c> launchStepLinkkList{get; set;}
    Map<Id,String> stepIdToDocumentLinkMap {get; set;}
    public List<PACE_StepDocumentLinkWrapperClass> conceptstepLinkClassList{get; set;}
    public List<PACE_StepDocumentLinkWrapperClass> defstepLinkClassList{get; set;}
    public List<PACE_StepDocumentLinkWrapperClass> devstepLinkClassList{get; set;}
    public List<PACE_StepDocumentLinkWrapperClass> launchstepLinkClassList{get; set;}

    public List<cHistories> definitionHistoryList{get;set;} 
    public List<cHistories> developmentHistoryList{get;set;}
    public List<cHistories> launchHistoryList{get;set;} 
    public List<cHistories> conceptHistoryList{get;set;}
    public List<cHistories> programHistoryList{get; set;}
    public List<Id> dummyList{get; set;}
    public Id removedocumentLinkId{get; set;}
    public String removedFromTab{get; set;}
   // public Integer i,j;
    // public String tabInFocus;
    public List<PACE_Step__c> stepRecordList;
 //   public List<PACE_Step__c> stepRecordTemp;

   /*public boolean displayPopup {get; set;}     
   public List<PACE_Review_Calendar__c> upcomingPRB{get; set;}
   public List<PACE_Review_Calendar__c> upcomingException{get; set;} 
    public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {        
        displayPopup = true;    
    }
   */ 
    public String selectedTab {
        get {
            for(PACE_Program__c prg :[ Select Last_Saved_Tab__c From PACE_Program__c WHERE Id =:stdCtrl.getId()])
            {
                selectedTab = prg.Last_Saved_Tab__c;
            }

            if (selectedTab == null) {
                selectedTab = 'program';
            }
            return selectedTab;
        }
        set {
            selectedTab = value;
        }
    }


    // Standard constructor for the class
    public PACE_Program2Controller(ApexPages.StandardController std)
    {

        stdCtrl=std;
        pageID2 = stdCtrl.getId();
        conceptList = new List<PACE_Phase__c>();
        definitionList = new List<PACE_Phase__c>();
        developmentList = new List<PACE_Phase__c>();
        launchList = new List<PACE_Phase__c>();
      //  conStepList = new List<PACE_Step__c>();
        defStepList = new List<PACE_Step__c>();
        devStepList = new List<PACE_Step__c>();
        launchStepList = new List<PACE_Step__c>();
        conceptstepList = new List<PACE_Step__c>();
        definitionStepDocumentLinkkList = new List<PACE_Document_Link__c>();
        definitionStepLinkkList = new List<PACE_Step__c>();
        stepIdToDocumentLinkMap = new Map<Id,String>();
        defstepLinkClassList =new List<PACE_StepDocumentLinkWrapperClass>();
        devstepLinkClassList =new List<PACE_StepDocumentLinkWrapperClass>();
        launchstepLinkClassList =new List<PACE_StepDocumentLinkWrapperClass>();
        conceptstepLinkClassList =new List<PACE_StepDocumentLinkWrapperClass>();
        definitionHistoryList = new List<cHistories>();
        developmentHistoryList = new List<cHistories>();
        launchHistoryList = new List<cHistories>();
        conceptHistoryList = new List<cHistories>();
        programHistoryList = new List<cHistories>();
        //upcomingException = new List<PACE_Review_Calendar__c>();
        //upcomingPRB = new List<PACE_Review_Calendar__c>();
        dummyList=new List<Id>();
        link = null;
        selectedTab = 'program';
        stepRecordList = new List<PACE_Step__c>();
        getPhaseRecordsGeneric();
        init();
    }
    // Default constructor being called by Upload Document Page
    public PACE_Program2Controller()
    {
        conceptstepList = new List<PACE_Step__c>();
        stepIdToDocumentLinkMap = new Map<Id,String>();
        conceptstepLinkClassList =new List<PACE_StepDocumentLinkWrapperClass>();
        dummyList=new List<Id>();
        link = null;
        definitionList = new List<PACE_Phase__c>();
        developmentList = new List<PACE_Phase__c>();
        launchList = new List<PACE_Phase__c>();
        defStepList = new List<PACE_Step__c>();
        devStepList = new List<PACE_Step__c>();
        launchStepList = new List<PACE_Step__c>();
        selectedTab = 'program';
        defstepLinkClassList =new List<PACE_StepDocumentLinkWrapperClass>();
        link = null;

    }

    /* Method which queries for the Program of the current page,goes over and gets all the Phases belonging to that Program and individual
    Steps attached to each phase. This list of steps will be used to attach the document links */
    public void getPhaseRecordsGeneric()
{
    PACECustomSettings__c defPahseRecordType = PACECustomSettings__c.getValues('DefinitionPhaseRecordTypeName');
    PACECustomSettings__c devPahseRecordType = PACECustomSettings__c.getValues('DevelopmentPhaseRecordTypeName');
    PACECustomSettings__c launchPahseRecordType = PACECustomSettings__c.getValues('LaunchPhaseRecordTypeName');
    for(PACE_Program__c prg :[ Select Version__c, Last_Saved_Tab__c,  Schedule_Status__c, Resource_Status__c,  Program_Type__c, Program_Phase__c, Program_Manager__c, Product_Manager__c, Product_Line__c,   Name, IsDeleted, Id, Division__c   From PACE_Program__c WHERE Id =:stdCtrl.getId()])
    {
        programObj = prg;
        programId=programObj.Id;
    }

    for(PACE_Phase__c phaseRecord : [Select  Id, Name,RecordType.Name,Target_Phase_Commit_Date__c, SystemModstamp, RecordTypeId, Phase_Review_Approval_Status__c, Phase_Contract_Tolerance_Date__c, Phase_Commit_Date__c, PRB_Review_Date__c, PACE_Program__c, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Exception_Review_Date__c, CurrencyIsoCode, CreatedDate, CreatedById FROM PACE_Phase__c  WHERE  PACE_Program__c= :stdCtrl.getId()])
    { 
        if(phaseRecord.RecordType.Name== defPahseRecordType.Value__c)
        {
            definitionList.add(phaseRecord);
            definitionId = phaseRecord.Id;
        }
        else if(phaseRecord.RecordType.Name== devPahseRecordType.Value__c)
        {
            developmentList.add(phaseRecord);
            developmentId = phaseRecord.Id;
        }
        else if(phaseRecord.RecordType.Name== launchPahseRecordType.Value__c)
        {
            launchList.add(phaseRecord);
            launchId = phaseRecord.Id;
        }
        else if(phaseRecord.RecordType.Name== 'PACE Concept')
        {
            conceptList.add(phaseRecord);
            conceptId = phaseRecord.Id;
        }
    }
  /*  if(programObj.Concept__c != null)
    {
        conceptId = programObj.Concept__c;
    }  */

    //stepRecordTemp = new List<PACE_Step__c>();
    
    stepRecordList = [Select Name,Id,Phase__r.Id,Position__c From PACE_Step__c Where Phase__r.Id = :definitionId 
        OR Phase__r.Id = :developmentId
        OR Phase__r.Id = :launchId
        OR Phase__r.Id = :conceptId
        ORDER BY Position__c ASC];
    
    if(stepRecordList.size()>0)
    {
        for(PACE_Step__c stepItem : stepRecordList)
        {
            if(stepItem.Phase__r.Id == conceptId)
            {
                conceptstepList.add(stepItem);
            }
            else if(stepItem.Phase__r.Id == definitionId)
            {
                defStepList.add(stepItem);
            }
            else if(stepItem.Phase__r.Id == developmentId)
            {
                devStepList.add(stepItem);
            }
            else if(stepItem.Phase__r.Id == launchId)
            {
                launchStepList.add(stepItem);
            }
        }
    }
    
  

}

/* intit() method which gets all the document links and attaches it to the associated Step for a Phase
This method also calls the getHistory method to initialize it at every reload*/

public void init(){ 

    List<Id> stepIds = new List<Id>();
    
    for(PACE_Step__c stepItem : stepRecordList)
    {
        stepIds.add(stepItem.Id);
    }
    
    List<PACE_Document_Link__c> stepDocumentLinkList = [Select Id,Document_URL__c,Name,Step__r.Name,Step__c From PACE_Document_Link__c  where Step__c in :stepIds];
    Map<id,List<PACE_Document_Link__c>> idDocumentLinkListMap=new Map<id,List<PACE_Document_Link__c>>();

    for(PACE_Step__c stepItem : stepRecordList)
    {
        PACE_StepDocumentLinkWrapperClass stepLinkClassItem; 
        List<PACE_Document_Link__c> stepDocLinkList = new List<PACE_Document_Link__c>();

        for(PACE_Document_Link__c stepDocumentLinkItem : stepDocumentLinkList)
        {
            if(stepDocumentLinkItem.Step__c == stepItem.Id)
            {
                stepDocLinkList.add(stepDocumentLinkItem);
            }
        }
        idDocumentLinkListMap.put(stepItem.Id,stepDocLinkList);
        if(idDocumentLinkListMap.get(stepItem.Id)==null)
        {
            idDocumentLinkListMap.put(stepItem.Id,null);
        }
        if(idDocumentLinkListMap.get(stepItem.Id)!=null)
        {
            stepLinkClassItem = new PACE_StepDocumentLinkWrapperClass(stepItem,idDocumentLinkListMap.get(stepItem.Id));
        }
        else
        {
            stepLinkClassItem = new PACE_StepDocumentLinkWrapperClass(stepItem);
        }

        if(stepLinkClassItem != null)
        {
            if(stepLinkClassItem.stepToLinkObject.Phase__r.Id == definitionId)
            {
                defstepLinkClassList.add(stepLinkClassItem);
            }
            else if(stepLinkClassItem.stepToLinkObject.Phase__r.Id == developmentId)
            {
                devstepLinkClassList.add(stepLinkClassItem);
            }
            else if(stepLinkClassItem.stepToLinkObject.Phase__r.Id == launchId)
            {
                launchstepLinkClassList.add(stepLinkClassItem);
            }
            else if(stepLinkClassItem.stepToLinkObject.Phase__r.Id == conceptId)
            {
                conceptstepLinkClassList.add(stepLinkClassItem);
            }
        }


    }
    //Calling the get Histroy method to laod the history on page relaod
    getPhaseHistoryMethod();
  //  getConceptHistoryMethod();
    getProgramHistoryMethod();
   // getUpcomingEventMethod();
}
/* Upload link method is called from the Upload Document page when we attach a link to the Step of a Phase */     

public void uploadLink(){

    List<PACE_Document_Link__c> documentLinkItemList = new List<PACE_Document_Link__c>();
    linkStepId = apexpages.currentpage().getparameters().get('id');
    String tabName = apexpages.currentpage().getparameters().get('tabname');
    Id programId = apexpages.currentpage().getparameters().get('programId');
    
    
    if(link != ''  && documentTitle != '')
    {
        PACE_Document_Link__c documentLink = new  PACE_Document_Link__c(Name = documentTitle, Step__c = linkStepId, Document_URL__c = link );
        documentLinkItemList.add(documentLink);
        if(documentLinkItemList.size() > 0)
        {
            insert documentLinkItemList;
        }  
        
        if(programId!=null){
        PACE_Program__c prog = new PACE_Program__c(Id = programId,Last_Saved_Tab__c = tabName);
        update prog;
        }
        mode = true;
    }  
    else
    {
        ApexPages.Message dupeMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter the Link and the Title');
        ApexPages.addMessage(dupeMsg);
    }

}             

//Method to remove the link uploaded from the Program page at Step level

public PageReference removeLinkMethod()
{
    PageReference programPage = new PageReference('/apex/PACE_ProgramWithTab?id='+pageID);
    
        String tabName = removedFromTab;
        Id programId = pageID;
    
    List<PACE_Document_Link__c> documentLinkList = new List<PACE_Document_Link__c>();

    for(PACE_Document_Link__c documentLink : [Select Id,Name,Document_URL__c From PACE_Document_Link__c where Id =:removedocumentLinkId ]) 
    {
        documentLinkList.add(documentLink);
    }
    if(documentLinkList.size()>0)
    {
        delete documentLinkList;
    }
        
        if(programId!=null){
        PACE_Program__c prog = new PACE_Program__c(Id = programId,Last_Saved_Tab__c = tabName);
        update prog;
        }

    programPage.setRedirect(true);

    return programPage;
}


//Getting the history details for the program records

public void getPhaseHistoryMethod() {
        String type='PACE_Phase__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        String reviewCalendarPrefix = PACE_Review_Calendar__c.SObjectType.getDescribe().getKeyPrefix();// get all objects from the org
        
    // Initialize list to be returned
    list<cHistories> list_ch = new list<cHistories>();
    // Loop through all field history records
    for (PACE_Phase__History fh: [select 
        ParentId, 
        OldValue, 
        NewValue, 
        IsDeleted, 
        Id, 
        Field, 
        CreatedDate, 
        CreatedById,
        CreatedBy.Name
        From PACE_Phase__History
        Where ParentId =:definitionId 
        OR ParentId = :developmentId
        OR ParentId = :launchId
        OR ParentId = :conceptId
        order by CreatedDate desc
    ]) {

        // Create a new wrapper object
        cHistories ch = new cHistories();
        // Set the parentId
        ch.parentId = fh.ParentId;
        // Set the Date
        ch.theDate = String.valueOf(fh.createddate);
        // Set who performed the action
        ch.who = fh.createdby.name;
        // Set the Action value
        if (String.valueOf(fh.Field) == 'created') {    // on Creation
            ch.action = 'Created.';
    } else if (fh.OldValue != null && fh.NewValue == null){ // when deleting a value from a field
        // Format the Date and if there's an error, catch it and re
    try {
        ch.action = 'Deleted ' + Date.valueOf(fh.OldValue).format() + ' in <b>' + String.valueOf(fh.Field) + '</b>.';
    } catch (Exception e){
        ch.action = 'Deleted ' + String.valueOf(fh.OldValue) + ' in <b>' + String.valueOf(fh.Field) + '</b>.';
    }

} else {             // all other scenarios

    String fromText = '';
if (fh.OldValue != null) {
    try {
        fromText = ' from ' + Date.valueOf(fh.OldValue).format();
    } catch (Exception e) {
        fromText = ' from ' + String.valueOf(fh.OldValue);
    }
}

String toText = '';
try {
    //toText = ' from ' + Date.valueOf(fh.NewValue).format();
    toText = Date.valueOf(fh.NewValue).format();
} catch (Exception e) {
    //toText = ' from ' + String.valueOf(fh.NewValue);
    toText = String.valueOf(fh.NewValue);
}
ch.action = '';

if(fromText!=null && toText!=null && !fromText.startsWith(reviewCalendarPrefix) && !toText.startsWith(reviewCalendarPrefix))
{
ch.action = 'Changed <b>' + String.valueOf(fieldMap.get(fh.Field).getDescribe().getLabel()) + '</b>' + fromText + ' to <b>' + toText + '</b>.';
}

}
if(ch.action != '')
{
    list_ch.add(ch); 
}   

}
for(cHistories ch : list_ch)
{
    if(ch.parentId == definitionId)
    {
        definitionHistoryList.add(ch);
    }
    else if(ch.parentId == developmentId)
    {
        developmentHistoryList.add(ch);
    }
    else if(ch.parentId == launchId)
    {
        launchHistoryList.add(ch);
    }
    else if(ch.parentId == conceptId)
    {
        conceptHistoryList.add(ch);
    }
}

}



//Getting the history details for the program records
/*
public void getConceptHistoryMethod() {
    
        //Getting all the API names to get the Label Name  
        String type='PACE_Concept__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        
        //String reviewCalendarPrefix = PACE_Review_Calendar__c.SObjectType.getDescribe().getKeyPrefix();// get all objects from the org
        
    // Initialize list to be returned
    list<cHistories> list_ch = new list<cHistories>();
    // Loop through all field history records
    for (PACE_Concept__History fh: [select 
        ParentId, 
        OldValue, 
        NewValue, 
        IsDeleted, 
        Id, 
        Field, 
        CreatedDate, 
        CreatedById,
        CreatedBy.Name

        From PACE_Concept__History
        Where ParentId = :conceptId
        order by CreatedDate desc
    ]) {

        // Create a new wrapper object
        cHistories ch = new cHistories();
        // Set the parentId
        ch.parentId = fh.ParentId;
        // Set the Date
        ch.theDate = String.valueOf(fh.createddate);

        // Set who performed the action
        ch.who = fh.createdby.name;

        // Set the Action value
        if (String.valueOf(fh.Field) == 'created') {    // on Creation

            ch.action = 'Created.';

    } else if (fh.OldValue != null && fh.NewValue == null){ // when deleting a value from a field

        // Format the Date and if there's an error, catch it and re
    try {
        ch.action = 'Deleted ' + Date.valueOf(fh.OldValue).format() + ' in <b>' + String.valueOf(fh.Field) + '</b>.';
    } catch (Exception e){
        ch.action = 'Deleted ' + String.valueOf(fh.OldValue) + ' in <b>' + String.valueOf(fh.Field) + '</b>.';
    }

} else {             // all other scenarios

    String fromText = '';
if (fh.OldValue != null) {
    try {
        fromText = ' from ' + Date.valueOf(fh.OldValue).format();
    } catch (Exception e) {
        fromText = ' from ' + String.valueOf(fh.OldValue);
    }
}

String toText = '';
try {
    //toText = ' from ' + Date.valueOf(fh.NewValue).format();
    toText = Date.valueOf(fh.NewValue).format();
} catch (Exception e) {
    //toText = ' from ' + String.valueOf(fh.NewValue);
    toText = String.valueOf(fh.NewValue);
}

ch.action = '';
if(fromText!=null && toText!=null && !fromText.startsWith('0') && !toText.startsWith('0') )
{
    ch.action = 'Changed <b>' + String.valueOf(String.valueOf(fieldMap.get(fh.Field).getDescribe().getLabel())) + '</b>' + fromText + ' to <b>' + toText + '</b>.';
}

}
if(ch.action!= '')
{
    list_ch.add(ch);   
} 

}
for(cHistories ch : list_ch)
{
    if(ch.parentId == conceptId)
    {
        conceptHistoryList.add(ch);
    }
}

}*/

/*public void getUpcomingEventMethod()
{
date monthafterdate = system.today().addDays(30);
date currentdate=system.today();

for(PACE_Review_Calendar__c prc:[SELECT Id,Name,Review_Date__c,RecordType.Name FROM PACE_Review_Calendar__c WHERE Review_Date__c > :currentdate and Review_Date__c < :monthafterdate])
{
    if(prc.RecordType.Name=='PRB Review')
    {
        upcomingPRB.add(prc);    
    }
    else if(prc.RecordType.Name=='Exception Review')
    {
        upcomingException.add(prc);    
    }
}

}*/


//Added by Nagdeep 
//Getting the history details for the program records

public void getProgramHistoryMethod() {
    
        //Getting all the API names to get the Label Name  
        String type='PACE_Program__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        
        //String reviewCalendarPrefix = PACE_Review_Calendar__c.SObjectType.getDescribe().getKeyPrefix();// get all objects from the org
        
    // Initialize list to be returned
    list<cHistories> list_ch = new list<cHistories>();
    // Loop through all field history records
    for (PACE_Program__History fh: [select 
        ParentId, 
        OldValue, 
        NewValue, 
        IsDeleted, 
        Id, 
        Field, 
        CreatedDate, 
        CreatedById,
        CreatedBy.Name

        From PACE_Program__History
        Where ParentId = :programId
        order by CreatedDate desc
    ]) {

        // Create a new wrapper object
        cHistories ch = new cHistories();
        // Set the parentId
        ch.parentId = fh.ParentId;
        // Set the Date
        ch.theDate = String.valueOf(fh.createddate);

        // Set who performed the action
        ch.who = fh.createdby.name;

        // Set the Action value
        if (String.valueOf(fh.Field) == 'created') {    // on Creation

            ch.action = 'Created.';

    } else if (fh.OldValue != null && fh.NewValue == null){ // when deleting a value from a field

        // Format the Date and if there's an error, catch it and re
    try {
        ch.action = 'Deleted ' + Date.valueOf(fh.OldValue).format() + ' in <b>' + String.valueOf(fh.Field) + '</b>.';
    } catch (Exception e){
        ch.action = 'Deleted ' + String.valueOf(fh.OldValue) + ' in <b>' + String.valueOf(fh.Field) + '</b>.';
    }

} else {             // all other scenarios

    String fromText = '';
if (fh.OldValue != null) {
    try {
        fromText = ' from ' + Date.valueOf(fh.OldValue).format();
    } catch (Exception e) {
        fromText = ' from ' + String.valueOf(fh.OldValue);
    }
}

String toText = '';
try {
    //toText = ' from ' + Date.valueOf(fh.NewValue).format();
    toText = Date.valueOf(fh.NewValue).format();
} catch (Exception e) {
    //toText = ' from ' + String.valueOf(fh.NewValue);
    toText = String.valueOf(fh.NewValue);
}

ch.action = '';
if(fromText!=null && toText!=null && !fromText.startsWith('0') && !toText.startsWith('0') )
{
    ch.action = 'Changed <b>' + String.valueOf(String.valueOf(fieldMap.get(fh.Field).getDescribe().getLabel())) + '</b>' + fromText + ' to <b>' + toText + '</b>.';
}

}
if(ch.action!= '')
{
    list_ch.add(ch);   
} 

}
for(cHistories ch : list_ch)
{
    if(ch.parentId == programId)
    {
        programHistoryList.add(ch);
    }
}

}






// History Class with the required variables
public class cHistories {

    // Class properties
    public String theDate {get; set;}
    public String who {get; set;}
    public String action {get; set;}
    public Id parentId {get; set;}


}
//Step Document wrapper class
public class PACE_StepDocumentLinkWrapperClass {

    public PACE_Step__c stepToLinkObject{get ; set;}
    public List<PACE_Document_Link__c> documentLinkList {get;set;}
    public PACE_StepDocumentLinkWrapperClass(PACE_Step__c stepToLinkObject,List<PACE_Document_Link__c> documentLinkList)
    {
        this.stepToLinkObject=stepToLinkObject;
        this.documentLinkList=documentLinkList;
    }

    public PACE_StepDocumentLinkWrapperClass(PACE_Step__c stepToLinkObject)
    {
        this.stepToLinkObject=stepToLinkObject;
    }
    public PACE_StepDocumentLinkWrapperClass()
    {

    }
}


}