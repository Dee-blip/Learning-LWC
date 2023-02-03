//Apex and Flow Exception have different patterns based on that, the code captures the infomation and separate out the conditions.
global class SawyerUnhandledExceptionHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        String Subject= email.subject.toLowerCase();
        Boolean checkstrApex=Subject.contains('developer');
        Boolean checkstrFlow=Subject.contains('flow');
        try{
            Map<String,String> logObjectMap=new map<String,String>();
            String emailBody= '';
            emailBody= email.plainTextBody;
            //for capture Apex exceptions
            if (checkstrApex==True)
            {
                List<String> lststring= emailBody.split('\n');
                String lastline= lststring.get(lststring.size()-1);
                String firstline;
                for(Integer i=0;i<lststring.size();i++)
                {	
                    String check=lststring[i];
                    Integer findclassindex=check.indexOf('Class.');
                    if(findclassindex>0)
                    {
                       firstline=lststring[i].mid(findclassindex,100);
                       break;
                    }
                    else if(check.startswith('Class.')==True || check.startswith('Trigger.')==True)
                    {
                       firstline=lststring[i];
                       break;
                    }
                 
                }
                String Cstacktrace='';
                //Checking if firstline contains Class. and trigger. 
                if(firstline!=null && firstline!='')
                {
                String firstsubstring=firstline.substringBeforeLast(':');
                List<String> splitfirstline= firstsubstring.split('\\.');                
                Integer sizesplitline=splitfirstline.size();           
                
                
                if(emailBody!=null && emailBody!='')
                {   
                    String Cclass;
                    String FinalClass='';
                    if(sizesplitline==2)
                    {	
                        //Apex exceptions who don't have method name in their stacktrace.
                        FinalClass= firstsubstring.substringAfter('.').mid(0,60);
                        logObjectMap.put('Method__c',' ');
                        
                    }
                    else
                    {
                        //Apex exceptions contains all information
                        Cclass= firstline.substringBeforeLast('.');
                        FinalClass=Cclass.substringAfter('.').mid(0,60);
                        String cmethod=firstline.substringAfterLast('.');
                        logObjectMap.put('Method__c',cmethod.substringBeforeLast(':'));
                        
                        
                    }
                                    
                    if(FinalClass=='SawyerUnhandledExceptionHandler')
                    {
                        //Calling the method
        				SendmailSawyerException();
                    }
                    else
                    {	
						logObjectMap.put('Class__c',FinalClass);
                        logObjectMap.put('User_ID_Text__c',emailBody.substringBetween('organization:','/')); 
                        logObjectMap.put('Message_Text__c',emailBody.substringBetween('caused by: ','\n'));
                  
                        
                        Integer sizelstring=lststring.size();
                        Boolean flag=False;
                        
                        for(Integer i=0; i<sizelstring;i++)
                        {
                            if(lststring[i].contains('caused by:'))
                            {   
                                Integer count=i+1;
                                while(count<sizelstring){
                                    Cstacktrace=Cstacktrace+lststring[count]+'\n';
                                    count=count+1;
                                    flag=True;
                                }
                            }
                            if(flag==True){
                                break;
                            }
                            
                        }
                        
                        logObjectMap.put('Stack_Trace_Text__c',Cstacktrace);
                        
                        //Calling the method
                        CreationSawyedLogs(logObjectMap);
                        
                    }
                }
                
                }
                else
                {	
                    //Apex exceptions--1. who don't have any class and methods in the stack trace only statement is present System Code. 2.The mails who don't have stact-trace and change in their pattern.
                    String Catchclass='';
                    if(emailBody.contains('Failed to process')==True)
                    {
                        Catchclass=emailBody.substringBetween('class','for job id').remove('\'').mid(0,60);
                    }
                    else
                    {	
                        Catchclass=lastline.substringBefore(':').mid(0,60);
                    	
                    }
                    if(Catchclass.contains('SawyerUnhandledExceptionHandler')==True)
                    {
                        //Calling the method
                     	SendmailSawyerException();
                    }
                    else
                    {
                        logObjectMap.put('Class__c',Catchclass);  
                        logObjectMap.put('User_ID_Text__c',emailBody.substringBetween('organization:','/')); 
                        
                        String catcherr='';
                        if(emailBody.contains('caused by:')==True)
                        {
                            catcherr=emailBody.substringBetween('caused by: ','\n');
    
                        }
                        else
                        {
                            catcherr=lastline.substringAfter(':');
                        }
                        logObjectMap.put('Message_Text__c',catcherr);
                        logObjectMap.put('Method__c',' ');
                        logObjectMap.put('Stack_Trace_Text__c','');
                        
                        //Calling the method
                        CreationSawyedLogs(logObjectMap);
                
                    
                	}	
                }
               
                
            }   

            //For capture the flow exceptions
            if(checkstrFlow==True)
            {
                String htmlbody;
                String stacktracelimit;
                
                htmlbody=email.htmlBody.unescapeHtml4();
                Pattern pattn1 = Pattern.compile('<style>[^<]*<\\/style>|<\\/?\\w*\\b[^>]*>');
				Matcher matching=pattn1.matcher(htmlbody);
                String flowplaintextbody=matching.replaceAll('');
                String Cuserid='';
                if(flowplaintextbody!=null && flowplaintextbody!='')
                {
                    
                    logObjectMap.put('Class__c',flowplaintextbody.substringBetween('Flow API Name:','Type:'));
                    if(htmlbody.contains('Error Occurred:'))
                    {
                    	logObjectMap.put('Message_Text__c',flowplaintextbody.substringBetween('Error Occurred:','\n'));
                    
                    }
                    else
                    {
                        logObjectMap.put('Message_Text__c','');
                    }
                    Pattern patt1=Pattern.compile('005([a-zA-Z0-9]{12})');
                    Matcher mtch= patt1.matcher(flowplaintextbody);
                    if(mtch.find())
                    {
                        Cuserid= mtch.group(0);
                        logObjectMap.put('User_ID_Text__c',Cuserid);
                    }
                }
                
       
                String stacktrace='';
                if(logObjectMap.get('Message_Text__c').length()>0)
                {
                    stacktrace=flowplaintextbody.substringBetween('Flow Details','Error Occurred:');
                }
                else
                {
                    stacktrace=flowplaintextbody.substringBetween('Flow Details','Salesforce Error ID:');
                }
                if(stacktrace!=null)
                {
                    stacktracelimit=stacktrace.mid(0,2000);
                	logObjectMap.put('Stack_Trace_Text__c',stacktracelimit);                    
                }
                
                //Calling the method
                CreationSawyedLogs(logObjectMap);
                    
                
                 
            }     
            result.success=True;
        }
    
        catch(Exception e){
                Sawyer.saw(e);
                result.success=False;
            }
        return result;
        
    }

    //Sent mails because here apex exception mails catching the sawyerunhandledexceptionHandler class in their body. 
    public void SendmailSawyerException()
    {
        Messaging.SingleEmailMessage sendemail;
       	sendemail=GsmUtilClass.createSingleEmail('dl-pni-dev@akamai.com','','SawyerUnhandle Apex email exception ','','The unhandle apex exception have the Swayerunhandlesexception class namee');
       	Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {sendemail};
       	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
       	System.debug('results'+results);
                         
    }
    //Creating the Sawyed Logs
    public void CreationSawyedLogs(Map<String,String> logObjectMap)
    {
        
        if(logObjectMap.get('Class__c')==null && logObjectMap.get('Method__c')==null)
        {
            System.debug('Nothing');
        }
        else 
        {
            SawedLawg__c sawyedrecord= new SawedLawg__c();
            sawyedrecord.Class__c=logObjectMap.get('Class__c');
            sawyedrecord.User_ID_Text__c=logObjectMap.get('User_ID_Text__c');
            sawyedrecord.Method__c=logObjectMap.get('Method__c');
            sawyedrecord.Message_Text__c=logObjectMap.get('Message_Text__c');  
            sawyedrecord.Stack_Trace_Text__c=logObjectMap.get('Stack_Trace_Text__c'); 
            insert sawyedrecord;  
        }
    }

}