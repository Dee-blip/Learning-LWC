public Class StreamingPublisher {
    public String profileCheck{get;set;}
    public String streamingConstantsList {get;set;}
    public StreamingPublisher(){
        profileCheck='false';
        Map<String,SC_Streaming_Settings__c> streamingSettings = SC_Streaming_Settings__c.getall();
        streamingConstantsList = JSON.serialize(streamingSettings);
        Set<String> sProfiles = new Set<String>();
        for(SC_HomeScreen_Profiles__c  p : SC_HomeScreen_Profiles__c.getAll().Values()) {
            sProfiles.add(p.Profile__c);
        }
        //Added by ssawhney for CR 2985554 
        for(SC_StreamingProfiles__c  p : SC_StreamingProfiles__c.getAll().Values()) {
            sProfiles.add(p.ProfileName__c);
        }
        
        String p =[Select Profile.Name from User where Id=:Userinfo.getUserId()][0].Profile.Name;
        if(sProfiles.contains(p)) {
            profileCheck='true';
        }
    
    }
 }