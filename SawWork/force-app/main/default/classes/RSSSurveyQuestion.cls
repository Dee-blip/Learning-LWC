Public class RSSSurveyQuestion
{
    public Survey_Question__c question {get; set;}
    public List<SelectOption> choices  {get; set;}
    Public static Integer AutoNumber =0;
    public Integer UniqueNumber {get;set;}
    public String UniqueName {get;set;}
    public RSSSurveyQuestion()
    {
        question = new Survey_Question__c();
        AutoNumber++;
    UniqueNumber = AutoNumber;
    UniqueName = GuidUtil.NewGuid();
       
    }
    public void UpdateChoices()
    {
        if(question.Type__c!='Free Text')
        Choices = stringToSelectOptions(question.Choices__c)  ;
    }
    public RSSSurveyQuestion(Survey_Question__c q)
    {
        question = q;
        if(q.Type__c!='Free Text')
        Choices = stringToSelectOptions(q.Choices__c)  ;
        AutoNumber++;
        UniqueNumber = AutoNumber;
        UniqueName = GuidUtil.NewGuid();
    }
    private List<SelectOption> stringToSelectOptions(String str){
        List<String> strList;
        List<SelectOption> returnVal = new List<SelectOption>();
        if(!String.isBlank(str))
        {
        strList = str.split('\n');
        
        
        for(String s: strList){
        if (s!='') {
          returnVal.add(new SelectOption(s.trim(),s.trim()));          
        }
        }
        }
        //system.assertEquals(returnVal,null);
        return returnVal;
    }
}