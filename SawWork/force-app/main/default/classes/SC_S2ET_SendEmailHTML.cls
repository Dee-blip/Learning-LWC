/*
************************************************************************************************************
    Author              :   Kunal Sharma
    Created             :   22-April-2020
    Purpose             :   Shift Handover Report
    JIRA Story          :   ESESP-3524 :: Security Services Dashboard: S2ET Dashboard and Case Improvements

	Sujay				: 	ESESP-5678 :Modified to accomodate new column on Email notifications : ESESP-5678
    Jay                 :   ESESP-3945 :Updated Shift Handover Report to include special notes.
************************************************************************************************************

*/

public class SC_S2ET_SendEmailHTML {
    public static Boolean isOpenHighPriorityCaseSection = true;
    public static Boolean isOpenCaseSection = true;
    public static Boolean isCloseCaseSection = true;
    public static String shiftName = '';
    public static List<List<SC_SecurityServices_Ctrlr.CaseWrapper>> lCasesToDisplay; //= SC_SecurityServices_Ctrlr.getCaseListForReport();
    public static List<List<SC_ProvisioningDashboard_Controller.CaseWrapper>> lCasesToDisplayPLX;
    
    public SC_S2ET_SendEmailHTML() {
    }
    
    public static void emailShiftHandoverReport(String specialNotes) {

        if (!String.isBlank(specialNotes) && specialNotes.contains('<img src=')) {
            specialNotes = replaceImagesWithHref(specialNotes);
        }
        specialNotes = specialNotes == null ? '' : specialNotes;
        if(lCasesToDisplay != null && lCasesToDisplay.size() > 0)
        {
            String subject =
                '24PS Shift Handover Report - ' +
                shiftName +
                ' - ' +
                DateTime.now().dayGmt() +
                '-' +
                getMonthText(DateTime.now().monthGmt()) +
                '-' +
                DateTime.now().yearGmt();
            String styleClass = '<html> <head> <style> table {   font-family: arial, sans-serif; font-size:13px; border-collapse: collapse;   width: 100%; }  td, th {   border: 1px solid #000000;   text-align: center;   padding: 8px; } th{text-align: center;}</style> </head>';
            String tableHeader = '<body><br>'; //'<body><center><h1>Shift Handover Report : ' + shiftName +'</h1></center><br>';
            String tableColumnHeader = '';
            String tableSummaryReport = '';
            String emailBody = '';
            tableSummaryReport +=
                '<table> <tr style="background-color:#dddddd"> <th style="width:30%;" colspan="2">Summary Stats</th> <th style="width:70%">Special Notes</th></tr>   <tr><td>Open Cases</td><td>' +
                SC_SecurityServices_Ctrlr.numberOfTotalOpenCases +
                '</td>' +
                '<td rowspan="3">'+specialNotes+'</td></tr>';
            tableSummaryReport +=
                '<tr><td>New Cases</td><td>' +
                SC_SecurityServices_Ctrlr.numberOfOpenCase +
                '</td> </tr>';
            tableSummaryReport +=
                '<tr><td>Closed Cases</td><td>' +
                SC_SecurityServices_Ctrlr.numberOfClosedCases +
                '</td> </tr></table><br>';
            //tableHeader += '<table>   <tr><td><center><h4>Open Cases : ' + SC_SecurityServices_Ctrlr.numberOfOpenCase + '</h4></center></td>';
            //tableHeader += '<td><center><h4>Closed Cases : ' + SC_SecurityServices_Ctrlr.numOfClosedCases + '</h4></center></td> </tr></table><br>';
            tableColumnHeader += '<th style="width:3%"> </th>     <th style="width:7%">Case Id</th>     <th style="width:16%">Escalations</th>  <th style="width:27%">Subject</th> <th style="width:2%">Sev</th> <th style="width:2%">Age</th> <th style="width:15%">Service</th> <th style="width:20%">Tasks Completed</th> </tr> ';
            
            //String caseURL = 'https://akamai--gssapril.lightning.force.com/lightning/r/Case/';
            String caseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Case/';
            String bodyToSend = styleClass + tableHeader + tableSummaryReport;
            for (Integer i = 0; i < lCasesToDisplay.size(); i++) {
                Integer j = 0;
                String emailBodyContent = '';
                for (SC_SecurityServices_Ctrlr.CaseWrapper caseVar : lCasesToDisplay[i]) {
                    String escalationRecords = '';
                    for (Engagement_Request__c varEscalation : caseVar.lEscalationRecords) {
                        escalationRecords += '<a href="' + varEscalation.URL__c + '">' + varEscalation.ID__c + ' - ' + varEscalation.Request_Status__c + '</a><br>';
                    }
                    //escalationRecords += '</td>';
                    j++;
                    if (
                        (caseVar.caseType.containsIgnoreCase('HighPriorityOpenCase')) &&
                        j == 1
                    ) {
                        isOpenHighPriorityCaseSection = false;
                        emailBodyContent = '<tr><td colspan="7"><h2>Priority-Flagged Cases</h2></td></tr>';
                        emailBodyContent += '<table>   <tr style="background-color:#FFC300">' + tableColumnHeader;
                    }
                    if (caseVar.caseType.equalsIgnoreCase('OpenCase') && j == 1) {
                        emailBodyContent =
                            emailBodyContent +
                            '<br>' +
                            '<tr><td colspan="7"><h2>Other Open Cases</h2></td></tr>';
                        emailBodyContent += '<table>   <tr style="background-color:#dddddd">' + tableColumnHeader;
                        isOpenCaseSection = false;
                    }
                    if (caseVar.caseType.containsIgnoreCase('ClosedCase') && j == 1) {
                        emailBodyContent += emailBodyContent + '<br>' + '<tr><td colspan="7"><h2>Closed Cases</h2></td></tr>';
                        emailBodyContent += '<table>   <tr style="background-color:#dddddd">' + tableColumnHeader;
                        isCloseCaseSection = false;
                    }
                    
                    emailBodyContent +=
                        '<tr><td ><strong style="font-size:25px;">' +
                        caseVar.hotCustomer +
                        '</strong></td><td><a href="' +
                        caseURL +
                        caseVar.caseId +
                        '/view' +
                        '">' +
                        caseVar.akamCaseId +
                        '</a>' +
                        '</td><td>' +
                        escalationRecords +
                        '</td><td>' +
                        caseVar.subject +
                        '</td><td>' +
                        caseVar.severity +
                        '</td><td>' +
                        caseVar.ageDays +
                        '</td><td>' +
                        caseVar.service +
                        '</td><td>' +
                        caseVar.taskCompleted +
                        '</td></tr>';
                    if (j == lCasesToDisplay[i].size()) {
                        emailBody = emailBody + emailBodyContent + '</table>';
                    }
                }
            }
            bodyToSend = bodyToSend + emailBody + '</body> </html>';
            //   styleClass +
            //   tableHeader +
            //   emailBodyContent +
            //   '</table>  </body> </html>';
            
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAdds = new List<String>();
            toAdds.add(UserInfo.getUserEmail());
            mail.setToAddresses(toAdds);
            mail.setSubject(subject);
            mail.setHtmlBody(bodyToSend);
            mails.add(mail);
            system.debug('emailBody' + bodyToSend);
            Messaging.sendEmail(mails);
        }
    }
    
    
    public static void emailShiftHandoverReportPLX() {
        String subject =
            'PLX Shift Handover Report - ' +
            //shiftName +
            //' - ' +
            DateTime.now().dayGmt() +
            '-' +
            getMonthText(DateTime.now().monthGmt()) +
            '-' +
            DateTime.now().yearGmt();
        String styleClass = '<html> <head> <style> table {   font-family: arial, sans-serif; font-size:13px; border-collapse: collapse;   width: 100%; }  td, th {   border: 1px solid #000000;   text-align: center;   padding: 8px; } th{text-align: center;}</style> </head>';
        String tableHeader = '<body><br>'; //'<body><center><h1>Shift Handover Report : ' + shiftName +'</h1></center><br>';
        String tableColumnHeader = '';
        String tableSummaryReport = '';
        String emailBody = '';
        tableSummaryReport += '<table> <tr style="background-color:#dddddd"> <th style="width:30%;" colspan="2">Summary Stats</th> <th style="width:70%">Special Notes</th></tr>   <tr><td>Open Cases</td><td>' +
            SC_ProvisioningDashboard_Controller.numberOfOpenCase +
            '</td>' +
            '<td rowspan="3"></td></tr>';
        tableSummaryReport += '<tr><td>Open Tasks</td><td>' + SC_ProvisioningDashboard_Controller.numOfTasksOpen +
            '</td> </tr><tr><td>Completed Tasks</td><td>'+SC_ProvisioningDashboard_Controller.numOfTasksCompleted+
            '</table><br>';
        /*tableSummaryReport +=
            '<tr><td>New Cases</td><td>' +
            SC_ProvisioningDashboard_Controller.numberOfOpenCase +
            '</td> </tr>';
        tableSummaryReport +=
            '<tr><td>Closed Cases</td><td>' +
            SC_ProvisioningDashboard_Controller.numOfClosedCases +
            '</td> </tr></table><br>';*/
        //tableHeader += '<table>   <tr><td><center><h4>Open Cases : ' + SC_ProvisioningDashboard_Controller.numberOfOpenCase + '</h4></center></td>';
        //tableHeader += '<td><center><h4>Closed Cases : ' + SC_ProvisioningDashboard_Controller.numOfClosedCases + '</h4></center></td> </tr></table><br>';
        tableColumnHeader += '<th style="width:3%"> </th>     <th style="width:7%">Case Id</th>     <th style="width:16%">Account</th>  <th style="width:16%">Shift Owner</th>   <th style="width:27%">Subject</th> <th style="width:2%">Sev</th> <th style="width:2%">Age</th> <th style="width:15%">Service</th> <th style="width:20%">Tasks Open</th> <th style="width:20%">Tasks Completed</th> </tr> ';
        
        //String caseURL = 'https://akamai--gssapril.lightning.force.com/lightning/r/Case/';
        String caseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Case/';
        String bodyToSend = styleClass + tableHeader + tableSummaryReport;
        for (Integer i = 0; i < lCasesToDisplayPLX.size(); i++) {
            Integer j = 0;
            String emailBodyContent = '';
            for (SC_ProvisioningDashboard_Controller.CaseWrapper caseVar : lCasesToDisplayPLX[i]) {
                //String escalationRecords = '';
                /*for (Engagement_Request__c varEscalation : caseVar.lEscalationRecords) {
                    escalationRecords += '<a href="' + varEscalation.URL__c + '">' + varEscalation.ID__c + ' - ' + varEscalation.Request_Status__c + '</a><br>';
                }*/
                //escalationRecords += '</td>';
                j++;
                if ((caseVar.caseType.containsIgnoreCase('HighPriorityOpenCase')) && j == 1) 
                {
                    isOpenHighPriorityCaseSection = false;
                    emailBodyContent = '<tr><td colspan="8"><h2>Priority-Flagged Cases</h2></td></tr>';
                    emailBodyContent += '<table>   <tr style="background-color:#FFC300">' + tableColumnHeader;
                }
                if (caseVar.caseType.equalsIgnoreCase('OpenCase') && j == 1) {
                    emailBodyContent = emailBodyContent + '<br>' + '<tr><td colspan="8"><h2>Other Open Cases</h2></td></tr>';
                    emailBodyContent += '<table>   <tr style="background-color:#dddddd">' + tableColumnHeader;
                    isOpenCaseSection = false;
                }
                if (caseVar.caseType.containsIgnoreCase('ClosedCase') && j == 1) {
                    emailBodyContent += emailBodyContent + '<br>' + '<tr><td colspan="8"><h2>Closed Cases</h2></td></tr>';
                    emailBodyContent += '<table>   <tr style="background-color:#dddddd">' + tableColumnHeader;
                    isCloseCaseSection = false;
                }
                
                /*emailBodyContent +=
                    '<tr><td ><strong style="font-size:25px;">' +
                    caseVar.hotCustomer + '</strong></td><td><a href="' + caseURL + caseVar.caseId + '/view' + '">' + caseVar.akamCaseId +
                    '</a>' + '</td><td>' + escalationRecords + '</td><td>' + caseVar.subject + '</td><td>' + caseVar.severity +
                    '</td><td>' + caseVar.service + '</td><td>' + caseVar.taskNext + '</td></tr>';*/

                emailBodyContent +=
                    '<tr><td ><strong style="font-size:25px;">' +
                    caseVar.hotCustomer + '</strong></td><td><a href="' + caseURL + caseVar.caseId + '/view' + '">' + caseVar.akamCaseId +
                    '</a>' + '</td><td>' + caseVar.accountName + '</td><td>' + caseVar.shiftOwner + '</td><td>' + 
                    caseVar.subject + '</td><td>' + caseVar.severity +
                    '</td><td>' + caseVar.service + '</td><td>' + caseVar.taskNext + '</td><td>' + caseVar.taskCompleted + '</td></tr>';

                if (j == lCasesToDisplayPLX[i].size()) {
                    emailBody = emailBody + emailBodyContent + '</table>';
                }
            }
        }
        bodyToSend = bodyToSend + emailBody + '</body> </html>';
        //   styleClass +
        //   tableHeader +
        //   emailBodyContent +
        //   '</table>  </body> </html>';
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAdds = new List<String>();
        toAdds.add(UserInfo.getUserEmail());
        mail.setToAddresses(toAdds);
        mail.setSubject(subject);
        mail.setHtmlBody(bodyToSend);
        mails.add(mail);
        system.debug('emailBody' + bodyToSend);
        Messaging.sendEmail(mails);
    }
    
    @AuraEnabled
    public static void getShiftDetailsPLX() {
        Datetime startDate = system.now();
        DateTime endDate = system.now().addHours(6);
        lCasesToDisplayPLX = SC_ProvisioningDashboard_Controller.getCaseListForReport(startDate,endDate);
        emailShiftHandoverReportPLX();
    }
    
    @AuraEnabled
    public static void getShiftDetails(String shiftInfo) {
        DateTime startDate;
        DateTime endDate;
        CommonUtilClass.ShiftDetails shiftDetails = CommonUtilClass.getShiftDetails(Datetime.now());
        if (shiftInfo == 'CURRENTSHIFT') {
            shiftName = shiftDetails.currentShift;
            startDate = shiftDetails.startDate;
            endDate = shiftDetails.endDate;
        }else if (shiftInfo == 'PREVIOUSSHIFT'){
            shiftName = shiftDetails.previousShift;
            //subtract 6 hours to go to prev shift as each shift is 6 hours long
            startDate = shiftDetails.startDate.addHours(-6);
            endDate = shiftDetails.endDate.addHours(-6);
        }

        String specialNotes = getShiftSpecialNotes();

        lCasesToDisplay = SC_SecurityServices_Ctrlr.getCaseListForReport(
            startDate,
            endDate
        );
        emailShiftHandoverReport(specialNotes);
    }
    
    public static String getMonthText(Integer month) {
        String monthText = '';
        switch on month {
            when 1 {monthText = 'Jan';}
            when 2 {monthText = 'Feb';}
            when 3 {monthText = 'Mar';}
            when 4 {monthText = 'Apr';}
            when 5 {monthText = 'May';}
            when 6 {monthText = 'Jun';}
            when 7 {monthText = 'Jul';}
            when 8 {monthText = 'Aug';}
            when 9 {monthText = 'Sep';}
            when 10 {monthText = 'Oct';}
            when 11 {monthText = 'Nov';}
            when 12 {monthText = 'Dec';}
        }
        return monthText;
    }

    public static String getShiftSpecialNotes(){
        String key = '-SPCLNOTES-';
        List<SC_QM_User_Filter__c> filters = [SELECT Id,SpecialNotes__c FROM SC_QM_User_Filter__c WHERE User_Id__c=:key LIMIT 1];
        if (filters.size()>0) {
            return filters[0].SpecialNotes__c;
        }else {
            return '';
        }
    }

    private static String replaceImagesWithHRef(String specialNotes) {
        Pattern mPattern = Pattern.compile('<img src="(.+?)"></img>');
        Matcher mMatcher = mPattern.matcher(specialNotes);
        while (mMatcher.find()){
            String imgTag = mMatcher.group(0);
            String imgUrl = mMatcher.group(1);
            specialNotes = specialNotes.replace(imgTag,'<a href="'+imgUrl+'">Image</a>');
        }
        return specialNotes;
    }

}