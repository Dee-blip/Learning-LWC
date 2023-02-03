/**

/**  
  Sonali Tandon   SFDC- 1201 NAP -- Implement File Subscribe functionality -  4th Oct 2016 - NAPFileSubscriptionDigestBatchClass 
  sends emails of updated content versions (files versions updated after the last successful cron run) that NAP users have subscribed to. 

  Shivam Verma    SFDC 1340 -- Added the functionality of library subscription

 **/
global class NAPFileSubscriptionDigestBatchClass implements Database.Batchable<sObject> {
  
  global  String query;
  global Messaging.SendEmailResult[] results;
    global Datetime completedDate;
  global String workspaceId;

  global NAPFileSubscriptionDigestBatchClass()
  { 
    Cron_Batch_Job__c cronBatchJob = [Select Id from Cron_Batch_Job__c where Batch_Job_Type__c = 'NAP File Subscription Digest' LIMIT 1 ];
        List<Cron_Batch_Run__c> latestCronRun = new List<Cron_Batch_Run__c>();
        latestCronRun = [SELECT Id,Completed__c,Result__c FROM Cron_Batch_Run__c WHERE Cron_Batch_Job__c =:cronBatchJob.Id AND Result__c = 'Success' ORDER BY Completed__c DESC LIMIT 1];
        if(latestCronRun.size()>0)
        {
            completedDate = latestCronRun[0].Completed__c;
            query = 'Select Id, ContentDocumentId, IsLatest, CreatedDate,Title, Description from ContentVersion where IsLatest = true AND lastModifiedDate > :completedDate';
            
        }
  }
    
  private void createSubscriptionMails(Map<String,Set<ContentVersion>> mapOfEmailToContentVersion)
  {
        System.debug('Map Of Email To ContentVersion while sending mail:'+mapOfEmailToContentVersion);
        EmailTemplate template =[select Body,Subject,HtmlValue from EmailTemplate where DeveloperName='File_Subscription_Email'][0];
        
        String emailTextBody, emailHTMLBody;
        String fileDownloadLink;
        String urlPrefix;
        
        if(System.URL.getSalesforceBaseUrl().getHost().contains('qa'))
            urlPrefix = NAPSettings.getValue('PartnerCommunityURL_QA');
        else
            urlPrefix = NAPSettings.getValue('PartnerCommunityURL_Prod');
        
        List<Messaging.SingleEmailMessage> listOfEmails = new List<Messaging.SingleEmailMessage>();

        Document logo = [SELECT Id, Name from Document where name = 'Generic Netalliance Logo' LIMIT 1];
        String urlFileRef= '<image src = "'+ System.URL.getSalesforceBaseUrl().toExternalForm()+
            '/servlet/servlet.ImageServer?id=' + logo.Id + '&oid=' + UserInfo.getOrganizationId()+
            + '" alt = "akamai_netalliance_logo" /> '; //SDFC 7172
        
        for(String email : mapOfEmailToContentVersion.keySet())

        {
            if (!mapOfEmailToContentVersion.get(email).isEmpty()) {
                String tableBody = '';
                System.debug('Email for user :'+email);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setToAddresses (new String[]{ email });
                message.setSubject (template.Subject);   
                System.debug('Content Version for '+email +' :::'+mapOfEmailToContentVersion.get(email));

                for(ContentVersion cv : mapOfEmailToContentVersion.get(email))
                {
                    fileDownloadLink = urlPrefix + GsmUtilClass.convertToCommunityURL(NAPSettings.getValue('File_Download_Link') + String.valueOf(cv.Id) + '?operationContext=CHATTER');
                    tableBody += '<li style = "font-size : 12px; font-family: verdana;"><b>' + cv.Title + '</b> </br> Updated:' + cv.CreatedDate + ' GMT | <a href="' + fileDownloadLink + '"> Download</a></br>';
                    if(!String.isBlank(cv.Description))
                        tableBody += 'Description:'+ cv.Description +'</li><hr>';
                    else
                        tableBody += '</li><hr>';
                }
                
                // Document logo = [SELECT Id, Name from Document where name = 'Generic Netalliance Logo' LIMIT 1];
                // String url_file_ref = '<image src = "'+ System.URL.getSalesforceBaseUrl().toExternalForm()+
                //     '/servlet/servlet.ImageServer?id=' + logo.Id + '&oid=' + UserInfo.getOrganizationId()+
                //     + '" alt = "akamai_netalliance_logo" /> ';
                emailTextBody = template.Body.replace('#body#', tableBody).replace('#akamailogo#',urlFileRef);
                emailHTMLBody = template.HtmlValue.replace('#body#', tableBody).replace('#akamailogo#',urlFileRef);
                listOfEmails.add(GsmUtilClass.createSingleEmail(email,'',template.Subject,emailTextBody,emailHTMLBody));
            }
      
      }
    System.debug('List of emails :'+listOfEmails);

      results = Messaging.sendEmail(listOfEmails); 
  }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {   
        System.debug(query);   
        return Database.getQueryLocator(query); 
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        
      List<Id> contentDocumentIdList = new List<Id>();
      Map<Id,ContentVersion>  mapOfDocumentIdToContentVersion = new Map<Id,ContentVersion>();
      Map<Id,ContentVersion>  mapOfContentDocumentIdToContentVersion = new Map<Id,ContentVersion>();
      List<ContentVersion> eligibleContentVersions = new List<ContentVersion>();

      List<ContentVersion> contentVersionList = (List<ContentVersion>)scope;
        
      for (ContentVersion cvv:contentVersionList) {
            contentDocumentIdList.add(cvv.ContentDocumentId);
            mapOfDocumentIdToContentVersion.put(cvv.ContentDocumentId,cvv);
      }
        
        workspaceId = NAPSettings.getValue('Partner_Documents_Library_Id');
        
        /* Here we have the list of all the documents update
         * From that list, check those document link where linked entity is partner share library
         * i.e. the document is shared with the resp. library
         */
        List<ContentDocumentLink> partnerShareDocumentLinks = new List<ContentDocumentLink>();
        if (contentDocumentIdList != null && contentDocumentIdList.size() > 0) {
            partnerShareDocumentLinks = [Select ContentDocumentId, LinkedEntityId
                                          From ContentDocumentLink
                                          Where ContentDocumentId IN :contentDocumentIdList
                                          and LinkedEntityId=:workspaceId];
        }
        
        //If there are partner share documents in the content document links, get the related contentVersions
        if (partnerShareDocumentLinks.size() > 0) {
            for (ContentDocumentLink cdl:partnerShareDocumentLinks) {
                eligibleContentVersions.add(mapOfDocumentIdToContentVersion.get(cdl.ContentDocumentId));
            }
        }
      
       Map<String,Set<ContentVersion>> mapOfEmailToContentVersion  = new Map<String,Set<ContentVersion>>();
       Set<ContentVersion> contentVersionWithoutAttributes = new Set<ContentVersion>();
      
       /* SFDC 1340 Getting the set of Content Version with attributes by
        * 1) First create a list of all content version from scope
        * 2) Get the list of all content version attributes using the list of content verions
        * 3) Create a set of all content versions having attributes using list created in step 2
       */
       List<Id> contentVersionids = new List<Id>();
       for (ContentVersion cv:eligibleContentVersions) {
           contentVersionids.add(cv.id);
       }
        
       List<ContentVersionAttribute__c> contentVersionAttributesList = [Select id,ContentVersionId__c From ContentVersionAttribute__c where
                                                                        ContentVersionId__c IN:contentVersionids];
        
       Set<Id> contentVersionWithAttributesSet = new Set<Id>();
       for (ContentVersionAttribute__c cva:contentVersionAttributesList) {
           contentVersionWithAttributesSet.add(cva.ContentVersionId__c);
       }
        
       for (ContentVersion conVer:eligibleContentVersions) {
           if (!contentVersionWithAttributesSet.contains(conVer.id))
               contentVersionWithoutAttributes.add(conVer);
       }
        
       //Get all the User subscribed to library
       List<Contact> subscribedContacts = [Select id,Partner_User__r.email from Contact where Subscribed_to_Library__c = true];
       for (Contact con:subscribedContacts) {
         //SFDC-6646
         if(con.Partner_User__r != null && con.Partner_User__r.email != null) {
          mapOfEmailToContentVersion.put(con.Partner_User__r.email, contentVersionWithoutAttributes);
         }
       }
        
       /* SFDC 1340 Though the User have the functionality of subscribing to the library,
       * there exist a use case where the user have not subscribed to library but to individual files
       * The below code is an exsiting code handling that use case
       */
        
      for(ContentVersion cv : eligibleContentVersions)
      { 
            mapOfContentDocumentIdToContentVersion.put(cv.ContentDocumentId,cv);
      }
    
      for(NAP_File_Subscribe__c napFileSubscribe : [Select Id,Content_Document_Id__c, Active_subscription__c, User__c, User__r.Email from NAP_File_Subscribe__c
      where Content_Document_Id__c IN :mapOfContentDocumentIdToContentVersion.keySet() AND Active_subscription__c = true])
      {
        //SFDC 1340 Removing the email ids which are included under library subscription as those are already included as part of library subscribe functionality
        if(napFileSubscribe.User__r != null && napFileSubscribe.User__r.Email != null && napFileSubscribe.User__r.Email != '') { //SFDC-6646
          if(!mapOfEmailToContentVersion.containsKey(napFileSubscribe.User__r.Email) /*&& !mapOfEmailToContentVersion.keySet().contains(napFileSubscribe.User__r.Email)*/)
          mapOfEmailToContentVersion.put(napFileSubscribe.User__r.Email, new Set<ContentVersion>{mapOfContentDocumentIdToContentVersion.get(Id.valueOf(napFileSubscribe.Content_Document_Id__c))});
        else /*if (!mapOfEmailToContentVersion.keySet().contains(napFileSubscribe.User__r.Email))*/
          mapOfEmailToContentVersion.get(napFileSubscribe.User__r.Email).add(mapOfContentDocumentIdToContentVersion.get(Id.valueOf(napFileSubscribe.Content_Document_Id__c)));
        }
      }
        

      System.debug(LoggingLevel.ERROR, mapOfEmailToContentVersion);

      if(mapOfEmailToContentVersion.size()>0)
        createSubscriptionMails(mapOfEmailToContentVersion);
  
  }

  
  global void finish(Database.BatchableContext BC) {

    if(results!=null)
    {

        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

    for(Messaging.SendEmailResult sendEmailResult: results){
            
          if(!sendEmailResult.isSuccess())
          {
            for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors())
            { 

              Error_Log__c el = new Error_Log__c(Name='NAPFileSubscriptionDigestBatchClass', Class__c='NAPFileSubscriptionDigestBatchClass', Error_Message__c=sendEmailError.Message);
                  errorLogs.add(el);
            }
          }
      }


        if(errorLogs.size()>0)
            Database.insert(errorLogs, false);

    }

  

    
  }
  
}