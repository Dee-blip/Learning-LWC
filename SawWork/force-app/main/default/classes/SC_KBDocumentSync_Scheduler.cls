/*=====================================================================================================+
    Class name                :   SC_KBDocumentSync_Scheduler 
    Author                    :   Akamai
    Created                   :   10-Mar-14
    Purpose                   :   Synching Knowledge Article to Document Folder - For Luna          

    Last Modified   Developer   Purpose            
    =============   =========   =======
    15-Mar-15       Jay       CR:2789994 (sync to DR.added new article types and added couple of fields to current)
    26-Apr-15       Jay       CR:3001403 (Modified logic to avoid concurrent limit issue)
    12-Nov-15     Himanshu  CR:3151921 (Moved Batch Size value to custom setting) 
    16-Jan-19     Vamsee    ESESP-1779 (Lightning Knowledge Migration)
+=====================================================================================================*/   

global class SC_KBDocumentSync_Scheduler implements Schedulable{

  public boolean isTestCall=false;

   global void execute(SchedulableContext SC) {
      
      // Get the Batch Size from Custom Setting
      Integer KBBatchSize = Integer.valueOf(SC_Autogen_Running_Freq__c.getValues('KBSyncBatchSize-Document').Batch_Size__c);
     
      // Get the no of days freq from which Batch will Pick Article from Custom Setting
      Integer KBBatchFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues('KBSyncBatchSize-Document').Subsequent_Freq_in_Days__c);
     
        //Sync How To Articles to Documents
    String query = 'Select h.Title,h.AKAM_Article_Number__c ,h.Summary,h.Applies_To__c ,h.Description__c ,h.How_To_Procedure__c , h.AKAM_Modified_Date__c ,h.keywords__c, (Select toLabel(DataCategoryName),toLabel(DataCategoryGroupName) From DataCategorySelections) From Knowledge__kav h where Recordtype.Developername = \'How_To\' AND language = \'en_US\' and publishstatus = \'online\' and h.Visibility__c=\'External\'';
        
        // If KBBatchSize = null then Full Synch otherwise based on Batch Size
        //query = (KBBatchFreq == null) ? query : query + ' AND LastModifiedDate = LAST_N_DAYS:' + KBBatchFreq + ' ';
        
        if(isTestCall) query+=' order by createdDate asc limit 1';
        
        /* There are many article types which needs to be synced. But SFDC has limit of 
         * 5 concurrent limits. Unfortunately when we do database.executeBatch it tries to execute batch job.
         * if there are 5 processes running , then it will FAIL. Ideally it should be placed in queue.
         * APEX flex queue feature released in Spring 15 fixes this , but still unstable.
         * So going for sequential execution. one aricle type will be synced. In finish job of that
         * article type , another batch job for article type starts.
         * 
         * Other option which we evaluated is to check if number of job running is 0 and then try
         * to execute all 5 at a time. But if we go this approach then we have following limits.
         * 1.When we add 6th article type , this will break
         * 2.Since we will consume all limits , others will get impacted and all other jobs will fail.
         * 3. after this sycn , perforce sync needs to run. so this cant be option
       */ 
       
    set<String> totalItemsToProcess = new set<String>();
        totalItemsToProcess.add('HT');
        totalItemsToProcess.add('TP');
        totalItemsToProcess.add('QA');
        totalItemsToProcess.add('RN');
        totalItemsToProcess.add('GD');
        
        SC_KBDocumentSync_Batch batchApexStart = new SC_KBDocumentSync_Batch(query, 'HT',totalItemsToProcess,'HT'); 
        Database.executeBatch(batchApexStart,KBBatchSize);
  }
  
  //This method is used to delete those documents whose corresponding article has been archivedor deleted ßin the Knowledge Base  
  public void deleteArticles() {
        
        //Set containing article numbers articles 
      Set<String> articleList=new Set<String>();
        
        //List of the documents in External KB Folder
      List<Document> deleteDocs=new List<Document>();
      
        Folder fold=[select id from folder where name = 'External KB Articles' limit 1];
        String foldID=fold.id;
      String artNumber;
        
        //Retrieve the list of Articles in Knowledge Base
        for(Knowledge__kav eachArticle : [select AKAM_Article_Number__c from Knowledge__kav where language = 'en_US' and publishstatus = 'online' and Visibility__c='External']){
            articleList.add((eachArticle.AKAM_Article_Number__c).replaceFirst('^0+',''));
        }
      
        /*    
        for(How_To__kav ht : [select articleNumber from How_To__kav where language = 'en_US' and publishstatus = 'online' and Visibility__c='External']) {
        articleList.add((ht.ArticleNumber).replaceFirst('^0+',''));
      }
      for(Question_Answer__kav ht : [select articleNumber from Question_Answer__kav where language = 'en_US' and publishstatus = 'online' and Visibility__c='External']) {
        articleList.add((ht.ArticleNumber).replaceFirst('^0+',''));
      }
      for(Release_Notes__kav ht : [select articleNumber from Release_Notes__kav where language = 'en_US' and publishstatus = 'online' and Visibility__c='External']) {
        articleList.add((ht.ArticleNumber).replaceFirst('^0+',''));
      }
      for(Troubleshooting_Procedure__kav ht : [select articleNumber from Troubleshooting_Procedure__kav where language = 'en_US' and publishstatus = 'online' and Visibility__c='External']) {
        articleList.add((ht.ArticleNumber).replaceFirst('^0+',''));
      }
        for(Glossary_Definition__kav ht : [select articleNumber from Glossary_Definition__kav where language = 'en_US' and publishstatus = 'online' and Visibility__c='External']) {
        articleList.add((ht.ArticleNumber).replaceFirst('^0+',''));
      }*/
        
        //Retrieve the List of documents
      for(Document doc : [select name from Document where folderid =: foldID]) {
        artNumber = (doc.name).substring(3,(doc.name).indexOf('_html'));
            
            //Compare document name against the list of article numbers
      if(articleList.contains(artNumber) == false)
        deleteDocs.add(doc);
      }
        
        //Delete old documentsß
        delete deleteDocs;
    }
}