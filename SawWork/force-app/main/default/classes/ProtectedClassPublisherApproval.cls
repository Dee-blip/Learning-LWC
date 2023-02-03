global class ProtectedClassPublisherApproval {

    private ApexPages.StandardController standardController;

    public ProtectedClassPublisherApproval(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
    }

    public void pageApprove()
    {
        String result = '';
        Id recordId = standardController.getId();
        Protected_Class_Publisher__c record = (Protected_Class_Publisher__c) standardController.getRecord();

        result = recordApprove(recordId);

        if (result == 'Approved') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Approved'));
        }
        else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,result));
        }
    }

    public void pageDeny()
    {
        String result = '';
        Id recordId = standardController.getId();
        Protected_Class_Publisher__c record = (Protected_Class_Publisher__c) standardController.getRecord();

        result = recordDeny(recordId);

        if (result == 'Denied') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Denied'));
        }
        else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,result));
        }
    }

    @AuraEnabled
    webservice static String recordApprove(Id recId)
    {

        System.debug('inside 114');

        String result = '';
        String regionStr;
        String geography;
        //String division;
        List<Account> acc = new List<Account>();
        List<String> approvers = new List<String>();
        List<Protected_Class_Publisher__c> protectedPubls = new List<Protected_Class_Publisher__c>();
        List<AggregateResult> regMap = new List<AggregateResult>();
        String loggedinUser = [select Alias from user where id =: UserInfo.getUserId() ].Alias ;
        List<String> userTitles = new List<String>();

        userTitles.addAll( ([select Value__c from RAMD_Setting__mdt where DeveloperName = 'RAMD_Protected_Class_Approver_Titles' limit 1].Value__c).split(',') );

        protectedPubls = [select id,Approved_By__c ,Approvers__c,Status__c, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_1__c , Escalated__c from Protected_Class_Publisher__c where id in (:recId)];

        //egionStr = protectedPubls.get(0).Account__r.TERR_HIER_2__c + ' (Region)';
        //geography = protectedPubls.get(0).Account__r.TERR_HIER_1__c + ' (Geography)';
        //division = protectedPubls.get(0).Account__r.Division_Formula__c + ' (Division)';
        regMap = [select User__r.Alias, User__r.Title ,User__r.Email , User__r.Manager.Alias ManAl  from Inv_WorkBox_Region_Mapping__c 
            where RecordType.Name = 'RAMD'
            GROUP BY User__r.Alias,User__r.Email, User__r.Title, User__r.Manager.Alias ];
        

        System.debug(' all users : ' + regMap );


        System.debug('user titles ' + userTitles );
        for(AggregateResult region: regMap )
        {
            Boolean titleFound = true; // making default value this flag true because last minute change was suggested to remove the title check
            /* for (String usrTitle : userTitles) {
                    if(region.get('Title') != null && region.get('Title').toString().contains(usrTitle) )
                    {
                        titleFound = true;
                    }
                } */
            
            System.debug('user and user title and condition : ' + (region.get('Alias') != null  && titleFound && ( !protectedPubls.get(0).Escalated__c ) ) );
            if(region.get('Alias') != null  && titleFound && ( !protectedPubls.get(0).Escalated__c ) )
            {
                approvers.add(region.get('Alias').toString());
            } else if(region.get('Alias') != null  && titleFound && protectedPubls.get(0).Escalated__c  ){
                approvers.add(region.get('Alias').toString());
                approvers.add(region.get('ManAl').toString() );
            }
        }

        System.debug('all approvers :' + approvers);
            

        if( !approvers.isEmpty() && approvers.contains(loggedinUser) && protectedPubls.get(0).Status__c == 'Pending'  )
        {
            protectedPubls.get(0).Status__c = 'Approved';
            protectedPubls.get(0).Approved_By__c = UserInfo.getUserId() ;
            result = 'Approved';
        }
        else if ( !approvers.isEmpty() && (protectedPubls.get(0).Status__c == 'Approved' ||   protectedPubls.get(0).Status__c == 'denied' ) )
        {
            result = ' This record has already been approved/denied ';
        }
        else 
        {
            result = ' You are not authorised to approve this record ';
        }

        System.debug('disply result : ' + result );

        if(result == 'Approved')
        {
            update protectedPubls;
        }

        return result;

    }

    @AuraEnabled
    webservice static String recordDeny(Id recId)
    {
        String result = '';
        String regionStr;
        String geography;
        //String division;
        List<Account> acc = new List<Account>();
        List<String> approvers = new List<String>();
        List<AggregateResult> regMap = new List<AggregateResult>();
        List<Protected_Class_Publisher__c> protectedPubls = new List<Protected_Class_Publisher__c>();
        List<String> userTitles = new List<String>();

        userTitles.addAll( ([select Value__c from RAMD_Setting__mdt where DeveloperName = 'RAMD_Protected_Class_Approver_Titles' limit 1].Value__c).split(',') );

        String loggedinUser = [select Alias from user where id =: UserInfo.getUserId() ].Alias ;

        protectedPubls = [select id,Approved_By__c ,Approvers__c,Status__c, Account__r.TERR_HIER_2__c , Account__r.TERR_HIER_1__c , Escalated__c from Protected_Class_Publisher__c where id in (:recId)];

        regionStr = protectedPubls.get(0).Account__r.TERR_HIER_2__c + ' (Region)';
        geography = protectedPubls.get(0).Account__r.TERR_HIER_1__c + ' (Geography)';
        //division = protectedPubls.get(0).Account__r.Division_Formula__c + ' (Division)';
        regMap = [select User__r.Alias, User__r.Title ,User__r.Email , User__r.Manager.Alias ManAl from Inv_WorkBox_Region_Mapping__c 
            where RecordType.Name = 'RAMD'
            GROUP BY User__r.Alias,User__r.Email, User__r.Title, User__r.Manager.Alias ];

        for(AggregateResult region: regMap )
        {
            Boolean titleFound = true; // making default value this flag true because last minute change was suggested to remove the title check
            /* for (String usrTitle : userTitles) {
                    if(region.get('Title') != null && region.get('Title').toString().contains(usrTitle) )
                    {
                        titleFound = true;
                    }
                } */
            
            if(region.get('Alias') != null  && titleFound && ( !protectedPubls.get(0).Escalated__c ) )
            {
                approvers.add(region.get('Alias').toString());
            } else if(region.get('Alias') != null  && titleFound && protectedPubls.get(0).Escalated__c  ){
                approvers.add(region.get('Alias').toString());
                approvers.add(region.get('ManAl').toString() );
            }
        }

        System.debug(' deny :' + approvers + ' al ch cndtn : ' + ( !approvers.isEmpty() && approvers.contains(loggedinUser) && protectedPubls.get(0).Status__c == 'Pending'  ) );


        if( !approvers.isEmpty() && approvers.contains(loggedinUser) && protectedPubls.get(0).Status__c == 'Pending'  )
        {
            protectedPubls.get(0).Status__c = 'Denied';
            result = 'Denied';
        }
        else if ( !approvers.isEmpty() && (protectedPubls.get(0).Status__c == 'Approved' ||   protectedPubls.get(0).Status__c == 'denied' ) )
        {
            System.debug('has not reachde ' + (protectedPubls != null && protectedPubls.size() > 0 &&  protectedPubls.get(0).Approvers__c != null && protectedPubls.get(0).Approvers__c.split(',').contains(loggedinUser) && protectedPubls.get(0).Status__c == 'Pending'  ) + ' scnd cnd : ' + (protectedPubls != null && protectedPubls.size() > 0 && (protectedPubls.get(0).Status__c == 'Approved' ||   protectedPubls.get(0).Status__c == 'denied' ) ));
            result = ' This record has already been approved/denied ';
        }
        else 
        {
            result = ' You are not authorised to deny this record ';
        }

        if(result == 'Denied')
        {
            update protectedPubls;
        }

        return result;

    }

    Public static void protectedClassPublisherEscalation2(List<Protected_Class_Publisher__c> newProtectedClass, Map<Id, Protected_Class_Publisher__c> oldProtectedClassMap)
    {
        List<Id> protectedPublsIds = new List<Id>();
        List<Protected_Class_Publisher__c> publishers = new List<Protected_Class_Publisher__c>();
        List<Protected_Class_Publisher__c> publishersDetail = new List<Protected_Class_Publisher__c>();
        Map<Id, List<String>> escalatedProtectedClassList = new Map<Id, List<String>>();

        for(Protected_Class_Publisher__c protectedPubls: newProtectedClass)
        {
            
            if( !oldProtectedClassMap.get(protectedPubls.Id).Escalated__c && protectedPubls.Escalated__c )
            {
                    protectedPublsIds.add(protectedPubls.Id);
                    publishers.add(protectedPubls);
                    //regionList.add(protectedClassMap.get(protectedPubls.Id).Account__r.Region__c + ' (Region)');
                    //geographyList.add(protectedClassMap.get(protectedPubls.Id).Account__r.TERR_HIER_1__c + ' (Geography)');
                    //divisionList.add(protectedClassMap.get(protectedPubls.Id).Account__r.TERR_HIER_2__c + ' (Division)');
            }
        }

        publishersDetail = [select id, User__r.id , User__r.Name , Account__c , Account__r.Name from Protected_Class_Publisher__c where id IN :protectedPublsIds ];


        if(!publishers.isEmpty() && publishers.size() > 0 )
        {
            escalatedProtectedClassList = checkApprovers(publishersDetail);

            System.debug('will here ch: ' + escalatedProtectedClassList );

            for(Protected_Class_Publisher__c protectedPubls: newProtectedClass)
            {
                if(protectedPublsIds.contains(protectedPubls.Id))
                {
                    protectedPubls.Approvers__c = string.join(escalatedProtectedClassList.get(protectedPubls.Id),',');
                }
            }
            System.debug('after loop');
        }

        System.debug('at the end ');

    }



    public Static Map<Id, List<String> > checkApprovers(List<Protected_Class_Publisher__c> publishers)
    {
        Map<Id, List<String> > lApprover = new Map<Id, List<String>>();
        List<Id> allAccIds = new List<Id>();
        Set<String> regionNames = new Set<String>();
        Set<String> geoNames = new Set<String>();
        Set<String> divNames = new Set<String>();
        List<Inv_WorkBox_Region_Mapping__c> lregMap = new List<Inv_WorkBox_Region_Mapping__c>();
        Map<Id, List<String>> accIdToDGR = new Map<Id, List<String>>();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        List<String> userEmails = new List<String>();
        List<String> userTitles = new List<String>();
        String orgWideEmailId;
        PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress');
        String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';
        try
        {
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id;
        }
        catch(Exception e)
        {
            orgWideEmailId = null;
        }

        userTitles.addAll( ([select Value__c from RAMD_Setting__mdt where DeveloperName = 'RAMD_Protected_Class_Approver_Titles' limit 1].Value__c).split(',') );

        for(Protected_Class_Publisher__c  eachPub: publishers){
            allAccIds.add(eachPub.Account__c);
        }


        List<Account> accountRecs = new List<Account>([select Id, Owner.Alias, TERR_HIER_2__c, TERR_HIER_1__c from Account where id IN :allAccIds]);

        for(Account eachAcc : accountRecs){


            regionNames.add(eachAcc.TERR_HIER_2__c + ' (Region)');
            geoNames.add(eachAcc.TERR_HIER_1__c + ' (Geography)');
            //divNames.add(eachAcc.Division_Formula__c + ' (Division)'); 

            List<String> lDGR = new List<String>();
            lDGR.add(eachAcc.TERR_HIER_2__c + ' (Region)');
            lDGR.add(eachAcc.TERR_HIER_1__c + ' (Geography)');
            //lDGR.add(eachAcc.Division_Formula__c + ' (Division)');

            if(!accIdToDGR.containsKey(eachAcc.Id)){
                accIdToDGR.put(eachAcc.Id, lDGR);    
            }
            
        }

        System.debug('regionNames : ' + regionNames );

        System.debug('geoNames : ' + geoNames );

        lregMap = [SELECT 
                        User__r.Alias, User__r.Title ,User__r.Id ,User__r.Email, User__r.ManagerId, User__r.Manager.Email , User__r.Manager.Alias , TERR_HIER_2__r.Name , TERR_HIER_2_F__c , TERR_HIER_1__r.Name, TERR_HIER_1_F__c 
                    FROM Inv_WorkBox_Region_Mapping__c 
                    WHERE (TERR_HIER_2__r.Name IN :regionNames OR TERR_HIER_2_F__c = '*')
                    AND (TERR_HIER_1__r.Name IN :geoNames OR TERR_HIER_1_F__c = '*')
                    AND RecordType.Name = 'RAMD'];


        if(!lregMap.isEmpty()){
            for(Protected_Class_Publisher__c eachPub : publishers)
            {
                System.debug('inside 1s for :');
                List<String> escalatedApprovers = new List<String>();
                for(Inv_WorkBox_Region_Mapping__c urMap :  lregMap)
                {
                    System.debug('cvals cnondion  : ' + ( (urMap.TERR_HIER_2__r.Name == accIdToDGR.get(eachPub.Account__c).get(0) || urMap.TERR_HIER_2_F__c == '*')  &&
                        (urMap.TERR_HIER_1__r.Name == accIdToDGR.get(eachPub.Account__c).get(1) || urMap.TERR_HIER_1_F__c == '*')  ) );
                    Boolean titleFound = false;
                    for (String usrTitle : userTitles) {
                            if(urMap.User__r.Title.contains(usrTitle) )
                            {
                                titleFound = true;
                            }
                        }

                    if( (urMap.TERR_HIER_2__r.Name == accIdToDGR.get(eachPub.Account__c).get(0) || urMap.TERR_HIER_2_F__c == '*')  &&
                        (urMap.TERR_HIER_1__r.Name == accIdToDGR.get(eachPub.Account__c).get(1) || urMap.TERR_HIER_1_F__c == '*') &&
                        titleFound )
                    {
                        escalatedApprovers.add(urMap.User__r.Manager.Alias);
                        userEmails.add(urMap.User__r.Manager.Email);
                    }
                    System.debug('esc apprs : ' + escalatedApprovers);
                }


                lApprover.put(eachPub.Id, escalatedApprovers);
                sendMail_RAMD( userEmails , eachPub.User__r.Id , orgWideEmailId, mailsToBeSent , eachPub , 'RAMD: Protected Class Publisher is awaiting for approval', true );
            }

            if(mailsToBeSent.size() > 0)
            {
                Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
                for(Messaging.SendEmailResult emailResult : mailSendResult)
                {
                    System.debug('Email result ' + emailResult.IsSuccess());
                    System.debug('Individ rsll :' + emailResult);
                }
            }
        }

        return lApprover;            
        
    }

    public static void sendMail_RAMD(List<String> toAddress, Id targetObjectId, String orgWideEmailId, Messaging.SingleEmailMessage[] mailsToBeSent, Protected_Class_Publisher__c protectedPublisher, String subject, Boolean escalated )
    {
        String escalation;

        if (escalated ) {
            escalation = ' And you have not approved or denied this request,';   
        } else if (!escalated) {
            escalation = ' ';
        }
        
        String htmlBody = '<html><head><link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">' +
        '<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>' +
        '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>' +
        '<style>table {width:100%;}table, th, td {border: 1px solid black;border-collapse: collapse;}th, td {padding: 15px;' +
        'text-align: center;}table#t01 th {background-color: rgb(0, 109, 204);color: white;height: 70px;}body{padding: 30px;}' +
        '.btn {background-color: rgb(0, 109, 204);}</style></head><body></br><table id="t01"><tr>' +
        '<th id="th01" colspan="1" ><font face="verdana" color="White">RAMD</font></th></tr><tr><td><font face="verdana" color="Black"></br></font>' +
        'A user has requested that they be added to a protected class account for which you are an approver.' + escalation + ' This user cannot push customer metadata to the production network until you have approved their access request.' +
        '</br></br><table id="t02"><tr>' +
        '<td><font face="verdana" color="Black">Internal Akamai User</br><b>' + protectedPublisher.User__r.Name + 
        '</b></font></td>' +
        '<td colspan="2" ><font face="verdana" color="Black">Protected Class Account</br><b>' + protectedPublisher.Account__r.Name +
        '</b></font></td>' +
        '</tr></table></br></br>' +
        'As soon as possible, please log in to the Protected Class <a href=" ' + URL.getSalesforceBaseUrl().toExternalForm()+'/'+protectedPublisher.Id + ' ">Control Panel</a> in Salesforce to review this access request.</br></td></tr></table></br>' +
        '<div class="container" align = "center" id="btn" height="10px">' +
        '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + protectedPublisher.Id + 
        '" class="btn btn-primary" role="button"><font face="verdana" color="White">Take Action?</font></a>' +
        '</div></br></br></br></body></html>';

        Messaging.SingleEmailMessage objEmail = new Messaging.Singleemailmessage();
        objEmail.setToAddresses(toAddress);

        objEmail.setReplyTo('noreply@akamai.com');

        objEmail.setHtmlBody(htmlBody);

        if(targetObjectId != null)
        {
          objEmail.setTargetObjectId(targetObjectId);
        }

        if( subject != null )
        {
            objEmail.setSubject(subject);
        }
        
        if (orgWideEmailId != null)
        {
          objEmail.setOrgWideEmailAddressId(orgWideEmailId);
        }

        objEmail.saveAsActivity = false ;
        mailsToBeSent.add(objEmail);
        System.debug('check each mail : ' + objEmail );

        
    }
    
    public static void costCenterTeamMemberCheck(List<Protected_Class_Publisher__c> newList)
    {
        User protectedClassUser = new User();
        protectedClassUser = [select Cost_Center__c from User where id IN(:newList.get(0).User__c) limit 1 ];
        
        System.debug('user cost cent :' + protectedClassUser);
        
        String userCostCenter = String.valueOf(protectedClassUser.Cost_Center__c);
        
        System.debug('user cost cent to string :' + userCostCenter);
                
        List<RAMD_Cost_Center__c> costCenter = new List<RAMD_Cost_Center__c>();
        costCenter = [select Cost_Center__c from RAMD_Cost_Center__c where IsActive__c =true AND Cost_Center__c IN (:userCostCenter) ];
        
        System.debug('cost cent obj :' + costCenter);
        
        List<AccountTeamMember> teamMember = new List<AccountTeamMember>();
        teamMember = [select id,UserId,AccountId from AccountTeamMember where AccountId IN(: newList.get(0).Account__c) AND UserId IN(:newList.get(0).User__c) ];
        
        System.debug('teamMember :' + teamMember + ' new list account  '  + newList.get(0).Account__c);

        if(costCenter.isEmpty() || teamMember.isEmpty() )
        {
            newList.get(0).addError('Please add user as Account Team Member and has valid RAMD Cost Center');

        }

    }

    public static void duplicateCheck(List<Protected_Class_Publisher__c> protectedClassList)
    {
        List<Protected_Class_Publisher__c> protectedClassPub = new List<Protected_Class_Publisher__c>();

        protectedClassPub = [select id, Name , Account__c , Status__c , User__c from Protected_Class_Publisher__c where User__c	IN (:protectedClassList.get(0).User__c) AND Account__c IN (:protectedClassList.get(0).Account__c) AND Status__c IN ('Approved','Pending') limit 1 ];

        if(!protectedClassPub.isEmpty())
        {
            protectedClassList.get(0).addError('There is already a Protected Class Publisher record with same User and Account : ' + protectedClassPub.get(0).Name );
            //return;
        }
    }

    public static void protectedClassSubmit(List<Protected_Class_Publisher__c> protectedClassList)
    {

        List<Protected_Class_Publisher__c> protectedClassEmailList = new List<Protected_Class_Publisher__c>();
        Protected_Class_Publisher__c protectedClassEmail = new Protected_Class_Publisher__c();
        String regionStr;
        String geography;
        //String division;
        String users = '';
        List<Account> acc = new List<Account>();
        List<Protected_Class_Publisher__c> protectedPubls = new List<Protected_Class_Publisher__c>();
        List<AggregateResult> regMap = new List<AggregateResult>();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        List<String> aliases = new List<String>();
        List<String> approverEmailList = new List<String>();
        List<String> userTitles = new List<String>();

        Protected_Class_Publisher__c protectedClassUpdate = new Protected_Class_Publisher__c();
        protectedClassUpdate = [select id,Approvers__c , Status__c, SubmittedOn__c , Account__r.Name , Account__r.id , Account__r.Owner.Alias, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_1__c , User__r.Name from Protected_Class_Publisher__c where ID IN ( :protectedClassList.get(0).Id ) limit 1 ];
        protectedClassEmailList.add(protectedClassUpdate);
        
        String orgWideEmailId;
        String toAddress = '' ;
        Id templateId = [SELECT id FROM EmailTemplate WHERE developerName = 'RAMD_ProtectedClass_Publisher_Pending' limit 1].Id;
        PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress');
        String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';
        try
        {
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id;
        }
        catch(Exception e)
        {
            orgWideEmailId = null;
        }

        userTitles.addAll( ([select Value__c from RAMD_Setting__mdt where DeveloperName = 'RAMD_Protected_Class_Approver_Titles' limit 1].Value__c).split(',') );
        System.debug('acc >> '+ acc);
        
        regionStr = protectedClassUpdate.Account__r.TERR_HIER_2__c + ' (Region)';
        geography = protectedClassUpdate.Account__r.TERR_HIER_1__c + ' (Geography)';
        //division = protectedClassUpdate.Account__r.Division_Formula__c + ' (Division)';
        regMap = [select User__r.Alias, User__r.Title ,User__r.Id ,User__r.Email from Inv_WorkBox_Region_Mapping__c 
            where (TERR_HIER_2__r.Name IN (:regionStr) OR TERR_HIER_2_F__c = '*')
            AND (TERR_HIER_1__r.Name IN (:geography) OR TERR_HIER_1_F__c = '*')
            AND RecordType.Name = 'RAMD'
            GROUP BY User__r.Alias,User__r.Email,User__r.Id,User__r.Title ];
        

        System.debug(' user Title submit :  ' + userTitles);
        if(!regMap.isEmpty()){
            for(AggregateResult region: regMap)
            {
                Boolean titleFound = false;
                for (String usrTitle : userTitles) {
                    if(region.get('Title').toString().contains(usrTitle) )
                    {
                        titleFound = true;
                    }
                }
                
                System.debug('all condtn in submit : ' + region.get('Alias') + ' todtring():: ' + region.get('Title').toString() + ' contaisn cndtn ::' + userTitles.contains( region.get('Title').toString() ) );
                if(region.get('Alias') != null && titleFound )
                {
                    aliases.add(region.get('Alias').toString());
                    approverEmailList.add(region.get('Email').toString());
                }

            }
        }
        
        System.debug(' alises : ' + aliases);

        if(!regMap.isEmpty()){

            users = string.join(aliases,',');
            System.debug(' new users check : ' + users );
        }

        if( users != '' )
        {
            protectedClassEmailList.get(0).Approvers__c = users ;
            protectedClassEmailList.get(0).Status__c = 'Pending';
            protectedClassEmailList.get(0).SubmittedOn__c =  System.now();
            //result = 'submitted';
            update protectedClassUpdate;
            sendMail_RAMD( approverEmailList , protectedClassEmailList.get(0).User__r.Id , orgWideEmailId, mailsToBeSent , protectedClassEmailList.get(0) , 'RAMD: Protected Class Publisher is awaiting for approval', false );
            if(mailsToBeSent.size() > 0)
            {
                Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
                for(Messaging.SendEmailResult emailResult : mailSendResult)
                {
                    System.debug('Email result ' + emailResult.IsSuccess());
                    System.debug('Individ rsl :' + emailResult);
                }
            }
        }            
    }
}