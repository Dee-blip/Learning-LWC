public class RSSFormWrapper
{
public SurveyTaker__c ProductForm {get;set;}
public List< RSSResponseGroupWrapper > responseGroupWrappers {get;set;}
Public static Integer AutoNumber =0;
public Integer UniqueNumber {get;set;}
public RSSFormWrapper()
{
responseGroupWrappers = new List<RSSResponseGroupWrapper>();
ProductForm  = new SurveyTaker__c();
AutoNumber++;
UniqueNumber = AutoNumber;
}
public RSSFormWrapper(SurveyTaker__c rf)
{
    ProductForm = rf;
    responseGroupWrappers = new List<RSSResponseGroupWrapper>();
    AutoNumber++;
        UniqueNumber = AutoNumber;
}

}