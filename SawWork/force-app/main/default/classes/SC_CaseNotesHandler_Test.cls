@isTest
public class SC_CaseNotesHandler_Test {
    static testmethod void contentNotesTest(){
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('Test Notes Account1');   
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        accList.add(acc);
        
        acc = utilTestClass.CreateAccount('Test Notes Account2');   
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        accList.add(acc);
        insert accList;
        
        Contact con = utilTestClass.CreateContact('FNotesName1','LNotesName1');
        con.AccountId = accList[0].Id;
        insert con;
        
        
    	Case c;
        List<Case> caseList = new List<Case>();
        Id RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        for(integer i=0;i<3;i++){
            c = new Case();
            c.subject = 'Test 1';
            c.Description = 'Test 2';
            c.RecordTypeId = RecordTypeId;
            c.AccountId = accList[0].Id;
            caseList.add(c);
        }
        insert caseList;
        
        List<Id> caseIdList = new List<Id>();
        
        for(case eachCase :caseList){
            caseIdList.add(eachCase.Id);
        }
        
        list<contentNote> docList = new List<contentNote>();
		ContentNote conDoc;
        FeedItem fi;
        List<FeedItem> feedItemList = new List<FeedItem>();
		for(integer i=0;i<3;i++){
   			conDoc = new ContentNote(); 
   			conDoc.Title ='Managed Security NNotes 12345';
   			conDoc.Content = Blob.valueOf('This is a test note 12345');
   			docList.add(conDoc); 
            
            fi = new FeedItem();
            fi.ParentId = caseList[i].Id;
            fi.Body = 'This is a test post.';
            fi.Status = 'Published';
            feedItemList.add(fi);
		}
		
		insert docList;

		List<Id> contDocId = new List<Id>();
		for(contentNote eachDoc :docList){
    		contDocId.add(eachDoc.Id);
		}
        
		List<ContentDocumentLink> conLink = new List<ContentDocumentLink>([Select id,ContentDocumentId,LinkedEntityId from ContentDocumentLink where ContentDocumentId IN :contDocId]);
		ContentDocumentLink clink;
		List<ContentDocumentLink> linkUpdateList = new List<ContentDocumentLink>();
		for(integer i=0;i<conLink.size();i++){	
        	clink = new ContentDocumentLink();
    		clink.LinkedEntityId = caseIdList[i];
        	clink.ContentDocumentId = conLink[i].ContentDocumentId;
        	clink.shareType='I';
    		linkUpdateList.add(clink);
		}
        test.startTest();
        insert feedItemList;
		insert linkUpdateList;
        delete docList[0];
        test.stopTest();
    }
}