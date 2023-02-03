@RestResource(urlMapping='/liveagent')
global class LiveAgentWebservice {  
    
     /**
     * This method returns button or invitation code for the live agent based on skill and
     * whether request is for button or invitation.
     *
     * @param skillset          This is the skill for which the button code is required                          
     * @param invitation        Whether request is for button or for invitation
     *
     * @return                  The button or invitation code that can be embed in any external website
     *   
     * @ERRORS                  INVALID_INPUT, INVALID_SKILL, <exception message>
     * @STATUS                  SUCCESS, ERROR
     */
    
    
    global class Response {
        public String status;
        public String statusCode;       
        public String buttonCode;
        public String textButtonCode;
        public String errorCode;
    }
    
    @HttpGet
    global static Response getLiveAgentCode() {
        
        Response res = new Response();
        RestRequest req = RestContext.request;
        
        String skillset;
        Boolean invitation = false;
        Boolean validSkill = false;
        String buttonCode;
        String textButtonCode;
        
        try {          
            skillset = req.params.get('skillset');
            
            if (req.params.get('invitation') != null)
                invitation = Boolean.valueOf(req.params.get('invitation'));
        } catch (Exception e) {
            res.errorCode = 'INVALID_INPUT';
            res.status = 'ERROR';
            res.statusCode = '400';
            return res;
        }
        
        if (skillset == null || skillset == '') {
            res.errorCode = 'EMPTY_SKILLSET';
            res.status = 'ERROR';
            res.statusCode = '400';
            return res;
        }
        
        try {
            
            List<String> skills = new List<String>();
            
            if (skillset.contains(',')) {
                skills = skillset.split(',');
                skills = processSkills(skills);
            } else {
                skills.add(skillset.trim().toUpperCase());
            }
            
            List<Live_Agent_Mapping__mdt> liveAgentMapping = [Select developerName,Skill__c, Invitation__c , Botton_Code__c 
                                                             From Live_Agent_Mapping__mdt
                                                             Where Invitation__c =:invitation];
            
            for (Live_Agent_Mapping__mdt mapping:liveAgentMapping) {
                if (mapping.Skill__c != null && mapping.Skill__c != '') {
                    String mappingSkill = mapping.Skill__c;
                    List<String> skillsList;
                    if (mappingSkill.contains(',')) {
                        skillsList = mappingSkill.split(',');
                    } else {
                        skillsList = new List<String>();
                        skillsList.add(mappingSkill);
                    }
                    Set<String> skillsMappingSet = new Set<String>();
                    
                    skillsList = processSkills(skillsList);
                    skillsMappingSet.addAll(skillsList);
                    if (skillsMappingSet.containsAll(skills)) {
                        validSkill = true;
                        if(mapping.developerName.contains('Button') || mapping.developerName.contains('Invitation'))
                        {
                            buttonCode = mapping.Botton_Code__c;
                        }
                        else if(mapping.developerName.contains('Text'))
                        {
                            textButtonCode = mapping.Botton_Code__c;
                        }
                    }
                } 
            }
            
            
            if (!validSkill) {
                res.errorCode = 'INCORRECT_SKILLSET';
                res.status = 'ERROR';
                res.statusCode = '400';
                return res;
            }
            
            //Live_Agent_Mapping__mdt liveAgentConfig = liveAgentMapping[0];
            //System.debug('Button Code:'+liveAgentConfig.Botton_Code__c);
            //String buttonCode = liveAgentConfig.Botton_Code__c;
            //buttonCode = buttonCode.replaceAll('"', '&amp;quot;');
            //buttonCode = buttonCode.escapeXml();
            
            res.buttonCode = buttonCode;
            if(textButtonCode!=null)
            {
                res.textButtonCode = textButtonCode;
            }
            res.statusCode = '200';
            res.status = 'SUCCESS';
            return res;
        } catch (Exception e) {
            res.errorCode = e.getMessage();
            res.status = 'ERROR';
            res.statusCode = '500';
            return res;
        }
    }
    
    /*
     * This method is used to process the skillset
     * -- Trim the Skills for spaces
     * -- Capitalize for correct comparision
     */
    public static List<String> processSkills(List<String> skills) {
        
        List<String> processedSkills = new List<String>();
        
        if (skills != null && skills.size() > 0) {
            for (String s:skills) {
                String skil = s.toUpperCase().trim();
                processedSkills.add(skil);
            }
            return processedSkills;
        } else {
            return skills;
        }
    }
    
    global static String getLiveErrorMessage() {
        String errorMessage;
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Not A Valid Contract';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Please validate if all required Fields are present';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Opportunity';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Account';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate pageReference';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        
        return errorMessage;
    }

}