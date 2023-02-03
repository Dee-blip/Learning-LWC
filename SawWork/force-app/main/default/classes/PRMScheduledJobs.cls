/***
    PRMScheduledJobs
    @author Vinayendra T N <Vinatara@akamai.com>
    @Description : This class contains Scheduled Jobs related to PRM.
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N	28/06/11	CR 1150381 PRM: Need to create a time-based WF for deal registration and MDF approvals
 								A scheduled job will run everyday which sends email and creates task if any of
								the below condition is satisfied 
								1. Status=(deal:pending,FR:submitted) AND submitted date >24 hrs and <48hrs 
								2. Status=(deal:pending,FR:submitted) AND submitted date >48 hrs and <72hrs 					
   Vinayendra T N   28/06/11	CR 1162207 PRM: Add partner admin to sales team of all opportunities
   								~ A scheduled job will run everyday which gets all users created in less than 24 hrs and profile is 'Akamai Partner Administrator'
   								~ Gets all Opptys whose Partner Involved is same the partner contacts account
   								~ Add the partner to the sales team with a permission 'EDIT'
   								~ Updates the Registration Status of the oppty with 'Akamai Provided'
   Ali KM			16/12/11	CR 1440397 PRM: Update users who appear in the FR/FC/DR emails
   								~ As part of this CR, we need to ensure email is sent out only to Active Users, thus added isActive flag in User Query.
   Ali KM			1/Oct/12	CR 1900927 - License Alert
   								~ Added License Alert for SFDC (Standard) users licenses as well.   								   								
*/ 
global class PRMScheduledJobs {
    // Get all PRM_Settings__c custom settings and put it in a map.
    private static Map<string, PRM_Settings__c> PRMSettingsMap = PRM_Settings__c.getall();
    public static Messaging.SingleEmailMessage createSingleEmail(Id oppid,Id UserId,string CcEmail,string CaseCreateTemplate)
    {
        boolean CcEmailflag=false;
        if(CcEmail!='')
            CcEmailflag=true;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        String[] ccAddresses = CcEmail.split(',');
        mail.setWhatId(oppid);
        mail.setTargetObjectId(UserId);
        if(CcEmailflag==true)
            mail.setCcAddresses(ccAddresses);
        mail.setTemplateId(CaseCreateTemplate);
        mail.setSaveAsActivity(false);
        return mail;
        /*try{
          Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(exception e)
        {
        return e.getMessage();
        }
        return 'Success';*/
    }

    public static Task createtask(id usrid,string usralias,id taskwhatid,string subjecttext,string bodytext)
    {
        Task ta=new Task();
        ta.OwnerId=usrid;
        ta.WhatId=taskwhatid;
        ta.Subject=subjecttext;
        ta.Type__c='Email';
        ta.Description =bodytext;
        ta.Status='Completed';
        ta.AKAM_Created_By__c=usrAlias;
        ta.AKAM_Created_Date__c=Datetime.now();
        ta.AKAM_Modified_By__c=usrAlias;
        ta.AKAM_Modified_Date__c=Datetime.now();
        ta.AKAM_System__c='FORCE'; 
        return ta;       
        /*try{
          insert ta;
        }
        catch(exception e)
        {
        return e.getMessage();
        }
        return 'Success';*/
    }

    private static string getCcEmailListFromSubGroup(string subgroup)
    {
        string MatchCustomSettingValue= 'job-SubGroup#'+subgroup;
        //if(PRMSettingsMap.get(MatchCustomSettingValue).Value__c!=null)
        if(PRMSettingsMap.containsKey(MatchCustomSettingValue))
            return ','+PRMSettingsMap.get(MatchCustomSettingValue).Value__c;
        else
            return '';
    }
    private static string getCcEmailListFromGroup(string subgroup)
    {
        string MatchCustomSettingValue= 'job-Group#'+subgroup;
        //if(PRMSettingsMap.get(MatchCustomSettingValue).Value__c!=null)
        if(PRMSettingsMap.containsKey(MatchCustomSettingValue))
            return ','+PRMSettingsMap.get(MatchCustomSettingValue).Value__c;
        else
            return '';
    }
    private static string HandleNullManagerEmail(string ManagerEmail)
    {
        //string ManagerEmail='';
        if(ManagerEmail!=null)
            return ManagerEmail;
        else
            return '';
    }
    /*
       CR 1150381 PRM: Need to create a time-based WF for deal registration and MDF approvals
       A scheduled job will run everyday which sends email and creates task if any of
       the below condition is satisfied 
       1. Status=(deal:pending,FR:submitted) AND submitted date >24 hrs and <48hrs 
       2. Status=(deal:pending,FR:submitted) AND submitted date >48 hrs and <72hrs 					
     */
    public static string SendDealRegEmailReminder()
    {
        String result='';
        Boolean HasError=false;
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult>();	
        list<Task> taskList = new list<Task>();

        /**********Opportunity************/
        list<Opportunity> DealsPostOneDay = new list<Opportunity>();
        list<Opportunity> DealsPostTwoDays = new list<Opportunity>();
        string[] limits = (PRMSettingsMap.get('job#deal time limits').Value__c).split(':');
        integer lowerlimit=integer.valueof(limits[0]);
        integer middlelimit=integer.valueof(limits[1]);
        integer upperlimit=integer.valueof(limits[2]);
        for(Opportunity opp:[select id,Registration_Submitted_Date__c,FCM__c,FCM__r.Email,FCM__r.Alias,FCM__r.ManagerId,FCM__r.Manager.Email,Channel_Manager__r.Partner_SubGroup__c,Channel_Manager__r.Partner_Group__c from Opportunity where Registration_Status__c!=null AND Registration_Submitted_Date__c!=null AND Registration_Status__c=:PRMSettingsMap.get('job#deal Registration Status').Value__c and Registration_Submitted_Date__c<:Datetime.now().addHours(lowerlimit) and Registration_Submitted_Date__c>:Datetime.now().addHours(upperlimit) and CreatedDate = LAST_90_DAYS])
        {
            if(opp.Registration_Submitted_Date__c<Datetime.now().addHours(lowerlimit) && opp.Registration_Submitted_Date__c>Datetime.now().addHours(middlelimit))
                DealsPostOneDay.add(opp);
            if(opp.Registration_Submitted_Date__c<Datetime.now().addHours(middlelimit) && opp.Registration_Submitted_Date__c>Datetime.now().addHours(upperlimit))
                DealsPostTwoDays.add(opp);
            //result+='\nId:'+opp.id+',RegTime:'+opp.Registration_Submitted_Date__c;
        }

        result+='\nDeals After 1 day before 2 days';
        for(Opportunity opp:DealsPostOneDay)
        {
            result+='\nId:'+opp.id+',RegTime:'+opp.Registration_Submitted_Date__c+'FCM value='+opp.FCM__c;
            if(opp.FCM__c!=null)
            {

                sendEmailList.add(createSingleEmail(opp.id,opp.FCM__c,HandleNullManagerEmail(opp.FCM__r.Manager.Email),PRMSettingsMap.get('job#deal 24hr email templateid').Value__c));
                taskList.add(createtask(opp.FCM__c,opp.FCM__r.Alias,opp.id,PRMSettingsMap.get('job#deal 24hr task subject').Value__c,PRMSettingsMap.get('job#deal 24hr task body').Value__c));
            }
            //taskList.add(createtask(opp.FCM__c,opp.FCM__r.Alias,opp.id,PRMSettingsMap.get('job#deal 24hr task subject').Value__c,PRMSettingsMap.get('job#deal 24hr task body').Value__c));
        }

        result+='\nDeals After 2 days before 3 days';
        for(Opportunity opp:DealsPostTwoDays)
        {
            result+='\nId:'+opp.id+',RegTime:'+opp.Registration_Submitted_Date__c+'FCM value='+opp.FCM__c;
            if(opp.FCM__c!=null)
            {
                string DealEmailList = '';
                if(opp.Channel_Manager__r.Partner_SubGroup__c!=null)
                    DealEmailList=getCcEmailListFromSubGroup(opp.Channel_Manager__r.Partner_SubGroup__c);
                if(DealEmailList=='' && opp.Channel_Manager__r.Partner_Group__c!=null)
                    DealEmailList=getCcEmailListFromGroup(opp.Channel_Manager__r.Partner_Group__c);
                sendEmailList.add(createSingleEmail(opp.id,opp.FCM__c,HandleNullManagerEmail(opp.FCM__r.Manager.Email)+DealEmailList,PRMSettingsMap.get('job#deal 48hr email templateid').Value__c));
                taskList.add(createtask(opp.FCM__c,opp.FCM__r.Alias,opp.id,PRMSettingsMap.get('job#deal 48hr task subject').Value__c,PRMSettingsMap.get('job#deal 48hr task body').Value__c));
            } 
            //taskList.add(createtask(opp.FCM__c,opp.FCM__r.Alias,opp.id,PRMSettingsMap.get('job#deal 48hr task subject').Value__c,PRMSettingsMap.get('job#deal 48hr task body').Value__c));
        }




        /**********Fund Request************/
        list<SFDC_MDF__c> FRPostOneDay = new list<SFDC_MDF__c>();
        list<SFDC_MDF__c> FRPostTwoDays = new list<SFDC_MDF__c>();
        limits = (PRMSettingsMap.get('job#MDF time limits').Value__c).split(':');
        lowerlimit=integer.valueof(limits[0]);
        middlelimit=integer.valueof(limits[1]);
        upperlimit=integer.valueof(limits[2]);
        for(SFDC_MDF__c fr:[select id,Submitted_Date__c,Fund_Request_Approver__c,Fund_Request_Approver__r.Email,Fund_Request_Approver__r.Alias,Fund_Request_Approver__r.ManagerId,Fund_Request_Approver__r.Manager.Email from SFDC_MDF__c where Status__c=:PRMSettingsMap.get('job#MDF Status').Value__c and Submitted_Date__c<:Datetime.now().addHours(lowerlimit) and Submitted_Date__c>:Datetime.now().addHours(upperlimit)])
        {
            if(fr.Submitted_Date__c<Datetime.now().addHours(lowerlimit) && fr.Submitted_Date__c>Datetime.now().addHours(middlelimit))
                FRPostOneDay.add(fr);
            if(fr.Submitted_Date__c<Datetime.now().addHours(middlelimit) && fr.Submitted_Date__c>Datetime.now().addHours(upperlimit))
                FRPostTwoDays.add(fr);
            //result+='\nId:'+opp.id+',RegTime:'+opp.Registration_Submitted_Date__c;
        }

        string emaillist='';
        list<Id> userIdlist = new list<Id>();
        if(FRPostOneDay.size()>0 || FRPostTwoDays.size()>0)
        {
            For(GroupMember grp:[Select UserOrGroupId, GroupId From GroupMember where GroupId=:PRMSettingsMap.get('job#Fund Claim groupid').Value__c])
            {
                string uid=grp.UserOrGroupId;
                if(uid.startsWith(Schema.Sobjecttype.User.getKeyPrefix()))
                    userIdlist.add(grp.UserOrGroupId);
            }
            for(User usr:[select email from User where id IN :userIdlist AND isActive = true])
            {
                emaillist+=usr.email+',';
            }
            emaillist=emaillist.substring(0,emaillist.length()-1);
            result+='\nFR fund request queue email list:'+emaillist;
        }

        result+='\nFR After 1 day before 2 days';
        for(SFDC_MDF__c fr:FRPostOneDay)
        {
            result+='\nId:'+fr.id+',RegTime:'+fr.Submitted_Date__c+'Fund_Request_Approver__c value='+fr.Fund_Request_Approver__c;
            if(fr.Fund_Request_Approver__c!=null)
            {
                sendEmailList.add(createSingleEmail(fr.id,fr.Fund_Request_Approver__c,emaillist,PRMSettingsMap.get('job#MDF 24hr email templateid').Value__c));
                taskList.add(createtask(fr.Fund_Request_Approver__c,fr.Fund_Request_Approver__r.Alias,fr.id,PRMSettingsMap.get('job#MDF 24hr task subject').Value__c,PRMSettingsMap.get('job#MDF 24hr task body').Value__c));
            }
        }

        result+='\nFR After 2 days before 3 days';
        for(SFDC_MDF__c fr:FRPostTwoDays)
        {
            result+='\nId:'+fr.id+',RegTime:'+fr.Submitted_Date__c+'Fund_Request_Approver__c value='+fr.Fund_Request_Approver__c;
            if(fr.Fund_Request_Approver__c!=null)
            {
                string ccaddress='';
                if(emaillist!='')
                    ccaddress=HandleNullManagerEmail(fr.Fund_Request_Approver__r.Manager.Email)+','+emaillist;
                else
                    ccaddress=HandleNullManagerEmail(fr.Fund_Request_Approver__r.Manager.Email);
                sendEmailList.add(createSingleEmail(fr.id,fr.Fund_Request_Approver__c,ccaddress,PRMSettingsMap.get('job#MDF 48hr email templateid').Value__c));
                taskList.add(createtask(fr.Fund_Request_Approver__c,fr.Fund_Request_Approver__r.Alias,fr.id,PRMSettingsMap.get('job#MDF 48hr task subject').Value__c,PRMSettingsMap.get('job#MDF 48hr task body').Value__c));
            }
            //taskList.add(createtask(fr.Fund_Request_Approver__c,fr.Fund_Request_Approver__r.Alias,fr.id,PRMSettingsMap.get('job#MDF 48hr task subject').Value__c,PRMSettingsMap.get('job#MDF 48hr task body').Value__c));
        }




        /**********SEND EMAIL ************/
        if (sendEmailList.size()>0)
        {
            result+='\nSending Email started:';
            integer count=0;
            integer failedcount=0;
            sendEmailResultList = Messaging.sendEmail(sendEmailList, false);
            for(Messaging.SendEmailResult sr:sendEmailResultList){
                if(!sr.isSuccess())
                {
                    //string err = sr.getErrors();//[0];
                    result+='\nError getMessage:'+sr.getErrors()[0].getMessage();
                    result+='##getFields:'+sr.getErrors()[0].getFields();
                    result+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
                    result+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();
                    result+='##record count:'+count;
                    failedcount++;
                    HasError=true;
                }
                count++;
            }
            /*for (Integer k=0; k<sendEmailResultList.size(); k++)
              {
              if (sendEmailResultList.get(k).isSuccess())
              count++;

            //else
            //reminderEmailSuccess = false;
            // need to add try catch to mail failures to the SF Recipient.
            }*/
            result+='\nNo. Of emails sent:'+(count-failedcount);
        }




        /**********Create task************/
        if(taskList.size()>0)
        {
            result+='\nStart Task insertion:';
            integer count=0;
            integer failedcount=0;
            Database.SaveResult[] lsr = Database.insert(taskList,false);

            for(Database.SaveResult sr:lsr){
                if(!sr.isSuccess())
                {
                    Database.Error err = sr.getErrors()[0];
                    result+='\nError getMessage:'+err.getMessage();
                    result+='##getStatusCode:'+err.getStatusCode();
                    result+='##record count:'+count;
                    failedcount++;
                    HasError=true;
                }
                count++;
            }
            result+='\nNo. Of tasks inserted:'+(count-failedcount);
        }
        if(HasError==true)
            return '0:'+result;
        else
            return '1:'+result;
    }
    /*
       CR 1162207 PRM: Add partner admin to sales team of all opportunities
       ~ A scheduled job will run everyday which gets all users created in less than 24 hrs and profile is 'Akamai Partner Administrator'
       ~ Gets all Opptys whose Partner Involved is same the partner contacts account
       ~ Add the partner to the sales team with a permission 'EDIT'
       ~ Updates the Registration Status of the oppty with 'Akamai Provided'
     */
    public static string AddPartnerAdminToSalesTeam()
    {
        String result='';
        Boolean HasError=false;
        map<id,list<User>> AccIdUserMap = new map<id,list<User>>();
        //list<OpportunityTeamMember> otmList = new list<OpportunityTeamMember>();
        list<OpportunityShare> osshareList = new list<OpportunityShare>();
        set<Opportunity> opptylist = new set<Opportunity>();
        string partnerAdminProfile=PRMSettingsMap.get('Partner Admin Profile').Value__c;
        //Get all users 
        for(User usr:[select id,AccountId__c from User where CreatedDate<:Datetime.now() AND CreatedDate>:Datetime.now().addHours(-24)  AND User_Profile_Name__c=:partnerAdminProfile])
        {
            if(AccIdUserMap.get(usr.AccountId__c)==null)
                AccIdUserMap.put(usr.AccountId__c,new list<User>());

            AccIdUserMap.get(usr.AccountId__c).add(usr);
            result+='\n usr Id:'+usr.id;
        }
        //Get all Opptys
        for(Opportunity opp:[select id,Partner_Involved__c,OwnerId,CreatedById,Registration_Status__c,AccountId from Opportunity where IsClosed=false AND Partner_Involved__c IN :AccIdUserMap.keySet()])
        {
            for(User usr:AccIdUserMap.get(opp.Partner_Involved__c))
            {
                if(opp.OwnerId!=usr.id && opp.CreatedById!=usr.id && opp.AccountId!=opp.Partner_Involved__c)
                {
                    //Adding to Sales team is no longer needed.
                    /*OpportunityTeamMember member = new OpportunityTeamMember();
                      member.OpportunityId = opp.id;
                      member.UserId = usr.id;
                      member.TeamMemberRole = 'Partner';
                      otmList.add(member);*/
                    OpportunityShare osshare = new OpportunityShare();
                    osshare.OpportunityId = opp.id;
                    osshare.UserOrGroupId = usr.id;
                    osshare.OpportunityAccessLevel ='Edit';
                    osshareList.add(osshare);

                    result+='\nOppty Id:'+opp.id;
                    if(opp.Registration_Status__c==null || opp.Registration_Status__c=='')
                    {
                        opp.Registration_Status__c='Akamai Provided';
                        opptylist.add(opp);
                    }
                }
            }
        }

        /**********Upsert Sales Team member************
          if(otmList.size()>0)
          {
          result+='\nStart Sales Team members insertion:';
          integer count=0;
          integer failedcount=0;
          Database.SaveResult[] lsr = Database.insert(otmList,false);

          for(Database.SaveResult sr:lsr){
          if(!sr.isSuccess())
          {
          Database.Error err = sr.getErrors()[0];
          result+='\nError getMessage:'+err.getMessage();
          result+='##getStatusCode:'+err.getStatusCode();
          result+='##record count:'+count;
          failedcount++;
          HasError=true;
          }
          count++;
          }
          result+='\nNo. Of Sales Team members inserted:'+(count-failedcount);
          }


         **********Upsert Sales table entry************/
        if(osshareList.size()>0)
        {
            result+='\nStart Sales table entry insertion:';
            integer count=0;
            integer failedcount=0;
            Database.SaveResult[] lsr = Database.insert(osshareList,false);

            for(Database.SaveResult sr:lsr){
                if(!sr.isSuccess())
                {
                    Database.Error err = sr.getErrors()[0];
                    result+='\nError getMessage:'+err.getMessage();
                    result+='##getStatusCode:'+err.getStatusCode();
                    result+='##record count:'+count;
                    failedcount++;
                    HasError=true;
                }

                count++;
            }
            result+='\nNo. Of Sales table entry inserted:'+(count-failedcount);
        }


        /**********update opportunity************/
        if(opptylist.size()>0)
        {
            list<Opportunity> newopptylist = new list<Opportunity>();
            for(Opportunity opp:opptylist)
                newopptylist.add(opp);
            result+='\nStart Opporunity update:';
            integer count=0;
            integer failedcount=0;
            Database.SaveResult[] lsr = Database.update(newopptylist,false);

            for(Database.SaveResult sr:lsr){
                if(!sr.isSuccess())
                {
                    Database.Error err = sr.getErrors()[0];
                    result+='\nError getMessage:'+err.getMessage();
                    result+='##getStatusCode:'+err.getStatusCode();
                    result+='##record count:'+count;
                    failedcount++;
                    HasError=true;
                }

                count++;
            }
            result+='\nNo. Of  Opporunity updated:'+(count-failedcount);
        }
        if(HasError==true)
            return '0:'+result;
        else
            return '1:'+result;
    }

    public static String sendNotficationMailForNAPLicense()
    {
        String result='1:';
        Messaging.SingleEmailMessage[] sendLicenseAlertEmailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SendEmailResult[] sendEmailResultList1 = new List<Messaging.SendEmailResult>();

        try
        {
            // NAP User Critical Alert
            Integer usedPartnerLicenses=[select count() from User where userType like '%Partner%' and isActive = true];
            Integer totalPartnerLicenses=Integer.valueOf(GsmUtilClass.getGSMSettingValue('NetAlliancePortalTotalLicense'));
            Integer criticalLicenseCount=Integer.valueOf(GsmUtilClass.getGSMSettingValue('NetAlliancePortalCriticalLicense'));
            Integer licenseLeft=totalPartnerLicenses-usedPartnerLicenses;

            String toEmailAddress=GsmUtilClass.getGSMSettingValue('NAPCriticalLicenseSendMailTo');
            String[] toAddresses = toEmailAddress.split(',');
            result=result+' TotalPartnerLicenses='+totalPartnerLicenses+'\n'
                +'CriticalLicenseCount='+criticalLicenseCount+'\n'
                +'UsedPartnerLicenses='+usedPartnerLicenses+'\n'
                +'Email To Address='+toEmailAddress;
            String subject=GsmUtilClass.getGSMSettingValue('NAPCriticalLicenseMailSubject');
            String mailBody=GsmUtilClass.getGSMSettingValue('NAPCriticalLicenseMailBody')+GsmUtilClass.getGSMSettingValue('NAPCriticalLicenseMailBody1');
            mailBody=mailBody.replace('#licenseLeft#', licenseLeft.format());
            mailBody=mailBody.replace('#userName#',GsmUtilClass.getGSMSettingValue('NAPCriticalLicenseMailAddressTo'));
            if((totalPartnerLicenses-usedPartnerLicenses)<=criticalLicenseCount)
            {
                Messaging.SingleEmailMessage emsg=new Messaging.SingleEmailMessage();
                emsg.setToAddresses(toAddresses);//(new List<String>{toEmailAddress});
                eMsg.setHtmlBody(mailBody);
                eMsg.setSubject(subject);
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emsg});
                sendLicenseAlertEmailList.add(emsg);
            }

            // SFDC (Standard) User Critical Alert
            Integer usedSFDCLicenses=[Select count() from User where isActive = true  AND Profile.UserLicense.LicenseDefinitionKey = 'SFDC'];
            Integer totalSFDCLicenses=Integer.valueOf(GsmUtilClass.getGSMSettingValue('SFDCLicenseCountTotal'));
            Integer criticalSFDCLicenseCount=Integer.valueOf(GsmUtilClass.getGSMSettingValue('SFDCLicenseCountCritical'));
            Integer sfdcLicensesLeft=totalSFDCLicenses-usedSFDCLicenses;

            String toEmailAddress1=GsmUtilClass.getGSMSettingValue('SFDCCriticalLicenseSendMailTo');
            String[] toAddresses1 = toEmailAddress1.split(',');
            result=result+'\n\n TotalSFDCLicenses='+totalSFDCLicenses+'\n'
                +'CriticalSFDCLicenseCount='+criticalSFDCLicenseCount+'\n'
                +'UsedSFDCLicenses='+usedSFDCLicenses+'\n'
                +'Email To Address='+toEmailAddress1;
            String subject1=GsmUtilClass.getGSMSettingValue('SFDCCriticalLicenseMailSubject');
            String mailBody1=GsmUtilClass.getGSMSettingValue('SFDCCriticalLicenseMailBody')+GsmUtilClass.getGSMSettingValue('SFDCCriticalLicenseMailBody1');
            mailBody1=mailBody1.replace('#licenseLeft#', sfdcLicensesLeft.format());
            mailBody1=mailBody1.replace('#userName#',GsmUtilClass.getGSMSettingValue('SFDCCriticalLicenseMailAddressTo'));
            if((totalSFDCLicenses-usedSFDCLicenses)<=criticalSFDCLicenseCount)
            {
                Messaging.SingleEmailMessage emsg1=new Messaging.SingleEmailMessage();
                emsg1.setToAddresses(toAddresses1);//(new List<String>{toEmailAddress});
                eMsg1.setHtmlBody(mailBody1);
                eMsg1.setSubject(subject1);
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emsg1});
                sendLicenseAlertEmailList.add(emsg1);
            }

            // Service Cloud User Critical Alert
            Integer usedServiceCloudLicenses=[Select count() from User where isActive = true  AND USERPERMISSIONSSUPPORTUSER = true ];
            Integer totalServiceCloudLicenses=Integer.valueOf(GSM_Custom_Settings__c.getInstance('SCLicenseCountTotal').value__c);
            Integer criticalServiceCloudLicenseCount=Integer.valueOf(GSM_Custom_Settings__c.getInstance('SCLicenseCountCritical').value__c);
            Integer ServiceCloudLicensesLeft=totalServiceCloudLicenses-usedServiceCloudLicenses;
            String toEmailAddress2=GSM_Custom_Settings__c.getInstance('SCCriticalLicenseSendMailTo').value__c;
            String[] toAddresses2 = toEmailAddress2.split(',');
            result=result+'\n\n TotalServiceCloudLicenses='+totalServiceCloudLicenses+'\n'
                +'CriticalServiceCloudLicenseCount='+criticalServiceCloudLicenseCount+'\n'
                +'UsedServiceCloudLicenses='+usedServiceCloudLicenses+'\n'
                +'Email To Address='+toEmailAddress2;
            String subject2=GSM_Custom_Settings__c.getInstance('SCCriticalLicenseMailSubject').value__c;
            String mailBody2=GSM_Custom_Settings__c.getInstance('SCCriticalLicenseMailBody').value__c+GSM_Custom_Settings__c.getInstance('SCCriticalLicenseMailBody1').value__c;
            mailBody2=mailBody2.replace('#licenseLeft#', ServiceCloudLicensesLeft.format());

            mailBody2=mailBody2.replace('#userName#',GSM_Custom_Settings__c.getInstance('SCCriticalLicenseAlertTo').value__c);
            if((totalServiceCloudLicenses-usedServiceCloudLicenses)<=criticalServiceCloudLicenseCount)
            {
                Messaging.SingleEmailMessage emsg2=new Messaging.SingleEmailMessage();
                emsg2.setToAddresses(toAddresses2);//(new List<String>{toEmailAddress});
                eMsg2.setHtmlBody(mailBody2);
                eMsg2.setSubject(subject2);
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emsg2});
                sendLicenseAlertEmailList.add(emsg2);
            }



            // Knowledge User Critical Alert
            Integer usedKnowledgeUserLicenses=[Select count() from User where isActive = true  AND USERPERMISSIONSKNOWLEDGEUSER  = true ];
            Integer totalKnowledgeUserLicenses=Integer.valueOf(GSM_Custom_Settings__c.getInstance('KULicenseCountTotal').value__c);
            Integer criticalKnowledgeUserLicenseCount=Integer.valueOf(GSM_Custom_Settings__c.getInstance('KULicenseCountCritical').value__c);
            Integer KnowledgeUserLicensesLeft=totalKnowledgeUserLicenses-usedKnowledgeUserLicenses;

            String toEmailAddress3=GSM_Custom_Settings__c.getInstance('KUCriticalLicenseSendMailTo').value__c;
            String[] toAddresses3 = toEmailAddress3.split(',');
            result=result+'\n\n TotalKnowledgeUserLicenses='+totalKnowledgeUserLicenses+'\n'
                +'CriticalKnowledgeUserLicenseCount='+criticalKnowledgeUserLicenseCount+'\n'
                +'UsedKnowledgeUserLicenses='+usedKnowledgeUserLicenses+'\n'
                +'Email To Address='+toEmailAddress3;
            String subject3=GSM_Custom_Settings__c.getInstance('KUCriticalSubject').value__c;
            String mailBody3=GSM_Custom_Settings__c.getInstance('KUCriticalLicenseMailBody').value__c+GSM_Custom_Settings__c.getInstance('KUCriticalLicenseMailBody1').value__c;
            mailBody3=mailBody3.replace('#licenseLeft#', KnowledgeUserLicensesLeft.format());
            mailBody3=mailBody3.replace('#userName#',GSM_Custom_Settings__c.getInstance('KUCriticalAlertAddressTo').value__c);
            if((totalKnowledgeUserLicenses-usedKnowledgeUserLicenses)<=criticalKnowledgeUserLicenseCount)
            {
                Messaging.SingleEmailMessage emsg3=new Messaging.SingleEmailMessage();
                emsg3.setToAddresses(toAddresses3);//(new List<String>{toEmailAddress});
                eMsg3.setHtmlBody(mailBody3);
                eMsg3.setSubject(subject3);
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emsg3});
                sendLicenseAlertEmailList.add(emsg3);
            }


            if (sendLicenseAlertEmailList.size()>0)  
                sendEmailResultList1 = Messaging.sendEmail(sendLicenseAlertEmailList, false);
        }
        catch(Exception e)
        {
            result='0#'+e.getMessage();
        }
        return result;
    }
}