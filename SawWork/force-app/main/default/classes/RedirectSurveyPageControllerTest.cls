@isTest(SeeAllData=false)
public class RedirectSurveyPageControllerTest{
    public static testMethod void unitTest()
    {
        RSSTemplateTest.initClass();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(RSSTemplateTest.RSSTemplate);
        RedirectSurveyPageController controller = new RedirectSurveyPageController(sc);
        PageReference pageRef = Page.RedirectSurveypage;
        pageRef.getParameters().put('id',RSSTemplateTest.RSSTemplate.id);
        Test.setCurrentPage(pageRef);
        sc = new ApexPages.StandardController(RSSTemplateTest.RSSTemplate);
        controller = new RedirectSurveyPageController(sc);
        Survey__c RSSTemplate = new Survey__c();
        RSSTemplate.Name ='Apple';
        RSSTemplate.RecordTypeId = [select id from RecordType where name = 'Product Approval' limit 1][0].id; //Need to have a record Type RSS Template
        RSSTemplate.UniqueName__c = GuidUtil.NewGuid();
        RSSTemplate.Submit_Response__c = ' temp ';
        insert RSSTemplate;
         sc = new ApexPages.StandardController(RSSTemplate);
        controller = new RedirectSurveyPageController(sc);
    }
}