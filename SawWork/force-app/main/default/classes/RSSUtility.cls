global class RSSUtility 
{
    //Clone template given template Id
    public static String deepCloneNewTemplate(String TemplateId)
    {
        Survey__c NewTemplate;
        List< Survey_Question_Group__c > questionGroups;
        List< Survey_Question__c > questions;
        Survey_Question__c tempQuestion;
        Survey_Question_Group__c tempQuestionGroup;
        String rectype;
        Boolean Published;
        
        system.debug('____Entered Clone Function');
        NewTemplate = new Survey__c();
        for(Survey__c s: [select name,RSS_Published__c,RecordTypeId,RecordType.Name,UniqueName__c,Submit_Response__c,Version__c from Survey__c where Id =:TemplateId])
        {
            NewTemplate.name=s.name;
            NewTemplate.RecordTypeId=s.RecordTypeId;
            NewTemplate.UniqueName__c=s.UniqueName__c;
            NewTemplate.Submit_Response__c=s.Submit_Response__c;
            Published = s.RSS_Published__c;
            rectype = s.RecordType.Name;
        }
        if(rectype!='RSS Template')
        {
            return 'Can only clone surveys of recordType RSS Template';
        }
        
        NewTemplate.Version__c = null;
        insert NewTemplate;
        
        system.debug('____Created new Template' + NewTemplate);
        questionGroups = new List< Survey_Question_Group__c >();
        Map<Id,Survey_Question_Group__c> tempMap = new Map<Id,Survey_Question_Group__c>();
        for( Survey_Question_Group__c sqg :[select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :TemplateId order by Order_Number__c])
        {
            tempQuestionGroup = new Survey_Question_Group__c();
            tempQuestionGroup.name = sqg.Name;
            tempQuestionGroup.Survey__c = NewTemplate.Id;
            tempQuestionGroup.Order_Number__c = sqg.Order_Number__c;
            questionGroups.add(tempQuestionGroup);
            tempMap.put(sqg.Id,tempQuestionGroup);
        }
        system.debug('____questionGroups' + questionGroups);
        insert questionGroups;
        questions = new List <Survey_Question__c>();
        for(Survey_Question__c q: [Select s.Type__c, s.Required__c, s.Question__c,
                                   s.OrderNumber__c, s.QuestionDescription__c, s.Name,s.UniqueName__c, s.Choices__c, s.Survey_Question_Group__c, s.Category__c
                                   From Survey_Question__c s
                                   WHERE s.Survey__c =: TemplateId and s.Survey_Question_Group__c in :tempMap.keySet()ORDER BY s.Survey_Question_Group__r.Order_Number__c, s.OrderNumber__c])
        {
            tempQuestion = new Survey_Question__c();
            tempQuestion.Type__c = q.Type__c;
            tempQuestion.Name = q.Name;
            tempQuestion.Question__c = q.Question__c;
            tempQuestion.OrderNumber__c = q.OrderNumber__c;
            tempQuestion.Choices__c = q.Choices__c;
            tempQuestion.Survey_Question_Group__c = tempMap.get(q.Survey_Question_Group__c).Id;
            tempQuestion.Survey__c = NewTemplate.Id;
            tempQuestion.UniqueName__c = q.UniqueName__c;
            tempQuestion.Required__c = q.Required__c;
            tempQuestion.QuestionDescription__c = q.QuestionDescription__c;

            // cookie - Category__c
            tempQuestion.Category__c = q.Category__c;
            questions.add(tempQuestion);
        }
        insert questions;
        system.debug('____questions' + questions);
        return NewTemplate.Id;    
    }

    //get Next Version of the Template for versioning.
    public static Integer getNextVersionNumberForTemplate(String Guid)
    {
        List<Survey__c> surveys = [select Version__c from Survey__c where UniqueName__c = :Guid order by Version__c desc];
        
        if(surveys!=null && surveys.size() > 0)
        {
            system.debug(surveys[0]);
            return Integer.valueOf(surveys[0].Version__c) + 1;
            
        }
        return 0;
    }

    //get Next Version of the RSS Form for versioning.
    public static Integer getNextVersionNumberForRSSForm(String Guid)
    {
        List<RSS_Form__c> RSSForms= [select Version__c from RSS_Form__c where UniqueName__c= :Guid order by Version__c desc];
        if(RSSForms!=null && RSSForms.size() > 0)
        {
            return Integer.valueOf(RSSForms[0].Version__c) +1;
            
        }
        return 0;
    }

    //Clone RSS Form without responses/data
    public static string deepCloneRSSForm(String RSSFormId,List<String> Templates)
    {
        List<SurveyQuestionResponse__c> responses;
        RSS_Form__c RSSform;
        SurveyQuestionResponse__c tempResponse;
        List<SurveyTaker__c> Forms ;
        responses = new List<SurveyQuestionResponse__c>();
        RSSform = new RSS_Form__c();
        system.debug('___ before Assigning RSSForm');
        try
        {
            for(RSS_Form__c s:[select Name,Id, Version__c, UniqueName__c from RSS_Form__c where Id = :RSSFormId])
            {
                RSSForm.Name = s.Name;
                RSSForm.UniqueName__c = GuidUtil.NewGuid();
            }
            
            
            RSSForm.Version__c = 0;//getNextVersionNumberForRSSForm(RSSForm.RSS_Unique_Name__c);
            
            system.debug('___ before insert RSSForm');
            insert RSSForm;
            system.debug('___ after insert RSSForm');
            Forms = [select id,Survey__c from SurveyTaker__c where RSS_Form__c =:RSSFormid];
            List<SurveyTaker__c> insertList = new List<SurveyTaker__c>();
            List<RSSFormWrapper> RSSFormWrappers = new List<RSSFormWrapper>();
            List<SurveyQuestionResponse__c> RSSQuestionResponses = new List<SurveyQuestionResponse__c>();
            
            if(RSSFormId !=null && Templates != null)
            {
                
                //SurveyTaker,Responses
                Map<String,FormSetResponses> QuestionsTemplateMap = new Map<String,FormSetResponses>();
                for(Survey_Question__c sq:[Select  Id, Survey__c From Survey_Question__c  WHERE Survey__c =: Templates  ORDER BY OrderNumber__c])
                {
                    if(QuestionsTemplateMap.get(sq.Survey__c)==null)
                    {
                        FormSetResponses Fsr = new FormSetResponses();
                        insertList.add(Fsr.Form);
                        QuestionsTemplateMap.put(sq.Survey__c,Fsr);
                    }
                    FormSetResponses tempFSr = QuestionsTemplateMap.get(sq.Survey__c);
                    tempFSr.form.Survey__c = sq.Survey__c;
                    tempFSr.form.RSS_Form__c = RSSForm.Id;
                    SurveyQuestionResponse__c response = new SurveyQuestionResponse__c();
                    response.Survey_Question__c = sq.id;
                    tempFSr.responses.add(response);
                }
                
                insert insertList;
                for(FormSetResponses fsr:QuestionsTemplateMap.values())
                {
                    for(SurveyQuestionResponse__c sqr:fsr.responses)
                    {
                        sqr.SurveyTaker__c=fsr.form.id;
                        RSSQuestionResponses.add(sqr);
                    }
                }
                insert RSSQuestionResponses;
                return RSSForm.Id;
            }
        }
        catch(Exception e)
        {
            
        }
        return null;
        
    }

    //Clone RSS Form with data + Responses
    public static string deepCloneRSSFormWithResponses(String RSSFormId)
    {
        List<SurveyQuestionResponse__c> responses;
        
        RSS_Form__c RSSform;
        SurveyQuestionResponse__c tempResponse;
        List<SurveyTaker__c> Forms ;
        responses = new List<SurveyQuestionResponse__c>();
        RSSform = new RSS_Form__c();
        system.debug('___ before Assigning RSSForm');
        try
        {
            for(RSS_Form__c s:[select Name,Id,AEName__c, Version__c, UniqueName__c, Account__c, DigitalProperty__c from RSS_Form__c where Id = :RSSFormId])
            {
                RSSForm.Name = s.Name;
                RSSForm.UniqueName__c = s.UniqueName__c;
                RSSForm.Published__c = false;
                RSSForm.Locked__c = false;
                RSSForm.AEName__c = s.AEName__c;
                //  RSSForm.CustomerName__c = s.CustomerName__c;
                RSSFORM.DigitalProperty__c = s.DigitalProperty__c;
                RSSForm.Account__c = s.Account__c;
                //    RSSForm.GDRAT__c = s.GDRAT__c;
            }
            
            
            RSSForm.Version__c = null;
            
            system.debug('___ before insert RSSForm');
            insert RSSForm;
            system.debug('___ after insert RSSForm');
            Forms = [select id,Survey__c from SurveyTaker__c where RSS_Form__c =:RSSFormid order by Survey__r.Name];
            List<SurveyTaker__c> insertList = new List<SurveyTaker__c>();
            List<String> Templates = new List<String>();
            List<String> SruveyFormIds = new List<String>();
            for(SurveyTaker__c st:Forms)
            {
                SruveyFormIds.add(st.id);
                Templates.add(st.Survey__c);
                
            }
            List<RSSFormWrapper> RSSFormWrappers = new List<RSSFormWrapper>();
            List<SurveyQuestionResponse__c> RSSQuestionResponses = new List<SurveyQuestionResponse__c>();
            
            if(RSSFormId !=null && Templates != null)
            {
                
                //SurveyTaker,Responses
                Map<String,FormSetResponses> QuestionsTemplateMap = new Map<String,FormSetResponses>();
                for(SurveyQuestionResponse__c r : [select Id,Question__c, Response__c, SurveyTaker__c,Survey_Question__c,Survey_Question__r.Survey__c
                                                   from SurveyQuestionResponse__c where SurveyTaker__c = :SruveyFormIds
                                                   ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c])
                {
                    if(QuestionsTemplateMap.get(r.Survey_Question__r.Survey__c)==null)
                    {
                        FormSetResponses Fsr = new FormSetResponses();
                        insertList.add(Fsr.Form);
                        QuestionsTemplateMap.put(r.Survey_Question__r.Survey__c,Fsr);
                    }
                    FormSetResponses tempFSr = QuestionsTemplateMap.get(r.Survey_Question__r.Survey__c);
                    tempFSr.form.Survey__c =r.Survey_Question__r.Survey__c;
                    tempFSr.form.RSS_Form__c = RSSForm.Id;
                    SurveyQuestionResponse__c response = new SurveyQuestionResponse__c();
                    response.Survey_Question__c = r.Survey_Question__c;
                    response.response__c = r.response__c;
                    tempFSr.responses.add(response);
                }
                
                insert insertList;
                for(FormSetResponses fsr:QuestionsTemplateMap.values())
                {
                    for(SurveyQuestionResponse__c sqr:fsr.responses)
                    {
                        sqr.SurveyTaker__c=fsr.form.id;
                        RSSQuestionResponses.add(sqr);
                    }
                }
                insert RSSQuestionResponses;
                return RSSForm.Id;
            }
            return null;
        }
        catch(Exception e)
        {
            return e.getMessage() + '  Line Number  : ' + e.getLineNumber();
        }
    }
    
    //webservice Generate a JSON for a given RSS Form
    /*
    webservice static string createJSON( String RSSFormId)
    {
        ID RSSId;
        List<RSSResponseGroupWrapper> responseGroupWrappers ;
        List<Survey_Question_Group__c> questionGroups ;
        RSS_Form__c RSSform ;
        List<RSSQuestionResponse> surveyResponses ;
        List<RSSFormWrapper> RSSFormWrappers = new List<RSSFormWrapper>();
        
        try
        {
            RSSId = RSSFormId;
            responseGroupWrappers = new List<RSSResponseGroupWrapper>();
            for(RSS_Form__c s:[select id, Name, AEName__c, AEName__r.name, Version__c, Published__c, Locked__c,UniqueName__c, DigitalProperty__c,  Account__c, Account__r.name from RSS_Form__c where id=:RSSFormId limit 1])
            {
                RSSform = s;
            }
            RSSFormWrappers = new List<RSSFormWrapper>();
            Map<String,String> TemplateFormMap = new Map<String,String>();
            List<SurveyTaker__c> forms = [select id,Survey__r.Name,Survey__c from SurveyTaker__c where RSS_Form__c = :RSSFormId  order by Survey__r.Name];
            for(SurveyTaker__c st:forms)
            {
                TemplateFormMap.put(st.Survey__c,st.id);
                
                
            }
            questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :TemplateFormMap.keyset() order by Order_Number__c];
            //      Map<id,List<Survey_Question_Group__c>> FormQuestionGroupMap = new Map<id,List<Survey_Question_Group__c>>();
            Map<id,List<RSSResponseGroupWrapper>> FormGroupMap = new Map<id,List<RSSResponseGroupWrapper>>();
            if(questionGroups != null || questionGroups.size() != 0)
            {
                List<String> Formids = new List<String>();
                for(SurveyTaker__c st:forms)
                {
                    Formids.add(st.id);
                }
                List<SurveyQuestionResponse__c > tempResponses = [select Id,Question__c, Response__c, SurveyTaker__c,Survey_Question__c, Survey_Question__r.Question__c, Survey_Question__r.OrderNumber__c,
                                                                  Survey_Question__r.Type__c, Survey_Question__r.Choices__c,Survey_Question__r.QuestionDescription__c,Survey_Question__r.Survey_Question_Group__c from SurveyQuestionResponse__c where SurveyTaker__c in :Formids
                                                                  and Survey_Question__r.Survey_Question_Group__c in :questionGroups ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c];
                //QuestionGroup,Responses
                Map<Id,List<RSSQuestionResponse>> tempMap = new Map<Id,List<RSSQuestionResponse>>();
                for(SurveyQuestionResponse__c q:tempResponses)
                {
                    if(tempMap.get(q.Survey_Question__r.Survey_Question_Group__c)==null)
                    {
                        tempMap.put(q.Survey_Question__r.Survey_Question_Group__c,new List<RSSQuestionResponse>());
                    }
                    tempMap.get(q.Survey_Question__r.Survey_Question_Group__c).add(new RSSQuestionResponse(q));
                }
                
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
        }
        catch(Exception e)
        {
            system.assertEquals(e,null);
        }
        /*    gen.writeStringField('def', 'xyz');
         gen.writeFieldName('ghi');
         gen.writeStartObject();
         
         gen.writeObjectField('aaa', intlist);
         
         gen.writeEndObject();*/
    /*
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('RSSFormId', RSSFormId);
        gen.writeStringField('RSSFormName', RSSForm.Name);
        gen.writeNumberField('RSSFormVersion', RSSForm.Version__c);
        gen.writeStringField('RSSFormUniqueName', RSSForm.UniqueName__c);
        if(RSSForm.AEName__r.Name!=null)
            gen.writeStringField('RSSFormAEName', RSSForm.AEName__r.Name);
        if(RSSForm.DigitalProperty__c!=null)
            gen.writeStringField('RSSFormDigitalProperty', RSSForm.DigitalProperty__c);
        if(RSSForm.Account__c!=null)
            gen.writeStringField('RSSFormCustomerName', RSSForm.Account__r.Name);
        gen.writeStringField('RSSFormCustomerid', RSSForm.Account__c);
        gen.writeFieldName('RSSProductForms');
        gen.writeStartArray();
        
        for(RSSFormWrapper rfw:RSSFormWrappers)
        {
            gen.writeStartObject();
            gen.WriteStringField('RSSProductFormName', rfw.ProductForm.Survey__r.Name);
            gen.writeFieldName('RSSQuestionGroup');
            gen.writeStartArray();
            for(RSSResponseGroupWrapper rgw:rfw.responseGroupWrappers)
            {
                gen.writeStartObject();
                gen.writeStringField('RSSQuestionGroupName', rgw.QuestionGroup.Name);
                gen.writeNumberField('RSSQuestionGroupOrderNumber', rgw.QuestionGroup.Order_Number__c);
                if(rgw.surveyResponses!=null)
                {
                    
                    gen.writeFieldName('Responses');
                    gen.writeStartArray();
                    for(RSSQuestionResponse r:rgw.surveyResponses)
                    {
                        gen.writeStartObject();
                        if(r.response.Id!=null)
                            gen.writeStringField('Id', r.response.Id);
                        if(!String.isBlank(r.response.Survey_Question__r.Question__c))
                            gen.writeStringField('Question', r.response.Survey_Question__r.Question__c);
                        if(!String.isBlank(r.response.Survey_Question__c))
                            gen.writeStringField('QuestionId', r.response.Survey_Question__c);
                        if(!String.isBlank(r.response.Survey_Question__r.QuestionDescription__c))
                            gen.writeStringField('QuestionDescription', r.response.Survey_Question__r.QuestionDescription__c);
                        if(r.response.Survey_Question__r.OrderNumber__c!=null)
                            gen.writeNumberField('OrderNumber', r.response.Survey_Question__r.OrderNumber__c);
                        if(!String.isBlank(r.response.Survey_Question__r.type__c))
                            gen.writeStringField('Type', r.response.Survey_Question__r.type__c);
                        if(r.response.Survey_Question__r.type__c != 'Free Text')
                        {
                            if(!String.isBlank(r.response.Survey_Question__r.Choices__c))
                                gen.writeStringField('Choices', r.response.Survey_Question__r.Choices__c);
                        }
                        if(r.response.response__c!=null)
                        {
                            gen.writeStringField('Answer', r.response.response__c);
                        }
                        else
                        {
                            gen.writeStringField('Answer', '');
                        }
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                    
                }
                
                gen.writeEndObject();
            }
            
            gen.writeEndArray();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString();
        
    }*/

    webservice static string RSSFormJSONS( List<String> RSSFormIds)
    {
        ID RSSId;
        List<RSSResponseGroupWrapper> responseGroupWrappers ;
        List<Survey_Question_Group__c> questionGroups ;
        Map<String,RSS_Form__c> RSSforms = new Map<String,RSS_Form__c>();
        List<RSSQuestionResponse> surveyResponses ;
        List<RSSFormWrapper> RSSFormWrappers = new List<RSSFormWrapper>();
        Map<RSS_Form__c,List<RSSFormWrapper>> RSSFormsList = new Map<RSS_Form__c,List<RSSFormWrapper>>();
        
        try
        {
            responseGroupWrappers = new List<RSSResponseGroupWrapper>();
            for(RSS_Form__c s:[select id, Name, AEName__c, AEName__r.name, Version__c, Published__c, Locked__c,UniqueName__c, DigitalProperty__c,  Account__c, Account__r.name from RSS_Form__c where id in :RSSFormIds  ])
            {
                RSSforms.put(s.id,s);
            }
            RSSFormWrappers = new List<RSSFormWrapper>();
            Map<String,String> TemplateFormMap = new Map<String,String>();
            system.debug('$$$$ ' + RSSFormIds);
            List<SurveyTaker__c> forms = [select id,Survey__r.Name,Survey__c,Survey__r.Version__c,RSS_Form__c from SurveyTaker__c where RSS_Form__c in :RSSFormIds  order by Survey__r.Name];
            system.debug('$$$$ ' + forms);
            for(SurveyTaker__c st:forms)
            {
                TemplateFormMap.put(st.Survey__c,st.id);
                
                
            }
            questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :TemplateFormMap.keyset() order by Order_Number__c];
            Map<String,Survey_Question_Group__c> questionGroupMap =  new Map<String,Survey_Question_Group__c>();
            for(Survey_Question_Group__c g:questionGroups)
            {
                questionGroupMap.put(g.id,g);
            }
            
            //      Map<id,List<Survey_Question_Group__c>> FormQuestionGroupMap = new Map<id,List<Survey_Question_Group__c>>();
            Map<id,List<RSSResponseGroupWrapper>> FormGroupMap = new Map<id,List<RSSResponseGroupWrapper>>();
            if(questionGroups != null || questionGroups.size() != 0)
            {
                List<String> Formids = new List<String>();
                for(SurveyTaker__c st:forms)
                {
                    Formids.add(st.id);
                }
                List<SurveyQuestionResponse__c > tempResponses = [select Id,Question__c, Response__c, SurveyTaker__c,Survey_Question__c, Survey_Question__r.Question__c, Survey_Question__r.UniqueName__c, Survey_Question__r.OrderNumber__c,
                                                                  Survey_Question__r.Type__c,Survey_Question__r.Required__c, Survey_Question__r.Choices__c,Survey_Question__r.QuestionDescription__c,Survey_Question__r.Survey_Question_Group__c from SurveyQuestionResponse__c where SurveyTaker__c in :Formids
                                                                  and Survey_Question__r.Survey_Question_Group__c in :questionGroups ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c];
                Map<String,List<SurveyQuestionResponse__c>> responsesPerSurveyTakerMap = new Map<String,List<SurveyQuestionResponse__c>>();
                
                for(SurveyQuestionResponse__c q:tempResponses)
                {
                    if(responsesPerSurveyTakerMap.get(q.SurveyTaker__c)==null)
                    {
                        responsesPerSurveyTakerMap.put(q.SurveyTaker__c,new List<SurveyQuestionResponse__c>());
                    }
                    responsesPerSurveyTakerMap.get(q.SurveyTaker__c).add(q);
                }
                
                //QuestionGroup,Responses
                Map<Id,List<RSSQuestionResponse>> tempMap = new Map<Id,List<RSSQuestionResponse>>();
                List<RSSResponseGroupWrapper> RSSResponseGroupWrappers = new List<RSSResponseGroupWrapper>();
                for(String sur:responsesPerSurveyTakerMap.keySet())
                {
                    tempMap = new Map<Id,List<RSSQuestionResponse>>();
                    for(SurveyQuestionResponse__c q:responsesPerSurveyTakerMap.get(sur))
                    {
                        if(tempMap.get(q.Survey_Question__r.Survey_Question_Group__c)==null)
                        {
                            tempMap.put(q.Survey_Question__r.Survey_Question_Group__c,new List<RSSQuestionResponse>());
                        }
                        tempMap.get(q.Survey_Question__r.Survey_Question_Group__c).add(new RSSQuestionResponse(q));
                        
                    }
                    for(String g:tempMap.keySet())
                    {
                        RSSResponseGroupWrapper gw = new RSSResponseGroupWrapper(questionGroupMap.get(g));
                        gw.surveyResponses = tempMap.get(g);
                        if(gw.surveyResponses.size()>0)
                        {
                            gw.ProductFormId = gw.surveyResponses[0].response.SurveyTaker__c;
                            RSSResponseGroupWrappers.add(gw);
                        }
                    }
                }
                
                for(RSSResponseGroupWrapper srrgw:RSSResponseGroupWrappers)
                {
                    if(FormGroupMap.get(srrgw.ProductFormId) ==null)
                    {
                        FormGroupMap.put(srrgw.ProductFormId,new List<RSSResponseGroupWrapper>());
                    }
                    FormGroupMap.get(srrgw.ProductFormId).add(srrgw);
                }
                
                for(SurveyTaker__c st:forms)
                {
                    RSSFormWrapper toBeAdded = new RSSFormWrapper(st);
                    toBeAdded.responseGroupWrappers = FormGroupMap.get(st.id);
                    if(RSSFormsList.get(RSSforms.get(st.RSS_Form__c))==null)
                    {
                        RSSFormsList.put(RSSforms.get(st.RSS_Form__c),new List<RSSFormWrapper>());
                    }
                    RSSFormsList.get(RSSforms.get(st.RSS_Form__c)).add(toBeAdded);
                }
            }
        }
        catch(Exception e)
        {
            system.assertEquals(e,null);
        }
        /*    gen.writeStringField('def', 'xyz');
         gen.writeFieldName('ghi');
         gen.writeStartObject();
         
         gen.writeObjectField('aaa', intlist);
         
         gen.writeEndObject();*/
        system.debug('$$$$ String JSON Generation ' + RSSFormsList.keySet());
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('RSSForms');
        gen.writeStartArray();
        for(RSS_Form__c rf:RSSFormsList.keySet())
        {
            gen.writeStartObject();
            system.debug('$$$$ Inside a RSSForm ' + rf.Name);
            gen.writeStringField('RSSFormId', rf.id);
            gen.writeStringField('RSSFormName', rf.Name);
            if(rf.Version__c != null)
            gen.writeNumberField('RSSFormVersion', rf.Version__c);
            gen.writeStringField('RSSFormUniqueName', rf.UniqueName__c);
            if(rf.AEName__r.Name!=null)
                gen.writeStringField('RSSFormAEName', rf.AEName__r.Name);
            if(rf.DigitalProperty__c!=null)
                gen.writeStringField('RSSFormDigitalProperty', rf.DigitalProperty__c);
            if(rf.Account__c!=null)
                gen.writeStringField('RSSFormCustomerName', rf.Account__r.Name);
            if(rf.Account__c!=null)
                gen.writeStringField('RSSFormCustomerid', rf.Account__c);
            gen.writeFieldName('RSSProductForms');
            gen.writeStartArray();
            
            for(RSSFormWrapper rfw:RSSFormsList.get(rf))
            {
                system.debug('$$$$ Inside a RSSProductForm ' + rfw.ProductForm.Survey__r.Name);
                gen.writeStartObject();
                gen.WriteStringField('RSSProductFormName', rfw.ProductForm.Survey__r.Name);
                gen.WriteStringField('RSSProductFormId', rfw.ProductForm.Id);
                gen.WriteNumberField('RSSTemplateVersion', rfw.ProductForm.Survey__r.Version__c);
                gen.writeFieldName('RSSQuestionGroup');
                gen.writeStartArray();
                if(rfw.responseGroupWrappers!=null)
                    for(RSSResponseGroupWrapper rgw:rfw.responseGroupWrappers)
                    {
                        system.debug('$$$$ Inside a RSS Group ' +  rgw.QuestionGroup.Name);
                        gen.writeStartObject();
                        gen.writeStringField('RSSQuestionGroupName', rgw.QuestionGroup.Name);
                        gen.writeNumberField('RSSQuestionGroupOrderNumber', rgw.QuestionGroup.Order_Number__c);
                        if(rgw.surveyResponses!=null)
                        {
                            
                            gen.writeFieldName('Responses');
                            gen.writeStartArray();
                            for(RSSQuestionResponse r:rgw.surveyResponses)
                            {
                                system.debug('$$$$ Inside a RSS response ');
                                gen.writeStartObject();
                                if(r.response.Id!=null)
                                    gen.writeStringField('Id', r.response.Id);
                                if(!String.isBlank(r.response.Survey_Question__r.Question__c))
                                    gen.writeStringField('Question', r.response.Survey_Question__r.Question__c);
                                if(!String.isBlank(r.response.Survey_Question__c))
                                    gen.writeStringField('QuestionId', r.response.Survey_Question__c);
                                if(!String.isBlank(r.response.Survey_Question__r.UniqueName__c))
                                    gen.writeStringField('QuestionUniqueId', r.response.Survey_Question__r.UniqueName__c);
                                if(!String.isBlank(r.response.Survey_Question__r.QuestionDescription__c))
                                    gen.writeStringField('QuestionDescription', r.response.Survey_Question__r.QuestionDescription__c);
                                if(r.response.Survey_Question__r.Required__c!=null)
                                gen.writeBooleanField('RequiredQuestion', r.response.Survey_Question__r.Required__c);
                                if(r.response.Survey_Question__r.OrderNumber__c!=null)
                                    gen.writeNumberField('OrderNumber', r.response.Survey_Question__r.OrderNumber__c);
                                if(!String.isBlank(r.response.Survey_Question__r.type__c))
                                    gen.writeStringField('Type', r.response.Survey_Question__r.type__c);
                                if(r.response.Survey_Question__r.type__c != 'Free Text')
                                {
                                    if(!String.isBlank(r.response.Survey_Question__r.Choices__c))
                                        gen.writeStringField('Choices', r.response.Survey_Question__r.Choices__c);
                                }
                                if(!String.isBlank(r.response.response__c))
                                {
                                    gen.writeStringField('Answer', r.response.response__c);
                                }
                                else
                                {
                                    gen.writeStringField('Answer', '');
                                }
                                gen.writeEndObject();
                            }
                            gen.writeEndArray();
                            
                        }
                        
                        gen.writeEndObject();
                    }
                
                gen.writeEndArray();
                gen.writeEndObject();
            }
            gen.writeEndArray();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString();  
    }

    public class RSSTemplateWrapper
    {
        public Survey__c RSSTemplate;
        public List<RSSQuestionGroupWrapper> questionGroupWrappers {get { return  mapquestionGroupWrappers.values();}}
        Map<Id,RSSQuestionGroupWrapper> mapquestionGroupWrappers;
        public RSSTemplateWrapper( Survey__c survey)
        {
            RSSTemplate = survey;
            mapquestionGroupWrappers = new Map<Id,RSSQuestionGroupWrapper>();
        }
    }

    webservice static string createJSONForOfflineUse()
    {
        ID RSSId;
        List<RSSTemplateWrapper> rssTemplateWrappers ;
        List<Survey_Question_Group__c> questionGroups ;
        Map<id,RSSTemplateWrapper> mapRSSTemplateWrappers;
        try
        {
            mapRSSTemplateWrappers = new Map<id,RSSTemplateWrapper>();
            for(Survey__c s:[select id, Name, Version__c, UniqueName__c,RSS_Published__c from Survey__c where RSS_Published__c = true])
            {
                RSSTemplateWrapper trtw = new RSSTemplateWrapper(s);
                mapRSSTemplateWrappers.put(s.id,trtw);
            }
            for(Survey_Question_Group__c sqg :[select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__r.RSS_Published__c = true order by Order_Number__c])
            {
                mapRSSTemplateWrappers.get(sqg.Survey__c).mapquestionGroupWrappers.put(sqg.id,new RSSQuestionGroupWrapper(sqg) );
            }
            for(Survey_Question__c q: [Select s.Type__c, s.Required__c, s.Question__c,s.Survey__c,
                                       s.OrderNumber__c, s.Name,s.UniqueName__c, s.Choices__c, s.Survey_Question_Group__c, s.QuestionDescription__c
                                       From Survey_Question__c s
                                       WHERE s.Survey__r.RSS_Published__c =true ORDER BY s.Survey_Question_Group__r.Order_Number__c, s.OrderNumber__c])
            {
                mapRSSTemplateWrappers.get(q.Survey__c).mapquestionGroupWrappers.get(q.Survey_Question_Group__c).surveyQuestions.add( new RSSSurveyQuestion(q));
            }
            rssTemplateWrappers = mapRSSTemplateWrappers.values();
        }
        catch(Exception e)
        {
            system.Debug(e);
        }
        /*    gen.writeStringField('def', 'xyz');
         gen.writeFieldName('ghi');
         gen.writeStartObject();
         
         gen.writeObjectField('aaa', intlist);
         
         gen.writeEndObject();*/
        //  system.assertEquals(rssTemplateWrappers, null);
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('RSSTemplates');
        gen.writeStartArray();
        
        for(RSSTemplateWrapper rtw:rssTemplateWrappers)
        {
            gen.writeStartObject();
            gen.WriteStringField('RSSTemplateName', rtw.RSSTemplate.Name);
            gen.WriteStringField('RSSTemplateId',rtw.RSSTemplate.Id);
            gen.WriteStringField('RSSTemplateUniqueName',rtw.RSSTemplate.UniqueName__c);
            gen.writeNumberField('RSSTemplateVersion', rtw.RSSTemplate.Version__c);
            gen.writeFieldName('RSSQuestionGroup');
            gen.writeStartArray();
            if(rtw.questionGroupWrappers!=null)
                for(RSSQuestionGroupWrapper rgw:rtw.questionGroupWrappers)
                {
                    gen.writeStartObject();
                    gen.writeStringField('RSSQuestionGroupName', rgw.QuestionGroup.Name);
                    gen.writeNumberField('RSSQuestionGroupOrderNumber', rgw.QuestionGroup.Order_Number__c);
                    if(rgw.surveyQuestions!=null)
                    {
                        
                        gen.writeFieldName('Questions');
                        gen.writeStartArray();
                        for(RSSSurveyQuestion q:rgw.surveyQuestions)
                        {
                            gen.writeStartObject();
                            gen.writeStringField('Id', q.question.Id);
                            if(!String.isBlank(q.question.UniqueName__c))
                                gen.writeStringField('QuestionUniqueId', q.question.UniqueName__c);
                            gen.writeStringField('Question', q.question.Question__c);
                            if(q.question.UniqueName__c!=null)
                                gen.writeStringField('QuestionUniqueName', q.question.UniqueName__c);
                            if(q.question.QuestionDescription__c!=null)
                                gen.writeStringField('QuestionDescription', q.question.QuestionDescription__c);
                            if(q.question.Required__c!=null)
                            gen.writeBooleanField('RequiredQuestion', q.question.Required__c);
                            gen.writeNumberField('OrderNumber', q.question.OrderNumber__c);
                            gen.writeStringField('Type', q.question.type__c);
                            if(q.question.type__c != 'Free Text')
                            {
                                gen.writeStringField('Choices', q.question.Choices__c);
                            }
                            gen.writeEndObject();
                        }
                        gen.writeEndArray();
                        
                    }
                    
                    gen.writeEndObject();
                }
            
            gen.writeEndArray();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString(); 
    }

    Public static Boolean TemplateWriteAccess(string userId)
    {
        Set<string> Psets = new Set<String>();
        try
        {
        eRSS__c objApp = eRSS__c.getInstance('eRSS');
            List<String> tempList = String.valueOf(objApp.Permission_Set_Template__c).split(',',0);
        for(String a:tempList)
        {
            Psets.add(a.trim());
        }
        }
        catch(Exception e)
        {
           
            return false;
        }
        
        for(PermissionSetAssignment pas : [SELECT PermissionSet.label FROM PermissionSetAssignment where AssigneeId = :userId])
        {
            if(Psets.contains(pas.PermissionSet.label))
            {
                return true;
            }
        }
        string userIdCheck = Userinfo.getUserId();
        for(User objUser: [SELECT Profile.Name,ERSS_Service_Architect__c, ERSS_Super_User__c FROM User WHERE Id = :userIdCheck]){
            if(Psets.contains(objUser.Profile.Name) || objUser.ERSS_Service_Architect__c || objUser.ERSS_Super_User__c)
            {
                return true;
            }
        }
        return false;
    }


    //Changes by shprasan: Changing the return type to Map<String,Boolean> from Boolean
    Public static Map<String,Boolean> FormWriteAccess(string userId)
    {
        //Changes by shprasan: Creating the map userPermissionMap and initialising the values
        Map<String,Boolean> userPermissionMap = new Map<String,Boolean>();
        userPermissionMap.put('Pre-sales',false);
        userPermissionMap.put('Post-sales',false);
        userPermissionMap.put('WriteAccessOfUser',false);
        userPermissionMap.put('SuperUser',false);
        userPermissionMap.put('CCare',false);
        Set<string> Psets = new Set<String>();
        Set<string> ProfilesPostSales = new Set<string>();
        Set<string> profilesReadOnly = new Set<string>();
        //Changes by Sharath for CR 3730732 
        //Creating the temp variables:
        List<String> tempListPreSales = new List<String>();
        List<String> tempListPostSales = new List<String>();
        List<String> tempListReadOnly = new List<String>();
        //Query the ERSS_Profile_Access__mdt custom metadata object. Fetch all the records
        List<ERSS_Profile_Access__mdt> profileAccessMetaData = new List<ERSS_Profile_Access__mdt>();
        profileAccessMetaData = [select Post_Sales__c,Pre_Sales__c,Read_Only__c from ERSS_Profile_Access__mdt];        
        try
        {
            eRSS__c objApp = eRSS__c.getInstance('eRSS');
            
             //Get the value from the custom setting. populate the temp lists.   
             tempListPreSales = String.valueOf(objApp.Permission_Set_Form__c).split(',',0);
             tempListPostSales = String.valueOf(objApp.Post_Sales__c).split(',',0);
             tempListReadOnly = String.valueOf(objApp.Read_Only__c).split(',',0);
             // Loop through the custom metadata records: populate the temp lists 
             for(ERSS_Profile_Access__mdt metaDataRec: profileAccessMetaData)
             {
                if(metaDataRec.Pre_Sales__c != null && metaDataRec.Pre_Sales__c.length() > 14)
                {
                    tempListPreSales.addAll(metaDataRec.Pre_Sales__c.split(',',0));
                }   
                if(metaDataRec.Post_Sales__c != null && metaDataRec.Post_Sales__c.length() > 14)
                {
                    tempListPostSales.addAll(metaDataRec.Post_Sales__c.split(',',0));
                }   
                if(metaDataRec.Read_Only__c != null && metaDataRec.Read_Only__c.length() > 14)
                {
                    tempListReadOnly.addAll(metaDataRec.Read_Only__c.split(',',0));
                }   
             }
             //trim the values in the list and add to the set
            for(String a:tempListPreSales)
            {
                Psets.add(a.trim());
            }
            
            for(String a:tempListPostSales)
            {
                ProfilesPostSales.add(a.trim());
            }
            
            for(String a:tempListReadOnly)
            {
                profilesReadOnly.add(a.trim());
            }

        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in Setting permission'));
            //Changing the return statement
            //return false;
        }
        
        for(PermissionSetAssignment pas : [SELECT PermissionSet.label FROM PermissionSetAssignment where AssigneeId = :userId])
        {
            if(Psets.contains(pas.PermissionSet.label) || ProfilesPostSales.contains(pas.PermissionSet.label))
            {
                //if (pas.PermissionSet.label == 'eRSS - Solution Engineer')
                //{
                //       //system.assert(1==2); 
                //       userPermissionMap.put('Pre-sales',true);
                //       userPermissionMap.put('WriteAccessOfUser',true); 
                //}
                //else if (pas.PermissionSet.label == 'eRSS - PostSales')                
                //{
                //       userPermissionMap.put('Post-sales',true);
                //       userPermissionMap.put('WriteAccessOfUser',true); 
                //}
                if (pas.PermissionSet.label == 'eRSS - System Administrator')
                {
                       userPermissionMap.put('SuperUser',true);
                       userPermissionMap.put('WriteAccessOfUser',true);                         
                }
                //return true;
                //Changing the return statement
                return userPermissionMap;
            }
        }
        string userIdCheck = Userinfo.getUserId();
        //Changing the if condition: Profiles dont matter
        for(User objUser: [SELECT ProfileID,Profile.Name, ERSS_Service_Architect__c, ERSS_Super_User__c FROM User WHERE Id = :userIdCheck])
        {
            String id = objUser.ProfileID;
            if(objUser.ERSS_Super_User__c)
            {
                //Changes by shprasan: Changing the return value
                //return true;
                    userPermissionMap.put('SuperUser',true);
                    userPermissionMap.put('WriteAccessOfUser',true);                         
                    return userPermissionMap;
            }
            else if (Psets.contains(objUser.ProfileID) || Psets.contains(id.left(15)))
            {                    
                    userPermissionMap.put('Pre-sales',true);
                    userPermissionMap.put('WriteAccessOfUser',true);                         
                    return userPermissionMap;                
            }
            else if (ProfilesPostSales.contains(objUser.ProfileID) || ProfilesPostSales.contains(id.left(15)))
            {
                    userPermissionMap.put('Post-sales',true);
                    userPermissionMap.put('WriteAccessOfUser',true);                         
                    return userPermissionMap;                

            }
            else if (profilesReadOnly.contains(objUser.ProfileID) || profilesReadOnly.contains(id.left(15)))                
            {                    
                    userPermissionMap.put('CCare',true);
                    return userPermissionMap;                                    
            }
        }
        //Changes by shprasan: changed the return  statement
        //return false;
        return userPermissionMap;
    }
    /*
     webservice static String CreateXML( String RSSFormId)
     {
     ID RSSId;
     List<RSSResponseGroupWrapper> responseGroupWrappers ;
     List<Survey_Question_Group__c> questionGroups ;
     SurveyTaker__c RSSform ;
     List<RSSQuestionResponse> surveyResponses ;
     
     try
     {
     RSSId = RSSFormId;
     responseGroupWrappers = new List<RSSResponseGroupWrapper>();
     for(SurveyTaker__c s:[select Name,Id, RSS_Name__c, Version__c, RSS_Unique_name__c, Survey__c from SurveyTaker__c where Id = :RSSId])
     {
     RSSform = s;
     }
     questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :RSSform.Survey__c order by Order_Number__c];
     if(questionGroups != null || questionGroups.size() != 0)
     {
     List<SurveyQuestionResponse__c > tempResponses = [select Id,Question__c,Survey_Question__r.QuestionDescription__c, Response__c, SurveyTaker__c,Survey_Question__c, Survey_Question__r.Question__c, Survey_Question__r.OrderNumber__c,
     Survey_Question__r.Type__c, Survey_Question__r.Choices__c,Survey_Question__r.Survey_Question_Group__c from SurveyQuestionResponse__c where SurveyTaker__c = :RSSId
     and Survey_Question__r.Survey_Question_Group__c in :questionGroups ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c];
     Map<Id,List<RSSQuestionResponse>> tempMap = new Map<Id,List<RSSQuestionResponse>>();
     for(SurveyQuestionResponse__c q:tempResponses)
     {
     if(tempMap.get(q.Survey_Question__r.Survey_Question_Group__c)==null)
     {
     tempMap.put(q.Survey_Question__r.Survey_Question_Group__c,new List<RSSQuestionResponse>());
     }
     tempMap.get(q.Survey_Question__r.Survey_Question_Group__c).add(new RSSQuestionResponse(q));
     }
     for(Survey_Question_Group__c sqg:QuestionGroups)
     {
     RSSResponseGroupWrapper toBeAdded = new RSSResponseGroupWrapper(sqg);
     tobeAdded.surveyResponses = tempMap.get(sqg.Id);
     responseGroupWrappers.add(toBeAdded);
     }
     }
     }
     catch(Exception e)
     {
     system.assertEquals(e,null);
     }
     
     XmlStreamWriter w = new XmlStreamWriter();
     w.writeCharacters('\n');
     w.writeStartElement(null, 'RSSForm', null);
     w.writeCharacters('\n');
     w.writeStartElement(null, 'RSSFormId', null);
     w.writeCharacters(RSSFormId);
     w.writeEndElement();
     w.writeCharacters('\n');
     for(RSSResponseGroupWrapper rgw:responseGroupWrappers)
     {
     w.writeStartElement(null, 'RSSQuestionGroup', null);
     w.writeCharacters('\n');
     w.writeStartElement(null, 'RSSQuestionName', null);
     w.writeCharacters(rgw.QuestionGroup.Name);
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeStartElement(null, 'RSSQuestionGroupOrderNumber', null);
     w.writeCharacters(String.valueof(rgw.QuestionGroup.Order_Number__c));
     w.writeEndElement();
     w.writeCharacters('\n');
     if(rgw.surveyResponses!=null)
     {
     for(RSSQuestionResponse r:rgw.surveyResponses)
     {
     w.writeCharacters('\t');
     w.writeStartElement(null, 'Responses', null);
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeStartElement(null, 'Id', null);
     w.writeCharacters(r.response.Id);
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeStartElement(null, 'Question', null);
     w.writeCharacters(r.response.Survey_Question__r.Question__c);
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeStartElement(null, 'OrderNumber', null);
     w.writeCharacters(String.valueof(r.response.Survey_Question__r.OrderNumber__c));
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeStartElement(null, 'Type', null);
     w.writeCharacters(r.response.Survey_Question__r.type__c);
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     if(r.response.Survey_Question__r.type__c != 'Free Text')
     {
     w.writeStartElement(null, 'Choices', null);
     w.writeCharacters(r.response.Survey_Question__r.Choices__c);
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     }
     w.writeStartElement(null, 'Answer', null);
     if(r.response.response__c!=null)
     {
     w.writeCharacters(r.response.response__c);
     }
     else
     {
     w.writeCharacters(' ');
     }
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     w.writeCharacters('\t');
     w.writeEndElement();
     w.writeCharacters('\n');
     w.writeCharacters('\t');
     
     }
     }
     w.writeEndElement();
     
     w.writeCharacters('\n');
     }
     w.writeEndElement();
     w.writeCharacters('\n');
     
     String xmlOutput = w.getXmlString();
     w.close();
     return xmlOutput;
     }
     */
    class FormSetResponses
    {
        public SurveyTaker__c form;
        public List<SurveyQuestionResponse__c> responses;
        public FormSetResponses()
        {
            form = new SurveyTaker__c();
            responses = new List<SurveyQuestionResponse__c>();
        }
    }

    //
    public static List<RSSFormWrapper> CreateRSSFromTemplate(List<String> Templates,String RSSFormId)
    {
        List<SurveyTaker__c> insertList = new List<SurveyTaker__c>();
        List<RSSFormWrapper> RSSFormWrappers = new List<RSSFormWrapper>();
        List<SurveyQuestionResponse__c> RSSQuestionResponses = new List<SurveyQuestionResponse__c>();
        if(RSSFormId !=null && Templates != null)
        {
            //SurveyTaker,Responses
            Map<String,FormSetResponses> QuestionsTemplateMap = new Map<String,FormSetResponses>();
            for(Survey_Question__c sq:[Select  Id, Survey__c From Survey_Question__c  WHERE Survey__c =: Templates  ORDER BY OrderNumber__c])
            {
                if(QuestionsTemplateMap.get(sq.Survey__c)==null)
                {
                    FormSetResponses Fsr = new FormSetResponses();
                    insertList.add(fsr.form);
                    
                    QuestionsTemplateMap.put(sq.Survey__c,Fsr);
                }
                FormSetResponses tempFSr = QuestionsTemplateMap.get(sq.Survey__c);
                tempFSr.form.Survey__c = sq.Survey__c;
                tempFSr.form.RSS_Form__c = RSSFormId;
                SurveyQuestionResponse__c response = new SurveyQuestionResponse__c();
                response.Survey_Question__c = sq.id;
                tempFSr.responses.add(response);
            }
            try
            {
                insert insertList;
                for(FormSetResponses fsr:QuestionsTemplateMap.values())
                {
                    for(SurveyQuestionResponse__c sqr:fsr.responses)
                    {
                        sqr.SurveyTaker__c=fsr.form.id;
                        RSSQuestionResponses.add(sqr);
                    }
                }
                insert RSSQuestionResponses;
                /*
                 List<Survey_Question_Group__c> questionGroups;
                 questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c = :QuestionsTemplateMap.keyset() order by Order_Number__c];
                 //        Map<id,List<Survey_Question_Group__c>> FormQuestionGroupMap = new Map<id,List<Survey_Question_Group__c>>();
                 Map<id,List<RSSResponseGroupWrapper>> FormGroupMap = new Map<id,List<RSSResponseGroupWrapper>>();
                 if(questionGroups != null || questionGroups.size() != 0)
                 {
                 List<String> Formids = new List<String>();
                 for(SurveyTaker__c st:insertList)
                 {
                 Formids.add(st.id);
                 }
                 List<SurveyQuestionResponse__c > tempResponses = [select Id,Question__c, Response__c, SurveyTaker__c,Survey_Question__c, Survey_Question__r.Question__c, Survey_Question__r.OrderNumber__c,
                 Survey_Question__r.Type__c, Survey_Question__r.Choices__c,Survey_Question__r.QuestionDescription__c,Survey_Question__r.Survey_Question_Group__c from SurveyQuestionResponse__c where SurveyTaker__c in :Formids
                 and Survey_Question__r.Survey_Question_Group__c in :questionGroups ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, Survey_Question__r.OrderNumber__c];
                 //QuestionGroup,Responses
                 Map<Id,List<RSSQuestionResponse>> tempMap = new Map<Id,List<RSSQuestionResponse>>();
                 //In the View Page, We would need to display only the questions which were responded. creating a new Map for RSSFormView Page
                 Map<Id,List<RSSQuestionResponse>> pdftempMap = new Map<Id,List<RSSQuestionResponse>>();
                 
                 for(SurveyQuestionResponse__c q:tempResponses)
                 {
                 if(tempMap.get(q.Survey_Question__r.Survey_Question_Group__c)==null)
                 {
                 tempMap.put(q.Survey_Question__r.Survey_Question_Group__c,new List<RSSQuestionResponse>());
                 }
                 tempMap.get(q.Survey_Question__r.Survey_Question_Group__c).add(new RSSQuestionResponse(q));
                 }
                 
                 for(Survey_Question_Group__c sqg:QuestionGroups)
                 {
                 
                 RSSResponseGroupWrapper toBeAdded = new RSSResponseGroupWrapper(sqg);
                 tobeAdded.surveyResponses = tempMap.get(sqg.Id);
                 
                 if(FormGroupMap.get(QuestionsTemplateMap.get(sqg.survey__c).form.id) ==null)
                 {
                 FormGroupMap.put(QuestionsTemplateMap.get(sqg.survey__c).form.id,new List<RSSResponseGroupWrapper>());
                 }
                 FormGroupMap.get(QuestionsTemplateMap.get(sqg.survey__c).form.id).add(toBeAdded);
                 }
                 for(SurveyTaker__c st:insertList)
                 {
                 RSSFormWrapper toBeAdded = new RSSFormWrapper(st);
                 toBeAdded.responseGroupWrappers = FormGroupMap.get(st.id);
                 RSSFormWrappers.add(toBeAdded);
                 }
                 return RSSFormWrappers;
                 
                 }
                 */
            }
            catch(Exception e)
            {
                system.assertEquals(e,null);
            }
        }
        return null;
    }
    
    
    public static void updateProductInfoOnRSSForm(List<Id> lRSSToUpdateId)
    {
        List<RSS_Form__c> lRSSFormWithProducts = new List<RSS_Form__c>();
        
        Map<Id,String> mRSSFormIdAndProducts = new Map<Id,String>();
        
        Schema.DescribeSObjectResult schemaSurveyObj = Schema.SObjectType.Survey__c;
        Map<String,Schema.RecordTypeInfo> surveyRecordTypeInfo = schemaSurveyObj.getRecordTypeInfosByName();
        
        Id surveyId = surveyRecordTypeInfo.get('RSS Template').getRecordTypeId();
        
        for(SurveyTaker__c objSurveyTaken :[SELECT Id, RSS_Form__c, Survey__r.Name FROM SurveyTaker__c WHERE RSS_Form__c IN :lRSSToUpdateId AND Survey__r.RecordTypeId =:surveyId])
        {
            if(mRSSFormIdAndProducts.containsKey(objSurveyTaken.RSS_Form__c))
            {
                string tempString;
                tempString = mRSSFormIdAndProducts.get(objSurveyTaken.RSS_Form__c)+ ',' + objSurveyTaken.Survey__r.Name;
                mRSSFormIdAndProducts.put(objSurveyTaken.RSS_Form__c, tempString);
            }
            
            else
            {
                mRSSFormIdAndProducts.put(objSurveyTaken.RSS_Form__c, objSurveyTaken.Survey__r.Name);
            }
        }
        
        for(RSS_Form__c objRSSForm:[SELECT Id,Products__c FROM RSS_Form__c WHERE Id IN :lRSSToUpdateId])
        {
            if(mRSSFormIdAndProducts.containsKey(objRSSForm.Id))
            {
                objRSSForm.Products__c = mRSSFormIdAndProducts.get(objRSSForm.Id);
                lRSSFormWithProducts.add(objRSSForm);
            }
        }
        
        
        if(lRSSFormWithProducts.size()>0)
        {
            try
            {
                update lRSSFormWithProducts;
            }
            
            catch(Exception e)
            {
                system.debug('Exception in Trigger #ERSSUpdateProductsOnRSSForm for Updating Products' + e);
            }
        }
    }
    
    //Added method for cloning the Forms with responses
    
    // changes by Vandhana for CR 3393971
    public static List<RSSFormWrapper> cloneRSSFromWithResponse(List<String> Templates,String RSSFormId, String oldFormId)
    {
        Map<String,String> mQuesUniqueNameAndResponse = new Map<String,String>();
        Map<String,String> mUniqueNameAndSurvey = new Map<String,String>();
        list<String> lSurveyUniqueName = new list<String>();
        List<SurveyTaker__c> Forms = new List<SurveyTaker__c>();
        List<String> SurveyFormIds = new List<String>();
        
        Forms = [select id,Survey__c,Survey__r.Id from SurveyTaker__c where RSS_Form__c =:oldFormId order by Survey__r.Name];
        
        system.debug('#########1#' + Forms);
        
        
        for(SurveyTaker__c st:Forms)
        {
            // changes by Vandhana, add template Id to retain previous version of template
                //lSurveyUniqueName.add(st.Survey__r.UniqueName__c);
            lSurveyUniqueName.add(st.Survey__r.Id);
            SurveyFormIds.add(st.Id);
        }
        
        // changes by Vandhana
        //    1. Replace Survey.UniqueName with Survey.Id to retain previous version of template on RSSForm

        //for(Survey__c objSurvey :[SELECT Id,Version__c, UniqueName__c FROM Survey__c WHERE 
        //                      UniqueName__c IN :lSurveyUniqueName AND 
        //                      RSS_Published__c = true ORDER BY Id Desc, Version__c DESC])
        for(Survey__c objSurvey :[SELECT Id,Version__c, UniqueName__c FROM Survey__c WHERE 
                              Id IN :lSurveyUniqueName ORDER BY Id Desc, Version__c DESC])
        {
            if(!mUniqueNameAndSurvey.containsKey(objSurvey.UniqueName__c))
            {
                mUniqueNameAndSurvey.put(objSurvey.UniqueName__c, objSurvey.Id);
            }    
        }
        
        System.debug('#########4#' + mUniqueNameAndSurvey);
        
        for(SurveyQuestionResponse__c objSurveyQuestionResponse: [SELECT Id, Response__c, SurveyTaker__c, Survey_Question__r.UniqueName__c FROM SurveyQuestionResponse__c 
                                                                  WHERE SurveyTaker__c IN :SurveyFormIds ])
                                               
        {
            mQuesUniqueNameAndResponse.put(objSurveyQuestionResponse.Survey_Question__r.UniqueName__c, objSurveyQuestionResponse.Response__c);
            /*for(SurveyQuestionResponse__c objResponse: objSurveyQuestion.Survey_Question_Answers__r)
            {
                mQuesUniqueNameAndResponse.put(objSurveyQuestion.UniqueName__c, objResponse.Response__c);
            } */   
        } 
        
        system.debug('#########5#' + mQuesUniqueNameAndResponse);
        
        List<SurveyTaker__c> insertList = new List<SurveyTaker__c>();
        List<RSSFormWrapper> RSSFormWrappers = new List<RSSFormWrapper>();
        List<SurveyQuestionResponse__c> RSSQuestionResponses = new List<SurveyQuestionResponse__c>();
        if(RSSFormId !=null && Templates != null)
        {
        
        //SurveyTaker,Responses
        Map<String,FormSetResponses> QuestionsTemplateMap = new Map<String,FormSetResponses>();
        for(Survey_Question__c sq:[Select  Id, Survey__c,UniqueName__c From Survey_Question__c  WHERE Survey__c =: mUniqueNameAndSurvey.values() ORDER BY OrderNumber__c])
        {
            if(QuestionsTemplateMap.get(sq.Survey__c)==null)
            {
                FormSetResponses Fsr = new FormSetResponses();
                insertList.add(fsr.form);
                
                QuestionsTemplateMap.put(sq.Survey__c,Fsr);
            }
                FormSetResponses tempFSr = QuestionsTemplateMap.get(sq.Survey__c);
                tempFSr.form.Survey__c = sq.Survey__c;
                tempFSr.form.RSS_Form__c = RSSFormId;
                SurveyQuestionResponse__c response = new SurveyQuestionResponse__c();
                response.Survey_Question__c = sq.id;
                if(mQuesUniqueNameAndResponse.containsKey(sq.UniqueName__c))
                {
                    response.Response__c = mQuesUniqueNameAndResponse.get(sq.UniqueName__c);
                }
                tempFSr.responses.add(response);
        }         
        try
        {
        insert insertList;
        for(FormSetResponses fsr:QuestionsTemplateMap.values())
        {
            for(SurveyQuestionResponse__c sqr:fsr.responses)
            {
                sqr.SurveyTaker__c=fsr.form.id;
                RSSQuestionResponses.add(sqr);
            }
        }
        insert RSSQuestionResponses;
        
        }
        catch(Exception e)
        {
        system.assertEquals(e,null);
        }
        }
        return null;
    }
}