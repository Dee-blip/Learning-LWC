public class HD_EscalationButtonController{
    public String userID {get; set;}
    public String incidentID {get; set;}
    public BMCServiceDesk__IncidentHistory__c currentNote {get; set;}
    public Boolean success {get;set;}

    public HD_EscalationButtonController() {
        incidentID = ApexPages.currentPage().getParameters().get('incidentID');
        userID = UserInfo.getUserId();
        currentNote = new BMCServiceDesk__IncidentHistory__c();
        currentNote.BMCServiceDesk__FKIncident__c=incidentID;
        currentNote.BMCServiceDesk__FKUser__c=userID;
        currentNote.BMCServiceDesk__duration__c='00:00';
        currentNote.BMCServiceDesk__description__c='Transfer Note';
        currentNote.BMCServiceDesk__note__c='RF Incident(s):\n\nProblem statement:\n\nEnvironment:\n\nTroubleshooting:\n\nExpectation from next level:';
        success = null;
    }

    public PageReference save(){
        try{
            List<BMCServiceDesk__Action__c> actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'ESCALATION_NOTE'];
            if(actionList!=null){

                String effort = currentNote.BMCServiceDesk__duration__c;
                try{
                  if(String.isNotBlank(effort)){
                    String[] tokens = effort.split(':');
                    if(tokens.size()==2){
                        String hoursStr = tokens[0];
                        String minutesStr = tokens[1];
                        if(hoursStr.length()!=2 || minutesStr.length()!=2){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide Time Spent value in HH:MM format.'));
                            return null;
                        }
                        Integer hours = Integer.valueOf(tokens[0]);
                        Integer minutes = Integer.valueOf(tokens[1]);
                        if(minutes>59){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'minutes value in HH:MM can not exceed 59'));
                            return null;
                        }
                      if(hours==0){ 
                        if(minutes<10){
                          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Time Spent value should be in the range 00:10 to 36:00'));
                          return null;
                        }
                      }else{  
                        if(minutes==0){
                            if(hours>36){
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Time Spent value should be in the range 00:10 to 36:00'));
                                return null;
                            }
                        } else if(hours>35){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Time Spent value should be in the range 00:10 to 36:00'));
                            return null;
                        }
                      }
                    }else{
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Time Spent value should be in the format HH:MM'));
                        return null;
                    }
                  }
                  }catch(Exception e){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There was a problem with parsing Time Spent value.'));
                    return null;
                  }

                currentNote.BMCServiceDesk__FKAction__c=actionList[0].Id;
                currentNote.HD_Action__c='ESCALATION_NOTE';
                insert currentNote;
                success = true;
                BMCServiceDesk__Incident__c thisIncident = [select Id,HD_OwnerLocked__c from BMCServiceDesk__Incident__c where id=:incidentID LIMIT 1];
                thisIncident.HD_OwnerLocked__c=false;
                update thisIncident;
            }
        }
        catch(Exception e){
            System.debug('HD_EscalationNote -> '+e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem in saving the Escalation Note!'));
        }
        return null;
    }
}