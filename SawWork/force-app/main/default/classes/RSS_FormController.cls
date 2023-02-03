/*
RSS_FormController : Controller for RSSForm page
Creates new RSS Forms, saves, submits, publishes and clones forms

Developer                           Date
1. Sharath Prasanna             7 March, 2016
2. Vandhana Krishnamurthy       7 March, 2016

Vandhana                        25 April, 2016 for CR 3350181
Sharath                         25 April, 2016 for CR 3147531

Vandhana                        30 June, 2016 for CR 3393971
Sharath                         19 July, 2016 for CR 3385611

//Changes by Sharath on 20th June 2018: Removed the query from the or loop for FFPSA-607

//Changes by Sandeep Naga on 28th November 2018: Merged custom metadata from eRSS_Hostname_Delimiters__mdt to PSA_Common_Setting__mdt



*/


public class RSS_FormController 
{
    public LIST<RSSResponseGroupWrapper> pdfResponseGroupWrappers {get;set;}
    public Boolean Disabled {get;set;}
    
    public Boolean DisabledAttachment {get;set;}
    //public Attachment attachment {get { if(attachment==null){ attachment = new Attachment();}return attachment;}set;}
    //public Boolean WriteAccessOfUser{get {if(WriteAccessOfUser==null){
    //WriteAccessOfUser = RSSUtility.FormWriteAccess(UserInfo.getUserId());  } return WriteAccessOfUser;} set; }
    public boolean RefreshAttachments{ get;set;}
    public Boolean showOwner{get;set;}
    public Map<String,List<RSSQuestionResponse>> pdftempMap {get;set;}

    //Start of changes by shprasan
    //the ValidScenario is used to check if the PostSales has published a form and the PreSales is trying to resubmit it or if the presales has resubmitted a form and the postsales is trying to publish it
    public boolean ValidScenario {get;set;}

    public boolean SaveNewFlag {get;set;}

    Public Map<String,String> TSPNameToEmail
    {
        get
        {
            if(TSPNameToEmail == null)
            {
                TSPNameToEmail = new Map<String,String>();   
            }
            return TSPNameToEmail;
        }
        set;
    }

    Public Map<String,Boolean> userPermissionMap
    {
        get
        {
            if(userPermissionMap==null)
            {
                userPermissionMap = RSSUtility.FormWriteAccess(UserInfo.getUserId());  
            } 
            return userPermissionMap;
        } 
        set; 
    }

    public Boolean WriteAccessOfUser
    {
        get 
        {    
            if(WriteAccessOfUser==null)
            {
                WriteAccessOfUser = userPermissionMap.get('WriteAccessOfUser');
            } 
            return WriteAccessOfUser;
        } 
        set;
    }

    public Boolean PreSales
    {
        get 
        {
            if(PreSales==null)
            {
                PreSales = userPermissionMap.get('Pre-sales');
            } 
            return PreSales;
        } 
        set;
    }

    public Boolean PostSales
    {
        get 
        {
            if(PostSales==null)
            {
                PostSales = userPermissionMap.get('Post-sales');
            } 
            return PostSales;
        } 
        set;
    }

    public Boolean SuperUser
    {
        get 
        {
            if(SuperUser==null)
            {
                SuperUser = userPermissionMap.get('SuperUser');
            } 
            return SuperUser;
        } 
        set;
    }

    //Set if Form has an Opportunity
    public Boolean OpportunitySet{get;set;} 

    //Set if Opportunity is Indirect
    public Boolean IndirectOpportunity{get;set;}

    //Page Reload : stores URL of page to reload 
    public String SavedURl {get;set;}
    
    //Set Saved message in Update function
    public Boolean FromPublish{get;set;}
    //end of changes by shprasan

    //Changes by Sharath: Creating ServicesForm variable 
    public Boolean ServicesForm{get;set;}

    // cookie
    // Changes by Sandeep for merging custom metadata
    //public List<eRSS_Hostname_Delimiters__mdt> eRSSMDT {get;set;}
    public List<PSA_Common_Setting__mdt> eRSSMDT {get;set;}

    //Changes by Sharath for Leap
    // Creating LeapForm variable
    public Boolean LeapForm {get;set;}
    public String onChangeError{get;set;}
    public String PageMessageSeverity{get;set;}
    public Boolean CallRetrieveContact 
    {
        get
        {
            if (CallRetrieveContact == null)
            {
                return true;
            }
           return CallRetrieveContact; 
        }
        set;
    }

    public String AFirstName 
    {
        get
        {
            return AFirstName;
        }
        set;
    }
    public String ALastName 
    {
        get
        {
            return ALastName;
        }
        set;
    }
    public String AEmail {get;set;}
    public String APhone 
    {
        get
        {
            return APhone;
        }
        set;
    }

    public String TFirstName 
    {
        get
        {
            return TFirstName;
        }
        set;
    }
    public String TLastName
    {
        get
        {
            return TLastName;
        }
        set;
    }
    public String TEmail {get;set;}
    public String TPhone
    {
        get
        {
            return TPhone;
        }
        set;
    }

    //End of changes by Sharath

    public Boolean errorFlag 
    {
        get
        {
            if(errorFlag==null)
            {
                errorFlag = false;
            } 
            return errorFlag;
        } 
        set;
    }

    public Attachment attachment 
    {
        get 
        {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }
  
    public list<Attachment> attachmentList 
    {
        get 
        {
            if (attachmentList == null)
                attachmentList = displayAttachments();
            return attachmentList;
        }
      set;
    }
    
    public void attachmentListUpdate()
    {
       RefreshAttachments=False;
       attachmentList =displayAttachments();
    }
    
    public Boolean KeepSaving 
    { 
        get
        {
            if(KeepSaving==null)
            {
                KeepSaving=true;
            }
            return KeepSaving;
        }
        set;
    }
    
    public Boolean OfflineOperationDone {get;set;}
    public List<RSS_Form__c> OfflineUpdateIds {get;set;}
    public List<RSS_Form__c> OfflineInsertIds {get;set;}
    public Boolean InvalidOpportunity{get;set;}
    public List<SurveyQuestionResponse__c> responses;
    public List<surveyTaker__c> surveyTakers;
    Map<Id,SurveyQuestionResponse__c> MapResponses;
    public List<RSSResponseGroupWrapper> responseGroupWrappers {get;set;}
    public List<RSSFormWrapper> RSSFormWrappers {get;set;}
    List<Survey_Question_Group__c> questionGroups;
    List<SurveyTaker__c> SurveyTakerForms;
    public string RSSFormId;
    public Boolean NewForm {get;set;}
    public Boolean UpdateForm {get;set;}

    public RSS_Form__c RSSForm 
    {
        get
        {
            if(RSSForm==null)
            {
                RSSForm = new RSS_Form__c();
            } 
            return RSSForm;
        }
        set;
    }  

    //public string OfflineFileName {get{return 'eRSSOffline.html';}}
    public string OfflineFileName {get{return RSSForm.Name;}}
    public Boolean InvalidTemplates {get;set;}
    public List<String> InvalidFormIds {get;set;}
    public List<String> InvalidTemplateIds {get;set;}
    public List<String> InvalidTemplateRecordIds {get;set;}

    public Boolean EnableOpportunity{get;set;}

    public List<selectOption> availableList{get;set;}

    public List<selectOption> chosenList 
    {
        get
        {
            if(chosenList == NULL)
            {
                chosenList = new List<selectOption>();
                // changes by Vandhana - commenting out default template names
                    //availableList.add(new selectOption('DSA','DSA'));
                    //availableList.add(new selectOption('Aqua Ion','Aqua Ion'));
                    //availableList.add(new selectOption('Product 1','Product 1'));
                    //availableList.add(new selectOption('Product 2','Product 2'));             
            }
            return chosenList;
        }
        set;
    } 

    public Opportunity FromOpportunity {get;set;}

    public Boolean flaggedSQR = false;

//     ----------------------------------- FUNCTIONS -------------------------------

    // Default Constructor
    public RSS_FormController() 
    {
    
    }

    // Constructor that calls main Custom Constructor function
    public RSS_FormController(ApexPages.StandardController controller)
    {
        CustomConstructor();
        //adminExists = true;
    }
    
    // Initialises RSS Form records, called on page load
    public void CustomConstructor()
    {
        String ParameterPassed;
        InvalidOpportunity = false;
        Disabled =false;
        showOwner = true;
        //start of changes by shprasan
        ValidScenario = true;
        string UpdateDone;
        OpportunitySet = false;
        IndirectOpportunity = false;
        FromPublish = false;
        SaveNewFlag = false;
        //Changes by Sharath: Setting the ServicesForm flag to false by default
        ServicesForm = false;
        //Changes bt Sharath: Setting the Leapform flag to false by default
        LeapForm = false;
        onChangeError = '';
        PageMessageSeverity = 'error';
        //CallRetrieveContact = true;

        //end of changes by shprasan

        if(Apexpages.currentPage()!= NULL)
        { 
            ParameterPassed = Apexpages.currentPage().getParameters().get('id');
            Id OppId = ApexPages.currentPage().getParameters().get('OppId');
            
            if(ParameterPassed != NULL)
            {
                if(OppId != NULL)
                {
                    FromOpportunity = [Select Id,Name from Opportunity where Id = :OppId limit 1];
                    RSSForm.Opportunity__c = FromOpportunity.Id;
                    //Changes by Sharath: call the pportunity function for non Services forms
                    if (! PostSales)
                    {
                        CallRetrieveContact = false;
                        ValidateOpportunity();    
                        CallRetrieveContact = true;
                    }                        
                }

                // New RSS Form, populate Available List of Templates
                if(ParameterPassed == 'new')
                {
                    NewForm=true;
                    UpdateForm = false;
                    availableList = new List<selectOption>();
                    showOwner = false;
                    //Changes by Sharath for Leap: setting the leap form variable to true
                    LeapForm = true;

                    for(Survey__c s:[select name,Id,Owner.Name,Version__c,UniqueName__c from Survey__c where id!=null and recordType.Name = 'RSS Template'and RSS_Published__c = true and (NOT Name like 'HIDE%') Order by Name Asc NULLS LAST limit 5000 ])
                    {
                        availableList.add(new selectOption(s.Id,s.Name));                 
                    }
                    
                    //Changes by Sharath: No error messsage is thrown if Post-Sales try to create Forms                    
                    //if(PostSales)
                    //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<h1 style="font-size:13px"> Post Sales cannot create forms </h1>')); 
                }

                // Existing RSS Form, query all related fields
                else
                {   
                    RSSFormId = ParameterPassed;
                    //changes by Vandhana : added Commitment_Type__c
                    //Changes by Sharath: Added Services_Form__c
                    RSSForm = [select id, Partner_Involved__c,Partner_Name__c,Partner__c, Type_of_Integration__c,Created_Date__c,Commitment_Type_Internal__c,Customer_Technical_Contact_Details__c,Submit_Version__c,Submit_Locked__c, Customer_Technical_Contact_Name__c, Name, AEName__c,Version__c, Opportunity__c, Published_Date__c,Submittal_Date__c, Published__c,Submitted__c, Products__c, Locked__c,UniqueName__c, DigitalProperty__c,Account__c,Account__r.id,Owner.Name,Commitment_Type__c,Customer_Business_Objective__c,Customer_agreed_Success_Criteria__c,Customer_Risk__c,TSP__c,Submitted_By__c,Submitted_By__r.Id,LastModifiedByID,LOE__c,Services_Form__c,Leap_Form__c,Admin_Contact__c,Admin_Contact_Details__c,Technical_Contact__c,Technical_Contact_Details__c
                        from RSS_Form__c where id=:RSSFormId limit 1];

                    if(RSSForm != null)
                    {
                        //List<PermissionSetAssignment> preSalesId = [SELECT AssigneeId FROM PermissionSetAssignment where PermissionSet.Label = 'eRSS - Solution Engineer' and AssigneeId = :RSSForm.LastModifiedById];

                        //Show the savenew button: The button which clones the form only if LastModifiedById = Submitted_By__r.Id. In the case of  super-user who can submit and publish forms, this condition is invalid. So check if the lastmodifiedby is not the current user

                // changes by Vandhana - CR 3393961 
                //(Post Sales now have Read Only view on Pre-Sales saved forms)

                        //if(PostSales && !RSSForm.Submitted__c)
                        //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' Post Sales cannot work on RSS Forms that are not Submitted. ')); 
                        //Changes by Sharath: Checking for Non Services form to show the save new button and setting the ServicesForm variable to RSSForm.Services_Form__c

                        ServicesForm = RSSForm.Services_Form__c;
                        //Changes by Sharath for Leap: initialising the Leapform variable
                        LeapForm = RSSForm.Leap_Form__c;
                        //CurrentFormAccount = RSSForm.Account__c;
                        if(!ServicesForm && RSSForm.LastModifiedById == RSSForm.Submitted_By__r.Id && RSSForm.LastModifiedById != UserInfo.getUserId())
                        {
                            SaveNewFlag = true;
                        }
                // end of changes by Vandhana

                        GenerateForm();
                        
                        //Changes by shprasan: Checking for the invalid scenario. A version of the form has already been published
                        //Changes by Sharath: Dont call the CheckForInvalidScenarios function for Services Forms
                        
                        if (!ServicesForm && CheckForInvalidScenarios())
                        {
                            Disabled = true;
                            InvalidTemplates = false;
                        }
                        if(ValidScenario)
                        {
                            InvalidTemplates = !isTemplatesValid();
                        }
                        //Changes by shprasan: If the TSP and Opportunity is not null query the TSP value and set the OpportunitySet flag
                        if(RSSForm.Opportunity__c != null)
                        {
                            QueryTSP();
                           // OpportunitySet = true;
                        }   
                        //Changes by Sharath for Leap:
                        if(LeapForm)
                        {
                            List<String> contactDetails;
                            if(RSSForm.Admin_Contact__c == null && RSSForm.Admin_Contact_Details__c != null && RSSForm.Admin_Contact_Details__c != '')
                            {
                                contactDetails = new List<String>();
                                contactDetails = RSSForm.Admin_Contact_Details__c.split('\n');
                                if(contactDetails.size() == 4)
                                {
                                    AEmail = contactDetails[0];
                                    AFirstName = contactDetails[1];
                                    ALastName = contactDetails[2];
                                    APhone = contactDetails[3];

                                }
                            }
                            if(RSSForm.Technical_Contact__c == null && RSSForm.Technical_Contact_Details__c != null && RSSForm.Technical_Contact_Details__c != '')
                            {
                                contactDetails = new List<String>();
                                contactDetails = RSSForm.Technical_Contact_Details__c.split('\n');
                                if(contactDetails.size() == 4)
                                {
                                    TEmail = contactDetails[0];
                                    TFirstName = contactDetails[1];
                                    TLastName = contactDetails[2];
                                    TPhone = contactDetails[3];

                                }

                            }
                            List <Id> contactIDs = new List <Id>();
                            if(RSSForm.Technical_Contact__c != null)
                            {
                                contactIDs.add(RSSForm.Technical_Contact__c);
                            }
                            if(RSSForm.Admin_Contact__c != null)
                            {
                                contactIDs.add(RSSForm.Admin_Contact__c);   
                            }
                            if(contactIDs.size() > 0)
                            { 
                                List <Contact> ExistingContacts = [select id,FirstName,LastName,Phone,Email from Contact where id in :contactIDs and accountid = :RSSForm.Account__r.id limit 2];
                                for (Contact c :ExistingContacts)
                                {
                                    if(RSSForm.Admin_Contact__c == RSSForm.Technical_Contact__c && RSSForm.Admin_Contact__c != NULL)
                                    {
                                        AEmail = c.Email;
                                        AFirstName = c.FirstName;
                                        ALastName = c.LastName;
                                        APhone = c.Phone;  
                                        TEmail = c.Email;
                                        TFirstName = c.FirstName;
                                        TLastName = c.LastName;
                                        TPhone = c.Phone; 
                                    }
                                    else if(c.id == RSSForm.Admin_Contact__c)
                                    {
                                        AEmail = c.Email;
                                        AFirstName = c.FirstName;
                                        ALastName = c.LastName;
                                        APhone = c.Phone;
                                    }
                                    else
                                    {
                                        TEmail = c.Email;
                                        TFirstName = c.FirstName;
                                        TLastName = c.LastName;
                                        TPhone = c.Phone;
                                    }
                                }
                            }
                        }
                        //End of changes for leap
                    }
                    //Changes by Sharath : If the update parameter is set, then add a page message
                    UpdateDone =  Apexpages.currentPage().getParameters().get('update');

                    // changes by Vandhana - CR 3393961
                    //Changes by Sharath: check if the form is not a services form for Post Sales
                    if (UpdateDone == 'true' && !Apexpages.hasMessages() && !(!ServicesForm && PostSales && !RSSForm.Submitted__c))
                    {
                        PageMessageSeverity = 'INFO';
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Saved')); 
                        onChangeError = 'Saved';

                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, ' Saved ')); 
                    }             
                    //end of changes by Sharath & Vandhana
                }
            }
        }
    }
    
    
    //Changes by shprasan: Disable Published forms, disable Submitted forms only for Pre-Sales
    public void CheckDisabled()
    {
        System.debug('CheckDisabled Start');
        if(RSSForm!=null)
        {
            System.debug('CheckDisabled entered if');
            
            //Start of changes by shprasan
            //if((RSSForm.Published__c == true)  || ((PreSales) && RSSForm.Submitted__c == true))
            //{
            //    Disabled = true;
            //}
            //Disable the form if it is published locked for all users or if it is Submit locked and not the latest submit version or if the user is presales and the form is submitted
            //Changes by Sharath: Dont disable the form if it is a services form and the user is Post Sales
            //Changes by Sharath: Disable the ServicesForm for Non Postsales user
            if(RSSForm.Locked__c || (RSSForm.Submit_Locked__c && !RSSForm.Submitted__c) || (PreSales && RSSForm.Submitted__c) || (!ServicesForm && PostSales && !RSSForm.Submitted__c) || (!PostSales && ServicesForm))
            {
                Disabled = true;
            }  
            else
            {
                Disabled = false;
            }
            if(!WriteAccessOfUser)
            { 
                Disabled = true; 
                DisabledAttachment = true; 
            }
            System.debug('CheckDisabled exited');
        }
    }

    // Populates Available List, Chosen List, Question Groups and Responses for Form
    public void GenerateForm()
    {
        NewForm=false;
        UpdateForm = true;
        RSSFormWrappers = new List<RSSFormWrapper>();
        availableList = new List<selectOption>();
        Map<String,String> TemplateFormMap = new Map<String,String>();
        List<SurveyTaker__c> forms = [select id,Survey__r.Name,Survey__r.UniqueName__c,OrderNumber__c,Survey__c from SurveyTaker__c where RSS_Form__c = :RSSFormId  order by OrderNumber__c];
        Map<String,String> chosenListFormNames = new Map<String,String>();
        SurveyTakerForms = forms;
        CheckDisabled();
        chosenList = new List<SelectOption>();
        surveyTakers = new List<SurveyTaker__c>();
        for(SurveyTaker__c st: forms)
        {
            TemplateFormMap.put(st.Survey__c,st.id);
            surveyTakers.add(st);
            chosenList.add(new SelectOption(st.Survey__c,st.Survey__r.Name));
            //chosenListFormNames.put(st.Survey__r.Name,st.Survey__r.Name);

            // Cookie change
            chosenListFormNames.put(st.Survey__r.UniqueName__c,st.Survey__r.Name);
        }
        //changes by shprasan: querying those templates that are not soft-deleted and that dont begin with the name HIDE
        for(Survey__c s:[select name,Id,Owner.Name,Version__c,UniqueName__c from Survey__c where Id!=NULL and RecordType.Name = 'RSS Template' and Soft_Delete__c=false and RSS_Published__c = true and (NOT Name like 'HIDE%') Order by Name Asc NULLS LAST limit 5000 ])
        {
            if(chosenListFormNames.get(s.UniqueName__c) == NULL)
            availableList.add(new selectOption(s.Id,s.Name));                 
        }
        questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :TemplateFormMap.keyset() order by Order_Number__c];
        //Map<id,List<Survey_Question_Group__c>> FormQuestionGroupMap = new Map<id,List<Survey_Question_Group__c>>();
        Map<id,List<RSSResponseGroupWrapper>> FormGroupMap = new Map<id,List<RSSResponseGroupWrapper>>();
        if(questionGroups != NULL || questionGroups.size() != 0)
        {
            List<String> Formids = new List<String>();
            for(SurveyTaker__c st:forms)
            {
                Formids.add(st.id);
            }

            // cookie
            List<SurveyQuestionResponse__c > tempResponses = [select Id,Question__c, Response__c, SurveyTaker__c, SurveyTaker__r.Survey__r.Name, Survey_Question__c, Survey_Question__r.Question__c, Survey_Question__r.Required__c, Survey_Question__r.OrderNumber__c,Survey_Question__r.Type__c, Survey_Question__r.Choices__c,Survey_Question__r.QuestionDescription__c,Survey_Question__r.Survey_Question_Group__c,Survey_Question__r.UniqueName__c,Survey_Question__r.Category__c  from SurveyQuestionResponse__c where SurveyTaker__c in :Formids and Survey_Question__r.Survey_Question_Group__c in :questionGroups ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c];
            
            //QuestionGroup,Responses
            Map<Id,List<RSSQuestionResponse>> tempMap = new Map<Id,List<RSSQuestionResponse>>();
            
            //In the View Page, we would need to display only the questions which were responded to. Creating a new Map for RSSFormView Page
            //Map<Id,List<RSSQuestionResponse>> pdftempMap {get;set;}
            responses = tempResponses;
            MapResponses = new Map<Id,SurveyQuestionResponse__c>();
                
            // populates question responses
            for(SurveyQuestionResponse__c q:tempResponses)
            {
                pdftempMap =new Map<String,List<RSSQuestionResponse>>();
                MapResponses.put(q.id,q);
                if(tempMap.get(q.Survey_Question__r.Survey_Question_Group__c)==null)
                {
                    tempMap.put(q.Survey_Question__r.Survey_Question_Group__c,new List<RSSQuestionResponse>());
                    //pdftempMap.put(q.Survey_Question__r.Id,new List<RSSQuestionResponse>());
                }
                tempMap.get(q.Survey_Question__r.Survey_Question_Group__c).add(new RSSQuestionResponse(q));
                pdftempMap.put(q.Survey_Question__r.Id,new List<RSSQuestionResponse>());
                pdftempMap.get(q.Survey_Question__r.Id).add(new RSSQuestionResponse(q));
            }

            // populates question groups
            for(Survey_Question_Group__c sqg:QuestionGroups)
            {
                
                RSSResponseGroupWrapper toBeAdded = new RSSResponseGroupWrapper(sqg);
                tobeAdded.surveyResponses = tempMap.get(sqg.Id);
                
                if(FormGroupMap.get(TemplateFormMap.get(sqg.survey__c)) ==null)
                {
                    FormGroupMap.put(TemplateFormMap.get(sqg.survey__c),new List<RSSResponseGroupWrapper>());
                }
                FormGroupMap.get(TemplateFormMap.get(sqg.survey__c)).add(toBeAdded);
            }

            for(SurveyTaker__c st:forms)
            {
                RSSFormWrapper toBeAdded = new RSSFormWrapper(st);
                toBeAdded.responseGroupWrappers = FormGroupMap.get(st.id);
                RSSFormWrappers.add(toBeAdded);
            }
        }

        //Changes by shprasan: including the submit version as well
        Apexpages.currentPage().getHeaders().put('content-disposition', 'filename=eRSS '+RSSForm.Name + ' - V.' + RSSForm.Submit_Version__c +RSSForm.Version__c + '.pdf');
    }

    // Save Function for New Form
    public PageReference SaveForm() 
    {   
        onChangeError = '';
        List<Survey_Question_Group__c> questionGroups;
        //System.assertEquals(AFirstName,null);
        //The error flag set to false by default
        errorFlag = false; 
        if (RSSForm.Name == NULL || RSSForm.Name == '')
        {
            Double loe = double.valueOf(RSSForm.Loe__c);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill in the Form Name'));
            errorFlag = true;
            //return NUll;            
        }
        
        // ensures atleast 1 Template is selected
        if(chosenList.size() <1)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one Product from the available list.'));
            errorFlag = true;
            //return NUll;
        }
        //Changes by Sharath: Opportunity is mandatory for form creation for PostSales
        if (PostSales && RSSForm.Opportunity__c == null)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select an Opportunity'));
            errorFlag = true;            
        }
        //system.assertEquals(AFirstName,null);
       // check if Opportunity selected already has any associated Form
        //Changes by Sharath for Leap
        CallRetrieveContact = false;
        ValidateOpportunity();    
        CallRetrieveContact = true;


        //ValidateOpportunity();
        
        if (InvalidOpportunity)
        { errorFlag = true; }

        //Changes by Sharath for Leap: 
        if(LeapForm)
        {
            if(!validateSaveContact())
            {
                errorFlag = true;
            }
        }
        //End of changes by Sharath

        if(errorFlag == true)
        { return NULL; }

        // Create record for New Form, populate primary set of fields
        if(RSSForm.id== NULL)
        {
            List<String> TempList = new List<String>();
            for(SelectOption so:chosenList)
            {
                TempList.add(so.getValue());
            }

            RSSForm.UniqueName__c = GuidUtil.NewGuid();
            RSSForm.Created_Date__c = Date.today();

            //Changes by Sharath for Leap: setting the leap form checkbox for newly created forms
            RSSForm.Leap_Form__c = true;
            try
            {
                insert RSSForm;
            }
            catch(Exception e)
            {
                    ApexPages.addMessages(e);   
                    return Null;                 
            }            
            // creates Survey Taker records for Form
            RSSUtility.CreateRSSFromTemplate(TempList,RSSForm.Id);

            RSSFormId = RSSForm.Id;
            PageReference pg = new PageReference('/apex/RSSForm?id='+RSSForm.id+'&update=true');
            //SavedURl = pg.getUrl();
            pg.setRedirect(true);
            return pg;
        }
        return NULL;
    }
      
    //changes by Sharath for Leap: adding a new function to validateContacts:        

    public Boolean validateSaveContact()
    {
        
        Boolean AdminValid = true;
        Boolean TechValid = true;        
        //Boolean error = false;
        if((AEmail == null || AEmail =='') && (TEmail == null || TEmail ==''))
        {
            AEmail = null;
            AFirstName = null;
            ALastName = null;
            APhone = null;
            RSSForm.Admin_Contact__c = null;
            RSSForm.Admin_Contact_Details__c = null;
            TEmail = null;
            TFirstName = null;
            TLastName = null;
            TPhone = null;
            RSSForm.Technical_Contact__c = null;
            RSSForm.Technical_Contact_Details__c = null;
            return true;
        }
        if(AEmail == null || AEmail =='')
        {
            AEmail = null;
            AFirstName = null;
            ALastName = null;
            APhone = null;
            RSSForm.Admin_Contact__c = null;
            RSSForm.Admin_Contact_Details__c = null;
            AdminValid = false;
        }
        if(TEmail == null || TEmail =='')
        {
            TEmail = null;
            TFirstName = null;
            TLastName = null;
            TPhone = null;
            RSSForm.Technical_Contact__c = null;
            RSSForm.Technical_Contact_Details__c = null;
            TechValid = false;         
        }
        if(RSSForm.Opportunity__c == null && ((AEmail != null && AEmail != '') || (TEmail != null && TEmail != '')))
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select the opportunity before entering the Admin or Technical contact email'));  
             return false;           
        }
        //if(AEmail == null || AEmail =='' )
        //{
        //    AdminValid = false;
        //}
        //if(TEmail == null || TEmail =='')
        //{
        //    TechValid = false;         
        //}
        if((AEmail != null && AEmail != '' && !EmailValidation(AEmail)) ) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a valid Customer Administrator Contact Email Id'));  
             //return false;  
             AdminValid = false;         
        }
        
        if((TEmail != null && TEmail != '' && !EmailValidation(TEmail))) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a valid Customer Technical Contact Email Id'));  
             //return false;  
             TechValid = false;         
        }

        List<String> emails = new List<String>();
        List<contact> techContactID = new List<contact>();
        List<contact> adminContactID = new List<contact>();
        List<contact> accountid = new List<contact>();
        Id CurrentFormAccount;        
        if(RSSForm.Opportunity__c != null)
        {
            Opportunity opp  = [select accountid from Opportunity where id = :RSSForm.Opportunity__c limit 1];
            CurrentFormAccount = opp.accountid;
        }
        else
        {
            return false;
        }
        Boolean error = false;
        if(AEmail != null && AEmail != ''  && AdminValid)
        {
            //emails.add(AEmail);
            adminContactID = [select id,firstname,lastname,accountid,Account.Name,email,phone from contact where email = :AEmail order by createddate desc limit 1];
            if(adminContactID != null && adminContactID.size() == 1)
            {
                accountid.add(adminContactID.get(0));
            }
        }
        if(TEmail != null && TEmail != '' && TechValid )
        {
            //emails.add(TEmail);
            techContactID = [select id,firstname,lastname,accountid,Account.Name,email,phone from contact where email = :TEmail order by createddate desc limit 1];
            if(techContactID != null && techContactID.size() == 1)
            {
                accountid.add(techContactID.get(0));
            }

        }
        //Map<String,String> emailToID = new Map<String,String>();  

        //accountid = [select id,firstname,lastname,accountid,Account.Name,email,phone from contact where email in :emails order by createddate desc limit 20];
        //if(accountid != null)
        //{   
        //    for (Contact c1: accountid)
        //    {
        //        if(!emailToID.containsKey(c1.email))
        //        {
        //            emailToID.put(c1.email,c1.id);                    
        //        }
        //        //else
        //        //{
        //        //    emailToID.remove(c1.email);
        //        //    emailToID.put(c1.email,null);                       
        //        //}
        //    }
        //}
        for(Contact c1: accountid)
        {
            //if(AdminValid && c1.email == AEmail  && emailToID.get(c1.email) == null)
            //{
            //        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'More than one contact exists with the same Customer Administrator Contact Email Id'));
            //        AdminValid = false;

            //}
            if(AdminValid && c1.email == AEmail && c1.accountid != CurrentFormAccount )
            {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">Contact ' + c1.firstname + ' ' + c1.lastname +' exists against the Account - ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + c1.Accountid + '">'+ c1.Account.name +'</a>' +  ' Please select a different Contact associated with the Account on the eRSS, or correct the contact data issue, in order to proceed.</h1>'));
                    AdminValid = false;
            }
            else if(AdminValid && c1.email == AEmail && c1.accountid == CurrentFormAccount)
            {
                    AFirstName = c1.FirstName;
                    ALastName = c1.LastName;
                    APhone = c1.Phone;
                    RSSForm.Admin_Contact__c = c1.id; 
                    RSSForm.Admin_Contact_Details__c = null;
            }

            //if(TechValid && c1.email == TEmail  && emailToID.get(c1.email) == null)
            //{
            //        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'More than one contact exists with the same Customer Technical Contact Email Id'));
            //        TechValid = false;

            //}
            if(TechValid && c1.email == TEmail && c1.accountid != CurrentFormAccount)
            {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">Contact ' + c1.firstname + ' ' + c1.lastname +' exists against the Account - ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + c1.Accountid + '">'+ c1.Account.name +'</a>' +  ' Please select a different Contact associated with the Account on the eRSS, or correct the contact data issue, in order to proceed.</h1>'));
                    TechValid = false;
            }
            else if(TechValid && c1.email == TEmail && c1.accountid == CurrentFormAccount)
            {
                    TFirstName = c1.FirstName;
                    TLastName = c1.LastName;
                    TPhone = c1.Phone;
                    RSSForm.Technical_Contact__c = c1.id; 
                    RSSForm.Technical_Contact_Details__c = null;
            }

        }
        //if(error)
        //{
        //    return false;
        //}
        
        //Boolean AdminValid = false;
        //Boolean TechValid = false;
        if(AdminValid && AEmail != null && AEmail != '' &&  RSSForm.Admin_Contact__c == null  ) 
        {
                //system.assertEquals(AEmail,null);        

            if(AFirstName == null || ALastName == null || APhone == null || AFirstName == '' || ALastName == '' || APhone == '')
            {

                //system.assertEquals(AFirstName,null);
                //system.assertEquals(ALastName,null);
                //System.assertEquals(APhone,null);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please fill in the Customer Administrator Contact details'));  
                AdminValid = false;

            }
            else
            {
                if(PhoneValidation(APhone))
                {
                    AdminValid = true;
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a valid Customer Administrator Contact Phone Number'));  
                    AdminValid = false;
                }

            }
        }

        if(TechValid && TEmail != null && TEmail != '' && RSSForm.Technical_Contact__c == null)
        {
            if(TFirstName == null || TLastName == null || TPhone == null || TFirstName == '' || TLastName == '' || TPhone == '')
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please fill in the Customer Technical Contact details'));  
                TechValid =  false;

            }
            else
            {
                if(PhoneValidation(TPhone))
                {
                    TechValid = true;
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a valid Customer Technical Contact Phone Number'));  
                    TechValid =  false;
                }

            }            
        }

        if(AdminValid && RSSForm.Admin_Contact__c == null)
        {
            RSSForm.Admin_Contact_Details__c =  AEmail.trim() + '\n' + AFirstName.trim() + '\n' + ALastName.trim() + '\n' + APhone.trim(); 

        }
        if(TechValid && RSSForm.Technical_Contact__c == null)
        {
            RSSForm.Technical_Contact_Details__c =  TEmail.trim() + '\n' + TFirstName.trim() + '\n' + TLastName.trim() + '\n' + TPhone.trim();                  

        }
        //system.assertEquals(RSSForm.Admin_Contact_Details__c,null);        
        if((AdminValid && TechValid) || (AdminValid && (TEmail == null || TEmail == '')) || (TechValid && (AEmail == null || AEmail == '')) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    // Saves updates made to existing Form    
    public void UpdateForm()
    {
        //Start of changes by shprasan: Checking for invalid scenarios for both PreSales and PostSales
        //system.assertEquals(AFirstName,null);        
                //system.debug('uf: entry AFirstName = ' + AFirstName);
         onChangeError = ''; 

        // cookie
        flaggedSQR = false;
        String invalidHostnames = '';

        //Changes by Sharath: Opportunity is mandatory for updating services forms
        if (PostSales && RSSForm.Opportunity__c == null)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select an Opportunity'));
           return;            
        }

        //Changes by Sharath: check if the form is a non services form
        if (!ServicesForm && CheckForInvalidScenarios())
        {
            //Disabled = true;
            return;                    
        } 
        //Changes by Sharath: Call the validate function for non-sevices form
        //system.debug('before vo:uf AFirstName = ' + AFirstName);
        
        if (!ServicesForm)
        {
            CallRetrieveContact = false;
            ValidateOpportunity();    
            CallRetrieveContact = true;
        }                       
        if (InvalidOpportunity)
        { return; }
        //system.debug('after vo: uf AFirstName = ' + AFirstName);


        //system.debug('after vsc: uf  AFirstName = ' + AFirstName);

        List<SurveyTaker__c> DeletedList = new List<SurveyTaker__c>();
        List<String> NewTemplatesList = new List<String>();
        Boolean NotThere = true;

            Set<SelectOption> ChosenSet = new Set<SelectOption>(ChosenList);
            ChosenList = new List<SelectOption>(ChosenSet);

        // List of Templates unselected
        for(SurveyTaker__c st:SurveyTakerForms)
        {
            NotThere=true;
            for(SelectOption so:ChosenList)
            {   
                if(st.Survey__c == so.getValue())
                {
                    NotThere = false;
                }
            }
            // if Survey not present in Survey Taker record, it is unselected, add to delete list
            if(NotThere)
            {                
                DeletedList.add(st);
            }
        }

        // Updated List of Templates
        for(SelectOption so:ChosenList)
        {
            NotThere=true;
            for(SurveyTaker__c st:SurveyTakerForms)
            {
                if(so.getValue() == st.Survey__c)
                {
                    NotThere = false;
                }
            }

            // populate updated list of Templates
            if(NotThere)
            {
                NewTemplatesList.add(so.getValue());
            }
        }

        try
        {   
            //Start of changes by shprasan:
            //The ChosenList doesn't always have the right list of selected templates (products). So every update has to be within a try/catch block
            //Creating a map of id to survey takers using the Deleted List and updating only those responses whose corresponding survey taker record is not be deleted
            Boolean error = false;
            try
            {
                //Changes by Sharath for Leap: 
                if(LeapForm)
                {
                    if(!validateSaveContact())
                    {
                        error = true;
                    }

                }
                //End of changes by Sharath

            }           
            catch(Exception e)
            {
                
            }

            List<SurveyQuestionResponse__c> responsesToUpdate = new List<SurveyQuestionResponse__c>();
            Map <Id,SurveyTaker__c> idToSurveyTaker = new Map <Id,SurveyTaker__c>(DeletedList);

            //Changes by Sharath on 20th June 2018: Removed the query from the or loop for FFPSA-607
            String delimiterList = '[';
            
            //Changes by Sandeep for merging custom metadata
            //eRSSMDT= [Select Delimiter__c from eRSS_Hostname_Delimiters__mdt limit 1];
            eRSSMDT= [Select Value__c from PSA_Common_Setting__mdt Where type__c='eRSS_Hostname_Delimiters__mdt' limit 1];
            
            //List<String> delimiters = eRSSMDT[0].Delimiter__c.split('#');
            List<String> delimiters = eRSSMDT[0].Value__c.split('#');
            
            for(String s : delimiters)
            {
                delimiterList += s; 
            }
            delimiterList += ']+';
            String validHostnameRegex = '^(([a-zA-Z0-9\\.a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$';
            //End of changes for FFPSA-607

            for (SurveyQuestionResponse__c sqr : responses)
            {
                //cookie
                if(!idToSurveyTaker.containsKey(sqr.SurveyTaker__c))
                {
                    if(sqr.Survey_Question__r.Category__c == 'List of secure hostname' || sqr.Survey_Question__r.Category__c == 'List of non-secure hostname')
                    {
                        //String delimiterList = '[,;\\n]+';
                        //String delimiterList = '[';
                        // //NOTE: Do not use eRSS_Hostname_Delimiters__mdt as it has been merged, rather use PSA_Common_Setting__mdt metadata and use Value__c instead of Delimter__c
                        //eRSSMDT= [Select Delimiter__c from eRSS_Hostname_Delimiters__mdt limit 1];
                        //List<String> delimiters = eRSSMDT[0].Delimiter__c.split('#');
                        //for(String s : delimiters)
                        //{
                        //    delimiterList += s; 
                        //}
                        //delimiterList += ']+';
                        //String validHostnameRegex = '^(([a-zA-Z0-9\\.a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$';
                        
                        Pattern hostNamePattern = Pattern.compile(validHostnameRegex);

                        System.debug('LEAPLEAP : ' + sqr.Response__c);
                        if(sqr.Response__c != NULL && sqr.Response__c != '')
                        {
                            List<String> hostnamesList = sqr.Response__c.split(delimiterList);
                        
                            for(String s : hostnamesList)
                            {
                                //s = s.replaceAll('\\s','');
                                if(s != NULL && s != '' && s.trim() != '')
                                {
                                    s = s.trim();
                                    Matcher hostNameMatcher = hostNamePattern.matcher(s);
                                    if(!hostNameMatcher.matches())
                                    {
                                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Hostname format incorrect : ' + s + ' in Product ' + sqr.SurveyTaker__r.Survey__r.Name + ' , '));
                                        invalidHostnames = invalidHostnames + s + ' in Product ' +  sqr.SurveyTaker__r.Survey__r.Name + ', ';
                                        flaggedSQR = true;
                                    }
                                }
                            }
                        }
                    }
                    responsesToUpdate.add(sqr);
                }
            }

            if(flaggedSQR && invalidHostnames != '')
            {
                invalidHostnames = invalidHostnames.substring(0, invalidHostnames.length() - 2);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<b>Hostname format incorrect: ' + invalidHostnames + '<br />Expected format for the hostname: <br />• Does not contain \'http://\' OR \'https://\' OR \'/\'<br />• Only contains valid characters: \'A-Z\', \'a-z\', \'0-9\', \'.\', \'-\' <br />• Hyphen \'-\' may not appear first or last<br />• Contains at least one dot \'.\'<br />Also, Hostnames should be separated by any of the following: comma \',\' OR semi-colon \';\' OR line-break(new line) \'\\n\'</b>'));
            }
            try
            {
                update responsesToUpdate;
            }
            catch(Exception e)
            {
                Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,e.getMessage()));
                
            }

            //Updating all the survey takers that should not be deleted
            Set<SurveyTaker__c> surveyTakersSet = new Set<SurveyTaker__c>(surveyTakers);
            surveyTakersSet.removeAll(DeletedList);
            List<SurveyTaker__c> surveytakersToUpdate = new List<SurveyTaker__c>(surveyTakersSet);
            try
            {
                update surveytakersToUpdate;
            }
            catch(Exception e)
            {
                Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,e.getMessage()));  
            }

                        
            //Query for the survey takers to be deleted. If they are not deleted, then delete them
            try
            {
                List <SurveyTaker__c> surveytakersToDelete = new List <SurveyTaker__c>();
                surveytakersToDelete = [Select Id from SurveyTaker__c where ID in :idToSurveyTaker.keySet()];
                if (surveytakersToDelete.size() > 0)
                {
                    delete surveytakersToDelete;    
                }                
            }
            catch(Exception e)
            {
                Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,e.getMessage()));
                
            }
            Set<String> NTL = new set<String>(NewTemplatesList);   
            Map<id,id> sToST = new  Map<id,id>();
            List<SurveyTaker__c> existingOnes = new List<SurveyTaker__c>([select id, Survey__c from SurveyTaker__c where RSS_Form__c = :RSSForm.id]);
            for (SurveyTaker__c st: existingOnes)
            {
                sToST.put(st.Survey__c, st.id);
            } 
            for (string template: NewTemplatesList)
            {
                  if(sToST.containsKey(template))
                  {
                    NTL.remove(template);
                  }
            }

            NewTemplatesList = new List<string>(NTL);
            //system.assertEquals(NewTemplatesList,null);
          

            RSSUtility.CreateRSSFromTemplate(NewTemplatesList,RSSForm.id); 

            if(error)
            {
                return;
            }
            if (!FromPublish)
            { update RSSForm; }            

            InvalidTemplates = !isTemplatesValid();   
            //To avoid duplicate values in the Chosen List, create a set using it and then create a list from the set

            GenerateForm();
            
            //if(InvalidTemplates)
            //{ return; }
            
            //ApexPages.getMessages().clear();
            
            if (!FromPublish && !flaggedSQR)
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The chosen LIST: ' + chosenList + 'The added templates: ' +  NewTemplatesList)); 
                PageMessageSeverity = 'INFO';
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Saved')); 
                onChangeError = 'Saved';
            }    
        }
        catch(Exception e)
        {
            ApexPages.addMessages(e);
            
        }
        return;
    }

    public void StopSaving()
    {
        KeepSaving = false;
    }
    public void StartSaving()
    {
        KeepSaving = true;
    }

    
    //Start of changes by Vandhana 
    //Function to ensure Opportunity selected does not have any valid form associated to it
    public void ValidateOpportunity()
    {
        //system.debug('vo: entry AFirstName = ' + AFirstName);
        onChangeError = '';  
        PageMessageSeverity = 'error';      
        String OpportunityName;
        RSSForm.Account__c = NULL;
        RSSForm.AEName__c = NULL;
        RSSForm.Partner_Involved__c = false;
        RSSForm.Partner_Name__c = NULL;
        InvalidOpportunity = false;

        if(RSSForm.Opportunity__c == NULL)
        {
            OpportunitySet=false;
            IndirectOpportunity=false;
            //Changes by Sharath for Leap 
            if(LeapForm && AEmail != null && AEmail != '')
            {   
                if(RSSForm.Admin_Contact__c != null)
                {
                    AEmail = null;
                    AFirstName = null;
                    ALastName = null;
                    APhone  = null;
                    RSSForm.Admin_Contact_Details__c = null;
                    RSSForm.Admin_Contact__c = null;

                }
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select the opportunity before entering the Admin contact email'));   
                onChangeError = 'Please select an Opportunity before entering the Customer Administrator Contact Email Id';                
                //ApexPages.currentPage().getParameters().put('ContactType','admin');
                //RetrieveContact();
            }
            if (LeapForm && TEmail != null && TEmail != '')
            {
                if(RSSForm.Technical_Contact__c != null)
                {
                    TFirstName = null;
                    TLastName = null;
                    TPhone  = null;
                    RSSForm.Technical_Contact__c = null;
                    RSSForm.Technical_Contact_Details__c = null;

                }
                //TEmail = null;
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select the opportunity before entering the Technical contact email'));  
                 if(onChangeError != '')
                 {
                    onChangeError = 'Please select an Opportunity before entering the Customer Administrator Contact Email Id and Customer Technical Contact Email Id';                 
                 }
                 else
                 {
                    onChangeError = 'Please select an Opportunity before entering the Customer Technical Contact Email Id';                 
                 }                     
                //ApexPages.currentPage().getParameters().put('ContactType','tech');
                //RetrieveContact();
            }
            //End of changes for Leap

            return;
        }
        //Changes by Sharath: Check if its a Services Form, if so, Check if the opportunity has an active SMP or TAS Contract Detail only on form creation
        if ((PostSales && NewForm) || ServicesForm)
        {
            Opportunity ServicesOpp = [select Id, Account.Id,Contract_ID__c from Opportunity where Id = :RSSForm.Opportunity__c limit 1];

            //Map <Id,Merge_Contract_Header__c> contractHeadersMap= new Map <Id,Merge_Contract_Header__c>([select Id from Merge_Contract_Header__c where Locked__c = true and Cancellation_Date__c = Null and Contract_Transferred_To__c = Null and Effective_End_Date__c >= Today and Effective_Start_Date__c <> null and Effective_End_Date__c <> null and Account_Name__c =: ServicesOpp.Account.id]);
            List<String> OriginalContractIDs = new List<String>();

            if (ServicesOpp.Contract_ID__c == '' || ServicesOpp.Contract_ID__c == null)
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">No Services Product associated to the Opportunity. Please associate an appropriate Contract to the Opportunity and try again</h1>'));
                InvalidOpportunity = true;
                onChangeError = '<h1 style="font-size:13px">No Services Product associated to the Opportunity. Please associate an appropriate Contract to the Opportunity and try again</h1>';
                return;                
            }
            OriginalContractIDs = ServicesOpp.Contract_ID__c.split(',');

            Map <Id,Merge_Contract_Header__c> contractHeadersMap= new Map <Id,Merge_Contract_Header__c>([select Id from Merge_Contract_Header__c where Locked__c = true and Cancellation_Date__c = Null and Contract_Transferred_To__c = Null and Effective_End_Date__c >= Today and Effective_Start_Date__c <> null and Effective_End_Date__c <> null and Contract_Id__c in :OriginalContractIDs]);

            if(contractHeadersMap == null || contractHeadersMap.size() == 0 )
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">No Services Product associated to the Opportunity. Please associate an appropriate Contract to the Opportunity and try again</h1>'));
                InvalidOpportunity = true;
                onChangeError = '<h1 style="font-size:13px">No Services Product associated to the Opportunity. Please associate an appropriate Contract to the Opportunity and try again</h1>';
                return;
            }
            //check for the following products: Service Management and Technical Advisory
            for (Merge_Contract_Detail__c detail: [Select Product__c from Merge_Contract_Detail__c where Effective_End_Date__c >= Today and Effective_Start_Date__c <> null and Effective_End_Date__c <> null and Original_Contract_Id__c in:contractHeadersMap.keyset()])
            {
                if(detail.Product__c.contains('SMP') || detail.Product__c.contains('TAS') || detail.Product__c.contains('Service Management') || detail.Product__c.contains('Technical Advisory'))
                {
                      RSSForm.Services_Form__c = true;
                      ServicesForm = true;
                      QueryTSP();
                      return;
                }
            }
            InvalidOpportunity = true;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">No permission to create an eRSS as there are no ACTIVE Services Product against the Contract that is associated to the Opportunity </h1> '));
            onChangeError = '<h1 style="font-size:13px">No permission to create an eRSS as there are no ACTIVE Services Product against the Contract that is associated to the Opportunity </h1> ';
            return;
        }
        else
        {
            //changes for Opportunity Validation, query for all form(s) already associated to select Opportunity
            //Changes by Sharath: Services forms should not b considered for Opportunity validation
            List<RSS_Form__c> formList = [Select Id,Name,Opportunity__r.Name,Submitted__c,Locked__c,LastModifiedBy.Id,Submitted_By__c,Published__c from RSS_Form__c where Opportunity__c = :RSSForm.Opportunity__c AND UniqueName__c != :RSSForm.UniqueName__c and Services_Form__c = false];
            for(RSS_Form__c validForm: formList)
            {
                if ((validForm.Submitted__c && !validForm.Locked__c && validForm.LastModifiedBy.Id == validForm.Submitted_By__c) || validForm.Published__c)
                {
                    InvalidOpportunity = true;
                    OpportunityName = validForm.Opportunity__r.Name;
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">The Opportunity : ' +  '<a target="_blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + RSSForm.Opportunity__c + '">'+ OpportunityName +'</a> already has the RSS Form : ' +  '<a target="_blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + validForm.Id + '">'+ validForm.Name +'</a> associated to it. Please select a different Opportunity.</h1>'));
                    onChangeError = '<h1 style="font-size:13px">The Opportunity : ' +  '<a target="_blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + RSSForm.Opportunity__c + '">'+ OpportunityName +'</a> already has the RSS Form : ' +  '<a target="_blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + validForm.Id + '">'+ validForm.Name +'</a> associated to it. Please select a different Opportunity.</h1>';
                    return;
                }
            }        
        }
        QueryTSP(); 
        //Changes by Sharath for Leap 
        if(CallRetrieveContact && LeapForm)
        {
            if (AEmail != null && AEmail != '' && (RSSForm.Admin_Contact__c != null || ((RSSForm.Admin_Contact_Details__c == null || RSSForm.Admin_Contact_Details__c == '') &&  RSSForm.Admin_Contact__c == null)))
            {
                ApexPages.currentPage().getParameters().put('ContactType','admin');
                RetrieveContact();
            }
            if (TEmail != null && TEmail != '' && (RSSForm.Technical_Contact__c != null || ((RSSForm.Technical_Contact_Details__c == null || RSSForm.Technical_Contact_Details__c == '') &&  RSSForm.Technical_Contact__c == null)))
            {
                ApexPages.currentPage().getParameters().put('ContactType','tech');
                RetrieveContact();
            }            
        }
        //system.assertEquals(AFirstName,null);
        //End of changes for Leap
        //system.debug('exit of vo: AFirstName = ' + AFirstName);

    }
    
    //Changes by Sharath for Leap: Adding the PhoneValidation,EmailValidation and RetrieveContact functions

    public Boolean PhoneValidation(String Phone)
    {
        String phoneRegex1 = '[+.()-]*?(\\d[+.()-]*?){10,}';
        //The pattern is atleast 10 digits and the allowed characters are + . ( )
        //String phoneRegex2 = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        //String phoneRegex3 = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern MyPattern = Pattern.compile(phoneRegex1);
        Matcher MyMatcher = MyPattern.matcher(Phone);
        if (!MyMatcher.matches())
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    public Boolean EmailValidation(String Email)
    {

        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(Email);
        if (!MyMatcher.matches())
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    //This function checks if a contact exists with the email address entered in one of the email fields on the form. 
    public void RetrieveContact()
    {
        //ApexPages.getMessages().clear();        
        String ContactType = ApexPages.currentPage().getParameters().get('ContactType');
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, ContactType));
        String ContactEmail;
        
        List<Contact> contacts = new List<Contact>();
        Id AccountID;

        onChangeError = '';
        PageMessageSeverity = 'error';
        if (ContactType == 'admin')
        {            
            RSSForm.Admin_Contact__c = null;
            AFirstName = null;
            ALastName = null;
            APhone = null;
            RSSForm.Admin_Contact_Details__c = null;
            //system.assertEquals(RSSForm.Account__c,'1');
            if (RSSForm.Opportunity__c == NUll)
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select the opportunity before entering the Admin contact email'));  
                onChangeError = 'Please select an Opportunity before entering the Customer Administrator Contact Email Id';
                //system.assertEquals(1,2);
                return;
            }
            AccountID = [Select Account.Id from opportunity where id = :RSSForm.Opportunity__c].Account.id;
            if(AEmail == null || AEmail == '')
            {
                return;
            }
            AEmail = AEmail.trim();
            //ContactEmail = AEmail;
            if (!EmailValidation(AEmail))
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a valid ' +  'Admin email address'));  
                onChangeError = 'Please enter a valid Customer Administrator Contact Email Id';
                return;
            }
            else
            {
                contacts = [Select id,FirstName,LastName,Phone,Accountid,Account.name from Contact where email = :AEmail order by createddate desc limit 1];
                if(contacts != null && contacts.size() == 1)
                {
                    if(contacts[0].Accountid == AccountID)
                    {
                        AFirstName = contacts[0].FirstName;
                        ALastName = contacts[0].LastName;
                        APhone = contacts[0].Phone;
                        RSSForm.Admin_Contact__c = contacts[0].id; 
                        RSSForm.Admin_Contact_Details__c = null;
                    }
                    else
                    {
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">Admin Contact already exists against the Account ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + contacts[0].Accountid + '">'+ contacts[0].Account.name +'</a></h1>'));
                        onChangeError = '<h1 style="font-size:13px">Contact ' + contacts[0].FirstName + ' ' + contacts[0].LastName +' exists against the Account ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + contacts[0].Accountid + '">'+ contacts[0].Account.name +'</a>' + ' Please select a different Contact associated with the Account on the eRSS, or correct the contact data issue, in order to proceed.</h1>';
                    }
                }
                else if(contacts != null && contacts.size() == 0)
                {
                    RSSForm.Admin_Contact_Details__c = '1';
                }
                //else if(contacts != null && contacts.size() > 1)
                //{
                //        AEmail = null; 
                //        onChangeError = 'More than one contact exists with the same Customer Administrator Contact Email Id ' + AEmail; 
                //}
                else
                {
                        AEmail = null; 
                        onChangeError =  'Customer Administrator Contact not found ' + AEmail;
                }

            }    
        }
        else
        {
            RSSForm.Technical_Contact__c = null;
            TFirstName = null;
            TLastName = null;
            TPhone = null;
            RSSForm.Technical_Contact_Details__c = null;

            if (RSSForm.Opportunity__c == NUll)
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select the opportunity before entering the Technical contact email'));  
                onChangeError = 'Please select an Opportunity before entering the Customer Technical Contact Id';
                return;
            }
            AccountID = [Select Account.Id from opportunity where id = :RSSForm.Opportunity__c].Account.id;

            if(TEmail == null || TEmail == '')
            {
                return;
            }
            TEmail = TEmail.trim();
            //ContactEmail = TEmail;
            if (!EmailValidation(TEmail))
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a valid ' +  'Technical contact email address'));  
                onChangeError = 'Please enter a valid Customer Technical Contact Email Id';
                return;
            }
            else
            {
                contacts = [Select id,FirstName,LastName,Phone,Accountid,Account.name from Contact where email = :TEmail order by createddate desc limit 1];
                if(contacts != null && contacts.size() == 1)
                {
                    if(contacts[0].Accountid == AccountID)
                    {
                            TFirstName = contacts[0].FirstName;
                            TLastName = contacts[0].LastName;
                            TPhone = contacts[0].Phone;
                            RSSForm.Technical_Contact__c = contacts[0].id; 
                            RSSForm.Technical_Contact_Details__c = null;
                    }
                    else
                    {
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, '<h1 style="font-size:13px">Technical Contact already exists against the Account ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + contacts[0].Accountid + '">'+ contacts[0].Account.name +'</a></h1>'));
                        //onChangeError = '<h1 style="font-size:13px">Customer Technical Contact Email Id already exists against the Account ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + contacts[0].Accountid + '">'+ contacts[0].Account.name +'</a></h1>';
                        onChangeError = '<h1 style="font-size:13px">Contact ' + contacts[0].FirstName + ' ' + contacts[0].LastName +' exists against the Account ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + contacts[0].Accountid + '">'+ contacts[0].Account.name +'</a>' + ' Please select a different Contact associated with the Account on the eRSS, or correct the contact data issue, in order to proceed.</h1>';

                    }
                }
                else if(contacts != null && contacts.size() == 0)
                {
                    //New contact:
                    RSSForm.Technical_Contact_Details__c = '1'; 
                }
                //else if(contacts != null && contacts.size() > 1)
                //{
                //        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'More than one contact exists with the same email id ' + TEmail)); 
                //        TEmail = null; 
                //        onChangeError = 'More than one contact exists with the same Customer Technical Contact Email Id ' + TEmail; 
                //}
                else
                {
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Contact not found ' + TEmail)); 
                        TEmail = null; 
                        onChangeError = 'Customer Technical Contact not found ' + TEmail;     
                }
            }    
        }


    }
    // changes by Vandhana  
    // Query TSP on Opportunity selected and populate TSP field and Account on RSSForm for Valid Opportunity
    // Populate AE
    //Populate Partner Related Fields
    public void QueryTSP()
    {
        OpportunitySet=false;
        IndirectOpportunity=false;
        TSPNameToEmail = new Map<String,String>();

        //Query TSP(s) on select Opportunity
        List<Opportunity> oppIdTeamMembers = [select Id, Account.Id, (select User.Name,User.Email from OpportunityTeamMembers where TeamMemberRole = 'Technical Sales - Primary')
        from Opportunity where Id = :RSSForm.Opportunity__c];
        if (oppIdTeamMembers.size() > 0)
        {
            Opportunity opp = oppIdTeamMembers.get(0);
            RSSForm.Account__c = opp.Account.Id;
            //Changes by sharath for Leap
            if (opp.OpportunityTeamMembers != NULL)
            {
                // Populate TSP only when there is 1 TSP for Opportunity, add to list for email
                if(opp.OpportunityTeamMembers.size() == 1)
                {
                    OpportunitySet=true;
                    OpportunityTeamMember oppTeam =  opp.OpportunityTeamMembers.get(0);  
                    RSSForm.TSP__c = oppTeam.UserId;
                }

                // For multiple TSPs on Opportunity, add to list for email, TSP field not populated
                for (OpportunityTeamMember oppTeamMember : opp.OpportunityTeamMembers)
                {
                    TSPNameToEmail.put(oppTeamMember.User.Name,oppTeamMember.User.Email);
                }
            }
        }

        //changes by Vandhana for CR 3303711 : AE name auto-populate from Account Team Member with Sales - Primary role
        List<Account> accIdTeamMembers = [select Id, (select User.Id,User.Name from AccountTeamMembers where TeamMemberRole = 'Sales - Primary')
        from Account where Id = :RSSForm.Account__c];
        if (accIdTeamMembers.size() > 0)
        {
            Account acc = accIdTeamMembers.get(0);
            if (acc.AccountTeamMembers != NULL)
            {
                // Populate Account Executive only when there is 1 AE for Account
                if(acc.AccountTeamMembers.size() == 1)
                {
                    AccountTeamMember accTeam =  acc.AccountTeamMembers.get(0);  
                    RSSForm.AEName__c = accTeam.UserId;
                }
            }
        }
        // end of changes

        //changes by Vandhana for CR 3053881 : Populate Partner Involved check, Partner Organisation Name and Partner Project Delivery Contact
        Opportunity opp = [Select Id,Name,Deal_Type__c,Partner_Involved__c,Partner_Involved__r.Id from Opportunity where Id = :RSSForm.Opportunity__c limit 1];
        if(opp.Deal_Type__c == 'Indirect')
        {
            IndirectOpportunity=true;
            RSSForm.Partner_Involved__c = true;
            RSSForm.Partner_Name__c = opp.Partner_Involved__r.Id;
        }
    }

    // changes by Vandhana
    // Save function when Post Sales clicks on 'Save' on a Submitted form for the first time
    // Clones the form (creates new copy) for Post Sales
    public PageReference CloneNewRSSForm()
    {
        if (!ServicesForm)
        {
            CallRetrieveContact = false;
            ValidateOpportunity();    
            CallRetrieveContact = true;
        }                       
        if (InvalidOpportunity)
        { return null; }

        if(!validateSaveContact())
        {
            return null;
        }
        RSS_Form__c aNewForm = RSSForm.clone();
        insert aNewForm;
        
        // Clone Notes and Attachments
        List<Attachment> attachmentList = [select Body,IsPrivate,Name,OwnerId,ParentId from Attachment where ParentID =:RSSForm.id];
        List<Attachment> newAttachmentList = new list<Attachment>();
        Attachment a1 = new attachment();
        List<Note> NoteList =  [select Body,IsPrivate,Title,OwnerId,ParentId from Note where ParentID =:RSSForm.id];
        List<Note> newNoteList = new list<Note>();
        Note n1 = new Note();
        List<String> TempList = new List<String>();
        
        try
        {
            for(Attachment a:attachmentList)
            {
                a1 = new attachment();
                a1.Body = a.Body ;
                a1.IsPrivate = a.IsPrivate;
                a1.Name = a.Name;
                a1.OwnerId = a.OwnerId ;
                a1.ParentId=aNewForm.Id;
                newAttachmentList.add(a1);
            }
            insert newAttachmentList;

            for(Note n:NoteList)
            {
                n1 = new Note();
                n1.Body = n.Body ;
                n1.IsPrivate = n.IsPrivate;
                n1.Title = n.Title;
                n1.OwnerId = n.OwnerId ;
                n1.ParentId=aNewForm.Id;
                newNoteList.add(n1);
            }
            insert newNoteList;
        }
        catch(Exception e)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string>{'eae-ops@akamai.com'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Attachment Cloning for RSS Revised Forms failed');
            mail.setPlainTextBody ('Attachment Cloning for RSS Revised Forms failed for ' + RSSForm.id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        
        Boolean NotThere = true;

        // List of Templates on the Submitted form populated for the Cloned form
        List<String> newTemplateListString = new List<String>();
        for(SelectOption so:ChosenList)
        {
            newTemplateListString.add(so.getValue());
        }
        
        // Latest revision of Templates if modified by Architects
        //InvalidTemplates = !isTemplatesValid();  

        //if (InvalidTemplates)
        //{
        //    Set<String> templates = new Set <String>(newTemplateListString);
        //    templates.removeAll(InvalidTemplateRecordIds);
        //    for(Survey__c ss : [select id from Survey__c where UniqueName__c in :InvalidTemplateIds and RSS_Published__c = true])
        //    {
        //        templates.add(ss.id);
        //    }        
        //    newTemplateListString = new List<String>(templates);               
        //}                                 
        
        // Create Survey Taker records and associate Forms to selected Templates
        RSSUtility.CreateRSSFromTemplate(newTemplateListString,aNewForm.id);

        // Update Survey Responses only on the Cloned form
        Map<String,String> questionToResponseMap = new Map<String,String>();

        for(SurveyQuestionResponse__c resp : responses)
        {
            questionToResponseMap.put(resp.Survey_Question__r.UniqueName__c,resp.response__c);
        }

        List<SurveyQuestionResponse__c> surveyResponsesNew = new List<SurveyQuestionResponse__c>();
        for(SurveyQuestionResponse__c sqr : [Select Id,Response__c,Survey_Question__r.UniqueName__c from SurveyQuestionResponse__c where Survey_Question__r.UniqueName__c in :questionToResponseMap.keySet() and SurveyTaker__r.RSS_Form__c = :aNewForm.Id ])
        {
            sqr.Response__c = questionToResponseMap.get(sqr.Survey_Question__r.UniqueName__c);
            surveyResponsesNew.add(sqr);
        }
        
        update surveyResponsesNew;
        GenerateForm();
        ApexPages.getMessages().clear();
        // Redirect to New Cloned Form
        PageReference pR = new PageReference('/apex/RSSForm?id='+aNewForm.Id);
        pR.setRedirect(true);
        return pR;
    }
    //end of changes by Vandhana


    // Clones RSS Form (Submitted/Published) upon click of Revise
    public PageReference ReviseRSS()
    {
        List<Attachment> attachmentList = [select Body,IsPrivate,Name,OwnerId,ParentId from Attachment where ParentID =:RSSForm.id];
        List<Attachment> newAttachmentList = new list<Attachment>();
        Attachment a1 = new attachment();
        List<Note> NoteList =  [select Body,IsPrivate,Title,OwnerId,ParentId from Note where ParentID =:RSSForm.id];
        List<Note> newNoteList = new list<Note>();
        Note n1 = new Note();
        List<String> TempList = new List<String>();
        RSS_Form__c newRSSform;
        SurveyQuestionResponse__c tempResponse;
        List<SurveyTaker__c> Forms ;
        responses = new List<SurveyQuestionResponse__c>();
        newRSSform = new RSS_Form__c();
        
        for(RSS_Form__c s:[select Name,Id,AEName__c, Version__c,Submit_Version__c, Opportunity__c, UniqueName__c, Account__c, DigitalProperty__c, Partner_Involved__c,Partner_Name__c,Partner__c,Customer_Technical_Contact_Details__c, Customer_Technical_Contact_Name__c,TSP__c,Type_of_Integration__c,Commitment_Type__c,Created_Date__c, Customer_Risk__c,Customer_Business_Objective__c,Customer_agreed_Success_Criteria__c,Submittal_Date__c,Submitted_By__c,Published__c,LOE__c,Services_Form__c,Leap_Form__c,Admin_Contact__c,Technical_Contact__c
            from RSS_Form__c where Id = :RSSForm.id])
            {
                newRSSform.Name = s.Name;
                newRSSform.UniqueName__c = s.UniqueName__c;
                newRSSform.Published__c = false;
                newRSSform.Locked__c = false;
                newRSSform.AEName__c = s.AEName__c;
                newRSSform.Opportunity__c = s.Opportunity__c;
                newRSSform.DigitalProperty__c = s.DigitalProperty__c;
                newRSSform.Account__c = s.Account__c;
                newRSSform.Version__c = 0;
                newRSSform.Customer_Technical_Contact_Details__c = s.Customer_Technical_Contact_Details__c;
                newRSSform.Customer_Technical_Contact_Name__c = s.Customer_Technical_Contact_Name__c;
                // Changes by Vandhana - populate new fields' values
                newRSSform.Partner_Involved__c = s.Partner_Involved__c;
                newRSSform.Partner__c = s.Partner__c;
                newRSSform.Partner_Name__c = s.Partner_Name__c;
                newRSSform.Type_of_Integration__c = s.Type_of_Integration__c;
                newRSSform.Commitment_Type__c = s.Commitment_Type__c;
                newRSSform.Customer_agreed_Success_Criteria__c = s.Customer_agreed_Success_Criteria__c;
                newRSSform.Customer_Risk__c = s.Customer_Risk__c;
                newRSSform.Customer_Business_Objective__c = s.Customer_Business_Objective__c;
                newRSSform.Created_Date__c = s.Created_Date__c;
                newRSSform.TSP__c = s.TSP__c;

                // changes by Vandhana for CR 3306821 - add LOE field
                newRSSform.LOE__c = s.LOE__c;
                
                //changes by Sharath: Add Services_Form__c field
                newRSSform.Services_Form__c = s.Services_Form__c;

                //Changes by Sharath for Leap: 
                //Adding fields for Leap
                newRSSform.Leap_Form__c = s.Leap_Form__c;
                newRSSform.Admin_Contact__c = s.Admin_Contact__c;
                newRSSform.Technical_Contact__c = s.Technical_Contact__c;
                
                //Check if the form is not published. Revising a submitted form: setting the submit and submit locked flags to false and the submit verison to null
                if(!s.Published__c)
                {
                       newRSSform.Submitted__c = false; 
                       newRSSform.Submit_Locked__c = false;
                       newRSSform.Submit_Version__c = 0;
                }

                //Check if the form is published. Revising a published form: setting the submit and submit locked flags to true and retaining the submit version,submittal date and submitted by
                else if (s.Published__c)
                {
                        //Changes by Sharath: For a Services Form: The submitted and submit-locked flags are false
                       if(s.Services_Form__c)
                       {
                           newRSSform.Submitted__c = false; 
                           newRSSform.Submit_Locked__c = false;                                
                       }
                       else
                       {
                           newRSSform.Submitted__c = true; 
                           newRSSform.Submit_Locked__c = true;                                
                       } 
                       newRSSform.Submit_Version__c = s.Submit_Version__c;
                       newRSSform.Submittal_Date__c = s.Submittal_Date__c;
                       newRSSform.Submitted_By__c = s.Submitted_By__c;
                }
                //End of changes by shprasan
            }
            
        insert newRSSform;

        //insert Notes and Attachments
        try
        {
            for(Attachment a:attachmentList)
            {
                a1 = new attachment();
                a1.Body = a.Body ;
                a1.IsPrivate = a.IsPrivate;
                a1.Name = a.Name;
                a1.OwnerId = a.OwnerId ;
                a1.ParentId=newRSSform.Id;
                newAttachmentList.add(a1);
            }
            insert newAttachmentList;
            For(Note n:NoteList)
            {
                n1 = new Note();
                n1.Body = n.Body ;
                n1.IsPrivate = n.IsPrivate;
                n1.Title = n.Title;
                n1.OwnerId = n.OwnerId ;
                n1.ParentId=newRSSform.Id;
                newNoteList.add(n1);
            }
            insert newNoteList;
        }
        catch(Exception e)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string>{'eae-ops@akamai.com'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Attachment Cloning for RSS Revised Forms failed');
            mail.setPlainTextBody ('Attachment Cloning for RSS Revised Forms failed for ' + RSSForm.id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

        // Populate Chosen List for New Form
        for(SelectOption so:chosenList)
        {
            TempList.add(so.getValue());
        }
        RSSUtility.cloneRSSFromWithResponse(TempList,newRSSform.Id,RSSForm.Id);
        PageReference pg = new PageReference('/apex/RSSForm?id='+newRSSform.Id);
        pg.setRedirect(true);
        return pg;
    } 

    // changes by Vandhana - sets date fields (Created & Submitted Dates) on related Opportunity and flushes out date values from previously related Opportunity 
    public void UpdateOpportunityDateFields()
    {
        Decimal oldVersion;
        List <RSS_Form__c> oldForms = new List <RSS_Form__c> ();
        if (RSSForm.Submitted__c && !RSSForm.Locked__c)
        {
            oldVersion = RSSForm.Submit_Version__c - 1;
            oldForms = [select  Opportunity__c from RSS_Form__c where uniqueName__c = :RSSForm.UniqueName__c and Submit_Version__c = :oldVersion limit 1];     
        }
        else if (RSSForm.Published__c)
        {
            oldVersion = RSSForm.Version__c - 1;
            oldForms = [select Opportunity__c from RSS_Form__c where uniqueName__c = :RSSForm.UniqueName__c and Version__c = :oldVersion limit 1];     
        }
        List <Opportunity> opp = new List <Opportunity>();
        List <Opportunity> oppToUpdate = new List <Opportunity>();
        Opportunity opportunity;
        if(oldForms.size() > 0 && oldForms.get(0).Opportunity__c != NULL && oldForms.get(0).Opportunity__c != RSSForm.Opportunity__c)
        {
            opp = [Select Id,eRSS_Publish_Date__c,eRSS_Create_Date__c from Opportunity where Id = :oldForms.get(0).Opportunity__c limit 1];
            // Flush out date fields on previously related Opportunity
            if (opp.size() > 0)
            {
                opportunity = opp.get(0);
                opportunity.Validation_Override__c = true;
                opportunity.eRSS_Create_Date__c = NULL;
                opportunity.eRSS_Publish_Date__c = NULL;
                oppToUpdate.add(opportunity);
            }
        }
        opp = [Select Id,eRSS_Publish_Date__c,eRSS_Create_Date__c from Opportunity where Id = :RSSForm.Opportunity__c limit 1];
        if (opp.size() > 0)
        {
            opportunity = opp.get(0);
            opportunity.Validation_Override__c = true;
            opportunity.eRSS_Create_Date__c = RSSForm.Created_Date__c;
            opportunity.eRSS_Publish_Date__c = RSSForm.Submittal_Date__c;
            oppToUpdate.add(opportunity);
        }
        update oppToUpdate;
    }

    //Added the wrapper function for CheckForInvalidScenarios 
    public PageReference WrapperForCheckForInvalidScenarios()
    {
        CheckForInvalidScenarios();
        return null;   
    }

    //Changes by shprasan: Added the function to Check for invalid scenarios
    public Boolean CheckForInvalidScenarios()
    {

        List<RSS_Form__c> RSSForms;
        // If the user is PreSales, check if any submitted version of the form is published
        if(PreSales)
        {
            RSSForms = [select ID from RSS_Form__c where UniqueName__c= :RSSForm.UniqueName__c and Published__c = true];
            if( RSSForms != null && RSSForms.size() > 0 && RSSForms.get(0).ID != RSSForm.ID)   
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, '<h1 style="font-size:13px">The Submitted version of this Form has been Published. No further changes can be made. ' +  '<a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForms.get(0).ID + '">Click here to view the Published Form</a></h1>'));
                ValidScenario = false;
                return true;
            }            
        }
        // If the user is PostSales, check if the submitted flag of the current form is false
        else if(PostSales)
        {
            //RSSForms = [select Submitted__c from RSS_Form__c where UniqueName__c= :RSSForm.UniqueName__c and ID= :RSSForm.ID];
            RSSForms = [select ID,Submit_Version__c from RSS_Form__c where UniqueName__c= :RSSForm.UniqueName__c and Submitted__c = true order by Submit_Version__c desc];
            if( RSSForms != null && RSSForms.size() != 0 && RSSForms.get(0).Submit_Version__c != RSSForm.Submit_Version__c && RSSForm.Submit_Locked__c == true)   
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, '<h1 style="font-size:13px">This Form has been resubmitted. Please work on the latest version. Changes made on this form will not be Saved.' + ' <a target="__blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForms.get(0).ID + '">Click here to view the latest version</a></h1>'));
                ValidScenario = false;
                return true;
            }
        }
        return false;
    }

    public void AutoSave()
    {
        try
        {
           update responses;
        }
        catch(Exception e)
        {
            ApexPages.addMessages(e);
        }
    }
        
    //Start of changes by shprasan: adding another parameter. Checks if the publish flag is true, gets the latest publish version. Otherwise gets the latest submit version
    public Integer getNextVersionNumber(String Guid,Boolean publish)
    {
        //start of changes by shprasan
        //doing the check for publish/submit

        //Getting the latest version based on submit or publish
        List<RSS_Form__c> RSSForms;
        if(publish)
        {
            RSSForms = [select Version__c from RSS_Form__c where UniqueName__c= :Guid order by Version__c  desc NULLS LAST];
        }
        else
        {
            RSSForms = [select Submit_Version__c from RSS_Form__c where UniqueName__c= :Guid order by Submit_Version__c  desc NULLS LAST];   
        }

        if(RSSForms!=null && RSSForms.size() > 0)
        {
            Integer FormVersion;
            if (publish)
            {
                  FormVersion = Integer.valueOf(RSSForms[0].Version__c) +1;  
            }
            else
            {
                  FormVersion = Integer.valueOf(RSSForms[0].Submit_Version__c) +1;  
            }
            return FormVersion;
    
        }
        return 0;
    }
     
    //Changes by shprasan: Checking for not submitted and not published
    public Boolean isTemplatesValid()
    {
        Boolean isValid = true;
        String inValidTemplates ='';
        InvalidFormIds = new List<String>();
        InvalidTemplateIds = new List<String>();
        InvalidTemplateRecordIds = new List<String>();
        for(SurveyTaker__c st : [select id, Survey__r.Name,Survey__r.ID,Survey__r.RSS_Published__c,Survey__c,Survey__r.UniqueName__c from SurveyTaker__c where RSS_Form__c =:RSSForm.id])
        {
            if(!st.Survey__r.RSS_Published__c)
            {
                isValid=false;
                inValidTemplates += st.Survey__r.Name + ', ';
                InvalidTemplateIds.add(st.Survey__r.UniqueName__c);       
                InvalidTemplateRecordIds.add(st.Survey__r.ID);
                InvalidFormIds.add(st.id);
            }
        }

        //Changes by shprasan: Changing the if condition
        // Changes by Vandhana : modifying If condition and error message
        if(!isValid && ( ((PostSales || SuperUser) && !RSSForm.Published__c) || (PreSales && !RSSForm.Submitted__c)) && !Disabled)
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' The Following Template(s) : ' + inValidTemplates.substring(0,inValidTemplates.length()-2) + '; is/are not the latest versions. Please click on \'Update Product Forms\' button to use the latest versions or remove them to continue.'));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, ' The following Template(s) : <b>' + inValidTemplates.substring(0,inValidTemplates.length()-2) + '</b>; is/are not the latest version. Click on \'Update Product Forms\' button to use the latest version, if not please continue. <br>Note that the Template data will be lost on click of the \'Update Product Forms\' button.'));
                return false;
            }
        return true;
    }

    // associates Forms with latest Templates re-submitted by Architects post revision
    public PageReference UpdateProductForms()
    {
        if (SaveNewFlag)
        {
            PageReference pg = CloneNewRSSForm();
            return pg;
        }
        Map<String,String> MapQuestionCurrentResponse = new Map<String,String>();
        List<String> MapPublishedTemplates = new List<String>();
        for(Survey__c ss : [select id from Survey__c where UniqueName__c in :InvalidTemplateIds and RSS_Published__c = true])
        {
            MapPublishedTemplates.add(ss.id);
        }
        for(SurveyQuestionResponse__c sqr:responses)
        {
           MapQuestionCurrentResponse.put(sqr.Survey_Question__r.UniqueName__c,sqr.Response__c);
        }
      //  system.assertEquals(InvalidFormIds,InvalidTemplateIds);
        delete [select id from SurveyTaker__c where id in :InvalidFormIds];
        RSSUtility.CreateRSSFromTemplate(MapPublishedTemplates,RSSForm.id);
        GenerateForm();
        String tempResponse = null;
        for(SurveyQuestionResponse__c sqr:responses)
        {
            tempResponse = MapQuestionCurrentResponse.get(sqr.Survey_Question__r.UniqueName__c);
            if(tempResponse !=null)
            {
                sqr.Response__c = tempResponse;
            }
        }
        update responses;
        InvalidTemplates = false;
        return null;
    }
        
    public PageReference publishForm()
    {

        //RSSForm.Published__c = true;
        //RSSForm.Locked__c = true;
        //RSSForm.Version__c = getNextVersionNumber(RSSForm.UniqueName__c);
        errorFlag = false;
        onChangeError = '';
        
        //cookie
        flaggedSQR = false;
        if (!ServicesForm && CheckForInvalidScenarios())
        {
            //Disabled = true;
            errorFlag = true;
            return null;                    
        }
        
        //ApexPages.getMessages().clear();
       
        if(RSSForm.Name == null || RSSForm.Name == '')
        {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the Form Name.'));
             errorFlag = true;
             return Null;            
        }

    //changes by Vandhana - return NULL only at the end, consolidate all error messages

        if(RSSForm.Customer_Technical_Contact_Name__c == NULL && !LeapForm)
        {
            errorFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the Customer Technical Contact Name.'));
            //return null;
        }
       
       if((RSSForm.Customer_Technical_Contact_Details__c == NULL || RSSForm.Customer_Technical_Contact_Details__c == '' )&& !LeapForm)
       {
            errorFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the Customer Technical Contact Details.'));
            //return null;
       }
       
       if(RSSForm.Commitment_Type__c == NULL)
       {
            errorFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select the Commitment Type.'));
            //return NULL;
       }

       if(RSSForm.Type_of_Integration__c == NULL)
       {
            errorFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select the Integration Management Type.'));
            //return NULL;
       }
       
        if(RSSForm.Customer_agreed_Success_Criteria__c == NULL || RSSForm.Customer_agreed_Success_Criteria__c == '')
        {
            errorFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the Customer agreed Success Criteria.'));
            //return NULL;
        }  
       
        if(RSSForm.Opportunity__c == NULL )
        {
            errorFlag = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select the Opportunity.'));
            //return NULL;
        } 
        if(chosenList.size() <1)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one Product from the available list.'));
            errorFlag = true;
            //return NUll;
        }
        //changes by sharath: validate for only non-services form
        if(!ServicesForm)
        {
            CallRetrieveContact = false;
            ValidateOpportunity();    
            CallRetrieveContact = true;
        }        
        if (InvalidOpportunity)
        {
            errorFlag = true;
        }
        //Changes by Sharath for leap
        if(LeapForm  && (AEmail == null || AEmail == '')) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill in the Customer Administrator Contact details'));
            errorFlag = true;
        }
        if(LeapForm)
        {
            if(!validateSaveContact())
            {
                errorFlag = true;       
            }
        }
       
       //Moving the check for required questions inside the try block          

       //Start of changes by shprasan 
       //Adding Submitted__c to the query
       List<RSS_Form__c> Rssforms = [select id,Locked__c,Submit_Locked__c,Submitted__c,Published__c from RSS_Form__c where uniqueName__c = :RSSForm.UniqueName__c and id!=:RSSForm.id];
       Set<RSS_Form__c> RssformsSet = new Set <RSS_Form__c>();
       
       //Setting published flag or submitted flag false based on the context
       for(RSS_Form__c rf:Rssforms)
       {
            //Changes by Sharath: treat services forms as published forms 
           if(RSSForm.Submitted__c || ServicesForm)
           {
                if (rf.Published__c)
                {
                    rf.Published__c = false;    
                    RssformsSet.add(rf);
                }
                
           }
           else if(!RSSForm.Submitted__c && !ServicesForm)
           {
                if (rf.Submitted__c)
                {
                    rf.Submitted__c = false;
                    RssformsSet.add(rf);       
                } 
           }
           //End of changes by shprasan
           //rf.Locked__c = true;
       }
       
       try
       {
            //start of changes by shprasan
            FromPublish = true;
            UpdateForm();

            //cookietesting
            FromPublish = false;
            for(SurveyQuestionResponse__c sqr:responses)
            {
                if(sqr.Survey_Question__r.Required__c && String.isEmpty(sqr.response__c))
                {
                    //ApexPages.getMessages().clear();
                    errorFlag = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please answer all the required questions')); 
                    
                    //Checking if the form has to be submitted or published
                    if(RSSForm.Submitted__c || ServicesForm)
                    {
                        RSSForm.Published__c = false;
                    }
                    else if(!RSSForm.Submitted__c && !ServicesForm)
                    {
                        RSSForm.Submitted__c = false;
                    }
                    
                    RSSForm.Locked__c = false;
                    return null;
                }
            }

            if(flaggedSQR || errorFlag)
            {
                return NULL;
            }
            //Changes by Sharath for leap
            if(LeapForm)
            {
               List <Contact> contactsToCreate = new List <Contact>();
               Contact c;
               List <String> contactDetails;

               Id recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
               //if(RSSForm.Admin_Contact__c == null && AEmail != null && AEmail != '' && RSSForm.Admin_Contact_Details__c != null && RSSForm.Admin_Contact_Details__c != '')
               //{

               //}
               //if (RSSForm.Technical_Contact__c == null && TEmail != null && TEmail != '' && TEmail != AEmail && RSSForm.Technical_Contact_Details__c != null && RSSForm.Technical_Contact_Details__c != '')
               //{
                
               //}

               if (RSSForm.Admin_Contact__c == null && AEmail != null && AEmail != '' && RSSForm.Admin_Contact_Details__c != null && RSSForm.Admin_Contact_Details__c != '')
               {
                    contactDetails = new List <String>();
                    contactDetails = RSSForm.Admin_Contact_Details__c.split('\n');
                    if(contactDetails.size() != 4)
                    {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the Customer Administrator Contact details'));
                            return null;
                    }
                    c = new Contact();
                    c.RecordTypeId = recordtypeID;
                    c.Email = contactDetails[0];
                    c.FirstName = contactDetails[1];
                    c.LastName = contactDetails[2];
                    c.Phone = contactDetails[3];
                    c.AccountId = RSSForm.Account__c;
                    c.Validation_Override__c = true;
                    contactsToCreate.add(c);
               }
               if (RSSForm.Technical_Contact__c == null && TEmail != null && TEmail != '' && TEmail != AEmail && RSSForm.Technical_Contact_Details__c != null && RSSForm.Technical_Contact_Details__c != '')
               {
                    contactDetails = new List <String>();
                    contactDetails = RSSForm.Technical_Contact_Details__c.split('\n');
                    if(contactDetails.size() != 4)
                    {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the Customer Technical Contact details'));
                            return null;
                    }                        
                    c = new Contact();
                    c.RecordTypeId = recordtypeID;
                    c.Email = contactDetails[0];
                    c.FirstName = contactDetails[1];
                    c.LastName = contactDetails[2];
                    c.Phone = contactDetails[3];
                    c.AccountId = RSSForm.Account__c;
                    c.Validation_Override__c = true;
                    contactsToCreate.add(c);
                    
               }
               if(contactsToCreate.size() > 0)
               {
                    try
                    {
                        insert contactsToCreate;
                    }
                    catch(Exception e)
                    {
                        ApexPages.addMessages(e);
                        return null;
                    }
                    for(Contact c1 : contactsToCreate)
                    {
                        if(AEmail == TEmail && AEmail != NULL && AEmail != '')
                        {
                            RSSForm.Admin_Contact__c = c1.id;    
                            RSSForm.Technical_Contact__c = c1.id;
                            RSSForm.Admin_Contact_Details__c = NULL;
                            RSSForm.Technical_Contact_Details__c = NULL;
                        }
                        else
                        {
                            if(c1.Email == AEmail)
                            {
                                RSSForm.Admin_Contact__c = c1.id;  
                                RSSForm.Admin_Contact_Details__c = NULL;  
                            }
                            else
                            {
                                RSSForm.Technical_Contact__c = c1.id;
                                RSSForm.Technical_Contact_Details__c = NULL;
                            }    
                        
                        }
                    }            
                }
            }
            //End of changes for Leap
            //GenerateForm();

            // cookietesting
            //FromPublish = false;
            //for(SurveyQuestionResponse__c sqr:responses)
            //{
            //    if(sqr.Survey_Question__r.Required__c && String.isEmpty(sqr.response__c))
            //    {
            //        //ApexPages.getMessages().clear();
            //        errorFlag = true;
            //        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please answer all the required questions')); 
                    
            //        //Checking if the form has to be submitted or published
            //        if(RSSForm.Submitted__c || ServicesForm)
            //        {
            //            RSSForm.Published__c = false;
            //        }
            //        else if(!RSSForm.Submitted__c && !ServicesForm)
            //        {
            //            RSSForm.Submitted__c = false;
            //        }
                    
            //        RSSForm.Locked__c = false;
            //        return null;
            //    }
            //}

           //end of changes by shprasan         
           
           //Start of changes by shprasan: Setting the published or submitted flag, the locked flag and the version based on the context           
           //RSSForm.Version__c = getNextVersionNumber(RSSForm.UniqueName__c);
           //Having two locked flags. The Submit_Locked flag is not false on revising a published form.
           if(RSSForm.Submitted__c || ServicesForm)
           {
                RSSForm.Published__c = true;
                RSSForm.Locked__c = true;   
                RSSForm.Version__c = getNextVersionNumber(RSSForm.UniqueName__c,true);
                UpdateAcceptanceFormLookup();
                
           }
           else if (!RSSForm.Submitted__c && !ServicesForm)
           {
                RSSForm.Submitted__c = true;
                RSSForm.Submit_Locked__c = true;                                
                RSSForm.Submit_Version__c = getNextVersionNumber(RSSForm.UniqueName__c,false);
                RSSForm.Submitted_By__c = UserInfo.getUserId();
                RSSForm.Submittal_Date__c = Date.today();
           }

           List<RSS_Form__c> RssformsToUpdate = new List<RSS_Form__c>(RssformsSet);
           update RSSForm;
           update RssformsToUpdate;
           //Start of changes by shprasan: Calling the function to send mails to the TSP
           //changes by Sharath: update opportunity date fields only for non-Services Forms
           if(!ServicesForm)
           {
                UpdateOpportunityDateFields();    
           }           
           sendMailToTSP();
           //End of changes by shprasan
           system.debug('done updated');
           CheckDisabled();
           errorFlag = false;
           //start of changes by shprasan
           PageReference pg = new PageReference('/apex/RSSForm?id='+RSSForm.id);
           pg.setRedirect(true);
           return pg;
           //end of changes by shprasan 
       }
       catch(Exception e)
       {
           ApexPages.addMessages(e);
       }
       return null;
    }

    //changes by sharath: Added the function to update the RSS Form lookup field on the corresponding Acceptance Form
    public void UpdateAcceptanceFormLookup()
    {
        ERSS_Acceptance_Form__c AcceptanceForm = new ERSS_Acceptance_Form__c();
        List<ERSS_Acceptance_Form__c> AcceptanceForms = new List<ERSS_Acceptance_Form__c>();
        AcceptanceForms = [select id,RSS_Form__c from ERSS_Acceptance_Form__c where RSS_Form_UniqueName__c = :RSSForm.UniqueName__c];
        if(AcceptanceForms != null && AcceptanceForms.size() > 0)
        {
            AcceptanceForm = AcceptanceForms[0];
                if (AcceptanceForm.RSS_Form__c != RSSForm.id)
                {
                    AcceptanceForm.RSS_Form__c = RSSForm.id;
                    update AcceptanceForm;            
                }
        }        
    }

    //Start of changes by shprasan: Creating the function to send mails to the TSP
    public void sendMailToTSP()
    {
        String fromAddress = eRSS__c.getInstance('eRSS').From_Address__c;
        System.debug('From Address: '+fromAddress);
        String orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        System.debug(orgWideEmailId);
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        String Subject;
        String BodySalutation;
        String Body;
        String ChangesComparison = '';
        List<RSS_Form__c> emailForm = [Select Account__r.Name,Opportunity__r.Name from RSS_Form__c where id = :RSSForm.ID];
        if(RSSForm.Submitted__c && !RSSForm.Published__c)
        {
            Subject = 'eRSS Form Submitted || ' + RSSForm.Name;
            if(RSSForm.Submit_Version__c == 1)
            {
                Body = '<br /><br />An eRSS Form has been Submitted with the below details:<br />'
                     + 'Form Name: ' + RSSForm.Name + '<br />'
                     + 'Account Name: ' + emailForm.get(0).Account__r.Name + '<br />'
                     + 'Opportunity Name: ' + emailForm.get(0).Opportunity__r.Name + '<br /><br />'
                     + 'To view the form in detail: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id;
            }
            else
            {
                 //Calling the function to compare the form versions: The fields of the form and the templates
                ChangesComparison = compareFormVersions(false,emailForm.get(0).Account__r.Name,emailForm.get(0).Opportunity__r.Name);
                if (ChangesComparison == '')
                {
                      Body = '<br /><br />The eRSS Form <a target="__blank" href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id + '"> ' + RSSForm.Name + ' </a>has been resubmitted with no changes.<br />';  
                }
                else
                {
                      Body = '<br /><br />The eRSS Form <a target="__blank" href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id + '"> ' + RSSForm.Name + ' </a>has been resubmitted with the below changes :<br />';  
                }
            }
        }
        //Changes by Sharath: Checking for Services Form 
        else if((RSSForm.Submitted__c && RSSForm.Published__c) || (RSSForm.Published__c && ServicesForm))
        {
            Subject = 'eRSS Form Published || ' + RSSForm.Name;
            if(RSSForm.Version__c == 1)
            {
                Body = '<br /><br />An eRSS Form has been Published with the below details:<br />'
                     + 'Form Name: ' + RSSForm.Name + '<br />'
                     + 'Account Name: ' + emailForm.get(0).Account__r.Name + '<br />'
                     + 'Opportunity Name: ' + emailForm.get(0).Opportunity__r.Name + '<br /><br />'
                     + 'To view the form in detail: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id;
            }
            else
            {
                //Body = '\n\nAn eRSS Form has been republished with the below changes:\n\n';  
                
                ChangesComparison = compareFormVersions(true,emailForm.get(0).Account__r.Name,emailForm.get(0).Opportunity__r.Name);
                if (ChangesComparison == '')
                {
                    Body = '<br /><br />The eRSS Form <a target="__blank" href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id + '"> ' + RSSForm.Name + ' </a>has been republished with no changes.<br />';
                }
                else
                {
                    Body = '<br /><br />The eRSS Form <a target="__blank" href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id + '"> ' + RSSForm.Name + ' </a>has been republished with the below changes :<br />';
                }
            }                        
        }
        for (String TSPName : TSPNameToEmail.keySet())
        {
                //BodySalutation = 'Hi ' + TSPName;
                BodySalutation = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + TSPName;
                email = new Messaging.SingleEmailMessage();  
                email.setToAddresses(new List<String>{TSPNameToEmail.get(TSPName)});   
                email.setOrgWideEmailAddressId(orgWideEmailId);
                email.setSubject(Subject);
                email.setHTMLBody(BodySalutation + Body + ChangesComparison + '</body></html>');
                mailsToBeSent.add(email);
        }
        if(mailsToBeSent != null && mailsToBeSent.size()>0)
        {
            Messaging.sendEmail(mailsToBeSent,false);
        }

    }
        
    //Changes by shprasan: added the function to compare the older and the latest versions of the form
    public String compareFormVersions(Boolean publish,String AccountName,String OpportunityName)
    {        
        List <RSS_Form__c> emailForms;
        Decimal oldVersion; 
        String ChangesComparison = '';
        //Query for the earlier version of the form
         if(publish)
         {
            oldVersion = RSSForm.Version__c - 1;
             emailForms = [select  Name,Partner_Involved__c,Partner_Name__c,Partner__c,Customer_Technical_Contact_Name__c,Customer_Technical_Contact_Details__c,Commitment_Type__c,Type_of_Integration__c,Account__c,Account__r.Name,AEName__c,Opportunity__c,Opportunity__r.Name,Customer_Business_Objective__c,Customer_Risk__c,Customer_agreed_Success_Criteria__c, LOE__c
                 from RSS_Form__c where uniqueName__c = :RSSForm.UniqueName__c and Version__c = :oldVersion];
         }  
         else
         {
            oldVersion = RSSForm.Submit_Version__c - 1;
             emailForms = [select  Name,Partner_Involved__c,Partner_Name__c,Partner__c,Customer_Technical_Contact_Name__c,Customer_Technical_Contact_Details__c,Commitment_Type__c,Type_of_Integration__c,Account__c,Account__r.Name,AEName__c,Opportunity__c,Opportunity__r.Name,Customer_Business_Objective__c,Customer_Risk__c,Customer_agreed_Success_Criteria__c, LOE__c
                from RSS_Form__c where uniqueName__c = :RSSForm.UniqueName__c and Submit_Version__c = :oldVersion];   
         } 
         //To compare the fields in the two versions of the form, Creating a list of strings with the fields to compare
         List <String> fields = new List <String> {'Name','Partner_Involved__c','Partner_Name__c','Partner__c','Customer_Technical_Contact_Name__c','Customer_Technical_Contact_Details__c','Commitment_Type__c','Type_of_Integration__c','Account__c','AEName__c','Opportunity__c','Customer_Business_Objective__c','Customer_Risk__c','Customer_agreed_Success_Criteria__c'};
         Map <String,String> FieldAPiToLabel = new Map <String,String> ();
         FieldAPiToLabel.put('Name','Name');
         FieldAPiToLabel.put('Partner_Involved__c','Partner Involved?');
         FieldAPiToLabel.put('Partner_Name__c','Partner Organisation Name');
         FieldAPiToLabel.put('Partner__c','Partner Project Delivery Contact');
         FieldAPiToLabel.put('Customer_Technical_Contact_Name__c','Customer Technical Contact Name');
         FieldAPiToLabel.put('Customer_Technical_Contact_Details__c','Customer Technical Contact Details');
         FieldAPiToLabel.put('Commitment_Type__c','Commitment Type');
         FieldAPiToLabel.put('Type_of_Integration__c','Integration Management Type');
         FieldAPiToLabel.put('AEName__c','AE Name');
         FieldAPiToLabel.put('Customer_Business_Objective__c','Customer Business Objective');
         FieldAPiToLabel.put('Customer_Risk__c','Customer Risk');
         FieldAPiToLabel.put('Customer_agreed_Success_Criteria__c','Customer agreed Success Criteria');
         FieldAPiToLabel.put('Account__c','Account');
         FieldAPiToLabel.put('Opportunity__c','Opportunity');
         FieldAPiToLabel.put('LOE__c','LOE');
         
         for (String field : fields)
         {
                //if the field is a text area, then check is made to determine if the field was blank or null in the earlier version and blank or null in the current version
               if (!((emailForms.get(0).get(field) == null || emailForms.get(0).get(field) == '')&& (RSSForm.get(field) == null || RSSForm.get(field) == '')) && emailForms.get(0).get(field) != RSSForm.get(field))
               {
                    if(field == 'Opportunity__c')
                    {
                         ChangesComparison += '<br />' + FieldAPiToLabel.get(field) + ': ' + OpportunityName;   
                    }
                    else if(field == 'Account__c')
                    {
                        ChangesComparison += '<br />' + FieldAPiToLabel.get(field) + ': ' + AccountName;
                    }
                    else
                    {
                            ChangesComparison += '<br />' + FieldAPiToLabel.get(field) + ': ' + RSSForm.get(field);                            
                    }
               } 
         }
         //calling the function to compare the template section of the two form versions
         ChangesComparison += compareTemplatePanel(emailForms.get(0).id);
         //ChangesComparison += '\n\nTo view the form in detail: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RSSForm?id=' + RSSForm.id;
         return ChangesComparison;
    }
    

    public String compareTemplatePanel(ID oldFormId)
    {
        //String ChangesComparison = '\nThe Template Section of the Form: \n';
        String ChangesComparison = '';
        List<SurveyTaker__c>oldSurveyTakers = [select id,Survey__c,Survey__r.Name,Survey__r.UniqueName__c,Survey__r.Version__c from SurveyTaker__c where RSS_Form__c =:oldFormId order by Survey__r.Name];
        List<SurveyTaker__c>newSurveyTakers = [select id,Survey__c,Survey__r.Name,Survey__r.UniqueName__c,Survey__r.Version__c from SurveyTaker__c where RSS_Form__c =:RSSForm.ID order by Survey__r.Name];
        List<id> toCompare = new List<id>();
        Boolean NotThere = true;
        String OldResponse = '';
        String NewResponse = '';
        //Determining which templates were removed or added. We have to compare only those templates which are there in both the form versions and the which have been unchanged(Not the answers but the template verison)
        for (SurveyTaker__c surveyTaker : oldSurveyTakers)
        {   
            NotThere = true;
            for(SurveyTaker__c newSurveyTaker: newSurveyTakers)
            {
                if (newSurveyTaker.Survey__r.Name == surveyTaker.Survey__r.Name)
                {
                    if (newSurveyTaker.Survey__r.Version__c != surveyTaker.Survey__r.Version__c)
                    {
                        ChangesComparison += '\nThe version of the Template ' +  surveyTaker.Survey__r.Name + ' has changed';          
                    }
                    else
                    {
                        toCompare.add(surveyTaker.id);
                        toCompare.add(newSurveyTaker.id);
                        System.debug('The no of survey takers ' + toCompare.size());
                    }
                    NotThere = false;
                } 
            }
            if(NotThere)
            {
                ChangesComparison += '<br />The Product ' + surveyTaker.Survey__r.Name + ' has been removed';
            }
        }
        //The list toCompare stores the templates that have to be compared
        for (SurveyTaker__c newSurveyTaker: newSurveyTakers)
        {   NotThere = true;
            for(SurveyTaker__c surveyTaker : oldSurveyTakers)
            {
                if (newSurveyTaker.Survey__r.Name == surveyTaker.Survey__r.Name)
                {
                    NotThere = false;
                } 
            }
            if(NotThere)
            {
                ChangesComparison += '<br />The Product ' + newSurveyTaker.Survey__r.Name + ' has been added';
            }
        }
        if(toCompare.size() > 0)
        {
            //Creating a map of Template Name to a Map of Questions to the answers to those questions in the two forms
            //every record in the map has a template name as the key. The value is a map of question to the answer in the previous verison of the form and the answer in the current version of the form
            Map <String,Map<String,List<String>>> SurveyToQuestionToResponses = new Map <String,Map<String,List<String>>>();
            List <SurveyQuestionResponse__c> questionResponses = [SELECT Id, Response__c, SurveyTaker__c, SurveyTaker__r.Survey__r.Name,SurveyTaker__r.RSS_Form__c,SurveyTaker__r.RSS_Form__r.Submit_Version__c,SurveyTaker__r.RSS_Form__r.Version__c,Survey_Question__r.UniqueName__c,Survey_Question__r.Question__c,Survey_Question__r.OrderNumber__c,Survey_Question__r.Survey_Question_Group__r.Order_Number__c FROM SurveyQuestionResponse__c WHERE SurveyTaker__c IN :toCompare order by SurveyTaker__r.RSS_Form__r.Version__c, SurveyTaker__r.RSS_Form__r.Submit_Version__c,Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c];
            //Doing a order by the Form ID: The answers in the previous version come first; Order by Question group: The sections in the templates are arranged in ascending order; Order by Question order: The questions in a section are arranged in ascending order
            String questionChanges = '';
            //System.debug('The number of responses in all: ' + questionResponses.size() + ' The size of surveytakers: ' + toCompare.size() + ' The takers id: ' + toCompare);
            for (SurveyQuestionResponse__c questionResponse : questionResponses)
            {
                if( !SurveyToQuestionToResponses.containsKey(questionResponse.SurveyTaker__r.Survey__r.Name))
                {
                    SurveyToQuestionToResponses.put(questionResponse.SurveyTaker__r.Survey__r.Name, new Map<String,List<String>> ());
                   // SurveryToQuestionToResponses.get(questionResponse.SurveryTaker__r.Survey__r.Name).put(questionResponse.Survey_Question__r.UniqueName__c,new List<String>());  
                }
                if(! SurveyToQuestionToResponses.get(questionResponse.SurveyTaker__r.Survey__r.Name).containsKey(questionResponse.Survey_Question__r.Question__c))
                {
                    SurveyToQuestionToResponses.get(questionResponse.SurveyTaker__r.Survey__r.Name).put(questionResponse.Survey_Question__r.Question__c,new List <String>());   
                }
                SurveyToQuestionToResponses.get(questionResponse.SurveyTaker__r.Survey__r.Name).get(questionResponse.Survey_Question__r.Question__c).add(questionResponse.Response__c);
            }
            for (String SurveyName: SurveyToQuestionToResponses.keySet())
            {                    
                    //questionChanges += '<br /><b>' + SurveyName + '</b>';
                    //questionChanges += '<br /><table><tr><th> Question </th<th> Old Response </th><th>Updated Response</th></tr>' ;
                    for (String QuestionName : SurveyToQuestionToResponses.get(SurveyName).keySet())
                    {
                        //system.debug('The question :' + QuestionName +' of Survey ' + SurveyName + ' has ' + SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).size() + ' responses: ' + SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(0));
                        if(SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(0) != SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(1))
                        {
                            //questionChanges += '<br /> The response to question: ' + QuestionName + ' has been changed from ' + SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(0) + ' to ' + SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(1);
                            OldResponse = SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(0) == null ? '' : SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(0);
                            NewResponse = SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(1) == null ? '' : SurveyToQuestionToResponses.get(SurveyName).get(QuestionName).get(1);
                            questionChanges += '<tr><td>' + QuestionName + '</td><td>' + OldResponse + '</td><td>' + NewResponse + '</td></tr>';
                        }
                    }
                    if (questionChanges != '')
                    {
                        //ChangesComparison += '<br /><br />The change in the responses of Template: ' + SurveyName + ' <br />';
                        ChangesComparison += '<br /><br /><b>' + SurveyName + '</b>';
                        ChangesComparison += '<br /><table><tr><th> Question </th><th> Old Response </th><th>Updated Response</th></tr>' ;
                        ChangesComparison += questionChanges;
                        ChangesComparison += '</table>';
                        questionChanges = '';
                    }
            }
        }
        return ChangesComparison;
    }

    //Changes by sharath: added the function. This checks if the acceptance form is already created. If not creates one and then navigates to it.
    public PageReference NavigateToAcceptanceForm()
    {
        String AcceptanceFormId;
        List<ERSS_Acceptance_Form__c> AcceptanceForms = new List<ERSS_Acceptance_Form__c>();
        AcceptanceForms = [select id from ERSS_Acceptance_Form__c where RSS_Form_UniqueName__c = :RSSForm.UniqueName__c];
        if(AcceptanceForms == null || AcceptanceForms.size() == 0 )
        {
            ERSS_Acceptance_Form__c AcceptanceForm = new ERSS_Acceptance_Form__c();
            AcceptanceForm.Name = GuidUtil.NewGuid(); 
            AcceptanceForm.RSS_Form__c = RSSForm.id;
            AcceptanceForm.RSS_Form_UniqueName__c = RSSForm.UniqueName__c;
            insert AcceptanceForm;
            AcceptanceFormId = AcceptanceForm.id;
        }
        else
        {
            AcceptanceFormId = AcceptanceForms[0].id;
        }
        PageReference pg = new PageReference('/apex/RSS_Acceptance_Form?id=' + AcceptanceFormId);
        pg.setRedirect(true);
        return  pg;
    }
    public PageReference DownloadOfflineData()
    {

        PageReference pg = new PageReference('/apex/RSSFormOfflineDownload?id=' + RSSForm.id);
        pg.setRedirect(true);
        return  pg;
    }   
    
    public PageReference DownloadPDF()
    {
        system.debug('^^^^^1 : '+ pdfResponseGroupWrappers);
        system.debug('^^^^^2 : '+ responses);
        system.debug('^^^^^3 : '+ responseGroupWrappers);
        system.debug('^^^^^4 : '+ RSSFormWrappers);
        system.debug('^^^^^5 : '+ RSSFormWrappers);
        system.debug('^^^^^6 : '+ questionGroups);
        //system.debug('^^^^^1 : '+ );
        PageReference pg = new PageReference('/apex/RSSFormView?id=' + RSSForm.id);
        pg.setRedirect(true);
        return  pg;
    }       

    //Read Responses from offlineRSS Upload
    // Move the responses to the newest template.
    public void getResponsesFromJSON(JSONParser parser) 
    {
        ListRSSForm forms;
        List<RSSFormC> OfflineUpdateList = new List<RSSFormC>();
        Set<String> OfflineInsertList = new Set<String>();
        Set<String> OfflineUpdateFormIds = new Set<String>();
        List<RSS_Form__c> RSSFormInsertList = new List<RSS_Form__c>();
        //Map RSSForm and its ID
        Map<String,RSS_Form__c> MapRSSForm = new Map<String,RSS_Form__c>();
        //Map SurveyTaker(uniqueName -ProductForm(Inner Class for reading JSON)) and Set of Resposes 
        Map<String,List<SurveyQuestionResponse__c>>  MapresponseInsertList = new Map<String,List<SurveyQuestionResponse__c>>();
        //Map SurveyTaker(uniqueName -ProductForm) and SurveyTaker Object
        Map<String,List<SurveyTaker__c>>  MapSurveyTakerRSSForm = new Map<String,List<SurveyTaker__c>>();
        //ditto but containst only SurvyeTaker objects for insert
        Map<String,SurveyTaker__c> MapSurveyTakerInsertList = new Map<String,SurveyTaker__c>();
        //RSSForm Insert List
        Map<String,RSS_Form__c>  MapRSSFormInsertList = new Map<String,RSS_Form__c>();
        List<SurveyQuestionResponse__c>  OfflineResponses;
        //Mapping Question Unique Id with response - to carry over the responses from older templates to the new one
        Map<String,SurveyQuestionResponse__c> MapOfflineResponses = new Map<String,SurveyQuestionResponse__c>();
        Map<String,String> MapTemplateUniqueName = new Map<String,String>();
        List<String> TemplateUniqueNameList = new List<String>();
        Map<String,SurveyQuestionResponse__c> MapUniqQuestionIdResponse = new Map<String,SurveyQuestionResponse__c>();
        while (parser.nextToken() != null) 
        {
            if (parser.getCurrentToken()== JSONToken.START_OBJECT)
            {
                    forms = (ListRSSForm)parser.readValueAs(ListRSSForm.class);
            }
        }
        RSS_Form__c TobeInsertedForm;
        SurveyTaker__c tempProductForm;
        for(RSSFormC f:forms.RSSForms)
        {     
            if(!f.RSSFormId.contains('New'))
            {
                OfflineUpdateList.add(f);
                OfflineUpdateFormIds.add(f.RSSFormId);
                for(ProductForm rpf:f.RSSProductForms)
                {
                    if(String.isBlank(rpf.RSSProductFormId))
                    {
                        tempProductForm = new SurveyTaker__c();
                        tempProductForm.RSS_Form__c = f.RSSFormId;
                        tempProductForm.Survey__c = rpf.RSSTemplateId;
                        MapSurveyTakerInsertList.put(rpf.UniqueName,tempProductForm);
                        MapresponseInsertList.put(rpf.UniqueName,new List<SurveyQuestionResponse__c>());
                        //THe UniqueName of the Tesmplate which is needed to be queried to get the Latest questions
                        TemplateUniqueNameList.add(rpf.RSSTemplateUniqueName);
                        //Map of the Unique Name of template and the SurveyTaker which is to be inserted.
                        MapTemplateUniqueName.put(rpf.RSSTemplateUniqueName,rpf.UniqueName);
                    }
                }
            }
            else
            {
                OfflineInsertList.add(f.UniqueName);
                TobeInsertedForm = new RSS_Form__c();
                TobeInsertedForm.Id=null;
                TobeInsertedForm.UniqueName__c = GuidUtil.NewGuid();
                TobeInsertedForm.Name = f.RSSFormName;
                //Changes by Sharath for Leap: Setting the Leapform field to true
                TobeInsertedForm.Leap_Form__c = true;
                //Changes by Sharath: Setting the creeated date field
                TobeInsertedForm.Created_Date__c = Date.today();
                RSSFormInsertList.add(TobeInsertedForm);
                MapRSSForm.put(f.UniqueName,TobeInsertedForm);
                MapSurveyTakerRSSForm.put(f.UniqueName,new List<SurveyTaker__c>());
                for(ProductForm rpf:f.RSSProductForms)
                {
                    TemplateUniqueNameList.add(rpf.RSSTemplateUniqueName);
                    MapTemplateUniqueName.put(rpf.RSSTemplateUniqueName,rpf.UniqueName);
                    tempProductForm = new SurveyTaker__c();
                    //tempProductForm.Survey__c = rpf.RSSTemplateId;
                    MapSurveyTakerRSSForm.get(f.UniqueName).add(tempProductForm);
                    MapSurveyTakerInsertList.put(rpf.UniqueName,tempProductForm);
                    MapresponseInsertList.put(rpf.UniqueName,new List<SurveyQuestionResponse__c>());
                }
            }       
        }
        
        //MapUniqQuestionIdResponse We Query for all the questions and create responses for them to be inserted
        SurveyQuestionResponse__c toBeInsertedResponse;
        for(Survey_Question__c sq: [select id,UniqueName__c,Survey__r.UniqueName__c,Survey__c from Survey_Question__c where 
                                                     Survey__r.UniqueName__c =:TemplateUniqueNameList and Survey__r.RSS_Published__c = true])
        {
            toBeInsertedResponse = new SurveyQuestionResponse__c();
            toBeInsertedResponse.Survey_Question__c = sq.Id;
            toBeInsertedResponse.Response__c = '';
            //Map of RSS template UniqueName(database ) and the ProductFOrm UniqueName(inner class created for readingJSON)
            MapresponseInsertList.get(MapTemplateUniqueName.get(sq.Survey__r.UniqueName__c)).add(toBeInsertedResponse);
            //Map Unique Question Name and the response to be inserted
            MapUniqQuestionIdResponse.put(sq.UniqueName__c,toBeInsertedResponse);

            MapSurveyTakerInsertList.get(MapTemplateUniqueName.get(sq.Survey__r.UniqueName__c)).Survey__c = sq.Survey__c;
        }
         
        if(OfflineUpdateFormIds.size()>0||OfflineInsertList.size()>0)
        {
            OfflineResponses = [select id,Response__c from SurveyQuestionResponse__c where SurveyTaker__r.RSS_Form__r.id in :OfflineUpdateFormIds];
            for(SurveyQuestionResponse__c sqr:OfflineResponses)
            {
                MapOfflineResponses.put(sqr.id,sqr);
            }
             
             /*RSSForm = [select id, Name, AEName__c,Version__c, Published__c, Products__c, Locked__c,UniqueName__c, DigitalProperty__c,Account__c from RSS_Form__c where id=:form.RSSFormId limit 1];
             RSSForm.Name= form.RSSFormName;
            // RSSForm.AEName__c = form.RSSFormAEName;
             RSSForm.DigitalProperty__c = form.RSSFormDigitalProperty;
             GenerateForm();
             SurveyQuestionResponse__c tempResponse;*/
             //ToDO:
             
             for(RSSFormc rfc:forms.RSSForms)
             {
                 if(OfflineInsertList.contains(rfc.UniqueName))
                 {
                     system.debug('$$$$ inside insert' + rfc.RSSFormName);
                     
                     system.debug('$$$$ inside insert' + rfc.UniqueName);
                 }
                 for(ProductForm rpf:rfc.RSSProductForms)
                 {
                     
                     if(OfflineInsertList.contains(rfc.UniqueName))
                     {
                         
                     }
                     
                     if(rpf.RSSQuestionGroup!=null)
                     for(RSSQuestionGroup rqg:rpf.RSSQuestionGroup)
                     {
                         if(rqg.Responses!=null)
                         for(RSSResponse res:rqg.Responses)
                         {
                             if(OfflineUpdateFormIds.contains(rfc.RSSFormId))
                             {
                                if(MapOfflineResponses.get(res.Id)!=null)
                                {
                                String TempString = res.Answer;
                                if(String.isNotBlank(TempString))
                                {
                                TempString = res.Answer.replace('â€“','–');
                                }
                                MapOfflineResponses.get(res.Id).Response__c = TempString;
                                }
                                else
                                { 
                                    if(String.isBlank(rpf.RSSProductFormId))
                                    {
                                        toBeInsertedResponse = MapUniqQuestionIdResponse.get(res.QuestionUniqueName);
                                        String TempString = res.Answer;
                                        if(String.isNotBlank(TempString))
                                        {
                                        TempString = res.Answer.replace('â€“','–');
                                        }
                                        toBeInsertedResponse.Response__c = TempString;
                                    }
                                }    
                             }
                             else
                             {
                                 toBeInsertedResponse = MapUniqQuestionIdResponse.get(res.QuestionUniqueName);
                                 String TempString = res.Answer;
                                 if(String.isNotBlank(TempString))
                                 {
                                     TempString = res.Answer.replace('â€“','–');
                                 }
                                 toBeInsertedResponse.Response__c = TempString;
                             }
                         }
                     }
                 }
             }
             try
             {
                 system.debug('$$$$ debug' + MapSurveyTakerRSSForm.values());
                 system.debug('$$$$ debug RSSFOrm Before Insert' + RSSFormInsertList);
                 update MapOfflineResponses.values();
                 insert RSSFormInsertList;
                 system.debug('$$$$ debug RSSFOrm After Insert' + RSSFormInsertList);

                 for(string rf: MapSurveyTakerRSSForm.keySet())
                 {
                     for(SurveyTaker__c pst:MapSurveyTakerRSSForm.get(rf))
                     {
                         pst.RSS_Form__c = MapRSSForm.get(rf).id;
                     }
                 }
                 insert MapSurveyTakerInsertList.values();
                 List<SurveyQuestionResponse__c> insertResponseList = new List<SurveyQuestionResponse__c>();
                 for(String rfp: MapresponseInsertList.keySet())
                 {
                     for(SurveyQuestionResponse__c sqr:MapresponseInsertList.get(rfp))
                     {
                         sqr.SurveyTaker__c = MapSurveyTakerInsertList.get(rfp).id;  
                         insertResponseList.add(sqr);
                     }
                 }
                 insert insertResponseList;
                 List<String> tempString = new List<String>();
                 OfflineInsertIds = new List<RSS_Form__c>();
                 for(RSSFormC rf:OfflineUpdateList)
                 {
                     tempString.add(rf.RSSFormId);
                 }
                 for(RSS_Form__c rf:RSSFormInsertList)
                 {
                     OfflineInsertIds.add(rf);
                 }
                 OfflineUpdateIds = new List<RSS_Form__c>();
                 OfflineUpdateIds = [select id,Name from RSS_Form__c where id in :tempString];
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, ' The Offline Forms have been updated'));
                 OfflineOperationDone = true;   
             }
             catch(Exception ex)
             {
                 //system.debug('$$$$ exception at 420 : ' + ex);
                 Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '$$$$ exception at 420 : ' + ex));
             }
        }    
    }

     //Generate the Offline Form
    public String getJSON()
    {
         
        PageReference pr = new PageReference('/resource/jquery119/jquery-ui-1.10.2.custom/erSSOffline.html');
         // String htmlpart = '<html><head><script> var localStorageName = "' + RSSFormId + Datetime.now().getTime() +'"; var erssFile = '+ RSSUtility.createJSON(RSSFormId) + ';';
          List<String> tempList  = new List<String>();
          List<String> uf ;
          try
          {
              uf = UserForms.substring(1,UserForms.length()-1).split(',',0);
          }
          catch(Exception e)
          {
              uf = new List<String>();
          }
          if(uf.size()>0 && UserForms.trim()!='[]')
          {
          for(String st:uf)
          {
              tempList.add(st.trim());
          }

          String htmlpart = '<html><head><script> var RSSTemplates = '+ RSSUtility.createJSONForOfflineUse() + ';' + 'var OfflineRSSForms = ' + RSSUtility.RSSFormJSONS(tempList) + '; ';
          try
          {
          Blob content = pr.getContent();
          String eRSSOfflineHTML = htmlpart + content.toString();
          //Start of changes by shprasan: Removing the create form option in the offline html
          if (PostSales)
          {
              String RemoveCreateForPostSales = '<button class="FormButtons" value="Create New" onclick="$(\'#NewFormdiv\').dialog(\'open\');return false;"> Create New</button>';
              return eRSSOfflineHTML.remove(RemoveCreateForPostSales);            
          }
          //End of changes by shprasant
          return eRSSOfflineHTML;
          }
          catch(Exception e)
          {
          }
          }
          
          return null;
     }

     //Upload the file generated from offline Form.
      public PageReference upload() 
      {
        system.debug(attachment);
        try{
        getResponsesFromJSON(JSON.createParser(attachment.body.toString()));
        //system.assert(1==2);
        }catch(NullPointerException ne)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check if you have uploaded the right file and try again'));
        }
        catch(Exception ex)
        {
            if(ex.getMessage().contains('errorUnexpected character'))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect file format, please upload the correct file'));
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect file format, please upload the correct file'));
            }
            
        }
        //getResponsesFromJSON(JSON.createParser(RSSUtility.createJSON(RSSId)));
        return null;
      }

      public void TempMethod()
      {

          if(UserForms.trim()=='[]')
          {
                Offline = false;
          }
          else
          {
                Offline = true;
          }
      }

      public Boolean Offline {get{if(Offline==null) {Offline = false;} return Offline;}set;}
      public String UserForms {get;set;}
      
      //Start of changes by shprasan: Changed the select query in the function. all the open forms of presales and postsales can be downloaded to work offline
      public List<SelectOption> OfflineRSSForms 
      {
        get
        {
            if(OfflineRSSForms==null) 
            {
                OfflineRSSForms = new List<SelectOption>();
                //Start of changes by shprasan: 
                List<RSS_Form__c> openForms = new List<RSS_Form__c>();
                if (PreSales)
                {
                    openForms = [select id,Name from RSS_Form__c where soft_delete__c = false and Submit_Locked__c = false and Submitted__c = false and OwnerId = :UserInfo.getUserId() ];
                }
                else if (PostSales)
                {
                    openForms = [select id,Name from RSS_Form__c where soft_delete__c = false and Submitted__c = true and Locked__c = false and Published__c = false and (OwnerId = :UserInfo.getUserId() or LastModifiedById = :UserInfo.getUserId())];
                }
                //Changing the for loop
                for(RSS_Form__c rf : openForms)
                {
                     OfflineRSSForms.add(new SelectOption(rf.id,rf.Name));
                }
                }
                return OfflineRSSForms;
        }
        set;
    }
            
    //  Class Struture to read from JSON
    public class ListRSSForm 
    {
        List<RSSFormC> RSSForms;
        public ListRSSForm(List<RSSFormC> tempList)
        {
            RSSForms = tempList.clone();
        }
    }

    public class RSSFormC
    {
        Public String RSSFormName;
        Public String RSSFormId;
        Public Integer RSSFormVersion;
        Public String RSSFormUniqueName;
        Public String RSSFormAEName;
        Public String RSSFormDigitalProperty;
        Public String RSSFormCustomerName;
        Public String RSSFormCustomerid;

        public string  UniqueName 
        { 
            get
            { 
                if(UniqueName==null) 
                { 
                    UniqueName = GuidUtil.NewGuid();
                } 
                return UniqueName; 
            }
            set;
        }
    
        List<ProductForm> RSSProductForms;
        public RSSFormC(String name,String Id,String UniqueName,String AEName,String DigitalProperty,Integer Version,String CustomerName, String Account, List<ProductForm> ProductForms,String uname)
        {
            RSSFormName= name;
            RSSFormId= id;
            RSSFormVersion = Version;
            RSSFormUniqueName =UniqueName;
            RSSFormAEName =AEName;
            RSSFormDigitalProperty =DigitalProperty;
            RSSFormCustomerName = CustomerName;
            RSSFormCustomerid = Account;
            RSSProductForms = productForms.clone();
            //UniqueName =GuidUtil.NewGuid();
        }
    }

    public class ProductForm
    {
        public string RSSProductFormName;
        public string RSSTemplateId;
        public string RSSProductFormId;
        public string RSSTemplateUniqueName;
        public string  UniqueName { get{ if(UniqueName==null) { UniqueName =GuidUtil.NewGuid();} return UniqueName; }set;}
        public List<RSSQuestionGroup> RSSQuestionGroup;

        public ProductForm(string name,String TemplateId,String FormId,List<RSSQuestionGroup> groups)
        {
                
                RSSProductFormName=name;
                RSSTemplateId = TemplateId;
                RSSProductFormId = FormId;
                //UniqueName = GuidUtil.NewGuid();
                RSSQuestionGroup=groups.clone();

        }
    }

    public class RSSQuestionGroup
    {
         public string RSSQuestionGroupName;
         public Integer RSSQuestionGroupOrderNumber;   
         public List<RSSResponse> Responses;
         public RSSQuestionGroup(string name,Integer orderNumber,List<RSSResponse> res)
         {
                RSSQuestionGroupName = name;
                RSSQuestionGroupOrderNumber = orderNumber;
                Responses = res.clone();
         }
    }
    
    public class RSSResponse
    {
        public string Id;
        public string Question;
        public string QuestionId;
        public string QuestionUniqueName;
        public Integer OrderNumber;
        public string Type;
        public string Choices;
        public string Answer;
    }

    public PageReference uploadAttachment() 
    {
        attachment.OwnerId = UserInfo.getUserId();
        attachment.ParentId = RSSFormId; // the record the file is attached to
        attachment.IsPrivate = false;
        try 
        {
          insert attachment;
          RefreshAttachments = TRUE;
        } 
        catch (DMLException e) 
        {
          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment'));
          return null;
        } 
        finally 
        {
          attachment = new Attachment(); 
        }

        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
        return null;
    }
    
    public List<Attachment> displayAttachments()
    {
        List<Attachment> attachmentList = [Select Id, Name From Attachment where ParentId = :RSSFormId];
        return attachmentList;
    }
}