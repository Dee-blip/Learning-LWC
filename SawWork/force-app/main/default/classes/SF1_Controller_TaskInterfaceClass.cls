/**
 *  SF1_Controller_TaskInterfaceClass
 *
   --Developer         --Date          --Description
   Sausharm           25/07/2017       Initial version of Controller for Task Comment App on SF1
 **/
public class SF1_Controller_TaskInterfaceClass
{

        @AuraEnabled
        public static String getTaskDetails(String taskId)
        {
                Task t = [select id,description,What.Name,WhatId,Subject,Status,Owner.name,OwnerId,Task_Type__c,ActivityDate from Task where id=:taskId];
                User u = [select MobilePhone,Phone from User where id=:t.ownerId];

                Map <String, String> jsonMap = new Map <String, String> ();
                jsonMap.put('currentUserName',UserInfo.getName());
                jsonMap.put('taskComment', t.description);
                jsonMap.put('taskStatus', t.Status);
                jsonMap.put('taskAssignedTo', t.Owner.name);
                jsonMap.put('taskAssignedToID', t.OwnerId);
                jsonMap.put('taskRelatedTo', t.What.Name);
                jsonMap.put('taskSubject', t.subject);
                jsonMap.put('taskType', t.Task_Type__c);
                jsonMap.put('taskUserCellPhone', u.MobilePhone);
                jsonMap.put('taskUserOfficePhone', u.Phone);
                jsonMap.put('relatedObjectId',t.WhatId);
                if(t.ActivityDate != null)
                {
                        jsonMap.put('taskDueDate',t.ActivityDate.format());
                }
                else
                {
                        jsonMap.put('taskDueDate','No Due Date');
                }
                //jsonMap.put('legalFollowUpNeeded',String.valueof(t.Legal_Followup_Needed__c));
                String jsonString = JSON.serialize(jsonMap);
                return jsonString;
        }

        @AuraEnabled
        public static Task getTask(String taskId)
        {
                Task t = [select id,description,What.Name,WhatId,Subject,Status,OwnerId,Task_Type__c,ActivityDate from Task where id=:taskId];
                return t;
        }

        @AuraEnabled
        public static List<String> loadTaskStatusPicklist()
        {
                return GSMLite_UtilClass.populatePickList('Task','Status');
        }

        @AuraEnabled
        public static void editTask(Task taskObject)
        {
                update taskObject;
                //q2o_customlogger.logmessage(String.valueof(taskObject));
                //q2o_customlogger.commitlogs();

        }

        @AuraEnabled
        public static void submitCommentbyUser(String taskId, String taskOwnerId, String comment, String taggedUsersJSON)
        {

                String ldap = getDisplayNamewithDate();
                Task t = [select id,description,What.Name from Task where id=:taskId];
                if(t.description != null)
                {
                        t.description = t.description +'\r\n\r\n['+ldap+'] '+comment;
                }
                else
                {
                        t.description = '['+ldap+'] '+comment;
                }
                update t;

                if(taggedUsersJSON != '')
                {
                        sendFeedstoUsers(taskId, taggedUsersJSON);
                }



        }

        private static String getDisplayNamewithDate()
        {
                Date d = date.today();
                String dt = DateTime.newInstance(d.year(),d.month(),d.day()).format('dd MMM,yyyy');
                return Userinfo.getName()+' '+dt;
        }

        private static void sendFeedstoUsers(String objectToPostId,String taggedUsersJSON)
        {
                Set<Id> userIDs = new Set<ID>();
                for(User u : (List<User>)JSON.deserialize(taggedUsersJSON, List<User>.class))
                {
                        userIDs.add(u.Id);
                }
                if(userIDs.size()>0)
                {
                        List<Id> uIDList = new List<Id>();
                        uIDList.addAll(userIDs);

                        // A future method, called Asynchronously
                        SF1_NotificationSenderUtil.sendNotification(uIDList,' you are tagged on Task Comment',objectToPostId);
                }
        }

}