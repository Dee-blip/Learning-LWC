/* 
Description: Controller extension class for Case creation, Edit and clone dynamic page
Test Class: SC_EditCaseController_Test

Date                        Developer               JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
20 September 2017      Vandhana Krishnamurthy       ESESP-354      Entitled Services on PS Service Cloud Cases
30 Oct 2017             Aditya Sonam                ESESP-786       Custom Case Feed View with Realted List Count 
05 Mar 2019             Pinkesh Rathore             ESESP-2083      Akatec Lightning Migration related changes
22 Aug 2019             Pinkesh Rathore             ESESP-2249      Auto setting of the field "Labels" for PS Cases
25 Oct 2021             Jay Rathod                  ESESP-2264
9  May 2022					Vandhana			 	ESESP-7167		Clear SC IP Scrubbed checkbox on cloned accounts
*/


public with sharing class SC_EditCaseController 
{
    //Private variables
    private string CaseQuery;
    public string defaultServices;
    private boolean onLoadService, onLoadRT, onLoadCC, onLoadAT, onLoadPSRC;
    
    private list<Case_Sections__mdt> sections; 
    private list<Case_Fields__mdt> fields;  
    // commenting out
    /*
private Map<string, string> mpRequestTypes = new Map<string, string>();
private Map<string, string> mpCloseCodes = new Map<string, string>();
private Map<string, string> mpAlertTypes = new Map<string, string>();
private Map<string, string> mpPSRootCauses = new Map<string, string>();
*/
    // end of changes
    private boolean isCloseCase = false;
    private boolean isCloneCase = false;
    private boolean isEditCase = false;
    
    private Set<String> allServValues;
    private Id accId;
    private String fifDigCaseId;
    private Contact conCase;
    
    // Public variables
    public integer relatedCaseCount{get;set;}
    public integer openActivityCount{get;set;}
    public integer activityHistoryCount{get;set;}
    public integer attachmentCount{get;set;}
    public integer caseHistoryCount{get;set;}
    public integer ProjectCaseAssoCount{get;set;}
    public string feedCustFilterItem{get;set;}
    public string filterValue{get;set;}
    
    
    public Map<Case_Sections__mdt, list<Case_Fields__mdt>> mpSections {get; set;}
    public Case objCase {get; set;}
    public CaseComment comment {get; set;}
    
    public String accValue{get;set;}
    public String serValue{get;set;}
    public String reqTypValue{get;set;}
    public String cloCodValue{get;set;}
    public String alertTypeValue{get;set;}
    public String psRootCauseValue{get;set;}
    
    public String changeRecType{get;set;}
    public String changeCaseOwner{get;set;}
    
    public boolean error{get;set;} 
    
    public List<CaseHistory> myCaseHistory;
    public List<CaseHistory> myCaseHistoryValid;
    
    public List<CaseHistory> getmyCaseHistoryValid()
    {
        return myCaseHistoryValid;
    }
    
    public void resetModal()
    {
        System.debug('Old Values !!! : '+accValue+'::'+serValue+'::'+
                     reqTypValue+'::'+cloCodValue+'::'+psRootCauseValue+'::'+alertTypeValue);
        
        this.objCase.AccountId = accValue;
        this.objCase.Service__c = serValue;
        this.objCase.Request_Type__c = reqTypValue;
        this.objCase.Close_Code__c = cloCodValue;
        this.objCase.PS_Root_Cause__c = psRootCauseValue;
        this.objCase.Alert_Type__c = alertTypeValue;
        
        System.debug('New Values !!! : '+this.objCase.AccountId+this.objCase.Service__c+this.objCase.Request_Type__c
                     + this.objCase.Close_Code__c+this.objCase.PS_Root_Cause__c+this.objCase.Alert_Type__c);
    }
    
    // Constructor method
    public SC_EditCaseController(ApexPages.StandardController controller) 
    {
        System.debug('FUNCTION : constructor');
        
        this.objCase = (Case)controller.getRecord();
        
        //This parameter is set when the case close layout needs to open 
        if (ApexPages.currentPage().getParameters().get('close') != null && ApexPages.currentPage().getParameters().get('close') == 'true')
            isCloseCase = true;
        if (ApexPages.currentPage().getParameters().get('clone') != null)
            isCloneCase = true;
        if(this.objCase.Id != null)
            isEditCase = true;
        
        //Initiatize metadata for dynamic page generation
        Initialize();
        
        //fetch case details
        if(this.objCase.Id != null)
        {
            this.objCase = Database.query(CaseQuery);
            if(!String.isBlank(this.objCase.ContactId))
                conCase = [Select Id,Email,Phone from Contact where Id = :this.objCase.ContactId limit 1];
            //Aditya's Changes
            relatedCaseCount = [select count() from Case where ParentId = :this.objCase.Id];
            openActivityCount = [select count() from Task where Status != 'Completed' and WhatId = :this.objCase.Id];
            activityHistoryCount = [select (select Id from ActivityHistories order by ActivityDate DESC, LastModifiedDate DESC limit 500 ) from Case where Id = :this.objCase.Id].ActivityHistories.size();
            attachmentCount = [select count() from Attachment where parentid = :this.objCase.Id];
            caseHistoryCount = [select count() FROM CaseHistory where CaseId = :this.objCase.Id];
            ProjectCaseAssoCount = [select count() from Project_Case_Association__c where Case__c = :this.objCase.Id];
            feedCustFilterItem = 'ChangeStatusPost';
            filterValue = '';
        }
        else
        {   
            this.objCase = new Case();
        }   
        
        //get case record type
        //find all Case record types
        List<Schema.RecordTypeInfo> infos = Schema.SObjectType.Case.RecordTypeInfos;
        Id defaultRecordTypeId;
        
        //check each one
        for (Schema.RecordTypeInfo info : infos) {
            if (info.DefaultRecordTypeMapping) {
                defaultRecordTypeId = info.RecordTypeId;
            }
        }
        if (ApexPages.currentPage().getParameters().get('RecordType') != null)
            this.objCase.RecordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        else if(!(isCloneCase || isEditCase))
            this.objCase.RecordTypeId = defaultRecordTypeId;
        
        
        //This parameter is set when case creation happens from the case related list on account detail page
        if (ApexPages.currentPage().getParameters().get('def_account_id') != null)
            this.objCase.AccountId = ApexPages.currentPage().getParameters().get('def_account_id');
        
        //This parameter is set during related case creation process
        if (ApexPages.currentPage().getParameters().get('def_parent_id') != null)
            this.objCase.ParentId = ApexPages.currentPage().getParameters().get('def_parent_id');
        
        //This parameter is set during related case creation process while cloning the parent case details
        if (ApexPages.currentPage().getParameters().get('cloneparent') != null && ApexPages.currentPage().getParameters().get('cloneparent') == '1')
            this.objCase.ParentId = this.objCase.Id;
        
        //This paramter is set when the case is getting cloned. Akam Case should be unique hence clearing the field for cloned cases.
        //if (ApexPages.currentPage().getParameters().get('clone') != null && ApexPages.currentPage().getParameters().get('cloneparent') == '1')
        if (ApexPages.currentPage().getParameters().get('clone') != null)
            this.objCase.AKAM_Case_ID__c = null;
        
        //variables used on set existing service, request type and close code values on page load
        onLoadService = onLoadRT = onLoadCC = onLoadAT = onLoadPSRC = true;
        
        //system.debug('....Rec Type Issue='+ this.objCase.RecordTypeId);
        allServValues = new Set<String>();
        if(String.isNotBlank(this.objCase.AccountId))
            accId = this.objCase.AccountId;
        
        if(String.isNotBlank(this.objCase.Id))
        {
            fifDigCaseId = this.objCase.Id;
            changeRecType = URL.getSalesforceBaseUrl().toExternalForm() + '/' + 'setup/ui/recordtypeselect.jsp?id=' + fifDigCaseId.substring(0,15)  + '&retURL=%2F' + fifDigCaseId.substring(0,15);
            changeCaseOwner = URL.getSalesforceBaseUrl().toExternalForm() + '/' + fifDigCaseId.substring(0,15) + '/a?retURL=%2F' + fifDigCaseId.substring(0,15);
            
            myCaseHistoryValid = new List<CaseHistory>();
            // populate Case History
            myCaseHistory = [Select OldValue, NewValue, Field, CreatedDate, CreatedBy.Name,
                             CreatedBy.FirstName, CreatedBy.LastName
                             From CaseHistory Where CaseId =:this.objCase.Id ORDER BY CreatedDate DESC limit 50000];
            CaseHistory ch;Boolean creat=false;
            
            for(Integer i=0; i < myCaseHistory.size(); i++)
            {
                try
                {
                    if(myCaseHistory[i].Field.equalsIgnoreCase('Created'))
                    {
                        ch = myCaseHistory[i];
                        creat = true;
                    }
                    else if(myCaseHistory[i].NewValue != null)
                    {
                        String s = (String)myCaseHistory[i].NewValue;
                        Id testId = s;
                    }
                    else if(myCaseHistory[i].oldValue != null)
                    {
                        String s = (String)myCaseHistory[i].oldValue;
                        Id testId = s;
                    }
                    else
                    {
                        myCaseHistoryValid.add(myCaseHistory[i]);
                    }
                }
                catch(Exception e)
                {
                    myCaseHistoryValid.add(myCaseHistory[i]);
                }
            }
            if(creat)
                myCaseHistoryValid.add(ch);
        }
        
    }
    
    //This method is called from SC_CaseOverridePage to decide if the user lands on the overriden page or default case edit/create screen
    
    public PageReference editCaseRedirect()
    {
        PageReference ref = Page.SC_EditCase;
        ref.getParameters().put('id',this.objCase.Id);
        ref.setRedirect(true);
        return ref;
    }   
    
    //This method is called from SC_CaseOverridePage to decide if the user lands on the overriden page or default case edit/create screen
    
    public PageReference Redirect()
    {
        System.debug('FUNCTION : Redirect=' + this.objCase.RecordTypeId);
        System.debug('FUNCTION : Redirect1=' + Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId());
        PageReference ref;
        
        //Navigate user to override page if override is true
        if(this.objCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId())
        {
            System.debug('PS Case');
            ref = Page.SC_EditCase;
        } 
        //Navigate user to default edit page if case already exists
        else if(this.objCase.Id != null) 
        {
            ref = new PageReference('/' + this.objCase.Id + '/e?nooverride=1');
        } 
        //Navigate user to default new case creation screen
        else 
        {
            ref = new PageReference('/' + Schema.Sobjecttype.Case.getKeyPrefix() + '/e?nooverride=1');
        }
        
        //fetch all parameters and pass to the redirected URL
        Map<String, String> parameters = ApexPages.currentPage().getParameters(); 
        
        for(String s: parameters.keySet())
        {
            //exclude sfdc.override and save_new as these cannot be used for overriden functionalities
            if(s != 'sfdc.override' && s != 'save_new')
                ref.getParameters().put(s,parameters.get(s));
        }
        ref.setRedirect(true);
        System.debug('REF : ' + ref);
        return ref;
    }   
    
    //This method is called from SC_CaseCloseOverridePage to decide if the user lands on the overriden page or default case close screen
    public PageReference CloseRedirect()
    {
        System.debug('FUNCTION : CloseRedirect');
        PageReference ref;
        
        //Navigate user to override page if override is true
        if(this.objCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId())
        {
            ref = Page.SC_EditCase;
            ref.getParameters().put('close','true');
        } 
        
        //fetch all parameters and pass to the redirected URL
        Map<String, String> parameters = ApexPages.currentPage().getParameters(); 
        
        for(String s: parameters.keySet())
        {
            if(s != 'sfdc.override' && s != 'save_new')
                ref.getParameters().put(s,parameters.get(s));
        }
        ref.setRedirect(true);
        return ref;
    }   
    
    // This method is called from SC_CaseViewOverridePage to decide if the user lands on the overriden page or default case view page
    public PageReference viewRedirect()
    {
        System.debug('FUNCTION : view Redirect');
        PageReference ref;
        
        //Navigate user to override page if override is true
        if(this.objCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId())
        {
            ref = Page.SC_CaseViewPage;
            ref.getParameters().put('id',this.objCase.Id);
        } 
        //Navigate user to default edit page if case already exists
        else if(this.objCase.Id != null) 
        {
            ref = new PageReference('/' + this.objCase.Id + '?nooverride=1');
        } 
        //fetch all parameters and pass to the redirected URL
        //Map<String, String> parameters = ApexPages.currentPage().getParameters(); 
        
        /*
for(String s: parameters.keySet())
{
//exclude sfdc.override and save_new as these cannot be used for overriden functionalities
if(s != 'sfdc.override' && s != 'save_new' && s != 'id')
ref.getParameters().put(s,parameters.get(s));
}
*/
        ref.setRedirect(true);
        return ref;
    }   
    
    //This method is used to initialize all metadata for the dynamic screen generation
    public void Initialize()
    {
        System.debug('FUNCTION : Initialise');
        
        //get all sections for the page
        //sections = [Select DeveloperName, SectionName__c, Columns__c, Hide_Label__c, Order__c, (Select Label, Field_Name__c, DeveloperName , Required__c, SectionName__c , ReadOnly__c, Overrride__c, Rerender__c, Order__c, Style__c from Case_Fields__r) from Case_Sections__mdt where Record_Type_Name__c = 'Professional Services' and Close_Case_Layout__c = :isCloseCase order by Order__c];
        Map<Id,Case_Sections__mdt> secMap = new Map<Id,Case_Sections__mdt>([Select Id,DeveloperName, SectionName__c, Columns__c, Hide_Label__c, Order__c, (Select Label, Field_Name__c, DeveloperName , Required__c, SectionName__c , ReadOnly__c, Overrride__c, Rerender__c, Order__c, Style__c from Case_Fields__r) from Case_Sections__mdt where Record_Type_Name__c = 'Professional Services' and Close_Case_Layout__c = :isCloseCase order by Order__c]);
        
        //fetch all fields for the sections
        //fields = [Select Label, Field_Name__c, DeveloperName , Required__c, SectionName__c , ReadOnly__c, Overrride__c, Override_method__c , Rerender__c, Order__c, Style__c from Case_Fields__mdt where Record_Type_Name__c = 'Professional Services' and Close_Case_Layout__c = :isCloseCase order by SectionName__c, Order__c];
        fields = [Select Label, Field_Name__c, DeveloperName , Required__c, SectionName__c , ReadOnly__c, Overrride__c, Override_method__c , Rerender__c, Order__c, Style__c from Case_Fields__mdt where Record_Type_Name__c = 'Professional Services' AND Case_Section__c in :secMap.keySet() order by SectionName__c, Order__c];        
        //create a map of section with fields
        mpSections = new Map<Case_Sections__mdt, list<Case_Fields__mdt>>();
        for(Case_Sections__mdt section: secMap.values())
        {
            list<Case_Fields__mdt> lstFields = new list<Case_Fields__mdt>();
            for(Case_Fields__mdt field: fields)
            {
                if(section.DeveloperName == field.SectionName__c)
                {
                    lstFields.add(field);
                }
            }
            mpSections.put(section, lstFields);
        }
        
        //generate the dynamic query for all case fields 
        if(this.objCase.Id != null)
        {
            CaseQuery = 'Select Id';
            for(Case_Fields__mdt field: fields)
            {
                if(String.isNotBlank(field.Field_Name__c))
                    CaseQuery += ', ' + field.Field_Name__c;
            }
            CaseQuery += ' from Case where Id = \'' + this.objCase.Id + '\'';
            if(!CaseQuery.contains('CaseNumber'))
            {
                CaseQuery = CaseQuery.replace('Select Id','Select Id, CaseNumber');
            } 
            if(!CaseQuery.contains('AccountId'))
            {
                CaseQuery = CaseQuery.replace('Select Id','Select Id, AccountId');
            } 
            if(!CaseQuery.contains('IsClosed'))
            {
                CaseQuery = CaseQuery.replace('Select Id','Select Id, IsClosed');
            } 
            if(!CaseQuery.contains('RecordType.Name'))
            {
                CaseQuery = CaseQuery.replace('Select Id','Select Id, RecordType.Name');
            } 
            if(!CaseQuery.contains('Owner.Name'))
            {
                CaseQuery = CaseQuery.replace('Select Id','Select Id, Owner.Name');
            } 
            if(!CaseQuery.contains('ContactId'))
            {
                CaseQuery = CaseQuery.replace('Select Id','Select Id, ContactId');
            } 
            System.debug('CASE QUERY : ' + CaseQuery);
        }
        
        // commenting out unused Metadata for ReqType,CloseCode,AlertType & PSRootCase
        /*
//get service request type mappings
List<SC_Service_ReqType__mdt> servReqType = [Select MasterLabel,Service__c,Request_Type__c from SC_Service_ReqType__mdt];
for(SC_Service_ReqType__mdt req:servReqType)
{
mpRequestTypes.put(req.Service__c,req.Request_Type__c);
}

//get request type close clode mappings
List<SC_ReqType_CloseCode__mdt> reqTypeCloseCode = [Select MasterLabel,Request_Type__c,Close_Code__c from SC_ReqType_CloseCode__mdt];   
for(SC_ReqType_CloseCode__mdt closecode:reqTypeCloseCode)
{
mpCloseCodes.put(closecode.Request_Type__c,closecode.Close_Code__c);
}

//get alert types mappings
List<SC_ReqType_AlertType_Mapping__mdt> reqTypeAlertType = [Select MasterLabel,Request_Type__c,Alert_Type__c from SC_ReqType_AlertType_Mapping__mdt];
for(SC_ReqType_AlertType_Mapping__mdt alertTyp:reqTypeAlertType)
{
mpAlertTypes.put(alertTyp.Request_Type__c,alertTyp.Alert_Type__c);
}

//get PS root cause mappings
List<SC_CloseCode_RootCause_Mapping__mdt > closeCodeRootCause = [Select MasterLabel,Close_Code__c,PS_Root_Cause__c from SC_CloseCode_RootCause_Mapping__mdt];   
for(SC_CloseCode_RootCause_Mapping__mdt closecode:closeCodeRootCause)
{
mpPSRootCauses.put(closecode.Close_Code__c,closecode.PS_Root_Cause__c);
}
*/
        
        //get the default service values
        Case_Service_Value__mdt serviceValues = [Select Service__c from Case_Service_Value__mdt where DeveloperName = 'Professional_Services'];        
        defaultServices = serviceValues.Service__c;
    }
    
    //Dynamically generate the sections and the fields 
    public Component.Apex.outputPanel getDynamicForm()
    {
        System.debug('FUNCTION : getDynamicForm');
        this.objCase.Labels__c = getLabels();
        Component.Apex.outputPanel outPanel = new Component.Apex.outputPanel();  
        outPanel.rendered = true;
        
        //create page section for each section mentioned in the metadata
        for(Case_Sections__mdt section : mpSections.keySet())
        {
            Component.Apex.pageBlockSection pgSection = new Component.Apex.pageBlockSection();
            pgSection.columns= (integer) section.Columns__c;
            pgSection.collapsible=false;
            pgSection.title=section.SectionName__c;
            pgSection.showHeader= section.Hide_Label__c ? false : true;
            list<Case_Fields__mdt> fields = mpSections.get(section);
            
            //create fields for each section
            for(Case_Fields__mdt field:fields)
            {
                Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().get(field.Field_Name__c).getDescribe();
                
                //add fields to layout only if user has access to the same
                if(fieldResult.isAccessible())
                {
                    //add readonly fields to the layout
                    if(field.ReadOnly__c || !fieldResult.isCreateable() || (this.objCase.Id != null && !fieldResult.isUpdateable()))
                    {
                        if(field.DeveloperName == 'Owner' && String.isBlank(this.objCase.Id))
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            Component.Apex.outputText outText = new Component.Apex.outputText();
                            outText.Id = field.DeveloperName;
                            outText.value = UserInfo.getName();
                            sectionItem.childComponents.add(outLabel);
                            sectionItem.childComponents.add(outText);
                            pgSection.childComponents.add(sectionItem);
                        }
                        else
                            if(field.DeveloperName == 'Contact_Email')
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            Component.Apex.outputText outText = new Component.Apex.outputText();
                            outText.Id = field.DeveloperName;
                            if(concase != NULL)
                            {
                                outText.value = conCase.Email;
                                sectionItem.childComponents.add(outLabel);
                                sectionItem.childComponents.add(outText);
                                pgSection.childComponents.add(sectionItem);
                            }
                        }
                        else
                            if(field.DeveloperName == 'Contact_Phone')
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            Component.Apex.outputText outText = new Component.Apex.outputText();
                            outText.Id = field.DeveloperName;
                            if(concase != NULL)
                            {
                                outText.value = conCase.Phone;
                                sectionItem.childComponents.add(outLabel);
                                sectionItem.childComponents.add(outText);
                                pgSection.childComponents.add(sectionItem);
                            }
                        }
                        else
                        {
                            Component.Apex.OutputField outField = new Component.Apex.OutputField();
                            outField.expressions.value = '{!objCase[\'' + field.Field_Name__c + '\']}';
                            outField.id = field.DeveloperName;
                            pgSection.childComponents.add(outField);
                        }
                    }
                    //override normal field functionality
                    else if(field.Overrride__c)
                    {
                        pgSection.childComponents.add(OverrideFields(field));
                    }
                    //add normal input fields to the page
                    else
                    {
                        Component.Apex.InputField inField = new Component.Apex.InputField();
                        inField.expressions.value = '{!objCase[\'' + field.Field_Name__c + '\']}';
                        //inField.id = field.DeveloperName;
                        
                        if(!Test.isRunningTest())
                            inField.required = field.Required__c;
                        
                        // code for required red bar styling
                        Component.Apex.outputPanel reqOutPanel = new Component.Apex.outputPanel(); 
                        
                        reqOutPanel.styleClass = 'requiredInput';
                        reqOutPanel.layout = 'block';
                        
                        Component.Apex.outputPanel innerPanel = new Component.Apex.outputPanel(); 
                        innerPanel.styleClass = 'requiredBlock';
                        innerPanel.layout = 'block';
                        reqOutPanel.childComponents.add(innerPanel);
                        
                        if(field.Style__c != null)
                            inField.style = field.Style__c;
                        
                        //If other fields need to rerender on change of this field, add action region and action support to the field
                        if(field.Rerender__c != null)
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            
                            Component.Apex.actionRegion region = new Component.Apex.actionRegion();
                            Component.Apex.actionSupport support = new Component.Apex.actionSupport();
                            support.event='onchange';
                            support.status = 'mySaveStatus';
                            Set<String> renderFields = new Set<String>();
                            renderFields.addAll(field.Rerender__c.split(','));
                            support.rerender = renderFields;
                            support.immediate = false;
                            inField.childComponents.add(support);
                            region.childComponents.add(inField);
                            sectionItem.childComponents.add(outLabel);
                            
                            if(field.Required__c)
                            {
                                reqOutPanel.id = field.DeveloperName;
                                reqOutPanel.childComponents.add(region);
                                sectionItem.childComponents.add(reqOutPanel);
                            }
                            else{
                                Component.Apex.outputPanel notReqOutPanel = new Component.Apex.outputPanel(); 
                                notReqOutPanel.id = field.DeveloperName;
                                notReqOutPanel.childComponents.add(region);
                                sectionItem.childComponents.add(notReqOutPanel);
                            }
                            
                            pgSection.childComponents.add(sectionItem);
                        }
                        else
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            sectionItem.childComponents.add(outLabel);
                            
                            if(field.Required__c)
                            {
                                reqOutPanel.id = field.DeveloperName;
                                reqOutPanel.childComponents.add(inField);
                                sectionItem.childComponents.add(reqOutPanel);
                                pgSection.childComponents.add(sectionItem);
                            }
                            else{
                                //Changes by Jay for ESESP-2264
                                inField.id = field.DeveloperName;
                                pgSection.childComponents.add(inField);
                            }
                            
                        }
                    }
                }
            }
            
            //add all sections to the output panel
            //outPanel.childComponents.add(pgSection);
            
            if(pgSection.childComponents.size() > 0)
                outPanel.childComponents.add(pgSection);
        }
        
        return outPanel;
    }
    
    //This method is used to dynamically generate all overriden picklists
    public Component.Apex.pageBlockSectionItem OverrideFields(Case_Fields__mdt field)
    {
        Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
        
        // code for required red bar styling
        Component.Apex.outputPanel reqOutPanel = new Component.Apex.outputPanel(); 
        reqOutPanel.styleClass = 'requiredInput';
        reqOutPanel.layout = 'block';
        
        Component.Apex.outputPanel innerPanel = new Component.Apex.outputPanel(); 
        innerPanel.styleClass = 'requiredBlock';
        innerPanel.layout = 'block';
        reqOutPanel.childComponents.add(innerPanel);
        
        
        Component.Apex.SelectList Sellist = new Component.Apex.SelectList();
        Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
        outLabel.value = field.Label;
        outLabel.for = field.DeveloperName;
        sectionItem.childComponents.add(outLabel);
        
        //value of picklist is corresponding case field
        Sellist.expressions.value='{!objCase[\'' + field.Field_Name__c + '\']}';
        Sellist.required = field.Required__c;
        
        Sellist.id = field.DeveloperName;
        Sellist.title = field.Label;
        Sellist.style = field.Style__c;
        Sellist.multiselect = false;
        Sellist.size = 1;
        
        //picklist dropdown values will be fetched from corresponding getter. Getter format get + 'field.DeveloperName' + s eg. getServices.
        Component.Apex.SelectOptions SelOptions = new Component.Apex.SelectOptions();
        SelOptions.expressions.value='{!' + field.Override_method__c + '}';
        Sellist.childComponents.add(SelOptions);
        
        //If picklist needs to rerender other fields, add the same in action regoin and action support
        if(field.Rerender__c != null)
        {            
            Component.Apex.actionRegion region = new Component.Apex.actionRegion();
            Component.Apex.actionSupport support = new Component.Apex.actionSupport();
            support.event='onchange';
            support.status = 'mySaveStatus';
            Set<String> renderFields = new Set<String>();
            renderFields.addAll(field.Rerender__c.split(','));
            support.rerender = renderFields;
            support.immediate = false;
            Sellist.childComponents.add(support);
            region.childComponents.add(Sellist);
            
            if(field.Required__c)
            {
                reqOutPanel.childComponents.add(region);
                sectionItem.childComponents.add(reqOutPanel);
            }
            else
                sectionItem.childComponents.add(region);
        }
        else
        {
            if(field.Required__c)
            {
                reqOutPanel.childComponents.add(Sellist);
                sectionItem.childComponents.add(reqOutPanel);
            }
            else
                sectionItem.childComponents.add(Sellist);
        }
        //return the section item
        return sectionItem;
    }
    
    // dynamic form for Case View
    //Dynamically generate the sections and the fields 
    public Component.Apex.outputPanel getViewDynamicForm()
    {
        
        Component.Apex.outputPanel outPanel = new Component.Apex.outputPanel();  
        outPanel.rendered = true;
        
        
        //create page section for each section mentioned in the metadata
        for(Case_Sections__mdt section : mpSections.keySet())
        {
            Component.Apex.pageBlockSection pgSection = new Component.Apex.pageBlockSection();
            pgSection.columns = (Integer)section.Columns__c;
            pgSection.collapsible = false;
            pgSection.title = section.SectionName__c;
            pgSection.id = section.DeveloperName + 'sectionHeaderID';
            pgSection.showHeader = section.Hide_Label__c ? false : true;
            List<Case_Fields__mdt> fields = mpSections.get(section);
            
            //create fields for each section
            for(Case_Fields__mdt field:fields)
            {
                Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().get(field.Field_Name__c).getDescribe();
                
                //add fields to layout only if user has access to the same
                if(fieldResult.isAccessible())
                {
                    //add readonly fields to the layout
                    if(field.ReadOnly__c || !fieldResult.isCreateable() || (this.objCase.Id != null && !fieldResult.isUpdateable()))
                    {
                        if(field.Field_Name__c == 'RecordTypeId' || field.Field_Name__c == 'OwnerId')
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            
                            Component.Apex.outputText outText = new Component.Apex.outputText();
                            outText.Id = field.DeveloperName;
                            
                            Component.Apex.outputPanel innerOutPanel = new Component.Apex.outputPanel();
                            Component.Apex.outputLink outLink = new Component.Apex.outputLink();
                            
                            if(field.Field_Name__c == 'RecordTypeId')
                            {
                                outText.value = this.objCase.RecordType.Name;
                                outLink.expressions.value = '{!changeRecType}';
                                Component.Apex.outputLabel outlab = new Component.Apex.outputLabel(value='[Change]');
                                outLab.style = 'cursor: pointer; cursor: hand;';
                                outLink.childComponents.add(outlab);
                            }   
                            else if(field.Field_Name__c == 'OwnerId')
                            {
                                outText.value = this.objCase.Owner.Name;
                                outLink.expressions.value = '{!changeCaseOwner}';
                                Component.Apex.outputLabel outlab = new Component.Apex.outputLabel(value='[Change]');
                                outLab.style = 'cursor: pointer; cursor: hand;';
                                outLink.childComponents.add(outlab);
                            }
                            
                            innerOutPanel.childComponents.add(outText);
                            innerOutPanel.childComponents.add(outLink);
                            
                            sectionItem.childComponents.add(outLabel);
                            sectionItem.childComponents.add(innerOutPanel);
                            pgSection.childComponents.add(sectionItem);
                        }
                        else
                        {
                            Component.Apex.OutputField outField = new Component.Apex.OutputField();
                            outField.expressions.value = '{!objCase[\'' + field.Field_Name__c + '\']}';
                            outField.id = field.DeveloperName + 'lockedField';
                            pgSection.childComponents.add(outField);   
                        }
                    }
                    else
                        if(field.Overrride__c)
                    {
                        Component.Apex.pageBlockSectionItem sectionItem1 = new Component.Apex.pageBlockSectionItem(id=field.DeveloperName+'SecItem');
                        sectionItem1.onDatadblclick = 'openDialogBox();';
                        
                        Component.Apex.outputLabel outLabel1 = new Component.Apex.outputLabel();
                        outLabel1.value = field.Label;
                        outLabel1.for = field.DeveloperName;
                        
                        Component.Apex.OutputText pickText = new Component.Apex.OutputText(id=field.DeveloperName+'text');
                        //pickText.expressions.value = '{!if(objCase.Service__c == \'--None--\',NULL,' + objCase.Service__c + ')}';
                        pickText.expressions.value = '{!if(objCase[\'' + field.Field_Name__c + '\'] == \'--None--\',NULL,' + 'objCase[\'' + field.Field_Name__c + '\'])}';
                        pickText.style = 'cursor: default;';
                        pickText.styleClass = 'noselect';
                        sectionItem1.childComponents.add(outLabel1);
                        
                        sectionItem1.childComponents.add(pickText);
                        
                        //sectionItem.childComponents.add(servText);
                        
                        pgSection.childComponents.add(sectionItem1);
                        //pgSection.childComponents.add(OverrideFields(field));
                    }
                    else
                        // add normal output field
                    {
                        Component.Apex.OutputField outField = new Component.Apex.OutputField();
                        outField.expressions.value = '{!objCase[\'' + field.Field_Name__c + '\']}';
                        outField.id = field.DeveloperName;
                        if(field.Style__c != null)
                            outField.style = field.Style__c;
                        
                        Component.Apex.inlineEditSupport ies = new Component.Apex.inlineEditSupport();
                        ies.showOnEdit = 'saveButton,cancelButton'; 
                        ies.hideOnEdit = 'indCustButton,reopenButton,cloneButton,editButton,deleteButton,closeCaseButton';
                        //ies.resetFunction = 'resetInlineEdit';
                        ies.changedStyleClass = 'myBoldClass';
                        if(field.DeveloperName != 'AccountName' && field.DeveloperName != 'PSRootCause' && field.DeveloperName != 'AlertType' && field.DeveloperName != 'CloseCode' && field.DeveloperName != 'RequestType')
                            outField.childComponents.add(ies);
                        
                        //If other fields need to be rerendered on change of this field, add action region and action support for this field
                        if(field.Rerender__c != null)
                        {
                            if(field.DeveloperName == 'AccountName')
                            {
                                Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                                sectionItem.id = field.DeveloperName+'SecItem';
                                sectionItem.onDatadblclick = 'openDialogBox();';
                                outField.id = field.DeveloperName+'text';
                                Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                                outLabel.value = field.Label;
                                outLabel.for = field.DeveloperName;
                                sectionItem.childComponents.add(outLabel);
                                
                                sectionItem.childComponents.add(outField);
                                
                                pgSection.childComponents.add(sectionItem);
                            }
                            else
                            {
                                System.debug('Normal field Rerender : ' + field.Label + ' : ' + field.Rerender__c);
                                
                                Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                                Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                                outLabel.value = field.Label;
                                outLabel.for = field.DeveloperName;
                                
                                Component.Apex.actionRegion region = new Component.Apex.actionRegion();
                                Component.Apex.actionSupport support = new Component.Apex.actionSupport();
                                support.event='onchange';
                                support.status = 'newStatus';
                                Set<String> renderFields = new Set<String>();
                                renderFields.addAll(field.Rerender__c.split(','));
                                support.rerender = renderFields;
                                support.immediate = false;
                                outField.childComponents.add(support);
                                region.childComponents.add(outField);
                                sectionItem.childComponents.add(outLabel);
                                
                                sectionItem.childComponents.add(region);
                                
                                pgSection.childComponents.add(sectionItem);
                            }
                        }
                        else
                        {
                            Component.Apex.pageBlockSectionItem sectionItem = new Component.Apex.pageBlockSectionItem();
                            if( field.DeveloperName == 'PSRootCause' || field.DeveloperName == 'AlertType' 
                               || field.DeveloperName == 'CloseCode' || field.DeveloperName == 'RequestType')
                            {
                                sectionItem.id = field.DeveloperName+'SecItem';
                                sectionItem.onDatadblclick = 'openDialogBox();';
                                outField.id = field.DeveloperName+'text';
                            }   
                            Component.Apex.outputLabel outLabel = new Component.Apex.outputLabel();
                            outLabel.value = field.Label;
                            outLabel.for = field.DeveloperName;
                            sectionItem.childComponents.add(outLabel);
                            
                            sectionItem.childComponents.add(outField);
                            
                            pgSection.childComponents.add(sectionItem);
                        }
                    }
                }
            }
            
            if(pgSection.childComponents.size() > 0)
                outPanel.childComponents.add(pgSection);
            
        }
        return outPanel;
    }
    
    
    //populate status with Closed on Close Case page
    public List<SelectOption> getStatuss()
    {
        System.debug('FUNCTION : getStatuss');
        List<SelectOption> lstOptions = new List<SelectOption>();
        lstOptions.add(new SelectOption('Closed','Closed'));
        System.debug('Status Options !!!' + lstOptions);
        return lstOptions;
    }
    
    //This method is used to dynamically fetch the entitled + default services values after case account is selected 
    public List<SelectOption> getServices()
    {
        System.debug('FUNCTION : getServices');
        System.debug('Account ID !!! : ' + this.objCase.AccountId);
        System.debug('OnLoad Account ID !!! : ' + accId);
        if(this.objCase.AccountId == accId)
            System.debug('SAME ACCOUNT ');
        else
            System.debug('DIFFERENT ACCOUNT ');
        System.debug('Service :  !!! : ' + this.objCase.Service__c);
        System.debug('OnLoadService :  !!! : ' + onLoadService);
        
        List<SelectOption> lstOptions = new List<SelectOption>();
        
        set<String> serviceOptions = new set<String>();
        
        // If no Account exists/is selected, set Service to --None--
        if(this.objCase.AccountId == NULL)
        {
            System.debug('Account blank');
            this.objCase.Service__c = '--None--';
            lstOptions.add(new SelectOption('--None--','--None--'));
        }
        
        //Add service values if account is selected
        else 
        {
            System.debug('Account present');
            
            //Add current Service value to the drop down on loading case for editing
            if(String.isNotBlank(this.objCase.Service__c))
            {    
                if(this.objCase.Service__c != '--None--')
                {
                    if(onLoadService || accId == this.objCase.AccountId)
                    {
                        System.debug('inside OnLoadService');
                        serviceOptions.add(this.objCase.Service__c);
                        onLoadService = false;
                    }
                }
            }
            
            //get the list of entitled services for account and add to list
            /*
List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> lstMktgEnggProd = [Select Area__c,Account__c, Contract_ID__c, Product_ID__c, Marketing_Product_Name__c from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c where Account__c = :this.objCase.AccountId and Area__c like '%Professional_Services%'];

if(lstMktgEnggProd.size() > 0)
{
for(SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c product : lstMktgEnggProd)
{
serviceOptions.add(product.Marketing_Product_Name__c);
}
}
*/
            
            //get list of Entitled Services for select Account and add to list
            for(String product : fetchEntitledServices(this.objCase.AccountId))
            {
                serviceOptions.add(product);
            }
            
            System.debug('Service Options : ' + serviceOptions);
            
            // Add default services
            for(String s : defaultServices.split('\n'))
            {
                serviceOptions.add(s.trim());
                allServValues.add(s.trim());
            }
            
            // populate Service Picklist with value,name
            for(String s : serviceOptions)
            {
                lstOptions.add(new SelectOption(s,s));
            }    
            
            // sort Service options alphabetically
            lstOptions.sort();
            
            // add --None-- as the 1st option
            lstOptions.add(0,new SelectOption('--None--','--None--'));
            
            //If the currently selected service value is not valid for current account selection, set the service to --None--
            if(!serviceOptions.contains(this.objCase.Service__c))
            {
                System.debug('Invalid Service');
                this.objCase.Service__c = '--None--';
            }
        }
        System.debug('Service Options !!!' + lstOptions);
        return lstOptions;
    }
    
    
    // get list of Entitled Services for incoming Account
    public List<String> fetchEntitledServices(Id acId)
    {
        List<String> entServ = new List<String>();
        List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> lstMktgEnggProd = [Select Area__c,Account__c, Contract_ID__c, Product_ID__c, Marketing_Product_Name__c 
                                                                            from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c 
                                                                            where Account__c = :acId and Area__c like '%Professional_Services%'];
        if(lstMktgEnggProd.size() > 0)
        {
            for(SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c product : lstMktgEnggProd)
            {
                entServ.add(product.Marketing_Product_Name__c);
            }
        }
        return entServ;
    }
    
    // get list of Request Type values for the select Service
    /*
public list<SelectOption> getRequestTypes()
{
System.debug('getReqType called');
System.debug('Service !!! ' + this.objCase.Service__c);

Set<String> reqTypeOptions = new set<String>();
list<SelectOption> lstOptions = new list<SelectOption>();

//If Service is not selected, set request type to --None--
if(this.objCase.Service__c == NULL || this.objCase.Service__c == '' || this.objCase.Service__c == '--None--')
{
this.objCase.Request_Type__c = '--None--';
lstOptions.add(new SelectOption('--None--','--None--'));
}
else
{    
//add the currently saved request type to list on case edit load
if(String.isNotBlank(this.objCase.Request_Type__c) && this.objCase.Request_Type__c != '--None--' && onLoadRT)
{    
reqTypeOptions.add(this.objCase.Request_Type__c);
onLoadRT = false;
}
//get the list of request types for selected service 
if(mpRequestTypes.containsKey(this.objCase.Service__c))
{ 
for(String eachReqType : mpRequestTypes.get(this.objCase.Service__c).split('\n'))
{
reqTypeOptions.add(eachReqType.trim());
}
}
//if request types values are available add them to the list
if(reqTypeOptions.size() > 0)
{
for(String s : reqTypeOptions)
lstOptions.add(new SelectOption(s,s));
lstOptions.sort();
lstOptions.add(0,new SelectOption('--None--','--None--'));

//if currently selected request type is not valid for the selected service, set request type to --None--
if(!reqTypeOptions.contains(this.objCase.Request_Type__c)){
this.objCase.Request_Type__c = '--None--';
}
}
//if no request types are available set request type as --None--
else
{
this.objCase.Request_Type__c = '--None--';
lstOptions.add(new SelectOption('--None--','--None--'));
}
}
return lstOptions;
}

// get list of Close Code values for the select Request Type
public list<SelectOption> getCloseCodes()
{
System.debug('getCloseCode called');
System.debug('Service !!! ' + this.objCase.Service__c);
System.debug('Request Type !!! ' + this.objCase.Request_Type__c);

set<String> closeCodeOptions = new set<String>();
list<SelectOption> lstOptions = new list<SelectOption>();

//set close code to --None-- if no request type is selected
if(this.objCase.Request_Type__c == NULL || this.objCase.Request_Type__c == '' || this.objCase.Request_Type__c == '--None--')
{
this.objCase.Close_Code__c = '--None--';
lstOptions.add(new SelectOption('--None--','--None--'));
}
else
{    
//add the currently saved close code value on case edit load
if(String.isNotBlank(this.objCase.Close_code__c) && this.objCase.Close_code__c != '--None--'  && onLoadCC)
{    
closeCodeOptions.add(this.objCase.Close_code__c);
onLoadCC = false;
}

//get the close code mappings for the selected 
if(mpCloseCodes.containsKey(this.objCase.Request_Type__c))
{
for(String eachCloseCode : mpCloseCodes.get(this.objCase.Request_Type__c).split('\n'))
{
closeCodeOptions.add(eachCloseCode.trim());
}
}

//if close code values exist, add them to the list options
if(closeCodeOptions.size()>0)
{
for(String s : closeCodeOptions)
lstOptions.add(new SelectOption(s,s));
lstOptions.sort();
lstOptions.add(0,new SelectOption('--None--','--None--'));

//if currently selected close clode value is not valid for the request type, make it --None--
if(!closeCodeOptions.contains(this.objCase.Close_code__c)){
this.objCase.Close_code__c = '--None--';
}
}
//if no close code mapping is present, set close code to --None--
else
{
this.objCase.Close_Code__c = '--None--';
lstOptions.add(new SelectOption('--None--','--None--'));
}
}
System.debug('Close Code OPTIONS : ' + lstOptions);

return lstOptions;
}

/*
// get list of Alert Type values for the select Request Type
public list<SelectOption> getAlertTypes()
{
System.debug('getAlertTypes called');
System.debug('Request Type !!! ' + this.objCase.Request_Type__c);

Set<String> alertTypeOptions = new set<String>();
list<SelectOption> lstOptions = new list<SelectOption>();

//set close code to --None-- if no request type is selected
if(this.objCase.Request_Type__c == NULL || this.objCase.Request_Type__c == '' || this.objCase.Request_Type__c == '--None--')
{
lstOptions.add(new SelectOption('--None--','--None--'));
}
else
{    
if(mpAlertTypes.containsKey(this.objCase.Request_Type__c))
{
for(String eachAlertType : mpAlertTypes.get(this.objCase.Request_Type__c).split('\n'))
{
alertTypeOptions.add(eachAlertType.trim());
}
}

if(alertTypeOptions.size()>0)
{
for(String s : alertTypeOptions)
lstOptions.add(new SelectOption(s,s));
lstOptions.sort();
lstOptions.add(0,new SelectOption('--None--','--None--'));
}
else
{
lstOptions.add(new SelectOption('--None--','--None--'));
}
}
System.debug('Alert Type OPTIONS : ' + lstOptions);
return lstOptions;
}


// get list of PS Root Cause values for the select Close Code
public list<SelectOption> getPSRootCauses()
{
System.debug('getPSRootCauses called');
System.debug('Close Code !!! ' + this.objCase.Close_Code__c);

Set<String> psRootCauseOptions = new set<String>();
list<SelectOption> lstOptions = new list<SelectOption>();

//set close code to --None-- if no request type is selected
if(this.objCase.Close_Code__c == NULL || this.objCase.Close_Code__c == '' || this.objCase.Close_Code__c == '--None--')
{
this.objCase.PS_Root_Cause__c = '--None--';
lstOptions.add(new SelectOption('--None--','--None--'));
}
else
{    
//add the currently saved close code value on case edit load
if(String.isNotBlank(this.objCase.PS_Root_Cause__c) && this.objCase.PS_Root_Cause__c != '--None--'  && onLoadPSRC)
{    
psRootCauseOptions.add(this.objCase.PS_Root_Cause__c);
onLoadPSRC = false;
}

//get the close code mappings for the selected 
if(mpPSRootCauses.containsKey(this.objCase.Close_Code__c))
{
for(String eachPSRootCause : mpPSRootCauses.get(this.objCase.Close_Code__c).split('\n'))
{
psRootCauseOptions.add(eachPSRootCause.trim());
}
}

//if close code values exist, add them to the list options
if(psRootCauseOptions.size()>0)
{
for(String s : psRootCauseOptions)
lstOptions.add(new SelectOption(s,s));
lstOptions.sort();
lstOptions.add(0,new SelectOption('--None--','--None--'));
}
//if no close code mapping is present, set close code to --None--
else
{
this.objCase.PS_Root_Cause__c = '--None--';
lstOptions.add(new SelectOption('--None--','--None--'));
}
}
System.debug('PS Root Cause OPTIONS : ' + lstOptions);
return lstOptions;
}
*/
    
    // Save Case record to Database
    public PageReference Save()
    {
        System.debug('FUNCTION : Save');
        try
        {
            error = false;
            
            for(Case_Fields__mdt field : fields)
            {
                System.debug('Field ' + field.Field_Name__c + ' : ' + this.objCase.get(field.Field_Name__c));
                
                //Replace all --None-- values with null
                if(this.objCase.get(field.Field_Name__c) == '--None--')
                    this.objCase.put(field.Field_Name__c,NULL);
                
                //check for required fields for case else add error
                if(field.Required__c && this.objCase.get(field.Field_Name__c) == NULL)
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,field.Label + ': You must enter a value'));
                    error = true;
                }  
            }
            
            if(this.objCase.Request_Type__c != 'Performance Alert')
            {
                System.debug('Request Type NOT PErformance Alert');
                this.objCase.Alert_Type__c = NULL;
            }    
            
            if(this.objCase.AccountId != accId && !String.isBlank(accId))
            {
                for(String product : fetchEntitledServices(this.objCase.AccountId))
                {
                    allServValues.add(product);
                }
                
                System.debug('List of all services : ' + allServValues);
                if(!allServValues.contains(this.objCase.Service__c))
                {
                    System.debug('INVALID SERVICE');
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'The selected Service ' + this.objCase.Service__c + ' is invalid for the Account. Please select a valid Service.'));
                    error = true;
                }
            }
            
            //https://akamai--cmcdev.cs65.my.salesforce.com/apex/SC_CaseOverridePage?clone=1&retURL=%2F5000m000001bXyb&scontrolCaching=1&_CONFIRMATIONTOKEN=VmpFPSxNakF4Tnkwd09TMHdOMVF3TnpveE5UbzFNaTR6TnpWYSxvQnNFV05hQmxyVk4wdjF5elF3QV9iLFlUSmtOamd5&common.udd.actions.ActionsUtilORIG_URI=%2F5000m000001bXyb%2Fe&sfdc.override=1&id=5000m000001bXyb
            
            //if no error proceed to save
            if(!error)
            {
                //if user is cloning the case, then blank out the case id, so as to create a new case
                if (ApexPages.currentPage().getParameters().get('clone') != null && ApexPages.currentPage().getParameters().get('clone') == '1')
                {
                    this.objCase.Id = null;
                    this.objCase.AKAM_Case_ID__c = null;
                }
                //save the data and redirect user to the case detail page
                upsert this.objCase;
                PageReference ref = new PageReference('/' + this.objCase.Id);
                ref.setRedirect(true);
                return ref;
            }
        } 
        catch (Exception ex) 
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,CommonUtilClass.ExtractValidationExMsg(ex)));
        }
        return null;
    }
    
    // Code emulates Re-open closed Case javascript button on Case
    public PageReference reopenCase()
    {
        if(this.objCase.IsClosed) 
        {
            Date todayDate = Date.today();
            Date closeDate = Date.newinstance(this.objCase.AKAM_Closed_Date__c.year(), this.objCase.AKAM_Closed_Date__c.month(), this.objCase.AKAM_Closed_Date__c.day());
            Double days = Math.floor(((todayDate.daysBetween(closeDate))/1000/60/60/24));
            if(days <= 30) 
            {
                List<Case> updateRecord = new List<Case>(); 
                
                Case update_Case = new Case();
                update_Case.Id = this.objCase.Id;
                update_Case.Reopened__c = true; 
                update_Case.Status = 'Reopened';
                update_Case.AKAM_Closed_Date__c = null;
                update_Case.AKAM_Reopened_Date__c = todayDate;
                update_Case.Is_IP_Scrubbed__c = false;
                update_Case.IP_Scrubbing_Failed_Objects__c = null;
                updateRecord.add(update_Case);
                
                Database.SaveResult[] srList = Database.update(updateRecord, false);
                
                for (Database.SaveResult sr : srList) 
                {
                    if (sr.isSuccess()) 
                    {
                        //PageReference ref = Page.SC_CaseViewPage;
                        //ref.getParameters().put('id',this.objCase.id);
                        PageReference ref = new PageReference('/' + this.objCase.Id);
                        ref.setRedirect(true);
                        return ref;
                    } 
                    else 
                    {
                        for(Database.Error err : sr.getErrors()) 
                        {
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'An error occurred updating this record: ' + err.getMessage()));
                        }
                    }
                }
            } 
            else 
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Cases can only be reopened within 30 days of case closure. Please create a new case'));
            }
        } 
        else 
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Re-open is only available on closed cases.'));
        }
        return NULL; 
    }
    
    public PageReference refreshFeed() {
        return null;
    }
    
    public void refreshChatterFilter(){
        feedCustFilterItem = filterValue;
        
    }
    
    //ESESP-2249
    public String getLabels(){
        if(this.objCase.AccountId != null){
            //Get List of all English Regions
            List<String> lEnglishRegions = new List<String>();
            for(SC_Utility__mdt eachrec : [Select id, DeveloperName, Value_Text__c from SC_Utility__mdt where Active__c = true and DeveloperName like 'English_Region_%']){
                lEnglishRegions.addAll(eachrec.Value_Text__c.split('#'));
            }
            
            //Get List of Premium & MSS services and products on account
            List<String> lMSSProducts = new List<String>();
            for(SC_Utility__mdt eachrec : [Select id, DeveloperName, Value_Text__c from SC_Utility__mdt where Active__c = true and DeveloperName like 'Account_Service_Support_Products_%']){
                lMSSProducts.addAll(eachrec.Value_Text__c.split('#'));
            }
            
            //if isCOEOnly = True, then set Labels = 'COE Only'
            Boolean isCOEOnly = true;
            
            String commercialSegmentation;
            String region;
            
            //get Account Service & Support Products
            List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> lProducts = [SELECT Id, Marketing_Product_Name__c, Effective_Start_Date__c, Effective_End_Date__c, Account__c, Account__r.Commercial_Segmentation__c, Account__r.Division__c, Name FROM SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c where Account__c =:this.objCase.AccountId];
            if(lProducts != null && lProducts.size()>0){
                commercialSegmentation = lProducts[0].Account__r.Commercial_Segmentation__c;
                region = lProducts[0].Account__r.Division__c;
            }
            else{
                Account acc = [Select Id, Commercial_Segmentation__c, Division__c from Account where Id =:this.objCase.AccountId limit 1];
                commercialSegmentation = acc.Commercial_Segmentation__c;
                region = acc.Division__c;
            }
            
            //Criteria 1: to check if entitlement  = 'Premium' or 'Managed Security Services'
            for(SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c eachRec : lProducts){
                if(!String.isBlank(eachRec.Marketing_Product_Name__c) && lMSSProducts.contains(eachRec.Marketing_Product_Name__c)
                    && (eachRec.Effective_Start_Date__c != null && eachRec.Effective_Start_Date__c <= System.today())
                    && (eachRec.Effective_End_Date__c == null || eachRec.Effective_End_Date__c >= System.today())
                  ){
                    isCOEOnly = false;
                    break;
                }
            }
            
            //Criteria 2: to check if Commercial_Segmentation__c = ‘Preferred Growth’ OR ‘Preferred Mature’ OR Blank
            if(String.isBlank(commercialSegmentation) || commercialSegmentation.equals('Preferred Growth') || commercialSegmentation.equals('Preferred Mature'))
                isCOEOnly = false;
            
            //Criteria 3: to check if Region is English
            if(String.isBlank(region) || !lEnglishRegions.contains(region))
                isCOEOnly = false;
            
            if(isCOEOnly)
                return 'COE Only';
        }
        return '';
    }
    
    public List<SelectOption> getCaseProducts(){
        List<SelectOption> options = new List<SelectOption>{
                new SelectOption('','--None--')
        };
        if (!String.isBlank(this.objCase.AccountId)) {
            for(EB_AccountProductMap__c product : [SELECT Id,Name FROM EB_AccountProductMap__c WHERE EB_Account__c =:this.objCase.AccountId AND EB_MarkedForDeletion__c=FALSE ORDER BY Name ASC]){
                options.add(new SelectOption(product.Id,product.Name));
            }
        }
        return options;
    }
    
}