global with sharing class ViewSurveyBackened {

    public static String  qQuestion                      {get; set;}
    public Boolean qRequired                      {get; set;}
    public static String  qChoices                       {get; set;}
    public static String surveyName                        {get; set;}
    public static String surveyHeader                {get; set;}
    public static String surveyId                          {get; set;} 
      public static string renderSurveyPreview           {get; set;}  
      public String questionName                    {get; set;}  
      public String questionType                    {get; set;}
      public Boolean questionRequired             {get; set;}
    // public List<SelectOption> singleOptions   {get; set;} 
    public List<Parameters> singleOptions   {get; set;} 
      public static List<question> allQuestions        {get; set;}
      public List<String> responses                   {get; set;}
      public static Integer allQuestionsSize               {get; set;}
      public static String  templateURL                {get; set;}
      public static String  surveyThankYouText         {get; set;}
      public static String  surveyThankYouURL          {get; set;}
    //public String  caseId                     {get; set;}
    //public String pAppId                      {get;set;}
    public static String approvalErrorMsg                      {get;set;}
    
    public static Boolean approvalError      {get;set;}
    public static String questionsDisplay {get;set;}
    public static Id surveyRecordTypeId {get;set;}    
    public static List<String> results = new String[2];
        //new List<String>();
    //public List<String> results = new String[0];
    //public String autoApprove = 'false'; 
    //public String approvalState  {get; set;}
    static Parameters params = new Parameters();

    // public ViewSurveyBackened() {

    // }

    // @AuraEnabled(cacheable =true)
    // public static Boolean getApprovalError(){
    //   System.debug('Inside getApprovalError - getApprovalError ==>'+approvalError);
    //   return approvalError; 
    // }

    @AuraEnabled(cacheable=true)
    public static Survey__c getSurveyRecord(String surveyId){
      Survey__c s = new Survey__c();
        if(surveyId != null){
          s = [SELECT Id, Name, Survey_Header__c, Show_Entry_Question__c, Entry_Question_Details__c, Main_Question_Details__c
                 FROM Survey__c where Id = :surveyId WITH SECURITY_ENFORCED];
          
        }
        return s;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean initialApproval(String surveyRecordId, String caseId, String pAppId){
        System.debug('Inside initialApproval');
        surveyId = surveyRecordId;
        if(caseId ==null || caseId.length()<5){
            caseId = 'none';
        }

        // By default the preview is not showing up
        renderSurveyPreview = 'false';

        if (surveyId != null){ 
            // Retrieve all necessary information to be displayed on the page
            allQuestions = new List<question>();
            setSurveyNameAndThankYou(surveyId);
            //allQuestionsSize = setupQuestionList();
        }
        
        
        System.debug('surveyId ==>'+surveyId+'caseId ==>'+caseId+'pAppId ==>'+pAppId);
         approvalError = false;
        if(surveyRecordTypeId == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Product Approval').getRecordTypeId()) 
        {
          Product_Approvals__c p_approval;
          
          for(Product_Approvals__c pa: [select Id,Status__c, Survey_Taken__c from Product_Approvals__c where id=:pAppId])
            p_approval = pa;
            if(p_approval == null) {
              approvalError = true;
              approvalErrorMsg = 'We could not find the related Request. Please ensure you copy and paste the entire link.';
            }
            else if(p_approval.Status__c != 'PENDING-TECHNICAL'){
                approvalError = true;
                approvalErrorMsg = 'This request has already been submitted. Please refer to the link in your email to check on the status.';
            }
        }
        System.debug('approvalError ==>'+approvalError);
        return approvalError;
}
//private
public static boolean checkRequired(String response, Survey_Question__c question){
  System.debug('question.Required__c - line 97 ==>'+question.Required__c);
  if(question.Required__c == true){
      if(response == null || response =='NO RESPONSE')
        return false;
  }
  return true;
} 
//private
public static List<SurveyQuestionResponse__c> handleMultiSelectResponse(String response, String surveyTakerId, String questionId, String approvalId){
  	System.debug('Inside handleMultiSelectResponse - line 106 ==>'+response+'\nsurveyTakerId - '+surveyTakerId+'\nquestionId - '+questionId+'\napprovalId - '+approvalId);
    List <String> responses = response.split('&@');
  List<SurveyQuestionResponse__c> sqrList = new List<SurveyQuestionResponse__c>();
  for( String r:responses){
     SurveyQuestionResponse__c sqr = new SurveyQuestionResponse__c();
     sqr.Response__c = r;
     sqr.SurveyTaker__c = surveyTakerId;
     sqr.Survey_Question__c = questionId;
     sqr.Product_Approval__c = approvalId;
     sqrList.add(sqr);
  }
return sqrList;
}



//Webservice
@AuraEnabled
public static  String getResponses(List<String> resp, String autoApprove) {
    System.debug('Inside getResponses - line 288');
    if(resp.size()<=2)
      return 'false';
       Id surveyRecordTypeId = null;
       Product_Approvals__c p_approval;
       System.debug('Inside getResponses - line 293 ==>'+ p_approval);
       SurveyTaker__c st;
       /* String userId = resp.get(resp.size()-3);*/
        String surveyId = resp.get(resp.size()-2);
        String paId = resp.get(resp.size()-1);
        System.debug('Inside getResponses - line 298 - surveyId ==>'+surveyId+' paId ==>'+paId);
        if(paId.toUpperCase()=='NONE'||paId == null || paId.length()<3)
         paId = null;
        
         Survey__c s = [SELECT Name, Id,recordTypeId FROM Survey__c WHERE Id =:surveyId];
         if (s != null)
          surveyRecordTypeId = s.RecordTypeId;
        
     /*   if(userId.toUpperCase() == 'NONE')
      userId = null;*/
    List <SurveyTaker__c> stList;
    /*
        if (userId == null || userId.length() < 10){
            st = new SurveyTaker__c();
            st.Case__c = null;
            st.Contact__c = null;
            try{  
              insert st;
            }catch(Exception e){
            return 'contact';
      }
        }*/
     if(surveyRecordTypeId == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Product Approval').getRecordTypeId()) 
     {
        
        for(Product_Approvals__c pa: [select Id,Survey_Taken__c from Product_Approvals__c where id=:paId])
            p_approval = pa;
            
            
            if(p_approval == null || p_approval.Survey_Taken__c == null){  //
                //System.debug('Inside getResponses - line 328 - p_approval ==>'+p_approval+'p_approval.Survey_Taken__c ==>'+p_approval.Survey_Taken__c);
                return 'problem';
            }
        
        
         
        try{
            stList = [Select id,  Taken__c from SurveyTaker__c where id = :p_approval.Survey_Taken__c ]; //Contact__c=:userId AND Survey__c= :surveyId AND Case__c= :caseId];
            System.debug('Inside getResponses - line 336 - stList ==>'+stList);
          }catch(Exception e){
            System.debug('Inside getResponses - line 338');
            return 'problem';
        }
        

        if(stList == null || stList.size()==0){
          System.debug('Inside getResponses - line 344 - stList ==>'+stList);
          return 'problem';
        }
         
        else{
          st = stList[0];
          System.debug('Inside getResponses - line 350 - st ==>'+st);
        }
         
               
     }
     else {
          
        st = new SurveyTaker__c();
    //st.Contact__c = userId;
    st.Survey__c = surveyId;
    st.Taken__c = 'true';
    //st.Case__c = caseId;
    insert st;
          
     }
       
        
        resp.remove(resp.size()-1);
        resp.remove(resp.size()-1);
        resp.remove(resp.size()-1);
        System.debug('Inside getResponses - line 370 - resp ==>'+resp);
        List<Survey_Question__c> allQuestions = [Select Id, Type__c, Required__c from Survey_Question__c Where Survey__c=:surveyId ORDER BY OrderNumber__c];
        System.debug('Inside getResponses - line 372 - allQuestions ==>'+allQuestions); 
        List<String> questionsId = new List<String>();
        
        for (Survey_Question__c q : allQuestions)
            questionsId.add(q.Id);
        System.debug('Inside getResponses - line 377 - questionsId ==>'+questionsId);
        //new response list  
        List <SurveyQuestionResponse__c> sqrList = new List<SurveyQuestionResponse__c>();
        
        Integer i = 0;
        Boolean skip_approval = false;
        
        if(autoApprove == 'true'){
            skip_approval = true;
        }
        else {
        
        for(String r:resp) {
        
        /*
            if(i==0 && r == 'No'){
                    skip_approval = true;
            }else if(!checkRequired(r, allQuestions[i])){
                return 'false';             
            }
          */  
          
          if(!checkRequired(r, allQuestions[i])){
                return 'false';             
            }
          
            if(allQuestions[i].Type__c=='Multi-Select--Vertical'){
              if(surveyRecordTypeId == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Product Approval').getRecordTypeId())
                sqrList.addAll(handleMultiSelectResponse(r, String.valueOf(st.Id), questionsId[i], String.valueOf(p_approval.id)));
              else
                sqrList.addAll(handleMultiSelectResponse(r, String.valueOf(st.Id), questionsId[i], ''));
                
            }
            else{
                SurveyQuestionResponse__c sqr = new SurveyQuestionResponse__c();
                sqr.SurveyTaker__c = st.Id;
                sqr.Response__c = r;
                sqr.Survey_Question__c = questionsId[i];
                if(surveyRecordTypeId == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Product Approval').getRecordTypeId())
                 sqr.Product_Approval__c = p_approval.id;
                sqrList.add(sqr);
            }
            i++;
            //insert sqr;
          
        }
        
        
        try{
            insert sqrList;
        }catch(exception e){
          System.debug('Inside getResponses - sqrList - line 429 ==>'+sqrList);
          System.debug('Inside getResponses - Exception ==>'+e);
            return 'false';
        }
        }
        
        // create the new approval request to submit
     if(surveyRecordTypeId == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Product Approval').getRecordTypeId()) 
     {
        if(skip_approval == true) {
        
         p_approval.Skip_Approval__c = true;
        
         update p_approval;
        }   System.debug('productApprovalId - line 440 ==>'+p_approval.id);
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('');
            req.setObjectId(p_approval.id);
            // submit the approval request for processing
            Approval.ProcessResult result = Approval.process(req);
            
        
     }  
        return 'true';
    }
  

//------------------------------------------------------------------------------//  

//CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //private static Testmethod void testViewSurveyController() {
    //    SurveyTestingUtil tu = new SurveyTestingUtil();
    //    Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
    //    Apexpages.Standardcontroller stc;   
    //    ViewSurveyController vsc = new ViewSurveyController(stc);
    //    vsc.getAQuestion();
    //    System.assert(vsc.allQuestionsSize == 4);
    //    System.assert(tu.surveyId != null);
    //}
//----------------------------------------------------------------------------//    
    
    /* Called during the setup of the page. 
       Retrieve questions and responses from DB and inserts them in 2 lists. */
       public Integer setupQuestionList(){
        /*allQuestions.clear();
        List<Survey_Question__c> allQuestionsObject = 
                                        [Select Type__c, Id, Survey__c, Required__c, 
                                        Question__c, OrderNumber__c, Name, Choices__c
                                        From Survey_Question__c  
                                        WHERE Survey__c =: surveyId
                                        order by OrderNumber__c];
        for (Survey_Question__c q : allQuestionsObject){
            question theQ = new question(q);
            allQuestions.add(theQ);
        }
        //responses = getResponses();//taken out because it was SOQL heavy//*/
        getAQuestion(surveyId);
        return allQuestions.size();
    }


    /** Sets the survey's name variable
    *  param: sID   The survey ID as specified in the DB
    */
    public static void setSurveyNameAndThankYou(String sId){
        System.debug('Inside setSurveyNameAndThankYou');
        Organization org = [Select Division from Organization];
        
          Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c, Survey_Header__c,Show_Entry_Question__c,recordTypeId
                             FROM Survey__c WHERE Id =:sId];
          surveyRecordTypeId = s.RecordTypeId;
          surveyName = s.Name;
          surveyHeader = s.Survey_Header__c;
          templateURL = org.Division + '/TakeSurvey?' + 'id='+sId;//+'&cId={!Contact.Id}'+'&caId='+'{!Case.id}';
          surveyThankYouText = s.thankYouText__c;
          surveyThankYouURL = s.thankYouLink__c;
          if (s.Show_Entry_Question__c == true){
            questionsDisplay = 'style="display:none;"';
          }
          System.debug('surveyRecordTypeId ==>'+surveyRecordTypeId+'surveyName ==>'+surveyName+'surveyHeader ==>'+surveyHeader+'templateURL ==>'+
          +templateURL+'surveyThankYouText ==>'+surveyThankYouText+'surveyThankYouURL ==>'+surveyThankYouURL);
      }



    
    /*public static List<String> getResults() {
      return results;
    }

    public static void setResults(List<String> r){
        results = r;
    }*/
    
   /* public static String getAutoApprove(){
        return autoApprove;
    }
    
    public static void setAutoApprove(String a){
        autoApprove = a;
    } */


//------------------------------------------------------------------------------//   
public Pagereference updateSurveyName(){
  Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id =:surveyId];
  s.Name = surveyName;
  try{
    update s;
  }catch (Exception e){
    Apexpages.addMessages(e);
  }
  return null;
} 


 //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
  //private static Testmethod void testUpdateSurveyName() {
  //    SurveyTestingUtil tu = new SurveyTestingUtil();
  //    Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
  //    Apexpages.Standardcontroller stc; 
  //    ViewSurveyController vsc = new ViewSurveyController(stc);
  //    vsc.surveyName = 'new name';
  //    system.assert(vsc.updateSurveyName() == null);
      
  //}
//------------------------------------------------------------------------------//      
public Pagereference updateSurveyThankYouAndLink(){
  Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id =:surveyId];
  s.thankYouText__c = surveyThankYouText;
  s.thankYouLink__c = surveyThankYouURL;
  try{
      update s;
  }catch(Exception e){
      Apexpages.addMessages(e);
  }
  return null;
}

//CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
  //private static Testmethod void testupdateSurveyThankYouAndLink() {
  //  SurveyTestingUtil tu = new SurveyTestingUtil();
  //  Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
  //  Apexpages.Standardcontroller stc; 
  //  ViewSurveyController vsc = new ViewSurveyController(stc);
  //  vsc.surveyThankYouText = 'new stuff';
  //  vsc.surveyThankYouURL = 'more new stff';
  //  system.assert(vsc.updateSurveyThankYouAndLink()==null);
  //}
  //------------------------------------------------------------------------------//    
  /** When requested from the page - when the user clicks on 'Update Order' -
      this function will reorganize the list so that it is displayed in the new order
   */
  public Pagereference refreshQuestionList(){
    setupQuestionList();
    return null;
   }

   /** 
    */
  //   public List<String> getResponses() {
  //     System.debug('Inside getResponses');
  //     List<SurveyQuestionResponse__c> qr = [Select Survey_Question__c, SurveyTaker__c, Response__c, Name From SurveyQuestionResponse__c limit 100];
  //     List<String> resp = new List<String>();
  //     for (SurveyQuestionResponse__c r : qr) {
  //         resp.add(r.Response__c);
  //     }
      
  //     return resp;
  // }  

    /** Class: question
    *  Retrieves the question information and puts it in the question object
    */      
    public class question{
      public String   name                   {get; set;}
      public String   id                           {get; set;}
      public String   question               {get; set;}
      public String   orderNumber            {get; set;}
      public String   choices                {get; set;}
      // public List<SelectOption> singleOptions{get; set;}
      public List<Parameters> singleOptions{get; set;}
      // public List<SelectOption> multiOptions {get; set;}
      public List<Parameters> multiOptions {get; set;}
      public Boolean  required               {get; set;}
      public String   questionType           {get; set;}    
      public String   surveyName               {get; set;}
      public String   renderFreeText             {get; set;}
        public String   renderSelectRadio      {get; set;}
        public String   renderSelectCheckboxes {get; set;} 
        public String   renderSelectRow        {get; set;}
      public List<String> responses              {get; set;}
      public String   singleOptionsForChart  {get; set;}
      public String   qResultsForChart         {get; set;} 
      public List<String> strList              {get; set;} // The question's option as a list of string
      //public List<Integer> resultsCounts       {get; set;} // The count of each response to a question's choices
      // public List<SelectOption> rowOptions   {get; set;}
      public List<Parameters> rowOptions   {get; set;}
      //public boolean  noData                 {get; set;}
      
        public question(){}

       /** Fills up the question object
       *  param:    Survey_Question__c 
       */     
     public question(Survey_Question__c sq) {
      name = sq.Name;
      id = sq.Id;
      System.debug('in Question found one with id '+id);
      question = sq.Question__c;
      orderNumber = String.valueOf(sq.OrderNumber__c+1);
      choices = sq.Choices__c;
      required = sq.Required__c;
      questionType = sq.Type__c;
      singleOptionsForChart = ' ';
   if (sq.Type__c=='Single Select--Vertical'){
              renderSelectRadio='true';
              singleOptions = stringToSelectOptions(choices);
              renderSelectCheckboxes='false';
              renderFreeText='false';
              renderSelectRow = 'false';
    }
   else if (sq.Type__c=='Multi-Select--Vertical'){        
              renderSelectCheckboxes='true';
              multiOptions = stringToSelectOptions(choices);
              renderSelectRadio='false';
              renderFreeText='false';
        renderSelectRow = 'false';
    }
   else if (sq.Type__c=='Single Select--Horizontal'){   
        renderSelectCheckboxes='false';
        rowOptions = stringToSelectOptions(choices);
        renderSelectRadio='false';
        renderFreeText='false';
        renderSelectRow = 'true';
    }
   else if (sq.Type__c=='Free Text'){
          renderFreeText='true';
          renderSelectRadio='false';
          renderSelectCheckboxes='false';
        renderSelectRow = 'false';
    }
      //responses= getResponses();
    }


     /** Splits up the string as given by the user and adds each option
        *  to a list to be displayed as option on the Visualforce page
        *  param: str   String as submitted by the user
        *  returns the List of SelectOption for the visualforce page
        */  
        // private List<SelectOption> stringToSelectOptions(String str){
          private List<Parameters> stringToSelectOptions(String str){
          strList = str.split('\n');
        
          // List<SelectOption> returnVal = new List<SelectOption>();
          List<Parameters> returnVal = new List<Parameters>();
          for(String s: strList){
              if (s!='') {
                  // returnVal.add(new SelectOption(s,s));
                  returnVal.add(new Parameters(s,s));
                  if (s != 'null' && s!= null) {
                      String sBis = s.replace(' ', '%20');
                      singleOptionsForChart += s.trim()+'|';
                  }
              }
          }
          singleOptionsForChart = singleOptionsForChart.substring(0, singleOptionsForChart.length()-1);
          return returnVal;
        } 
      }

      public class Parameters{
        private Map<String, Object> parameters = new Map<String, Object>();
        String str;

        public Parameters() { }

        public Parameters(String s, String t){
          this.str = s;
        }

        public void add(String name, Object value) {
            this.parameters.put(name, value);
        }
    
        /*public Object get(String name) {
            Object result = null;
    
            if(this.parameters.containsKey(name)) {
                result = this.parameters.get(name);
            }
            return result;
        }  */  
    
        public String serialize()
        {
            return JSON.serialize(parameters);      
        }
    
        public Parameters deserialize(String serialized)
        { 
            Parameters parameters = new Parameters();
            parameters.parameters = (Map<String, Object>) JSON.deserializeUntyped(serialized);
            return parameters;
        }
    }




 /** Fills up the List of questions to be displayed on the Visualforce page
   */   
  // List<question>
  @AuraEnabled(cacheable=true)
  public static String getAQuestion(Id surveyId) {
    qQuestion = '';
    qChoices ='';
    System.debug('Inside getAQuestion - 1 - surveyId ==>' + surveyId);   
    List<Survey_Question__c> allQuestionsObject = 
                                [Select s.Type__c, s.Id, s.Survey__c, s.Required__c, s.Question__c, 
                                s.OrderNumber__c, s.Name, s.Choices__c 
                                From Survey_Question__c s
                                //  Where s.Survey__c  = 'a2N4R000000pxUP' ORDER BY s.OrderNumber__c];
                                WHERE s.Survey__c =: surveyId ORDER BY s.OrderNumber__c];
System.debug('Inside getAQuestion - 2 - surveyId ==>' + surveyId);                                
System.debug('Inside getAQuestion - allQuestionsObject ==>'+allQuestionsObject);  



allQuestions = new List<question>();

Double old_OrderNumber = 0;
Double new_OrderNumber; 
Double difference = 0;
// Map<String, Object> parameters = new Map<String, Object>();

Integer i =0;
/* Make sure that the order number follow each other (after deleting a question, orders might not do so) */
for (Survey_Question__c q : allQuestionsObject){ 
    new_OrderNumber = q.OrderNumber__c;
    difference = new_OrderNumber - old_OrderNumber - 1;
    if (difference > 0) {
        Double dd = double.valueOf(difference);
        Integer newOrderInt = dd.intValue();
        q.OrderNumber__c -= Integer.valueOf(newOrderInt); 
    }
    old_OrderNumber = q.OrderNumber__c;
    question theQ = new question(q);
    allQuestions.add(theQ);   
    params.add(i+'', theQ);
    i++;
}

allQuestionsSize = allQuestions.size();
// System.debug('Inside getAQuestion - allQuestions ==>'+allQuestions);


// for(Integer i = 0; i < allQuestionsSize; i++){
//   System.debug(i+'- '+allQuestions[i]);
  
// }
// String serialized = JSON.serialize(parameters);
// System.debug('serialized ==>'+serialized);
// parameters = (Map<String, Object>) JSON.deserializeUntyped(serialized);

String serialized = params.serialize();
Parameters deserialized = params.deserialize(serialized);

return serialized;

// return JSON.serialize(allQuestions);
// return params;
} 




}

