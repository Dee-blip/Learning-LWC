public class RSSQuestionResponse
{
Public SurveyQuestionResponse__c response {get; set;}
Public List<SelectOption> Choices {get{if(Choices==null) { Choices = new List<SelectOption>();} return Choices;}set;}
Public String answer { get { if(response==null) { return '';} return response.Response__c;} set { response.Response__c = value; } }
Public Integer order { get { if(response==null) { return 0;}return Integer.valueOf(response.Survey_Question__r.OrderNumber__c +1);}}
public List<String> CheckBoxValues {get{ CheckBoxValues = stringToListOFString(response.Response__c);return CheckBoxValues;}set{ CheckBoxValues = value; response.Response__c = String.join(CheckBoxValues,',');}}
Public static Integer AutoNumber =0;
public Integer UniqueNumber {get;set;}
public RSSQuestionResponse ()
{
    AutoNumber++;
    UniqueNumber = AutoNumber;
}
public RSSQuestionResponse (SurveyQuestionResponse__c res)
{
    response = new SurveyQuestionResponse__c();
    AutoNumber++;
    UniqueNumber = AutoNumber;
    system.debug('#########K1' + Choices);
    response = res;
    if(res.Survey_Question__r.Type__c!='Free Text')
    Choices = stringToSelectOptions(res.Survey_Question__r.Choices__c)  ;
    system.debug('#########K2' + Choices);
    if(res.Survey_Question__r.Type__c=='Multi-Select--Vertical')
    {
        if(response.Response__c!=null)
        CheckBoxValues = stringToListOFString(response.Response__c);
        else
        CheckBoxValues = new List<String>();

    }
    if(res.Survey_Question__r.Type__c=='PickList')
    {
        Choices.add(0,new SelectOption('','--SELECT--'));
    }
    
    system.debug('#########K3' + Choices);
}
public List<SelectOption> stringToSelectOptions(String str){
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
    public List<String> stringToListOFString(String str){
    
      List<String> strList = new List<String>();
      if(!String.isBlank(str))
      {
      strList = str.split(',');
      for(String s:strList)
      {
      s=s.trim();
      }

      
      } 
      return strList;
    }
    
    
}