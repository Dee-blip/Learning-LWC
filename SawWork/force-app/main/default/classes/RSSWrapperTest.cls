@isTest(SeeAllData = false)
public class RSSWrapperTest{
    public static testMethod void unitTest()
    {
        GSM_Custom_Settings__c gsmSetting1 = new GSM_Custom_Settings__c();
        gsmSetting1.Name = 'CRM_Integration';
        gsmSetting1.Value__c = '005A0000000NHQc';
        insert gsmSetting1;

        //RSSFormWrapper tempWrapper = new RSSFormWrapper();
        //RSSResponseGroupWrapper tempResponseGroupWrapper = new RSSResponseGroupWrapper();
        RSSQuestionResponse tempQRWrapper = new RSSQuestionResponse();
        tempQRWrapper.stringToListOFString('a,b,c,d,e,f');
        Survey__c surveyRSSTemplate = new Survey__c();
        surveyRSSTemplate.Name ='Apple';
        surveyRSSTemplate.RecordTypeId = [select id from RecordType where name = 'RSS Template' limit 1][0].id; //Need to have a record Type RSS Template
        surveyRSSTemplate.UniqueName__c = GuidUtil.NewGuid();
        surveyRSSTemplate.Submit_Response__c = ' temp ';
        insert surveyRSSTemplate;
        Survey_Question__c q = new Survey_Question__c();
        q.name = 'abcd';
        q.question__c='avbcd';
        q.type__c='Multi-Select--Vertical';
        q.Survey__c =surveyRSSTemplate.id;
        q.Choices__c = '1\n2\n3\n4\n5\n6';
        q.OrderNumber__c=1;
        insert q;
            
        SurveyTaker__c st = new SurveyTaker__c();
        st.Survey__c = surveyRSSTemplate.id;
        insert st;
        SurveyQuestionResponse__c res = new SurveyQuestionResponse__c();
        res.Survey_Question__c = q.id;
        res.SurveyTaker__c = st.id;
        res.Response__c='a,b,c,d,e,f,g';
        insert res;
        
        tempQRWrapper = new RSSQuestionResponse([select Survey_Question__r.Type__c,Survey_Question__r.Choices__c, Response__c from SurveyQuestionResponse__c limit 1]);
    }
}