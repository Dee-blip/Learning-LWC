/**
IRCaseLockClass
    @author : Ankit Chawla
    @Description : This class has logic to lock IR cases

    @History
    --Developer           --Date            --Change
    Achawla               19/09/2019        MOM-980: Created the class to process IR Case lock in batches
*/
global class IRCaseLockClass implements Database.Batchable<sObject>, Database.Stateful
{
  global String query;
  private Boolean initialized=false;
  private Datetime startDate;
  private Datetime endDate;
  private String results = '1:No Cases to process for this Invoice Review Period';
  private List<Id> csToIgnoreIdList = new List<Id>();
  private User triggerUser;
  private Map<String,List<String>> dmlErrorLog = new Map<String,List<String>>();
  private Integer updatedCount = 0;

  global  IRCaseLockClass(Date pStartDate, Date pEndDate, Id pUserId)
  {
      this.startDate = pStartDate;
      this.endDate = pEndDate;
      this.triggerUser = [Select Id, isActive, Email from User where Id = :pUserID][0];

      this.initialized=doInitialize();
  }

  public Boolean doInitialize()
  {

    String query = 'Select Id, CaseNumber, Status, IR_Manual_Contract__c, Description, IR_Case_Locked__c,';
           query += ' IR_Defer_Until__c, RecordTypeId, IR_Invoice_Date__c from Case where RecordType.DeveloperName = \''+ GsmUtilClass.GetCustomSettingValue('IR_RecordTypeName_Default') + '\'';
           query += ' and IR_Invoice_Date__c >= ' + this.startDate.formatGMT('yyyy-MM-dd') + ' and IR_Invoice_Date__c <= ' + this.endDate.formatGMT('yyyy-MM-dd');
           query += ' AND LastModifiedDate = LAST_N_DAYS:180 limit 9000 ';

    this.query = query;
    return true;
  }

  global Database.QueryLocator start(Database.BatchableContext BC)
  {
      return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope)
  {
    List<Case> csToLockList = new List<Case>();
    try
    {
      for (sObject so : scope){
        switch on so {
          when Case cs {
            if (cs.Status=='Deferred'){
                if (!cs.IR_Manual_Contract__c.equalsIgnoreCase('Yes') && cs.IR_Defer_Until__c > Date.today())
                {
                    csToIgnoreIdList.add(cs.Id);
                    continue;
                }
                cs.Status='Approved';
            }
            if(cs.Status=='Rejected')
                cs.Status = 'Approved';
            cs.IR_Case_Locked__c=true;
            cs.Validation_Override__c=true;
            csToLockList.add(cs);
          }
        }
      }

      if (csToLockList.size()>0)
      {
          Database.Saveresult[] srList =Database.update(csToLockList,false);
          Integer i = 0;
          String err = '';
          for (Database.Saveresult sr : srList)
          {
              if (!sr.isSuccess())
              {
                  err = sr.getErrors()[0].getMessage();
                  String tmp = csToLockList[i].CaseNumber;
                  if (dmlErrorLog.containsKey(tmp))
                      dmlErrorLog.get(tmp).add(err);
                  else
                      dmlErrorLog.put(tmp,new List<String>{err});
              }
              else
                  updatedCount++;
              i++;
          }
      }
    }
    catch (Exception ex)
    {
        dmlErrorLog.put('Exception=',new List<String>{ex.getMessage()});
    }
  }

  global void finish(Database.BatchableContext BC)
  {
    results = '----IR Case Lockdown Summary----\n\n';
    results += 'Start Date=' + this.startDate + '\n';
    results += 'End Date=' + this.endDate + '\n';
    results += 'No. of IR Cases locked=' + updatedCount + '\n';
    results += 'No. of IR Cases ignored (with Deferred Status)=' + csToIgnoreIdList.size() + '\n';
    if (!dmlErrorLog.isEmpty())
        results += '\n----Error Logs---\n' + dmlErrorLog;
    results += '\n----END----';

    System.debug('results=' + results);

    // send email...
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String[] recipientEmailList = GsmUtilClass.GetCustomSettingValue('IRCasesEAlert_RecipientList').split(',');
    recipientEmailList.add(this.triggerUser.Email);
    mail.setToAddresses(recipientEmailList);
    mail.setSubject('IR Cases lockdown is complete!');
    mail.setPlainTextBody(results);
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}