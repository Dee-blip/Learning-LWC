public with sharing class MSMController 
{

        public Boolean isOps{get;set;} //boolean flag depicting if the user belongs to ops or dev
        public Boolean myRequestsFlag {get;set;}// boolean flag depicting if requests pertaining to the current user are to be rendered on queue
        public Boolean myCompletedRequestsFlag {get;set;}// boolean flag depicting if requests pertaining to the current user are to be rendered on completed queue
        public Integer healthMonitorVal{get;set;}// value of health monitor
        public Integer graphMaxVal {get;set;}// maximum value of bar graph : required to set bar values as integers
        public Integer totalRequests {get;set;}// total number of requests per release
        public String selectedRelease {get;set;}// release input by user on drop down from analyze requests tab
        public String uListJSON {get;set;}// set of ops members parsed into JSON for drop down in JS
        public List<Release__c> allCurrentReleases {get;set;}// list of all eligible releases for drop down
        public String displayReleases {get;set;} // The list of releases shown on main Dashboard
        public List<Deployment_Step_Request__c> dsrObjectList {get; set;}// list of new and assigned records as per current release
        public List<Deployment_Step_Request__c> dsrObjectListCompleted {get; set;}// list of completed and failed records as per current release
        public List<SelectOption> allReleases {get;set;}// list of releases for drop down
        public List<GraphData> barGraphData {get;set;}// data for bar graph depicting no of requests as per status
        public List<GraphData> pieGraphData {get;set;}// data for pie graph depicting no of requests by teams
        public String homePageUrl {get;set;}
        public String msmTitleDynamic {get; set;}
        @TestVisible private List<User> uList {get;set;}// list of ops members


        //Wrapper Class for Graph Data
        private class GraphData 
        {
            public String name {get;set;}
            public Integer data1 {get;set;}
            public GraphData(String name, Integer data1) {
                this.name = name;
                this.data1 = data1;
            }
        }

        //constructor
        public MSMController() 
        {
            setMSMTitle(0);
            setReleases();
            if(allCurrentReleases.size()>0)
            {
                setDisplayRelease(allCurrentReleases);
                setDataByRelease(); 
                setUserList();
                setInitialFlags();
                reloadDSR();  
                reloadDSRCompleted();
            }
            homePageUrl = URL.getSalesforceBaseUrl().toexternalform();
            
        }

        private void setMSMTitle(Integer openRequests)
        {
            msmTitleDynamic = String.valueof(System.now());
            if(openRequests == 0)
            {
                msmTitleDynamic = 'Manual Step Manager';
            }
            else
            {
                msmTitleDynamic = '('+openRequests+') Manual Step Manager';
            }
        }

        //set current release and all releases
        @TestVisible private void setReleases() 
        {
            allReleases = new List<SelectOption>();
            allCurrentReleases = new List<Release__c>();

            allReleases.add(new SelectOption('000', 'All-Releases'));

            for ( Release__c rel :  [ SELECT Id, Name, Release_Date__c FROM Release__c 
                                      WHERE 
                                      (Application__c = 'Salesforce' OR  Name = 'ese-force-Maintenance')
                                      ORDER BY Release_Date__c DESC ])
            {
                    
                allReleases.add(new SelectOption(rel.Id, rel.Name));
                if(rel.Release_Date__c > System.today() || rel.Release_Date__c==null)
                {
                    allCurrentReleases.add(rel);
                }
            }
        }

        private void setDisplayRelease(List<Release__c> allReleasesList)
        {
            Integer count = 1;
            displayReleases = '';
            for(Release__c rel : allReleasesList)
            {
                if(allReleasesList.size()>count)
                {
                   displayReleases = displayReleases+ rel.Name + ', ';
                }
                else
                {
                   displayReleases = displayReleases+ rel.Name;
                }
                count++;
            }
        }

        //set graph data by selected release 'true' parameter indicates show data for all releases
        public void setDataByRelease() 
        {
            if(selectedRelease == null) 
            {
                selectedRelease = '000';
            } 
            if(selectedRelease == '000') 
            {
                setBarGraphData(true);
                setPieGraphData(true);
            }
            else 
            {
                setBarGraphData(false);
                setPieGraphData(false);
            }
        }

        // set data for bar graph
        @TestVisible private void setBarGraphData(Boolean isAllSelected) 
        {
            barGraphData = new List<GraphData>();
            graphMaxVal = 0;
            totalRequests = 0;
            List<String> status = new List<String>();
            List<AggregateResult> aggregateData;
            status.add('Cancelled');
            if(isAllSelected) {
                aggregateData = [SELECT COUNT(Id) statusCount, status__c FROM Deployment_Step_Request__c WHERE status__c NOT IN :status GROUP BY status__c];
            }
            else {
                aggregateData = [SELECT COUNT(Id) statusCount, status__c FROM Deployment_Step_Request__c WHERE status__c NOT IN :status AND Deployment_Step__r.Release__r.Id = :Id.valueOf(selectedRelease) GROUP BY status__c];
            }

            Map<String, Integer> intialGraphData = new Map<String, Integer>();
            intialGraphData.put('New', 0);
            intialGraphData.put('Assigned', 0);
            intialGraphData.put('Completed', 0);
            intialGraphData.put('Failed', 0);

            for(AggregateResult temp : aggregateData) {
                intialGraphData.put(String.valueOf(temp.get('status__c')), Integer.valueOf(temp.get('statusCount')));
                totalRequests += Integer.valueOf(temp.get('statusCount'));
                if(Integer.valueOf(temp.get('statusCount')) > graphMaxVal) {
                    graphMaxVal = Integer.valueOf(temp.get('statusCount'));
                }               
            }

            for(String key : intialGraphData.keySet()) {
                barGraphData.add(new GraphData(key, intialGraphData.get(key)));
            }
        }

        //set data for pie graph
        @TestVisible private void setPieGraphData(Boolean isAllSelected)
        {
            pieGraphData = new List<GraphData>();
            List<String> status = new List<String>();
            status.add('Cancelled');
            List<AggregateResult> aggregateData;
            if(isAllSelected) {
                aggregateData = [SELECT COUNT(Id) requestCount, Deployment_Step__r.Team__c teams FROM Deployment_Step_Request__c WHERE status__c NOT IN :status GROUP BY Deployment_Step__r.Team__c];
            }
            else {
                aggregateData = [SELECT COUNT(Id) requestCount, Deployment_Step__r.Team__c teams FROM Deployment_Step_Request__c WHERE status__c NOT IN :status AND Deployment_Step__r.Release__r.Id = :Id.valueOf(selectedRelease) GROUP BY Deployment_Step__r.Team__c];
            }
            for(AggregateResult temp : aggregateData) {
                pieGraphData.add(new Graphdata(String.valueOf(temp.get('teams')), Integer.valueOf(temp.get('requestCount'))));
            }
        }

        //set userList with users who are in ops team
        @TestVisible private void setUserList() 
        {
            uList = new List<User>();
            List<User> newUList = new List<User>();
            uList = [SELECT Id, Name FROM User WHERE UserRole.Name = 'System Administrator' AND Profile.Name = 'System Administrator' AND isActive = true ];
            
            isOps = false;
            for(User u : uList) 
            {
                if(userinfo.getuserid() == u.Id) 
                {
                    newUList.add(u);
                    isOps = true;
                    break;
                }
            }
            for(User u : uList) 
            {
                if(userinfo.getuserid() != u.Id) 
                {
                    newUList.add(u);
                }
            }
            uListJSON = JSON.serialize(newUList);
        }

        // function to set tab val which is to be rendered accordingly for ops and dev
        @TestVisible private void setInitialFlags() 
        {
            if(isOps) {
                myRequestsFlag = false;
                myCompletedRequestsFlag = false;
            }
            else {
                myRequestsFlag = true;
                myCompletedRequestsFlag = true;
            }
        }

        // function to set 'dsrObjectList': records with status as 'New' and 'Assigned' as per 'currentRelease'
        public void reloadDSR() 
        {

            if(Apexpages.currentPage().getParameters().get('requestFlag') != null) {
                myRequestsFlag = Boolean.valueOf(Apexpages.currentPage().getParameters().get('requestFlag'));
            }
            Integer openRequests = 0;
            List<Deployment_Step_Request__c> dsrTempList = new List<Deployment_Step_Request__c>();
            List<String> status = new List<String>();
            dsrObjectList = new List<Deployment_Step_Request__c>();
            status.add('New');
            status.add('Assigned');
            if(isOps && myRequestsFlag) {
                for( Deployment_Step_Request__c dsr : [SELECT assignedTo__c, id, environment__c, requestedBy__r.Name, submissionTime__c, devComments__c, opsComments__c, Deployment_Step__r.Name, Deployment_Step__r.Team__c, status__c FROM Deployment_Step_Request__c WHERE status__c IN ('Assigned') AND Deployment_Step__r.Release__r.Id IN :allCurrentReleases AND assignedTo__c = :UserInfo.getUserId() ORDER BY submissionTime__c ASC ])
                {
                    dsrObjectList.add(dsr);
                    
                }
            }
            else {
                if(!isOps && myRequestsFlag) {
                    for( Deployment_Step_Request__c dsr : [SELECT assignedTo__c, id, environment__c, requestedBy__r.Name, submissionTime__c, devComments__c, opsComments__c, Deployment_Step__r.Name, Deployment_Step__r.Team__c, status__c FROM Deployment_Step_Request__c WHERE status__c IN ('New', 'Assigned') AND Deployment_Step__r.Release__r.Id IN :allCurrentReleases AND requestedBy__c = :UserInfo.getUserId() ORDER BY submissionTime__c ASC ])
                    {
                        dsrTempList.add(dsr);
                       
                    }
                }
                else {
                    for( Deployment_Step_Request__c dsr : [SELECT assignedTo__c, id, environment__c, requestedBy__r.Name, submissionTime__c, devComments__c, opsComments__c, Deployment_Step__r.Name, Deployment_Step__r.Team__c, status__c FROM Deployment_Step_Request__c WHERE status__c IN :status AND Deployment_Step__r.Release__r.Id IN :allCurrentReleases ORDER BY submissionTime__c ASC ])
                    {
                        dsrTempList.add(dsr);
    
                    }
                } 
               
                for( Deployment_Step_Request__c dsr : dsrTempList) {
                    if(dsr.status__c == 'New') {
                        dsrObjectList.add(dsr);
                        openRequests++;
                    }
                } 
                for(Deployment_Step_Request__c dsr : dsrTempList) {
                    if(dsr.status__c == 'Assigned') {
                        dsrObjectList.add(dsr);
                    }
                }
            } 
            calculateHealthMonitorValue();
            setMSMTitle(openRequests);
        }

        // calculate value to be set for health monitor
        @TestVisible private void calculateHealthMonitorValue() 
        {

            List<AggregateResult> value = [SELECT COUNT(Id) statusCount, status__c FROM Deployment_Step_Request__c WHERE status__c IN ('New', 'Assigned') AND Deployment_Step__r.Release__r.Id in :allCurrentReleases GROUP BY status__c];
            Double newRequests = 0;
            Double assignedRequests = 0;
            for(AggregateResult temp : value) {
                if(String.valueOf(temp.get('status__c')) == 'New') {
                    newRequests = Double.valueOf(temp.get('statusCount'));
                }
                else if(String.valueOf(temp.get('status__c')) == 'Assigned') {
                    assignedRequests = Double.valueOf(temp.get('statusCount'));
                }
            }
            if(newRequests ==0 && assignedRequests == 0) {
                healthMonitorVal = 100;
            }
            else {  
                Double tempVal = assignedRequests/(newRequests + assignedRequests) * 100;
                healthMonitorVal = Integer.valueOf(tempVal);        
            }
        }

        // function to set 'dsrObjectListCompleted': records with status as 'Completed' and 'Failed' as per 'currentRelease'
        public void reloadDSRCompleted() 
        {

            if(Apexpages.currentPage().getParameters().get('completedRequestFlag') != null) {
                myCompletedRequestsFlag = Boolean.valueOf(Apexpages.currentPage().getParameters().get('completedRequestFlag'));
            }
            dsrObjectListCompleted = new List<Deployment_Step_Request__c>();
            List<String> status = new List<String>();
            status.add('Completed');
            status.add('Failed');
            if(isOps && myCompletedRequestsFlag) {
                for( Deployment_Step_Request__c dsr : [SELECT assignedTo__c, id, environment__c, requestedBy__r.Name, submissionTime__c, completionTime__c, devComments__c, opsComments__c, Deployment_Step__r.Name, Deployment_Step__r.Team__c, status__c FROM Deployment_Step_Request__c WHERE status__c IN :status AND Deployment_Step__r.Release__r.Id IN :allCurrentReleases AND assignedTo__c = :UserInfo.getUserId() ORDER BY completionTime__c DESC ])
                {
                        dsrObjectListCompleted.add(dsr);
                }
            }
            else if(!isOps && myCompletedRequestsFlag) {
                for( Deployment_Step_Request__c dsr : [SELECT assignedTo__c, id, environment__c, requestedBy__r.Name, submissionTime__c, completionTime__c, devComments__c, opsComments__c, Deployment_Step__r.Name, Deployment_Step__r.Team__c, status__c FROM Deployment_Step_Request__c WHERE status__c IN :status AND Deployment_Step__r.Release__r.Id IN :allCurrentReleases AND requestedBy__c = :UserInfo.getUserId() ORDER BY completionTime__c DESC ])
                {
                       dsrObjectListCompleted.add(dsr);
                       
                }
            }
            else {
                for( Deployment_Step_Request__c dsr : [SELECT assignedTo__c, id, environment__c, requestedBy__r.Name, submissionTime__c, completionTime__c, devComments__c, opsComments__c, Deployment_Step__r.Name, Deployment_Step__r.Team__c, status__c FROM Deployment_Step_Request__c WHERE status__c IN :status AND Deployment_Step__r.Release__r.Id IN :allCurrentReleases ORDER BY completionTime__c DESC ])
                {
                        dsrObjectListCompleted.add(dsr);
                        
                }
            }
        }

        // function that updates status of a record as 'Completed' or 'Failed' or 'cancelled'
        public void updateStatusDSR() 
        {
            Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
                String ids = Apexpages.currentPage().getParameters().get('id');
                String reason = Apexpages.currentPage().getParameters().get('reason');
                String status = Apexpages.currentPage().getParameters().get('status');
                if(status == 'Completed' || status == 'Failed') {
                    dsr.completionTime__c = DateTime.now();
                }
                dsr.Id = ids;
                dsr.status__c = status;
                dsr.opsComments__c = reason;
                update dsr;
            reloadDSR();
        }

        // function to update record when it is 'Assigned' or 'Re-Assigned'
        public void updateAssignedDSR() 
        {
            Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
            dsr.status__c = 'Assigned';
                String ids = Apexpages.currentPage().getParameters().get('id');
                String assignedTo = Apexpages.currentPage().getParameters().get('assignedTo');
                String passOnComments = Apexpages.currentPage().getParameters().get('passOnComments');
                dsr.Id = ids;
                dsr.assignedTo__c = assignedTo;
                update dsr;
                if(passOnComments != '' && passOnComments != null )
                {
                    String userAlias = Userinfo.getUserName().substringBefore('@');
                    Deployment_Step_Request__c dsrObj = [Select Id,Deployment_Step__c, DS_Ops_Deployed_Comments__c, Assigned_to_name__c from Deployment_Step_Request__c where id =:ids limit 1];
                    Deployment_Step__c dsObj = new Deployment_Step__c();
                    String newComments;
                    if( dsrObj.DS_Ops_Deployed_Comments__c != null && 
                        dsrObj.DS_Ops_Deployed_Comments__c != '')
                    {
                        newComments = dsrObj.DS_Ops_Deployed_Comments__c + ' \n' + passOnComments+' -'+userAlias;
                        if(newComments.length() > 255)
                        {
                            newComments = passOnComments+' -'+userAlias;
                        }
                    }
                    else
                    {
                        newComments = passOnComments+' -'+userAlias;
                    }

                    if(newComments.length()>255)
                    {
                        newComments = newComments.substring(0,254);
                    }
                   dsObj.id = dsrObj.Deployment_Step__c;
                   dsObj.QA_Deployed_Ops_Comments__c = newComments;
                   update dsObj;


                }
                

                sendMailToAssignee(ids, passOnComments);
                reloadDSR();
        }

        // Send auto generated mail to assignee(ops) once a request is assigned
        @TestVisible private void sendMailToAssignee(Id ids, String passOnComments) 
        {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            List<String> listOfEmails = new List<String>();
            Deployment_Step_Request__c dsr = [SELECT Deployment_Step__r.Name, Deployment_Step__r.Id, assignedTo__r.Email, assignedTo__r.Name,Instance_URL__c FROM Deployment_Step_Request__c WHERE Id = :ids];
            listOfEmails.add(dsr.assignedTo__r.Email);
            message.setToAddresses(listOfEmails);
            message.setReplyTo('noreply.mailer@akamai.com');
            message.setSenderDisplayName('noreply.mailer');
            message.setSubject('[Deploy Step Request] Assigned');
                    
            String body = 'Hi '+dsr.assignedTo__r.Name+',<br/><br/>';
            body += 'You have been assigned <a href="'+dsr.Instance_URL__c+'/'+dsr.Deployment_Step__r.Id+'">'+dsr.Deployment_Step__r.Name+'</a> by <b>'+UserInfo.getName()+'</b> at <b>'+DateTime.now()+'</b> GMT<br/><br/>';  

            if(passOnComments != 'None') {
                body += '<b>Comments by '+UserInfo.getName()+' :</b><br/>';
                body += passOnComments+'<br/><br/>';
            }

            body += 'For further details check the <a href="'+dsr.Instance_URL__c+'/apex/MSM">Manual Step Manager</a> page<br/><br/>';
            body += 'Thank You<br/><br/><br/><br/>';
            body += '<b>NOTE : </b> This is a system generated mail. Please do not reply';
            message.setHtmlBody(body);
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            messages.add(message);
            Messaging.sendEmail(messages);
        }
}