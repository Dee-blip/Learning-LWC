global class PACE_Batch implements Database.Batchable<SObject> {
  global PACE_Batch() {
    // Batch Constructor
  }
  // Start Method
  global Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'select Id,Name,Original_GA__c,Planned_GA__c,Original_LA__c,Planned_LA__c,Program_Manager__r.firstName from PACE_Program__c where (Planned_GA__c = LAST_MONTH or Planned_LA__c = LAST_MONTH) and Status__c in (\'In Progress\',\'Completed\') order by Name';

    return Database.getQueryLocator(query);
  }

  // Execute Logic
  global void execute(Database.BatchableContext BC, List<PACE_Program__c> scope) {
    //String[] receipients = new List<String>();
    Date todays = Date.today();
    // Integer numberDaysDue;
    for (Integer i = 0; i < scope.size(); i++) {
      String phase = '';
      Date GA = Date.today();
      Date LA = Date.today();
      if (scope[i].Planned_GA__c != null)
        GA = scope[i].Planned_GA__c;
      if (scope[i].Planned_LA__c != null)
        LA = scope[i].Planned_LA__c;

      if (checkIfInLastMonth(LA)) {
        phase = 'LA';
        computation(scope[i].Original_LA__c, scope[i].Planned_LA__c, phase, scope[i].Original_GA__c, scope[i].Planned_GA__c, scope[i].Name, scope[i].Program_Manager__r.firstName, false);
      }
      if (checkIfInLastMonth(GA)) {
        phase = 'GA';
        computation(scope[i].Original_LA__c, scope[i].Planned_LA__c, phase, scope[i].Original_GA__c, scope[i].Planned_GA__c, scope[i].Name, scope[i].Program_Manager__r.firstName, GA > LA);
      }

    }
  }

  global void finish(Database.BatchableContext BC) {}

  public boolean checkIfInLastMonth(Date programDate){
    Date today = Date.today();

    //checking if today's month is january then previous month has to be december of previous year
    if(today.month() == 1){
      if(programDate.month() == 12 && programDate.year() == today.year() - 1){
        return true;
      }
    }
    else{
      if(programDate.month() == today.month() - 1 && programDate.year() == today.year()){
        return true;
      }
    }
    return false;
  }

  public void sendEmail(String subject, String htmlBody, String[] receipients) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(receipients);
    mail.setSubject(subject);
    //Email body for html compliant mail client
    mail.setHtmlBody(htmlBody);
    PACECustomSettings__c replyToMail = PACECustomSettings__c.getInstance('Batch_ReplyToEmail');

    if (replyToMail != null && replyToMail.Value__c != null) {
      mail.setReplyTo(replyToMail.Value__c);
    }

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }

  public void computation(Date originalLA, Date plannedLA, String phase, Date originalGA, Date plannedGA, String Name, String ProgManager, Boolean IsGAAfterLA) {

    PACECustomSettings__c usrProfileName = PACECustomSettings__c.getInstance('PACE_Batch_mail');

    if (usrProfileName.Value__c == null) {
      return;
    }
    String emails = usrProfileName.Value__c;
    List<String> receipients = emails.split(',');

    //adding QA mailers
    Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
    Boolean isProduction = !org.IsSandbox;
    if(!isProduction){
      receipients.clear();
      receipients.add('usomani@akamai.com');
      //receipients.add('mapdakan@akamai.com');
      receipients.add('bmurumul@akamai.com');
      receipients.add('jmelwyn@akamai.com');
    }

    String htmlBodyPart1 = '<!DOCTYPE html><html><head><style> table, th, td {border: 1px solid black;}</style></head><body><p>Hi ' + ProgManager + ',</p><p>Our records in SFDC indicate that you’ve completed launch in your program journey. To ensure proper record keeping, we request you to validate the LA/GA date in the table below & respond to this email as early as possible.</p><table style="width:100%"><tr>    <th>Program Name</th>    <th>Phases</th>     <th>Original Date</th>    <th>Actual Date</th>    <th>Tolerance</th>     <td><b>Slipped Days</b></td></tr>';

    DateTime dTplanned, dT2original; 
    Date d3planned, dT4original;

    String htmlBodyPart2 = '';
    Date original = phase == 'GA' ? originalGA : originalLA;

    if (original == null) {
      dTplanned = null; dT2original = null; d3planned = null; dT4original = null;
    } 
    else {
      if(phase == 'GA'){
        dTplanned =  plannedGA; 
        dT2original =  originalGA; 
        d3planned = plannedGA; 
        dT4original = originalGA;
      }
      else{
        dTplanned =  plannedLA; 
        dT2original =  originalLA; 
        d3planned = plannedLA; 
        dT4original = originalLA;
      }

      
      Integer differenceBetweenDates = math.abs(d3planned.daysBetween(dT4original));
      //if planned date is greater than original then the difference in days must be negative
      if(d3planned < dT4original){ 
        differenceBetweenDates = 0 - differenceBetweenDates;
      }
      Integer numberDaysDue = differenceBetweenDates - 30;

      //if the program has gone through LA. If so the formula has to be changed. Formula = (Original GA - Original LA) - (Planned/Actual GA-Planned/Actual LA)
      if(phase == 'GA' && IsGAAfterLA){
        numberDaysDue = (originalLA.daysBetween(originalGA)) - (plannedLA.daysBetween(plannedGA));
      }

      if (numberDaysDue > 0)  {
        htmlBodyPart2 = '<tr><td>' + Name + '</td>' + '<td>' + phase + '</td><td>' + dT2original.format('d-MMM-yy') + '</td><td>' + dTplanned.format('d-MMM-yy') + '</td><td>' + 30 + '</td><td>' + numberDaysDue + '</td></tr>';

        htmlBodyPart2 += '</table><p> Note: Please make sure you overwrite SFDC data with actual data (if any changes) <a href="https://akamai.my.salesforce.com/home/home.jsp">here</a></p><br><p>We’re working with PDG leadership to optimize the product development process. One such aspect to understand, & hopefully improve, is adherence to launch schedules. You’ll note in the table above that your program slipped it’s original launch date(s). If you feel the Actual date entered by you is incorrect, please make the appropriate changes in SFDC and take a moment to draft reasons that help us understand this slippage. Examples are provided below to help you understand the degree of detail you may need to go into when you draft your response.</p>                    <table style="width:100%"> <tr><th></th><th>Client Reputation</th> <th>KDD</th><tr><th>Phase Slipped</th> <td>LA</td>    <td>LA / GA</td>  </tr><tr><th>Type of Slip</th>    <td>Scope and Schedule</td><td>Schedule</td></tr>   <tr>    <th>Reason for Slip</th>    <td><b>Schedule:</b><br><b>Extended LA</b> - Delay in delivering Web Scrapers category for original LA period<br><b>Quality metrics</b> - Tier 1 reviews close to date of original launch drove executive review of quality metrics and direction to rebuild portions of the product to address quality metrics    </td><td><b>Schedule:</b><br><b>LA </b>- Beta Issues -   There were issues in acquiring beta customers prior to LA<br><b>GA </b>- Development Delay - There was an increase in scope post EC driven by Tier 1 reclassification.  Additional features needed to be built to support the SOC usage of the tools before GA.</td></tr></table><br />Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.<p>Thanks,<br />Product Operations</p></body></html>';

      }
      else {
        if(phase == 'GA' && IsGAAfterLA){
            htmlBodyPart2 = '<tr><td>' + Name + '</td>' + '<td>' + phase + '</td><td>' + dT2original.format('d-MMM-yy') + '</td><td>' + dTplanned.format('d-MMM-yy') + '</td><td>' + 30 + '</td><td>' + (numberDaysDue == 0 ? ' 0': String.valueOf(Math.abs(numberDaysDue))) + '</td></tr>';
        }
        else{
          htmlBodyPart2 = '<tr><td>' + Name + '</td>' + '<td>' + phase + '</td><td>' + dT2original.format('d-MMM-yy') + '</td><td>' + dTplanned.format('d-MMM-yy') + '</td><td>' + 30 + '</td><td>N/A</td></tr>';
        }

        htmlBodyPart2 += '</table><p> Note: Please make sure you overwrite our system data with actual data (if any changes) <a href="https://akamai.my.salesforce.com/home/home.jsp">here</a></p><br />Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.<p>Thanks,<br>Product Operations</p></body></html>';

      }
      String htmlBody = htmlBodyPart1 + htmlBodyPart2;
      sendEmail('PACE Update for ' + Name, htmlBody, receipients);

    }
  }
}