@isTest(seeAllData = false)
public class SF1_DeleteFilesTestClass {
	 
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod()
    {      
        System.runAs(dmlUser) {
            user accOwner = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
            accOwner.IsActive = true;
            insert accOwner;
            
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOwner.Id;
            
            acc.website = 'www.fileDeletion.com';
            insert acc;
            
            //Opportunity Creation
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;     
        }       
    }
    
    public static testmethod void retrieveAndDeleteContentDocument(){
        User u = [Select id from user where alias = 'MUSER'][0];
        System.runAs(u){
            Opportunity oppId = [select id, name from Opportunity where name = '__Test Opportunity'][0];
            order_approval__c orderApproval = [Select Id from order_approval__c where Associated_Opportunity__c  = :oppId.id][0];
            
            ContentDocument cd = new ContentDocument();
            
            //Create Document
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            Insert cv;
            
            //Get Content Version
            ContentVersion cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id][0];
            
            //Create Content Document Link
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = orderApproval.Id;
            cdLink.ContentDocumentId = cvList.ContentDocumentId;
            cdLink.shareType = 'I';
            insert cdLink;
                      
         	String result = '';
            List<ContentDocument> cdlList = SF1_DeleteFiles.getContentDocumentRecords(orderApproval.Id);
            /*
            List<String> idList = new List<String>();
            for(ContentDocument cdl : cdlList){
                String cdId = ''+cdl.Id;
                idList.add(cdId);
            }
            */
            String header = SF1_DeleteFiles.getDataTableHeader();
            result = SF1_DeleteFiles.deleteContentFiles(JSON.serialize(cdlList));           
        }
		        
    }
}