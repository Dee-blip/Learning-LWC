public class SC_PSAutomationMultipleAccount_BatchJob implements Database.Batchable<sObject> {
    public List < String > childMailerIds;


    public SC_PSAutomationMultipleAccount_BatchJob(String recs) {
      this.childMailerIds = (List < String > ) JSON.deserialize(recs, List < String >.class);
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {
      // collect the batches of records or objects to be passed to execute
  
      String query = 'SELECT Id,Email_forwarded_to_Contacts_On__c,Account__c,Parent_PS_Customer_Mailer__r.Subject__c,Parent_PS_Customer_Mailer__r.Content__c FROM PS_Customer_Mailers__c where Id IN:childMailerIds';
      return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext BC, List < PS_Customer_Mailers__c > childMailerList) {
      List < Id > accountId = new List < Id > ();
      List < Id > mailerIdInScope = new List < Id > ();
      List < Id > contentDocIds = new List < Id > ();
      List < String > toAddresses = new List < String > ();
      List < String > toAddressesForMailing = new List < String > ();
      Map < Id, List < Id >> mailerVsContentDocId = new Map < Id, List < Id >> ();
      Map < Id, List < ContentVersion >> contentDocVsContentVersion = new Map < Id, List < ContentVersion >> ();
      Map < Id, PS_Automation_Admin_DL__c > accVsDL = new Map < Id, PS_Automation_Admin_DL__c > ();
      List < Messaging.EmailFileAttachment > fileAttachments = new List < Messaging.EmailFileAttachment > ();
      List<messaging.SingleEmailMessage> allMails = new List<messaging.SingleEmailMessage>();
      for (PS_Customer_Mailers__c itrMailer: childMailerList) {
        if(itrMailer.Email_forwarded_to_Contacts_On__c == null){
          accountId.add(itrMailer.Account__c);
          mailerIdInScope.add(itrMailer.Id);
        }
      }
  
      for (contentDocumentLink CDLink: [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid IN: mailerIdInScope]) {
        if (mailerVsContentDocId.containsKey(CDLink.LinkedEntityid)) {
          mailerVsContentDocId.get(CDLink.LinkedEntityid).add(CDLink.ContentDocumentid);
        } else {
          mailerVsContentDocId.put(CDLink.LinkedEntityid, new List < Id > {
            CDLink.ContentDocumentid
          });
        }
        contentDocIds.add(CDLink.ContentDocumentid);
      }
  
      for (ContentVersion cversion: [SELECT title, ContentDocumentId,
          PathOnClient, FileType,
          versiondata
          FROM contentversion
          WHERE ContentDocumentId IN: contentDocIds
        ]) {
        if (contentDocVsContentVersion.containsKey(cversion.ContentDocumentId)) {
          contentDocVsContentVersion.get(cversion.ContentDocumentId).add(cversion);
        } else {
          contentDocVsContentVersion.put(cversion.ContentDocumentId, new List < ContentVersion > {
            cversion
          });
        }
      }
  
      for (PS_Automation_Admin_DL__c itrDL: [Select Id, Account__c, DL_Email_Address__c from PS_Automation_Admin_DL__c WHERE Account__c IN: accountId AND recordType.Name = 'External']) {
        if (!accVsDL.containsKey(itrDL.Account__c)) {
          accVsDL.put(itrDL.Account__c, itrDL);
        }
      }
  
      for (PS_Customer_Mailers__c itrMailer: childMailerList) {
        if(itrMailer.Email_forwarded_to_Contacts_On__c == null){
        // Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
        messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
        toAddresses = new List < String > ();
        toAddressesForMailing = new List < String > ();
        fileAttachments = new List < Messaging.EmailFileAttachment > ();
        if (accVsDL.containsKey(itrMailer.Account__c) && accVsDL.get(itrMailer.Account__c).DL_Email_Address__c != '') {
          toAddresses = accVsDL.get(itrMailer.Account__c).DL_Email_Address__c.split(',');
          for (String itrEmail: toAddresses) {
            toAddressesForMailing.add(itrEmail.trim());
          }
        }
        mail.setToAddresses(toAddressesForMailing);
        mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        mail.setSubject(itrMailer.Parent_PS_Customer_Mailer__r.Subject__c);
        mail.setHtmlBody(itrMailer.Parent_PS_Customer_Mailer__r.Content__c);
  
        mail.setWhatId(itrMailer.Id);
        mail.setSaveAsActivity(true);
        if(mailerVsContentDocId != null && mailerVsContentDocId.containsKey(itrMailer.Id)){
            for (Id itrCD: mailerVsContentDocId.get(itrMailer.Id)) {
                for (ContentVersion itrCV: contentDocVsContentVersion.get(itrCD)) {
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName(itrCV.title);
                    efa.setBody(itrCV.versiondata);
                    fileAttachments.add(efa);
                }
            }
        }    
        if (fileAttachments.size() > 0) {
          mail.setFileAttachments(fileAttachments);
        }
        allMails.add(mail);
        }
  
      }

      if(allMails.size() > 0){
      Messaging.sendEmailResult[] sendEmailResults =  Messaging.sendEmail(allMails);
          for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
            
                if(sendEmailResult.isSuccess()){
                    for (PS_Customer_Mailers__c itrMailer: childMailerList) {
                        itrMailer.Email_forwarded_to_Contacts_On__c = Datetime.now();
                    }    
                    update childMailerList;
                 }
            }
      }      
  
    }
  
  
  
  public void finish(Database.BatchableContext BC) {
    // execute any post-processing operations like sending email
  }
  }