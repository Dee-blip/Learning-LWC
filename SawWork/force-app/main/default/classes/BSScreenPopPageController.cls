public class BSScreenPopPageController {

    public PageReference runStandardPop() {
        return null;
    }


    public PageReference updateSearch() {
         String result;
         result = runSearchPhone(ani,contactOnly);
        
        return null;
    }


    public PageReference navigateToId() {
        System.debug('attempting to navigate to id...');
        System.debug(idToPop);
        
        return new PageReference('/'+idToPop);
    }
    public String defaultValues {get;set;}
    public String lob {get;set;}
    public String ani {get;set;}
    public String erc {get;set;}
    public String caseid {get;set;}
    public String taskid {get;set;}
    
    public String method {get;set;}
    public String cti_rt { get; set; }
    public String cti_data { get; set; }
    public String cti_obj { get; set; }
    public Contact matchedContact {get;set;}
    public Account matchedAccount {get;set;}
    
    public List<Case> caseArray {get;set;}
    public List<User> userarray {get;set;}
    public User matchedUser {get;set;}
    public List<BMCServiceDesk__Incident__c> incidentlist {get;set;}
    public List<BMCServiceDesk__Incident__c> serviceRequestList {get;set;}
    
    public List<Special_Instructions__c> specialInstructionsArray {get;set;}
    public List<AccountTeamMember> accountTeamMemberArray {get;set;}
    public List<Contact> contactarray {get;set;}
    public List<Lead> leadarray {get;set;}
    public List<Account> accountarray {get;set;}
    public String accountId {get;set;}
    public String matchedAccountId {get;set;}
    
    public Boolean contactOnly {get;set;}
    
    public String idToPop {get;set;}
    public String matchId {get;set;}
    public Boolean issueOnBehalf {get;set;}
    public String userName {get;set;}
    public String userId {get;set;}
    public String selectedId {get;set;}
    
    public PageReference runSelection() {
        
        if (lob == 'Billing') {
            return new PageReference('/'+selectedId);
        } 
      
        return null;
        
    }
    
    public String valueToSearch {get;set;}
    public Boolean canUpdateTask {get;set;}
    public String idToUpdate {get;set;}
    public PageReference runPrePopCheck() {
        System.debug('running prepop check');
        System.debug(lob + ' is lob');
        System.debug(ani + ' is ani');
        System.debug(erc + ' is erc');
        System.debug(taskid + ' is the taskid');
        String sresult = runSearchPhone(ani,true);
        System.debug('result of prepop: ' + sresult);
        valueToSearch = '';
        
        
        
        if (sresult == 'multimatch' || sresult == 'nomatch') {
            
            if (lob == 'Akatec') {
                valueToSearch = '';
            } else {
                valueToSearch = ani;    
            }
        } else {
            valueToSearch = 'standardpop';
        }
        
        if (sresult == 'multimatch' && lob == 'SOCC') {
            valueToSearch = ani;
        }
        
        
        return null;
        
        
    }
    
    public void updateTask(String inputid) {
        
        canUpdateTask = true;
        idToUpdate = inputid;
        return;
        
    }
    public void updateTaskRecord() {
       System.debug('updating Task Record..');
        Task t = new Task();
        
        Boolean canUpdate = false;
        
        if (taskid != null && taskid != '' && taskid.startsWith('00T')) {
            t.id = taskid;
            if (idToUpdate != null && (idToUpdate.startsWith('003') || idToUpdate.startsWith('00Q'))) {
                if (idToUpdate.startsWith('003')) {
                    List<Contact> clId = [select id, accountid from contact where id=:idToUpdate];
                    t.whatid = clId[0].accountid;
                    
                }
              
                        
                t.whoid = idToUpdate; canUpdate = true;
            }
            
            if (idToUpdate != null && idToUpdate.startsWith('500')) {
                t.whatid = idToUpdate; canUpdate = true;
            }
         
            if (canUpdate) {
                update t;
            }
        }
    }
    
    public BSScreenPopPageController() {
        searchResult = '';
        canUpdateTask = false;
        
    
        lob = ApexPages.currentpage().getparameters().get('lob');
        if (lob != null && lob.startsWith('Akatec')) {
            lob = 'Akatec';
        }
        
        ani = ApexPages.currentpage().getparameters().get('ani');
        erc = ApexPages.currentpage().getparameters().get('erc');
        caseid = ApexPages.currentpage().getparameters().get('caseid');
        taskid = ApexPages.currentpage().getparameters().get('taskid');
        method = '';
        String result; 
        
        
        if (lob == 'Marketing') {
            
            result = runSearchPhone(ani,false);
            contactOnly = false;
            
            if (result == 'singlematch') {
                method = 'navigatetorecord';
                idToPop = matchId;
                updateTask(matchId);
            }
           
            if (result == 'nomatch') {
                method = 'createobject';
                cti_obj = 'Lead';
                cti_rt = 'Marketo Lead';
                //Changes for ACD2-289: Replacing the existing phone field with custom phone
                defaultValues = 'Phone=' + ani +',Phone_Custom__c=' + ani +',Associated_Account__c=' + accountid;
            }
            
            if(result == 'multimatch') {
                method = 'navigatetorecord';
                idToPop = matchId;
                updateTask(matchId);
            }
        }
        
        if (lob == 'Billing') {
 
            result = runSearchPhone(ani,true);
            contactOnly = true;
            
            if (result == 'singlematch') {
                method = 'navigatetorecord';
                idToPop = matchId;
                updateTask(matchId);
            }
            if (result == 'multimatch') {
                method = 'selectrecord';
            }
            if (result == 'nomatch') {
                method = 'createobject';
                cti_obj = 'Case';
                cti_rt = 'Billing';
                defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + accountid;
            }

        }
        
        if (lob == 'BOCC') {
            
            result = runSearchPhone(ani,true);
            contactOnly = true; 
            
            System.debug('case id is : ' + caseid);
            
            if (caseid != null && caseid != '' && caseid != 'NULL') {
                    String caseid1 =  'F-CS-'+caseid;
                    String caseid2 = 'FD-CS-'+caseid;
                
                    List<Case> cl = Database.query('select id from case where  (AKAM_Case_ID__c LIKE \'%' +  caseid1 + '%\' or AKAM_Case_ID__c LIKE \'%' + caseid2 + '%\') limit 1');
                    if (cl.size() == 1) {
                        method = 'navigatetorecord';
                        idToPop = cl[0].Id;    
                        updateTask(idToPop);
                    } else {
                      
                         if (result == 'singlematch') {
                            updateTask(matchId);
                            method = 'akatecnewcallscreen';
                            defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + matchedAccountId + ',ContactId='+matchId;
                            caseArray = [select id, casenumber, severity__c, owner.name, subject from case where recordtype.name='Technical' and Sub_Type__c='BOCC' and status!= 'Closed' and contactid=:matchId];
                            specialInstructionsArray = [select id, account__c,Title__c,Title_URL__c, Instructions__c, Special_Instruction_Template__c from special_instructions__c  where account__c=:matchedContact.AccountId];
                            accountTeamMemberArray = [select user.name, user.phone, user.mobilePhone, TeamMemberRole, Id,Account.OwnerId,Account.Name ,Account.AKAM_Account_ID__c, Account.Id,UserId,Account.Owner.Name,Account.Region__c, Account.Parent_Division__c, Account.Division__c, Account.Area__c From AccountTeamMember where account.id =: matchedContact.AccountId and TeamMemberRole LIKE '%Technical Support%'];
        
                        } else if  (result == 'multimatch') {
                            System.debug('multi match for BOCC');
                            method = 'akatecmanycontactscreen';
                            defaultValues = 'Subject=ACD Call: ' + ani;
                            
                            
                        } else {
                             
                            method = 'createobject';
                            cti_obj = 'Case';
                            cti_rt = 'Technical';
                            defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + accountid;
                        }
               
                    /* method = 'akatecnewcallscreen';
                     defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + matchedAccountId + ',ContactId='+matchId;
                     //TODO correct due to missing matchId 
                     caseArray = [select id, casenumber, severity__c, owner.name, subject from case where recordtype.name='Technical' and  Sub_Type__c='BOCC' and status!= 'Closed' and contactid=:matchId order by createddate desc limit 100];
                     specialInstructionsArray = [select id, account__c,Title__c,Title_URL__c, Instructions__c, Special_Instruction_Template__c from special_instructions__c  where account__c=:matchedContact.AccountId];
                     accountTeamMemberArray = [select user.name, user.phone, TeamMemberRole, Id,Account.OwnerId,Account.Name ,Account.AKAM_Account_ID__c, Account.Id,UserId,Account.Owner.Name,Account.Region__c, Account.Parent_Division__c, Account.Division__c, Account.Area__c From AccountTeamMember where account.id =: matchedContact.AccountId];
                   */
                        
                        
                    }
            } else {
            
                if (result == 'singlematch') {
                    updateTask(matchId);
                    method = 'akatecnewcallscreen';
                    defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + matchedAccountId + ',ContactId='+matchId;
                    caseArray = [select id, casenumber, severity__c, owner.name, subject from case where recordtype.name='Technical' and Sub_Type__c='BOCC' and status!= 'Closed' and contactid=:matchId];
                    specialInstructionsArray = [select id, account__c,Title__c,Title_URL__c, Instructions__c, Special_Instruction_Template__c from special_instructions__c  where account__c=:matchedContact.AccountId];
                    accountTeamMemberArray = [select user.name, user.phone, user.mobilePhone, TeamMemberRole, Id,Account.OwnerId,Account.Name ,Account.AKAM_Account_ID__c, Account.Id,UserId,Account.Owner.Name,Account.Region__c, Account.Parent_Division__c, Account.Division__c, Account.Area__c From AccountTeamMember where account.id =: matchedContact.AccountId and TeamMemberRole LIKE '%Technical Support%'];

                } else if  (result == 'multimatch') {
                    System.debug('multi match for BOCC');
                    method = 'akatecmanycontactscreen';
                    defaultValues = 'Subject=ACD Call: ' + ani;
                    
                    
                } else {
                     
                    method = 'createobject';
                    cti_obj = 'Case';
                    cti_rt = 'Technical';
                    defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + accountid;
                }
            
            }
 
        }
     
        if (lob != null && lob.startsWith('SOCC')) {
            
             result = runSearchPhone(ani,true);
               
            if (result == 'singlematch') {
                method = 'navigatetorecord';
                idToPop = matchId;
                updateTask(matchId);
            } else {
                method = 'navigatetorecord';
                idToPop = '_ui/search/ui/UnifiedSearchResults?searchType=2&sen=001&sen=003&sen=00T&sen=00U&sen=500&sen=005&sen=00O&str='+ani;
            }         
             
            

        }
        if (lob == 'Akatec') {
            
            result = runSearchPhone(ani,true);
            List<Case> cl = new List<Case>();
            
            if (caseid != null && caseid != '' && caseid != 'NULL') {
                String caseid1 =  'F-CS-'+caseid;
                String caseid2 = 'FD-CS-'+caseid;
                cl = Database.query('select id from case where  (AKAM_Case_ID__c LIKE \'%' +  caseid1 + '%\' or AKAM_Case_ID__c LIKE \'%' + caseid2 + '%\') limit 1');
            }
            
            if (cl.size() == 1) {
                method = 'navigatetorecord';
                idToPop = cl[0].Id; 
                updateTask(idToPop);
                return;
                
            } else {
                 List<Account> ercAccountList = new List<Account>();
                
                if (erc != null && erc != '' && erc != 'NULL' && erc != '#') {
                    ercAccountList = [select id, name,Akatec_Geography__c, support_level__c from account where erc_numeric__c=:erc];
                }
                 if (result == 'singleaccountmatch') {
                  method = 'navigatetorecord';
                    idToPop = matchedAccountId;
                    updateTask(matchId);
                    return;
                }
                       
                      if (result == 'singlematch') {
                          System.debug('single match for akatec');
                          System.debug('$$ matchid' + matchId);
                          System.debug('$$ matchedcontact account' + matchedContact.AccountId);
                          System.debug('$$ matchedcontact' + matchedContact);
                          
                          method = 'akatecnewcallscreen';
                          defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + matchedAccountId + ',ContactId='+matchId;
                          caseArray = [select id, casenumber,createddate, severity__c, owner.name, subject from case where recordtype.name='Technical' and  Sub_Type__c!='BOCC' and status!= 'Closed' and contactid=:matchId order by createddate desc limit 100];
                          specialInstructionsArray = [select id, account__c,Title__c,Title_URL__c, Instructions__c, Special_Instruction_Template__c from special_instructions__c  where account__c=:matchedContact.AccountId];
                          accountTeamMemberArray = [select user.name, user.phone, user.mobilePhone, TeamMemberRole, Id,Account.OwnerId,Account.Name ,Account.AKAM_Account_ID__c, Account.Id,UserId,Account.Owner.Name,Account.Region__c, Account.Parent_Division__c, Account.Division__c, Account.Area__c From AccountTeamMember where account.id =: matchedContact.AccountId and TeamMemberRole LIKE '%Technical Support%'];
                          updateTask(matchId);
                          return;
                          
                      } else if (result == 'multimatch') {
                          System.debug('multi match for akatec');
                           if (ercAccountList.size() > 1) {
                                 accountarray = ercAccountList;
                                 method = 'akatecmanyaccountscreen';
                                 defaultValues = 'Subject=ACD Call: ' + ani;
                           } else {
                                method = 'akatecmanycontactscreen';
                                defaultValues = 'Subject=ACD Call: ' + ani;
                          }
                      } else {
                          System.debug('no single/multi:  result value: ' + result);
                          
                          if (ercAccountList.size() == 1) {
                                  method = 'akateconeaccountscreen';
                                  matchedAccount = ercAccountList[0];
                                  matchedAccountId = ercAccountList[0].Id;
                                  defaultValues = 'Subject=ACD Call: ' + ani + ',AccountId=' + matchedAccountId ;
                                  caseArray = [select id, casenumber,createddate, severity__c, owner.name, subject from case where recordtype.name='Technical' and  Sub_Type__c!='BOCC' and status!= 'Closed' and accountid=:matchedAccountId order by createddate desc limit 100];
                                  specialInstructionsArray = [select id, account__c,Title__c,Title_URL__c, Instructions__c, Special_Instruction_Template__c from special_instructions__c  where account__c=:matchedAccountId];
                                  accountTeamMemberArray = [select user.name, user.phone, user.mobilePhone, TeamMemberRole, Id,Account.OwnerId,Account.Name ,Account.AKAM_Account_ID__c, Account.Id,UserId,Account.Owner.Name,Account.Region__c, Account.Parent_Division__c, Account.Division__c, Account.Area__c From AccountTeamMember where account.id =: matchedAccountId and TeamMemberRole LIKE '%Technical Support%'];
                                  updateTask(matchedAccountId);
                                  return;
                          } else if (ercAccountList.size() > 1) {
                                 accountarray = ercAccountList;
                                 method = 'akatecmanyaccountscreen';
                                 defaultValues = 'Subject=ACD Call: ' + ani;
                              
                              
                          } else { 
                                method = 'createobject';
                                cti_obj = 'Case';
                                cti_rt = 'Technical';
                                defaultValues = 'Subject=ACD Call: ' + ani;
                          }
                          
                      }
                    
            }
            
        }
        
        if (lob == 'HelpDesk' || lob == 'EAE Ops') {
              result = runSearchPhone(ani,true);
              // will be redirecting to lightning component TBD
              method = 'helpdeskscreen';
              if (result == 'singleusermatch') {
                  matchedUser = userarray[0];
                  userName = matchedUser.username;
                  userId = matchedUser.Id;
                  List<BMCServiceDesk__Incident__c> openIncidents = new  List<BMCServiceDesk__Incident__c>();
                  List<BMCServiceDesk__Incident__c> resolvedIncidents = new  List<BMCServiceDesk__Incident__c>();
                  incidentlist  = new List<BMCServiceDesk__Incident__c>();
                  serviceRequestList = new List<BMCServiceDesk__Incident__c>();
                   
                  if (lob == 'HelpDesk') {
                  
                      openIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c,     BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c = 'Corp IT'  order by createddate desc];
                      resolvedIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c,   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c = 'Corp IT'  order by createddate desc];
                  }
                  if (lob == 'EAE Ops') {
                      openIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name,   BMCServiceDesk__Feedback__c,  BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops' order by createddate desc];
                      resolvedIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name,   BMCServiceDesk__Feedback__c,  BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops' order by createddate desc];
                  }
                  
                  
                  for (BMCServiceDesk__Incident__c inc : openIncidents) {
                      inc.BMCServiceDesk__Feedback__c = '';
                      if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                          String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                          inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                      }
                      incidentlist.add(inc);
                  }
                  for (BMCServiceDesk__Incident__c inc : resolvedIncidents ) {
                      inc.BMCServiceDesk__Feedback__c = '';
                      if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                          String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                          inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                      }
                      incidentlist.add(inc);
                  }                  
                  List<BMCServiceDesk__Incident__c> openSr = new List<BMCServiceDesk__Incident__c>();
                  List<BMCServiceDesk__Incident__c> resolvedSr = new List<BMCServiceDesk__Incident__c>();
                  
                 if (lob == 'HelpDesk') {
                     openSr = [select id, name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__Feedback__c,   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c = 'Corp IT'  order by createddate desc];
                     resolvedSr = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c,    BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName  and HD_Incident_Group__c = 'Corp IT' order by createddate desc];
                 }
                 
                 if (lob == 'EAE Ops') {
                     openSr = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c,    BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops'  order by createddate desc];
                     resolvedSr = [select id, name, BMCServiceDesk__FKStatus__r.name,   BMCServiceDesk__Feedback__c,  BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops' order by createddate desc];
                 }
                  
                  for (BMCServiceDesk__Incident__c inc: openSr) {
                      inc.BMCServiceDesk__Feedback__c = '';
                      if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                          String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                          inc.BMCServiceDesk__Feedback__c= treecomp[treecomp.size()-1];
                      } else {
                          inc.BMCServiceDesk__Feedback__c=inc.HD_Parent_Tree__c;
                      }
                      serviceRequestList.add(inc);
                  }
                  for (BMCServiceDesk__Incident__c inc: resolvedSr ) {
                      inc.BMCServiceDesk__Feedback__c = '';
                      if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                          String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                          inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                      }
                      serviceRequestList.add(inc);
                  }    
                  
                  //incidentlist = [select id, name, BMCServiceDesk__FKStatus__r.name,    BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where recordtype.name='Helpdesk' and  BMCServiceDesk__clientId__c=:userName and  BMCServiceDesk__FKStatus__r.name != 'CLOSED' ];   
                  
                  //serviceRequestList = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__shortDescription__c, HD_Parent_Tree__c, BMCServiceDesk__FKCategory__r.Name ,BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c, BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request' and  BMCServiceDesk__clientId__c=:userName  and  BMCServiceDesk__FKStatus__r.name != 'CLOSED'];                
              }
              
            cti_obj = '';
            cti_rt = '';
        }
          
        
       // method = ApexPages.currentpage().getparameters().get('method');
        
    
    }
    
    public String userNameSearch {get;set;}
    public String searchResult {get;set;}

        
    public String updateUserSearch() {
        System.debug('username' + userNameSearch );
        
        List<User> uList = Database.query('select id, name, username from user where username like \'' + userNameSearch + '%\' LIMIT 100');
        searchResult = '';
        userName = userNameSearch;
        if (uList.size() == 1) {
            
            matchedUser = uList[0];
            
            userName = matchedUser.username;
            userId = matchedUser.Id;
              List<BMCServiceDesk__Incident__c> openIncidents = new  List<BMCServiceDesk__Incident__c>();
              List<BMCServiceDesk__Incident__c> resolvedIncidents = new  List<BMCServiceDesk__Incident__c>();
              
              incidentlist  = new List<BMCServiceDesk__Incident__c>();
              serviceRequestList = new List<BMCServiceDesk__Incident__c>();
                   
              
              
              if (lob == 'HelpDesk') {
              
                  openIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c,   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c = 'Corp IT'  order by createddate desc];
                  resolvedIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name,BMCServiceDesk__Feedback__c,    BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c = 'Corp IT'  order by createddate desc];
              }
              if (lob == 'EAE Ops') {
                  openIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name,BMCServiceDesk__Feedback__c,    BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops' order by createddate desc];
                  resolvedIncidents = [select id, name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__Feedback__c,  BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c != 'Service Request' and recordtype.name='Helpdesk'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops' order by createddate desc];
              }
              
              
              for (BMCServiceDesk__Incident__c inc : openIncidents) {
                  inc.BMCServiceDesk__Feedback__c = '';
                  if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                      String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                      inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                  }    
                  incidentlist.add(inc);
              }
              for (BMCServiceDesk__Incident__c inc : resolvedIncidents ) {
                  inc.BMCServiceDesk__Feedback__c = '';
                  if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                      String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                      inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                  }
                  incidentlist.add(inc);
              }                  
              List<BMCServiceDesk__Incident__c> openSr = new List<BMCServiceDesk__Incident__c>();
              List<BMCServiceDesk__Incident__c> resolvedSr = new List<BMCServiceDesk__Incident__c>();
              
             if (lob == 'HelpDesk') {
                 openSr = [select id, name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__Feedback__c,  BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c = 'Corp IT'  order by createddate desc];
                 resolvedSr = [select id, name, BMCServiceDesk__FKStatus__r.name,    BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName  and HD_Incident_Group__c = 'Corp IT' order by createddate desc];
             }
             
             if (lob == 'EAE Ops') {
                 openSr = [select id, name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__Feedback__c,  BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request' and (not BMCServiceDesk__FKStatus__r.name LIKE 'CLOSED%') and  BMCServiceDesk__FKStatus__r.name != 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops'  order by createddate desc];
                 resolvedSr = [select id, name, BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c,   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name, HD_Owner_user_queue__c,    BMCServiceDesk__openDateTime__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = 'Service Request'  and  BMCServiceDesk__FKStatus__r.name = 'RESOLVED' and  BMCServiceDesk__clientId__c=:userName and HD_Incident_Group__c  = 'EAE Ops' order by createddate desc];
             }
              
              for (BMCServiceDesk__Incident__c inc: openSr) {
              inc.BMCServiceDesk__Feedback__c = '';
             if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                      String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                      inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                  }
                  
                  serviceRequestList.add(inc);
              }
              for (BMCServiceDesk__Incident__c inc: resolvedSr ) {
                  inc.BMCServiceDesk__Feedback__c = '';
              
                  if (inc.HD_Parent_Tree__c != null && inc.HD_Parent_Tree__c.contains('-->')) {
                      String[] treecomp = inc.HD_Parent_Tree__c.split('-->');
                      inc.BMCServiceDesk__Feedback__c = treecomp[treecomp.size()-1];
                  }
                  serviceRequestList.add(inc);
              }    
              
              
              
              
              
    
        } else {
        
            if (uList.size() > 1) {
                searchResult = 'Too many matches for this search, please try again';
            }
            if (uList.size() == 0) {
                searchResult = 'No matches for this search';
            }
            
        }
        
    
        return null;
        
    
    }
    


    public String runSearchPhone(String ani, Boolean contactOnly) {
            
             
            if (ani.startsWith(' 1')) {
                ani = ani.replace(' 1','');
            }
            if (ani.startsWith(' ')) {
                ani = ani.replace(' ','');
            }
            
           
            String result = '';
            
            String searchStr1 = '*'+ani+'*';
        	
        	Contact latestContact;
            
            //TODO add order by lastmodifieddate desc
            
            String searchQuery = 'FIND \'' + searchStr1 + '\' IN PHONE FIELDS RETURNING  Contact(id,lastmodifieddate,firstname, lastname, name,email,phone,mobilephone, mailingstate,mailingcity,mailingpostalcode,mailingstreet,Accountid,account.name,contact_type__c,account.Akatec_Geography__c,Support_level__c, Active_Portal_Login__c ORDER BY Lastmodifieddate desc limit 20), Lead(id, lastmodifieddate,city, state, postalcode, street, firstname, lastname, name, email, phone WHERE RecordType.Name = \'Marketo Lead\' ORDER BY Lastmodifieddate desc LIMIT 1), Account(id, akatec_geography__c, support_level__c), User(id,name,username  ORDER BY Lastmodifieddate desc LIMIT 1)';
            List<List <sObject>> searchList = search.query(searchQuery);
            System.debug(searchList);
            
            contactarray = ((List<contact>)searchList[0]);
            leadarray = ((List<lead>)searchList[1]);
            accountarray = ((List<Account>)searchList[2]);
            userarray = ((List<User>)searchList[3]);
        	List<Lead> llist = new List<Lead>();
            
         
            
            if (accountarray.size() == 1) {
                result = 'singleaccountmatch';
                accountid = accountarray[0].Id;
                matchedAccountId = accountid;
            } else {
                accountid = '';
            }
            if (contactarray.size() == 1) {
                result = 'singlematch';
                matchId = contactarray[0].Id;
                matchedAccountId = contactarray[0].accountid;
                matchedContact = contactarray[0];
            }
            if (userarray.size() == 1 && (lob == 'HelpDesk' || lob =='EAE Ops')) {
                result = 'singleusermatch';
                return result;
            }
            
            
            if (contactarray.size() > 1) {
                result = 'multimatch';
            }
            
            if (contactarray.size() == 0 && result == '') {
                result = 'nomatch';

            }
  
            if (lob == 'Marketing') {
                
                if(contactarray.size() > 1){
                    latestContact = contactarray[0];
                    result = 'multimatch';
                    matchId = contactarray[0].id;
                    llist = [select id, recordtypeid from lead where status in ('In Process','New') and Associated_Contact__c=:matchId and RecordType.Name = 'Akamai Lead' order by createddate desc limit 1];
                    if (llist.size() == 1) {
                        matchId = llist[0].Id;
                    }
                    
                    if(leadarray.size() >= 1){
                        result = 'multimatch';
                        if (leadarray[0].lastmodifieddate > latestContact.lastmodifieddate) {
                            matchId = leadarray[0].id;
                            llist = [select id, recordtypeid from lead where status in ('In Process','New') and Parent_Lead__c=:matchId and RecordType.Name = 'Akamai Lead' order by createddate desc limit 1];
                            if (llist.size() == 1) {
                                matchId = llist[0].Id;
                            } 
                            System.Debug('##' + matchId);
                        }          
                    }
                }
                else {
                    
                    
                    
                    if (contactarray.size() == 0 && leadarray.size() == 1) {
                        result = 'singlematch';
                        matchId = leadarray[0].id;
                        llist = [select id, recordtypeid from lead where status in ('In Process','New') and Parent_Lead__c=:matchId and RecordType.Name = 'Akamai Lead' order by createddate desc limit 1];
                        if (llist.size() == 1) {
                            matchId = llist[0].Id;
                        }    
                        
                    }
                    
                    if (contactarray.size() == 1 && leadarray.size() == 0) {
                        result = 'singlematch';
                        matchId = contactarray[0].id;
                        
                        llist = [select id, recordtypeid from lead where status in ('In Process','New') and Associated_Contact__c=:matchId and RecordType.Name = 'Akamai Lead' order by createddate desc limit 1];
                        if (llist.size() == 1) {
                            matchId = llist[0].Id;
                        }    
                        
                        
                        
                    }
                    
                    if (contactarray.size() == 1 && leadarray.size() == 1) {
                        result = 'singlematch';
                        
                        if (contactarray[0].lastmodifieddate > leadarray[0].lastmodifieddate) {
                            matchId = contactarray[0].id;
                            llist = [select id, recordtypeid from lead where status in ('In Process','New') and Associated_Contact__c=:matchId and RecordType.Name = 'Akamai Lead' order by createddate desc limit 1];
                            if (llist.size() == 1) {
                                matchId = llist[0].Id;
                            }  
                        } else {
                            matchId = leadarray[0].id;
                            llist = [select id, recordtypeid from lead where status in ('In Process','New') and Parent_Lead__c=:matchId and RecordType.Name = 'Akamai Lead' order by createddate desc limit 1];
                            if (llist.size() == 1) {
                                matchId = llist[0].Id;
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
        
        return result;
    
    }
    


}