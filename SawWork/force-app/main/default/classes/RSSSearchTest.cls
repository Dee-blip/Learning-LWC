@isTest(SeeAllData = false)
public class RSSSearchTest
{
    static testmethod void unitTestRSSTemplateSearch()
    {
        //18.7 getting the Id of CRM_Integration from Custom Meta Data instead of Custom Settings
        /*GSM_Custom_Settings__c gsmcs = new GSM_Custom_Settings__c();
        gsmcs.Name = 'CRM_Integration';
        gsmcs.Value__c = '005A0000000NHQc';
        insert gsmcs;*/
        RSSTemplateSearch search = new RSSTemplateSearch();
        EB_FilterObject  temp = search.searchFields;
        SI_QueryBuilder filter = new SI_QueryBuilder();
        filter.pageController=search;
        filter.inputQuery=search.InputQuery;
        filter.DefaultOrderBy = 'field';
        filter.DefaultSortOrderDirection ='asc';
        filter.limitSOQL = 5000;
        search.setComponentController(filter);
        search.getMyComponentController();
        search.getRSSTemplates();
        search.first();
        search.last();
        search.previous();
        search.next();
        search.SetObjControllerNull();
        search.sortField = 'name';
        String sortField = search.sortField;
        search.hasNext = search.hasPrevious;
        search.hasPrevious = search.hasNext;
        search.toggleSortOrder();
        search.SetObjControllerNull();
        Boolean tempB =search.hasNext;
        tempB = search.hasPrevious;
        search.first();
        search.last();
        search.previous();
        search.next();
        search.clearSearch();
        search.PostProcessApplySearch();
        search.changeCheckBoxValue();
        search.goToCreateNewSurveyPage();
        search.ShowMyTemplates=false;
        search.ChangeInputString();
        search.ShowMyTemplates=true;
        search.ChangeInputString();
        search.objController = null;
        search.getRSSTemplates();
        search.getDebugRender();
        eRSS__c cs = new eRSS__c();
        cs.Name= 'eRSS';
        cs.ShowDebug__c = True;
        insert cs;
        search.getDebugRender();
        search.deleteTemplate();
        Survey__c RSSTemplate = new Survey__c();
        RSSTemplate.Name ='Apple';
        RSSTemplate.Submit_Response__c = ' temp ';
        insert RSSTemplate;
        SurveyTaker__c st = new SurveyTaker__c();
        st.Survey__c =RSSTemplate.id;
        insert st;
        search.DeleteTemplateId =RSSTemplate.id;
        search.deleteTemplate();
        delete st;
        search.DeleteTemplateId =RSSTemplate.id;
        search.deleteTemplate();
        

    }
    //Changes by shprasan: views for PreSales, PostSales and superUser
    static testmethod void unitTestRSSFormSearch()
    {
        RSSFormSearchController search = new RSSFormSearchController();
        search.getsearchFields();
        SI_QueryBuilder filter = new SI_QueryBuilder();
        filter.pageController=search;
        filter.inputQuery=search.InputQuery;
        filter.DefaultOrderBy = 'field';
        filter.DefaultSortOrderDirection ='asc';
        filter.limitSOQL = 5000;
        search.setComponentController(filter);
        search.getMyComponentController();
        search.getRSSForms();
        search.first();
        search.last();
        search.previous();
        search.next();
        search.SetObjControllerNull();
        search.sortField = 'name';
        String sortField = search.sortField;
        search.hasNext = search.hasPrevious;
        search.hasPrevious = search.hasNext;
        search.toggleSortOrder();
        search.SetObjControllerNull();
        Boolean tempB = search.hasNext;
        tempB = search.hasPrevious;
        search.first();
        search.last();
        search.previous();
        search.next();
        search.clearSearch();
        search.PostProcessApplySearch();
        search.goToCreateNewRSSFormPage();
        search.goToOUploadPage();

        //Start of changes by shprasan
        String fieldToSort;
        search.goToDownloadOfflinePage();
        // All views for PostSales
        search.PostSales = true;
        search.sortField = null;
        search.SelectedView = null; 
        search.ChangeInputString();        
        search.SelectedView = 'My Open Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'Submitted Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'Published Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'My Published Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'All'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();

        // All views for PreSales
        search.PostSales = false;
        search.PreSales = true;           
        search.sortField = null;  
        search.SelectedView = null;   
        search.ChangeInputString();
        search.SelectedView = 'My Open Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'Submitted Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'Published Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'My Submitted Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'All'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();

        //All views for Super User
        search.SuperUser = true;
        search.PreSales = false; 
        search.sortField = null;  
        search.SelectedView = null;     
        search.ChangeInputString();
        search.SelectedView = 'My Open Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'All Submitted Published Forms'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();
        search.SelectedView = 'All'; 
        fieldToSort = search.FieldToSort;
        search.ChangeInputString();

        //testing the deleteRSSForm function
        RSS_Form__c RSSForm = new RSS_Form__c();
        RSSForm.Name = 'Test RSSForm';
        RSSForm.UniqueName__c = GuidUtil.NewGuid();
        RSSForm.Published__c = false;
        RSSForm.Locked__c = false;
        RSSForm.DigitalProperty__c = 'www.apple.com';
        RSSForm.Customer_Technical_Contact_Name__c = 'test';
        RSSForm.Customer_Technical_Contact_Details__c = 'test';
        insert RSSForm;
        
        search.DeleteFormId = RSSForm.ID; 
        search.deleteRSSForm();        
        //search.ChangeInputString();
        //search.SelectedView = 'Published Forms'; 
        //search.ChangeInputString();
        //search.SelectedView = 'All Forms'; 
        //search.ChangeInputString();

        //End of changes by shprasan
        search.objController = null;
        search.getRSSForms();
        search.getDebugRender();
        eRSS__c cs = new eRSS__c();
        cs.Name= 'eRSS';
        cs.ShowDebug__c = True;
        insert cs;
        search.getDebugRender();
    }  
}