public class QuipEventJSONToField {
    public List<Events> events {get;set;} 
    public Boolean more_to_read {get;set;} 
    public String next_cursor {get;set;} 
    
    public List<Quip_Document_History__c> getDocHistories() {
        List<Quip_Document_History__c> qdhList = new List<Quip_Document_History__c>();
        for(Events evt : events) {
            qdhList.add(evt.toQDH());
        }
        return qdhList;
    }
    
    public QuipEventJSONToField(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'events') {
                        events = arrayOfEvents(parser);
                    } else if (text == 'more_to_read') {
                        more_to_read = parser.getBooleanValue();
                    } else if (text == 'next_cursor') {
                        next_cursor = parser.getText();
                    } else {
                        System.debug(LoggingLevel.WARN, 'QuipEventJSONToField Consuming Unrecognized Property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public class Events {
        public Long time_usec {get;set;} 
        public String ip {get;set;} 
        public String session_id {get;set;} 
        public String user_agent {get;set;} 
        public String device {get;set;} 
        public String quip_version {get;set;} 
        public String thread_id {get;set;} 
        public String thread_author_id {get;set;} 
        public String source {get;set;} 
        public String user_id {get;set;} 
        public String company_id {get;set;} 
        public String event {get;set;} 
        public String id {get;set;} 
        public String object_Z {get;set;}
        public String action {get;set;} 
        public String sub_action {get;set;} 
        public String child_object {get;set;} 
        public String annotation_id {get;set;} 
        public String message_id {get;set;} 
        public String document_id {get;set;} 
        public String thread_thread_type {get;set;} 
        
        public Events(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'time_usec') {
                            time_usec = parser.getLongValue();
                        } else if (text == 'ip') {
                            ip = parser.getText();
                        } else if (text == 'session_id') {
                            session_id = parser.getText();
                        } else if (text == 'user_agent') {
                            user_agent = parser.getText();
                        } else if (text == 'device') {
                            device = parser.getText();
                        } else if (text == 'quip_version') {
                            quip_version = parser.getText();
                        } else if (text == 'thread_id') {
                            thread_id = parser.getText();
                        } else if (text == 'thread__author_id') {
                            thread_author_id = parser.getText();
                        } else if (text == 'source') {
                            source = parser.getText();
                        } else if (text == 'user_id') {
                            user_id = parser.getText();
                        } else if (text == 'company_id') {
                            company_id = parser.getText();
                        } else if (text == 'event') {
                            event = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else if (text == 'object') {
                            object_Z = parser.getText();
                        } else if (text == 'action') {
                            action = parser.getText();
                        } else if (text == 'sub_action') {
                            sub_action = parser.getText();
                        } else if (text == 'child_object') {
                            child_object = parser.getText();
                        } else if (text == 'annotation_id') {
                            annotation_id = parser.getText();
                        } else if (text == 'message_id') {
                            message_id = parser.getText();
                        } else if (text == 'document_id') {
                            document_id = parser.getText();
                        } else if (text == 'thread__thread_type') {
                            thread_thread_type = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Events Consuming Unrecognized Property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
        
        public Quip_Document_History__c toQDH() {
            return new Quip_Document_History__c(Action__c=this.action, Sub_Action__c=this.sub_action,Quip_User_Id__c=this.user_id, Object__c=this.object_Z,Quip_Document_Id__c=this.document_id, Timestamp__c=this.time_usec, Quip_Event_Id__c=this.id,Event__c=this.event,Quip_Thread_Id__c=this.thread_id ,Thread_Author_Id__c=this.thread_author_id);
        }
    }
    
    public static QuipEventJSONToField parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return new QuipEventJSONToField(parser);
    }
    
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                    depth++;
                } else if (curr == System.JSONToken.END_OBJECT ||
                           curr == System.JSONToken.END_ARRAY) {
                               depth--;
                           }
        } while (depth > 0 && parser.nextToken() != null);
    }
    
    private static List<Events> arrayOfEvents(System.JSONParser p) {
        List<Events> res = new List<Events>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Events(p));
        }
        return res;
    }
}