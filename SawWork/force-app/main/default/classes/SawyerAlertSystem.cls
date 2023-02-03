/*
@Created by - Aayushi Agrawal
@created Date - 5 January -2021
@purpose - To send emails for Sawyer failures
*/

public class SawyerAlertSystem implements Database.Batchable<sObject> , Database.stateful{

 //public  Map<Beep__c,String> mapBeepTologs = new Map<Beep__c,String>();
  public  Map<String,List<Beep__c>> mapRecepientToListOfBeeps = new Map<String,List<Beep__c>>();
  public Set<String> emailAddressSet = new Set<String>(); 
  /*
  @Method Name - Start
  @Purpose - to query all latest 5 errors from sawyer records , where Investigation_Status__c = pending
  */
  public Database.QueryLocator start(Database.BatchableContext bc)
  {

      String query = 'SELECT ID,name ,Fingerprint__c,Action_Status__c,Investigation_Notification_Channel__c,Investigation_Status__c ,(SELECT ID,Class__c,Method__c,Line_Number__c,Message_Text__c,Stack_Trace_Text__c FROM SawedLawgs__r order by createdDate desc limit 5 ),';
      query +=  '(SELECT ID, Unique_Key__c , FullLoadStatus__c , LastSuccessfulRunTime__c , Error__c  FROM Mulesoft_Pollings__r order by createdDate desc limit 5 ),';
      query += '(SELECT ID, Response_Body__c , Response_Status__c , Response_Status_Code__c , Request_URI__c , Request_Method__c   FROM Callout_Logs__r order by createdDate desc limit 5 ) FROM BEEP__c WHERE (Investigation_Status__c = \'PENDING\' AND Investigation_Notification_Channel__c != NULL  ) OR Action_Status__c = \'Action Pending\' ';
      Database.QueryLocator dq;
      try
      {
          dq = Database.getQueryLocator(query);
      }
      catch(Exception exx)
      {
          Sawyer.saw(exx);
      }
      return dq;
  } //end of start method

  /*
  @Method Name - Execute 
  @Purpose : to convert queried records in html code and do the merging of email addresses
  */
  public void execute(Database.BatchableContext bc, List<Beep__c> scope){
      try
      {
          List<String> emailAddresses = new List<String>();
          for(BEEP__c beep : scope){
              String emailAddress;
              //get email address as per investigation status
              if(beep.Investigation_Status__c == 'Pending'){ // dev team
                  emailAddress = beep.Investigation_Notification_Channel__c;
              } 
              else if (beep.Action_Status__c == 'Action Pending'){ // ops team
                  emailAddress = GSMSettings.getValue('Ops_Email_Address');
              } 
              //mapBeepTologs.put(beep, emailAddress);
              for(String singleEmail : emailAddress.split(',')){
                  if(!mapRecepientToListOfBeeps.containsKey(singleEmail)){
                      mapRecepientToListOfBeeps.put(singleEmail, new List<Beep__c>{});
                  }
                  mapRecepientToListOfBeeps.get(singleEmail).add(beep);
              }

              emailAddressSet.add(emailAddress);
          }// end of  for(BEEP__c beep : scope)
      }
      catch(Exception exx)
      {
          Sawyer.saw(exx);
      }
  }// end of execute method

  /**
  * @Method : Finish
    @Purpose : To send emails from finish method
  */
  public void finish(Database.BatchableContext bc)
  {
   
      try
      {
          List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
          if(mapRecepientToListOfBeeps.size() > 0)
          {
              for(String recepientEmail : mapRecepientToListOfBeeps.keySet())
              {
                  SawyerAlertHtmlCodeGeneration sawyerAlerting = new SawyerAlertHtmlCodeGeneration();
                  Messaging.SingleEmailMessage singleMessage = sawyerAlerting.getSingleEmailMessageFromListOfBeeps(mapRecepientToListOfBeeps.get(recepientEmail), recepientEmail);
                  emailList.add(singleMessage);

              }
              if (!emailList.isEmpty())
              {
                  Messaging.sendEmail(emailList, true);
              } // end of if (!emailList.isEmpty())
          }
      }
      catch(Exception exx)
      {
          Sawyer.saw(exx);
      }
  }

}// end of SawyerAlertSystem class