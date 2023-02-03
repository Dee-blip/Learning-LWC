/*=====================================================================================================+
    Class name          :   SC_UpdateArticle_BatchTest 
    Author              :   Pinkesh Rathore
    Created             :   07-Nov-17
    Purpose             :   This test class is used to cover code for below Components
                            1. SC_UpdateArticle_Batch
+=====================================================================================================*/
@isTest(seeAllData = False)
public class SC_UpdateArticle_BatchTest {
    
    public static testmethod void testUpdateArticle(){
        List<Knowledge__kav> lCB = new List<Knowledge__kav>();
        for(Integer i=0; i<5; i++){
            Knowledge__kav cb = new Knowledge__kav();
            cb.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
            cb.Title = 'ABC Some Random Community Blog XYZ' + i;
            cb.UrlName = 'ABC-Some-Random-Community-Blog-XYZ' + i;
            cb.Description__c = 'Test Description';
            cb.IsVisibleInPkb = true;
            cb.IsVisibleInCsp = true;
            cb.IsVisibleInPrm = true;
            cb.Visibility__c = 'Internal';
            lCB.add(cb);
        }
        insert lCB;
        
        List<Knowledge__kav> lToBePublished = [Select id, KnowledgearticleId from Knowledge__kav WHERE PublishStatus = 'Draft'];
        for(Knowledge__kav eachrec : lToBePublished)
        try{
                KbManagement.PublishingService.publishArticle(eachrec.knowledgearticleId, true);
        }
        Catch(Exception ex){
        }
        
       
        Test.startTest(); 
        String Results = Database.executeBatch(new SC_UpdateArticle_Batch());
        
        Test.stopTest();
    }
}