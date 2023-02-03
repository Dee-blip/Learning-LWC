public without sharing class AkaNovaConceptTriggerClass {
    public static void createConceptTeamOwner(List<Concept__c> concepts) {
        Set<String> owners = new Set<String>();
        Map<String, User> ldapToUser = new Map<String, User>();
        for(Concept__c concept : concepts) {
            owners.add(concept.Owner_Name__c);
        }
        List<User> users = [select Id, alias,Name from User where Alias in :owners];
        for (User usr : users) {
            ldapToUser.put(usr.alias.toLowerCase(), usr);
        }
        System.debug('ldapToUser :' + ldapToUser);
        List<Concept_Team__c> teamMembers = new List<Concept_Team__c>();
        User conceptOwner = new User ();
        for(Concept__c concept : concepts) {
            conceptOwner = ldapToUser.get(concept.Owner_Name__c.toLowerCase());
            Concept_Team__c conceptTeam = new Concept_Team__c();
            conceptTeam.Concept_AkaNova__c = concept.Id;
            conceptTeam.user__c = conceptOwner.Id;
            conceptTeam.Name = concept.Name;
            conceptTeam.User_Type__c = 'Concept Owner';
            teamMembers.add(conceptTeam);
            System.debug('teamMembers : ' + teamMembers);
        }
        insert teamMembers;
    }
    /*public static void createConceptTeamMembers(Map<Id, Set<String>> conceptToTeamMembers){
        Set<String> allTeamMembers = new Set<String>();
        Map<String, User> ldapToUser = new Map<String, User>();
        Map<Id,List<User>> ConceptIdToTeamMember = new Map<Id,List<User>>();
        for(Id conId : conceptToTeamMembers.keySet()) {
            allTeamMembers.addAll(conceptToTeamMembers.get(conId));
        }
        List<User> users = [select Id, alias,Name from User where Alias in :allTeamMembers];
        for (User usr : users) {
            ldapToUser.put(usr.alias.toLowerCase(), usr);
        }
        for(Id conId : conceptToTeamMembers.keySet()) {
            List<User> usrList = new List<User>();
            for(String ldap : conceptToTeamMembers.get(conId)) {
                User usrObj = ldapToUser.get(ldap.toLowerCase());
                usrList.add(usrObj);
            }
            ConceptIdToTeamMember.put(conId, usrList);
        }
        List<Concept_Team__c> teamMembers = new List<Concept_Team__c>();
        for(Id conId : ConceptIdToTeamMember.keySet()) {
            for (User usr : ConceptIdToTeamMember.get(conId)) {
                Concept_Team__c conceptTeam = new Concept_Team__c();
                System.debug('conId : ' + conId);
                conceptTeam.Concept_AkaNova__c = conId;
                conceptTeam.user__c = usr.Id;
                conceptTeam.User_Type__c = 'Concept Member';
                teamMembers.add(conceptTeam);
                System.debug('teamMembers : ' + teamMembers);
            }
        }
        insert teamMembers;
    }*/
    public static void createReviewerRecords(List<Concept__c> concepts) {
        List<AkaNova_Settings__mdt> reviewersList = [SELECT Id, ReviewerId__c FROM AkaNova_Settings__mdt WHERE DeveloperName = 'ReviewersList' LIMIT 1];
		List<String> ReviewerIds = reviewersList[0].ReviewerId__c.split(',');
        List<Concept_Team__c> reviwerMembers = new List<Concept_Team__c>();
        for (Concept__c concept : concepts) {
            for (String reviewerId : ReviewerIds) {
                Concept_Team__c reviewerTeam = new Concept_Team__c();
                reviewerTeam.Concept_AkaNova__c = concept.Id;
                reviewerTeam.Name = concept.Name;
                reviewerTeam.user__c = reviewerId;
                reviewerTeam.User_Type__c = 'Reviewer';
                reviwerMembers.add(reviewerTeam);
                System.debug('reviwerMembers : ' + reviwerMembers);
            }
        }
        insert reviwerMembers;
    }
}