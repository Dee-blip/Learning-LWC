/*=====================================================================================================+
    Class name          :   SC_KBDocumentSync_Batch 
    Author              :   Vijetha Vijayendran
    Created             :   02-Jan-14
    Purpose             :   Initial Development
     
    Last Modified   Developer   Purpose            
    =============   =========   =======
    15-March-2015   JAY         CR:2789994  New article type introduction
    26-April-2015   JAY         CR:3001403  (Modfiied logic to finish method avoid concurrent limit issue)
    12-Nov-15       Himanshu    CR:3151921 (Moved Batch Size value to custom setting) + Synch Image from Article to Document
    08-Jan-2016     Sonia       CR:3265081  Error when accessing KB article in Luna Portal
    25-Nov-2016     Sonia       CR 3595991  Modified the batch class to allow callouts for Image conversion 
    17-Jan-2019     Vamsee      ESESP-1779  Lightning Knowledge Migration
+===================================================================================================*/

global class SC_KBDocumentSync_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global string query; 
    global string objName;
    Map<String,Document> docMap;
    String foldID;
    set<String> totalItemsTOCompleteList;
    String currentProcessing;
    global SC_KBDocumentSync_Batch (String q, String o) {
        query = q;
        objName = o;
        Folder fold=[select id from folder where name = 'External KB Articles' limit 1];
        foldID=fold.id;
        
        //Map of the document name and their objects in External KB Folder
        docMap=new Map<String,Document>();
        
        if(!Test.isRunningTest()) {
            
            for(Document doc : [select id,name from Document where folderid =: foldID]) {
                docMap.put(doc.name,doc);
            }
        }
        else
        {
            for(Document doc : [select id,name from Document where folderid =: foldID limit 1]) {
                docMap.put(doc.name,doc);
            }
        }
    } 
    
    global SC_KBDocumentSync_Batch (String q, String o,set<String> totalItemsToProcess,String currentPro) {
        totalItemsTOCompleteList = totalItemsToProcess;
        currentProcessing = currentPro;
        query = q;
        objName = o;
        Folder fold=[select id from folder where name = 'External KB Articles' limit 1];
        foldID=fold.id;
        
        //Map of the document name and their objects in External KB Folder
        docMap=new Map<String,Document>();
        
        if(!Test.isRunningTest()) {
        
            for(Document doc : [select id,name from Document where folderid =: foldID]) {
                docMap.put(doc.name,doc);
            }
        }
        else
        {
            for(Document doc : [select id,name from Document where folderid =: foldID limit 1]) {
                docMap.put(doc.name,doc);
            }
            
        }
    }
    
    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        if(objName.equals('HT')) {
            insertHowTo(scope);
        }
        if(objName.equals('TP')) {
            insertTroubleshootingProc(scope);
        }
        if(objName.equals('QA')) {
            insertQuesAnswer(scope);
        }
        if(objName.equals('RN')) {
            insertReleaseNotes(scope);
        }
        if(objName.equals('GD')) {
            insertGlossaryDefinition(scope);
        }
        
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC) {
        
        // Get the Batch Size from Custom Setting
     Integer KBBatchSize = Integer.valueOf(SC_Autogen_Running_Freq__c.getValues('KBSyncBatchSize-Document').Batch_Size__c);
     
     // Get the no of days freq from which Batch will Pick Article from Custom Setting
     Integer KBBatchFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues('KBSyncBatchSize-Document').Subsequent_Freq_in_Days__c);
     
     // String to set to pick KB Articles from N Days
     string setKBPickDay = ' AND LastModifiedDate = LAST_N_DAYS:' + KBBatchFreq + ' ';
        
        totalItemsTOCompleteList.remove(currentProcessing);
        String currentProcessingAgain ;
        
        if (totalItemsTOCompleteList != null && totalItemsTOCompleteList.size() == 0){
           
           if(!Test.isRunningTest()) {
                SC_KBDocumentSync_Scheduler c = new SC_KBDocumentSync_Scheduler();
                c.deleteArticles();
           }
        }
        else {
            for(String s :totalItemsTOCompleteList){
                currentProcessingAgain = s;
                break;
            }
            if (currentProcessingAgain == 'TP'){
                
                //Sync Troubleshooting Procedure
                query = 'Select t.Title,t.AKAM_Article_Number__c ,t.Summary,t.Applies_To__c ,t.Symptoms__c,t.Troubleshooting_Guide_LTA__c ,t.AKAM_Modified_Date__c ,t.Keywords__c ,t.Explanation__c , (Select toLabel(DataCategoryName),toLabel(DataCategoryGroupName) From DataCategorySelections) From Knowledge__kav t where Recordtype.Developername = \'Troubleshooting_Procedure\' AND language = \'en_US\' and publishstatus = \'online\' and t.Visibility__c=\'External\'';
                
                // If KBBatchSize = null then Full Synch otherwise based on Batch Size
                //query = (KBBatchFreq == null) ? query : query + setKBPickDay;
                
                if(Test.isRunningTest()) query+=' order by createdDate asc limit 1';
                
                SC_KBDocumentSync_Batch batchApex2= new SC_KBDocumentSync_Batch(query, 'TP',totalItemsTOCompleteList,currentProcessingAgain);
                Database.executeBatch(batchApex2,KBBatchSize); 
            }    
             if (currentProcessingAgain == 'QA'){
                
                //Sync Question and Answer
                query = 'Select q.Title,q.AKAM_Article_Number__c ,q.Summary,q.Question_Answer_Question__c ,q.Question_Answer_Answer__c , q.AKAM_Modified_Date__c ,q.Keywords__c, (Select toLabel(DataCategoryName),toLabel(DataCategoryGroupName) From DataCategorySelections),q.Question_Answer_Answer_LTA__c ,Legacy_ID__c  From Knowledge__kav q where Recordtype.Developername = \'Question_Answer\' AND language = \'en_US\' and publishstatus = \'online\' and q.Visibility__c=\'External\'';
                
                // If KBBatchSize = null then Full Synch otherwise based on Batch Size
                //query = (KBBatchFreq == null) ? query : query + setKBPickDay;
                
                if(Test.isRunningTest()) query+=' order by createdDate asc limit 1';
                
                SC_KBDocumentSync_Batch batchApex3= new SC_KBDocumentSync_Batch(query, 'QA',totalItemsTOCompleteList,currentProcessingAgain);
                Database.executeBatch(batchApex3,KBBatchSize);
            }     
             if (currentProcessingAgain == 'RN'){
                
                //Sync Release Notes
                query = 'Select h.Title,h.AKAM_Article_Number__c ,h.Summary,h.Release_Notes_What_s_New__c ,h.Release_Notes_Enhancements__c ,h.Release_Notes_Bug_Fixes__c , h.AKAM_Modified_Date__c ,h.Release_Notes_Release_Date__c ,h.Keywords__c , (Select toLabel(DataCategoryName),toLabel(DataCategoryGroupName) From DataCategorySelections) From Knowledge__kav h where Recordtype.Developername = \'Release_Notes\' AND language = \'en_US\' and publishstatus = \'online\' and h.Visibility__c=\'External\'';
                
                // If KBBatchSize = null then Full Synch otherwise based on Batch Size
                //query = (KBBatchFreq == null) ? query : query + setKBPickDay;
                
                if(Test.isRunningTest()) query+=' order by createdDate asc limit 1';
                
                SC_KBDocumentSync_Batch batchApex4= new SC_KBDocumentSync_Batch(query, 'RN',totalItemsTOCompleteList,currentProcessingAgain);
                Database.executeBatch(batchApex4,KBBatchSize);
            }     
             if (currentProcessingAgain == 'GD'){
                
                //Sync GLossary defintion Notes
                query = 'Select h.Title,h.AKAM_Article_Number__c ,h.Summary, h.AKAM_Modified_Date__c ,h.Keywords__c ,h.Glossary_Definition_Term__c ,h.Internal_Notes__c ,h.Applies_To__c ,h.Definition__c, (Select toLabel(DataCategoryName),toLabel(DataCategoryGroupName) From DataCategorySelections) From Knowledge__kav  h where Recordtype.Developername = \'Glossary_Definition\' AND language = \'en_US\' and publishstatus = \'online\' and h.Visibility__c=\'External\'';
                
                // If KBBatchSize = null then Full Synch otherwise based on Batch Size
                //query = (KBBatchFreq == null) ? query : query + setKBPickDay;
                
                if(Test.isRunningTest()) query+=' order by createdDate asc limit 1';
                
                SC_KBDocumentSync_Batch batchApex5= new SC_KBDocumentSync_Batch(query, 'GD',totalItemsTOCompleteList,currentProcessingAgain);
                Database.executeBatch(batchApex5,KBBatchSize);
             }     
        }
    }
    
    //Sync How To Articles
    public void insertHowTo(List<sObject> scope) {
        //Create new lists to insert and update documents
        List<Document> docListInsert=new List<Document>();
        List<Document> docListUpdate=new List<Document>();
        
        List<Knowledge__kav> ht=scope;
        for(Knowledge__kav var : ht) {
            Document eachDoc=new Document();
            String cst='';
            String product='';
            String articleID=(var.AKAM_Article_Number__c).replaceFirst('^0+','');
            String docName='kb_'+articleID+'_html';
            for(Knowledge__DataCategorySelection dcs : var.DataCategorySelections) {
                if(dcs.DataCategoryGroupName == 'Customer Solution Topics') {
                    cst=cst+dcs.DataCategoryName+',';
                }
                if(dcs.DataCategoryGroupName == 'Product') {
                    product=product+dcs.DataCategoryName+',';
                }
            }
            
            //Generate the html
            String body = '<html><head><title>#'+articleID+':'+var.Title+'</title>';
            body=body+'<meta name="Products" content="'+product+'">';
            body=body+'<meta name="Description" content="';
            body=body+var.Title;
            body=body+'">\n<meta name="CustomerSolutionTopics" content="'+cst+'">';
            //Added by Sonia for CR 3265081 - fix encoding issues in document sync
            body=body+'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
            body=body+'<meta name="ArticleID" content="'+articleID+'">';
            body=body+'<meta name="LMD" content="'+var.AKAM_Modified_Date__c+'">';
            //new keywords section .added by JAY for CR2789994
            if (var.Keywords__c != null)
                body=body+'<meta name="Keywords" content="'+var.Keywords__c +'">';
            body=body+'</head><body>';
            body=body+'<h2>Applies To</h2><p>';
            if(String.isNotEmpty(var.Applies_To__c)) 
                body=body+var.Applies_To__c;
            body=body+'</p><h2>Description</h2><p>';
            if(String.isNotEmpty(var.Description__c)) 
                body=body+var.Description__c;
            body=body+'</p><h2>Procedure</h2><p>';
            if(String.isNotEmpty(var.How_To_Procedure__c)) 
                body=body+var.How_To_Procedure__c;
            body=body+'</p></body></html>';
            
            if(!Test.isRunningTest()){
                // Calling Image Converter Method to get the Complete Image
                body= SC_Utility.ImageConverter(body);
            }

            Blob bodyBlob=Blob.valueOf(body);
            
            //If document already exists, update otherwise insert
            if(docMap.containsKey(docName)) {
                eachDoc=docMap.get(docName);
                eachDoc.Body=bodyBlob;
                eachDoc.name=docName;
                docListUpdate.add(eachDoc);
            }
            else {
                eachDoc.Name=docName;
                eachDoc.Body=bodyBlob;
                eachDoc.FolderID=foldID;
                eachDoc.Type='html';
                docListInsert.add(eachDoc);  
            }
        }
        
        if(docListInsert.size()>0)
            insert docListInsert;
        if(docListUpdate.size()>0)
            update docListUpdate; 
    }
    public void insertTroubleshootingProc(List<sObject> scope) {
        //Create new lists to insert and update documents
        List<Document> docListInsert=new List<Document>();
        List<Document> docListUpdate=new List<Document>();
        List<Knowledge__kav> tp=scope;
       
        for(Knowledge__kav var : tp)
        {
            Document eachDoc=new Document();
            String cst='';
            String product='';
            String articleID=(var.AKAM_Article_Number__c).replaceFirst('^0+','');
            String docName='kb_'+articleID+'_html';
            for(Knowledge__DataCategorySelection dcs : var.DataCategorySelections) {
                if(dcs.DataCategoryGroupName == 'Customer Solution Topics') {
                    cst=cst+dcs.DataCategoryName+',';
                }
                if(dcs.DataCategoryGroupName == 'Product') {
                    product=product+dcs.DataCategoryName+',';
                }
            }
            
            //Generate the html
            String body = '<html><head><title>#'+articleID+':'+var.Title+'</title>';
            body=body+'<meta name="Products" content="'+product+'">';
            body=body+'<meta name="Description" content="';
            if(String.isNotEmpty(var.Symptoms__c )) 
                body=body+var.Symptoms__c ;
            body=body+'">\n<meta name="CustomerSolutionTopics" content="'+cst+'">';
            //Added by Sonia for CR 3265081 - fix encoding issues in document sync
            body=body+'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
            body=body+'<meta name="ArticleID" content="'+articleID+'">';
            body=body+'<meta name="LMD" content="'+var.AKAM_Modified_Date__c+'">';
            //new keywords section .added by JAY for CR2789994
            if (var.Keywords__c != null)
                body=body+'<meta name="Keywords" content="'+var.Keywords__c +'">';
            body=body+'</head><body>';
            body=body+'<h2>Symptoms</h2><p>';
            if(String.isNotEmpty(var.Symptoms__c )) 
                body=body+var.Symptoms__c ;
            body=body+'</p><h2>Applies To</h2><p>';
            if(String.isNotEmpty(var.Applies_To__c)) 
                body=body+var.Applies_To__c;
            body=body+'</p><h2>Explanation</h2><p>';
            //modified by Jay. added new field for CR2789994
            if(String.isNotEmpty(var.Explanation__c )) 
                body=body+var.Explanation__c ;
            body=body+'</p><h2>Solution</h2><p>';
            if(String.isNotEmpty(var.Troubleshooting_Guide_LTA__c )) 
                body=body+var.Troubleshooting_Guide_LTA__c ;
            body=body+'</p></body></html>';
            
            if(!Test.isRunningTest()){
                // Calling Image Converter Method to get the Complete Image
                body= SC_Utility.ImageConverter(body);
            }

            Blob bodyBlob=Blob.valueOf(body);
            
            //If document already exists, update otherwise insert
            if(docMap.containsKey(docName)) {
                eachDoc=docMap.get(docName);
                eachDoc.Body=bodyBlob;
                eachDoc.name=docName;
                docListUpdate.add(eachDoc);
            }
            else {
                eachDoc.Name=docName;
                eachDoc.Body=bodyBlob;
                eachDoc.FolderID=foldID;
                eachDoc.Type='html';
                docListInsert.add(eachDoc);  
            }
        }
        
        if(docListInsert.size()>0)
            insert docListInsert;
        if(docListUpdate.size()>0)
            update docListUpdate;
    }
    
    //Sync Question Answer
    public void insertQuesAnswer(List<sObject> scope) {
        
        //Create new lists to insert and update documents
        List<Document> docListInsert=new List<Document>();
        List<Document> docListUpdate=new List<Document>();
        List<Knowledge__kav> qa=scope;
        for( Knowledge__kav var : qa)
        {
            Document eachDoc=new Document();
            String cst='';
            String product='';
            String articleID=(var.AKAM_Article_Number__c).replaceFirst('^0+','');
            String docName='kb_'+articleID+'_html';
            for(Knowledge__DataCategorySelection dcs : var.DataCategorySelections) {
                if(dcs.DataCategoryGroupName == 'Customer Solution Topics') {
                    cst=cst+dcs.DataCategoryName+',';
                }
                if(dcs.DataCategoryGroupName == 'Product') {
                    product=product+dcs.DataCategoryName+',';
                }
            }
            
            //Generate the html
            String body = '<html><head><title>#'+articleID+':'+var.Title+'</title>';
            body=body+'<meta name="Products" content="'+product+'">';
            body=body+'<meta name="Description" content="';
            if(String.isNotEmpty(var.Question_Answer_Question__c)) 
                body=body+var.Question_Answer_Question__c;
            body=body+'">\n<meta name="CustomerSolutionTopics" content="'+cst+'">';
            //Added by Sonia for CR 3265081 - fix encoding issues in document sync
            body=body+'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
            body=body+'<meta name="ArticleID" content="'+articleID+'">';
            body=body+'<meta name="LMD" content="'+var.AKAM_Modified_Date__c +'">';
            //new keywords section .added by JAY for CR2789994
            if (var.Keywords__c != null)
                body=body+'<meta name="Keywords" content="'+var.Keywords__c +'">';
            body=body+'</head><body>';
            body=body+'<h2>';
            if(String.isNotEmpty(var.Question_Answer_Question__c)) 
                body=body+var.Question_Answer_Question__c;
            body=body+'</h2><p>';
            if(String.isNotEmpty(var.Question_Answer_Answer__c)) 
                body=body+var.Question_Answer_Answer__c;
            body=body+'</p></body></html>';
            
            if(!Test.isRunningTest()){
                // Calling Image Converter Method to get the Complete Image
                body= SC_Utility.ImageConverter(body);
            }
            
            Blob bodyBlob=Blob.valueOf(body);
            
            //If document already exists, update otherwise insert
            if(docMap.containsKey(docName)) {
                eachDoc=docMap.get(docName);
                eachDoc.Body=bodyBlob;
                eachDoc.name=docName;
                docListUpdate.add(eachDoc);
            }
            else {
                eachDoc.Name=docName;
                eachDoc.Body=bodyBlob;
                eachDoc.FolderID=foldID;
                eachDoc.Type='html';
                docListInsert.add(eachDoc);  
            }
        }
        if(docListInsert.size()>0)
            insert docListInsert;
        if(docListUpdate.size()>0)
        update docListUpdate;
    }
    
    //Sync Release Notes
    public void insertReleaseNotes(List<sObject> scope) {
        
        //Create new lists to insert and update documents
        List<Document> docListInsert=new List<Document>();
        List<Document> docListUpdate=new List<Document>();
        
        List<Knowledge__kav> rn=scope;  
        for( Knowledge__kav var : rn)
        {
            Document eachDoc=new Document();
            String cst='';
            String product='';
            String articleID=(var.AKAM_Article_Number__c).replaceFirst('^0+','');
            String docName='kb_'+articleID+'_html';
            for(Knowledge__DataCategorySelection dcs : var.DataCategorySelections) {
                if(dcs.DataCategoryGroupName == 'Customer Solution Topics') {
                    cst=cst+dcs.DataCategoryName+',';
                }
                if(dcs.DataCategoryGroupName == 'Product') {
                    product=product+dcs.DataCategoryName+',';
                }
            }
            
            //Generate the html
            String body = '<html><head><title>#'+articleID+':'+var.Title+'</title>';
            body=body+'<meta name="Products" content="'+product+'">';
            body=body+'<meta name="Description" content="';
            body=body+var.Title;
            body=body+'">\n<meta name="CustomerSolutionTopics" content="'+cst+'">';
            //Added by Sonia for CR 3265081 - fix encoding issues in document sync
            body=body+'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
            body=body+'<meta name="ArticleID" content="'+articleID+'">';
            body=body+'<meta name="LMD" content="'+var.AKAM_Modified_Date__c+'">';
            //new keywords section .added by JAY for CR2789994
            if (var.Keywords__c != null)
                body=body+'<meta name="Keywords" content="'+var.Keywords__c +'">';
            body=body+'</head><body>';
            body=body+'<h2>Release Date</h2><p>';
            if(var.Release_Notes_Release_Date__c != NULL) 
                body=body+var.Release_Notes_Release_Date__c;
            body=body+'</p><h2>What\'s New</h2><p>';
            if(var.Release_Notes_What_s_New__c != NULL && var.Release_Notes_What_s_New__c != '') 
                body=body+var.Release_Notes_What_s_New__c;
            body=body+'</p><h2>Enhancements</h2><p>';
            if(var.Release_Notes_Enhancements__c != NULL && var.Release_Notes_Enhancements__c != '') 
                body=body+var.Release_Notes_Enhancements__c;
            body=body+'</p><h2>Bug Fixes</h2><p>';
            if(var.Release_Notes_Bug_Fixes__c != NULL && var.Release_Notes_Bug_Fixes__c != '') 
                body=body+var.Release_Notes_Bug_Fixes__c;
            body=body+'</p></body></html>';
            
            if(!Test.isRunningTest()){
                // Calling Image Converter Method to get the Complete Image
                body= SC_Utility.ImageConverter(body);
            }
            
            Blob bodyBlob=Blob.valueOf(body);
            
            //If document already exists, update otherwise insert
            if(docMap.containsKey(docName)) {
                eachDoc=docMap.get(docName);
                eachDoc.Body=bodyBlob;
                eachDoc.name=docName;
                docListUpdate.add(eachDoc);
            }
            else {
                eachDoc.Name=docName;
                eachDoc.Body=bodyBlob;
                eachDoc.FolderID=foldID;
                eachDoc.Type='html';
                docListInsert.add(eachDoc);  
            }
        }
        if(docListInsert.size()>0)
            insert docListInsert;
        if(docListUpdate.size()>0)
            update docListUpdate;
    }
    
    //Sync Release Notes
    public void insertGlossaryDefinition(List<sObject> scope) {
        
        //Create new lists to insert and update documents
        List<Document> docListInsert=new List<Document>();
        List<Document> docListUpdate=new List<Document>();
        
        List<Knowledge__kav > rn=scope; 
        for( Knowledge__kav  var : rn)
        {
            Document eachDoc=new Document();
            String cst='';
            String product='';
            String articleID=(var.AKAM_Article_Number__c).replaceFirst('^0+','');
            String docName='kb_'+articleID+'_html';
            for(Knowledge__DataCategorySelection dcs : var.DataCategorySelections) {
                if(dcs.DataCategoryGroupName == 'Customer Solution Topics') {
                    cst=cst+dcs.DataCategoryName+',';
                }
                if(dcs.DataCategoryGroupName == 'Product') {
                    product=product+dcs.DataCategoryName+',';
                }
            }
            
            //Generate the html
            String body = '<html><head><title>#'+articleID+':'+var.Title+'</title>';
            body=body+'<meta name="Products" content="'+product+'">';
            body=body+'<meta name="Description" content="';
            body=body+var.Title;
            body=body+'">\n<meta name="CustomerSolutionTopics" content="'+cst+'">';
            //Added by Sonia for CR 3265081 - fix encoding issues in document sync
            body=body+'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
            body=body+'<meta name="ArticleID" content="'+articleID+'">';
            body=body+'<meta name="LMD" content="'+var.AKAM_Modified_Date__c+'">';
           //new keywords section .added by JAY for CR2789994
            if (var.Keywords__c != null)
                body=body+'<meta name="Keywords" content="'+var.Keywords__c +'">';
            body=body+'</head><body>';
             
            body = body + '<h2>Applies To</h2><p>';
            if (var.Applies_To__c != null){
             body = body + var.Applies_To__c;   
            }
            body = body + '</p><h2>Term</h2><p>';
            if (var.Glossary_Definition_Term__c != null){
                body = body + var.Glossary_Definition_Term__c;   
            }
            body = body + '</p><h2>Definition</h2><p>';
            if (var.Definition__c  != null){
             body = body + var.Definition__c;   
            }
           
            body=body+'</p></body></html>';
            
            if(!Test.isRunningTest()){
                // Calling Image Converter Method to get the Complete Image
                body= SC_Utility.ImageConverter(body);
            }
            
            Blob bodyBlob=Blob.valueOf(body);
            
            //If document already exists, update otherwise insert
            if(docMap.containsKey(docName)) {
                eachDoc=docMap.get(docName);
                eachDoc.Body=bodyBlob;
                eachDoc.name=docName;
                docListUpdate.add(eachDoc);
            }
            else {
                eachDoc.Name=docName;
                eachDoc.Body=bodyBlob;
                eachDoc.FolderID=foldID;
                eachDoc.Type='html';
                docListInsert.add(eachDoc);  
            }
        }
        if(docListInsert.size()>0)
            insert docListInsert;
        if(docListUpdate.size()>0)
            update docListUpdate;
    }
}