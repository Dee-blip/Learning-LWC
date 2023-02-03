public class RSSEditTemplateController 
{
    public String surveyRef {get;set;}
    public Survey__c RSSTemplate {get;set;}
    public List<Survey_Question__c> DeleteQuestions {get;set;}
    public Boolean WriteAccessOfUser{get {if(WriteAccessOfUser==null){
        WriteAccessOfUser = RSSUtility.TemplateWriteAccess(UserInfo.getUserId()); } return WriteAccessOfUser;} set; }
    public Survey_Question__c qQuestion {get; set;}
    public List<RSSSurveyQuestion> SurveyQuestions;
    public String questionReference{get;set;}
    public RSSSurveyQuestion NewQuestion {get;set;}
    public String questionType {get; set;}
    public List<SelectOption> questionTypeOptions {get; set;}
    public String RSSFormName {get; set;}
    public List< Survey_Question_Group__c > questionGroups {get; set;}
    public List<RSSQuestionGroupWrapper> questionGroupWrappers {get;set;}
    public List<Survey_Question_Group__c> DeletequestionGroupWrappers {get;set;}
    public List<SelectOption> QuestionGroupChoices {get; set;}
    public Survey_Question_Group__c questionGroup {get; set;}
    public String questionGroupName {get; set;}
    public String NewGroupname {get;set;}
    public Boolean RequiredQuestion {get;set;}
    public String EditQuestionUniqueGroupName {get; set;}
    public String DeleteQuestionUniqueGroupName {get; set;}
    public String UpdateQuestionGroupName {get; set;} 
    public String DeleteQuestionGroupName {get; set;} 
    public String EditQuestionGroupUniqueName {get;set;}
    public String EditQuestionUniqueName {get;set;}
    public Boolean Disabled {get;set;}
    public Boolean RSSTemplateEditMode {get;set;}
    public SurveyTaker__c NewRSSForm{get;set;}
    public Boolean KeepSaving {get{if(KeepSaving==null){KeepSaving=true;}return KeepSaving;}set;}
    String surveyId;
    public Integer QuestionGroupSize
    {
        get 
        {
            Integer c =0;
            if(questionGroupWrappers!=null)
            for(RSSQuestionGroupWrapper rqw1:questionGroupWrappers)
            {
               // c = c+ rgw1.QuestionCount;
                c++;
            }
            return c;
        }
    }
    
    public Integer QuestionSize 
    { 
        get 
        {
            Integer c =0;
            if(questionGroupWrappers!=null)
            for(RSSQuestionGroupWrapper rqw1:questionGroupWrappers)
            {
               // c = c+ rgw1.QuestionCount;
                    
                if(rqw1.surveyQuestions!=null)
                for(RSSSurveyQuestion rsq:rqw1.surveyQuestions)
                {
                    c++;
                }
                
            }
            return c;
        }
    }


//------------------------------------- CLASS METHODS -------------------------------------

    public RSSEditTemplateController(ApexPages.StandardController controller) 
    {
        /**/
        // Get url parameters - id
        // ReportFinderUtil rfu = new ReportFinderUtil();
        // reportId = rfu.findReportId('Survey with Questions and Responses');
        NewRSSForm = new SurveyTaker__c();    
        surveyId = Apexpages.currentPage().getParameters().get('id');
        qQuestion  = new Survey_Question__c();
        NewQuestion = new RSSSurveyQuestion();
        setupQuestionTypeOptions();
        surveyRef = surveyId;
        RSSTemplate = new Survey__c();
        for(Survey__c s:[select name,Locked__c, AKAM_Survey_ID__c,Id, RSS_Published__c,RecordTypeId,UniqueName__c,Submit_Response__c,Version__c from Survey__c where Id =:surveyId])
        {
            RSSTemplate.name=s.name;
            RSSTemplate.RecordTypeId=s.RecordTypeId;
            RSStemplate.UniqueName__c=s.UniqueName__c;
            RSStemplate.Submit_Response__c=s.Submit_Response__c;
            RSSTemplate.Version__c =s.Version__c;
            RSSTemplate.RSS_Published__c = s.RSS_Published__c;
            RSSTemplate.Locked__c = s.Locked__c;
            RSSTemplate.AKAM_Survey_ID__c = s.AKAM_Survey_ID__c;
            RSSTemplate.Id = s.Id;
        }
        if(RSSTemplate.RSS_Published__c!=true && RSSTemplate.Locked__c != true )
        {
            Disabled = false;
        }
        else
        {
            Disabled = true;
        }
        if(!WriteAccessOfUser)
        {
            Disabled = true;
        }
        DeleteQuestionUniqueGroupName = '';
        //The List for the groups which needs to be deleted
        DeletequestionGroupWrappers = new List<Survey_Question_Group__c>();
        setupQuestionGroupsAndQuestions();
        //The list for the questions which needs to be deleted
        DeleteQuestions = new List< Survey_Question__c >();
        setupQuestionGroupSelectOptions();
        questionGroup = new Survey_Question_Group__c();
    }
    
    public void setupQuestionGroupsAndQuestions()
    {
        questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :surveyId order by Order_Number__c];
        questionGroupWrappers = new List<RSSQuestionGroupWrapper>();
        if(questionGroups == null || questionGroups.size() == 0)
        {
            // questionGroupWrappers.add(new RSSQuestionGroupWrapper(questionGroups[0]));
        }

    // cookie - added Category__c
        else
        {
            List<Survey_Question__c> tempQuestions = [Select s.Type__c, s.QuestionDescription__c,s.Akam_Survey_Question_ID__c, s.Id, s.Survey__c, s.Required__c, s.Question__c,
                        s.OrderNumber__c, s.Name, s.Choices__c, s.Survey_Question_Group__c, Category__c
                        From Survey_Question__c s
                        WHERE s.Survey__c =: surveyId and s.Survey_Question_Group__c in :QuestionGroups ORDER BY s.Survey_Question_Group__r.Order_Number__c, s.OrderNumber__c];
            Map<Id,List<RSSSurveyQuestion>> tempMap = new Map<Id,List<RSSSurveyQuestion>>();
            for(Survey_Question__c q:tempQuestions)
            {
                if(tempMap.get(q.Survey_Question_Group__c)==null)
                {
                    tempMap.put(q.Survey_Question_Group__c,new List<RSSSurveyQuestion>());
                }
                tempMap.get(q.Survey_Question_Group__c).add(new RSSSurveyQuestion(q));
            }
            for(Survey_Question_Group__c sqg:QuestionGroups)
            {
                RSSQuestionGroupWrapper toBeAdded = new RSSQuestionGroupWrapper(sqg);
                tobeAdded.surveyQuestions = tempMap.get(sqg.Id);
                if(tobeAdded.surveyQuestions == null)
                {
                    tobeAdded.surveyQuestions = new List<RSSSurveyQuestion>();
                }
                questionGroupWrappers.add(toBeAdded);
            }
        }
    }


    //In the Add Questions UI, set up the Picklist to select the section to add the questions to.
    private void setupQuestionGroupSelectOptions()
    {
        QuestionGroupChoices = new List<SelectOption>();
        for(RSSQuestionGroupWrapper qg:questionGroupWrappers)
        {
            QuestionGroupChoices.add(new SelectOption(qg.UniqueName,qg.questionGroup.Name));
        }
    }


    //Setup Question type options by getting the pick-list values.
    private void setupQuestionTypeOptions()
    {
        //get picklist values
        Schema.DescribeFieldResult fieldResult = Survey_Question__c.Type__c.getDescribe();
        List<Schema.PicklistEntry>  ple = fieldResult.getPicklistValues();
        //set/add them to selectOption list
        questionTypeOptions = new List<SelectOption>();
        questionTypeOptions.add(new SelectOption('--SELECT--','--SELECT--'));
        for(Schema.PicklistEntry pe: ple)
        {
            questionTypeOptions.add(new SelectOption(pe.getLabel(), pe.getValue()));
        }
    }

    public Integer getSizeOfQuestionWrapper()
    {
        return questionGroupWrappers.size();
    }

    //Create new QuestionGroup.
    public void createNewQuestionGroup()
    {
        if(String.isNotBlank(NewGroupname))
        {            
        Survey_Question_Group__c sqg = new Survey_Question_Group__c();
        sqg.Name = NewGroupname ;
        sqg.Order_Number__c = questionGroups.size();
        sqg.Survey__c = surveyRef;
        questionGroups.add(sqg);
        questionGroupWrappers.add(new RSSQuestionGroupWrapper(sqg));
        setupQuestionGroupSelectOptions();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Name cannot be empty'));
        }
        resetViews();
    }

    //Add question to a question group (section).
    public void addQuestionToQuestionGroup(Survey_Question__c ques,String GroupName)
    {
        for(RSSQuestionGroupWrapper qgw:QuestionGroupWrappers)
        {
           if(qgw.UniqueName == GroupName)
           {
               qgw.surveyQuestions.add(new RSSSurveyQuestion(ques));
                       system.debug('$$$$$$$$$ done added : ');
           }
        }
    }

    //Create new question
    public void createNewQuestion()
    {
        if(String.isNotEmpty(qQuestion.Question__c) &&(questionType == 'Free Text' || String.isNotEmpty(qQuestion.Choices__c)))
        {
            Survey_Question__c newCreatedQuestion = new Survey_Question__c();
            newCreatedQuestion.Survey__c = surveyRef;
            newCreatedQuestion.Name = questionToName(qQuestion.Question__c);
            newCreatedQuestion.Choices__c = qQuestion.Choices__c;
            newCreatedQuestion.Required__c = qQuestion.Required__c;
            newCreatedQuestion.Type__c = questionType;
            newCreatedQuestion.UniqueName__c = GuidUtil.NewGuid();
        // cookie - Category__c
            newCreatedQuestion.Category__c = qQuestion.Category__c;
            for(RSSQuestionGroupWrapper qgw:QuestionGroupWrappers)
            {
                if(qgw.UniqueName==questionGroupName)
                {
                    newCreatedQuestion.OrderNumber__c = qgw.surveyQuestions.size();
                    break;
                }
            }

            newCreatedQuestion.Question__c = qQuestion.Question__c;  
            newCreatedQuestion.QuestionDescription__c =  qQuestion.QuestionDescription__c;    
            system.debug('NewQuestion+ ' + newCreatedQuestion);
            //RSSQuestions.add(newCreatedQuestion);
            addQuestionToQuestionGroup(newCreatedQuestion,questionGroupName);
            system.debug('$$$$$$$$$ newQuestion : ' + newCreatedQuestion + '   GroupName  :' +  questionGroupName);
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Required Fields cannot be empty'));
        }
        resetViews();  
    }

    //update questiongroup
    public void updateQuestionGroup()
    {
        if(String.isNotBlank(NewGroupname))
        {
            Integer count = 0;
            RSSQuestionGroupWrapper tempQW;
            for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
            {
                if(sq.UniqueName  == EditQuestionGroupUniqueName)
                {    
                    sq.questionGroup.Name = NewGroupname;
                    tempQW = QuestionGroupWrappers.Remove(count);
                    if(QuestionGroupWrappers.size()!=tempQW.questionGroup.Order_Number__c)
                        QuestionGroupWrappers.add(Integer.ValueOf(tempQW.questionGroup.Order_Number__c),tempQW);
                    else
                    {
                        QuestionGroupWrappers.add(tempQW);
                    }
                    break;
                }
                count++;
            }
            setupQuestionGroupSelectOptions();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Name cannot be empty'));
        }
        resetViews();
    }


    //update question
    public void updateQuestion()
    {
        System.debug('_____Inside updateQuestion___  :' + questionReference);
        if(String.isNotEmpty(qQuestion.Question__c) &&(questionType == 'Free Text' || String.isNotEmpty(qQuestion.Choices__c)))
        {
            Survey_Question__c tempQuestion ;
            RSSSurveyQuestion updatedQuestion ;
            Integer count = 0;
            for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
            {
                if(sq.UniqueName == EditQuestionUniqueGroupName)
                {
                    count = 0;
                    for(RSSSurveyQuestion s:sq.surveyQuestions)
                    {
                        if(s.UniqueName == EditQuestionUniqueName)
                        {
                            System.debug('_____Remove ' + count);
                            updatedQuestion = sq.surveyQuestions.remove(count);
                            System.debug('_____Question Removed' + count);
                            updatedQuestion.question.Name = questionToName(qQuestion.Question__c);
                            updatedQuestion.question.Choices__c = qQuestion.Choices__c;
                            updatedQuestion.question.Required__c = qQuestion.Required__c;
                            updatedQuestion.question.Type__c = questionType;

                            // cookie - Category__c
                            updatedQuestion.question.Category__c = qQuestion.Category__c;
                            updatedQuestion.question.OrderNumber__c = qQuestion.OrderNumber__c ;
                            updatedQuestion.question.Question__c = qQuestion.Question__c;
                            updatedQuestion.question.QuestionDescription__c = qQuestion.QuestionDescription__c; 
                            updatedQuestion.UpdateChoices();
                            break;
                        }
                        count++;
                    }
                    break;
                }
            }
            count = 0;
        
            // If the section for the question changes, add it to the newly selected section
            for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
            {
                if(sq.UniqueName == questionGroupName)
                {
                    if(questionGroupName == EditQuestionUniqueGroupName)
                    {
                        if(sq.surveyQuestions.size() == Integer.ValueOf(updatedQuestion.question.OrderNumber__c))
                        {
                            sq.surveyQuestions.add(updatedQuestion);
                        }  
                        else
                        {
                            sq.surveyQuestions.add(Integer.ValueOf(updatedQuestion.question.OrderNumber__c),updatedQuestion);
                        }                
                    }
                    else
                    {
                        sq.surveyQuestions.add(updatedQuestion);   
                    }
                    break;
                }
                count++;
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Required Fields cannot be empty'));
        }    
         resetViews();  
    }


    public void deleteQuestion()
    {
        Integer count = 0;
        for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
        {
            if(sq.UniqueName == EditQuestionUniqueGroupName)
            {
                count = 0;
                for(RSSSurveyQuestion s:sq.surveyQuestions)
                {
                    if(s.UniqueName == EditQuestionUniqueName)
                    {   
                        if(s.question.Id!=null)
                        {
                            DeleteQuestions.add(s.question);
                        }
                        sq.surveyQuestions.remove(count);             
                        break;
                    }
                    count++;
                }
                break;
            }
        }
        resetViews();  
    }


    public pageReference deleteQuestionGroup()
    {
        Integer countQ = 0;
        Integer count = 0;
        for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
        {
            if(sq.UniqueName == DeleteQuestionUniqueGroupName)
            {
                if(sq.surveyQuestions!=null)
                {
                    for(RSSSurveyQuestion s:sq.surveyQuestions)
                    {
                        if(s.question.Id!=null)
                        {
                            DeleteQuestions.add(s.question);
                        }              
                    }
                    if(sq.questionGroup.id!=null)
                    {
                        DeletequestionGroupWrappers.add(sq.questionGroup);
                    }
                    QuestionGroupWrappers.remove(Count);
                    if(questionGroups.size()<1)
                    {
                       // QuestionGroupSize = 0;
                    }
                    break;
                }
                /* if(sq.questionGroup.id!=null)
                {
                    DeletequestionGroupWrappers.add(sq.questionGroup);
                }
                QuestionGroupWrappers.remove(Count);
                if(questionGroups.size()<1)
                {
                   // QuestionGroupSize = 0;
                }
                break; */
            }
           count++;
        }
        resetViews();
        setupQuestionGroupSelectOptions();
        return null;        
    }


    //method which is called when save is clicked in the edit/add question popup.
    public void controllerSavQuestion()
    {
        System.debug('controllerSavQuestion: Save Entered + questionReference:' + questionReference);
        if(questionReference == null)
            createNewQuestion();
        else
            updateQuestion();
    }


    //method which is called when save is clicked in the edit/add question Group popup.
    public void controllerSavQuestionGroup()
    {
        System.debug('controllerSavQuestionGroup: Save Entered + questionGroupName:' + UpdateQuestionGroupName);
        if(UpdateQuestionGroupName == null)
            createNewQuestionGroup();
        else
            updateQuestionGroup();
    }


    public void resetViews()
    {
        questionReference =null;
        EditQuestionUniqueGroupName = null;
        UpdateQuestionGroupName = null;
        EditQuestionUniqueName = null;
        EditQuestionGroupUniqueName = null;
        DeleteQuestionUniqueGroupName = null;
        NewGroupname = null;
        RequiredQuestion = false;
        qQuestion = new Survey_Question__c();
        questionType='';
    }


    public pageReference EditRSSTemplateDetails()
    {
        RSSTemplateEditMode = true;
        return null;
    }


    public pageReference UpdateRSSTemplateDetails()
    {
        RSSTemplateEditMode = false;
        return null;
    }


    //setup the popup with the right question when edit is clicked next to a question
    public pageReference editQuestion()
    {
        if(questionReference!=null && EditQuestionUniqueGroupName!=null)
        {            
            Integer count = 0;
            for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
            {
                if(sq.UniqueName == EditQuestionUniqueGroupName)
                {
                    for(RSSSurveyQuestion s: sq.surveyQuestions)
                    {
                        if(s.UniqueName == EditQuestionUniqueName)
                        {
                            qQuestion = new Survey_Question__c ();
                            qQuestion.Name = s.question.Question__c;
                            qQuestion.Survey__c = surveyRef;
                            qQuestion.Choices__c =  s.question.Choices__c;
                            qQuestion.Required__c =  s.question.Required__c;
                            qQuestion.Type__c =  s.question.Type__c;

                            // cookie - Category__c
                            qQuestion.Category__c =  s.question.Category__c;
                            qQuestion.OrderNumber__c =  s.question.OrderNumber__c;
                            qQuestion.Question__c = s.question.Question__c;
                            qQuestion.AKAM_Survey_Question_ID__c = s.question.AKAM_Survey_Question_ID__c;
                            qQuestion.QuestionDescription__c = s.question.QuestionDescription__c;
                            questionGroupName =sq.UniqueName;
                            break;
                        }
                    }
                    break;
                }
                count++;
            }
            questionType=qQuestion.Type__c;
        }
        return null;
    }


    //setup the popup with the right question when edit is clicked next to a question
    public pageReference editQuestionGroup()
    {
        if(UpdateQuestionGroupName!=null)
        {
            Integer count = 0;        
            for(RSSQuestionGroupWrapper sq: QuestionGroupWrappers)
            {
               if(sq.UniqueName == EditQuestionGroupUniqueName)
               {
                    NewGroupname = UpdateQuestionGroupName;
                    break;
               }
            }
        }
        return null;
    }


    public Integer getLatestVersion(String Guid)
    {
        List<Survey__c> surveys = [select Version__c from Survey__c where UniqueName__c = :Guid order by Version__c desc NULLS LAST];
        
        if(surveys!=null && surveys.size() > 0)
        {
            return Integer.valueOf(surveys[0].Version__c) + 1;
        }
        return -1;
    }


    public void AutoSave()
    {
        Survey__c currentVersion = RSSTemplate;
        System.debug('___start Save');        
        try
        {   
            update currentVersion;
            Survey_Question_Group__c tempGroup;
            List<Survey_Question_Group__c> RSSQuestionGroupNextVersion = new List<Survey_Question_Group__c>();
            for(RSSQuestionGroupWrapper qgw:QuestionGroupWrappers)
            {
                 RSSQuestionGroupNextVersion.add(qgw.questionGroup);   
            }
            upsert RSSQuestionGroupNextVersion;
            Survey_Question__c tempQuestion;
            List<Survey_Question__c> RSSQuestionsNextVersion = new List<Survey_Question__c>();
            for(RSSQuestionGroupWrapper qgw:QuestionGroupWrappers)
            {
                if(qgw.surveyQuestions!=null)
                for(RSSSurveyQuestion rsq:qgw.surveyQuestions)
                {
                    if(rsq!=null)
                    {
                        rsq.question.Survey_Question_Group__c = qgw.questionGroup.Id;
                        RSSQuestionsNextVersion.add(rsq.question);
                    }
                }
            }
            upsert RSSQuestionsNextVersion ;
            
            System.debug('#### Ques1 ' + DeleteQuestions);
            System.debug('#### Groups1 ' + DeletequestionGroupWrappers);
            delete DeleteQuestions;
            DeleteQuestions.clear();
            System.debug('#### Ques2 ' + DeleteQuestions);
            System.debug('#### Groups2 ' + DeletequestionGroupWrappers);
            
            delete DeletequestionGroupWrappers;
            DeletequestionGroupWrappers.clear();
            System.debug('#### Ques3 ' + DeleteQuestions);
            System.debug('#### Groups3 ' + DeletequestionGroupWrappers);
            
            DeleteQuestions = new List<Survey_Question__c>();
            DeletequestionGroupWrappers = new List<Survey_Question_Group__c>();
            //system.assertEquals(QuestionGroupWrappers,null);
            InsertionSort(QuestionGroupWrappers);
            //setupQuestionGroupsAndQuestions();
            resetViews();
        }
        catch(Exception e)
        {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Coudn\'t Save' + e + e.getLineNumber()));
        }
    }


    public PageReference SaveTemplate()
    {
        AutoSave();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Save Successful'));
        resetViews();
        return null;
        /*
        Survey__c currentVersion = RSSTemplate;
        system.debug('___start Save');        

        /*if(currentVersion.Version__c!=null)
        {
        Integer latestVersion = getLatestVersion(s.UniqueName__c);
        if(latestVersion!=-1)
        {
        s.Version__c = latestVersion +1;
        }
        
        }
        else
        {
        s.Version__c=1;
        
        }*/
   //     try
    //    {
        /*List<Survey__c> OlderVersions = [select Id,Active_Template__c from Survey__c where UniqueName__c = :currentVersion.UniqueName__c order by Version__c desc];
        for(Survey__c ss:OlderVersions)
        {
            ss.Active_Template__c = false;
        }
        update OlderVersions;*/
        //updateOrderofQuestions();
/*         system.debug('___ before Save ' + QuestionGroupWrappers);
         
        update currentVersion;
                system.debug('___ updated Template');
        Survey_Question_Group__c tempGroup;
        List<Survey_Question_Group__c> RSSQuestionGroupNextVersion = new List<Survey_Question_Group__c>();
        for(RSSQuestionGroupWrapper qgw:QuestionGroupWrappers)
        {
             RSSQuestionGroupNextVersion.add(qgw.questionGroup);   
        }
        system.debug(RSSQuestionGroupNextVersion);
        upsert RSSQuestionGroupNextVersion;
                        system.debug('___ updated Groups ' + ' ' + RSSQuestionGroupNextVersion);
        Survey_Question__c tempQuestion;
        List<Survey_Question__c> RSSQuestionsNextVersion = new List<Survey_Question__c>();
                        system.debug('___ ' + QuestionGroupWrappers.size());
        for(RSSQuestionGroupWrapper qgw:QuestionGroupWrappers)
        {
                                    system.debug('___ ' + qgw.surveyQuestions);
            if(qgw.surveyQuestions!=null)
            for(RSSSurveyQuestion rsq:qgw.surveyQuestions)
            {
                if(rsq!=null)
                {
                    rsq.question.Survey_Question_Group__c = qgw.questionGroup.Id;
                    RSSQuestionsNextVersion.add(rsq.question);
                }
            }
                        system.debug('___ exit' + qgw);
        }
        system.debug('RSSQuestion Before Save: ' + RSSQuestionsNextVersion );
                              
        upsert RSSQuestionsNextVersion ;
                        system.debug('___ updated Questions');
        delete DeleteQuestions;
        delete DeletequestionGroupWrappers;
                        system.debug('___ deleted questions Groups');
          
        PageReference pg = new PageReference('/apex/RSSEditTemplate?id='+currentVersion.Id); 
        pg.setRedirect(true);
        return pg;

        system.debug('___ after Save ' + QuestionGroupWrappers);
// initFunc();
        setupQuestionGroupsAndQuestions();
        return null;
        }
        catch(Exception e)
        {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Coudn\'t Save'));
        }
        return null; */
    }
    
    
    public void StopSaving()
    {
        KeepSaving = false;
    }

    public void StartSaving()
    {
        KeepSaving = true;
    }
  
    public void clearFields()
    {
        qQuestion = new Survey_Question__c ();
    }


    //publish template
    public pageReference PublishTemplate()
    {
        Survey__c currentVersion;
        
        system.debug('####' + RSSTemplate.name);
        
        List<Survey__c> lSurveyList = [SELECT Id, Name, RSS_Published__c FROM Survey__c WHERE Name = :RSSTemplate.name AND UniqueName__c != :RSStemplate.UniqueName__c AND RSS_Published__c = true];
        system.debug('######33'+lSurveyList);
        
        if(lSurveyList.size()>0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Template with the same name already exists. Cannot publish this Template.'));
            return null;
        }
        
        for(Survey__c sur:[select name,Locked__c,RSS_Published__c,RecordTypeId,UniqueName__c,Submit_Response__c,Version__c from Survey__c where Id =:surveyRef])
        {
            currentVersion =sur;
        }
        List <Survey__c> OlderVersionTemplates = [select Id,name,Locked__c,RSS_Published__c,RecordTypeId,RecordType.Name,UniqueName__c,Submit_Response__c,Version__c from Survey__c WHERE UniqueName__c = :currentVersion.UniqueName__c and Id !=:surveyRef];
        for(Survey__c s:OlderVersionTemplates)
        {
            s.RSS_Published__c = false;
        }

        currentVersion.RSS_Published__c=true;
        currentVersion.Locked__c =true;
        currentVersion.Version__c =getLatestVersion(currentVersion.UniqueName__c);
        update currentVersion;
        update OlderVersionTemplates;
        PageReference pg = new PageReference('/apex/RSSEditTemplate?id=' +currentVersion.Id);
        pg.setRedirect(true);
        return pg;
    }


    public PageReference CreateNewVersion()
    {
        try
        {
            String NewTemplateId = RSSUtility.deepCloneNewTemplate(SurveyRef);
            PageReference NewPage = new PageReference('/apex/RSSEditTemplate?id=' + NewTemplateId);
            NewPage.setRedirect(true);
            return NewPage;
        }
        catch(Exception e)
        {
            return null;
        }
    }


    private String questionToName(String q)
    {
        if(q.length()<75)
            return q;
        else
            return q.substring(0, 75)+'...';
    }
 
  //  create new RSS using this template
  /*
    public PageReference CreateRSSFromTemplate()
    {
        if(surveyRef!=null)
        {
        List<Survey_Question__c> RSSquestions;
        SurveyTaker__c RSSForm = NewRSSForm;
        RSSForm.Survey__c = surveyRef;
        RSSForm.RSS_Unique_name__c = GuidUtil.NewGuid();
        RSSForm.Version__c =0;
        try
        {
    //Todo:
        /*RSS_Form_Header__c rssFormHeader = new RSS_Form_Header__c();
        
        insert rssFormHeader;
        RSSForm.RSS_Form_Header__c = rssFormHeader.id;*/
        /*
        insert RSSForm;
        RSSquestions =  [Select s.Type__c, s.AKAM_Survey_Question_ID__c, s.Id, s.Survey__c, s.Required__c, s.Question__c,
                    s.OrderNumber__c, s.Name, s.QuestionDescription__c, s.Choices__c, s.Survey_Question_Group__c
                    From Survey_Question__c s
                    WHERE s.Survey__c =: surveyRef  ORDER BY s.OrderNumber__c];
        List<SurveyQuestionResponse__c> RSSResponses= new List<SurveyQuestionResponse__c>();
        SurveyQuestionResponse__c response;
        for(Survey_Question__c q: RSSquestions)
        {
        response = new SurveyQuestionResponse__c();
        response.Survey_Question__c = q.id;
        response.SurveyTaker__c = RSSForm.Id;
        RSSResponses.add(response);
        }
        insert RSSResponses;
        
        return new PageReference('/apex/RSSForm?id=' +RSSForm.id);
        
        }
        catch(Exception e)
        {
        system.assertEquals(e,null);
        }
        }
        return null;
    }
   */
    public static void InsertionSort( List<RSSQuestionGroupWrapper> groups)
    {
        Integer j;                     // the number of items sorted so far
        RSSQuestionGroupWrapper key;                // the item to be inserted
        Integer i;  

        for (j = 1; j < groups.size(); j++)    // Start with 1 (not 0)
        {
            key = groups[ j ];
            for(i = j - 1; (i >= 0) && (groups[ i ].questionGroup.Order_Number__c > key.questionGroup.Order_Number__c); i--)   // Smaller values are moving up
            {
                groups[ i + 1 ] = groups[ i ];
            }
            groups[ i+1 ] = key;    // Put the key in its proper location
        }
        for (j = 0; j < groups.size(); j++)
        {
            InsertionSort(groups[j].surveyQuestions);
        }
    }


    public static void InsertionSort( List<RSSSurveyQuestion> questions)
    {
        Integer j;                     // the number of items sorted so far
        RSSSurveyQuestion key;                // the item to be inserted
        Integer i;  

        for (j = 1; j < questions.size(); j++)    // Start with 1 (not 0)
        {
            key = questions[ j ];
            for(i = j - 1; (i >= 0) && (questions[ i ].question.OrderNumber__c > key.question.OrderNumber__c); i--)   // Smaller values are moving up
            {
            questions[ i + 1 ] = questions[ i ];
            }
            questions[ i+1 ] = key;    // Put the key in its proper location
        }
    }

}