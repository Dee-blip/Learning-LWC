/*created by rsharma because the method was part of non test class and hence deployment was failing
    */
@isTest
public class DocumentJsonControllerTest
{
    
    static{
        utilTestClass.insertCustomSettings();
    }

        static void DocumentJsonControllerTestMethod() {

        /*ContentVersion contentVersionObj = new ContentVersion();
        contentVersionObj.ContentURL='http://www.google.com/';
        contentVersionObj.Title = 'Google.com';   
        contentVersionObj.Tagcsv='public,private';         
        insert contentVersionObj;*/
        PageReference pageRef = Page.DocumentJson;
        Test.setCurrentPageReference(pageRef);
        DocumentJsonController fruc = new DocumentJsonController();
        
    }
}